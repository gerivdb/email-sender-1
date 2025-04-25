<#
.SYNOPSIS
    Tests d'intégration pour le mode C-BREAK.

.DESCRIPTION
    Ce script contient des tests d'intégration pour vérifier le bon fonctionnement du mode C-BREAK.
    Il utilise le framework Pester pour exécuter les tests.

.EXAMPLE
    Invoke-Pester -Path ".\Test-CBreakMode.ps1"

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2025-04-25
#>

# Importer le module Pester si nécessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Chemin vers le script à tester
$scriptPath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "c-break-mode.ps1"

# Créer un répertoire temporaire pour les tests
$testProjectPath = Join-Path -Path $env:TEMP -ChildPath "CBreakModeTests"
$testOutputPath = Join-Path -Path $env:TEMP -ChildPath "CBreakModeTestsOutput"
$testRoadmapPath = Join-Path -Path $testProjectPath -ChildPath "test-roadmap.md"

# Créer un environnement de test
function Initialize-TestEnvironment {
    # Créer les répertoires de test
    if (-not (Test-Path -Path $testProjectPath)) {
        New-Item -Path $testProjectPath -ItemType Directory -Force | Out-Null
    }
    
    if (-not (Test-Path -Path $testOutputPath)) {
        New-Item -Path $testOutputPath -ItemType Directory -Force | Out-Null
    }
    
    # Créer un fichier roadmap de test
    @"
# Test Roadmap

## 1. Test Task
- [ ] **1.1** Test Subtask 1
- [ ] **1.2** Test Subtask 2
"@ | Out-File -FilePath $testRoadmapPath -Encoding UTF8
    
    # Créer des fichiers de test avec des dépendances circulaires
    $file1Path = Join-Path -Path $testProjectPath -ChildPath "file1.ps1"
    $file2Path = Join-Path -Path $testProjectPath -ChildPath "file2.ps1"
    $file3Path = Join-Path -Path $testProjectPath -ChildPath "file3.ps1"
    
    # Fichier 1 dépend de Fichier 2
    @"
# Fichier 1
. "$file2Path"

function Test-Function1 {
    Test-Function2
}
"@ | Out-File -FilePath $file1Path -Encoding UTF8
    
    # Fichier 2 dépend de Fichier 3
    @"
# Fichier 2
. "$file3Path"

function Test-Function2 {
    Test-Function3
}
"@ | Out-File -FilePath $file2Path -Encoding UTF8
    
    # Fichier 3 dépend de Fichier 1 (cycle)
    @"
# Fichier 3
. "$file1Path"

function Test-Function3 {
    Test-Function1
}
"@ | Out-File -FilePath $file3Path -Encoding UTF8
}

# Nettoyer l'environnement de test
function Cleanup-TestEnvironment {
    if (Test-Path -Path $testProjectPath) {
        Remove-Item -Path $testProjectPath -Recurse -Force
    }
    
    if (Test-Path -Path $testOutputPath) {
        Remove-Item -Path $testOutputPath -Recurse -Force
    }
}

# Exécuter les tests
Describe "Tests d'intégration du mode C-BREAK" {
    BeforeAll {
        # Initialiser l'environnement de test
        Initialize-TestEnvironment
    }
    
    AfterAll {
        # Nettoyer l'environnement de test
        Cleanup-TestEnvironment
    }
    
    Context "Détection de cycles" {
        It "Devrait détecter les cycles de dépendances" {
            # Exécuter le script avec les paramètres de test
            $output = & $scriptPath -FilePath $testRoadmapPath -ProjectPath $testProjectPath -OutputPath $testOutputPath -IncludePatterns "*.ps1" -DetectionAlgorithm "TARJAN" -WhatIf
            
            # Vérifier que le script s'est exécuté sans erreur
            $LASTEXITCODE | Should -Be 0
            
            # Vérifier que le rapport de détection a été généré
            $reportPath = Join-Path -Path $testOutputPath -ChildPath "cycle_detection_report.json"
            Test-Path -Path $reportPath | Should -Be $true
            
            # Vérifier que des cycles ont été détectés
            $report = Get-Content -Path $reportPath -Raw | ConvertFrom-Json
            $report.CyclesDetected | Should -BeGreaterThan 0
        }
    }
    
    Context "Génération de graphe" {
        It "Devrait générer un graphe de dépendances" {
            # Exécuter le script avec les paramètres de test
            $output = & $scriptPath -FilePath $testRoadmapPath -ProjectPath $testProjectPath -OutputPath $testOutputPath -IncludePatterns "*.ps1" -DetectionAlgorithm "TARJAN" -GenerateGraph $true -GraphFormat "DOT" -WhatIf
            
            # Vérifier que le script s'est exécuté sans erreur
            $LASTEXITCODE | Should -Be 0
            
            # Vérifier que le graphe a été généré
            $graphPath = Join-Path -Path $testOutputPath -ChildPath "dependency_graph.dot"
            Test-Path -Path $graphPath | Should -Be $true
            
            # Vérifier que le graphe contient des informations sur les dépendances
            $graphContent = Get-Content -Path $graphPath -Raw
            $graphContent | Should -Match "digraph DependencyGraph"
            $graphContent | Should -Match "file1.ps1"
            $graphContent | Should -Match "file2.ps1"
            $graphContent | Should -Match "file3.ps1"
        }
    }
    
    Context "Correction automatique" {
        It "Devrait corriger les cycles de dépendances" {
            # Exécuter le script avec les paramètres de test
            $output = & $scriptPath -FilePath $testRoadmapPath -ProjectPath $testProjectPath -OutputPath $testOutputPath -IncludePatterns "*.ps1" -DetectionAlgorithm "TARJAN" -AutoFix $true -FixStrategy "INTERFACE_EXTRACTION" -WhatIf
            
            # Vérifier que le script s'est exécuté sans erreur
            $LASTEXITCODE | Should -Be 0
            
            # Vérifier que le rapport de correction a été généré
            $fixReportPath = Join-Path -Path $testOutputPath -ChildPath "cycle_fix_report.json"
            Test-Path -Path $fixReportPath | Should -Be $true
            
            # Vérifier que des cycles ont été corrigés
            $fixReport = Get-Content -Path $fixReportPath -Raw | ConvertFrom-Json
            $fixReport.CyclesFixed | Should -BeGreaterThan 0
        }
    }
    
    Context "Mise à jour de la roadmap" {
        It "Devrait mettre à jour la tâche dans la roadmap" {
            # Exécuter le script avec les paramètres de test
            $output = & $scriptPath -FilePath $testRoadmapPath -ProjectPath $testProjectPath -OutputPath $testOutputPath -IncludePatterns "*.ps1" -DetectionAlgorithm "TARJAN" -TaskIdentifier "1.1" -WhatIf
            
            # Vérifier que le script s'est exécuté sans erreur
            $LASTEXITCODE | Should -Be 0
            
            # Vérifier que la tâche a été mise à jour dans la roadmap
            $roadmapContent = Get-Content -Path $testRoadmapPath -Raw
            $roadmapContent | Should -Match "\[x\] \*\*1\.1\*\* Test Subtask 1"
        }
    }
}
