#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le module PredictiveCache.
.DESCRIPTION
    Ce script contient les tests unitaires pour le module principal PredictiveCache
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

# Créer un chemin temporaire pour les tests
$testCachePath = Join-Path -Path $env:TEMP -ChildPath "PSCacheManager_Tests\PredictiveCache_Test"
$testDatabasePath = Join-Path -Path $env:TEMP -ChildPath "PSCacheManager_Tests\PredictiveCache_Test.db"
$testDir = Split-Path -Path $testCachePath -Parent
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Nettoyer les tests précédents
if (Test-Path -Path $testCachePath) {
    Remove-Item -Path $testCachePath -Recurse -Force
}
if (Test-Path -Path $testDatabasePath) {
    Remove-Item -Path $testDatabasePath -Force
}

Describe "PredictiveCache Module Tests" {
    BeforeAll {
        # Mocks pour les dépendances
        Mock -CommandName New-UsageCollector -MockWith {
            return [PSCustomObject]@{
                RecordAccess         = { param($key, $hit) }
                RecordSet            = { param($key, $value, $ttl) }
                RecordEviction       = { param($key) }
                GetMostAccessedKeys  = { param($limit, $timeWindow) return @() }
                GetFrequentSequences = { param($limit, $timeWindow) return @() }
                GetKeyAccessStats    = { param($key) return $null }
                Close                = { }
            }
        }

        Mock -CommandName New-PredictionEngine -MockWith {
            return [PSCustomObject]@{
                UpdateModel             = { }
                PredictNextAccesses     = { return @() }
                CalculateKeyProbability = { param($key) return 0.5 }
                GetPredictionsForKey    = { param($key) return @() }
            }
        }

        Mock -CommandName New-PreloadManager -MockWith {
            return [PSCustomObject]@{
                RegisterGenerator       = { param($keyPattern, $generator) }
                IsPreloadCandidate      = { param($key) return $false }
                PreloadKeys             = { param($keys) }
                PreloadInBackground     = { param($key, $generator) }
                OptimizePreloadStrategy = { }
                GetPreloadStatistics    = {
                    return [PSCustomObject]@{
                        TotalPreloads         = 0
                        SuccessfulPreloads    = 0
                        SuccessRate           = 0
                        AveragePreloadTime    = 0
                        MaxConcurrentPreloads = 3
                        ResourceThreshold     = 0.7
                    }
                }
            }
        }

        Mock -CommandName New-TTLOptimizer -MockWith {
            return [PSCustomObject]@{
                OptimizeTTL               = { param($key, $currentTTL) return $currentTTL }
                UpdateTTLRules            = { }
                GetOptimizationStatistics = {
                    return [PSCustomObject]@{
                        RuleCount      = 0
                        PatternCount   = 0
                        AverageTTL     = 3600
                        MinimumTTL     = 60
                        MaximumTTL     = 86400
                        LastRuleUpdate = (Get-Date)
                    }
                }
            }
        }

        Mock -CommandName New-DependencyManager -MockWith {
            return [PSCustomObject]@{
                AddDependency               = { param($sourceKey, $targetKey, $strength) }
                RemoveDependency            = { param($sourceKey, $targetKey) }
                GetDependencies             = { param($key) return @{} }
                GetDependents               = { param($key) return @{} }
                DetectDependencies          = { }
                InvalidateDependents        = { param($key) }
                PreloadDependencies         = { param($key, $preloadManager) }
                CleanupObsoleteDependencies = { }
                GetDependencyStatistics     = {
                    return [PSCustomObject]@{
                        TotalSources      = 0
                        TotalTargets      = 0
                        TotalDependencies = 0
                        AverageStrength   = 0
                        AutoDetectEnabled = $true
                    }
                }
            }
        }
    }

    Context "New-PredictiveCache Function" {
        It "Should create a new PredictiveCache object" {
            $cache = New-PredictiveCache -name "TestCache" -UsageDatabase $testDatabasePath -CachePath $testCachePath
            $cache | Should -Not -BeNullOrEmpty
            $cache.Name | Should -Be "TestCache"
        }

        It "Should set the correct database path" {
            $cache = New-PredictiveCache -name "TestCache" -UsageDatabase $testDatabasePath -CachePath $testCachePath
            $cache.UsageDatabasePath | Should -Be $testDatabasePath
        }

        It "Should set the correct cache path" {
            $cache = New-PredictiveCache -name "TestCache" -UsageDatabase $testDatabasePath -CachePath $testCachePath
            $cache.BaseCache.CachePath | Should -Be $testCachePath
        }
    }

    Context "Set-PredictiveCacheOptions Function" {
        It "Should update cache options" {
            # Arrange
            $cache = New-PredictiveCache -name "TestCache" -UsageDatabase $testDatabasePath -CachePath $testCachePath

            # Act
            $result = Set-PredictiveCacheOptions -Cache $cache -PreloadEnabled $true -AdaptiveTTL $true -DependencyTracking $true

            # Assert
            $result | Should -Be $true
            $cache.PreloadEnabled | Should -Be $true
            $cache.AdaptiveTTLEnabled | Should -Be $true
            $cache.DependencyTrackingEnabled | Should -Be $true
        }
    }

    Context "Optimize-PredictiveCache Function" {
        It "Should optimize the cache" {
            # Arrange
            $cache = New-PredictiveCache -name "TestCache" -UsageDatabase $testDatabasePath -CachePath $testCachePath

            # Act
            $result = Optimize-PredictiveCache -Cache $cache

            # Assert
            $result | Should -Be $true
        }
    }

    Context "Get-PredictiveCacheStatistics Function" {
        It "Should get cache statistics" {
            # Arrange
            $cache = New-PredictiveCache -name "TestCache" -UsageDatabase $testDatabasePath -CachePath $testCachePath

            # Act
            $stats = Get-PredictiveCacheStatistics -Cache $cache

            # Assert
            $stats | Should -Not -BeNullOrEmpty
            $stats.BaseCache | Should -Not -BeNullOrEmpty
            $stats.PredictionHits | Should -BeGreaterOrEqual 0
            $stats.PredictionMisses | Should -BeGreaterOrEqual 0
        }
    }

    Context "PredictiveCache Methods" {
        BeforeEach {
            # Cette variable est utilisée dans chaque test de ce contexte
            $script:cache = New-PredictiveCache -Name "TestCache" -UsageDatabase $testDatabasePath -CachePath $testCachePath
        }

        It "Should trigger preload" {
            # Act
            { $cache.TriggerPreload() } | Should -Not -Throw
        }

        It "Should handle cache access" {
            # Arrange
            $key = "TestKey"
            $value = "TestValue"

            # Act
            { $cache.BaseCache.Set($key, $value) } | Should -Not -Throw
            { $cache.BaseCache.Get($key) } | Should -Not -Throw
        }
    }

    AfterAll {
        # Nettoyage
        if (Test-Path -Path $testCachePath) {
            Remove-Item -Path $testCachePath -Recurse -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path -Path $testDatabasePath) {
            Remove-Item -Path $testDatabasePath -Force -ErrorAction SilentlyContinue
        }
    }
}
