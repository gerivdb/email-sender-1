# Script de test simple pour Invoke-RunspaceProcessor
Write-Host "Test simple de Invoke-RunspaceProcessor"

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "UnifiedParallel.psm1"
Import-Module $modulePath -Force -Verbose

# Initialiser le module
Initialize-UnifiedParallel -Verbose

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
            # Simuler un traitement
            Start-Sleep -Milliseconds (Get-Random -Minimum 100 -Maximum 300)
            return "Traitement de l'élément $Item terminé"
        })

    # Ajouter le paramètre
    [void]$powershell.AddParameter('Item', $i)

    # Démarrer l'exécution asynchrone
    $handle = $powershell.BeginInvoke()

    # Ajouter à la liste des runspaces
    [void]$runspaces.Add([PSCustomObject]@{
            PowerShell = $powershell
            Handle     = $handle
            Item       = $i
        })

    Write-Host "Runspace $i créé et démarré"
}

# Attendre tous les runspaces
Write-Host "Attente des runspaces..."
$completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -Verbose

# Traiter les résultats avec Invoke-RunspaceProcessor
Write-Host "Traitement des runspaces avec Invoke-RunspaceProcessor..."

# Créer une copie des runspaces complétés pour éviter les problèmes
$runspacesToProcess = New-Object System.Collections.ArrayList
foreach ($runspace in $completedRunspaces) {
    [void]$runspacesToProcess.Add($runspace)
}

# Traiter les runspaces
try {
    $processorResults = Invoke-RunspaceProcessor -CompletedRunspaces $runspacesToProcess -Verbose

    # Afficher les résultats
    Write-Host "Nombre de résultats: $($processorResults.Results.Count)"
    Write-Host "Nombre d'erreurs: $($processorResults.Errors.Count)"
    Write-Host "Nombre total traité: $($processorResults.TotalProcessed)"
    Write-Host "Nombre de succès: $($processorResults.SuccessCount)"

    foreach ($result in $processorResults.Results) {
        Write-Host "Résultat pour l'élément $($result.Item): $($result.Value)" -ForegroundColor Green
    }
} catch {
    Write-Host "Erreur lors de l'exécution de Invoke-RunspaceProcessor: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}

# Fermer le pool de runspaces
$runspacePool.Close()
$runspacePool.Dispose()

# Nettoyer
Clear-UnifiedParallel -Verbose

Write-Host "Test terminé."
