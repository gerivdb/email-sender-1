BeforeAll {
    # Importer le module à tester
    $global:scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\scripts\maintenance\error-learning\Predict-ErrorCascades.ps1"
    $global:modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\scripts\maintenance\error-learning\ErrorPatternAnalyzer.psm1"

    # Créer un dossier temporaire pour les tests
    $global:testFolder = Join-Path -Path $TestDrive -ChildPath "ErrorCascadeTests"
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

    # Fonction pour créer un modèle de test
    function New-TestModel {
        param (
            [Parameter(Mandatory = $false)]
            [string]$ModelPath = $global:modelPath
        )

        # Créer un modèle de test
        $model = @{
            Weights          = @{
                ExceptionType  = @{
                    "System.NullReferenceException"   = 0.8
                    "System.IndexOutOfRangeException" = 0.6
                    "System.ArgumentException"        = 0.4
                }
                ErrorId        = @{
                    "NullReference"   = 0.8
                    "IndexOutOfRange" = 0.6
                    "ArgumentError"   = 0.4
                }
                MessagePattern = @{}
                ScriptContext  = @{
                    "Test-Script0.ps1" = 0.8
                    "Test-Script1.ps1" = 0.6
                    "Test-Script2.ps1" = 0.4
                }
                LinePattern    = @{}
                Occurrences    = 0.5
            }
            Bias             = 0.1
            LearningRate     = 0.01
            Iterations       = 10
            TrainingAccuracy = 0.8
        }

        # Sauvegarder le modèle
        $xmlWriter = New-Object System.Xml.XmlTextWriter($ModelPath, [System.Text.Encoding]::UTF8)
        $xmlWriter.Formatting = [System.Xml.Formatting]::Indented
        $xmlWriter.Indentation = 4

        $xmlWriter.WriteStartDocument()
        $xmlWriter.WriteStartElement("ErrorPatternModel")

        # Écrire les métadonnées
        $xmlWriter.WriteStartElement("Metadata")
        $xmlWriter.WriteElementString("CreatedAt", (Get-Date -Format "yyyy-MM-ddTHH:mm:ss"))
        $xmlWriter.WriteElementString("Iterations", $model.Iterations.ToString())
        $xmlWriter.WriteElementString("LearningRate", $model.LearningRate.ToString())
        $xmlWriter.WriteElementString("TrainingAccuracy", $model.TrainingAccuracy.ToString())
        $xmlWriter.WriteEndElement() # Metadata

        # Écrire les poids
        $xmlWriter.WriteStartElement("Weights")

        # Écrire le biais
        $xmlWriter.WriteElementString("Bias", $model.Bias.ToString())

        # Écrire les poids numériques
        $xmlWriter.WriteElementString("Occurrences", $model.Weights.Occurrences.ToString())

        # Écrire les poids catégoriels
        $xmlWriter.WriteStartElement("ExceptionTypes")
        foreach ($key in $model.Weights.ExceptionType.Keys) {
            $xmlWriter.WriteStartElement("ExceptionType")
            $xmlWriter.WriteAttributeString("name", $key)
            $xmlWriter.WriteAttributeString("weight", $model.Weights.ExceptionType[$key].ToString())
            $xmlWriter.WriteEndElement() # ExceptionType
        }
        $xmlWriter.WriteEndElement() # ExceptionTypes

        $xmlWriter.WriteStartElement("ErrorIds")
        foreach ($key in $model.Weights.ErrorId.Keys) {
            $xmlWriter.WriteStartElement("ErrorId")
            $xmlWriter.WriteAttributeString("name", $key)
            $xmlWriter.WriteAttributeString("weight", $model.Weights.ErrorId[$key].ToString())
            $xmlWriter.WriteEndElement() # ErrorId
        }
        $xmlWriter.WriteEndElement() # ErrorIds

        $xmlWriter.WriteStartElement("ScriptContexts")
        foreach ($key in $model.Weights.ScriptContext.Keys) {
            $xmlWriter.WriteStartElement("ScriptContext")
            $xmlWriter.WriteAttributeString("name", $key)
            $xmlWriter.WriteAttributeString("weight", $model.Weights.ScriptContext[$key].ToString())
            $xmlWriter.WriteEndElement() # ScriptContext
        }
        $xmlWriter.WriteEndElement() # ScriptContexts

        $xmlWriter.WriteEndElement() # Weights

        $xmlWriter.WriteEndElement() # ErrorPatternModel
        $xmlWriter.WriteEndDocument()
        $xmlWriter.Flush()
        $xmlWriter.Close()

        return $ModelPath
    }
}

Describe "Predict-ErrorCascades" {
    BeforeEach {
        # Créer une base de données de test
        New-TestDatabase -DatabasePath $global:databasePath -PatternCount 10

        # Créer un modèle de test
        New-TestModel -ModelPath $global:modelPath
    }

    It "Charge correctement un modèle" {
        # Charger le script
        . $global:scriptPath -DatabasePath $global:databasePath -ModelPath $global:modelPath -CorrelationThreshold 0.6 -ReportPath "$global:testFolder\test_report.md"

        # Charger le modèle
        $model = Import-ErrorModel -ModelPath $global:modelPath

        $model | Should -Not -BeNullOrEmpty
        $model.Weights | Should -Not -BeNullOrEmpty
        $model.Bias | Should -Not -BeNullOrEmpty
        $model.LearningRate | Should -Not -BeNullOrEmpty
        $model.Iterations | Should -BeGreaterThan 0
        $model.TrainingAccuracy | Should -BeGreaterThan 0
    }

    It "Construit correctement un graphe de dépendances" {
        # Charger le script
        . $global:scriptPath -DatabasePath $global:databasePath -ModelPath $global:modelPath -CorrelationThreshold 0.6 -ReportPath "$global:testFolder\test_report.md"

        # Charger la base de données
        $database = Get-Content -Path $global:databasePath -Raw | ConvertFrom-Json

        # Construire le graphe de dépendances
        $graph = Build-ErrorDependencyGraph -Patterns $database.Patterns -Correlations $database.Correlations -CorrelationThreshold 0.6

        $graph | Should -Not -BeNullOrEmpty
        $graph.Count | Should -Be $database.Patterns.Count

        # Vérifier que les dépendances ont été ajoutées
        $hasDependencies = $false
        foreach ($patternId in $graph.Keys) {
            if ($graph[$patternId].Dependencies.Count -gt 0) {
                $hasDependencies = $true
                break
            }
        }

        $hasDependencies | Should -Be $true
    }

    It "Identifie correctement les patterns racines" {
        # Charger le script
        . $global:scriptPath -DatabasePath $global:databasePath -ModelPath $global:modelPath -CorrelationThreshold 0.6 -ReportPath "$global:testFolder\test_report.md"

        # Charger la base de données
        $database = Get-Content -Path $global:databasePath -Raw | ConvertFrom-Json

        # Construire le graphe de dépendances
        $graph = Build-ErrorDependencyGraph -Patterns $database.Patterns -Correlations $database.Correlations -CorrelationThreshold 0.6

        # Identifier les patterns racines
        $rootPatterns = Get-RootPatterns -Graph $graph

        $rootPatterns | Should -Not -BeNullOrEmpty
    }

    It "Identifie correctement les patterns feuilles" {
        # Charger le script
        . $global:scriptPath -DatabasePath $global:databasePath -ModelPath $global:modelPath -CorrelationThreshold 0.6 -ReportPath "$global:testFolder\test_report.md"

        # Charger la base de données
        $database = Get-Content -Path $global:databasePath -Raw | ConvertFrom-Json

        # Construire le graphe de dépendances
        $graph = Build-ErrorDependencyGraph -Patterns $database.Patterns -Correlations $database.Correlations -CorrelationThreshold 0.6

        # Identifier les patterns feuilles
        $leafPatterns = Get-LeafPatterns -Graph $graph

        $leafPatterns | Should -Not -BeNullOrEmpty
    }

    It "Identifie correctement les chemins de cascade" {
        # Charger le script
        . $global:scriptPath -DatabasePath $global:databasePath -ModelPath $global:modelPath -CorrelationThreshold 0.6 -ReportPath "$global:testFolder\test_report.md"

        # Charger la base de données
        $database = Get-Content -Path $global:databasePath -Raw | ConvertFrom-Json

        # Construire le graphe de dépendances
        $graph = Build-ErrorDependencyGraph -Patterns $database.Patterns -Correlations $database.Correlations -CorrelationThreshold 0.6

        # Identifier les patterns racines
        $rootPatterns = Get-RootPatterns -Graph $graph

        # Identifier les chemins de cascade
        $cascadePaths = Get-CascadePaths -Graph $graph -RootPatterns $rootPatterns

        $cascadePaths | Should -Not -BeNullOrEmpty
    }

    It "Calcule correctement la probabilité d'une cascade" {
        # Charger le script
        . $global:scriptPath -DatabasePath $global:databasePath -ModelPath $global:modelPath -CorrelationThreshold 0.6 -ReportPath "$global:testFolder\test_report.md"

        # Charger la base de données
        $database = Get-Content -Path $global:databasePath -Raw | ConvertFrom-Json

        # Construire le graphe de dépendances
        $graph = Build-ErrorDependencyGraph -Patterns $database.Patterns -Correlations $database.Correlations -CorrelationThreshold 0.6

        # Identifier les patterns racines
        $rootPatterns = Get-RootPatterns -Graph $graph

        # Identifier les chemins de cascade
        $cascadePaths = Get-CascadePaths -Graph $graph -RootPatterns $rootPatterns

        if ($cascadePaths.Count -gt 0) {
            # Calculer la probabilité d'une cascade
            $probability = Measure-CascadeProbability -Graph $graph -Path $cascadePaths[0]

            $probability | Should -BeOfType [double]
            $probability | Should -BeGreaterThanOrEqual 0
            $probability | Should -BeLessThanOrEqual 1
        }
    }

    It "Génère correctement un rapport de prédiction" {
        # Charger le script
        . $global:scriptPath -DatabasePath $global:databasePath -ModelPath $global:modelPath -CorrelationThreshold 0.6 -ReportPath "$global:testFolder\test_report.md"

        # Charger la base de données
        $database = Get-Content -Path $global:databasePath -Raw | ConvertFrom-Json

        # Construire le graphe de dépendances
        $graph = Build-ErrorDependencyGraph -Patterns $database.Patterns -Correlations $database.Correlations -CorrelationThreshold 0.6

        # Identifier les patterns racines
        $rootPatterns = Get-RootPatterns -Graph $graph

        # Identifier les chemins de cascade
        $cascadePaths = Get-CascadePaths -Graph $graph -RootPatterns $rootPatterns

        # Générer un rapport de prédiction
        $reportPath = Join-Path -Path $global:testFolder -ChildPath "test_cascade_report.md"
        $result = New-CascadePredictionReport -Graph $graph -CascadePaths $cascadePaths -ReportPath $reportPath

        $result | Should -Be $reportPath
        Test-Path -Path $reportPath | Should -Be $true

        $reportContent = Get-Content -Path $reportPath -Raw
        $reportContent | Should -Match "Rapport de prédiction des erreurs en cascade"
        $reportContent | Should -Match "Résumé"
        $reportContent | Should -Match "Cascades d'erreurs les plus probables"
    }
}

Describe "Predict-ErrorCascades Integration" {
    BeforeAll {
        # Créer une base de données de test
        New-TestDatabase -DatabasePath $global:databasePath -PatternCount 20

        # Créer un modèle de test
        New-TestModel -ModelPath $global:modelPath
    }

    It "Exécute correctement le script complet" {
        # Exécuter le script
        $reportPath = Join-Path -Path $global:testFolder -ChildPath "integration_report.md"
        & $global:scriptPath -DatabasePath $global:databasePath -ModelPath $global:modelPath -CorrelationThreshold 0.6 -ReportPath $reportPath

        # Vérifier que le rapport a été généré
        Test-Path -Path $reportPath | Should -Be $true

        $reportContent = Get-Content -Path $reportPath -Raw
        $reportContent | Should -Match "Rapport de prédiction des erreurs en cascade"
    }
}
