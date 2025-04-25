<#
.SYNOPSIS
    Tests pour le script predic-mode.ps1.

.DESCRIPTION
    Ce script contient des tests unitaires et d'intégration pour le script predic-mode.ps1
    qui implémente le mode PREDIC pour anticiper les performances, détecter les anomalies
    et analyser les tendances dans le comportement du système.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
#>

# Importer Pester si disponible
if (Get-Module -ListAvailable -Name Pester) {
    Import-Module Pester
} else {
    Write-Warning "Le module Pester n'est pas installé. Les tests ne seront pas exécutés avec le framework Pester."
}

# Chemin vers le script à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent (Split-Path -Parent $scriptPath)
$projectRoot = Split-Path -Parent (Split-Path -Parent $modulePath)
$predicModePath = Join-Path -Path $projectRoot -ChildPath "predic-mode.ps1"

# Chemin vers les fonctions à tester
$invokePredicPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Invoke-RoadmapPrediction.ps1"

# Vérifier si les fichiers existent
if (-not (Test-Path -Path $predicModePath)) {
    Write-Warning "Le script predic-mode.ps1 est introuvable à l'emplacement : $predicModePath"
}

if (-not (Test-Path -Path $invokePredicPath)) {
    Write-Warning "Le fichier Invoke-RoadmapPrediction.ps1 est introuvable à l'emplacement : $invokePredicPath"
}

# Importer les fonctions si elles existent
if (Test-Path -Path $invokePredicPath) {
    . $invokePredicPath
    Write-Host "Fonction Invoke-RoadmapPrediction importée." -ForegroundColor Green
}

# Créer un fichier temporaire pour les tests
$testFilePath = Join-Path -Path $env:TEMP -ChildPath "TestRoadmap_$(Get-Random).md"

# Créer un fichier de test avec une structure de roadmap simple
@"
# Roadmap de test

## Section 1

- [ ] **1.1** Analyse prédictive
  - [ ] **1.1.1** Développer les mécanismes de prédiction
  - [ ] **1.1.2** Implémenter la détection d'anomalies
- [ ] **1.2** Analyse de tendances
  - [ ] **1.2.1** Développer les mécanismes d'analyse de tendances
  - [ ] **1.2.2** Implémenter la génération de rapports prédictifs

## Section 2

- [ ] **2.1** Tests de prédiction
"@ | Set-Content -Path $testFilePath -Encoding UTF8

Write-Host "Fichier de roadmap créé : $testFilePath" -ForegroundColor Green

# Créer des répertoires temporaires pour les tests
$testDataPath = Join-Path -Path $env:TEMP -ChildPath "TestData_$(Get-Random)"
$testOutputPath = Join-Path -Path $env:TEMP -ChildPath "TestOutput_$(Get-Random)"

# Créer la structure des répertoires de test
New-Item -Path $testDataPath -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path -Path $testDataPath -ChildPath "performance") -ItemType Directory -Force | Out-Null
New-Item -Path $testOutputPath -ItemType Directory -Force | Out-Null

# Créer des fichiers de données de performance pour les tests
$performanceDataPath = Join-Path -Path $testDataPath -ChildPath "performance\performance_data.csv"
@"
Date,ResponseTime,MemoryUsage,CPUUsage,ErrorCount
2023-01-01,1.2,512,25,0
2023-01-02,1.3,520,27,0
2023-01-03,1.4,530,28,0
2023-01-04,1.5,540,30,0
2023-01-05,1.6,550,32,0
2023-01-06,1.7,560,35,0
2023-01-07,1.8,570,37,0
2023-01-08,1.9,580,40,0
2023-01-09,2.0,590,42,0
2023-01-10,2.1,600,45,0
2023-01-11,2.2,610,47,0
2023-01-12,2.3,620,50,0
2023-01-13,2.4,630,52,0
2023-01-14,2.5,640,55,0
2023-01-15,2.6,650,57,1
2023-01-16,2.7,660,60,0
2023-01-17,2.8,670,62,0
2023-01-18,2.9,680,65,0
2023-01-19,3.0,690,67,0
2023-01-20,3.1,700,70,0
2023-01-21,3.2,710,72,0
2023-01-22,3.3,720,75,0
2023-01-23,3.4,730,77,0
2023-01-24,3.5,740,80,0
2023-01-25,3.6,750,82,0
2023-01-26,3.7,760,85,0
2023-01-27,3.8,770,87,0
2023-01-28,3.9,780,90,0
2023-01-29,4.0,790,92,0
2023-01-30,4.1,800,95,0
"@ | Set-Content -Path $performanceDataPath -Encoding UTF8

Write-Host "Données de performance créées : $performanceDataPath" -ForegroundColor Green
Write-Host "Répertoire de sortie créé : $testOutputPath" -ForegroundColor Green

# Tests unitaires avec Pester
Describe "Invoke-RoadmapPrediction" {
    BeforeEach {
        # Préparation avant chaque test
    }

    AfterEach {
        # Nettoyage après chaque test
    }

    It "Devrait exécuter correctement avec des paramètres valides" {
        # Appeler la fonction
        if (Get-Command -Name Invoke-RoadmapPrediction -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapPrediction -DataPath $testDataPath -OutputPath $testOutputPath -PredictionHorizon 30
            $result | Should -Not -BeNullOrEmpty
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapPrediction n'est pas disponible"
        }
    }

    It "Devrait lever une exception si le répertoire de données n'existe pas" {
        # Appeler la fonction avec un répertoire inexistant
        if (Get-Command -Name Invoke-RoadmapPrediction -ErrorAction SilentlyContinue) {
            { Invoke-RoadmapPrediction -DataPath "RepertoireInexistant" -OutputPath $testOutputPath -PredictionHorizon 30 } | Should -Throw
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapPrediction n'est pas disponible"
        }
    }

    It "Devrait prédire l'évolution des métriques" {
        # Appeler la fonction et vérifier les prédictions
        if (Get-Command -Name Invoke-RoadmapPrediction -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapPrediction -DataPath $testDataPath -OutputPath $testOutputPath -PredictionHorizon 30 -MetricName "ResponseTime"
            
            # Vérifier que les prédictions sont générées
            $result.Predictions | Should -Not -BeNullOrEmpty
            $result.Predictions.Count | Should -BeGreaterThan 0
            
            # Vérifier que les prédictions contiennent la métrique spécifiée
            $result.Predictions.ResponseTime | Should -Not -BeNullOrEmpty
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapPrediction n'est pas disponible"
        }
    }

    It "Devrait détecter les anomalies" {
        # Appeler la fonction et vérifier la détection d'anomalies
        if (Get-Command -Name Invoke-RoadmapPrediction -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapPrediction -DataPath $testDataPath -OutputPath $testOutputPath -AnomalyDetection $true -AlertThreshold 0.95
            
            # Vérifier que les anomalies sont détectées
            $result.Anomalies | Should -Not -BeNullOrEmpty
            $result.Anomalies.Count | Should -BeGreaterThan 0
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapPrediction n'est pas disponible"
        }
    }

    It "Devrait analyser les tendances" {
        # Appeler la fonction et vérifier l'analyse de tendances
        if (Get-Command -Name Invoke-RoadmapPrediction -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapPrediction -DataPath $testDataPath -OutputPath $testOutputPath -TrendAnalysis $true
            
            # Vérifier que les tendances sont analysées
            $result.Trends | Should -Not -BeNullOrEmpty
            $result.Trends.Count | Should -BeGreaterThan 0
            
            # Vérifier que les tendances contiennent des informations sur la croissance
            $result.Trends.GrowthRate | Should -Not -BeNullOrEmpty
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapPrediction n'est pas disponible"
        }
    }

    It "Devrait générer un rapport de prédiction" {
        # Appeler la fonction et vérifier la génération du rapport
        if (Get-Command -Name Invoke-RoadmapPrediction -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapPrediction -DataPath $testDataPath -OutputPath $testOutputPath -PredictionHorizon 30 -AnomalyDetection $true -TrendAnalysis $true
            
            # Vérifier que le rapport est généré
            $predictionReportPath = Join-Path -Path $testOutputPath -ChildPath "prediction_report.html"
            Test-Path -Path $predictionReportPath | Should -Be $true
            
            # Vérifier que le contenu du rapport contient les informations attendues
            $reportContent = Get-Content -Path $predictionReportPath -Raw
            $reportContent | Should -Match "Prédictions"
            $reportContent | Should -Match "Anomalies"
            $reportContent | Should -Match "Tendances"
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapPrediction n'est pas disponible"
        }
    }
}

# Test d'intégration du script predic-mode.ps1
Describe "predic-mode.ps1 Integration" {
    It "Devrait s'exécuter correctement avec des paramètres valides" {
        if (Test-Path -Path $predicModePath) {
            # Exécuter le script
            $output = & $predicModePath -DataPath $testDataPath -OutputPath $testOutputPath -PredictionHorizon 30 -AnomalyDetection $true -TrendAnalysis $true
            
            # Vérifier que le script s'est exécuté sans erreur
            $LASTEXITCODE | Should -Be 0
            
            # Vérifier que les fichiers attendus existent
            $predictionReportPath = Join-Path -Path $testOutputPath -ChildPath "prediction_report.html"
            Test-Path -Path $predictionReportPath | Should -Be $true
        } else {
            Set-ItResult -Skipped -Because "Le script predic-mode.ps1 n'est pas disponible"
        }
    }
}

# Nettoyage
if (Test-Path -Path $testFilePath) {
    Remove-Item -Path $testFilePath -Force
    Write-Host "Fichier de roadmap supprimé." -ForegroundColor Gray
}

if (Test-Path -Path $testDataPath) {
    Remove-Item -Path $testDataPath -Recurse -Force
    Write-Host "Répertoire de données supprimé." -ForegroundColor Gray
}

if (Test-Path -Path $testOutputPath) {
    Remove-Item -Path $testOutputPath -Recurse -Force
    Write-Host "Répertoire de sortie supprimé." -ForegroundColor Gray
}

# Exécuter les tests si Pester est disponible
if (Get-Command -Name Invoke-Pester -ErrorAction SilentlyContinue) {
    Invoke-Pester -Path $MyInvocation.MyCommand.Path
} else {
    Write-Host "Tests terminés. Utilisez Invoke-Pester pour exécuter les tests avec le framework Pester." -ForegroundColor Yellow
}
