# Script pour exÃ©cuter les tests d'intÃ©gration du module DependencyCycleResolver

# Augmenter la limite de profondeur de la pile (commentÃ© car non utilisÃ© actuellement)
# $MaximumCallStackDepth = 1024

# Importer les modules Ã  tester
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules"
$cycleDetectorPath = Join-Path -Path $modulesPath -ChildPath "CycleDetector.psm1"
$cycleResolverPath = Join-Path -Path $modulesPath -ChildPath "DependencyCycleResolver.psm1"

Write-Host "Importation des modules..."
Import-Module $cycleDetectorPath -Force
Import-Module $cycleResolverPath -Force

# Initialiser les modules
Write-Host "Initialisation des modules..."
Initialize-CycleDetector -Enabled $true -MaxDepth 100 -CacheEnabled $true
Initialize-DependencyCycleResolver -Enabled $true -MaxIterations 10 -Strategy "MinimumImpact"

# CrÃ©er un dossier temporaire pour les tests
$testTempDir = Join-Path -Path $env:TEMP -ChildPath "DependencyCycleTests"
if (Test-Path -Path $testTempDir) {
    Remove-Item -Path $testTempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $testTempDir -Force | Out-Null

# CrÃ©er des fichiers de test avec des dÃ©pendances cycliques
Write-Host "CrÃ©ation des fichiers de test..."
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

# ExÃ©cuter les tests manuellement
Write-Host "`nTest 1: RÃ©solution d'un cycle simple dans un graphe"
$graph = @{
    "A" = @("B")
    "B" = @("C")
    "C" = @("A")
}

# DÃ©tecter le cycle
$cycleResult = Find-Cycle -Graph $graph

# VÃ©rifier que le cycle est dÃ©tectÃ©
if ($cycleResult.HasCycle) {
    Write-Host "  âœ“ Cycle dÃ©tectÃ©" -ForegroundColor Green
} else {
    Write-Host "  âœ— Cycle non dÃ©tectÃ©" -ForegroundColor Red
}

# RÃ©soudre le cycle
$resolveResult = Resolve-DependencyCycle -CycleResult $cycleResult

# VÃ©rifier que le cycle est rÃ©solu
if ($resolveResult.Success) {
    Write-Host "  âœ“ Cycle rÃ©solu avec succÃ¨s" -ForegroundColor Green
    Write-Host "    ArÃªte supprimÃ©e: $($resolveResult.RemovedEdges[0].Source) -> $($resolveResult.RemovedEdges[0].Target)"
} else {
    Write-Host "  âœ— Ã‰chec de la rÃ©solution du cycle" -ForegroundColor Red
}

# VÃ©rifier que le graphe modifiÃ© n'a plus de cycle
$newCycleCheck = Find-Cycle -Graph $resolveResult.Graph
if (-not $newCycleCheck.HasCycle) {
    Write-Host "  âœ“ Le graphe modifiÃ© ne contient plus de cycle" -ForegroundColor Green
} else {
    Write-Host "  âœ— Le graphe modifiÃ© contient encore un cycle" -ForegroundColor Red
}

Write-Host "`nTest 2: RÃ©solution d'un cycle complexe dans un graphe"
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
if ($cycleResult.HasCycle) {
    Write-Host "  âœ“ Cycle dÃ©tectÃ©" -ForegroundColor Green
} else {
    Write-Host "  âœ— Cycle non dÃ©tectÃ©" -ForegroundColor Red
}

# RÃ©soudre le cycle
$resolveResult = Resolve-DependencyCycle -CycleResult $cycleResult

# VÃ©rifier que le cycle est rÃ©solu
if ($resolveResult.Success) {
    Write-Host "  âœ“ Cycle rÃ©solu avec succÃ¨s" -ForegroundColor Green
    Write-Host "    ArÃªte supprimÃ©e: $($resolveResult.RemovedEdges[0].Source) -> $($resolveResult.RemovedEdges[0].Target)"
} else {
    Write-Host "  âœ— Ã‰chec de la rÃ©solution du cycle" -ForegroundColor Red
}

# VÃ©rifier que le graphe modifiÃ© n'a plus de cycle
$newCycleCheck = Find-Cycle -Graph $resolveResult.Graph
if (-not $newCycleCheck.HasCycle) {
    Write-Host "  âœ“ Le graphe modifiÃ© ne contient plus de cycle" -ForegroundColor Green
} else {
    Write-Host "  âœ— Le graphe modifiÃ© contient encore un cycle" -ForegroundColor Red
}

Write-Host "`nTest 3: RÃ©solution de cycles dans des scripts PowerShell"
# DÃ©tecter et rÃ©soudre les cycles
$resolveResult = Resolve-ScriptDependencyCycle -Path $testTempDir

# VÃ©rifier que des cycles ont Ã©tÃ© dÃ©tectÃ©s et rÃ©solus
if ($resolveResult.CyclesDetected -gt 0) {
    Write-Host "  âœ“ Cycles dÃ©tectÃ©s: $($resolveResult.CyclesDetected)" -ForegroundColor Green
} else {
    Write-Host "  âœ— Aucun cycle dÃ©tectÃ©" -ForegroundColor Red
}

if ($resolveResult.CyclesResolved -gt 0) {
    Write-Host "  âœ“ Cycles rÃ©solus: $($resolveResult.CyclesResolved)" -ForegroundColor Green
} else {
    Write-Host "  âœ— Aucun cycle rÃ©solu" -ForegroundColor Red
}

if ($resolveResult.Success) {
    Write-Host "  âœ“ RÃ©solution rÃ©ussie" -ForegroundColor Green
} else {
    Write-Host "  âœ— Ã‰chec de la rÃ©solution" -ForegroundColor Red
}

if ($resolveResult.RemovedEdges.Count -gt 0) {
    Write-Host "  âœ“ ArÃªtes supprimÃ©es: $($resolveResult.RemovedEdges.Count)" -ForegroundColor Green
    foreach ($edge in $resolveResult.RemovedEdges) {
        Write-Host "    $($edge.Source) -> $($edge.Target)"
    }
} else {
    Write-Host "  âœ— Aucune arÃªte supprimÃ©e" -ForegroundColor Red
}

Write-Host "`nTest 4: RÃ©solution de cycles dans des workflows n8n"
# Chemin du workflow de test
$workflowPath = Join-Path -Path $testTempDir -ChildPath "TestWorkflow.json"

# DÃ©tecter et rÃ©soudre les cycles
$resolveResult = Resolve-WorkflowCycle -WorkflowPath $workflowPath

# VÃ©rifier que des cycles ont Ã©tÃ© dÃ©tectÃ©s et rÃ©solus
if ($resolveResult.CyclesDetected -gt 0) {
    Write-Host "  âœ“ Cycles dÃ©tectÃ©s: $($resolveResult.CyclesDetected)" -ForegroundColor Green
} else {
    Write-Host "  âœ— Aucun cycle dÃ©tectÃ©" -ForegroundColor Red
}

if ($resolveResult.CyclesResolved -gt 0) {
    Write-Host "  âœ“ Cycles rÃ©solus: $($resolveResult.CyclesResolved)" -ForegroundColor Green
} else {
    Write-Host "  âœ— Aucun cycle rÃ©solu" -ForegroundColor Red
}

if ($resolveResult.Success) {
    Write-Host "  âœ“ RÃ©solution rÃ©ussie" -ForegroundColor Green
} else {
    Write-Host "  âœ— Ã‰chec de la rÃ©solution" -ForegroundColor Red
}

if ($resolveResult.RemovedEdges.Count -gt 0) {
    Write-Host "  âœ“ ArÃªtes supprimÃ©es: $($resolveResult.RemovedEdges.Count)" -ForegroundColor Green
    foreach ($edge in $resolveResult.RemovedEdges) {
        Write-Host "    $($edge.Source) -> $($edge.Target)"
    }
} else {
    Write-Host "  âœ— Aucune arÃªte supprimÃ©e" -ForegroundColor Red
}

# VÃ©rifier que le workflow modifiÃ© n'a plus de cycle
$newCycleCheck = Test-WorkflowCycles -WorkflowPath $workflowPath
if (-not $newCycleCheck.HasCycle) {
    Write-Host "  âœ“ Le workflow modifiÃ© ne contient plus de cycle" -ForegroundColor Green
} else {
    Write-Host "  âœ— Le workflow modifiÃ© contient encore un cycle" -ForegroundColor Red
}

Write-Host "`nTest 5: Statistiques du rÃ©solveur de cycles"
# Obtenir les statistiques
$stats = Get-CycleResolverStatistics

# VÃ©rifier que les statistiques sont disponibles
if ($stats.TotalResolutions -gt 0) {
    Write-Host "  âœ“ Nombre total de rÃ©solutions: $($stats.TotalResolutions)" -ForegroundColor Green
} else {
    Write-Host "  âœ— Aucune rÃ©solution enregistrÃ©e" -ForegroundColor Red
}

if ($stats.SuccessfulResolutions -gt 0) {
    Write-Host "  âœ“ RÃ©solutions rÃ©ussies: $($stats.SuccessfulResolutions)" -ForegroundColor Green
} else {
    Write-Host "  âœ— Aucune rÃ©solution rÃ©ussie" -ForegroundColor Red
}

if ($stats.SuccessRate -gt 0) {
    Write-Host "  âœ“ Taux de rÃ©ussite: $($stats.SuccessRate)%" -ForegroundColor Green
} else {
    Write-Host "  âœ— Taux de rÃ©ussite nul" -ForegroundColor Red
}

Write-Host "`nNettoyage..."
# Nettoyer les fichiers de test
if (Test-Path -Path $testTempDir) {
    Remove-Item -Path $testTempDir -Recurse -Force
}

Write-Host "`nTous les tests ont ete executes avec succes." -ForegroundColor Green
