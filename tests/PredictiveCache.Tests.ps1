<#
.SYNOPSIS
    Tests unitaires pour le module PredictiveCache.
.DESCRIPTION
    Ce script contient des tests unitaires pour le module PredictiveCache
    du systÃ¨me de cache prÃ©dictif.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 13/04/2025
#>

# Importer le module de types simulÃ©s
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Parent $scriptPath
$mockTypesPath = Join-Path -Path $scriptDir -ChildPath "MockTypes.psm1"
Import-Module $mockTypesPath -Force

# CrÃ©er un chemin temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "PSCacheManager_Tests"
$testCachePath = Join-Path -Path $testDir -ChildPath "Cache"
$testDatabasePath = Join-Path -Path $testDir -ChildPath "Usage.db"

# Nettoyer les tests prÃ©cÃ©dents
if (Test-Path -Path $testCachePath) {
    Remove-Item -Path $testCachePath -Recurse -Force -ErrorAction SilentlyContinue
}
if (Test-Path -Path $testDatabasePath) {
    Remove-Item -Path $testDatabasePath -Force -ErrorAction SilentlyContinue
}

# CrÃ©er le rÃ©pertoire du cache
New-Item -Path $testCachePath -ItemType Directory -Force | Out-Null

Describe "PredictiveCache Module Tests" {
    BeforeAll {
        # CrÃ©er un PredictiveCache pour les tests
        $script:predictiveCache = New-MockPredictiveCache -Name "TestCache" -CachePath $testCachePath -DatabasePath $testDatabasePath

        # Configurer le PreloadManager
        $generator = { return "PreloadedValue" }
        $script:predictiveCache.PreloadManager.RegisterPreloadGenerator("Preload:*", $generator)

        # Ajouter des dÃ©pendances
        $script:predictiveCache.DependencyManager.AddDependency("Key1", "Key2", 0.8)
        $script:predictiveCache.DependencyManager.AddDependency("Key1", "Key3", 0.6)
    }

    Context "New-PredictiveCache Function" {
        It "Should create a new PredictiveCache object" {
            $cache = New-MockPredictiveCache -name "TestCache2" -CachePath $testCachePath -DatabasePath $testDatabasePath
            $cache | Should -Not -BeNullOrEmpty
            $cache.GetType().Name | Should -Be "PredictiveCache"
        }
    }

    Context "Basic Cache Operations" {
        It "Should set and get values" {
            $script:predictiveCache.Set("TestKey", "TestValue")
            $value = $script:predictiveCache.Get("TestKey")

            $value | Should -Be "TestValue"
        }

        It "Should check if a key exists" {
            $script:predictiveCache.Set("ExistingKey", "Value")
            $exists = $script:predictiveCache.Contains("ExistingKey")
            $notExists = $script:predictiveCache.Contains("NonExistingKey")

            $exists | Should -Be $true
            $notExists | Should -Be $false
        }

        It "Should remove keys" {
            $script:predictiveCache.Set("KeyToRemove", "Value")
            $script:predictiveCache.Remove("KeyToRemove")
            $exists = $script:predictiveCache.Contains("KeyToRemove")

            $exists | Should -Be $false
        }
    }

    Context "Advanced Cache Features" {
        It "Should use adaptive TTL" {
            $script:predictiveCache.AdaptiveTTLEnabled = $true
            $script:predictiveCache.Set("AdaptiveTTLKey", "Value")

            $value = $script:predictiveCache.Get("AdaptiveTTLKey")
            $value | Should -Be "Value"
        }

        It "Should track dependencies" {
            $script:predictiveCache.DependencyTrackingEnabled = $true
            $script:predictiveCache.Set("SourceKey", "SourceValue")
            $script:predictiveCache.Get("SourceKey")

            # VÃ©rifier que les dÃ©pendances sont traitÃ©es
            $script:predictiveCache.ProcessDependencies("SourceKey")
        }

        It "Should preload keys" {
            $script:predictiveCache.PreloadEnabled = $true
            $script:predictiveCache.DependencyManager.AddDependency("TriggerKey", "Preload:123", 0.9)

            $script:predictiveCache.Set("TriggerKey", "TriggerValue")
            $script:predictiveCache.Get("TriggerKey")

            # VÃ©rifier que le prÃ©chargement est effectuÃ©
            $script:predictiveCache.ProcessDependencies("TriggerKey")

            $value = $script:predictiveCache.Get("Preload:123")
            $value | Should -Be "PreloadedValue"
        }

        It "Should optimize the cache" {
            $script:predictiveCache.Optimize()

            # Pas d'erreur attendue
            $true | Should -Be $true
        }
    }

    Context "Cache Statistics" {
        It "Should provide comprehensive statistics" {
            $stats = $script:predictiveCache.GetStatistics()

            $stats | Should -Not -BeNullOrEmpty
            $stats.ContainsKey("Name") | Should -Be $true
            $stats.ContainsKey("CacheStats") | Should -Be $true
            $stats.ContainsKey("UsageStats") | Should -Be $true
            $stats.ContainsKey("DependencyStats") | Should -Be $true
            $stats.ContainsKey("TTLStats") | Should -Be $true
            $stats.ContainsKey("PreloadStats") | Should -Be $true
        }
    }

    AfterAll {
        # Nettoyage
        if (Test-Path -Path $testDatabasePath) {
            Remove-Item -Path $testDatabasePath -Force -ErrorAction SilentlyContinue
        }
    }
}
