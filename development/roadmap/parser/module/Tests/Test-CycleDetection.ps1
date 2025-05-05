<#
.SYNOPSIS
    Tests pour les fonctions de dÃ©tection de cycles de dÃ©pendances.

.DESCRIPTION
    Ce script contient des tests unitaires pour les fonctions de dÃ©tection
    de cycles de dÃ©pendances.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2025-04-25
#>

# Importer les fonctions Ã  tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath ".."
$cycleDetectionPath = Join-Path -Path $modulePath -ChildPath "Functions\Private\CycleDetection\CycleDetectionAlgorithms.ps1"
$dependencyAnalysisPath = Join-Path -Path $modulePath -ChildPath "Functions\Private\CycleDetection\DependencyAnalysisFunctions.ps1"

. $cycleDetectionPath
. $dependencyAnalysisPath

Describe "Fonctions de dÃ©tection de cycles" {
    Context "Find-CyclesDFS" {
        It "DÃ©tecte un cycle simple" {
            # CrÃ©er un graphe avec un cycle simple
            $graph = @{
                "A" = @("B")
                "B" = @("C")
                "C" = @("A")
            }
            
            $cycles = Find-CyclesDFS -Graph $graph
            
            $cycles.Count | Should -BeGreaterThan 0
            $cycles[0].Files.Count | Should -BeGreaterThan 0
        }
        
        It "Ne dÃ©tecte pas de cycle dans un graphe acyclique" {
            # CrÃ©er un graphe acyclique
            $graph = @{
                "A" = @("B", "C")
                "B" = @("D")
                "C" = @("D")
                "D" = @()
            }
            
            $cycles = Find-CyclesDFS -Graph $graph
            
            $cycles.Count | Should -Be 0
        }
        
        It "GÃ¨re correctement un graphe vide" {
            $graph = @{}
            
            $cycles = Find-CyclesDFS -Graph $graph
            
            $cycles.Count | Should -Be 0
        }
    }
    
    Context "Find-CyclesTarjan" {
        It "DÃ©tecte un cycle simple" {
            # CrÃ©er un graphe avec un cycle simple
            $graph = @{
                "A" = @("B")
                "B" = @("C")
                "C" = @("A")
            }
            
            $cycles = Find-CyclesTarjan -Graph $graph
            
            $cycles.Count | Should -BeGreaterThan 0
            $cycles[0].Files.Count | Should -BeGreaterThan 0
        }
        
        It "Ne dÃ©tecte pas de cycle dans un graphe acyclique" {
            # CrÃ©er un graphe acyclique
            $graph = @{
                "A" = @("B", "C")
                "B" = @("D")
                "C" = @("D")
                "D" = @()
            }
            
            $cycles = Find-CyclesTarjan -Graph $graph
            
            $cycles.Count | Should -Be 0
        }
        
        It "GÃ¨re correctement un graphe vide" {
            $graph = @{}
            
            $cycles = Find-CyclesTarjan -Graph $graph
            
            $cycles.Count | Should -Be 0
        }
    }
    
    Context "Find-CyclesJohnson" {
        It "DÃ©tecte un cycle simple" {
            # CrÃ©er un graphe avec un cycle simple
            $graph = @{
                "A" = @("B")
                "B" = @("C")
                "C" = @("A")
            }
            
            $cycles = Find-CyclesJohnson -Graph $graph
            
            $cycles.Count | Should -BeGreaterThan 0
            $cycles[0].Files.Count | Should -BeGreaterThan 0
        }
        
        It "Ne dÃ©tecte pas de cycle dans un graphe acyclique" {
            # CrÃ©er un graphe acyclique
            $graph = @{
                "A" = @("B", "C")
                "B" = @("D")
                "C" = @("D")
                "D" = @()
            }
            
            $cycles = Find-CyclesJohnson -Graph $graph
            
            $cycles.Count | Should -Be 0
        }
        
        It "GÃ¨re correctement un graphe vide" {
            $graph = @{}
            
            $cycles = Find-CyclesJohnson -Graph $graph
            
            $cycles.Count | Should -Be 0
        }
    }
    
    Context "Find-DependencyCycles" {
        It "DÃ©tecte un cycle simple avec l'algorithme par dÃ©faut (Tarjan)" {
            # CrÃ©er un graphe avec un cycle simple
            $graph = @{
                "A" = @("B")
                "B" = @("C")
                "C" = @("A")
            }
            
            $result = Find-DependencyCycles -Graph $graph
            
            $result.AllCycles.Count | Should -BeGreaterThan 0
            $result.FilteredCycles.Count | Should -BeGreaterThan 0
        }
        
        It "DÃ©tecte un cycle simple avec l'algorithme DFS" {
            # CrÃ©er un graphe avec un cycle simple
            $graph = @{
                "A" = @("B")
                "B" = @("C")
                "C" = @("A")
            }
            
            $result = Find-DependencyCycles -Graph $graph -Algorithm "DFS"
            
            $result.AllCycles.Count | Should -BeGreaterThan 0
            $result.FilteredCycles.Count | Should -BeGreaterThan 0
        }
        
        It "DÃ©tecte un cycle simple avec l'algorithme Johnson" {
            # CrÃ©er un graphe avec un cycle simple
            $graph = @{
                "A" = @("B")
                "B" = @("C")
                "C" = @("A")
            }
            
            $result = Find-DependencyCycles -Graph $graph -Algorithm "JOHNSON"
            
            $result.AllCycles.Count | Should -BeGreaterThan 0
            $result.FilteredCycles.Count | Should -BeGreaterThan 0
        }
        
        It "Filtre les cycles selon la sÃ©vÃ©ritÃ© minimale" {
            # CrÃ©er un graphe avec un cycle simple
            $graph = @{
                "A" = @("B")
                "B" = @("C")
                "C" = @("A")
            }
            
            $result = Find-DependencyCycles -Graph $graph -MinimumCycleSeverity 10
            
            $result.AllCycles.Count | Should -BeGreaterThan 0
            $result.FilteredCycles.Count | Should -Be 0
        }
    }
}

Describe "Fonctions d'analyse de dÃ©pendances" {
    Context "Get-FileDependencies" {
        BeforeAll {
            # CrÃ©er des fichiers temporaires pour les tests
            $tempDir = [System.IO.Path]::GetTempPath()
            $projectRoot = Join-Path -Path $tempDir -ChildPath "TestProject"
            
            # CrÃ©er le rÃ©pertoire du projet
            New-Item -Path $projectRoot -ItemType Directory -Force | Out-Null
            
            # CrÃ©er des fichiers PowerShell
            $ps1File1 = Join-Path -Path $projectRoot -ChildPath "File1.ps1"
            $ps1File2 = Join-Path -Path $projectRoot -ChildPath "File2.ps1"
            
            # CrÃ©er le contenu des fichiers
            Set-Content -Path $ps1File1 -Value @"
# Fichier 1
. "$projectRoot\File2.ps1"
"@
            
            Set-Content -Path $ps1File2 -Value @"
# Fichier 2
function Test-Function {
    Write-Host "Test"
}
"@
        }
        
        AfterAll {
            # Supprimer les fichiers temporaires
            Remove-Item -Path $projectRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        It "DÃ©tecte les dÃ©pendances d'un fichier PowerShell" {
            $dependencies = Get-FileDependencies -FilePath $ps1File1 -ProjectRoot $projectRoot
            
            $dependencies.Count | Should -Be 1
            $dependencies[0] | Should -Be $ps1File2
        }
        
        It "Retourne un tableau vide pour un fichier sans dÃ©pendances" {
            $dependencies = Get-FileDependencies -FilePath $ps1File2 -ProjectRoot $projectRoot
            
            $dependencies.Count | Should -Be 0
        }
        
        It "GÃ¨re correctement un fichier inexistant" {
            $dependencies = Get-FileDependencies -FilePath (Join-Path -Path $projectRoot -ChildPath "NonExistentFile.ps1") -ProjectRoot $projectRoot
            
            $dependencies.Count | Should -Be 0
        }
    }
    
    Context "Build-DependencyGraph" {
        BeforeAll {
            # CrÃ©er des fichiers temporaires pour les tests
            $tempDir = [System.IO.Path]::GetTempPath()
            $projectRoot = Join-Path -Path $tempDir -ChildPath "TestProject"
            
            # CrÃ©er le rÃ©pertoire du projet
            New-Item -Path $projectRoot -ItemType Directory -Force | Out-Null
            
            # CrÃ©er des fichiers PowerShell
            $ps1File1 = Join-Path -Path $projectRoot -ChildPath "File1.ps1"
            $ps1File2 = Join-Path -Path $projectRoot -ChildPath "File2.ps1"
            $ps1File3 = Join-Path -Path $projectRoot -ChildPath "File3.ps1"
            
            # CrÃ©er le contenu des fichiers
            Set-Content -Path $ps1File1 -Value @"
# Fichier 1
. "$projectRoot\File2.ps1"
"@
            
            Set-Content -Path $ps1File2 -Value @"
# Fichier 2
. "$projectRoot\File3.ps1"
"@
            
            Set-Content -Path $ps1File3 -Value @"
# Fichier 3
function Test-Function {
    Write-Host "Test"
}
"@
        }
        
        AfterAll {
            # Supprimer les fichiers temporaires
            Remove-Item -Path $projectRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        It "Construit un graphe de dÃ©pendances correct" {
            $files = Get-ChildItem -Path $projectRoot -Filter "*.ps1"
            $graph = Build-DependencyGraph -Files $files -ProjectRoot $projectRoot
            
            $graph.Count | Should -Be 3
            $graph[$ps1File1].Count | Should -Be 1
            $graph[$ps1File1][0] | Should -Be $ps1File2
            $graph[$ps1File2].Count | Should -Be 1
            $graph[$ps1File2][0] | Should -Be $ps1File3
            $graph[$ps1File3].Count | Should -Be 0
        }
        
        It "Limite la profondeur des dÃ©pendances" {
            $files = Get-ChildItem -Path $projectRoot -Filter "*.ps1"
            $graph = Build-DependencyGraph -Files $files -ProjectRoot $projectRoot -MaxDepth 1
            
            $graph.Count | Should -Be 3
            $graph[$ps1File1].Count | Should -Be 1
            $graph[$ps1File1][0] | Should -Be $ps1File2
            $graph[$ps1File2].Count | Should -Be 1
            $graph[$ps1File2][0] | Should -Be $ps1File3
            $graph[$ps1File3].Count | Should -Be 0
        }
    }
}
