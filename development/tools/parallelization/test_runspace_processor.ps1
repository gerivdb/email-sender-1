# Script de test pour Invoke-RunspaceProcessor
Write-Host "Test de Invoke-RunspaceProcessor"

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
        $result = [PSCustomObject]@{
            Output = "Traitement de l'élément $Item terminé"
            Success = $true
            Error = $null
            StartTime = [datetime]::Now
            EndTime = $null
            Duration = $null
            ThreadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
        }
        
        # Simuler un traitement
        Start-Sleep -Milliseconds (Get-Random -Minimum 100 -Maximum 300)
        
        # Simuler une erreur pour l'élément 2
        if ($Item -eq 2) {
            try {
                throw "Erreur simulée pour l'élément $Item"
            } catch {
                $result.Success = $false
                $result.Error = $_
            }
        }
        
        $result.EndTime = [datetime]::Now
        $result.Duration = $result.EndTime - $result.StartTime
        
        return $result
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
$completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -Verbose

# Vérifier les résultats manuellement
Write-Host "Vérification manuelle des résultats..."
foreach ($runspace in $completedRunspaces) {
    try {
        $result = $runspace.PowerShell.EndInvoke($runspace.Handle)
        Write-Host "Résultat pour l'élément $($runspace.Item): $($result.Output)"
    } catch {
        Write-Host "Erreur lors de la récupération du résultat pour l'élément $($runspace.Item): $_" -ForegroundColor Red
    }
}

# Tester Invoke-RunspaceProcessor
Write-Host "Test de Invoke-RunspaceProcessor..."
try {
    # Créer une copie des runspaces complétés pour éviter les problèmes
    $runspacesToProcess = New-Object System.Collections.ArrayList
    foreach ($runspace in $completedRunspaces) {
        [void]$runspacesToProcess.Add($runspace)
    }
    
    # Traiter les runspaces
    $processorResults = Invoke-RunspaceProcessor -CompletedRunspaces $runspacesToProcess -Verbose
    
    # Afficher les résultats
    Write-Host "Nombre de résultats: $($processorResults.Results.Count)"
    Write-Host "Nombre d'erreurs: $($processorResults.Errors.Count)"
    
    foreach ($result in $processorResults.Results) {
        if ($result.Success) {
            Write-Host "Résultat: $($result.Value)" -ForegroundColor Green
        } else {
            Write-Host "Erreur: $($result.Error.Exception.Message)" -ForegroundColor Red
        }
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
