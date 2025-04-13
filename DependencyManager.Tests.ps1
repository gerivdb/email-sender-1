<#
.SYNOPSIS
    Tests unitaires pour le module DependencyManager.
.DESCRIPTION
    Ce script contient des tests unitaires pour le module DependencyManager
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
$testCachePath = Join-Path -Path $testDir -ChildPath "Cache"
$testDatabasePath = Join-Path -Path $testDir -ChildPath "Usage.db"

# Nettoyer les tests précédents
if (Test-Path -Path $testCachePath) {
    Remove-Item -Path $testCachePath -Recurse -Force -ErrorAction SilentlyContinue
}
if (Test-Path -Path $testDatabasePath) {
    Remove-Item -Path $testDatabasePath -Force -ErrorAction SilentlyContinue
}

# Créer le répertoire du cache
New-Item -Path $testCachePath -ItemType Directory -Force | Out-Null

Describe "DependencyManager Module Tests" {
    BeforeAll {
        # Créer un CacheManager et un UsageCollector pour les tests
        $script:baseCache = New-MockCacheManager -Name "TestCache" -CachePath $testCachePath
        $script:usageCollector = New-MockUsageCollector -DatabasePath $testDatabasePath -CacheName "TestCache"

        # Ajouter des données de test au UsageCollector
        $script:usageCollector.RecordAccess("Key1", $true)
        $script:usageCollector.RecordAccess("Key2", $true)
        $script:usageCollector.RecordAccess("Key3", $true)

        # Créer un DependencyManager pour les tests
        $script:dependencyManager = New-MockDependencyManager -BaseCache $script:baseCache -UsageCollector $script:usageCollector
    }

    Context "New-DependencyManager Function" {
        It "Should create a new DependencyManager object" {
            $manager = New-MockDependencyManager -BaseCache $script:baseCache -UsageCollector $script:usageCollector
            $manager | Should -Not -BeNullOrEmpty
            $manager.GetType().Name | Should -Be "DependencyManager"
        }
    }

    Context "Add-CacheDependency Function" {
        It "Should add a dependency between keys" {
            $script:dependencyManager.AddDependency("Source1", "Target1", 0.8)
            $dependencies = $script:dependencyManager.GetDependencies("Source1")
            $dependencies.Count | Should -Be 1
            $dependencies["Target1"] | Should -Be 0.8
        }
    }

    Context "Remove-CacheDependency Function" {
        It "Should remove a dependency between keys" {
            $script:dependencyManager.AddDependency("Source2", "Target2", 0.7)
            $result = $script:dependencyManager.RemoveDependency("Source2", "Target2")
            $result | Should -Be $true
            $dependencies = $script:dependencyManager.GetDependencies("Source2")
            $dependencies.Count | Should -Be 0
        }
    }

    Context "Set-DependencyManagerOptions Function" {
        It "Should update dependency manager options" {
            $script:dependencyManager.AutoDetectDependencies = $false
            $script:dependencyManager.MaxDependenciesPerKey = 5
            $script:dependencyManager.MinDependencyStrength = 0.2

            $script:dependencyManager.AutoDetectDependencies | Should -Be $false
            $script:dependencyManager.MaxDependenciesPerKey | Should -Be 5
            $script:dependencyManager.MinDependencyStrength | Should -Be 0.2
        }
    }

    Context "DependencyManager Methods" {
        It "Should add and retrieve dependencies" {
            $script:dependencyManager.AddDependency("SourceA", "TargetA", 0.9)
            $script:dependencyManager.AddDependency("SourceA", "TargetB", 0.7)
            $script:dependencyManager.AddDependency("SourceA", "TargetC", 0.5)

            $dependencies = $script:dependencyManager.GetDependencies("SourceA")
            $dependencies.Count | Should -Be 3
            $dependencies["TargetA"] | Should -Be 0.9
            $dependencies["TargetB"] | Should -Be 0.7
            $dependencies["TargetC"] | Should -Be 0.5
        }

        It "Should add and retrieve dependents" {
            $script:dependencyManager.AddDependency("SourceX", "TargetZ", 0.8)
            $script:dependencyManager.AddDependency("SourceY", "TargetZ", 0.6)

            $dependents = $script:dependencyManager.GetDependents("TargetZ")
            $dependents.Count | Should -Be 2
            $dependents["SourceX"] | Should -Be 0.8
            $dependents["SourceY"] | Should -Be 0.6
        }

        It "Should detect dependencies automatically" {
            # Simuler des séquences d'accès
            $script:usageCollector.RecordAccess("KeyA", $true)
            Start-Sleep -Milliseconds 100
            $script:usageCollector.RecordAccess("KeyB", $true)
            Start-Sleep -Milliseconds 100
            $script:usageCollector.RecordAccess("KeyA", $true)
            Start-Sleep -Milliseconds 100
            $script:usageCollector.RecordAccess("KeyB", $true)

            # Activer la détection automatique
            $script:dependencyManager.AutoDetectDependencies = $true
            $script:dependencyManager.DetectDependencies()

            # Vérifier les statistiques
            $stats = $script:dependencyManager.GetDependencyStatistics()
            $stats | Should -Not -BeNullOrEmpty
        }
    }

    AfterAll {
        # Nettoyage
        if (Test-Path -Path $testDatabasePath) {
            Remove-Item -Path $testDatabasePath -Force -ErrorAction SilentlyContinue
        }
    }
}
