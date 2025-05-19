# Test très simple pour la fonction Wait-ForCompletedRunspace

# Importer le module
Import-Module .\development\tools\parallelization\UnifiedParallel.psm1 -Force

# Initialiser le module
Initialize-UnifiedParallel

# Créer un pool de runspaces
$pool = [runspacefactory]::CreateRunspacePool(1, 2)
$pool.Open()

# Créer des runspaces de test
$runspaces = New-Object System.Collections.ArrayList

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
    
    $runspaces.Add($runspace) | Out-Null
}

Write-Host "Runspaces créés: $($runspaces.Count)"

# Attendre qu'un runspace soit complété
$completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -TimeoutSeconds 5

Write-Host "Runspaces complétés: $($completedRunspaces.Count)"
Write-Host "Runspaces restants: $($runspaces.Count)"

# Nettoyer les ressources
$pool.Close()
$pool.Dispose()
