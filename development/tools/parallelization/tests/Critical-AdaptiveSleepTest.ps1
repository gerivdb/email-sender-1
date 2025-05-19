# Test critique pour la fonction Wait-ForCompletedRunspace avec délai adaptatif
# Ce script teste les aspects critiques de l'implémentation

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Import-Module $modulePath -Force

# Initialiser le module
Initialize-UnifiedParallel -Verbose

Write-Host "Test critique pour Wait-ForCompletedRunspace avec délai adaptatif" -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor Yellow

# Fonction pour créer des runspaces de test
function New-TestRunspaces {
    param(
        [int]$Count = 5,
        [int]$DelayMilliseconds = 100
    )

    # Créer un pool de runspaces
    $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $runspacePool = [runspacefactory]::CreateRunspacePool(1, 4, $sessionState, $Host)
    $runspacePool.Open()

    # Créer une liste pour stocker les runspaces
    $runspaces = [System.Collections.Generic.List[object]]::new()

    # Créer les runspaces
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

        # Ajouter les paramètres
        [void]$powershell.AddParameter('Item', $i)
        [void]$powershell.AddParameter('DelayMilliseconds', $DelayMilliseconds)

        # Démarrer l'exécution asynchrone
        $handle = $powershell.BeginInvoke()

        # Ajouter à la liste des runspaces
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

# Test 1: Vérifier le comportement avec un nombre normal de runspaces
Write-Host "`nTest 1: Comportement avec un nombre normal de runspaces (10)" -ForegroundColor Cyan
$test1 = New-TestRunspaces -Count 10 -DelayMilliseconds 100
$runspaces1 = $test1.Runspaces
$pool1 = $test1.Pool

$stopwatch1 = [System.Diagnostics.Stopwatch]::StartNew()
$completedRunspaces1 = Wait-ForCompletedRunspace -Runspaces $runspaces1 -WaitForAll -NoProgress -TimeoutSeconds 10 -Verbose
$stopwatch1.Stop()

Write-Host "Temps d'exécution: $($stopwatch1.ElapsedMilliseconds) ms" -ForegroundColor Green
Write-Host "Runspaces complétés: $($completedRunspaces1.Count) sur 10" -ForegroundColor Green

$results1 = Invoke-RunspaceProcessor -CompletedRunspaces $completedRunspaces1.Results -NoProgress
Write-Host "Succès: $($results1.SuccessCount), Erreurs: $($results1.ErrorCount)" -ForegroundColor Green

$pool1.Close()
$pool1.Dispose()

# Test 2: Vérifier le comportement avec un timeout
Write-Host "`nTest 2: Comportement avec un timeout" -ForegroundColor Cyan
$test2 = New-TestRunspaces -Count 5 -DelayMilliseconds 1000
$runspaces2 = $test2.Runspaces
$pool2 = $test2.Pool

$stopwatch2 = [System.Diagnostics.Stopwatch]::StartNew()
$completedRunspaces2 = Wait-ForCompletedRunspace -Runspaces $runspaces2 -WaitForAll -NoProgress -TimeoutSeconds 1 -Verbose
$stopwatch2.Stop()

Write-Host "Temps d'exécution: $($stopwatch2.ElapsedMilliseconds) ms" -ForegroundColor Green
Write-Host "Runspaces complétés: $($completedRunspaces2.Count) sur 5" -ForegroundColor Green

if ($completedRunspaces2.Count -lt 5) {
    Write-Host "Timeout détecté correctement." -ForegroundColor Green
} else {
    Write-Host "ERREUR: Timeout non détecté." -ForegroundColor Red
}

$pool2.Close()
$pool2.Dispose()

# Test 3: Vérifier le comportement avec des délais très courts
Write-Host "`nTest 3: Comportement avec des délais très courts (5ms)" -ForegroundColor Cyan
$test3 = New-TestRunspaces -Count 20 -DelayMilliseconds 5
$runspaces3 = $test3.Runspaces
$pool3 = $test3.Pool

$stopwatch3 = [System.Diagnostics.Stopwatch]::StartNew()
$completedRunspaces3 = Wait-ForCompletedRunspace -Runspaces $runspaces3 -WaitForAll -NoProgress -TimeoutSeconds 10 -Verbose
$stopwatch3.Stop()

Write-Host "Temps d'exécution: $($stopwatch3.ElapsedMilliseconds) ms" -ForegroundColor Green
Write-Host "Runspaces complétés: $($completedRunspaces3.Count) sur 20" -ForegroundColor Green

$results3 = Invoke-RunspaceProcessor -CompletedRunspaces $completedRunspaces3.Results -NoProgress
Write-Host "Succès: $($results3.SuccessCount), Erreurs: $($results3.ErrorCount)" -ForegroundColor Green

$pool3.Close()
$pool3.Dispose()

# Test 4: Vérifier le comportement avec des délais très longs
Write-Host "`nTest 4: Comportement avec des délais très longs (500ms)" -ForegroundColor Cyan
$test4 = New-TestRunspaces -Count 5 -DelayMilliseconds 500
$runspaces4 = $test4.Runspaces
$pool4 = $test4.Pool

$stopwatch4 = [System.Diagnostics.Stopwatch]::StartNew()
$completedRunspaces4 = Wait-ForCompletedRunspace -Runspaces $runspaces4 -WaitForAll -NoProgress -TimeoutSeconds 10 -Verbose
$stopwatch4.Stop()

Write-Host "Temps d'exécution: $($stopwatch4.ElapsedMilliseconds) ms" -ForegroundColor Green
Write-Host "Runspaces complétés: $($completedRunspaces4.Count) sur 5" -ForegroundColor Green

$results4 = Invoke-RunspaceProcessor -CompletedRunspaces $completedRunspaces4.Results -NoProgress
Write-Host "Succès: $($results4.SuccessCount), Erreurs: $($results4.ErrorCount)" -ForegroundColor Green

$pool4.Close()
$pool4.Dispose()

# Résumé des tests
Write-Host "`nRésumé des tests:" -ForegroundColor Yellow
$testResults = @(
    [PSCustomObject]@{
        Test = "Test 1: Nombre normal (10)"
        Success = $completedRunspaces1.Count -eq 10
        ElapsedMs = $stopwatch1.ElapsedMilliseconds
        CompletedCount = $completedRunspaces1.Count
        TotalCount = 10
    },
    [PSCustomObject]@{
        Test = "Test 2: Timeout"
        Success = $completedRunspaces2.Count -lt 5
        ElapsedMs = $stopwatch2.ElapsedMilliseconds
        CompletedCount = $completedRunspaces2.Count
        TotalCount = 5
    },
    [PSCustomObject]@{
        Test = "Test 3: Délais courts"
        Success = $completedRunspaces3.Count -eq 20
        ElapsedMs = $stopwatch3.ElapsedMilliseconds
        CompletedCount = $completedRunspaces3.Count
        TotalCount = 20
    },
    [PSCustomObject]@{
        Test = "Test 4: Délais longs"
        Success = $completedRunspaces4.Count -eq 5
        ElapsedMs = $stopwatch4.ElapsedMilliseconds
        CompletedCount = $completedRunspaces4.Count
        TotalCount = 5
    }
)

$testResults | Format-Table -AutoSize

# Vérifier si tous les tests ont réussi
$allTestsPassed = ($testResults | Where-Object { -not $_.Success }).Count -eq 0

if ($allTestsPassed) {
    Write-Host "TOUS LES TESTS ONT RÉUSSI!" -ForegroundColor Green
} else {
    Write-Host "CERTAINS TESTS ONT ÉCHOUÉ!" -ForegroundColor Red
    $testResults | Where-Object { -not $_.Success } | Format-Table -AutoSize
}

# Nettoyer
Clear-UnifiedParallel -Verbose

Write-Host "`nTests terminés." -ForegroundColor Green
