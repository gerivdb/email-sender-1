# Test de gestion des timeouts pour Wait-ForCompletedRunspace
# Ce script teste la capacité de Wait-ForCompletedRunspace à gérer correctement les timeouts

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Import-Module $modulePath -Force

# Initialiser le module
Initialize-UnifiedParallel -Verbose

Write-Host "Test de gestion des timeouts pour Wait-ForCompletedRunspace" -ForegroundColor Yellow
Write-Host "=======================================================" -ForegroundColor Yellow

# Créer un pool de runspaces
$sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
$runspacePool = [runspacefactory]::CreateRunspacePool(1, 4, $sessionState, $Host)
$runspacePool.Open()

# Créer une liste pour stocker les runspaces
$runspaceCount = 10
$runspaces = [System.Collections.Generic.List[object]]::new($runspaceCount)

Write-Host "Création de $runspaceCount runspaces avec délais mixtes (certains dépasseront le timeout)..." -ForegroundColor Cyan

# Créer les runspaces avec des délais mixtes (certains dépasseront le timeout)
$delaysMilliseconds = @(100, 200, 300, 1500, 2000)
for ($i = 0; $i -lt $runspaceCount; $i++) {
    $delay = $delaysMilliseconds[$i % $delaysMilliseconds.Length]
    
    $powershell = [powershell]::Create()
    $powershell.RunspacePool = $runspacePool

    # Ajouter un script simple avec délai variable
    [void]$powershell.AddScript({
            param($Item, $DelayMilliseconds)
            Start-Sleep -Milliseconds $DelayMilliseconds
            return [PSCustomObject]@{
                Item = $Item
                Delay = $DelayMilliseconds
                ThreadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
                StartTime = Get-Date
                EndTime = Get-Date
            }
        })

    # Ajouter les paramètres
    [void]$powershell.AddParameter('Item', $i)
    [void]$powershell.AddParameter('DelayMilliseconds', $delay)

    # Démarrer l'exécution asynchrone
    $handle = $powershell.BeginInvoke()

    # Ajouter à la liste des runspaces
    $runspaces.Add([PSCustomObject]@{
            PowerShell = $powershell
            Handle     = $handle
            Item       = $i
            Delay      = $delay
            StartTime  = [datetime]::Now
        })
}

# Mesurer le temps d'exécution
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Définir un timeout court (1 seconde)
$timeoutSeconds = 1
Write-Host "Attente de $runspaceCount runspaces avec un timeout de $timeoutSeconds seconde..." -ForegroundColor Cyan

# Capturer les warnings
$warningOutput = New-Object System.Collections.Generic.List[string]
$warningAction = {
    param($message)
    $warningOutput.Add($message)
}

# Attendre que tous les runspaces soient complétés ou que le timeout soit atteint
$completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds $timeoutSeconds -WarningAction SilentlyContinue -WarningVariable warnings -Verbose

$stopwatch.Stop()
$elapsedMs = $stopwatch.ElapsedMilliseconds

# Afficher les résultats
Write-Host "Temps d'exécution: $elapsedMs ms" -ForegroundColor Green
Write-Host "Runspaces complétés: $($completedRunspaces.Count) sur $runspaceCount" -ForegroundColor Green

# Vérifier les warnings
if ($warnings) {
    Write-Host "Warnings détectés:" -ForegroundColor Yellow
    foreach ($warning in $warnings) {
        Write-Host "  - $warning" -ForegroundColor Yellow
    }
}

# Traiter les résultats
$results = Invoke-RunspaceProcessor -CompletedRunspaces $completedRunspaces.Results -NoProgress

# Afficher les statistiques
Write-Host "Runspaces traités: $($results.TotalProcessed)" -ForegroundColor Green
Write-Host "Succès: $($results.SuccessCount)" -ForegroundColor Green
Write-Host "Erreurs: $($results.ErrorCount)" -ForegroundColor Green

# Vérifier que le timeout a été respecté
$timeoutRespected = $elapsedMs -le ($timeoutSeconds * 1000 * 1.1) # 10% de marge
Write-Host "Timeout respecté: $timeoutRespected" -ForegroundColor $(if ($timeoutRespected) { "Green" } else { "Red" })

# Vérifier que certains runspaces n'ont pas été complétés (à cause du timeout)
$incompleteRunspaces = $runspaceCount - $completedRunspaces.Count
Write-Host "Runspaces non complétés (attendus): $incompleteRunspaces" -ForegroundColor $(if ($incompleteRunspaces -gt 0) { "Green" } else { "Red" })

# Vérifier que les runspaces non complétés sont ceux avec les délais les plus longs
$longDelayRunspaces = ($runspaces | Where-Object { $_.Delay -gt ($timeoutSeconds * 1000) }).Count
$expectedIncomplete = [Math]::Min($longDelayRunspaces, $runspaceCount)
Write-Host "Runspaces avec délais > $($timeoutSeconds * 1000)ms: $longDelayRunspaces" -ForegroundColor Gray

# Vérifier si le test a réussi
$success = $timeoutRespected -and $incompleteRunspaces -gt 0
if ($success) {
    Write-Host "TEST DE GESTION DES TIMEOUTS RÉUSSI!" -ForegroundColor Green
} else {
    Write-Host "TEST DE GESTION DES TIMEOUTS ÉCHOUÉ!" -ForegroundColor Red
}

# Nettoyer les runspaces restants
Write-Host "`nNettoyage des runspaces restants..." -ForegroundColor Cyan
foreach ($runspace in $runspaces) {
    if (-not $runspace.Handle.IsCompleted) {
        try {
            $runspace.PowerShell.Stop()
            $runspace.PowerShell.Dispose()
        }
        catch {
            Write-Host "Erreur lors du nettoyage d'un runspace: $_" -ForegroundColor Red
        }
    }
}

$runspacePool.Close()
$runspacePool.Dispose()
Clear-UnifiedParallel -Verbose

Write-Host "`nTest terminé." -ForegroundColor Green
