# Test simple de scalabilité pour Wait-ForCompletedRunspace
# Ce script teste la capacité de Wait-ForCompletedRunspace à gérer un grand nombre de runspaces

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Import-Module $modulePath -Force

# Initialiser le module
Initialize-UnifiedParallel -Verbose

Write-Host "Test de scalabilité pour Wait-ForCompletedRunspace" -ForegroundColor Yellow
Write-Host "=================================================" -ForegroundColor Yellow

# Fonction pour créer un grand nombre de runspaces
function New-LargeRunspaceSet {
    param(
        [int]$Count = 50,
        [int[]]$DelaysMilliseconds = @(10, 20, 30, 40, 50)
    )

    Write-Host "Création de $Count runspaces..." -ForegroundColor Cyan

    # Créer un pool de runspaces
    $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $runspacePool = [runspacefactory]::CreateRunspacePool(1, 8, $sessionState, $Host)
    $runspacePool.Open()

    # Créer une liste pour stocker les runspaces
    $runspaces = [System.Collections.Generic.List[object]]::new($Count)

    # Créer les runspaces avec des délais différents
    for ($i = 0; $i -lt $Count; $i++) {
        $delay = $DelaysMilliseconds[$i % $DelaysMilliseconds.Length]
        
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

    return @{
        Runspaces = $runspaces
        Pool = $runspacePool
    }
}

# Test avec 50 runspaces
Write-Host "`nTest avec 50 runspaces:" -ForegroundColor Green
$test50 = New-LargeRunspaceSet -Count 50 -DelaysMilliseconds @(10, 20, 30, 40, 50)
$runspaces50 = $test50.Runspaces
$pool50 = $test50.Pool

$stopwatch50 = [System.Diagnostics.Stopwatch]::StartNew()
Write-Host "Attente de 50 runspaces..." -ForegroundColor Cyan
$completedRunspaces50 = Wait-ForCompletedRunspace -Runspaces $runspaces50 -WaitForAll -NoProgress -TimeoutSeconds 30 -Verbose
$stopwatch50.Stop()

Write-Host "Temps d'exécution pour 50 runspaces: $($stopwatch50.ElapsedMilliseconds) ms" -ForegroundColor Green
Write-Host "Runspaces complétés: $($completedRunspaces50.Count) sur 50" -ForegroundColor Green

$results50 = Invoke-RunspaceProcessor -CompletedRunspaces $completedRunspaces50.Results -NoProgress
Write-Host "Succès: $($results50.SuccessCount), Erreurs: $($results50.ErrorCount)" -ForegroundColor Green

$pool50.Close()
$pool50.Dispose()

# Test avec 75 runspaces
Write-Host "`nTest avec 75 runspaces:" -ForegroundColor Green
$test75 = New-LargeRunspaceSet -Count 75 -DelaysMilliseconds @(5, 10, 15, 20, 25, 30)
$runspaces75 = $test75.Runspaces
$pool75 = $test75.Pool

$stopwatch75 = [System.Diagnostics.Stopwatch]::StartNew()
Write-Host "Attente de 75 runspaces..." -ForegroundColor Cyan
$completedRunspaces75 = Wait-ForCompletedRunspace -Runspaces $runspaces75 -WaitForAll -NoProgress -TimeoutSeconds 45 -Verbose
$stopwatch75.Stop()

Write-Host "Temps d'exécution pour 75 runspaces: $($stopwatch75.ElapsedMilliseconds) ms" -ForegroundColor Green
Write-Host "Runspaces complétés: $($completedRunspaces75.Count) sur 75" -ForegroundColor Green

$results75 = Invoke-RunspaceProcessor -CompletedRunspaces $completedRunspaces75.Results -NoProgress
Write-Host "Succès: $($results75.SuccessCount), Erreurs: $($results75.ErrorCount)" -ForegroundColor Green

$pool75.Close()
$pool75.Dispose()

# Test avec 100 runspaces
Write-Host "`nTest avec 100 runspaces:" -ForegroundColor Green
$test100 = New-LargeRunspaceSet -Count 100 -DelaysMilliseconds @(10, 20, 30, 40, 50)
$runspaces100 = $test100.Runspaces
$pool100 = $test100.Pool

$stopwatch100 = [System.Diagnostics.Stopwatch]::StartNew()
Write-Host "Attente de 100 runspaces..." -ForegroundColor Cyan
$completedRunspaces100 = Wait-ForCompletedRunspace -Runspaces $runspaces100 -WaitForAll -NoProgress -TimeoutSeconds 60 -Verbose
$stopwatch100.Stop()

Write-Host "Temps d'exécution pour 100 runspaces: $($stopwatch100.ElapsedMilliseconds) ms" -ForegroundColor Green
Write-Host "Runspaces complétés: $($completedRunspaces100.Count) sur 100" -ForegroundColor Green

$results100 = Invoke-RunspaceProcessor -CompletedRunspaces $completedRunspaces100.Results -NoProgress
Write-Host "Succès: $($results100.SuccessCount), Erreurs: $($results100.ErrorCount)" -ForegroundColor Green

$pool100.Close()
$pool100.Dispose()

# Résumé des tests
Write-Host "`nRésumé des tests de scalabilité:" -ForegroundColor Yellow
$testResults = @(
    [PSCustomObject]@{
        Test = "50 runspaces"
        ElapsedMs = $stopwatch50.ElapsedMilliseconds
        CompletedCount = $completedRunspaces50.Count
        TotalCount = 50
        Success = $completedRunspaces50.Count -eq 50
    },
    [PSCustomObject]@{
        Test = "75 runspaces"
        ElapsedMs = $stopwatch75.ElapsedMilliseconds
        CompletedCount = $completedRunspaces75.Count
        TotalCount = 75
        Success = $completedRunspaces75.Count -eq 75
    },
    [PSCustomObject]@{
        Test = "100 runspaces"
        ElapsedMs = $stopwatch100.ElapsedMilliseconds
        CompletedCount = $completedRunspaces100.Count
        TotalCount = 100
        Success = $completedRunspaces100.Count -eq 100
    }
)

$testResults | Format-Table -AutoSize

# Vérifier si tous les tests ont réussi
$allTestsPassed = ($testResults | Where-Object { -not $_.Success }).Count -eq 0

if ($allTestsPassed) {
    Write-Host "TOUS LES TESTS DE SCALABILITÉ ONT RÉUSSI!" -ForegroundColor Green
} else {
    Write-Host "CERTAINS TESTS DE SCALABILITÉ ONT ÉCHOUÉ!" -ForegroundColor Red
    $testResults | Where-Object { -not $_.Success } | Format-Table -AutoSize
}

# Nettoyer
Clear-UnifiedParallel -Verbose

Write-Host "`nTests terminés." -ForegroundColor Green
