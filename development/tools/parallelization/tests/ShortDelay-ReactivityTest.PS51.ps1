<#
.SYNOPSIS
    Tests pour la reactivite de Wait-ForCompletedRunspace avec des delais tres courts.
.DESCRIPTION
    Ce script contient des tests pour verifier la reactivite
    de Wait-ForCompletedRunspace avec des delais tres courts (<10ms).
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

Write-Host "Test de reactivite pour Wait-ForCompletedRunspace avec delais courts" -ForegroundColor Yellow
Write-Host "=============================================================" -ForegroundColor Yellow

# Test 1: Avec des delais tres courts (<10ms)
Write-Host "`nTest 1: Avec des delais tres courts (<10ms)" -ForegroundColor Cyan

# Creer un pool de runspaces
$sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
$runspacePool = [runspacefactory]::CreateRunspacePool(1, 8, $sessionState, $Host)
$runspacePool.Open()

# Creer une liste pour stocker les runspaces
$runspaceCount = 20
$runspaces = New-Object System.Collections.Generic.List[object]

Write-Host "Creation de $runspaceCount runspaces avec delais tres courts..." -ForegroundColor Cyan

# Creer les runspaces avec des delais tres courts
$delaysMilliseconds = @(1, 2, 3, 5, 8)
for ($i = 0; $i -lt $runspaceCount; $i++) {
    $delay = $delaysMilliseconds[$i % $delaysMilliseconds.Length]

    $powershell = [powershell]::Create()
    $powershell.RunspacePool = $runspacePool

    # Ajouter un script simple avec delai tres court
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

# Attendre que tous les runspaces soient completes
Write-Host "Attente de $runspaceCount runspaces avec delais tres courts..." -ForegroundColor Cyan
$completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 10 -Verbose

$stopwatch.Stop()
$elapsedMs = $stopwatch.ElapsedMilliseconds

# Traiter les resultats
$results = Invoke-RunspaceProcessor -CompletedRunspaces $completedRunspaces.Results -NoProgress

# Calculer les statistiques
$avgTimePerRunspace = $elapsedMs / $runspaceCount
$avgDelay = ($delaysMilliseconds | Measure-Object -Average).Average
$overhead = $avgTimePerRunspace - $avgDelay

# Verifier que tous les runspaces ont ete completes
if ($completedRunspaces.Count -eq $runspaceCount) {
    Write-Host "  SUCCES: Tous les runspaces ont ete completes" -ForegroundColor Green
} else {
    Write-Host "  ECHEC: Certains runspaces n'ont pas ete completes ($($completedRunspaces.Count) sur $runspaceCount)" -ForegroundColor Red
}

# Verifier que tous les runspaces ont ete traites avec succes
if ($results.SuccessCount -eq $runspaceCount -and $results.ErrorCount -eq 0) {
    Write-Host "  SUCCES: Tous les runspaces ont ete traites avec succes" -ForegroundColor Green
} else {
    Write-Host "  ECHEC: Certains runspaces n'ont pas ete traites avec succes (Succes: $($results.SuccessCount), Erreurs: $($results.ErrorCount))" -ForegroundColor Red
}

# Verifier que le temps d'execution est raisonnable
if ($elapsedMs -lt 800) {
    Write-Host "  SUCCES: Le temps d'execution est raisonnable ($elapsedMs ms < 800 ms)" -ForegroundColor Green
} else {
    Write-Host "  ECHEC: Le temps d'execution est trop long ($elapsedMs ms > 800 ms)" -ForegroundColor Red
}

# Verifier que l'overhead est raisonnable
if ($overhead -lt 40) {
    Write-Host "  SUCCES: L'overhead est raisonnable ($([Math]::Round($overhead, 2)) ms < 40 ms)" -ForegroundColor Green
} else {
    Write-Host "  ECHEC: L'overhead est trop important ($([Math]::Round($overhead, 2)) ms > 40 ms)" -ForegroundColor Red
}

# Nettoyer les runspaces
$runspacePool.Close()
$runspacePool.Dispose()

# Test 2: Avec un grand nombre de runspaces a delais courts
Write-Host "`nTest 2: Avec un grand nombre de runspaces a delais courts" -ForegroundColor Cyan

# Creer un nouveau pool de runspaces
$sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
$runspacePool = [runspacefactory]::CreateRunspacePool(1, 8, $sessionState, $Host)
$runspacePool.Open()

# Creer une liste pour stocker les runspaces
$runspaceCount = 50
$runspaces = New-Object System.Collections.Generic.List[object]

Write-Host "Creation de $runspaceCount runspaces avec delais tres courts..." -ForegroundColor Cyan

# Creer les runspaces avec des delais tres courts
$delaysMilliseconds = @(1, 2, 3, 5, 8)
for ($i = 0; $i -lt $runspaceCount; $i++) {
    $delay = $delaysMilliseconds[$i % $delaysMilliseconds.Length]

    $powershell = [powershell]::Create()
    $powershell.RunspacePool = $runspacePool

    # Ajouter un script simple avec delai tres court
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

# Attendre que tous les runspaces soient completes
Write-Host "Attente de $runspaceCount runspaces avec delais tres courts..." -ForegroundColor Cyan
$completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 10 -Verbose

$stopwatch.Stop()
$elapsedMs = $stopwatch.ElapsedMilliseconds

# Verifier que tous les runspaces ont ete completes
if ($completedRunspaces.Count -eq $runspaceCount) {
    Write-Host "  SUCCES: Tous les runspaces ont ete completes" -ForegroundColor Green
} else {
    Write-Host "  ECHEC: Certains runspaces n'ont pas ete completes ($($completedRunspaces.Count) sur $runspaceCount)" -ForegroundColor Red
}

# Verifier que le temps d'execution est raisonnable
if ($elapsedMs -lt 1000) {
    Write-Host "  SUCCES: Le temps d'execution est raisonnable ($elapsedMs ms < 1000 ms)" -ForegroundColor Green
} else {
    Write-Host "  ECHEC: Le temps d'execution est trop long ($elapsedMs ms > 1000 ms)" -ForegroundColor Red
}

# Nettoyer
$runspacePool.Close()
$runspacePool.Dispose()
Clear-UnifiedParallel -Verbose

Write-Host "`nTests termines." -ForegroundColor Green
