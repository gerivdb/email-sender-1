<#
.SYNOPSIS
    Tests d'intÃ©gration pour le mode C-BREAK.

.DESCRIPTION
    Ce script contient des tests d'intÃ©gration pour vÃ©rifier le bon fonctionnement du mode C-BREAK.
    Il utilise le framework Pester pour exÃ©cuter les tests.

.EXAMPLE
    Invoke-Pester -Path ".\Test-CBreakMode.ps1"

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2025-04-25
#>

# Importer le module Pester si nÃ©cessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Chemin vers le script Ã  tester
$scriptPath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "c-break-mode.ps1"

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testProjectPath = Join-Path -Path $env:TEMP -ChildPath "CBreakModeTests"
$testOutputPath = Join-Path -Path $env:TEMP -ChildPath "CBreakModeTestsOutput"
$testRoadmapPath = Join-Path -Path $testProjectPath -ChildPath "test-roadmap.md"

# CrÃ©er un environnement de test
function Initialize-TestEnvironment {
    # CrÃ©er les rÃ©pertoires de test
    if (-not (Test-Path -Path $testProjectPath)) {
        New-Item -Path $testProjectPath -ItemType Directory -Force | Out-Null
    }
    
    if (-not (Test-Path -Path $testOutputPath)) {
        New-Item -Path $testOutputPath -ItemType Directory -Force | Out-Null
    }
    
    # CrÃ©er un fichier roadmap de test
    @"
# Test Roadmap

## 1. Test Task
- [ ] **1.1** Test Subtask 1
- [ ] **1.2** Test Subtask 2
"@ | Out-File -FilePath $testRoadmapPath -Encoding UTF8
    
    # CrÃ©er des fichiers de test avec des dÃ©pendances circulaires
    $file1Path = Join-Path -Path $testProjectPath -ChildPath "file1.ps1"
    $file2Path = Join-Path -Path $testProjectPath -ChildPath "file2.ps1"
    $file3Path = Join-Path -Path $testProjectPath -ChildPath "file3.ps1"
    
    # Fichier 1 dÃ©pend de Fichier 2
    @"
# Fichier 1
. "$file2Path"

function Test-Function1 {
    Test-Function2
}
"@ | Out-File -FilePath $file1Path -Encoding UTF8
    
    # Fichier 2 dÃ©pend de Fichier 3
    @"
# Fichier 2
. "$file3Path"

function Test-Function2 {
    Test-Function3
}
"@ | Out-File -FilePath $file2Path -Encoding UTF8
    
    # Fichier 3 dÃ©pend de Fichier 1 (cycle)
    @"
# Fichier 3
. "$file1Path"

function Test-Function3 {
    Test-Function1
}
"@ | Out-File -FilePath $file3Path -Encoding UTF8
}

# Nettoyer l'environnement de test
function Clear-TestEnvironment {
    if (Test-Path -Path $testProjectPath) {
        Remove-Item -Path $testProjectPath -Recurse -Force
    }
    
    if (Test-Path -Path $testOutputPath) {
        Remove-Item -Path $testOutputPath -Recurse -Force
    }
}

# ExÃ©cuter les tests
Describe "Tests d'intÃ©gration du mode C-BREAK" {
    BeforeAll {
        # Initialiser l'environnement de test
        Initialize-TestEnvironment
    }
    
    AfterAll {
        # Nettoyer l'environnement de test
        Clear-TestEnvironment
    }
    
    Context "DÃ©tection de cycles" {
        It "Devrait dÃ©tecter les cycles de dÃ©pendances" {
            # ExÃ©cuter le script avec les paramÃ¨tres de test
            $output = & $scriptPath -FilePath $testRoadmapPath -ProjectPath $testProjectPath -OutputPath $testOutputPath -IncludePatterns "*.ps1" -DetectionAlgorithm "TARJAN" -WhatIf
            
            # VÃ©rifier que le script s'est exÃ©cutÃ© sans erreur
            $LASTEXITCODE | Should -Be 0
            
            # VÃ©rifier que le rapport de dÃ©tection a Ã©tÃ© gÃ©nÃ©rÃ©
            $reportPath = Join-Path -Path $testOutputPath -ChildPath "cycle_detection_report.json"
            Test-Path -Path $reportPath | Should -Be $true
            
            # VÃ©rifier que des cycles ont Ã©tÃ© dÃ©tectÃ©s
            $report = Get-Content -Path $reportPath -Raw | ConvertFrom-Json
            $report.CyclesDetected | Should -BeGreaterThan 0
        }
    }
    
    Context "GÃ©nÃ©ration de graphe" {
        It "Devrait gÃ©nÃ©rer un graphe de dÃ©pendances" {
            # ExÃ©cuter le script avec les paramÃ¨tres de test
            $output = & $scriptPath -FilePath $testRoadmapPath -ProjectPath $testProjectPath -OutputPath $testOutputPath -IncludePatterns "*.ps1" -DetectionAlgorithm "TARJAN" -GenerateGraph $true -GraphFormat "DOT" -WhatIf
            
            # VÃ©rifier que le script s'est exÃ©cutÃ© sans erreur
            $LASTEXITCODE | Should -Be 0
            
            # VÃ©rifier que le graphe a Ã©tÃ© gÃ©nÃ©rÃ©
            $graphPath = Join-Path -Path $testOutputPath -ChildPath "dependency_graph.dot"
            Test-Path -Path $graphPath | Should -Be $true
            
            # VÃ©rifier que le graphe contient des informations sur les dÃ©pendances
            $graphContent = Get-Content -Path $graphPath -Raw
            $graphContent | Should -Match "digraph DependencyGraph"
            $graphContent | Should -Match "file1.ps1"
            $graphContent | Should -Match "file2.ps1"
            $graphContent | Should -Match "file3.ps1"
        }
    }
    
    Context "Correction automatique" {
        It "Devrait corriger les cycles de dÃ©pendances" {
            # ExÃ©cuter le script avec les paramÃ¨tres de test
            $output = & $scriptPath -FilePath $testRoadmapPath -ProjectPath $testProjectPath -OutputPath $testOutputPath -IncludePatterns "*.ps1" -DetectionAlgorithm "TARJAN" -AutoFix $true -FixStrategy "INTERFACE_EXTRACTION" -WhatIf
            
            # VÃ©rifier que le script s'est exÃ©cutÃ© sans erreur
            $LASTEXITCODE | Should -Be 0
            
            # VÃ©rifier que le rapport de correction a Ã©tÃ© gÃ©nÃ©rÃ©
            $fixReportPath = Join-Path -Path $testOutputPath -ChildPath "cycle_fix_report.json"
            Test-Path -Path $fixReportPath | Should -Be $true
            
            # VÃ©rifier que des cycles ont Ã©tÃ© corrigÃ©s
            $fixReport = Get-Content -Path $fixReportPath -Raw | ConvertFrom-Json
            $fixReport.CyclesFixed | Should -BeGreaterThan 0
        }
    }
    
    Context "Mise Ã  jour de la roadmap" {
        It "Devrait mettre Ã  jour la tÃ¢che dans la roadmap" {
            # ExÃ©cuter le script avec les paramÃ¨tres de test
            $output = & $scriptPath -FilePath $testRoadmapPath -ProjectPath $testProjectPath -OutputPath $testOutputPath -IncludePatterns "*.ps1" -DetectionAlgorithm "TARJAN" -TaskIdentifier "1.1" -WhatIf
            
            # VÃ©rifier que le script s'est exÃ©cutÃ© sans erreur
            $LASTEXITCODE | Should -Be 0
            
            # VÃ©rifier que la tÃ¢che a Ã©tÃ© mise Ã  jour dans la roadmap
            $roadmapContent = Get-Content -Path $testRoadmapPath -Raw
            $roadmapContent | Should -Match "\[x\] \*\*1\.1\*\* Test Subtask 1"
        }
    }
}

