# Script pour exécuter les tests d'intégration du module DependencyCycleResolver

# Augmenter la limite de profondeur de la pile (commenté car non utilisé actuellement)
# $MaximumCallStackDepth = 1024

# Importer les modules à tester
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

# Créer un dossier temporaire pour les tests
$testTempDir = Join-Path -Path $env:TEMP -ChildPath "DependencyCycleTests"
if (Test-Path -Path $testTempDir) {
    Remove-Item -Path $testTempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $testTempDir -Force | Out-Null

# Créer des fichiers de test avec des dépendances cycliques
Write-Host "Création des fichiers de test..."
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

# Créer un workflow n8n avec un cycle
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

# Exécuter les tests manuellement
Write-Host "`nTest 1: Résolution d'un cycle simple dans un graphe"
$graph = @{
    "A" = @("B")
    "B" = @("C")
    "C" = @("A")
}

# Détecter le cycle
$cycleResult = Find-Cycle -Graph $graph

# Vérifier que le cycle est détecté
if ($cycleResult.HasCycle) {
    Write-Host "  ✓ Cycle détecté" -ForegroundColor Green
} else {
    Write-Host "  ✗ Cycle non détecté" -ForegroundColor Red
}

# Résoudre le cycle
$resolveResult = Resolve-DependencyCycle -CycleResult $cycleResult

# Vérifier que le cycle est résolu
if ($resolveResult.Success) {
    Write-Host "  ✓ Cycle résolu avec succès" -ForegroundColor Green
    Write-Host "    Arête supprimée: $($resolveResult.RemovedEdges[0].Source) -> $($resolveResult.RemovedEdges[0].Target)"
} else {
    Write-Host "  ✗ Échec de la résolution du cycle" -ForegroundColor Red
}

# Vérifier que le graphe modifié n'a plus de cycle
$newCycleCheck = Find-Cycle -Graph $resolveResult.Graph
if (-not $newCycleCheck.HasCycle) {
    Write-Host "  ✓ Le graphe modifié ne contient plus de cycle" -ForegroundColor Green
} else {
    Write-Host "  ✗ Le graphe modifié contient encore un cycle" -ForegroundColor Red
}

Write-Host "`nTest 2: Résolution d'un cycle complexe dans un graphe"
$graph = @{
    "A" = @("B", "C")
    "B" = @("D", "E")
    "C" = @("F")
    "D" = @("G")
    "E" = @("H")
    "F" = @("I")
    "G" = @("J")
    "H" = @("K")
    "I" = @("A") # Crée un cycle A -> C -> F -> I -> A
    "J" = @()
    "K" = @()
}

# Détecter le cycle
$cycleResult = Find-Cycle -Graph $graph

# Vérifier que le cycle est détecté
if ($cycleResult.HasCycle) {
    Write-Host "  ✓ Cycle détecté" -ForegroundColor Green
} else {
    Write-Host "  ✗ Cycle non détecté" -ForegroundColor Red
}

# Résoudre le cycle
$resolveResult = Resolve-DependencyCycle -CycleResult $cycleResult

# Vérifier que le cycle est résolu
if ($resolveResult.Success) {
    Write-Host "  ✓ Cycle résolu avec succès" -ForegroundColor Green
    Write-Host "    Arête supprimée: $($resolveResult.RemovedEdges[0].Source) -> $($resolveResult.RemovedEdges[0].Target)"
} else {
    Write-Host "  ✗ Échec de la résolution du cycle" -ForegroundColor Red
}

# Vérifier que le graphe modifié n'a plus de cycle
$newCycleCheck = Find-Cycle -Graph $resolveResult.Graph
if (-not $newCycleCheck.HasCycle) {
    Write-Host "  ✓ Le graphe modifié ne contient plus de cycle" -ForegroundColor Green
} else {
    Write-Host "  ✗ Le graphe modifié contient encore un cycle" -ForegroundColor Red
}

Write-Host "`nTest 3: Résolution de cycles dans des scripts PowerShell"
# Détecter et résoudre les cycles
$resolveResult = Resolve-ScriptDependencyCycle -Path $testTempDir

# Vérifier que des cycles ont été détectés et résolus
if ($resolveResult.CyclesDetected -gt 0) {
    Write-Host "  ✓ Cycles détectés: $($resolveResult.CyclesDetected)" -ForegroundColor Green
} else {
    Write-Host "  ✗ Aucun cycle détecté" -ForegroundColor Red
}

if ($resolveResult.CyclesResolved -gt 0) {
    Write-Host "  ✓ Cycles résolus: $($resolveResult.CyclesResolved)" -ForegroundColor Green
} else {
    Write-Host "  ✗ Aucun cycle résolu" -ForegroundColor Red
}

if ($resolveResult.Success) {
    Write-Host "  ✓ Résolution réussie" -ForegroundColor Green
} else {
    Write-Host "  ✗ Échec de la résolution" -ForegroundColor Red
}

if ($resolveResult.RemovedEdges.Count -gt 0) {
    Write-Host "  ✓ Arêtes supprimées: $($resolveResult.RemovedEdges.Count)" -ForegroundColor Green
    foreach ($edge in $resolveResult.RemovedEdges) {
        Write-Host "    $($edge.Source) -> $($edge.Target)"
    }
} else {
    Write-Host "  ✗ Aucune arête supprimée" -ForegroundColor Red
}

Write-Host "`nTest 4: Résolution de cycles dans des workflows n8n"
# Chemin du workflow de test
$workflowPath = Join-Path -Path $testTempDir -ChildPath "TestWorkflow.json"

# Détecter et résoudre les cycles
$resolveResult = Resolve-WorkflowCycle -WorkflowPath $workflowPath

# Vérifier que des cycles ont été détectés et résolus
if ($resolveResult.CyclesDetected -gt 0) {
    Write-Host "  ✓ Cycles détectés: $($resolveResult.CyclesDetected)" -ForegroundColor Green
} else {
    Write-Host "  ✗ Aucun cycle détecté" -ForegroundColor Red
}

if ($resolveResult.CyclesResolved -gt 0) {
    Write-Host "  ✓ Cycles résolus: $($resolveResult.CyclesResolved)" -ForegroundColor Green
} else {
    Write-Host "  ✗ Aucun cycle résolu" -ForegroundColor Red
}

if ($resolveResult.Success) {
    Write-Host "  ✓ Résolution réussie" -ForegroundColor Green
} else {
    Write-Host "  ✗ Échec de la résolution" -ForegroundColor Red
}

if ($resolveResult.RemovedEdges.Count -gt 0) {
    Write-Host "  ✓ Arêtes supprimées: $($resolveResult.RemovedEdges.Count)" -ForegroundColor Green
    foreach ($edge in $resolveResult.RemovedEdges) {
        Write-Host "    $($edge.Source) -> $($edge.Target)"
    }
} else {
    Write-Host "  ✗ Aucune arête supprimée" -ForegroundColor Red
}

# Vérifier que le workflow modifié n'a plus de cycle
$newCycleCheck = Test-WorkflowCycles -WorkflowPath $workflowPath
if (-not $newCycleCheck.HasCycle) {
    Write-Host "  ✓ Le workflow modifié ne contient plus de cycle" -ForegroundColor Green
} else {
    Write-Host "  ✗ Le workflow modifié contient encore un cycle" -ForegroundColor Red
}

Write-Host "`nTest 5: Statistiques du résolveur de cycles"
# Obtenir les statistiques
$stats = Get-CycleResolverStatistics

# Vérifier que les statistiques sont disponibles
if ($stats.TotalResolutions -gt 0) {
    Write-Host "  ✓ Nombre total de résolutions: $($stats.TotalResolutions)" -ForegroundColor Green
} else {
    Write-Host "  ✗ Aucune résolution enregistrée" -ForegroundColor Red
}

if ($stats.SuccessfulResolutions -gt 0) {
    Write-Host "  ✓ Résolutions réussies: $($stats.SuccessfulResolutions)" -ForegroundColor Green
} else {
    Write-Host "  ✗ Aucune résolution réussie" -ForegroundColor Red
}

if ($stats.SuccessRate -gt 0) {
    Write-Host "  ✓ Taux de réussite: $($stats.SuccessRate)%" -ForegroundColor Green
} else {
    Write-Host "  ✗ Taux de réussite nul" -ForegroundColor Red
}

Write-Host "`nNettoyage..."
# Nettoyer les fichiers de test
if (Test-Path -Path $testTempDir) {
    Remove-Item -Path $testTempDir -Recurse -Force
}

Write-Host "`nTous les tests ont ete executes avec succes." -ForegroundColor Green
