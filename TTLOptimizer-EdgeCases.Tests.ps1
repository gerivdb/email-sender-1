<#
.SYNOPSIS
    Tests des cas limites pour le module TTLOptimizer.
.DESCRIPTION
    Ce script contient des tests pour les cas limites du module TTLOptimizer
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

Describe "TTLOptimizer Edge Cases Tests" {
    BeforeAll {
        # Créer un CacheManager et un UsageCollector pour les tests
        $script:baseCache = New-MockCacheManager -Name "TestCache" -CachePath $testCachePath
        $script:usageCollector = New-MockUsageCollector -DatabasePath $testDatabasePath -CacheName "TestCache"

        # Créer un TTLOptimizer pour les tests
        $script:ttlOptimizer = New-MockTTLOptimizer -BaseCache $script:baseCache -UsageCollector $script:usageCollector
    }

    Context "Extreme Values" {
        It "Should handle zero default TTL" {
            $optimizedTTL = $script:ttlOptimizer.OptimizeTTL("TestKey", 0)

            $optimizedTTL | Should -BeGreaterOrEqual $script:ttlOptimizer.MinimumTTL
        }

        It "Should handle very large default TTL" {
            $optimizedTTL = $script:ttlOptimizer.OptimizeTTL("TestKey", 1000000)

            $optimizedTTL | Should -BeLessOrEqual $script:ttlOptimizer.MaximumTTL
        }

        It "Should handle negative default TTL" {
            $optimizedTTL = $script:ttlOptimizer.OptimizeTTL("TestKey", -1000)

            $optimizedTTL | Should -BeGreaterOrEqual $script:ttlOptimizer.MinimumTTL
        }
    }

    Context "Edge Cases for Weighting Factors" {
        It "Should handle zero weights" {
            $script:ttlOptimizer.FrequencyWeight = 0
            $script:ttlOptimizer.RecencyWeight = 0
            $script:ttlOptimizer.StabilityWeight = 0

            $optimizedTTL = $script:ttlOptimizer.OptimizeTTL("TestKey", 3600)

            $optimizedTTL | Should -BeGreaterOrEqual $script:ttlOptimizer.MinimumTTL
        }

        It "Should handle very large weights" {
            $script:ttlOptimizer.FrequencyWeight = 10
            $script:ttlOptimizer.RecencyWeight = 10
            $script:ttlOptimizer.StabilityWeight = 10

            $optimizedTTL = $script:ttlOptimizer.OptimizeTTL("TestKey", 3600)

            $optimizedTTL | Should -BeLessOrEqual $script:ttlOptimizer.MaximumTTL
        }

        It "Should handle negative weights" {
            $script:ttlOptimizer.FrequencyWeight = -0.5
            $script:ttlOptimizer.RecencyWeight = -0.3
            $script:ttlOptimizer.StabilityWeight = -0.2

            $optimizedTTL = $script:ttlOptimizer.OptimizeTTL("TestKey", 3600)

            $optimizedTTL | Should -BeGreaterOrEqual $script:ttlOptimizer.MinimumTTL
        }
    }

    Context "Non-existent Keys" {
        It "Should handle non-existent keys" {
            $optimizedTTL = $script:ttlOptimizer.OptimizeTTL("NonExistentKey", 3600)

            $optimizedTTL | Should -Be 3600
        }
    }

    Context "Special Key Patterns" {
        It "Should handle empty keys" {
            $optimizedTTL = $script:ttlOptimizer.OptimizeTTL("", 3600)

            $optimizedTTL | Should -BeGreaterOrEqual $script:ttlOptimizer.MinimumTTL
        }

        It "Should handle very long keys" {
            $longKey = "a" * 1000
            $optimizedTTL = $script:ttlOptimizer.OptimizeTTL($longKey, 3600)

            $optimizedTTL | Should -BeGreaterOrEqual $script:ttlOptimizer.MinimumTTL
        }

        It "Should handle special characters in keys" {
            $specialKey = "!@#$%^&*()_+{}|:<>?~`-=[]\\;',./'"
            $optimizedTTL = $script:ttlOptimizer.OptimizeTTL($specialKey, 3600)

            $optimizedTTL | Should -BeGreaterOrEqual $script:ttlOptimizer.MinimumTTL
        }
    }

    AfterAll {
        # Nettoyage
        if (Test-Path -Path $testDatabasePath) {
            Remove-Item -Path $testDatabasePath -Force -ErrorAction SilentlyContinue
        }
    }
}
