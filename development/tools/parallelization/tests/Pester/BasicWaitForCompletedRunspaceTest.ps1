# Test basique pour la fonction Wait-ForCompletedRunspace
# Ce script teste la fonction Wait-ForCompletedRunspace du module UnifiedParallel

# Importer le module
Import-Module .\development\tools\parallelization\UnifiedParallel.psm1 -Force

# Initialiser le module
Initialize-UnifiedParallel

# Créer un pool de runspaces
$pool = [runspacefactory]::CreateRunspacePool(1, 2)
$pool.Open()

# Créer des runspaces de test
$runspaces = [System.Collections.Generic.List[object]]::new()

for ($i = 0; $i -lt 2; $i++) {
    $scriptBlock = {
        param($index)
        
        # Simuler un traitement
        Start-Sleep -Milliseconds 100
        
        # Retourner un résultat
        return "Résultat du runspace $index"
    }
    
    $powershell = [powershell]::Create().AddScript($scriptBlock).AddParameter("index", $i)
    $powershell.RunspacePool = $pool
    
    $runspace = [PSCustomObject]@{
        PowerShell = $powershell
        Handle = $powershell.BeginInvoke()
        Index = $i
    }
    
    $runspaces.Add($runspace)
}

Write-Host "Runspaces créés: $($runspaces.Count)"

# Attendre qu'un runspace soit complété
$completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -TimeoutSeconds 5

Write-Host "Runspaces complétés: $($completedRunspaces.Count)"
Write-Host "Runspaces restants: $($runspaces.Count)"

# Récupérer les résultats
$results = $completedRunspaces.Results | ForEach-Object {
    try {
        $_.PowerShell.EndInvoke($_.Handle)
    } catch {
        "Erreur: $_"
    }
}

Write-Host "Résultats: $results"

# Nettoyer les ressources
foreach ($runspace in $runspaces) {
    if ($runspace.PowerShell) {
        $runspace.PowerShell.Dispose()
    }
}

foreach ($runspace in $completedRunspaces.Results) {
    if ($runspace.PowerShell) {
        $runspace.PowerShell.Dispose()
    }
}

$pool.Close()
$pool.Dispose()

# Nettoyer le module
Clear-UnifiedParallel
