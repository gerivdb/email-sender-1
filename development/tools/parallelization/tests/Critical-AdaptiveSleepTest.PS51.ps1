<#
.SYNOPSIS
    Tests pour la fonction Wait-ForCompletedRunspace avec delai adaptatif.
.DESCRIPTION
    Ce script contient des tests pour verifier les aspects critiques
    de l'implementation de Wait-ForCompletedRunspace avec delai adaptatif.
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

# Fonction pour creer des runspaces de test
function New-TestRunspaces {
    param(
        [int]$Count = 5,
        [int]$DelayMilliseconds = 100
    )

    # Creer un pool de runspaces
    $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $runspacePool = [runspacefactory]::CreateRunspacePool(1, 4, $sessionState, $Host)
    $runspacePool.Open()

    # Creer une liste pour stocker les runspaces
    $runspaces = New-Object System.Collections.Generic.List[object]

    # Creer les runspaces
    for ($i = 0; $i -lt $Count; $i++) {
        $powershell = [powershell]::Create()
        $powershell.RunspacePool = $runspacePool

        # Ajouter un script simple
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

        # Ajouter les parametres
        [void]$powershell.AddParameter('Item', $i)
        [void]$powershell.AddParameter('DelayMilliseconds', $DelayMilliseconds)

        # Demarrer l'execution asynchrone
        $handle = $powershell.BeginInvoke()

        # Ajouter a la liste des runspaces
        $runspaces.Add([PSCustomObject]@{
                PowerShell = $powershell
                Handle     = $handle
                Item       = $i
                StartTime  = [datetime]::Now
            })
    }

    return @{
        Runspaces = $runspaces
        Pool = $runspacePool
    }
}

# Tests pour le comportement avec un nombre normal de runspaces
Write-Host "Test: Comportement avec un nombre normal de runspaces" -ForegroundColor Cyan

$test = New-TestRunspaces -Count 10 -DelayMilliseconds 100
$runspaces = $test.Runspaces
$pool = $test.Pool

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 10 -Verbose
$stopwatch.Stop()

$results = Invoke-RunspaceProcessor -CompletedRunspaces $completedRunspaces.Results -NoProgress

# Verifier que tous les runspaces ont ete completes
if ($completedRunspaces.Count -eq 10) {
    Write-Host "  SUCCES: Tous les runspaces ont ete completes" -ForegroundColor Green
} else {
    Write-Host "  ECHEC: Certains runspaces n'ont pas ete completes ($($completedRunspaces.Count) sur 10)" -ForegroundColor Red
}

# Verifier que tous les runspaces ont ete traites avec succes
if ($results.SuccessCount -eq 10 -and $results.ErrorCount -eq 0) {
    Write-Host "  SUCCES: Tous les runspaces ont ete traites avec succes" -ForegroundColor Green
} else {
    Write-Host "  ECHEC: Certains runspaces n'ont pas ete traites avec succes (Succes: $($results.SuccessCount), Erreurs: $($results.ErrorCount))" -ForegroundColor Red
}

# Verifier que l'execution s'est faite dans un delai raisonnable
if ($stopwatch.ElapsedMilliseconds -lt 2000) {
    Write-Host "  SUCCES: L'execution s'est faite dans un delai raisonnable ($($stopwatch.ElapsedMilliseconds) ms)" -ForegroundColor Green
} else {
    Write-Host "  ECHEC: L'execution a pris trop de temps ($($stopwatch.ElapsedMilliseconds) ms)" -ForegroundColor Red
}

$pool.Close()
$pool.Dispose()

# Tests pour le comportement avec un timeout
Write-Host "`nTest: Comportement avec un timeout" -ForegroundColor Cyan

$test = New-TestRunspaces -Count 5 -DelayMilliseconds 1000
$runspaces = $test.Runspaces
$pool = $test.Pool

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 1 -Verbose
$stopwatch.Stop()

# Verifier que le timeout a ete respecte
if ($stopwatch.ElapsedMilliseconds -lt 1200 -and $stopwatch.ElapsedMilliseconds -gt 800) {
    Write-Host "  SUCCES: Le timeout a ete respecte ($($stopwatch.ElapsedMilliseconds) ms)" -ForegroundColor Green
} else {
    Write-Host "  ECHEC: Le timeout n'a pas ete respecte ($($stopwatch.ElapsedMilliseconds) ms)" -ForegroundColor Red
}

# Verifier que tous les runspaces n'ont pas ete completes
if ($completedRunspaces.Count -lt 5) {
    Write-Host "  SUCCES: Tous les runspaces n'ont pas ete completes ($($completedRunspaces.Count) sur 5)" -ForegroundColor Green
} else {
    Write-Host "  ECHEC: Tous les runspaces ont ete completes malgre le timeout" -ForegroundColor Red
}

$pool.Close()
$pool.Dispose()

# Tests pour le comportement avec des delais tres courts
Write-Host "`nTest: Comportement avec des delais tres courts" -ForegroundColor Cyan

$test = New-TestRunspaces -Count 20 -DelayMilliseconds 5
$runspaces = $test.Runspaces
$pool = $test.Pool

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 10 -Verbose
$stopwatch.Stop()

$results = Invoke-RunspaceProcessor -CompletedRunspaces $completedRunspaces.Results -NoProgress

# Verifier que tous les runspaces ont ete completes
if ($completedRunspaces.Count -eq 20) {
    Write-Host "  SUCCES: Tous les runspaces ont ete completes" -ForegroundColor Green
} else {
    Write-Host "  ECHEC: Certains runspaces n'ont pas ete completes ($($completedRunspaces.Count) sur 20)" -ForegroundColor Red
}

# Verifier que tous les runspaces ont ete traites avec succes
if ($results.SuccessCount -eq 20 -and $results.ErrorCount -eq 0) {
    Write-Host "  SUCCES: Tous les runspaces ont ete traites avec succes" -ForegroundColor Green
} else {
    Write-Host "  ECHEC: Certains runspaces n'ont pas ete traites avec succes (Succes: $($results.SuccessCount), Erreurs: $($results.ErrorCount))" -ForegroundColor Red
}

# Verifier que l'execution s'est faite rapidement
if ($stopwatch.ElapsedMilliseconds -lt 1000) {
    Write-Host "  SUCCES: L'execution s'est faite rapidement ($($stopwatch.ElapsedMilliseconds) ms)" -ForegroundColor Green
} else {
    Write-Host "  ECHEC: L'execution a pris trop de temps ($($stopwatch.ElapsedMilliseconds) ms)" -ForegroundColor Red
}

$pool.Close()
$pool.Dispose()

# Tests pour le comportement avec des delais tres longs
Write-Host "`nTest: Comportement avec des delais tres longs" -ForegroundColor Cyan

$test = New-TestRunspaces -Count 5 -DelayMilliseconds 500
$runspaces = $test.Runspaces
$pool = $test.Pool

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 10 -Verbose
$stopwatch.Stop()

$results = Invoke-RunspaceProcessor -CompletedRunspaces $completedRunspaces.Results -NoProgress

# Verifier que tous les runspaces ont ete completes
if ($completedRunspaces.Count -eq 5) {
    Write-Host "  SUCCES: Tous les runspaces ont ete completes" -ForegroundColor Green
} else {
    Write-Host "  ECHEC: Certains runspaces n'ont pas ete completes ($($completedRunspaces.Count) sur 5)" -ForegroundColor Red
}

# Verifier que tous les runspaces ont ete traites avec succes
if ($results.SuccessCount -eq 5 -and $results.ErrorCount -eq 0) {
    Write-Host "  SUCCES: Tous les runspaces ont ete traites avec succes" -ForegroundColor Green
} else {
    Write-Host "  ECHEC: Certains runspaces n'ont pas ete traites avec succes (Succes: $($results.SuccessCount), Erreurs: $($results.ErrorCount))" -ForegroundColor Red
}

# Verifier que l'execution s'est faite dans un delai proportionnel
if ($stopwatch.ElapsedMilliseconds -gt 500 -and $stopwatch.ElapsedMilliseconds -lt 3000) {
    Write-Host "  SUCCES: L'execution s'est faite dans un delai proportionnel ($($stopwatch.ElapsedMilliseconds) ms)" -ForegroundColor Green
} else {
    Write-Host "  ECHEC: L'execution ne s'est pas faite dans un delai proportionnel ($($stopwatch.ElapsedMilliseconds) ms)" -ForegroundColor Red
}

$pool.Close()
$pool.Dispose()

# Nettoyer
Clear-UnifiedParallel -Verbose

Write-Host "`nTous les tests sont termines." -ForegroundColor Cyan
