# Test de Wait-ForCompletedRunspace et Invoke-RunspaceProcessor
$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'

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
        Start-Sleep -Milliseconds 100
        return "Test $Item"
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

# Attendre tous les runspaces
Write-Host "Attente des runspaces..."
$completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -Verbose

Write-Host "Nombre de runspaces complétés: $($completedRunspaces.Count)"

# Créer une copie des runspaces complétés
$runspacesToProcess = New-Object System.Collections.ArrayList
foreach ($runspace in $completedRunspaces) {
    [void]$runspacesToProcess.Add($runspace)
}

# Traiter les runspaces
Write-Host "Traitement des runspaces..."
$processorResults = Invoke-RunspaceProcessor -CompletedRunspaces $runspacesToProcess -NoProgress -Verbose

Write-Host "Nombre de résultats: $($processorResults.Results.Count)"
Write-Host "Nombre d'erreurs: $($processorResults.Errors.Count)"
Write-Host "Nombre total traité: $($processorResults.TotalProcessed)"
Write-Host "Nombre de succès: $($processorResults.SuccessCount)"

foreach ($result in $processorResults.Results) {
    Write-Host "Résultat pour l'élément $($result.Item): $($result.Value)"
}

# Nettoyer
$runspacePool.Close()
$runspacePool.Dispose()

Write-Host "Test terminé."
