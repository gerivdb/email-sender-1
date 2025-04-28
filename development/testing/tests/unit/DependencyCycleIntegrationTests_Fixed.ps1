#Requires -Version 5.1
<#
.SYNOPSIS
    Tests d'intégration améliorés pour les modules DependencyCycleResolver et CycleDetector.
.DESCRIPTION
    Ce script contient des tests d'intégration améliorés pour vérifier le bon fonctionnement
    des modules DependencyCycleResolver et CycleDetector ensemble, en utilisant le wrapper
    CycleDetectorWrapper pour résoudre les problèmes d'importation.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-20
#>

# Chemins des modules à tester
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules"
$cycleDetectorWrapperPath = Join-Path -Path $modulesPath -ChildPath "CycleDetectorWrapper.psm1"
$cycleResolverPath = Join-Path -Path $modulesPath -ChildPath "DependencyCycleResolver.psm1"

# Vérifier si les modules existent
if (-not (Test-Path -Path $cycleDetectorWrapperPath)) {
    throw "Le module CycleDetectorWrapper.psm1 n'existe pas à l'emplacement spécifié: $cycleDetectorWrapperPath"
}

if (-not (Test-Path -Path $cycleResolverPath)) {
    throw "Le module DependencyCycleResolver.psm1 n'existe pas à l'emplacement spécifié: $cycleResolverPath"
}

# Fonction pour exécuter un test
function Test-Function {
    param (
        [string]$Name,
        [scriptblock]$Test
    )
    
    Write-Host "Test: $Name" -ForegroundColor Cyan
    
    try {
        $result = & $Test
        if ($result) {
            Write-Host "  Réussi" -ForegroundColor Green
            return $true
        } else {
            Write-Host "  Échoué" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "  Erreur: $_" -ForegroundColor Red
        return $false
    }
}

# Initialiser les résultats des tests
$testsPassed = 0
$testsFailed = 0

# Test 1: Importer les modules
$result = Test-Function -Name "Importer les modules" -Test {
    try {
        # Supprimer les modules s'ils sont déjà importés
        if (Get-Module -Name CycleDetectorWrapper) {
            Remove-Module -Name CycleDetectorWrapper -Force
        }
        
        if (Get-Module -Name DependencyCycleResolver) {
            Remove-Module -Name DependencyCycleResolver -Force
        }
        
        # Importer les modules
        Import-Module $cycleDetectorWrapperPath -Force
        Import-Module $cycleResolverPath -Force
        
        # Vérifier que les modules sont importés
        $cycleDetectorImported = Get-Module -Name CycleDetectorWrapper
        $cycleResolverImported = Get-Module -Name DependencyCycleResolver
        
        return $cycleDetectorImported -ne $null -and $cycleResolverImported -ne $null
    } catch {
        Write-Host "  Erreur lors de l'importation des modules: $_" -ForegroundColor Red
        return $false
    }
}
if ($result) { $testsPassed++ } else { $testsFailed++ }

# Test 2: Initialiser les modules
$result = Test-Function -Name "Initialiser les modules" -Test {
    try {
        # Initialiser les modules
        $cycleDetectorResult = Initialize-CycleDetector -Enabled $true -MaxDepth 100 -CacheEnabled $true
        $cycleResolverResult = Initialize-DependencyCycleResolver -Enabled $true -MaxIterations 10 -Strategy "MinimumImpact"
        
        return $cycleDetectorResult -ne $null -and $cycleResolverResult -eq $true
    } catch {
        Write-Host "  Erreur lors de l'initialisation des modules: $_" -ForegroundColor Red
        return $false
    }
}
if ($result) { $testsPassed++ } else { $testsFailed++ }

# Test 3: Intégration Find-Cycle et Resolve-DependencyCycle
$result = Test-Function -Name "Intégration Find-Cycle et Resolve-DependencyCycle" -Test {
    try {
        # Créer un graphe avec un cycle
        $graph = @{
            "A" = @("B")
            "B" = @("C")
            "C" = @("A")
        }
        
        # Détecter le cycle
        $cycleResult = Find-Cycle -Graph $graph
        
        # Vérifier que le cycle est détecté
        if (-not $cycleResult.HasCycle) {
            Write-Host "  Le cycle n'a pas été détecté" -ForegroundColor Red
            return $false
        }
        
        # Créer un objet CycleResult compatible avec Resolve-DependencyCycle
        $compatibleCycleResult = [PSCustomObject]@{
            HasCycle  = $cycleResult.HasCycle
            CyclePath = $cycleResult.CyclePath
            Graph     = $graph
        }
        
        # Résoudre le cycle
        $resolveResult = Resolve-DependencyCycle -CycleResult $compatibleCycleResult
        
        # Vérifier que le cycle est résolu
        if (-not $resolveResult.Success) {
            Write-Host "  Le cycle n'a pas été résolu" -ForegroundColor Red
            return $false
        }
        
        # Vérifier que le graphe modifié n'a plus de cycle
        $newCycleCheck = Find-Cycle -Graph $resolveResult.Graph
        
        return -not $newCycleCheck.HasCycle
    } catch {
        Write-Host "  Erreur lors de l'intégration Find-Cycle et Resolve-DependencyCycle: $_" -ForegroundColor Red
        return $false
    }
}
if ($result) { $testsPassed++ } else { $testsFailed++ }

# Test 4: Test de workflow n8n
$result = Test-Function -Name "Test de workflow n8n" -Test {
    try {
        # Créer un dossier temporaire pour les tests
        $testTempDir = Join-Path -Path $env:TEMP -ChildPath "DependencyCycleTests"
        if (Test-Path -Path $testTempDir) {
            Remove-Item -Path $testTempDir -Recurse -Force
        }
        New-Item -ItemType Directory -Path $testTempDir -Force | Out-Null
        
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
        
        $workflowPath = Join-Path -Path $testTempDir -ChildPath "TestWorkflow.json"
        $workflowJson | Out-File -FilePath $workflowPath -Encoding utf8
        
        # Tester le workflow
        $cycleResult = Test-WorkflowCycles -WorkflowPath $workflowPath
        
        # Vérifier que le cycle est détecté
        if (-not $cycleResult.HasCycle) {
            Write-Host "  Le cycle n'a pas été détecté dans le workflow" -ForegroundColor Red
            return $false
        }
        
        # Nettoyer les fichiers de test
        if (Test-Path -Path $testTempDir) {
            Remove-Item -Path $testTempDir -Recurse -Force
        }
        
        return $true
    } catch {
        Write-Host "  Erreur lors du test de workflow n8n: $_" -ForegroundColor Red
        return $false
    }
}
if ($result) { $testsPassed++ } else { $testsFailed++ }

# Afficher le résumé des tests
Write-Host "`nRésumé des tests:" -ForegroundColor Yellow
Write-Host "  Tests réussis: $testsPassed" -ForegroundColor Green
Write-Host "  Tests échoués: $testsFailed" -ForegroundColor Red
Write-Host "  Total: $($testsPassed + $testsFailed)" -ForegroundColor Yellow

# Retourner un code de sortie en fonction des résultats des tests
if ($testsFailed -eq 0) {
    Write-Host "`nTous les tests ont été exécutés avec succès." -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont échoué." -ForegroundColor Red
    exit 1
}
