#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires simplifiés pour le module DependencyCycleResolver.
.DESCRIPTION
    Ce script contient des tests unitaires simplifiés pour vérifier le bon fonctionnement
    du module DependencyCycleResolver sans utiliser Pester.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-20
#>

# Chemin du module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\DependencyCycleResolver.psm1"

# Vérifier si le module existe
if (-not (Test-Path -Path $modulePath)) {
    throw "Le module DependencyCycleResolver.psm1 n'existe pas à l'emplacement spécifié: $modulePath"
}

# Importer le module à tester
Import-Module $modulePath -Force

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

# Test 1: Initialize-DependencyCycleResolver avec les paramètres par défaut
$result = Test-Function -Name "Initialize-DependencyCycleResolver avec les paramètres par défaut" -Test {
    $result = Initialize-DependencyCycleResolver
    return $result -eq $true
}
if ($result) { $testsPassed++ } else { $testsFailed++ }

# Test 2: Initialize-DependencyCycleResolver avec des paramètres personnalisés
$result = Test-Function -Name "Initialize-DependencyCycleResolver avec des paramètres personnalisés" -Test {
    $result = Initialize-DependencyCycleResolver -Enabled $false -MaxIterations 5 -Strategy "Random"
    return $result -eq $true
}
if ($result) { $testsPassed++ } else { $testsFailed++ }

# Test 3: Resolve-DependencyCycle avec un cycle simple
$result = Test-Function -Name "Resolve-DependencyCycle avec un cycle simple" -Test {
    # Réinitialiser le résolveur
    Initialize-DependencyCycleResolver -Enabled $true -MaxIterations 10 -Strategy "MinimumImpact"
    
    # Créer un graphe avec un cycle
    $graph = @{
        "A" = @("B")
        "B" = @("C")
        "C" = @("A")
    }
    
    # Créer un objet CycleResult
    $cycleResult = [PSCustomObject]@{
        HasCycle = $true
        CyclePath = @("A", "B", "C", "A")
        Graph = $graph
    }
    
    # Résoudre le cycle
    $resolveResult = Resolve-DependencyCycle -CycleResult $cycleResult
    
    # Vérifier que le cycle est résolu
    return $resolveResult.Success -eq $true -and $resolveResult.RemovedEdges.Count -eq 1
}
if ($result) { $testsPassed++ } else { $testsFailed++ }

# Test 4: Resolve-DependencyCycle sans cycle
$result = Test-Function -Name "Resolve-DependencyCycle sans cycle" -Test {
    # Réinitialiser le résolveur
    Initialize-DependencyCycleResolver -Enabled $true -MaxIterations 10 -Strategy "MinimumImpact"
    
    # Créer un graphe sans cycle
    $graph = @{
        "A" = @("B")
        "B" = @("C")
        "C" = @()
    }
    
    # Créer un objet CycleResult
    $cycleResult = [PSCustomObject]@{
        HasCycle = $false
        CyclePath = @()
        Graph = $graph
    }
    
    # Résoudre le cycle
    $resolveResult = Resolve-DependencyCycle -CycleResult $cycleResult
    
    # Vérifier que la fonction retourne false
    return $resolveResult -eq $false
}
if ($result) { $testsPassed++ } else { $testsFailed++ }

# Test 5: Resolve-DependencyCycle avec résolveur désactivé
$result = Test-Function -Name "Resolve-DependencyCycle avec résolveur désactivé" -Test {
    # Désactiver le résolveur
    Initialize-DependencyCycleResolver -Enabled $false -MaxIterations 10 -Strategy "MinimumImpact"
    
    # Créer un graphe avec un cycle
    $graph = @{
        "A" = @("B")
        "B" = @("C")
        "C" = @("A")
    }
    
    # Créer un objet CycleResult
    $cycleResult = [PSCustomObject]@{
        HasCycle = $true
        CyclePath = @("A", "B", "C", "A")
        Graph = $graph
    }
    
    # Résoudre le cycle
    $resolveResult = Resolve-DependencyCycle -CycleResult $cycleResult
    
    # Vérifier que la fonction retourne false
    return $resolveResult -eq $false
}
if ($result) { $testsPassed++ } else { $testsFailed++ }

# Test 6: Get-CycleResolverStatistics
$result = Test-Function -Name "Get-CycleResolverStatistics" -Test {
    # Réinitialiser le résolveur
    Initialize-DependencyCycleResolver -Enabled $true -MaxIterations 10 -Strategy "MinimumImpact"
    
    # Obtenir les statistiques
    $stats = Get-CycleResolverStatistics
    
    # Vérifier que les statistiques sont disponibles
    return $stats -ne $null -and 
           $stats.Enabled -is [bool] -and 
           $stats.MaxIterations -is [int] -and 
           $stats.Strategy -is [string] -and 
           $stats.TotalResolutions -is [int] -and 
           $stats.SuccessfulResolutions -is [int] -and 
           $stats.FailedResolutions -is [int] -and 
           $stats.SuccessRate -is [double]
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
