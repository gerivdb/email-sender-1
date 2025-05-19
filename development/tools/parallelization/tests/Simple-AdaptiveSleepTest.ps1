# Test simple pour la fonction Wait-ForCompletedRunspace avec délai adaptatif

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Import-Module $modulePath -Force

# Initialiser le module
Initialize-UnifiedParallel -Verbose

Write-Host "Test simple pour Wait-ForCompletedRunspace avec délai adaptatif" -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor Yellow

# Créer un pool de runspaces
$sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
$runspacePool = [runspacefactory]::CreateRunspacePool(1, 4, $sessionState, $Host)
$runspacePool.Open()

# Créer une liste pour stocker les runspaces
$runspaces = [System.Collections.Generic.List[object]]::new()

# Créer des runspaces avec des délais différents
$delaysMilliseconds = @(50, 100, 150, 200, 250)
$runspaceCount = 10

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
Write-Host "Attente de $runspaceCount runspaces avec délai adaptatif..." -ForegroundColor Cyan
$completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 10 -Verbose

$stopwatch.Stop()
$elapsedMs = $stopwatch.ElapsedMilliseconds

# Afficher les résultats
Write-Host "Temps d'exécution total: $elapsedMs ms" -ForegroundColor Green
Write-Host "Nombre de runspaces complétés: $($completedRunspaces.Count)" -ForegroundColor Green

# Traiter les résultats
$results = Invoke-RunspaceProcessor -CompletedRunspaces $completedRunspaces.Results -NoProgress

# Afficher les statistiques
Write-Host "Runspaces traités: $($results.TotalProcessed)" -ForegroundColor Green
Write-Host "Succès: $($results.SuccessCount)" -ForegroundColor Green
Write-Host "Erreurs: $($results.ErrorCount)" -ForegroundColor Green

# Nettoyer
$runspacePool.Close()
$runspacePool.Dispose()
Clear-UnifiedParallel -Verbose

Write-Host "`nTest terminé." -ForegroundColor Green
