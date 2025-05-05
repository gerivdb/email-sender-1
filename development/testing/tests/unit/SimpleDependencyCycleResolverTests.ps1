#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires simplifiÃ©s pour le module DependencyCycleResolver.
.DESCRIPTION
    Ce script contient des tests unitaires simplifiÃ©s pour vÃ©rifier le bon fonctionnement
    du module DependencyCycleResolver sans utiliser Pester.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-04-20
#>

# Chemin du module Ã  tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\DependencyCycleResolver.psm1"

# VÃ©rifier si le module existe
if (-not (Test-Path -Path $modulePath)) {
    throw "Le module DependencyCycleResolver.psm1 n'existe pas Ã  l'emplacement spÃ©cifiÃ©: $modulePath"
}

# Importer le module Ã  tester
Import-Module $modulePath -Force

# Fonction pour exÃ©cuter un test
function Test-Function {
    param (
        [string]$Name,
        [scriptblock]$Test
    )
    
    Write-Host "Test: $Name" -ForegroundColor Cyan
    
    try {
        $result = & $Test
        if ($result) {
            Write-Host "  RÃ©ussi" -ForegroundColor Green
            return $true
        } else {
            Write-Host "  Ã‰chouÃ©" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "  Erreur: $_" -ForegroundColor Red
        return $false
    }
}

# Initialiser les rÃ©sultats des tests
$testsPassed = 0
$testsFailed = 0

# Test 1: Initialize-DependencyCycleResolver avec les paramÃ¨tres par dÃ©faut
$result = Test-Function -Name "Initialize-DependencyCycleResolver avec les paramÃ¨tres par dÃ©faut" -Test {
    $result = Initialize-DependencyCycleResolver
    return $result -eq $true
}
if ($result) { $testsPassed++ } else { $testsFailed++ }

# Test 2: Initialize-DependencyCycleResolver avec des paramÃ¨tres personnalisÃ©s
$result = Test-Function -Name "Initialize-DependencyCycleResolver avec des paramÃ¨tres personnalisÃ©s" -Test {
    $result = Initialize-DependencyCycleResolver -Enabled $false -MaxIterations 5 -Strategy "Random"
    return $result -eq $true
}
if ($result) { $testsPassed++ } else { $testsFailed++ }

# Test 3: Resolve-DependencyCycle avec un cycle simple
$result = Test-Function -Name "Resolve-DependencyCycle avec un cycle simple" -Test {
    # RÃ©initialiser le rÃ©solveur
    Initialize-DependencyCycleResolver -Enabled $true -MaxIterations 10 -Strategy "MinimumImpact"
    
    # CrÃ©er un graphe avec un cycle
    $graph = @{
        "A" = @("B")
        "B" = @("C")
        "C" = @("A")
    }
    
    # CrÃ©er un objet CycleResult
    $cycleResult = [PSCustomObject]@{
        HasCycle = $true
        CyclePath = @("A", "B", "C", "A")
        Graph = $graph
    }
    
    # RÃ©soudre le cycle
    $resolveResult = Resolve-DependencyCycle -CycleResult $cycleResult
    
    # VÃ©rifier que le cycle est rÃ©solu
    return $resolveResult.Success -eq $true -and $resolveResult.RemovedEdges.Count -eq 1
}
if ($result) { $testsPassed++ } else { $testsFailed++ }

# Test 4: Resolve-DependencyCycle sans cycle
$result = Test-Function -Name "Resolve-DependencyCycle sans cycle" -Test {
    # RÃ©initialiser le rÃ©solveur
    Initialize-DependencyCycleResolver -Enabled $true -MaxIterations 10 -Strategy "MinimumImpact"
    
    # CrÃ©er un graphe sans cycle
    $graph = @{
        "A" = @("B")
        "B" = @("C")
        "C" = @()
    }
    
    # CrÃ©er un objet CycleResult
    $cycleResult = [PSCustomObject]@{
        HasCycle = $false
        CyclePath = @()
        Graph = $graph
    }
    
    # RÃ©soudre le cycle
    $resolveResult = Resolve-DependencyCycle -CycleResult $cycleResult
    
    # VÃ©rifier que la fonction retourne false
    return $resolveResult -eq $false
}
if ($result) { $testsPassed++ } else { $testsFailed++ }

# Test 5: Resolve-DependencyCycle avec rÃ©solveur dÃ©sactivÃ©
$result = Test-Function -Name "Resolve-DependencyCycle avec rÃ©solveur dÃ©sactivÃ©" -Test {
    # DÃ©sactiver le rÃ©solveur
    Initialize-DependencyCycleResolver -Enabled $false -MaxIterations 10 -Strategy "MinimumImpact"
    
    # CrÃ©er un graphe avec un cycle
    $graph = @{
        "A" = @("B")
        "B" = @("C")
        "C" = @("A")
    }
    
    # CrÃ©er un objet CycleResult
    $cycleResult = [PSCustomObject]@{
        HasCycle = $true
        CyclePath = @("A", "B", "C", "A")
        Graph = $graph
    }
    
    # RÃ©soudre le cycle
    $resolveResult = Resolve-DependencyCycle -CycleResult $cycleResult
    
    # VÃ©rifier que la fonction retourne false
    return $resolveResult -eq $false
}
if ($result) { $testsPassed++ } else { $testsFailed++ }

# Test 6: Get-CycleResolverStatistics
$result = Test-Function -Name "Get-CycleResolverStatistics" -Test {
    # RÃ©initialiser le rÃ©solveur
    Initialize-DependencyCycleResolver -Enabled $true -MaxIterations 10 -Strategy "MinimumImpact"
    
    # Obtenir les statistiques
    $stats = Get-CycleResolverStatistics
    
    # VÃ©rifier que les statistiques sont disponibles
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

# Afficher le rÃ©sumÃ© des tests
Write-Host "`nRÃ©sumÃ© des tests:" -ForegroundColor Yellow
Write-Host "  Tests rÃ©ussis: $testsPassed" -ForegroundColor Green
Write-Host "  Tests Ã©chouÃ©s: $testsFailed" -ForegroundColor Red
Write-Host "  Total: $($testsPassed + $testsFailed)" -ForegroundColor Yellow

# Retourner un code de sortie en fonction des rÃ©sultats des tests
if ($testsFailed -eq 0) {
    Write-Host "`nTous les tests ont Ã©tÃ© exÃ©cutÃ©s avec succÃ¨s." -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont Ã©chouÃ©." -ForegroundColor Red
    exit 1
}
