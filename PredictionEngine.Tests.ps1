<#
.SYNOPSIS
    Tests unitaires pour le module PredictionEngine.
.DESCRIPTION
    Ce script contient des tests unitaires pour le module PredictionEngine
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

Describe "PredictionEngine Module Tests" {
    BeforeAll {
        # CrÃ©er un CacheManager et un UsageCollector pour les tests
        $script:baseCache = New-MockCacheManager -Name "TestCache" -CachePath $testCachePath
        $script:usageCollector = New-MockUsageCollector -DatabasePath $testDatabasePath -CacheName "TestCache"

        # CrÃ©er un DependencyManager pour les tests
        $script:dependencyManager = New-MockDependencyManager -BaseCache $script:baseCache -UsageCollector $script:usageCollector

        # Ajouter des dÃ©pendances de test
        $script:dependencyManager.AddDependency("SourceKey", "TargetKey1", 0.8)
        $script:dependencyManager.AddDependency("SourceKey", "TargetKey2", 0.6)
        $script:dependencyManager.AddDependency("SourceKey", "TargetKey3", 0.4)
        $script:dependencyManager.AddDependency("SourceKey", "TargetKey4", 0.2)

        # CrÃ©er un PredictionEngine pour les tests
        $script:predictionEngine = New-MockPredictionEngine -UsageCollector $script:usageCollector -DependencyManager $script:dependencyManager
    }

    Context "New-PredictionEngine Function" {
        It "Should create a new PredictionEngine object" {
            $engine = New-MockPredictionEngine -UsageCollector $script:usageCollector -DependencyManager $script:dependencyManager
            $engine | Should -Not -BeNullOrEmpty
            $engine.GetType().Name | Should -Be "PredictionEngine"
        }
    }

    Context "PredictionEngine Methods" {
        It "Should predict next keys based on dependencies" {
            $predictions = $script:predictionEngine.PredictNextKeys("SourceKey", 3)

            $predictions | Should -Not -BeNullOrEmpty
            $predictions.Count | Should -Be 3
            $predictions[0].Key | Should -Be "TargetKey1"
            $predictions[0].Confidence | Should -Be 0.8
            $predictions[1].Key | Should -Be "TargetKey2"
            $predictions[1].Confidence | Should -Be 0.6
            $predictions[2].Key | Should -Be "TargetKey3"
            $predictions[2].Confidence | Should -Be 0.4
        }

        It "Should respect minimum confidence threshold" {
            $script:predictionEngine.MinConfidence = 0.5
            $predictions = $script:predictionEngine.PredictNextKeys("SourceKey")

            $predictions | Should -Not -BeNullOrEmpty
            $predictions.Count | Should -Be 2
            $predictions[0].Key | Should -Be "TargetKey1"
            $predictions[1].Key | Should -Be "TargetKey2"
        }

        It "Should update predictions" {
            $script:predictionEngine.UpdatePredictions()

            # VÃ©rifier que la mise Ã  jour a Ã©tÃ© effectuÃ©e
            $script:predictionEngine.LastUpdate | Should -Not -BeNullOrEmpty
        }

        It "Should provide prediction statistics" {
            $stats = $script:predictionEngine.GetPredictionStatistics()

            $stats | Should -Not -BeNullOrEmpty
            $stats.ContainsKey("TotalPredictions") | Should -Be $true
            $stats.ContainsKey("HighConfidencePredictions") | Should -Be $true
            $stats.ContainsKey("MinConfidence") | Should -Be $true
        }
    }

    Context "Prediction Configuration" {
        It "Should allow configuration of maximum predictions" {
            $script:predictionEngine.MaxPredictions = 50
            $script:predictionEngine.MaxPredictions | Should -Be 50
        }

        It "Should allow configuration of minimum confidence" {
            $script:predictionEngine.MinConfidence = 0.4
            $script:predictionEngine.MinConfidence | Should -Be 0.4
        }
    }

    AfterAll {
        # Nettoyage
        if (Test-Path -Path $testDatabasePath) {
            Remove-Item -Path $testDatabasePath -Force -ErrorAction SilentlyContinue
        }
    }
}
