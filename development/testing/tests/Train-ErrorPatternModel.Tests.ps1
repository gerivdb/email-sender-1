BeforeAll {
    # Importer le module Ã  tester
    $global:scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\development\scripts\maintenance\error-learning\Train-ErrorPatternModel.ps1"
    $global:modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\development\scripts\maintenance\error-learning\ErrorPatternAnalyzer.psm1"

    # CrÃ©er un dossier temporaire pour les tests
    $global:testFolder = Join-Path -Path $TestDrive -ChildPath "ErrorModelTests"
    New-Item -Path $global:testFolder -ItemType Directory -Force | Out-Null

    # CrÃ©er une base de donnÃ©es de test
    $global:databasePath = Join-Path -Path $global:testFolder -ChildPath "test_error_database.json"
    $global:modelPath = Join-Path -Path $global:testFolder -ChildPath "test_error_model.xml"

    # Fonction pour crÃ©er une base de donnÃ©es de test
    function New-TestDatabase {
        param (
            [Parameter(Mandatory = $false)]
            [string]$DatabasePath = $global:databasePath,

            [Parameter(Mandatory = $false)]
            [int]$PatternCount = 10
        )

        # Charger le module ErrorPatternAnalyzer
        . $global:modulePath

        # Initialiser la base de donnÃ©es
        $script:ErrorDatabasePath = $DatabasePath
        Initialize-ErrorDatabase -DatabasePath $DatabasePath -Force

        # CrÃ©er des patterns de test
        for ($i = 0; $i -lt $PatternCount; $i++) {
            $isInedited = ($i % 2 -eq 0)
            $exceptionType = if ($i % 3 -eq 0) { "System.NullReferenceException" } elseif ($i % 3 -eq 1) { "System.IndexOutOfRangeException" } else { "System.ArgumentException" }
            $errorId = if ($i % 3 -eq 0) { "NullReference" } elseif ($i % 3 -eq 1) { "IndexOutOfRange" } else { "ArgumentError" }
            $scriptContext = "Test-Script$($i % 3).ps1"

            $pattern = @{
                Id               = [guid]::NewGuid().ToString()
                Name             = "Pattern-$i"
                Description      = "Test pattern $i"
                Features         = @{
                    ExceptionType  = $exceptionType
                    ErrorId        = $errorId
                    MessagePattern = "Test message pattern $i"
                    ScriptContext  = $scriptContext
                    LinePattern    = "Test line pattern $i"
                }
                FirstOccurrence  = (Get-Date).AddDays(-10).ToString("yyyy-MM-ddTHH:mm:ss")
                LastOccurrence   = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
                Occurrences      = $i + 1
                Examples         = @(
                    @{
                        Timestamp        = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
                        ErrorId          = $errorId
                        Exception        = $exceptionType
                        Message          = "Test error message $i"
                        ScriptName       = $scriptContext
                        ScriptLineNumber = 42
                        Line             = "Test line $i"
                        PositionMessage  = "At $scriptContext:42"
                        StackTrace       = "at <ScriptBlock>, ${scriptContext}: line 42"
                        Context          = "Test"
                        Source           = "Test"
                        Tags             = @("Test")
                        CategoryInfo     = "InvalidOperation"
                    }
                )
                IsInedited       = $isInedited
                ValidationStatus = if ($i % 3 -eq 0) { "Valid" } elseif ($i % 3 -eq 1) { "Invalid" } else { "Pending" }
                RelatedPatterns  = @()
            }

            $script:ErrorDatabase.Patterns += $pattern
        }

        # Ajouter des corrÃ©lations
        for ($i = 0; $i -lt $PatternCount - 1; $i++) {
            $correlation = @{
                PatternId1   = $script:ErrorDatabase.Patterns[$i].Id
                PatternId2   = $script:ErrorDatabase.Patterns[$i + 1].Id
                Similarity   = 0.7
                Relationship = "Similar"
                Timestamp    = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
            }

            $script:ErrorDatabase.Correlations += $correlation
        }

        # Sauvegarder la base de donnÃ©es
        Save-ErrorDatabase -DatabasePath $DatabasePath

        return $DatabasePath
    }
}

Describe "Train-ErrorPatternModel" {
    BeforeEach {
        # CrÃ©er une base de donnÃ©es de test
        New-TestDatabase -DatabasePath $global:databasePath -PatternCount 10
    }

    It "Extrait correctement les caractÃ©ristiques d'un pattern" {
        # Charger le script
        . $global:scriptPath -DatabasePath $global:databasePath -ModelPath $global:modelPath -TrainingIterations 1

        # Charger la base de donnÃ©es
        $database = Get-Content -Path $global:databasePath -Raw | ConvertFrom-Json

        # Extraire les caractÃ©ristiques d'un pattern
        $features = Get-PatternFeatures -Pattern $database.Patterns[0]

        $features | Should -Not -BeNullOrEmpty
        $features.ExceptionType | Should -Be $database.Patterns[0].Features.ExceptionType
        $features.ErrorId | Should -Be $database.Patterns[0].Features.ErrorId
        $features.MessagePattern | Should -Be $database.Patterns[0].Features.MessagePattern
        $features.ScriptContext | Should -Be $database.Patterns[0].Features.ScriptContext
        $features.LinePattern | Should -Be $database.Patterns[0].Features.LinePattern
        $features.Occurrences | Should -Be $database.Patterns[0].Occurrences
        $features.IsInedited | Should -Be ([int]$database.Patterns[0].IsInedited)
        $features.ValidationStatus | Should -Be $database.Patterns[0].ValidationStatus
    }

    It "Normalise correctement les caractÃ©ristiques" {
        # Charger le script
        . $global:scriptPath -DatabasePath $global:databasePath -ModelPath $global:modelPath -TrainingIterations 1

        # Charger la base de donnÃ©es
        $database = Get-Content -Path $global:databasePath -Raw | ConvertFrom-Json

        # Normaliser les caractÃ©ristiques
        $normalizedPatterns = ConvertTo-NormalizedFeatures -Patterns $database.Patterns

        $normalizedPatterns | Should -Not -BeNullOrEmpty
        $normalizedPatterns.Count | Should -Be $database.Patterns.Count

        # VÃ©rifier que les occurrences sont normalisÃ©es
        $maxOccurrences = ($database.Patterns | ForEach-Object { $_.Occurrences } | Measure-Object -Maximum).Maximum
        $normalizedPatterns[0].Features.Occurrences | Should -Be ($database.Patterns[0].Occurrences / $maxOccurrences)
    }

    It "Divise correctement les donnÃ©es en ensembles d'entraÃ®nement et de test" {
        # Charger le script
        . $global:scriptPath -DatabasePath $global:databasePath -ModelPath $global:modelPath -TrainingIterations 1

        # Charger la base de donnÃ©es
        $database = Get-Content -Path $global:databasePath -Raw | ConvertFrom-Json

        # Normaliser les caractÃ©ristiques
        $normalizedPatterns = ConvertTo-NormalizedFeatures -Patterns $database.Patterns

        # Diviser les donnÃ©es
        $dataSets = Split-TrainingData -Patterns $normalizedPatterns -TrainingRatio 0.8

        $dataSets | Should -Not -BeNullOrEmpty
        $dataSets.TrainingSet | Should -Not -BeNullOrEmpty
        $dataSets.TestSet | Should -Not -BeNullOrEmpty

        # VÃ©rifier que les ensembles ont la bonne taille
        $expectedTrainingSize = [Math]::Floor($normalizedPatterns.Count * 0.8)
        $dataSets.TrainingSet.Count | Should -Be $expectedTrainingSize
        $dataSets.TestSet.Count | Should -Be ($normalizedPatterns.Count - $expectedTrainingSize)
    }

    It "EntraÃ®ne correctement un modÃ¨le de classification" {
        # Charger le script
        . $global:scriptPath -DatabasePath $global:databasePath -ModelPath $global:modelPath -TrainingIterations 5

        # Charger la base de donnÃ©es
        $database = Get-Content -Path $global:databasePath -Raw | ConvertFrom-Json

        # Normaliser les caractÃ©ristiques
        $normalizedPatterns = ConvertTo-NormalizedFeatures -Patterns $database.Patterns

        # Diviser les donnÃ©es
        $dataSets = Split-TrainingData -Patterns $normalizedPatterns -TrainingRatio 0.8

        # EntraÃ®ner le modÃ¨le
        $model = Start-ModelTraining -TrainingSet $dataSets.TrainingSet -Iterations 5

        $model | Should -Not -BeNullOrEmpty
        $model.Weights | Should -Not -BeNullOrEmpty
        $model.Bias | Should -Not -BeNullOrEmpty
        $model.LearningRate | Should -Not -BeNullOrEmpty
        $model.Iterations | Should -Be 5
        $model.TrainingAccuracy | Should -BeGreaterThan 0
    }

    It "PrÃ©dit correctement la classe d'un pattern" {
        # Charger le script
        . $global:scriptPath -DatabasePath $global:databasePath -ModelPath $global:modelPath -TrainingIterations 5

        # Charger la base de donnÃ©es
        $database = Get-Content -Path $global:databasePath -Raw | ConvertFrom-Json

        # Normaliser les caractÃ©ristiques
        $normalizedPatterns = ConvertTo-NormalizedFeatures -Patterns $database.Patterns

        # Diviser les donnÃ©es
        $dataSets = Split-TrainingData -Patterns $normalizedPatterns -TrainingRatio 0.8

        # EntraÃ®ner le modÃ¨le
        $model = Start-ModelTraining -TrainingSet $dataSets.TrainingSet -Iterations 5

        # PrÃ©dire la classe d'un pattern
        $prediction = Get-PatternClass -Model $model -Features $dataSets.TestSet[0].Features

        $prediction | Should -BeOfType [double]
        $prediction | Should -BeGreaterThanOrEqual 0
        $prediction | Should -BeLessThanOrEqual 1
    }

    It "Ã‰value correctement un modÃ¨le" {
        # Charger le script
        . $global:scriptPath -DatabasePath $global:databasePath -ModelPath $global:modelPath -TrainingIterations 5

        # Charger la base de donnÃ©es
        $database = Get-Content -Path $global:databasePath -Raw | ConvertFrom-Json

        # Normaliser les caractÃ©ristiques
        $normalizedPatterns = ConvertTo-NormalizedFeatures -Patterns $database.Patterns

        # Diviser les donnÃ©es
        $dataSets = Split-TrainingData -Patterns $normalizedPatterns -TrainingRatio 0.8

        # EntraÃ®ner le modÃ¨le
        $model = Start-ModelTraining -TrainingSet $dataSets.TrainingSet -Iterations 5

        # Ã‰valuer le modÃ¨le
        $metrics = Test-ErrorModel -Model $model -TestSet $dataSets.TestSet

        $metrics | Should -Not -BeNullOrEmpty
        $metrics.Accuracy | Should -BeOfType [double]
        $metrics.Precision | Should -BeOfType [double]
        $metrics.Recall | Should -BeOfType [double]
        $metrics.F1Score | Should -BeOfType [double]
        $metrics.TruePositives | Should -BeOfType [int]
        $metrics.FalsePositives | Should -BeOfType [int]
        $metrics.TrueNegatives | Should -BeOfType [int]
        $metrics.FalseNegatives | Should -BeOfType [int]
    }

    It "Sauvegarde et charge correctement un modÃ¨le" {
        # Charger le script
        . $global:scriptPath -DatabasePath $global:databasePath -ModelPath $global:modelPath -TrainingIterations 5

        # Charger la base de donnÃ©es
        $database = Get-Content -Path $global:databasePath -Raw | ConvertFrom-Json

        # Normaliser les caractÃ©ristiques
        $normalizedPatterns = ConvertTo-NormalizedFeatures -Patterns $database.Patterns

        # Diviser les donnÃ©es
        $dataSets = Split-TrainingData -Patterns $normalizedPatterns -TrainingRatio 0.8

        # EntraÃ®ner le modÃ¨le
        $model = Start-ModelTraining -TrainingSet $dataSets.TrainingSet -Iterations 5

        # Sauvegarder le modÃ¨le
        Save-Model -Model $model -ModelPath $global:modelPath

        # VÃ©rifier que le fichier a Ã©tÃ© crÃ©Ã©
        Test-Path -Path $global:modelPath | Should -Be $true

        # Charger le modÃ¨le
        $loadedModel = Import-ErrorModel -ModelPath $global:modelPath

        $loadedModel | Should -Not -BeNullOrEmpty
        $loadedModel.Weights | Should -Not -BeNullOrEmpty
        $loadedModel.Bias | Should -Not -BeNullOrEmpty
        $loadedModel.LearningRate | Should -Not -BeNullOrEmpty
        $loadedModel.Iterations | Should -Be $model.Iterations
        $loadedModel.TrainingAccuracy | Should -Be $model.TrainingAccuracy
    }

    It "GÃ©nÃ¨re correctement un rapport d'entraÃ®nement" {
        # Charger le script
        . $global:scriptPath -DatabasePath $global:databasePath -ModelPath $global:modelPath -TrainingIterations 5

        # Charger la base de donnÃ©es
        $database = Get-Content -Path $global:databasePath -Raw | ConvertFrom-Json

        # Normaliser les caractÃ©ristiques
        $normalizedPatterns = ConvertTo-NormalizedFeatures -Patterns $database.Patterns

        # Diviser les donnÃ©es
        $dataSets = Split-TrainingData -Patterns $normalizedPatterns -TrainingRatio 0.8

        # EntraÃ®ner le modÃ¨le
        $model = Start-ModelTraining -TrainingSet $dataSets.TrainingSet -Iterations 5

        # Ã‰valuer le modÃ¨le
        $metrics = Test-ErrorModel -Model $model -TestSet $dataSets.TestSet

        # GÃ©nÃ©rer un rapport
        $reportPath = Join-Path -Path $global:testFolder -ChildPath "test_training_report.md"
        $result = New-TrainingReport -Model $model -Metrics $metrics -ReportPath $reportPath

        $result | Should -Be $reportPath
        Test-Path -Path $reportPath | Should -Be $true

        $reportContent = Get-Content -Path $reportPath -Raw
        $reportContent | Should -Match "Rapport d'entraÃ®nement du modÃ¨le de classification des patterns d'erreur"
        $reportContent | Should -Match "ParamÃ¨tres d'entraÃ®nement"
        $reportContent | Should -Match "MÃ©triques d'Ã©valuation"
    }
}

Describe "Train-ErrorPatternModel Integration" {
    BeforeAll {
        # CrÃ©er une base de donnÃ©es de test
        New-TestDatabase -DatabasePath $global:databasePath -PatternCount 20
    }

    It "ExÃ©cute correctement le script complet" {
        # ExÃ©cuter le script
        & $global:scriptPath -DatabasePath $global:databasePath -ModelPath $global:modelPath -TrainingIterations 10

        # VÃ©rifier que le modÃ¨le a Ã©tÃ© crÃ©Ã©
        Test-Path -Path $global:modelPath | Should -Be $true

        # VÃ©rifier que le rapport a Ã©tÃ© gÃ©nÃ©rÃ©
        $reportPath = Join-Path -Path (Split-Path -Parent $global:scriptPath) -ChildPath "training_report.md"
        Test-Path -Path $reportPath | Should -Be $true
    }
}
