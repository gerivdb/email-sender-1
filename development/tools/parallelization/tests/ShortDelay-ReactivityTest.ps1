# Test de réactivité pour Wait-ForCompletedRunspace avec des délais très courts
# Ce script teste la capacité de Wait-ForCompletedRunspace à gérer des délais très courts (<10ms)

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Import-Module $modulePath -Force

# Initialiser le module
Initialize-UnifiedParallel -Verbose

Write-Host "Test de réactivité pour Wait-ForCompletedRunspace avec délais courts" -ForegroundColor Yellow
Write-Host "=============================================================" -ForegroundColor Yellow

# Créer un pool de runspaces
$sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
$runspacePool = [runspacefactory]::CreateRunspacePool(1, 8, $sessionState, $Host)
$runspacePool.Open()

# Créer une liste pour stocker les runspaces
$runspaceCount = 20
$runspaces = [System.Collections.Generic.List[object]]::new($runspaceCount)

Write-Host "Création de $runspaceCount runspaces avec délais très courts..." -ForegroundColor Cyan

# Créer les runspaces avec des délais très courts
$delaysMilliseconds = @(1, 2, 3, 5, 8)
for ($i = 0; $i -lt $runspaceCount; $i++) {
    $delay = $delaysMilliseconds[$i % $delaysMilliseconds.Length]
    
    $powershell = [powershell]::Create()
    $powershell.RunspacePool = $runspacePool

    # Ajouter un script simple avec délai très court
    [void]$powershell.AddScript({
            param($Item, $DelayMilliseconds)
            Start-Sleep -Milliseconds $DelayMilliseconds
            return [PSCustomObject]@{
                Item = $Item
                Delay = $DelayMilliseconds
                ThreadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
                StartTime = Get-Date
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

# Attendre que tous les runspaces soient complétés
Write-Host "Attente de $runspaceCount runspaces avec délais très courts..." -ForegroundColor Cyan
$completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 10 -Verbose

$stopwatch.Stop()
$elapsedMs = $stopwatch.ElapsedMilliseconds

# Afficher les résultats
Write-Host "Temps d'exécution: $elapsedMs ms" -ForegroundColor Green
Write-Host "Runspaces complétés: $($completedRunspaces.Count) sur $runspaceCount" -ForegroundColor Green

# Traiter les résultats
$results = Invoke-RunspaceProcessor -CompletedRunspaces $completedRunspaces.Results -NoProgress

# Afficher les statistiques
Write-Host "Runspaces traités: $($results.TotalProcessed)" -ForegroundColor Green
Write-Host "Succès: $($results.SuccessCount)" -ForegroundColor Green
Write-Host "Erreurs: $($results.ErrorCount)" -ForegroundColor Green

# Calculer le temps moyen par runspace
$avgTimePerRunspace = $elapsedMs / $runspaceCount
Write-Host "Temps moyen par runspace: $([Math]::Round($avgTimePerRunspace, 2)) ms" -ForegroundColor Green

# Calculer l'overhead par rapport au délai moyen des runspaces
$avgDelay = ($delaysMilliseconds | Measure-Object -Average).Average
$overhead = $avgTimePerRunspace - $avgDelay
Write-Host "Délai moyen des runspaces: $avgDelay ms" -ForegroundColor Gray
Write-Host "Overhead estimé: $([Math]::Round($overhead, 2)) ms" -ForegroundColor Gray

# Vérifier si le test a réussi
$success = $completedRunspaces.Count -eq $runspaceCount
if ($success) {
    Write-Host "TEST DE RÉACTIVITÉ RÉUSSI!" -ForegroundColor Green
} else {
    Write-Host "TEST DE RÉACTIVITÉ ÉCHOUÉ!" -ForegroundColor Red
}

# Nettoyer
$runspacePool.Close()
$runspacePool.Dispose()
Clear-UnifiedParallel -Verbose

Write-Host "`nTest terminé." -ForegroundColor Green
