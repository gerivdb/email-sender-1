<#
.SYNOPSIS
    Tests pour la gestion des timeouts dans Wait-ForCompletedRunspace.
.DESCRIPTION
    Ce script contient des tests pour verifier la gestion des timeouts
    dans la fonction Wait-ForCompletedRunspace.
.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  2023-05-19
    Encoding:       UTF-8 with BOM
#>

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Import-Module $modulePath -Force

# Initialiser le module
Initialize-UnifiedParallel -Verbose

Write-Host "Test de gestion des timeouts pour Wait-ForCompletedRunspace" -ForegroundColor Yellow
Write-Host "=======================================================" -ForegroundColor Yellow

# Creer un pool de runspaces
$sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
$runspacePool = [runspacefactory]::CreateRunspacePool(1, 4, $sessionState, $Host)
$runspacePool.Open()

# Creer une liste pour stocker les runspaces
$runspaceCount = 10
$runspaces = New-Object System.Collections.Generic.List[object]

Write-Host "Creation de $runspaceCount runspaces avec delais mixtes (certains depasseront le timeout)..." -ForegroundColor Cyan

# Creer les runspaces avec des delais mixtes (certains depasseront le timeout)
$delaysMilliseconds = @(100, 200, 300, 1500, 2000)
for ($i = 0; $i -lt $runspaceCount; $i++) {
    $delay = $delaysMilliseconds[$i % $delaysMilliseconds.Length]

    $powershell = [powershell]::Create()
    $powershell.RunspacePool = $runspacePool

    # Ajouter un script simple avec delai variable
    [void]$powershell.AddScript({
            param($Item, $DelayMilliseconds)
            Start-Sleep -Milliseconds $DelayMilliseconds
            return [PSCustomObject]@{
                Item      = $Item
                Delay     = $DelayMilliseconds
                ThreadId  = [System.Threading.Thread]::CurrentThread.ManagedThreadId
                StartTime = Get-Date
                EndTime   = Get-Date
            }
        })

    # Ajouter les parametres
    [void]$powershell.AddParameter('Item', $i)
    [void]$powershell.AddParameter('DelayMilliseconds', $delay)

    # Demarrer l'execution asynchrone
    $handle = $powershell.BeginInvoke()

    # Ajouter a la liste des runspaces
    $runspaces.Add([PSCustomObject]@{
            PowerShell = $powershell
            Handle     = $handle
            Item       = $i
            Delay      = $delay
            StartTime  = [datetime]::Now
        })
}

# Test 1: Avec un timeout court (1 seconde)
Write-Host "`nTest 1: Avec un timeout court (1 seconde)" -ForegroundColor Cyan

# Mesurer le temps d'execution
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Definir un timeout court (1 seconde)
$timeoutSeconds = 1
Write-Host "Attente de $runspaceCount runspaces avec un timeout de $timeoutSeconds seconde..." -ForegroundColor Cyan

# Attendre que tous les runspaces soient completes ou que le timeout soit atteint
$completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds $timeoutSeconds -WarningAction SilentlyContinue -Verbose

$stopwatch.Stop()
$elapsedMs = $stopwatch.ElapsedMilliseconds

# Traiter les resultats
$results = Invoke-RunspaceProcessor -CompletedRunspaces $completedRunspaces.Results -NoProgress

# Calculer les statistiques
$incompleteCount = $runspaceCount - $completedRunspaces.Count
$longDelayRunspaces = ($runspaces | Where-Object { $_.Delay -gt ($timeoutSeconds * 1000) }).Count

# Verifier que le timeout a ete respecte (avec une marge de 30%)
if ($elapsedMs -le ($timeoutSeconds * 1000 * 1.3) -and $elapsedMs -ge ($timeoutSeconds * 1000 * 0.7)) {
    Write-Host "  SUCCES: Le timeout a ete respecte ($elapsedMs ms)" -ForegroundColor Green
} else {
    Write-Host "  ECHEC: Le timeout n'a pas ete respecte ($elapsedMs ms)" -ForegroundColor Red
}

# Verifier que certains runspaces ont ete completes mais pas tous
if ($completedRunspaces.Count -gt 0 -and $completedRunspaces.Count -lt $runspaceCount) {
    Write-Host "  SUCCES: Certains runspaces ont ete completes mais pas tous ($($completedRunspaces.Count) sur $runspaceCount)" -ForegroundColor Green
} else {
    Write-Host "  ECHEC: Tous les runspaces ont ete completes ou aucun n'a ete complete ($($completedRunspaces.Count) sur $runspaceCount)" -ForegroundColor Red
}

# Verifier que les runspaces completes ont ete traites avec succes
if ($results.SuccessCount -eq $completedRunspaces.Count -and $results.ErrorCount -eq 0) {
    Write-Host "  SUCCES: Les runspaces completes ont ete traites avec succes" -ForegroundColor Green
} else {
    Write-Host "  ECHEC: Les runspaces completes n'ont pas ete traites avec succes (Succes: $($results.SuccessCount), Erreurs: $($results.ErrorCount))" -ForegroundColor Red
}

# Verifier que des runspaces avec delais longs n'ont pas ete completes
$longDelayIncomplete = ($runspaces | Where-Object { $_.Delay -gt ($timeoutSeconds * 1000) -and -not $_.Handle.IsCompleted }).Count
if ($longDelayIncomplete -gt 0) {
    Write-Host "  SUCCES: Des runspaces avec delais longs n'ont pas ete completes ($longDelayIncomplete sur $longDelayRunspaces)" -ForegroundColor Green
} else {
    Write-Host "  ECHEC: Tous les runspaces avec delais longs ont ete completes" -ForegroundColor Red
}

# Test 2: Avec un timeout plus long (3 secondes)
Write-Host "`nTest 2: Avec un timeout plus long (3 secondes)" -ForegroundColor Cyan

# Nettoyer les runspaces du test precedent
foreach ($runspace in $runspaces) {
    if (-not $runspace.Handle.IsCompleted) {
        try {
            $runspace.PowerShell.Stop()
            $runspace.PowerShell.Dispose()
        } catch {
            Write-Host "Erreur lors du nettoyage d'un runspace: $_" -ForegroundColor Red
        }
    }
}

# Creer de nouveaux runspaces pour le test 2
$runspaces = New-Object System.Collections.Generic.List[object]

for ($i = 0; $i -lt $runspaceCount; $i++) {
    $delay = $delaysMilliseconds[$i % $delaysMilliseconds.Length]

    $powershell = [powershell]::Create()
    $powershell.RunspacePool = $runspacePool

    # Ajouter un script simple avec delai variable
    [void]$powershell.AddScript({
            param($Item, $DelayMilliseconds)
            Start-Sleep -Milliseconds $DelayMilliseconds
            return [PSCustomObject]@{
                Item      = $Item
                Delay     = $DelayMilliseconds
                ThreadId  = [System.Threading.Thread]::CurrentThread.ManagedThreadId
                StartTime = Get-Date
                EndTime   = Get-Date
            }
        })

    # Ajouter les parametres
    [void]$powershell.AddParameter('Item', $i)
    [void]$powershell.AddParameter('DelayMilliseconds', $delay)

    # Demarrer l'execution asynchrone
    $handle = $powershell.BeginInvoke()

    # Ajouter a la liste des runspaces
    $runspaces.Add([PSCustomObject]@{
            PowerShell = $powershell
            Handle     = $handle
            Item       = $i
            Delay      = $delay
            StartTime  = [datetime]::Now
        })
}

# Mesurer le temps d'execution
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Definir un timeout plus long (3 secondes)
$timeoutSeconds = 3
Write-Host "Attente de $runspaceCount runspaces avec un timeout de $timeoutSeconds secondes..." -ForegroundColor Cyan

# Attendre que tous les runspaces soient completes ou que le timeout soit atteint
$completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds $timeoutSeconds -WarningAction SilentlyContinue -Verbose

$stopwatch.Stop()
$elapsedMs = $stopwatch.ElapsedMilliseconds

# Traiter les resultats
$results = Invoke-RunspaceProcessor -CompletedRunspaces $completedRunspaces.Results -NoProgress

# Verifier que tous les runspaces ont ete completes
if ($completedRunspaces.Count -eq $runspaceCount) {
    Write-Host "  SUCCES: Tous les runspaces ont ete completes" -ForegroundColor Green
} else {
    Write-Host "  ECHEC: Certains runspaces n'ont pas ete completes ($($completedRunspaces.Count) sur $runspaceCount)" -ForegroundColor Red
}

# Verifier que le temps d'execution est inferieur au timeout
if ($elapsedMs -lt ($timeoutSeconds * 1000)) {
    Write-Host "  SUCCES: Le temps d'execution est inferieur au timeout ($elapsedMs ms)" -ForegroundColor Green
} else {
    Write-Host "  ECHEC: Le temps d'execution est superieur au timeout ($elapsedMs ms)" -ForegroundColor Red
}

# Verifier que tous les runspaces ont ete traites avec succes
if ($results.SuccessCount -eq $runspaceCount -and $results.ErrorCount -eq 0) {
    Write-Host "  SUCCES: Tous les runspaces ont ete traites avec succes" -ForegroundColor Green
} else {
    Write-Host "  ECHEC: Certains runspaces n'ont pas ete traites avec succes (Succes: $($results.SuccessCount), Erreurs: $($results.ErrorCount))" -ForegroundColor Red
}

# Nettoyer
$runspacePool.Close()
$runspacePool.Dispose()
Clear-UnifiedParallel -Verbose

Write-Host "`nTests termines." -ForegroundColor Green
