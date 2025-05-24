<#
.SYNOPSIS
    Tests de partage de donnÃ©es entre les diffÃ©rents modes.

.DESCRIPTION
    Ce script contient des tests qui vÃ©rifient que les donnÃ©es gÃ©nÃ©rÃ©es par un mode
    peuvent Ãªtre utilisÃ©es par un autre mode, assurant ainsi une intÃ©gration fluide
    entre les diffÃ©rents modes.

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

# VÃ©rifier si les scripts existent
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

# CrÃ©er un fichier temporaire pour les tests
$testFilePath = Join-Path -Path $env:TEMP -ChildPath "TestRoadmap_$(Get-Random).md"

# CrÃ©er un fichier de test avec une structure de roadmap simple
@"
# Roadmap de test

## Section 1

- [ ] **1.1** DÃ©veloppement de fonctionnalitÃ©s
  - [ ] **1.1.1** Concevoir l'architecture du module
  - [ ] **1.1.2** ImplÃ©menter les fonctionnalitÃ©s de base
  - [ ] **1.1.3** Optimiser les performances
  - [ ] **1.1.4** Tester les fonctionnalitÃ©s
- [ ] **1.2** Correction de bugs
  - [ ] **1.2.1** Identifier les bugs
  - [ ] **1.2.2** Corriger les bugs
  - [ ] **1.2.3** Tester les corrections

## Section 2

- [ ] **2.1** DÃ©ploiement
  - [ ] **2.1.1** PrÃ©parer le dÃ©ploiement
  - [ ] **2.1.2** DÃ©ployer en production
"@ | Set-Content -Path $testFilePath -Encoding UTF8

Write-Host "Fichier de roadmap crÃ©Ã© : $testFilePath" -ForegroundColor Green

# CrÃ©er des rÃ©pertoires temporaires pour les tests
$testProjectPath = Join-Path -Path $env:TEMP -ChildPath "TestProject_$(Get-Random)"
$testOutputPath = Join-Path -Path $env:TEMP -ChildPath "TestOutput_$(Get-Random)"

# CrÃ©er la structure du projet de test
New-Item -Path $testProjectPath -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path -Path $testProjectPath -ChildPath "src") -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path -Path $testProjectPath -ChildPath "docs") -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path -Path $testProjectPath -ChildPath "tests") -ItemType Directory -Force | Out-Null
New-Item -Path $testOutputPath -ItemType Directory -Force | Out-Null

# CrÃ©er des fichiers pour les tests
@"
# Module principal

function Get-Data {
    param (
        [string]`$Source
    )
    
    # Bug: Pas de vÃ©rification si Source est null
    return "DonnÃ©es de `$Source"
}

function Invoke-Data {
    param (
        [object]`$Data
    )
    
    # ProblÃ¨me de performance: Utilisation inefficace de la concatÃ©nation de chaÃ®nes
    `$result = ""
    foreach (`$item in `$Data) {
        `$result += `$item + "`n"
    }
    
    return `$result
}
"@ | Set-Content -Path (Join-Path -Path $testProjectPath -ChildPath "src\Module.ps1") -Encoding UTF8

Write-Host "Projet de test crÃ©Ã© : $testProjectPath" -ForegroundColor Green
Write-Host "RÃ©pertoire de sortie crÃ©Ã© : $testOutputPath" -ForegroundColor Green

# Tests de partage de donnÃ©es entre modes
Describe "Partage de donnÃ©es entre modes" {
    BeforeEach {
        # PrÃ©paration avant chaque test
    }

    AfterEach {
        # Nettoyage aprÃ¨s chaque test
    }

    It "Devrait partager les donnÃ©es entre ARCHI et DEV-R" {
        # VÃ©rifier si les scripts nÃ©cessaires existent
        if ((Test-Path -Path $archiModePath) -and (Test-Path -Path $devRModePath)) {
            # 1. ARCHI: Concevoir l'architecture
            $archiOutput = & $archiModePath -FilePath $testFilePath -TaskIdentifier "1.1.1" -ProjectPath $testProjectPath -OutputPath $testOutputPath -DiagramType "C4"
            
            # VÃ©rifier que le mode ARCHI a gÃ©nÃ©rÃ© des diagrammes
            $architectureDiagramPath = Join-Path -Path $testOutputPath -ChildPath "architecture_diagram.md"
            Test-Path -Path $architectureDiagramPath | Should -Be $true
            
            # 2. DEV-R: Utiliser les diagrammes d'architecture pour l'implÃ©mentation
            $devROutput = & $devRModePath -RoadmapPath $testFilePath -TaskIdentifier "1.1.2" -OutputPath $testProjectPath -GenerateTests $true -TestsPath (Join-Path -Path $testProjectPath -ChildPath "tests") -ArchitecturePath $architectureDiagramPath
            
            # VÃ©rifier que le mode DEV-R a implÃ©mentÃ© des fonctionnalitÃ©s
            $implementationPath = Join-Path -Path $testProjectPath -ChildPath "src\Module.ps1"
            Test-Path -Path $implementationPath | Should -Be $true
            
            # VÃ©rifier que l'implÃ©mentation fait rÃ©fÃ©rence Ã  l'architecture
            $implementationContent = Get-Content -Path $implementationPath -Raw
            $implementationContent | Should -Match "Architecture"
        } else {
            Set-ItResult -Skipped -Because "Un ou plusieurs scripts nÃ©cessaires sont manquants"
        }
    }

    It "Devrait partager les donnÃ©es entre DEBUG et TEST" {
        # VÃ©rifier si les scripts nÃ©cessaires existent
        if ((Test-Path -Path $debugModePath) -and (Test-Path -Path $testModePath)) {
            # CrÃ©er un fichier de log d'erreur
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
            
            # VÃ©rifier que le mode DEBUG a gÃ©nÃ©rÃ© un patch
            $patchPath = Join-Path -Path $testOutputPath -ChildPath "fix_patch.ps1"
            Test-Path -Path $patchPath | Should -Be $true
            
            # Appliquer le patch
            if (Test-Path -Path $patchPath) {
                & $patchPath
            }
            
            # 2. TEST: Tester les corrections avec les cas de test gÃ©nÃ©rÃ©s par DEBUG
            $testOutput = & $testModePath -ModulePath $testProjectPath -TestsPath (Join-Path -Path $testProjectPath -ChildPath "tests") -CoverageThreshold 90 -OutputPath $testOutputPath -TestCases (Join-Path -Path $testOutputPath -ChildPath "test_cases.json")
            
            # VÃ©rifier que le mode TEST a gÃ©nÃ©rÃ© des rapports
            $coverageReportPath = Join-Path -Path $testOutputPath -ChildPath "coverage_report.html"
            Test-Path -Path $coverageReportPath | Should -Be $true
        } else {
            Set-ItResult -Skipped -Because "Un ou plusieurs scripts nÃ©cessaires sont manquants"
        }
    }

    It "Devrait partager les donnÃ©es entre OPTI et PREDIC" {
        # VÃ©rifier si les scripts nÃ©cessaires existent
        if ((Test-Path -Path $optiModePath) -and (Test-Path -Path $predicModePath)) {
            # 1. OPTI: Optimiser les performances
            $optiOutput = & $optiModePath -ModulePath $testProjectPath -ProfileOutput $testOutputPath -OptimizationTarget "All"
            
            # VÃ©rifier que le mode OPTI a gÃ©nÃ©rÃ© des rapports
            $profilingReportPath = Join-Path -Path $testOutputPath -ChildPath "profiling_report.html"
            Test-Path -Path $profilingReportPath | Should -Be $true
            
            # VÃ©rifier que le mode OPTI a gÃ©nÃ©rÃ© des donnÃ©es de performance
            $performanceDataPath = Join-Path -Path $testOutputPath -ChildPath "performance_data.csv"
            Test-Path -Path $performanceDataPath | Should -Be $true
            
            # 2. PREDIC: Utiliser les donnÃ©es de performance pour les prÃ©dictions
            $predicOutput = & $predicModePath -DataPath $testOutputPath -OutputPath $testOutputPath -PredictionHorizon 30 -AnomalyDetection $true -TrendAnalysis $true
            
            # VÃ©rifier que le mode PREDIC a gÃ©nÃ©rÃ© des rapports
            $predictionReportPath = Join-Path -Path $testOutputPath -ChildPath "prediction_report.html"
            Test-Path -Path $predictionReportPath | Should -Be $true
        } else {
            Set-ItResult -Skipped -Because "Un ou plusieurs scripts nÃ©cessaires sont manquants"
        }
    }

    It "Devrait partager les donnÃ©es entre REVIEW et GIT" {
        # VÃ©rifier si les scripts nÃ©cessaires existent
        if ((Test-Path -Path $reviewModePath) -and (Test-Path -Path $gitModePath)) {
            # Initialiser un dÃ©pÃ´t Git
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
                Write-Warning "Impossible d'initialiser le dÃ©pÃ´t Git : $_"
                Pop-Location
            }
            
            # 1. REVIEW: VÃ©rifier la qualitÃ© du code
            $reviewOutput = & $reviewModePath -ModulePath $testRepoPath -OutputPath $testOutputPath -CheckStandards $true -CheckDocumentation $true -CheckComplexity $true
            
            # VÃ©rifier que le mode REVIEW a gÃ©nÃ©rÃ© des rapports
            $reviewReportPath = Join-Path -Path $testOutputPath -ChildPath "review_report.html"
            Test-Path -Path $reviewReportPath | Should -Be $true
            
            # 2. GIT: Utiliser les rÃ©sultats de la revue pour les messages de commit
            $gitOutput = & $gitModePath -RepositoryPath $testRepoPath -CommitStyle "Thematic" -SkipVerify $true -FinalVerify $true -PushAfterCommit $false -ReviewReport $reviewReportPath
            
            # VÃ©rifier que les messages de commit contiennent des rÃ©fÃ©rences Ã  la revue
            try {
                Push-Location $testRepoPath
                $commitMessage = git log -1 --pretty=%B
                Pop-Location
                
                $commitMessage | Should -Match "Review"
            } catch {
                Write-Warning "Impossible de vÃ©rifier les messages de commit : $_"
                Pop-Location
            }
            
            # Supprimer le dÃ©pÃ´t Git
            Remove-Item -Path $testRepoPath -Recurse -Force
        } else {
            Set-ItResult -Skipped -Because "Un ou plusieurs scripts nÃ©cessaires sont manquants"
        }
    }

    It "Devrait partager les donnÃ©es entre C-BREAK et ARCHI" {
        # VÃ©rifier si les scripts nÃ©cessaires existent
        if ((Test-Path -Path $cBreakModePath) -and (Test-Path -Path $archiModePath)) {
            # 1. C-BREAK: DÃ©tecter les dÃ©pendances circulaires
            $cBreakOutput = & $cBreakModePath -ModulePath $testProjectPath -OutputPath $testOutputPath -AutoFix $false -GenerateGraph $true
            
            # VÃ©rifier que le mode C-BREAK a gÃ©nÃ©rÃ© un graphe de dÃ©pendances
            $graphPath = Join-Path -Path $testOutputPath -ChildPath "dependency_graph.html"
            Test-Path -Path $graphPath | Should -Be $true
            
            # 2. ARCHI: Utiliser le graphe de dÃ©pendances pour la conception
            $archiOutput = & $archiModePath -FilePath $testFilePath -TaskIdentifier "1.1.1" -ProjectPath $testProjectPath -OutputPath $testOutputPath -DiagramType "C4" -DependencyGraph $graphPath
            
            # VÃ©rifier que le mode ARCHI a gÃ©nÃ©rÃ© des diagrammes
            $architectureDiagramPath = Join-Path -Path $testOutputPath -ChildPath "architecture_diagram.md"
            Test-Path -Path $architectureDiagramPath | Should -Be $true
            
            # VÃ©rifier que le diagramme fait rÃ©fÃ©rence aux dÃ©pendances
            $diagramContent = Get-Content -Path $architectureDiagramPath -Raw
            $diagramContent | Should -Match "Dependency"
        } else {
            Set-ItResult -Skipped -Because "Un ou plusieurs scripts nÃ©cessaires sont manquants"
        }
    }

    It "Devrait partager les donnÃ©es entre GRAN, DEV-R et CHECK" {
        # VÃ©rifier si les scripts nÃ©cessaires existent
        if ((Test-Path -Path $granModePath) -and (Test-Path -Path $devRModePath) -and (Test-Path -Path $checkModePath)) {
            # CrÃ©er une copie de la roadmap pour le test
            $testRoadmapCopyPath = Join-Path -Path $env:TEMP -ChildPath "TestRoadmapCopy_$(Get-Random).md"
            Copy-Item -Path $testFilePath -Destination $testRoadmapCopyPath
            
            # 1. GRAN: DÃ©composer une tÃ¢che
            $granOutput = & $granModePath -FilePath $testRoadmapCopyPath -TaskIdentifier "1.1.2"
            
            # 2. DEV-R: ImplÃ©menter les sous-tÃ¢ches
            $devROutput = & $devRModePath -RoadmapPath $testRoadmapCopyPath -TaskIdentifier "1.1.2" -OutputPath $testProjectPath -GenerateTests $true -TestsPath (Join-Path -Path $testProjectPath -ChildPath "tests")
            
            # 3. CHECK: VÃ©rifier l'Ã©tat d'implÃ©mentation
            $checkOutput = & $checkModePath -FilePath $testRoadmapCopyPath -TaskIdentifier "1.1.2" -ImplementationPath $testProjectPath
            
            # VÃ©rifier que la roadmap a Ã©tÃ© mise Ã  jour
            $roadmapContent = Get-Content -Path $testRoadmapCopyPath -Raw
            $roadmapContent | Should -Match "\[x\]"
            
            # Supprimer la copie de la roadmap
            Remove-Item -Path $testRoadmapCopyPath -Force
        } else {
            Set-ItResult -Skipped -Because "Un ou plusieurs scripts nÃ©cessaires sont manquants"
        }
    }
}

# Nettoyage
if (Test-Path -Path $testFilePath) {
    Remove-Item -Path $testFilePath -Force
    Write-Host "Fichier de roadmap supprimÃ©." -ForegroundColor Gray
}

if (Test-Path -Path $testProjectPath) {
    Remove-Item -Path $testProjectPath -Recurse -Force
    Write-Host "Projet de test supprimÃ©." -ForegroundColor Gray
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

