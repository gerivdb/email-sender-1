BeforeAll {
    # Importer le module à tester
    $global:scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\scripts\maintenance\error-learning\Train-ErrorPatternModel.ps1"
    $global:modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\scripts\maintenance\error-learning\ErrorPatternAnalyzer.psm1"

    # Créer un dossier temporaire pour les tests
    $global:testFolder = Join-Path -Path $TestDrive -ChildPath "ErrorModelTests"
    New-Item -Path $global:testFolder -ItemType Directory -Force | Out-Null

    # Créer une base de données de test
    $global:databasePath = Join-Path -Path $global:testFolder -ChildPath "test_error_database.json"
    $global:modelPath = Join-Path -Path $global:testFolder -ChildPath "test_error_model.xml"

    # Fonction pour créer une base de données de test
    function New-TestDatabase {
        param (
            [Parameter(Mandatory = $false)]
            [string]$DatabasePath = $global:databasePath,

            [Parameter(Mandatory = $false)]
            [int]$PatternCount = 10
        )

        # Charger le module ErrorPatternAnalyzer
        . $global:modulePath

        # Initialiser la base de données
        $script:ErrorDatabasePath = $DatabasePath
        Initialize-ErrorDatabase -DatabasePath $DatabasePath -Force

        # Créer des patterns de test
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

        # Ajouter des corrélations
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

        # Sauvegarder la base de données
        Save-ErrorDatabase -DatabasePath $DatabasePath

        return $DatabasePath
    }
}

Describe "Train-ErrorPatternModel" {
    BeforeEach {
        # Créer une base de données de test
        New-TestDatabase -DatabasePath $global:databasePath -PatternCount 10
    }

    It "Extrait correctement les caractéristiques d'un pattern" {
        # Charger le script
        . $global:scriptPath -DatabasePath $global:databasePath -ModelPath $global:modelPath -TrainingIterations 1

        # Charger la base de données
        $database = Get-Content -Path $global:databasePath -Raw | ConvertFrom-Json

        # Extraire les caractéristiques d'un pattern
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

    It "Normalise correctement les caractéristiques" {
        # Charger le script
        . $global:scriptPath -DatabasePath $global:databasePath -ModelPath $global:modelPath -TrainingIterations 1

        # Charger la base de données
        $database = Get-Content -Path $global:databasePath -Raw | ConvertFrom-Json

        # Normaliser les caractéristiques
        $normalizedPatterns = ConvertTo-NormalizedFeatures -Patterns $database.Patterns

        $normalizedPatterns | Should -Not -BeNullOrEmpty
        $normalizedPatterns.Count | Should -Be $database.Patterns.Count

        # Vérifier que les occurrences sont normalisées
        $maxOccurrences = ($database.Patterns | ForEach-Object { $_.Occurrences } | Measure-Object -Maximum).Maximum
        $normalizedPatterns[0].Features.Occurrences | Should -Be ($database.Patterns[0].Occurrences / $maxOccurrences)
    }

    It "Divise correctement les données en ensembles d'entraînement et de test" {
        # Charger le script
        . $global:scriptPath -DatabasePath $global:databasePath -ModelPath $global:modelPath -TrainingIterations 1

        # Charger la base de données
        $database = Get-Content -Path $global:databasePath -Raw | ConvertFrom-Json

        # Normaliser les caractéristiques
        $normalizedPatterns = ConvertTo-NormalizedFeatures -Patterns $database.Patterns

        # Diviser les données
        $dataSets = Split-TrainingData -Patterns $normalizedPatterns -TrainingRatio 0.8

        $dataSets | Should -Not -BeNullOrEmpty
        $dataSets.TrainingSet | Should -Not -BeNullOrEmpty
        $dataSets.TestSet | Should -Not -BeNullOrEmpty

        # Vérifier que les ensembles ont la bonne taille
        $expectedTrainingSize = [Math]::Floor($normalizedPatterns.Count * 0.8)
        $dataSets.TrainingSet.Count | Should -Be $expectedTrainingSize
        $dataSets.TestSet.Count | Should -Be ($normalizedPatterns.Count - $expectedTrainingSize)
    }

    It "Entraîne correctement un modèle de classification" {
        # Charger le script
        . $global:scriptPath -DatabasePath $global:databasePath -ModelPath $global:modelPath -TrainingIterations 5

        # Charger la base de données
        $database = Get-Content -Path $global:databasePath -Raw | ConvertFrom-Json

        # Normaliser les caractéristiques
        $normalizedPatterns = ConvertTo-NormalizedFeatures -Patterns $database.Patterns

        # Diviser les données
        $dataSets = Split-TrainingData -Patterns $normalizedPatterns -TrainingRatio 0.8

        # Entraîner le modèle
        $model = Start-ModelTraining -TrainingSet $dataSets.TrainingSet -Iterations 5

        $model | Should -Not -BeNullOrEmpty
        $model.Weights | Should -Not -BeNullOrEmpty
        $model.Bias | Should -Not -BeNullOrEmpty
        $model.LearningRate | Should -Not -BeNullOrEmpty
        $model.Iterations | Should -Be 5
        $model.TrainingAccuracy | Should -BeGreaterThan 0
    }

    It "Prédit correctement la classe d'un pattern" {
        # Charger le script
        . $global:scriptPath -DatabasePath $global:databasePath -ModelPath $global:modelPath -TrainingIterations 5

        # Charger la base de données
        $database = Get-Content -Path $global:databasePath -Raw | ConvertFrom-Json

        # Normaliser les caractéristiques
        $normalizedPatterns = ConvertTo-NormalizedFeatures -Patterns $database.Patterns

        # Diviser les données
        $dataSets = Split-TrainingData -Patterns $normalizedPatterns -TrainingRatio 0.8

        # Entraîner le modèle
        $model = Start-ModelTraining -TrainingSet $dataSets.TrainingSet -Iterations 5

        # Prédire la classe d'un pattern
        $prediction = Get-PatternClass -Model $model -Features $dataSets.TestSet[0].Features

        $prediction | Should -BeOfType [double]
        $prediction | Should -BeGreaterThanOrEqual 0
        $prediction | Should -BeLessThanOrEqual 1
    }

    It "Évalue correctement un modèle" {
        # Charger le script
        . $global:scriptPath -DatabasePath $global:databasePath -ModelPath $global:modelPath -TrainingIterations 5

        # Charger la base de données
        $database = Get-Content -Path $global:databasePath -Raw | ConvertFrom-Json

        # Normaliser les caractéristiques
        $normalizedPatterns = ConvertTo-NormalizedFeatures -Patterns $database.Patterns

        # Diviser les données
        $dataSets = Split-TrainingData -Patterns $normalizedPatterns -TrainingRatio 0.8

        # Entraîner le modèle
        $model = Start-ModelTraining -TrainingSet $dataSets.TrainingSet -Iterations 5

        # Évaluer le modèle
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

    It "Sauvegarde et charge correctement un modèle" {
        # Charger le script
        . $global:scriptPath -DatabasePath $global:databasePath -ModelPath $global:modelPath -TrainingIterations 5

        # Charger la base de données
        $database = Get-Content -Path $global:databasePath -Raw | ConvertFrom-Json

        # Normaliser les caractéristiques
        $normalizedPatterns = ConvertTo-NormalizedFeatures -Patterns $database.Patterns

        # Diviser les données
        $dataSets = Split-TrainingData -Patterns $normalizedPatterns -TrainingRatio 0.8

        # Entraîner le modèle
        $model = Start-ModelTraining -TrainingSet $dataSets.TrainingSet -Iterations 5

        # Sauvegarder le modèle
        Save-Model -Model $model -ModelPath $global:modelPath

        # Vérifier que le fichier a été créé
        Test-Path -Path $global:modelPath | Should -Be $true

        # Charger le modèle
        $loadedModel = Import-ErrorModel -ModelPath $global:modelPath

        $loadedModel | Should -Not -BeNullOrEmpty
        $loadedModel.Weights | Should -Not -BeNullOrEmpty
        $loadedModel.Bias | Should -Not -BeNullOrEmpty
        $loadedModel.LearningRate | Should -Not -BeNullOrEmpty
        $loadedModel.Iterations | Should -Be $model.Iterations
        $loadedModel.TrainingAccuracy | Should -Be $model.TrainingAccuracy
    }

    It "Génère correctement un rapport d'entraînement" {
        # Charger le script
        . $global:scriptPath -DatabasePath $global:databasePath -ModelPath $global:modelPath -TrainingIterations 5

        # Charger la base de données
        $database = Get-Content -Path $global:databasePath -Raw | ConvertFrom-Json

        # Normaliser les caractéristiques
        $normalizedPatterns = ConvertTo-NormalizedFeatures -Patterns $database.Patterns

        # Diviser les données
        $dataSets = Split-TrainingData -Patterns $normalizedPatterns -TrainingRatio 0.8

        # Entraîner le modèle
        $model = Start-ModelTraining -TrainingSet $dataSets.TrainingSet -Iterations 5

        # Évaluer le modèle
        $metrics = Test-ErrorModel -Model $model -TestSet $dataSets.TestSet

        # Générer un rapport
        $reportPath = Join-Path -Path $global:testFolder -ChildPath "test_training_report.md"
        $result = New-TrainingReport -Model $model -Metrics $metrics -ReportPath $reportPath

        $result | Should -Be $reportPath
        Test-Path -Path $reportPath | Should -Be $true

        $reportContent = Get-Content -Path $reportPath -Raw
        $reportContent | Should -Match "Rapport d'entraînement du modèle de classification des patterns d'erreur"
        $reportContent | Should -Match "Paramètres d'entraînement"
        $reportContent | Should -Match "Métriques d'évaluation"
    }
}

Describe "Train-ErrorPatternModel Integration" {
    BeforeAll {
        # Créer une base de données de test
        New-TestDatabase -DatabasePath $global:databasePath -PatternCount 20
    }

    It "Exécute correctement le script complet" {
        # Exécuter le script
        & $global:scriptPath -DatabasePath $global:databasePath -ModelPath $global:modelPath -TrainingIterations 10

        # Vérifier que le modèle a été créé
        Test-Path -Path $global:modelPath | Should -Be $true

        # Vérifier que le rapport a été généré
        $reportPath = Join-Path -Path (Split-Path -Parent $global:scriptPath) -ChildPath "training_report.md"
        Test-Path -Path $reportPath | Should -Be $true
    }
}
