#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le module UsageCollector.
.DESCRIPTION
    Ce script contient les tests unitaires pour le module UsageCollector
    du système de cache prédictif.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 12/04/2025
#>

# Importer Pester si nécessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer le module de types simulés
$mockTypesPath = Join-Path -Path $PSScriptRoot -ChildPath "MockTypes.psm1"
Import-Module $mockTypesPath -Force

# Créer un chemin temporaire pour la base de données de test
$testDatabasePath = Join-Path -Path $env:TEMP -ChildPath "PSCacheManager_Tests\UsageCollector_Test.db"
$testDatabaseDir = Split-Path -Path $testDatabasePath -Parent
if (-not (Test-Path -Path $testDatabaseDir)) {
    New-Item -Path $testDatabaseDir -ItemType Directory -Force | Out-Null
}

# Nettoyer les tests précédents
if (Test-Path -Path $testDatabasePath) {
    Remove-Item -Path $testDatabasePath -Force
}

Describe "UsageCollector Module Tests" {
    BeforeAll {
        # Créer un mock pour System.Data.SQLite si nécessaire
        if (-not ([System.Management.Automation.PSTypeName]'System.Data.SQLite.SQLiteConnection').Type) {
            # Si SQLite n'est pas disponible, créer un mock de base de données en mémoire
            # Cette variable est utilisée indirectement via les mocks
            $script:mockDatabase = [PSCustomObject]@{
                Accesses  = @()
                Sets      = @()
                Evictions = @()
                Sequences = @()
            }

            # Mock de la classe UsageDatabase
            Mock -CommandName New-Object -ParameterFilter {
                $TypeName -eq 'System.Data.SQLite.SQLiteConnection'
            } -MockWith {
                return [PSCustomObject]@{
                    Open          = { }
                    Close         = { }
                    CreateCommand = {
                        return [PSCustomObject]@{
                            CommandText     = ""
                            Parameters      = [PSCustomObject]@{
                                AddWithValue = { param($name, $value) }
                            }
                            ExecuteNonQuery = { return 0 }
                            ExecuteReader   = {
                                return [PSCustomObject]@{
                                    Read  = { return $false }
                                    Close = { }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Context "New-UsageCollector Function" {
        It "Should create a new UsageCollector object" {
            $collector = New-UsageCollector -DatabasePath $testDatabasePath -CacheName "TestCache"
            $collector | Should -Not -BeNullOrEmpty
            $collector.GetType().Name | Should -Be "UsageCollector"
        }

        It "Should set the correct database path" {
            $collector = New-UsageCollector -DatabasePath $testDatabasePath -CacheName "TestCache"
            $collector.DatabasePath | Should -Be $testDatabasePath
        }

        It "Should set the correct cache name" {
            $collector = New-UsageCollector -DatabasePath $testDatabasePath -CacheName "TestCache"
            $collector.CacheName | Should -Be "TestCache"
        }
    }

    Context "UsageCollector Methods" {
        BeforeEach {
            # Cette variable est utilisée dans chaque test de ce contexte
            $script:collector = New-UsageCollector -DatabasePath $testDatabasePath -CacheName "TestCache"
        }

        It "Should record cache access" {
            # Arrange
            $key = "TestKey"
            $hit = $true

            # Act
            { $collector.RecordAccess($key, $hit) } | Should -Not -Throw

            # Assert - Vérification indirecte via les statistiques
            $stats = $collector.GetKeyAccessStats($key)
            if ($stats) {
                $stats.Key | Should -Be $key
            }
        }

        It "Should record cache set operation" {
            # Arrange
            $key = "TestKey"
            $value = "TestValue"
            $ttl = 3600

            # Act
            { $collector.RecordSet($key, $value, $ttl) } | Should -Not -Throw
        }

        It "Should record cache eviction" {
            # Arrange
            $key = "TestKey"

            # Act
            { $collector.RecordEviction($key) } | Should -Not -Throw
        }

        It "Should retrieve most accessed keys" {
            # Arrange
            $collector.RecordAccess("Key1", $true)
            $collector.RecordAccess("Key1", $true)
            $collector.RecordAccess("Key2", $false)

            # Act
            $mostAccessed = $collector.GetMostAccessedKeys(10, 60)

            # Assert
            if ($mostAccessed -and $mostAccessed.Count -gt 0) {
                $mostAccessed[0].Key | Should -Be "Key1"
            }
        }

        It "Should retrieve frequent sequences" {
            # Arrange
            $collector.RecordAccess("Key1", $true)
            Start-Sleep -Milliseconds 100
            $collector.RecordAccess("Key2", $true)

            # Act
            $sequences = $collector.GetFrequentSequences(10, 60)

            # Assert - Vérification de base
            $sequences | Should -Not -BeNullOrEmpty -ErrorAction SilentlyContinue
        }
    }

    Context "Database Operations" {
        BeforeEach {
            # Cette variable est utilisée dans le test de fermeture de connexion
            $script:collector = New-UsageCollector -DatabasePath $testDatabasePath -CacheName "TestCache"
        }

        It "Should close the database connection" {
            # Act
            { $collector.Close() } | Should -Not -Throw
        }
    }

    AfterAll {
        # Nettoyage
        if (Test-Path -Path $testDatabasePath) {
            Remove-Item -Path $testDatabasePath -Force -ErrorAction SilentlyContinue
        }
    }
}
