# Script de test pour les runspaces
Write-Host "Test des runspaces"

# Créer un pool de runspaces
$sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
$runspacePool = [runspacefactory]::CreateRunspacePool(1, 2, $sessionState, $Host)
$runspacePool.Open()

# Créer une liste pour stocker les runspaces
$runspaces = New-Object System.Collections.ArrayList

# Créer quelques runspaces
for ($i = 1; $i -le 3; $i++) {
    $powershell = [powershell]::Create()
    $powershell.RunspacePool = $runspacePool
    
    # Ajouter un script simple
    [void]$powershell.AddScript({
        param($Item)
        Start-Sleep -Milliseconds (Get-Random -Minimum 100 -Maximum 500)
        return "Traitement de l'élément $Item terminé"
    })
    
    # Ajouter le paramètre
    [void]$powershell.AddParameter('Item', $i)
    
    # Démarrer l'exécution asynchrone
    $handle = $powershell.BeginInvoke()
    
    # Ajouter à la liste des runspaces
    [void]$runspaces.Add([PSCustomObject]@{
        PowerShell = $powershell
        Handle = $handle
        Item = $i
    })
    
    Write-Host "Runspace $i créé et démarré"
}

# Attendre et récupérer les résultats
$results = New-Object System.Collections.ArrayList

Write-Host "Attente des résultats..."
while ($runspaces.Count -gt 0) {
    for ($i = 0; $i -lt $runspaces.Count; $i++) {
        $runspace = $runspaces[$i]
        
        if ($runspace.Handle.IsCompleted) {
            # Récupérer le résultat
            $result = $runspace.PowerShell.EndInvoke($runspace.Handle)
            [void]$results.Add($result)
            
            # Nettoyer le runspace
            $runspace.PowerShell.Dispose()
            $runspaces.RemoveAt($i)
            $i--
            
            Write-Host "Résultat récupéré: $result"
        }
    }
    
    if ($runspaces.Count -gt 0) {
        Start-Sleep -Milliseconds 100
    }
}

# Fermer le pool de runspaces
$runspacePool.Close()
$runspacePool.Dispose()

Write-Host "Test terminé avec succès. Résultats:"
$results | ForEach-Object { Write-Host "- $_" }
