#Requires -Version 5.1
<#
.SYNOPSIS
    Tests d'intÃ©gration pour le module DependencyCycleResolver.
.DESCRIPTION
    Ce script contient des tests d'intÃ©gration pour vÃ©rifier le bon fonctionnement
    du module DependencyCycleResolver avec le module CycleDetector.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-04-20
#>

# Importer Pester
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Install-Module -Name Pester -Force -SkipPublisherCheck
}
Import-Module Pester -Force

# Importer les modules Ã  tester
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules"
$cycleDetectorPath = Join-Path -Path $modulesPath -ChildPath "CycleDetector.psm1"
$cycleResolverPath = Join-Path -Path $modulesPath -ChildPath "DependencyCycleResolver.psm1"

Import-Module $cycleDetectorPath -Force
Import-Module $cycleResolverPath -Force

# CrÃ©er un dossier temporaire pour les tests
$testTempDir = Join-Path -Path $env:TEMP -ChildPath "DependencyCycleTests"
if (Test-Path -Path $testTempDir) {
    Remove-Item -Path $testTempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $testTempDir -Force | Out-Null

Describe "DependencyCycleResolver - Tests d'intÃ©gration" {
    BeforeAll {
        # Initialiser les modules
        Initialize-CycleDetector -Enabled $true -MaxDepth 100 -CacheEnabled $true
        Initialize-DependencyCycleResolver -Enabled $true -MaxIterations 10 -Strategy "MinimumImpact"
        
        # CrÃ©er des fichiers de test avec des dÃ©pendances cycliques
        $scriptA = @'
# Script A
. "$PSScriptRoot\ScriptB.ps1"
function Test-ScriptA {
    Write-Output "Script A"
    Test-ScriptB
}
'@
        
        $scriptB = @'
# Script B
. "$PSScriptRoot\ScriptC.ps1"
function Test-ScriptB {
    Write-Output "Script B"
    Test-ScriptC
}
'@
        
        $scriptC = @'
# Script C
. "$PSScriptRoot\ScriptA.ps1"
function Test-ScriptC {
    Write-Output "Script C"
    Test-ScriptA
}
'@
        
        # Enregistrer les scripts dans le dossier temporaire
        $scriptA | Out-File -FilePath (Join-Path -Path $testTempDir -ChildPath "ScriptA.ps1") -Encoding utf8
        $scriptB | Out-File -FilePath (Join-Path -Path $testTempDir -ChildPath "ScriptB.ps1") -Encoding utf8
        $scriptC | Out-File -FilePath (Join-Path -Path $testTempDir -ChildPath "ScriptC.ps1") -Encoding utf8
        
        # CrÃ©er un workflow n8n avec un cycle
        $workflowJson = @'
{
  "name": "Test Workflow",
  "nodes": [
    {
      "id": "NodeA",
      "name": "Node A",
      "type": "n8n-nodes-base/Start",
      "position": [100, 100]
    },
    {
      "id": "NodeB",
      "name": "Node B",
      "type": "n8n-nodes-base/Function",
      "position": [300, 100]
    },
    {
      "id": "NodeC",
      "name": "Node C",
      "type": "n8n-nodes-base/Function",
      "position": [500, 100]
    }
  ],
  "connections": [
    {
      "source": {
        "node": "NodeA",
        "output": "main"
      },
      "target": {
        "node": "NodeB",
        "input": "main"
      }
    },
    {
      "source": {
        "node": "NodeB",
        "output": "main"
      },
      "target": {
        "node": "NodeC",
        "input": "main"
      }
    },
    {
      "source": {
        "node": "NodeC",
        "output": "main"
      },
      "target": {
        "node": "NodeA",
        "input": "main"
      }
    }
  ]
}
'@
        
        $workflowJson | Out-File -FilePath (Join-Path -Path $testTempDir -ChildPath "TestWorkflow.json") -Encoding utf8
    }
    
    AfterAll {
        # Nettoyer les fichiers de test
        if (Test-Path -Path $testTempDir) {
            Remove-Item -Path $testTempDir -Recurse -Force
        }
    }
    
    Context "RÃ©solution de cycles dans un graphe" {
        It "Devrait rÃ©soudre un cycle simple" {
            # CrÃ©er un graphe avec un cycle
            $graph = @{
                "A" = @("B")
                "B" = @("C")
                "C" = @("A")
            }
            
            # DÃ©tecter le cycle
            $cycleResult = Find-Cycle -Graph $graph
            
            # VÃ©rifier que le cycle est dÃ©tectÃ©
            $cycleResult.HasCycle | Should -Be $true
            
            # RÃ©soudre le cycle
            $resolveResult = Resolve-DependencyCycle -CycleResult $cycleResult
            
            # VÃ©rifier que le cycle est rÃ©solu
            $resolveResult.Success | Should -Be $true
            $resolveResult.RemovedEdges.Count | Should -Be 1
            
            # VÃ©rifier que le graphe modifiÃ© n'a plus de cycle
            $newCycleCheck = Find-Cycle -Graph $resolveResult.Graph
            $newCycleCheck.HasCycle | Should -Be $false
        }
        
        It "Devrait rÃ©soudre un cycle complexe" {
            # CrÃ©er un graphe avec un cycle complexe
            $graph = @{
                "A" = @("B", "C")
                "B" = @("D", "E")
                "C" = @("F")
                "D" = @("G")
                "E" = @("H")
                "F" = @("I")
                "G" = @("J")
                "H" = @("K")
                "I" = @("A") # CrÃ©e un cycle A -> C -> F -> I -> A
                "J" = @()
                "K" = @()
            }
            
            # DÃ©tecter le cycle
            $cycleResult = Find-Cycle -Graph $graph
            
            # VÃ©rifier que le cycle est dÃ©tectÃ©
            $cycleResult.HasCycle | Should -Be $true
            
            # RÃ©soudre le cycle
            $resolveResult = Resolve-DependencyCycle -CycleResult $cycleResult
            
            # VÃ©rifier que le cycle est rÃ©solu
            $resolveResult.Success | Should -Be $true
            $resolveResult.RemovedEdges.Count | Should -Be 1
            
            # VÃ©rifier que le graphe modifiÃ© n'a plus de cycle
            $newCycleCheck = Find-Cycle -Graph $resolveResult.Graph
            $newCycleCheck.HasCycle | Should -Be $false
        }
    }
    
    Context "RÃ©solution de cycles dans des scripts PowerShell" {
        It "Devrait dÃ©tecter et rÃ©soudre un cycle de dÃ©pendances dans des scripts" {
            # DÃ©tecter et rÃ©soudre les cycles
            $resolveResult = Resolve-ScriptDependencyCycle -Path $testTempDir
            
            # VÃ©rifier que des cycles ont Ã©tÃ© dÃ©tectÃ©s et rÃ©solus
            $resolveResult.CyclesDetected | Should -BeGreaterThan 0
            $resolveResult.CyclesResolved | Should -BeGreaterThan 0
            $resolveResult.Success | Should -Be $true
            
            # VÃ©rifier que les arÃªtes ont Ã©tÃ© supprimÃ©es
            $resolveResult.RemovedEdges.Count | Should -BeGreaterThan 0
        }
    }
    
    Context "RÃ©solution de cycles dans des workflows n8n" {
        It "Devrait dÃ©tecter et rÃ©soudre un cycle dans un workflow n8n" {
            # Chemin du workflow de test
            $workflowPath = Join-Path -Path $testTempDir -ChildPath "TestWorkflow.json"
            
            # DÃ©tecter et rÃ©soudre les cycles
            $resolveResult = Resolve-WorkflowCycle -WorkflowPath $workflowPath
            
            # VÃ©rifier que des cycles ont Ã©tÃ© dÃ©tectÃ©s et rÃ©solus
            $resolveResult.CyclesDetected | Should -BeGreaterThan 0
            $resolveResult.CyclesResolved | Should -BeGreaterThan 0
            $resolveResult.Success | Should -Be $true
            
            # VÃ©rifier que les arÃªtes ont Ã©tÃ© supprimÃ©es
            $resolveResult.RemovedEdges.Count | Should -BeGreaterThan 0
            
            # VÃ©rifier que le workflow modifiÃ© n'a plus de cycle
            $newCycleCheck = Test-WorkflowCycles -WorkflowPath $workflowPath
            $newCycleCheck.HasCycle | Should -Be $false
        }
    }
    
    Context "Statistiques du rÃ©solveur de cycles" {
        It "Devrait fournir des statistiques sur les rÃ©solutions de cycles" {
            # Obtenir les statistiques
            $stats = Get-CycleResolverStatistics
            
            # VÃ©rifier que les statistiques sont disponibles
            $stats.TotalResolutions | Should -BeGreaterThan 0
            $stats.SuccessfulResolutions | Should -BeGreaterThan 0
            $stats.SuccessRate | Should -BeGreaterThan 0
        }
    }
}

# ExÃ©cuter les tests
Invoke-Pester -Path $PSScriptRoot -Output Detailed
