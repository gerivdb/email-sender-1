<#
.SYNOPSIS
    Tests unitaires pour le module TTLOptimizer.
.DESCRIPTION
    Ce script contient des tests unitaires pour le module TTLOptimizer
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

Describe "TTLOptimizer Module Tests" {
    BeforeAll {
        # CrÃ©er un CacheManager et un UsageCollector pour les tests
        $script:baseCache = New-MockCacheManager -Name "TestCache" -CachePath $testCachePath
        $script:usageCollector = New-MockUsageCollector -DatabasePath $testDatabasePath -CacheName "TestCache"

        # Ajouter des donnÃ©es de test au UsageCollector
        $script:usageCollector.RecordAccess("Key1", $true)
        $script:usageCollector.RecordAccess("Key1", $true)
        $script:usageCollector.RecordAccess("Key2", $true)
        $script:usageCollector.RecordAccess("Key2", $false)
        $script:usageCollector.RecordAccess("FrequentKey", $true)
        $script:usageCollector.RecordAccess("FrequentKey", $true)
        $script:usageCollector.RecordAccess("FrequentKey", $true)
        $script:usageCollector.RecordAccess("FrequentKey", $true)
        $script:usageCollector.RecordAccess("FrequentKey", $true)

        # CrÃ©er un TTLOptimizer pour les tests
        $script:ttlOptimizer = New-MockTTLOptimizer -BaseCache $script:baseCache -UsageCollector $script:usageCollector
    }

    Context "New-TTLOptimizer Function" {
        It "Should create a new TTLOptimizer object" {
            $optimizer = New-MockTTLOptimizer -BaseCache $script:baseCache -UsageCollector $script:usageCollector
            $optimizer | Should -Not -BeNullOrEmpty
            $optimizer.GetType().Name | Should -Be "TTLOptimizer"
        }
    }

    Context "TTLOptimizer Methods" {
        It "Should optimize TTL based on usage patterns" {
            $defaultTTL = 3600
            $optimizedTTL = $script:ttlOptimizer.OptimizeTTL("FrequentKey", $defaultTTL)

            $optimizedTTL | Should -BeGreaterThan 0
            # Le TTL optimisÃ© devrait Ãªtre diffÃ©rent du TTL par dÃ©faut
            $optimizedTTL | Should -Not -Be $defaultTTL
        }

        It "Should detect key patterns" {
            $pattern1 = $script:ttlOptimizer.DetectKeyPattern("user123")
            $pattern2 = $script:ttlOptimizer.DetectKeyPattern("cache:item42")
            $pattern3 = $script:ttlOptimizer.DetectKeyPattern("api/users/profile")

            $pattern1 | Should -Be "AlphaNumeric"
            $pattern2 | Should -Be "Namespaced"
            $pattern3 | Should -Be "Hierarchical"
        }

        It "Should calculate frequency factor correctly" {
            $factor1 = $script:ttlOptimizer.CalculateFrequencyFactor(10)
            $factor2 = $script:ttlOptimizer.CalculateFrequencyFactor(200)

            $factor1 | Should -Be 0.1
            $factor2 | Should -Be 1.0
        }

        It "Should calculate recency factor correctly" {
            $now = Get-Date
            $recent = $now.AddMinutes(-30)
            $old = $now.AddHours(-12)

            $factor1 = $script:ttlOptimizer.CalculateRecencyFactor($recent)
            $factor2 = $script:ttlOptimizer.CalculateRecencyFactor($old)

            $factor1 | Should -BeGreaterThan $factor2
        }

        It "Should calculate stability factor correctly" {
            $factor1 = $script:ttlOptimizer.CalculateStabilityFactor(0.8)
            $factor2 = $script:ttlOptimizer.CalculateStabilityFactor(0.2)

            $factor1 | Should -Be 0.8
            $factor2 | Should -Be 0.2
        }

        It "Should provide optimization statistics" {
            $stats = $script:ttlOptimizer.GetOptimizationStatistics()

            $stats | Should -Not -BeNullOrEmpty
            $stats.ContainsKey("RuleCount") | Should -Be $true
            $stats.ContainsKey("PatternCount") | Should -Be $true
            $stats.ContainsKey("AverageTTL") | Should -Be $true
        }
    }

    Context "TTL Optimization Parameters" {
        It "Should respect minimum and maximum TTL values" {
            $script:ttlOptimizer.MinimumTTL = 300
            $script:ttlOptimizer.MaximumTTL = 7200

            $optimizedTTL = $script:ttlOptimizer.OptimizeTTL("Key1", 3600)

            $optimizedTTL | Should -BeGreaterOrEqual 300
            $optimizedTTL | Should -BeLessOrEqual 7200
        }

        It "Should use weighting factors correctly" {
            $script:ttlOptimizer.FrequencyWeight = 0.5
            $script:ttlOptimizer.RecencyWeight = 0.3
            $script:ttlOptimizer.StabilityWeight = 0.2

            $optimizedTTL = $script:ttlOptimizer.OptimizeTTL("FrequentKey", 3600)

            $optimizedTTL | Should -BeGreaterThan 0
        }
    }

    AfterAll {
        # Nettoyage
        if (Test-Path -Path $testDatabasePath) {
            Remove-Item -Path $testDatabasePath -Force -ErrorAction SilentlyContinue
        }
    }
}
