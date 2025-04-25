<#
.SYNOPSIS
    Tests de partage de données entre les différents modes.

.DESCRIPTION
    Ce script contient des tests qui vérifient que les données générées par un mode
    peuvent être utilisées par un autre mode, assurant ainsi une intégration fluide
    entre les différents modes.

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

# Chemins vers les scripts de mode
$archiModePath = Join-Path -Path $projectRoot -ChildPath "archi-mode.ps1"
$debugModePath = Join-Path -Path $projectRoot -ChildPath "debug-mode.ps1"
$testModePath = Join-Path -Path $projectRoot -ChildPath "test-mode.ps1"
$optiModePath = Join-Path -Path $projectRoot -ChildPath "opti-mode.ps1"
$reviewModePath = Join-Path -Path $projectRoot -ChildPath "review-mode.ps1"
$devRModePath = Join-Path -Path $projectRoot -ChildPath "dev-r-mode.ps1"
$predicModePath = Join-Path -Path $projectRoot -ChildPath "predic-mode.ps1"
$cBreakModePath = Join-Path -Path $projectRoot -ChildPath "c-break-mode.ps1"
$gitModePath = Join-Path -Path $projectRoot -ChildPath "git-mode.ps1"
$checkModePath = Join-Path -Path $projectRoot -ChildPath "check-mode.ps1"
$granModePath = Join-Path -Path $projectRoot -ChildPath "gran-mode.ps1"

# Vérifier si les scripts existent
$missingScripts = @()
if (-not (Test-Path -Path $archiModePath)) { $missingScripts += "archi-mode.ps1" }
if (-not (Test-Path -Path $debugModePath)) { $missingScripts += "debug-mode.ps1" }
if (-not (Test-Path -Path $testModePath)) { $missingScripts += "test-mode.ps1" }
if (-not (Test-Path -Path $optiModePath)) { $missingScripts += "opti-mode.ps1" }
if (-not (Test-Path -Path $reviewModePath)) { $missingScripts += "review-mode.ps1" }
if (-not (Test-Path -Path $devRModePath)) { $missingScripts += "dev-r-mode.ps1" }
if (-not (Test-Path -Path $predicModePath)) { $missingScripts += "predic-mode.ps1" }
if (-not (Test-Path -Path $cBreakModePath)) { $missingScripts += "c-break-mode.ps1" }
if (-not (Test-Path -Path $gitModePath)) { $missingScripts += "git-mode.ps1" }
if (-not (Test-Path -Path $checkModePath)) { $missingScripts += "check-mode.ps1" }
if (-not (Test-Path -Path $granModePath)) { $missingScripts += "gran-mode.ps1" }

if ($missingScripts.Count -gt 0) {
    Write-Warning "Les scripts suivants sont introuvables : $($missingScripts -join ', ')"
}

# Créer un fichier temporaire pour les tests
$testFilePath = Join-Path -Path $env:TEMP -ChildPath "TestRoadmap_$(Get-Random).md"

# Créer un fichier de test avec une structure de roadmap simple
@"
# Roadmap de test

## Section 1

- [ ] **1.1** Développement de fonctionnalités
  - [ ] **1.1.1** Concevoir l'architecture du module
  - [ ] **1.1.2** Implémenter les fonctionnalités de base
  - [ ] **1.1.3** Optimiser les performances
  - [ ] **1.1.4** Tester les fonctionnalités
- [ ] **1.2** Correction de bugs
  - [ ] **1.2.1** Identifier les bugs
  - [ ] **1.2.2** Corriger les bugs
  - [ ] **1.2.3** Tester les corrections

## Section 2

- [ ] **2.1** Déploiement
  - [ ] **2.1.1** Préparer le déploiement
  - [ ] **2.1.2** Déployer en production
"@ | Set-Content -Path $testFilePath -Encoding UTF8

Write-Host "Fichier de roadmap créé : $testFilePath" -ForegroundColor Green

# Créer des répertoires temporaires pour les tests
$testProjectPath = Join-Path -Path $env:TEMP -ChildPath "TestProject_$(Get-Random)"
$testOutputPath = Join-Path -Path $env:TEMP -ChildPath "TestOutput_$(Get-Random)"

# Créer la structure du projet de test
New-Item -Path $testProjectPath -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path -Path $testProjectPath -ChildPath "src") -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path -Path $testProjectPath -ChildPath "docs") -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path -Path $testProjectPath -ChildPath "tests") -ItemType Directory -Force | Out-Null
New-Item -Path $testOutputPath -ItemType Directory -Force | Out-Null

# Créer des fichiers pour les tests
@"
# Module principal

function Get-Data {
    param (
        [string]`$Source
    )
    
    # Bug: Pas de vérification si Source est null
    return "Données de `$Source"
}

function Process-Data {
    param (
        [object]`$Data
    )
    
    # Problème de performance: Utilisation inefficace de la concaténation de chaînes
    `$result = ""
    foreach (`$item in `$Data) {
        `$result += `$item + "`n"
    }
    
    return `$result
}
"@ | Set-Content -Path (Join-Path -Path $testProjectPath -ChildPath "src\Module.ps1") -Encoding UTF8

Write-Host "Projet de test créé : $testProjectPath" -ForegroundColor Green
Write-Host "Répertoire de sortie créé : $testOutputPath" -ForegroundColor Green

# Tests de partage de données entre modes
Describe "Partage de données entre modes" {
    BeforeEach {
        # Préparation avant chaque test
    }

    AfterEach {
        # Nettoyage après chaque test
    }

    It "Devrait partager les données entre ARCHI et DEV-R" {
        # Vérifier si les scripts nécessaires existent
        if ((Test-Path -Path $archiModePath) -and (Test-Path -Path $devRModePath)) {
            # 1. ARCHI: Concevoir l'architecture
            $archiOutput = & $archiModePath -FilePath $testFilePath -TaskIdentifier "1.1.1" -ProjectPath $testProjectPath -OutputPath $testOutputPath -DiagramType "C4"
            
            # Vérifier que le mode ARCHI a généré des diagrammes
            $architectureDiagramPath = Join-Path -Path $testOutputPath -ChildPath "architecture_diagram.md"
            Test-Path -Path $architectureDiagramPath | Should -Be $true
            
            # 2. DEV-R: Utiliser les diagrammes d'architecture pour l'implémentation
            $devROutput = & $devRModePath -RoadmapPath $testFilePath -TaskIdentifier "1.1.2" -OutputPath $testProjectPath -GenerateTests $true -TestsPath (Join-Path -Path $testProjectPath -ChildPath "tests") -ArchitecturePath $architectureDiagramPath
            
            # Vérifier que le mode DEV-R a implémenté des fonctionnalités
            $implementationPath = Join-Path -Path $testProjectPath -ChildPath "src\Module.ps1"
            Test-Path -Path $implementationPath | Should -Be $true
            
            # Vérifier que l'implémentation fait référence à l'architecture
            $implementationContent = Get-Content -Path $implementationPath -Raw
            $implementationContent | Should -Match "Architecture"
        } else {
            Set-ItResult -Skipped -Because "Un ou plusieurs scripts nécessaires sont manquants"
        }
    }

    It "Devrait partager les données entre DEBUG et TEST" {
        # Vérifier si les scripts nécessaires existent
        if ((Test-Path -Path $debugModePath) -and (Test-Path -Path $testModePath)) {
            # Créer un fichier de log d'erreur
            $errorLogPath = Join-Path -Path $testOutputPath -ChildPath "error.log"
            @"
[ERROR] 2023-08-15T10:15:30 - NullReferenceException in Get-Data: Object reference not set to an instance of an object.
   at Get-Data, $testProjectPath\src\Module.ps1: line 8
   at CallSite.Target(Closure , CallSite , Object )
Stack trace:
   at Get-Data(`$Source = null)
   at Invoke-ProcessData(`$InputData = null)
   at Main()
"@ | Set-Content -Path $errorLogPath -Encoding UTF8
            
            # 1. DEBUG: Corriger les bugs
            $debugOutput = & $debugModePath -ErrorLog $errorLogPath -ModulePath $testProjectPath -OutputPath $testOutputPath -GeneratePatch $true
            
            # Vérifier que le mode DEBUG a généré un patch
            $patchPath = Join-Path -Path $testOutputPath -ChildPath "fix_patch.ps1"
            Test-Path -Path $patchPath | Should -Be $true
            
            # Appliquer le patch
            if (Test-Path -Path $patchPath) {
                & $patchPath
            }
            
            # 2. TEST: Tester les corrections avec les cas de test générés par DEBUG
            $testOutput = & $testModePath -ModulePath $testProjectPath -TestsPath (Join-Path -Path $testProjectPath -ChildPath "tests") -CoverageThreshold 90 -OutputPath $testOutputPath -TestCases (Join-Path -Path $testOutputPath -ChildPath "test_cases.json")
            
            # Vérifier que le mode TEST a généré des rapports
            $coverageReportPath = Join-Path -Path $testOutputPath -ChildPath "coverage_report.html"
            Test-Path -Path $coverageReportPath | Should -Be $true
        } else {
            Set-ItResult -Skipped -Because "Un ou plusieurs scripts nécessaires sont manquants"
        }
    }

    It "Devrait partager les données entre OPTI et PREDIC" {
        # Vérifier si les scripts nécessaires existent
        if ((Test-Path -Path $optiModePath) -and (Test-Path -Path $predicModePath)) {
            # 1. OPTI: Optimiser les performances
            $optiOutput = & $optiModePath -ModulePath $testProjectPath -ProfileOutput $testOutputPath -OptimizationTarget "All"
            
            # Vérifier que le mode OPTI a généré des rapports
            $profilingReportPath = Join-Path -Path $testOutputPath -ChildPath "profiling_report.html"
            Test-Path -Path $profilingReportPath | Should -Be $true
            
            # Vérifier que le mode OPTI a généré des données de performance
            $performanceDataPath = Join-Path -Path $testOutputPath -ChildPath "performance_data.csv"
            Test-Path -Path $performanceDataPath | Should -Be $true
            
            # 2. PREDIC: Utiliser les données de performance pour les prédictions
            $predicOutput = & $predicModePath -DataPath $testOutputPath -OutputPath $testOutputPath -PredictionHorizon 30 -AnomalyDetection $true -TrendAnalysis $true
            
            # Vérifier que le mode PREDIC a généré des rapports
            $predictionReportPath = Join-Path -Path $testOutputPath -ChildPath "prediction_report.html"
            Test-Path -Path $predictionReportPath | Should -Be $true
        } else {
            Set-ItResult -Skipped -Because "Un ou plusieurs scripts nécessaires sont manquants"
        }
    }

    It "Devrait partager les données entre REVIEW et GIT" {
        # Vérifier si les scripts nécessaires existent
        if ((Test-Path -Path $reviewModePath) -and (Test-Path -Path $gitModePath)) {
            # Initialiser un dépôt Git
            $testRepoPath = Join-Path -Path $env:TEMP -ChildPath "TestRepo_$(Get-Random)"
            New-Item -Path $testRepoPath -ItemType Directory -Force | Out-Null
            Copy-Item -Path $testProjectPath -Destination $testRepoPath -Recurse
            
            try {
                Push-Location $testRepoPath
                git init
                git config user.name "Test User"
                git config user.email "test@example.com"
                git add .
                git commit -m "Initial commit"
                Pop-Location
            } catch {
                Write-Warning "Impossible d'initialiser le dépôt Git : $_"
                Pop-Location
            }
            
            # 1. REVIEW: Vérifier la qualité du code
            $reviewOutput = & $reviewModePath -ModulePath $testRepoPath -OutputPath $testOutputPath -CheckStandards $true -CheckDocumentation $true -CheckComplexity $true
            
            # Vérifier que le mode REVIEW a généré des rapports
            $reviewReportPath = Join-Path -Path $testOutputPath -ChildPath "review_report.html"
            Test-Path -Path $reviewReportPath | Should -Be $true
            
            # 2. GIT: Utiliser les résultats de la revue pour les messages de commit
            $gitOutput = & $gitModePath -RepositoryPath $testRepoPath -CommitStyle "Thematic" -SkipVerify $true -FinalVerify $true -PushAfterCommit $false -ReviewReport $reviewReportPath
            
            # Vérifier que les messages de commit contiennent des références à la revue
            try {
                Push-Location $testRepoPath
                $commitMessage = git log -1 --pretty=%B
                Pop-Location
                
                $commitMessage | Should -Match "Review"
            } catch {
                Write-Warning "Impossible de vérifier les messages de commit : $_"
                Pop-Location
            }
            
            # Supprimer le dépôt Git
            Remove-Item -Path $testRepoPath -Recurse -Force
        } else {
            Set-ItResult -Skipped -Because "Un ou plusieurs scripts nécessaires sont manquants"
        }
    }

    It "Devrait partager les données entre C-BREAK et ARCHI" {
        # Vérifier si les scripts nécessaires existent
        if ((Test-Path -Path $cBreakModePath) -and (Test-Path -Path $archiModePath)) {
            # 1. C-BREAK: Détecter les dépendances circulaires
            $cBreakOutput = & $cBreakModePath -ModulePath $testProjectPath -OutputPath $testOutputPath -AutoFix $false -GenerateGraph $true
            
            # Vérifier que le mode C-BREAK a généré un graphe de dépendances
            $graphPath = Join-Path -Path $testOutputPath -ChildPath "dependency_graph.html"
            Test-Path -Path $graphPath | Should -Be $true
            
            # 2. ARCHI: Utiliser le graphe de dépendances pour la conception
            $archiOutput = & $archiModePath -FilePath $testFilePath -TaskIdentifier "1.1.1" -ProjectPath $testProjectPath -OutputPath $testOutputPath -DiagramType "C4" -DependencyGraph $graphPath
            
            # Vérifier que le mode ARCHI a généré des diagrammes
            $architectureDiagramPath = Join-Path -Path $testOutputPath -ChildPath "architecture_diagram.md"
            Test-Path -Path $architectureDiagramPath | Should -Be $true
            
            # Vérifier que le diagramme fait référence aux dépendances
            $diagramContent = Get-Content -Path $architectureDiagramPath -Raw
            $diagramContent | Should -Match "Dependency"
        } else {
            Set-ItResult -Skipped -Because "Un ou plusieurs scripts nécessaires sont manquants"
        }
    }

    It "Devrait partager les données entre GRAN, DEV-R et CHECK" {
        # Vérifier si les scripts nécessaires existent
        if ((Test-Path -Path $granModePath) -and (Test-Path -Path $devRModePath) -and (Test-Path -Path $checkModePath)) {
            # Créer une copie de la roadmap pour le test
            $testRoadmapCopyPath = Join-Path -Path $env:TEMP -ChildPath "TestRoadmapCopy_$(Get-Random).md"
            Copy-Item -Path $testFilePath -Destination $testRoadmapCopyPath
            
            # 1. GRAN: Décomposer une tâche
            $granOutput = & $granModePath -FilePath $testRoadmapCopyPath -TaskIdentifier "1.1.2"
            
            # 2. DEV-R: Implémenter les sous-tâches
            $devROutput = & $devRModePath -RoadmapPath $testRoadmapCopyPath -TaskIdentifier "1.1.2" -OutputPath $testProjectPath -GenerateTests $true -TestsPath (Join-Path -Path $testProjectPath -ChildPath "tests")
            
            # 3. CHECK: Vérifier l'état d'implémentation
            $checkOutput = & $checkModePath -FilePath $testRoadmapCopyPath -TaskIdentifier "1.1.2" -ImplementationPath $testProjectPath
            
            # Vérifier que la roadmap a été mise à jour
            $roadmapContent = Get-Content -Path $testRoadmapCopyPath -Raw
            $roadmapContent | Should -Match "\[x\]"
            
            # Supprimer la copie de la roadmap
            Remove-Item -Path $testRoadmapCopyPath -Force
        } else {
            Set-ItResult -Skipped -Because "Un ou plusieurs scripts nécessaires sont manquants"
        }
    }
}

# Nettoyage
if (Test-Path -Path $testFilePath) {
    Remove-Item -Path $testFilePath -Force
    Write-Host "Fichier de roadmap supprimé." -ForegroundColor Gray
}

if (Test-Path -Path $testProjectPath) {
    Remove-Item -Path $testProjectPath -Recurse -Force
    Write-Host "Projet de test supprimé." -ForegroundColor Gray
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
