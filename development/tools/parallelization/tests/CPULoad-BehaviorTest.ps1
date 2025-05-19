# Test de comportement sous charge CPU élevée pour Wait-ForCompletedRunspace
# Ce script teste la capacité de Wait-ForCompletedRunspace à gérer une charge CPU élevée

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Import-Module $modulePath -Force

# Initialiser le module
Initialize-UnifiedParallel -Verbose

Write-Host "Test de comportement sous charge CPU élevée pour Wait-ForCompletedRunspace" -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor Yellow

# Créer un pool de runspaces
$sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
$runspacePool = [runspacefactory]::CreateRunspacePool(1, 8, $sessionState, $Host)
$runspacePool.Open()

# Créer une liste pour stocker les runspaces
$runspaceCount = 8
$runspaces = [System.Collections.Generic.List[object]]::new($runspaceCount)

Write-Host "Création de $runspaceCount runspaces avec calculs intensifs..." -ForegroundColor Cyan

# Créer les runspaces avec des calculs intensifs
$delaysMilliseconds = @(50, 100, 150, 200)
for ($i = 0; $i -lt $runspaceCount; $i++) {
    $delay = $delaysMilliseconds[$i % $delaysMilliseconds.Length]
    
    $powershell = [powershell]::Create()
    $powershell.RunspacePool = $runspacePool

    # Ajouter un script avec calculs intensifs
    [void]$powershell.AddScript({
            param($Item, $DelayMilliseconds)
            $startTime = Get-Date
            
            # Simuler une charge CPU élevée
            $result = 0
            for ($i = 0; $i -lt 1000000; $i++) {
                $result += [Math]::Pow($i, 2) % 10
            }
            
            Start-Sleep -Milliseconds $DelayMilliseconds
            
            return [PSCustomObject]@{
                Item = $Item
                Delay = $DelayMilliseconds
                CPUWork = $result
                Duration = ((Get-Date) - $startTime).TotalMilliseconds
                ThreadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
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

# Mesurer le temps d'exécution et l'utilisation CPU
$process = Get-Process -Id $PID
$startCPU = $process.TotalProcessorTime
$startMemory = $process.WorkingSet64

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Attendre que tous les runspaces soient complétés
Write-Host "Attente de $runspaceCount runspaces avec charge CPU élevée..." -ForegroundColor Cyan
$completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 60 -Verbose

$stopwatch.Stop()
$elapsedMs = $stopwatch.ElapsedMilliseconds

# Mesurer l'utilisation CPU et mémoire
$process = Get-Process -Id $PID
$endCPU = $process.TotalProcessorTime
$endMemory = $process.WorkingSet64

$cpuTime = ($endCPU - $startCPU).TotalMilliseconds
$memoryUsage = ($endMemory - $startMemory) / 1MB

# Afficher les résultats
Write-Host "Temps d'exécution: $elapsedMs ms" -ForegroundColor Green
Write-Host "Runspaces complétés: $($completedRunspaces.Count) sur $runspaceCount" -ForegroundColor Green
Write-Host "Temps CPU utilisé: $([Math]::Round($cpuTime, 2)) ms" -ForegroundColor Green
Write-Host "Mémoire utilisée: $([Math]::Round($memoryUsage, 2)) MB" -ForegroundColor Green

# Traiter les résultats
$results = Invoke-RunspaceProcessor -CompletedRunspaces $completedRunspaces.Results -NoProgress

# Afficher les statistiques
Write-Host "Runspaces traités: $($results.TotalProcessed)" -ForegroundColor Green
Write-Host "Succès: $($results.SuccessCount)" -ForegroundColor Green
Write-Host "Erreurs: $($results.ErrorCount)" -ForegroundColor Green

# Analyser les durées d'exécution des runspaces
$durations = $results.Results | ForEach-Object { $_.Output.Duration }
$avgDuration = ($durations | Measure-Object -Average).Average
$minDuration = ($durations | Measure-Object -Minimum).Minimum
$maxDuration = ($durations | Measure-Object -Maximum).Maximum

Write-Host "Durée moyenne d'exécution des runspaces: $([Math]::Round($avgDuration, 2)) ms" -ForegroundColor Green
Write-Host "Durée minimale: $([Math]::Round($minDuration, 2)) ms" -ForegroundColor Green
Write-Host "Durée maximale: $([Math]::Round($maxDuration, 2)) ms" -ForegroundColor Green

# Vérifier si le test a réussi
$success = $completedRunspaces.Count -eq $runspaceCount
if ($success) {
    Write-Host "TEST DE COMPORTEMENT SOUS CHARGE CPU ÉLEVÉE RÉUSSI!" -ForegroundColor Green
} else {
    Write-Host "TEST DE COMPORTEMENT SOUS CHARGE CPU ÉLEVÉE ÉCHOUÉ!" -ForegroundColor Red
}

# Nettoyer
$runspacePool.Close()
$runspacePool.Dispose()
Clear-UnifiedParallel -Verbose

Write-Host "`nTest terminé." -ForegroundColor Green
