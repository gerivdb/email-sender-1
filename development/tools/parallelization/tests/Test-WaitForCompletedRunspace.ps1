# Script de test pour vérifier les améliorations apportées à Wait-ForCompletedRunspace
#Requires -Version 5.1

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Import-Module $modulePath -Force

# Initialiser le module
Initialize-UnifiedParallel

# Fonction pour créer un runspace qui s'exécute pendant un certain temps
function New-TestRunspace {
    param(
        [Parameter(Mandatory = $true)]
        [int]$SleepSeconds,
        
        [Parameter(Mandatory = $false)]
        [switch]$ThrowError,
        
        [Parameter(Mandatory = $false)]
        [switch]$NullHandle
    )
    
    # Créer un PowerShell
    $ps = [powershell]::Create()
    
    # Ajouter un script qui s'exécute pendant un certain temps
    $null = $ps.AddScript({
        param($SleepSeconds, $ThrowError)
        
        # Simuler un traitement long
        Start-Sleep -Seconds $SleepSeconds
        
        # Simuler une erreur si demandé
        if ($ThrowError) {
            throw "Erreur simulée dans le runspace"
        }
        
        return "Runspace terminé après $SleepSeconds secondes"
    })
    
    # Ajouter les arguments
    $null = $ps.AddArgument($SleepSeconds)
    $null = $ps.AddArgument($ThrowError)
    
    # Créer un objet runspace
    $runspace = [PSCustomObject]@{
        PowerShell = $ps
        Handle     = if ($NullHandle) { $null } else { $ps.BeginInvoke() }
    }
    
    return $runspace
}

# Fonction pour tester Wait-ForCompletedRunspace avec différents scénarios
function Test-WaitForCompletedRunspaceScenario {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScenarioName,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$TestScript,
        
        [Parameter(Mandatory = $false)]
        [switch]$ExpectSuccess
    )
    
    Write-Host "`n=== Test de Wait-ForCompletedRunspace: $ScenarioName ===" -ForegroundColor Cyan
    
    try {
        & $TestScript
        
        if ($ExpectSuccess) {
            Write-Host "✅ Test réussi: $ScenarioName" -ForegroundColor Green
        } else {
            Write-Host "❌ Test échoué: $ScenarioName (devrait échouer mais a réussi)" -ForegroundColor Red
        }
    } catch {
        if ($ExpectSuccess) {
            Write-Host "❌ Test échoué: $ScenarioName" -ForegroundColor Red
            Write-Host "   Erreur: $_" -ForegroundColor Red
        } else {
            Write-Host "✅ Test réussi: $ScenarioName (échec attendu)" -ForegroundColor Green
        }
    }
}

# Test 1: Attente normale sans timeout
Test-WaitForCompletedRunspaceScenario -ScenarioName "Attente normale sans timeout" -ExpectSuccess -TestScript {
    # Créer des runspaces qui s'exécutent pendant différentes durées
    $runspaces = @(
        (New-TestRunspace -SleepSeconds 1),
        (New-TestRunspace -SleepSeconds 2),
        (New-TestRunspace -SleepSeconds 3)
    )
    
    # Attendre que tous les runspaces soient complétés
    $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress
    
    # Vérifier que tous les runspaces sont complétés
    if ($completedRunspaces.Count -ne 3) {
        throw "Nombre incorrect de runspaces complétés: $($completedRunspaces.Count) au lieu de 3"
    }
    
    Write-Host "  Nombre de runspaces complétés: $($completedRunspaces.Count)" -ForegroundColor Yellow
}

# Test 2: Attente avec timeout
Test-WaitForCompletedRunspaceScenario -ScenarioName "Attente avec timeout" -ExpectSuccess -TestScript {
    # Créer des runspaces qui s'exécutent pendant différentes durées
    $runspaces = @(
        (New-TestRunspace -SleepSeconds 1),
        (New-TestRunspace -SleepSeconds 10),  # Ce runspace ne sera pas complété avant le timeout
        (New-TestRunspace -SleepSeconds 15)   # Ce runspace ne sera pas complété avant le timeout
    )
    
    # Attendre avec un timeout de 3 secondes
    $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -TimeoutSeconds 3 -NoProgress
    
    # Vérifier que seul le premier runspace est complété
    if ($completedRunspaces.Count -ne 1) {
        throw "Nombre incorrect de runspaces complétés: $($completedRunspaces.Count) au lieu de 1"
    }
    
    # Vérifier que les runspaces non complétés sont toujours dans la liste
    if ($runspaces.Count -ne 2) {
        throw "Nombre incorrect de runspaces restants: $($runspaces.Count) au lieu de 2"
    }
    
    Write-Host "  Nombre de runspaces complétés: $($completedRunspaces.Count)" -ForegroundColor Yellow
    Write-Host "  Nombre de runspaces restants: $($runspaces.Count)" -ForegroundColor Yellow
}

# Test 3: Attente avec timeout et nettoyage automatique
Test-WaitForCompletedRunspaceScenario -ScenarioName "Attente avec timeout et nettoyage automatique" -ExpectSuccess -TestScript {
    # Créer des runspaces qui s'exécutent pendant différentes durées
    $runspaces = @(
        (New-TestRunspace -SleepSeconds 1),
        (New-TestRunspace -SleepSeconds 10),  # Ce runspace ne sera pas complété avant le timeout
        (New-TestRunspace -SleepSeconds 15)   # Ce runspace ne sera pas complété avant le timeout
    )
    
    # Attendre avec un timeout de 3 secondes et nettoyage automatique
    $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -TimeoutSeconds 3 -WaitForAll -NoProgress
    
    # Vérifier que seul le premier runspace est complété
    if ($completedRunspaces.Count -ne 1) {
        throw "Nombre incorrect de runspaces complétés: $($completedRunspaces.Count) au lieu de 1"
    }
    
    # Vérifier que les runspaces non complétés ont été nettoyés
    if ($runspaces.Count -ne 0) {
        throw "Les runspaces non complétés n'ont pas été nettoyés: $($runspaces.Count) restants"
    }
    
    Write-Host "  Nombre de runspaces complétés: $($completedRunspaces.Count)" -ForegroundColor Yellow
    Write-Host "  Nombre de runspaces restants: $($runspaces.Count)" -ForegroundColor Yellow
}

# Test 4: Gestion des handles null
Test-WaitForCompletedRunspaceScenario -ScenarioName "Gestion des handles null" -ExpectSuccess -TestScript {
    # Créer des runspaces dont certains ont des handles null
    $runspaces = @(
        (New-TestRunspace -SleepSeconds 1),
        (New-TestRunspace -SleepSeconds 2 -NullHandle),  # Ce runspace a un handle null
        (New-TestRunspace -SleepSeconds 3)
    )
    
    # Attendre avec un timeout de 5 secondes
    $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -TimeoutSeconds 5 -WaitForAll -NoProgress
    
    # Vérifier que seuls les runspaces avec des handles valides sont complétés
    if ($completedRunspaces.Count -ne 2) {
        throw "Nombre incorrect de runspaces complétés: $($completedRunspaces.Count) au lieu de 2"
    }
    
    Write-Host "  Nombre de runspaces complétés: $($completedRunspaces.Count)" -ForegroundColor Yellow
}

# Test 5: Gestion des erreurs dans les runspaces
Test-WaitForCompletedRunspaceScenario -ScenarioName "Gestion des erreurs dans les runspaces" -ExpectSuccess -TestScript {
    # Créer des runspaces dont certains génèrent des erreurs
    $runspaces = @(
        (New-TestRunspace -SleepSeconds 1),
        (New-TestRunspace -SleepSeconds 2 -ThrowError),  # Ce runspace génère une erreur
        (New-TestRunspace -SleepSeconds 3)
    )
    
    # Attendre que tous les runspaces soient complétés
    $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress
    
    # Vérifier que tous les runspaces sont complétés, même ceux qui ont généré des erreurs
    if ($completedRunspaces.Count -ne 3) {
        throw "Nombre incorrect de runspaces complétés: $($completedRunspaces.Count) au lieu de 3"
    }
    
    Write-Host "  Nombre de runspaces complétés: $($completedRunspaces.Count)" -ForegroundColor Yellow
}

# Test 6: Performances avec un grand nombre de runspaces
Test-WaitForCompletedRunspaceScenario -ScenarioName "Performances avec un grand nombre de runspaces" -ExpectSuccess -TestScript {
    # Nombre de runspaces à créer
    $runspaceCount = 50
    
    # Créer un grand nombre de runspaces
    $runspaces = @()
    for ($i = 0; $i -lt $runspaceCount; $i++) {
        $runspaces += New-TestRunspace -SleepSeconds 1
    }
    
    # Mesurer le temps d'exécution
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Attendre que tous les runspaces soient complétés
    $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress
    
    $stopwatch.Stop()
    $elapsedTime = $stopwatch.Elapsed.TotalSeconds
    
    # Vérifier que tous les runspaces sont complétés
    if ($completedRunspaces.Count -ne $runspaceCount) {
        throw "Nombre incorrect de runspaces complétés: $($completedRunspaces.Count) au lieu de $runspaceCount"
    }
    
    Write-Host "  Nombre de runspaces complétés: $($completedRunspaces.Count)" -ForegroundColor Yellow
    Write-Host "  Temps d'exécution: $elapsedTime secondes" -ForegroundColor Yellow
}

# Nettoyer les ressources
Clear-UnifiedParallel

Write-Host "`nTous les tests sont terminés." -ForegroundColor Cyan
