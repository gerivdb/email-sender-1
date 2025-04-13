#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le module TTLOptimizer.
.DESCRIPTION
    Ce script contient les tests unitaires pour le module TTLOptimizer
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

# Importer les modules à tester
$usageCollectorPath = Join-Path -Path $PSScriptRoot -ChildPath "..\UsageCollector.psm1"
$ttlOptimizerPath = Join-Path -Path $PSScriptRoot -ChildPath "..\TTLOptimizer.psm1"
Import-Module $usageCollectorPath -Force
Import-Module $ttlOptimizerPath -Force

# Créer un chemin temporaire pour la base de données de test
$testDatabasePath = Join-Path -Path $env:TEMP -ChildPath "PSCacheManager_Tests\TTLOptimizer_Test.db"
$testDatabaseDir = Split-Path -Path $testDatabasePath -Parent
if (-not (Test-Path -Path $testDatabaseDir)) {
    New-Item -Path $testDatabaseDir -ItemType Directory -Force | Out-Null
}

# Nettoyer les tests précédents
if (Test-Path -Path $testDatabasePath) {
    Remove-Item -Path $testDatabasePath -Force
}

Describe "TTLOptimizer Module Tests" {
    BeforeAll {
        # Créer un mock pour le UsageCollector
        $script:mockUsageCollector = [PSCustomObject]@{
            GetMostAccessedKeys = {
                param($limit, $timeWindowMinutes)
                return @(
                    [PSCustomObject]@{
                        Key = "Key1"
                        AccessCount = 10
                        Hits = 8
                        Misses = 2
                        HitRatio = 0.8
                        LastAccess = (Get-Date).AddMinutes(-5)
                    },
                    [PSCustomObject]@{
                        Key = "Key2"
                        AccessCount = 5
                        Hits = 3
                        Misses = 2
                        HitRatio = 0.6
                        LastAccess = (Get-Date).AddMinutes(-10)
                    }
                )
            }
            GetKeyAccessStats = {
                param($key)
                return [PSCustomObject]@{
                    Key = $key
                    TotalAccesses = 10
                    Hits = 8
                    Misses = 2
                    HitRatio = 0.8
                    AvgExecutionTime = 100
                    LastAccess = (Get-Date).AddMinutes(-5)
                }
            }
        }
        
        # Créer un mock pour le CacheManager
        $script:mockCacheManager = [PSCustomObject]@{
            DefaultTTLSeconds = 3600
            Contains = { param($key) return $false }
        }
        
        # Mock pour New-UsageCollector
        Mock -CommandName New-UsageCollector -MockWith {
            return $mockUsageCollector
        }
    }
    
    Context "New-TTLOptimizer Function" {
        It "Should create a new TTLOptimizer object" {
            $optimizer = New-TTLOptimizer -BaseCache $mockCacheManager -UsageCollector $mockUsageCollector
            $optimizer | Should -Not -BeNullOrEmpty
            $optimizer.GetType().Name | Should -Be "TTLOptimizer"
        }
        
        It "Should set the correct default TTL range" {
            $optimizer = New-TTLOptimizer -BaseCache $mockCacheManager -UsageCollector $mockUsageCollector
            $optimizer.MinimumTTL | Should -BeGreaterThan 0
            $optimizer.MaximumTTL | Should -BeGreaterThan $optimizer.MinimumTTL
        }
    }
    
    Context "Set-TTLOptimizerParameters Function" {
        It "Should update TTL optimizer parameters" {
            # Arrange
            $optimizer = New-TTLOptimizer -BaseCache $mockCacheManager -UsageCollector $mockUsageCollector
            $newMinTTL = 300
            $newMaxTTL = 43200
            
            # Act
            $result = Set-TTLOptimizerParameters -TTLOptimizer $optimizer -MinimumTTL $newMinTTL -MaximumTTL $newMaxTTL
            
            # Assert
            $result | Should -Be $true
            $optimizer.MinimumTTL | Should -Be $newMinTTL
            $optimizer.MaximumTTL | Should -Be $newMaxTTL
        }
        
        It "Should update weight parameters" {
            # Arrange
            $optimizer = New-TTLOptimizer -BaseCache $mockCacheManager -UsageCollector $mockUsageCollector
            $frequencyWeight = 0.6
            $recencyWeight = 0.3
            $stabilityWeight = 0.1
            
            # Act
            $result = Set-TTLOptimizerParameters -TTLOptimizer $optimizer `
                -FrequencyWeight $frequencyWeight `
                -RecencyWeight $recencyWeight `
                -StabilityWeight $stabilityWeight
            
            # Assert
            $result | Should -Be $true
            $optimizer.FrequencyWeight | Should -Be $frequencyWeight
            $optimizer.RecencyWeight | Should -Be $recencyWeight
            $optimizer.StabilityWeight | Should -Be $stabilityWeight
        }
    }
    
    Context "TTLOptimizer Methods" {
        BeforeEach {
            # Cette variable est utilisée dans chaque test de ce contexte
            $script:optimizer = New-TTLOptimizer -BaseCache $mockCacheManager -UsageCollector $mockUsageCollector
        }
        
        It "Should optimize TTL for a key" {
            # Arrange
            $key = "TestKey"
            $currentTTL = 3600
            
            # Act
            $optimizedTTL = $optimizer.OptimizeTTL($key, $currentTTL)
            
            # Assert
            $optimizedTTL | Should -BeGreaterOrEqual $optimizer.MinimumTTL
            $optimizedTTL | Should -BeLessOrEqual $optimizer.MaximumTTL
        }
        
        It "Should calculate optimal TTL based on key stats" {
            # Arrange
            $keyStats = [PSCustomObject]@{
                Key = "TestKey"
                TotalAccesses = 10
                Hits = 8
                Misses = 2
                HitRatio = 0.8
                AvgExecutionTime = 100
                LastAccess = (Get-Date).AddMinutes(-5)
            }
            $currentTTL = 3600
            
            # Act
            $optimizedTTL = $optimizer.CalculateOptimalTTL($keyStats, $currentTTL)
            
            # Assert
            $optimizedTTL | Should -BeGreaterOrEqual $optimizer.MinimumTTL
            $optimizedTTL | Should -BeLessOrEqual $optimizer.MaximumTTL
        }
        
        It "Should update TTL rules" {
            # Act
            { $optimizer.UpdateTTLRules() } | Should -Not -Throw
        }
        
        It "Should detect key patterns" {
            # Arrange
            $keys = @(
                "User:123",
                "User:456",
                "Config:App:Setting",
                "Data:2023-04-12:Stats"
            )
            
            # Act & Assert
            foreach ($key in $keys) {
                $pattern = $optimizer.DetectKeyPattern($key)
                $pattern | Should -Not -BeNullOrEmpty
                $pattern | Should -Match "\*"  # Le pattern devrait contenir un caractère générique
            }
        }
        
        It "Should get optimization statistics" {
            # Act
            $stats = $optimizer.GetOptimizationStatistics()
            
            # Assert
            $stats | Should -Not -BeNullOrEmpty
            $stats.RuleCount | Should -BeGreaterOrEqual 0
            $stats.LastRuleUpdate | Should -Not -BeNullOrEmpty
        }
    }
    
    AfterAll {
        # Nettoyage
        if (Test-Path -Path $testDatabasePath) {
            Remove-Item -Path $testDatabasePath -Force -ErrorAction SilentlyContinue
        }
    }
}
