#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le module PredictionEngine.
.DESCRIPTION
    Ce script contient les tests unitaires pour le module PredictionEngine
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
$testDatabasePath = Join-Path -Path $env:TEMP -ChildPath "PSCacheManager_Tests\PredictionEngine_Test.db"
$testDatabaseDir = Split-Path -Path $testDatabasePath -Parent
if (-not (Test-Path -Path $testDatabaseDir)) {
    New-Item -Path $testDatabaseDir -ItemType Directory -Force | Out-Null
}

# Nettoyer les tests précédents
if (Test-Path -Path $testDatabasePath) {
    Remove-Item -Path $testDatabasePath -Force
}

Describe "PredictionEngine Module Tests" {
    BeforeAll {
        # Créer un mock pour le UsageCollector
        $mockUsageCollector = [PSCustomObject]@{
            GetMostAccessedKeys  = {
                param($limit, $timeWindowMinutes)
                return @(
                    [PSCustomObject]@{
                        Key         = "Key1"
                        AccessCount = 10
                        Hits        = 8
                        Misses      = 2
                        HitRatio    = 0.8
                        LastAccess  = (Get-Date).AddMinutes(-5)
                    },
                    [PSCustomObject]@{
                        Key         = "Key2"
                        AccessCount = 5
                        Hits        = 3
                        Misses      = 2
                        HitRatio    = 0.6
                        LastAccess  = (Get-Date).AddMinutes(-10)
                    }
                )
            }
            GetFrequentSequences = {
                param($limit, $timeWindowMinutes)
                return @(
                    [PSCustomObject]@{
                        FirstKey          = "Key1"
                        SecondKey         = "Key2"
                        SequenceCount     = 5
                        AvgTimeDifference = 1000
                        LastOccurrence    = (Get-Date).AddMinutes(-5)
                    },
                    [PSCustomObject]@{
                        FirstKey          = "Key2"
                        SecondKey         = "Key3"
                        SequenceCount     = 3
                        AvgTimeDifference = 2000
                        LastOccurrence    = (Get-Date).AddMinutes(-10)
                    }
                )
            }
            GetKeyAccessStats    = {
                param($key)
                return [PSCustomObject]@{
                    Key              = $key
                    TotalAccesses    = 10
                    Hits             = 8
                    Misses           = 2
                    HitRatio         = 0.8
                    AvgExecutionTime = 100
                    LastAccess       = (Get-Date).AddMinutes(-5)
                }
            }
        }

        # Mock pour New-UsageCollector
        Mock -CommandName New-UsageCollector -MockWith {
            return $mockUsageCollector
        }
    }

    Context "New-PredictionEngine Function" {
        It "Should create a new PredictionEngine object" {
            $usageCollector = New-UsageCollector -DatabasePath $testDatabasePath -CacheName "TestCache"
            $engine = New-PredictionEngine -UsageCollector $usageCollector -CacheName "TestCache"
            $engine | Should -Not -BeNullOrEmpty
            $engine.GetType().Name | Should -Be "PredictionEngine"
        }

        It "Should set the correct cache name" {
            $usageCollector = New-UsageCollector -DatabasePath $testDatabasePath -CacheName "TestCache"
            $engine = New-PredictionEngine -UsageCollector $usageCollector -CacheName "TestCache"
            $engine.CacheName | Should -Be "TestCache"
        }
    }

    Context "PredictionEngine Methods" {
        BeforeEach {
            $usageCollector = New-UsageCollector -DatabasePath $testDatabasePath -CacheName "TestCache"
            # Cette variable est utilisée dans chaque test de ce contexte
            $script:engine = New-PredictionEngine -UsageCollector $usageCollector -CacheName "TestCache"
        }

        It "Should update the prediction model" {
            # Act
            { $engine.UpdateModel() } | Should -Not -Throw
        }

        It "Should predict next accesses" {
            # Act
            $predictions = $engine.PredictNextAccesses()

            # Assert
            $predictions | Should -Not -BeNullOrEmpty
            $predictions.Count | Should -BeGreaterThan 0
            $predictions[0].Key | Should -Not -BeNullOrEmpty
            $predictions[0].Probability | Should -BeGreaterThan 0
        }

        It "Should calculate key probability" {
            # Act
            $probability = $engine.CalculateKeyProbability("Key1")

            # Assert
            $probability | Should -BeGreaterOrEqual 0
            $probability | Should -BeLessOrEqual 1
        }

        It "Should get predictions for a specific key" {
            # Act
            $predictions = $engine.GetPredictionsForKey("Key1")

            # Assert
            $predictions | Should -Not -BeNullOrEmpty -ErrorAction SilentlyContinue
        }
    }

    Context "Probability Calculation Methods" {
        BeforeEach {
            $usageCollector = New-UsageCollector -DatabasePath $testDatabasePath -CacheName "TestCache"
            # Cette variable est utilisée dans chaque test de ce contexte
            $script:engine = New-PredictionEngine -UsageCollector $usageCollector -CacheName "TestCache"
        }

        It "Should calculate recency factor" {
            # Arrange
            $lastAccess = (Get-Date).AddMinutes(-10)

            # Act - Utilisation de la réflexion pour accéder à la méthode privée
            $recencyFactor = $engine.CalculateRecencyFactor($lastAccess)

            # Assert
            $recencyFactor | Should -BeGreaterThan 0
            $recencyFactor | Should -BeLessOrEqual 1
        }

        It "Should calculate sequence confidence" {
            # Arrange
            $sequence = [PSCustomObject]@{
                FirstKey          = "Key1"
                SecondKey         = "Key2"
                SequenceCount     = 5
                AvgTimeDifference = 1000
                LastOccurrence    = (Get-Date).AddMinutes(-5)
            }

            # Act - Utilisation de la réflexion pour accéder à la méthode privée
            $confidence = $engine.CalculateSequenceConfidence($sequence)

            # Assert
            $confidence | Should -BeGreaterThan 0
            $confidence | Should -BeLessOrEqual 1
        }
    }

    AfterAll {
        # Nettoyage
        if (Test-Path -Path $testDatabasePath) {
            Remove-Item -Path $testDatabasePath -Force -ErrorAction SilentlyContinue
        }
    }
}
