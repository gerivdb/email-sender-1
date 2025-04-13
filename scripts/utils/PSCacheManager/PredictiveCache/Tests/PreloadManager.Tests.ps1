#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le module PreloadManager.
.DESCRIPTION
    Ce script contient les tests unitaires pour le module PreloadManager
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
$predictionEnginePath = Join-Path -Path $PSScriptRoot -ChildPath "..\PredictionEngine.psm1"
$preloadManagerPath = Join-Path -Path $PSScriptRoot -ChildPath "..\PreloadManager.psm1"
Import-Module $predictionEnginePath -Force
Import-Module $preloadManagerPath -Force

Describe "PreloadManager Module Tests" {
    BeforeAll {
        # Créer un mock pour le CacheManager
        $script:mockCacheManager = [PSCustomObject]@{
            Set = { param($key, $value) }
            Contains = { param($key) return $false }
            DefaultTTLSeconds = 3600
        }
        
        # Créer un mock pour le PredictionEngine
        $script:mockPredictionEngine = [PSCustomObject]@{
            PredictNextAccesses = {
                return @(
                    [PSCustomObject]@{
                        Key = "Key1"
                        Probability = 0.8
                        Source = "FrequencyAnalysis"
                    },
                    [PSCustomObject]@{
                        Key = "Key2"
                        Probability = 0.6
                        Source = "SequenceAnalysis"
                    }
                )
            }
        }
    }
    
    Context "New-PreloadManager Function" {
        It "Should create a new PreloadManager object" {
            $manager = New-PreloadManager -BaseCache $mockCacheManager -PredictionEngine $mockPredictionEngine
            $manager | Should -Not -BeNullOrEmpty
            $manager.GetType().Name | Should -Be "PreloadManager"
        }
    }
    
    Context "Register-PreloadGenerator Function" {
        It "Should register a generator for a key pattern" {
            # Arrange
            $manager = New-PreloadManager -BaseCache $mockCacheManager -PredictionEngine $mockPredictionEngine
            $keyPattern = "User:*"
            $generator = { return "User Data" }
            
            # Act
            $result = Register-PreloadGenerator -PreloadManager $manager -KeyPattern $keyPattern -Generator $generator
            
            # Assert
            $result | Should -Be $true
        }
    }
    
    Context "PreloadManager Methods" {
        BeforeEach {
            # Cette variable est utilisée dans chaque test de ce contexte
            $script:manager = New-PreloadManager -BaseCache $mockCacheManager -PredictionEngine $mockPredictionEngine
            $script:manager.RegisterGenerator("User:*", { return "User Data" })
            $script:manager.RegisterGenerator("Product:*", { return "Product Data" })
        }
        
        It "Should find a generator for a key" {
            # Arrange
            $key = "User:123"
            
            # Act - Utilisation de la réflexion pour accéder à la méthode privée
            $generator = $manager.FindGenerator($key)
            
            # Assert
            $generator | Should -Not -BeNullOrEmpty
        }
        
        It "Should check if a key is a preload candidate" {
            # Arrange
            $key = "User:123"
            $manager.PreloadedKeys[$key] = $true
            
            # Act
            $isCandidate = $manager.IsPreloadCandidate($key)
            
            # Assert
            $isCandidate | Should -Be $true
        }
        
        It "Should preload keys" {
            # Arrange
            $keys = @("User:123", "Product:456")
            
            # Act
            { $manager.PreloadKeys($keys) } | Should -Not -Throw
        }
        
        It "Should check system load" {
            # Act
            $isUnderLoad = $manager.IsSystemUnderHeavyLoad()
            
            # Assert
            $isUnderLoad | Should -BeOfType [bool]
        }
        
        It "Should optimize preload strategy" {
            # Act
            { $manager.OptimizePreloadStrategy() } | Should -Not -Throw
        }
        
        It "Should get preload statistics" {
            # Act
            $stats = $manager.GetPreloadStatistics()
            
            # Assert
            $stats | Should -Not -BeNullOrEmpty
            $stats.TotalPreloads | Should -BeGreaterOrEqual 0
            $stats.MaxConcurrentPreloads | Should -BeGreaterThan 0
        }
    }
}
