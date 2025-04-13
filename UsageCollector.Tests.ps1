<#
.SYNOPSIS
    Tests unitaires pour le module UsageCollector.
.DESCRIPTION
    Ce script contient des tests unitaires pour le module UsageCollector
    du système de cache prédictif.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 13/04/2025
#>

# Importer le module de types simulés
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Parent $scriptPath
$mockTypesPath = Join-Path -Path $scriptDir -ChildPath "MockTypes.psm1"
Import-Module $mockTypesPath -Force

# Créer un chemin temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "PSCacheManager_Tests"
$testDatabasePath = Join-Path -Path $testDir -ChildPath "Usage.db"

# Nettoyer les tests précédents
if (Test-Path -Path $testDatabasePath) {
    Remove-Item -Path $testDatabasePath -Force -ErrorAction SilentlyContinue
}

# Créer le répertoire parent si nécessaire
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

Describe "UsageCollector Module Tests" {
    BeforeAll {
        # Créer un UsageCollector pour les tests
        $script:usageCollector = New-MockUsageCollector -DatabasePath $testDatabasePath -CacheName "TestCache"
    }

    Context "New-UsageCollector Function" {
        It "Should create a new UsageCollector object" {
            $collector = New-MockUsageCollector -DatabasePath $testDatabasePath -CacheName "TestCache2"
            $collector | Should -Not -BeNullOrEmpty
            $collector.GetType().Name | Should -Be "UsageCollector"
        }

        It "Should set the correct cache name" {
            $collector = New-MockUsageCollector -DatabasePath $testDatabasePath -CacheName "TestCache3"
            $collector.CacheName | Should -Be "TestCache3"
        }
    }

    Context "UsageCollector Methods" {
        It "Should record cache access" {
            $script:usageCollector.RecordAccess("TestKey1", $true)
            $script:usageCollector.RecordAccess("TestKey1", $true)
            $script:usageCollector.RecordAccess("TestKey1", $false)

            $stats = $script:usageCollector.GetKeyAccessStats("TestKey1")
            $stats | Should -Not -BeNullOrEmpty
            $stats.TotalAccesses | Should -Be 3
            $stats.Hits | Should -Be 2
            $stats.Misses | Should -Be 1
        }

        It "Should record cache set operation" {
            $script:usageCollector.RecordSet("TestKey2", "TestValue")
            $script:usageCollector.RecordAccess("TestKey2", $true)

            $stats = $script:usageCollector.GetKeyAccessStats("TestKey2")
            $stats | Should -Not -BeNullOrEmpty
            $stats.TotalAccesses | Should -Be 1
            $stats.Hits | Should -Be 1
        }

        It "Should record cache eviction" {
            $script:usageCollector.RecordAccess("TestKey3", $true)
            $script:usageCollector.RecordEviction("TestKey3")

            $stats = $script:usageCollector.GetKeyAccessStats("TestKey3")
            $stats | Should -Not -BeNullOrEmpty
        }

        It "Should retrieve most accessed keys" {
            $script:usageCollector.RecordAccess("FrequentKey1", $true)
            $script:usageCollector.RecordAccess("FrequentKey1", $true)
            $script:usageCollector.RecordAccess("FrequentKey1", $true)
            $script:usageCollector.RecordAccess("FrequentKey2", $true)
            $script:usageCollector.RecordAccess("FrequentKey2", $true)
            $script:usageCollector.RecordAccess("RareKey", $true)

            $mostAccessed = $script:usageCollector.GetMostAccessedKeys(2)
            $mostAccessed | Should -Not -BeNullOrEmpty
            $mostAccessed.Count | Should -BeGreaterOrEqual 1
            $mostAccessed[0].Key | Should -Be "FrequentKey1"
        }

        It "Should retrieve frequent sequences" {
            $script:usageCollector.RecordAccess("SeqA", $true)
            Start-Sleep -Milliseconds 100
            $script:usageCollector.RecordAccess("SeqB", $true)
            Start-Sleep -Milliseconds 100
            $script:usageCollector.RecordAccess("SeqA", $true)
            Start-Sleep -Milliseconds 100
            $script:usageCollector.RecordAccess("SeqB", $true)

            $sequences = $script:usageCollector.GetFrequentSequences(5)
            $sequences | Should -Not -BeNullOrEmpty
        }
    }

    Context "Database Operations" {
        It "Should close the database connection" {
            $script:usageCollector.Close()
            # Pas d'erreur attendue
            $true | Should -Be $true
        }
    }

    AfterAll {
        # Nettoyage
        if (Test-Path -Path $testDatabasePath) {
            Remove-Item -Path $testDatabasePath -Force -ErrorAction SilentlyContinue
        }
    }
}
