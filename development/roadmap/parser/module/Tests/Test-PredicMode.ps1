<#
.SYNOPSIS
    Tests pour le script predic-mode.ps1.

.DESCRIPTION
    Ce script contient des tests unitaires et d'intÃ©gration pour le script predic-mode.ps1
    qui implÃ©mente le mode PREDIC pour anticiper les performances, dÃ©tecter les anomalies
    et analyser les tendances dans le comportement du systÃ¨me.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>

# Importer Pester si disponible
if (Get-Module -ListAvailable -Name Pester) {
    Import-Module Pester
} else {
    Write-Warning "Le module Pester n'est pas installÃ©. Les tests ne seront pas exÃ©cutÃ©s avec le framework Pester."
}

# Chemin vers le script Ã  tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent (Split-Path -Parent $scriptPath)
$projectRoot = Split-Path -Parent (Split-Path -Parent $modulePath)
$predicModePath = Join-Path -Path $projectRoot -ChildPath "predic-mode.ps1"

# Chemin vers les fonctions Ã  tester
$invokePredicPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Invoke-RoadmapPrediction.ps1"

# VÃ©rifier si les fichiers existent
if (-not (Test-Path -Path $predicModePath)) {
    Write-Warning "Le script predic-mode.ps1 est introuvable Ã  l'emplacement : $predicModePath"
}

if (-not (Test-Path -Path $invokePredicPath)) {
    Write-Warning "Le fichier Invoke-RoadmapPrediction.ps1 est introuvable Ã  l'emplacement : $invokePredicPath"
}

# Importer les fonctions si elles existent
if (Test-Path -Path $invokePredicPath) {
    . $invokePredicPath
    Write-Host "Fonction Invoke-RoadmapPrediction importÃ©e." -ForegroundColor Green
}

# CrÃ©er un fichier temporaire pour les tests
$testFilePath = Join-Path -Path $env:TEMP -ChildPath "TestRoadmap_$(Get-Random).md"

# CrÃ©er un fichier de test avec une structure de roadmap simple
@"
# Roadmap de test

## Section 1

- [ ] **1.1** Analyse prÃ©dictive
  - [ ] **1.1.1** DÃ©velopper les mÃ©canismes de prÃ©diction
  - [ ] **1.1.2** ImplÃ©menter la dÃ©tection d'anomalies
- [ ] **1.2** Analyse de tendances
  - [ ] **1.2.1** DÃ©velopper les mÃ©canismes d'analyse de tendances
  - [ ] **1.2.2** ImplÃ©menter la gÃ©nÃ©ration de rapports prÃ©dictifs

## Section 2

- [ ] **2.1** Tests de prÃ©diction
"@ | Set-Content -Path $testFilePath -Encoding UTF8

Write-Host "Fichier de roadmap crÃ©Ã© : $testFilePath" -ForegroundColor Green

# CrÃ©er des rÃ©pertoires temporaires pour les tests
$testDataPath = Join-Path -Path $env:TEMP -ChildPath "TestData_$(Get-Random)"
$testOutputPath = Join-Path -Path $env:TEMP -ChildPath "TestOutput_$(Get-Random)"

# CrÃ©er la structure des rÃ©pertoires de test
New-Item -Path $testDataPath -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path -Path $testDataPath -ChildPath "performance") -ItemType Directory -Force | Out-Null
New-Item -Path $testOutputPath -ItemType Directory -Force | Out-Null

# CrÃ©er des fichiers de donnÃ©es de performance pour les tests
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

Write-Host "DonnÃ©es de performance crÃ©Ã©es : $performanceDataPath" -ForegroundColor Green
Write-Host "RÃ©pertoire de sortie crÃ©Ã© : $testOutputPath" -ForegroundColor Green

# Tests unitaires avec Pester
Describe "Invoke-RoadmapPrediction" {
    BeforeEach {
        # PrÃ©paration avant chaque test
    }

    AfterEach {
        # Nettoyage aprÃ¨s chaque test
    }

    It "Devrait exÃ©cuter correctement avec des paramÃ¨tres valides" {
        # Appeler la fonction
        if (Get-Command -Name Invoke-RoadmapPrediction -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapPrediction -DataPath $testDataPath -OutputPath $testOutputPath -PredictionHorizon 30
            $result | Should -Not -BeNullOrEmpty
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapPrediction n'est pas disponible"
        }
    }

    It "Devrait lever une exception si le rÃ©pertoire de donnÃ©es n'existe pas" {
        # Appeler la fonction avec un rÃ©pertoire inexistant
        if (Get-Command -Name Invoke-RoadmapPrediction -ErrorAction SilentlyContinue) {
            { Invoke-RoadmapPrediction -DataPath "RepertoireInexistant" -OutputPath $testOutputPath -PredictionHorizon 30 } | Should -Throw
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapPrediction n'est pas disponible"
        }
    }

    It "Devrait prÃ©dire l'Ã©volution des mÃ©triques" {
        # Appeler la fonction et vÃ©rifier les prÃ©dictions
        if (Get-Command -Name Invoke-RoadmapPrediction -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapPrediction -DataPath $testDataPath -OutputPath $testOutputPath -PredictionHorizon 30 -MetricName "ResponseTime"
            
            # VÃ©rifier que les prÃ©dictions sont gÃ©nÃ©rÃ©es
            $result.Predictions | Should -Not -BeNullOrEmpty
            $result.Predictions.Count | Should -BeGreaterThan 0
            
            # VÃ©rifier que les prÃ©dictions contiennent la mÃ©trique spÃ©cifiÃ©e
            $result.Predictions.ResponseTime | Should -Not -BeNullOrEmpty
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapPrediction n'est pas disponible"
        }
    }

    It "Devrait dÃ©tecter les anomalies" {
        # Appeler la fonction et vÃ©rifier la dÃ©tection d'anomalies
        if (Get-Command -Name Invoke-RoadmapPrediction -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapPrediction -DataPath $testDataPath -OutputPath $testOutputPath -AnomalyDetection $true -AlertThreshold 0.95
            
            # VÃ©rifier que les anomalies sont dÃ©tectÃ©es
            $result.Anomalies | Should -Not -BeNullOrEmpty
            $result.Anomalies.Count | Should -BeGreaterThan 0
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapPrediction n'est pas disponible"
        }
    }

    It "Devrait analyser les tendances" {
        # Appeler la fonction et vÃ©rifier l'analyse de tendances
        if (Get-Command -Name Invoke-RoadmapPrediction -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapPrediction -DataPath $testDataPath -OutputPath $testOutputPath -TrendAnalysis $true
            
            # VÃ©rifier que les tendances sont analysÃ©es
            $result.Trends | Should -Not -BeNullOrEmpty
            $result.Trends.Count | Should -BeGreaterThan 0
            
            # VÃ©rifier que les tendances contiennent des informations sur la croissance
            $result.Trends.GrowthRate | Should -Not -BeNullOrEmpty
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapPrediction n'est pas disponible"
        }
    }

    It "Devrait gÃ©nÃ©rer un rapport de prÃ©diction" {
        # Appeler la fonction et vÃ©rifier la gÃ©nÃ©ration du rapport
        if (Get-Command -Name Invoke-RoadmapPrediction -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapPrediction -DataPath $testDataPath -OutputPath $testOutputPath -PredictionHorizon 30 -AnomalyDetection $true -TrendAnalysis $true
            
            # VÃ©rifier que le rapport est gÃ©nÃ©rÃ©
            $predictionReportPath = Join-Path -Path $testOutputPath -ChildPath "prediction_report.html"
            Test-Path -Path $predictionReportPath | Should -Be $true
            
            # VÃ©rifier que le contenu du rapport contient les informations attendues
            $reportContent = Get-Content -Path $predictionReportPath -Raw
            $reportContent | Should -Match "PrÃ©dictions"
            $reportContent | Should -Match "Anomalies"
            $reportContent | Should -Match "Tendances"
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapPrediction n'est pas disponible"
        }
    }
}

# Test d'intÃ©gration du script predic-mode.ps1
Describe "predic-mode.ps1 Integration" {
    It "Devrait s'exÃ©cuter correctement avec des paramÃ¨tres valides" {
        if (Test-Path -Path $predicModePath) {
            # ExÃ©cuter le script
            $output = & $predicModePath -DataPath $testDataPath -OutputPath $testOutputPath -PredictionHorizon 30 -AnomalyDetection $true -TrendAnalysis $true
            
            # VÃ©rifier que le script s'est exÃ©cutÃ© sans erreur
            $LASTEXITCODE | Should -Be 0
            
            # VÃ©rifier que les fichiers attendus existent
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
    Write-Host "Fichier de roadmap supprimÃ©." -ForegroundColor Gray
}

if (Test-Path -Path $testDataPath) {
    Remove-Item -Path $testDataPath -Recurse -Force
    Write-Host "RÃ©pertoire de donnÃ©es supprimÃ©." -ForegroundColor Gray
}

if (Test-Path -Path $testOutputPath) {
    Remove-Item -Path $testOutputPath -Recurse -Force
    Write-Host "RÃ©pertoire de sortie supprimÃ©." -ForegroundColor Gray
}

# ExÃ©cuter les tests si Pester est disponible
if (Get-Command -Name Invoke-Pester -ErrorAction SilentlyContinue) {
    Invoke-Pester -Path $MyInvocation.MyCommand.Path
} else {
    Write-Host "Tests terminÃ©s. Utilisez Invoke-Pester pour exÃ©cuter les tests avec le framework Pester." -ForegroundColor Yellow
}
