# Test de collecte des métriques de temps de réponse pour différents scénarios
# Ce script mesure les temps de réponse de Wait-ForCompletedRunspace dans différents scénarios

# Importer le module UnifiedParallel
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Import-Module $modulePath -Force

# Initialiser le module
Initialize-UnifiedParallel -Verbose

# Fonction pour créer des runspaces de test avec différents types de charge
function New-TestRunspaces {
    param(
        [int]$Count = 50,
        [int[]]$DelaysMilliseconds = @(10, 20, 30, 40, 50),
        [ValidateSet("Sleep", "CPU", "IO", "Mixed")]
        [string]$WorkloadType = "Sleep"
    )

    # Créer un pool de runspaces
    $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $runspacePool = [runspacefactory]::CreateRunspacePool(1, 8, $sessionState, $Host)
    $runspacePool.Open()

    # Créer une liste pour stocker les runspaces
    $runspaces = [System.Collections.Generic.List[object]]::new($Count)

    # Sélectionner le script approprié en fonction du type de charge
    $scriptBlock = switch ($WorkloadType) {
        "Sleep" {
            {
                param($Item, $DelayMilliseconds)
                Start-Sleep -Milliseconds $DelayMilliseconds
                return [PSCustomObject]@{
                    Item         = $Item
                    Delay        = $DelayMilliseconds
                    WorkloadType = "Sleep"
                    ThreadId     = [System.Threading.Thread]::CurrentThread.ManagedThreadId
                    StartTime    = Get-Date
                    EndTime      = Get-Date
                }
            }
        }
        "CPU" {
            {
                param($Item, $DelayMilliseconds)
                $startTime = Get-Date

                # Simuler une charge CPU intensive
                $result = 0
                $iterations = $DelayMilliseconds * 1000 # Ajuster pour obtenir une durée similaire
                for ($i = 0; $i -lt $iterations; $i++) {
                    $result += [Math]::Pow($i % 100, 2) % 10
                }

                return [PSCustomObject]@{
                    Item         = $Item
                    Delay        = $DelayMilliseconds
                    WorkloadType = "CPU"
                    Result       = $result
                    ThreadId     = [System.Threading.Thread]::CurrentThread.ManagedThreadId
                    StartTime    = $startTime
                    EndTime      = Get-Date
                }
            }
        }
        "IO" {
            {
                param($Item, $DelayMilliseconds)
                $startTime = Get-Date

                # Simuler des opérations I/O
                $tempFile = [System.IO.Path]::GetTempFileName()
                $content = "X" * ($DelayMilliseconds * 100) # Taille proportionnelle au délai

                # Écriture
                [System.IO.File]::WriteAllText($tempFile, $content)

                # Lecture
                $readContent = [System.IO.File]::ReadAllText($tempFile)

                # Nettoyage
                Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue

                return [PSCustomObject]@{
                    Item         = $Item
                    Delay        = $DelayMilliseconds
                    WorkloadType = "IO"
                    ContentSize  = $content.Length
                    ThreadId     = [System.Threading.Thread]::CurrentThread.ManagedThreadId
                    StartTime    = $startTime
                    EndTime      = Get-Date
                }
            }
        }
        "Mixed" {
            {
                param($Item, $DelayMilliseconds)
                $startTime = Get-Date

                # Mélange de Sleep, CPU et IO
                $sleepTime = $DelayMilliseconds / 3
                Start-Sleep -Milliseconds $sleepTime

                # Partie CPU
                $result = 0
                $iterations = $sleepTime * 500
                for ($i = 0; $i -lt $iterations; $i++) {
                    $result += [Math]::Pow($i % 50, 2) % 10
                }

                # Partie IO
                $tempFile = [System.IO.Path]::GetTempFileName()
                $content = "X" * ($sleepTime * 50)
                [System.IO.File]::WriteAllText($tempFile, $content)
                $readContent = [System.IO.File]::ReadAllText($tempFile)
                Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue

                return [PSCustomObject]@{
                    Item         = $Item
                    Delay        = $DelayMilliseconds
                    WorkloadType = "Mixed"
                    Result       = $result
                    ContentSize  = $content.Length
                    ThreadId     = [System.Threading.Thread]::CurrentThread.ManagedThreadId
                    StartTime    = $startTime
                    EndTime      = Get-Date
                }
            }
        }
    }

    # Créer les runspaces avec le script approprié
    for ($i = 0; $i -lt $Count; $i++) {
        $delay = $DelaysMilliseconds[$i % $DelaysMilliseconds.Length]

        $powershell = [powershell]::Create()
        $powershell.RunspacePool = $runspacePool

        # Ajouter le script
        [void]$powershell.AddScript($scriptBlock)

        # Ajouter les paramètres
        [void]$powershell.AddParameter('Item', $i)
        [void]$powershell.AddParameter('DelayMilliseconds', $delay)

        # Démarrer l'exécution asynchrone
        $handle = $powershell.BeginInvoke()

        # Ajouter à la liste des runspaces
        $runspaces.Add([PSCustomObject]@{
                PowerShell   = $powershell
                Handle       = $handle
                Item         = $i
                Delay        = $delay
                WorkloadType = $WorkloadType
                StartTime    = [datetime]::Now
            })
    }

    return @{
        Runspaces = $runspaces
        Pool      = $runspacePool
    }
}

# Fonction pour mesurer les temps de réponse
function Measure-ResponseTime {
    param(
        [int]$RunspaceCount = 50,
        [int[]]$DelaysMilliseconds = @(10, 20, 30, 40, 50),
        [ValidateSet("Sleep", "CPU", "IO", "Mixed")]
        [string]$WorkloadType = "Sleep",
        [int]$BatchSize = 10,
        [int]$SleepMilliseconds = 50,
        [int]$Iterations = 3
    )

    $results = @{
        RunspaceCount     = $RunspaceCount
        WorkloadType      = $WorkloadType
        BatchSize         = $BatchSize
        SleepMilliseconds = $SleepMilliseconds
        TotalTime         = 0
        CPUTime           = 0
        MemoryUsage       = 0
        ResponseTimes     = @()
        CompletionTimes   = @()
        Iterations        = $Iterations
    }

    for ($iter = 1; $iter -le $Iterations; $iter++) {
        Write-Host "Itération $iter/$Iterations avec $RunspaceCount runspaces de type $WorkloadType..." -ForegroundColor Gray

        # Créer des runspaces de test
        $testData = New-TestRunspaces -Count $RunspaceCount -DelaysMilliseconds $DelaysMilliseconds -WorkloadType $WorkloadType
        $runspaces = $testData.Runspaces
        $pool = $testData.Pool

        # Mesurer le temps d'exécution et l'utilisation CPU
        $process = Get-Process -Id $PID
        $startCPU = $process.TotalProcessorTime
        $startMemory = $process.WorkingSet64

        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        # Modifier la variable globale de taille de lot
        $script:BatchSizeOverride = $BatchSize

        # Exécuter Wait-ForCompletedRunspace
        $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 60 -SleepMilliseconds $SleepMilliseconds -Verbose

        # Réinitialiser la variable globale
        $script:BatchSizeOverride = $null

        $stopwatch.Stop()
        $elapsedMs = $stopwatch.ElapsedMilliseconds

        # Mesurer l'utilisation CPU et mémoire
        $process = Get-Process -Id $PID
        $endCPU = $process.TotalProcessorTime
        $endMemory = $process.WorkingSet64

        $cpuTime = ($endCPU - $startCPU).TotalMilliseconds
        $memoryUsage = ($endMemory - $startMemory) / 1MB

        # Traiter les résultats
        $results.TotalTime += $elapsedMs
        $results.CPUTime += $cpuTime
        $results.MemoryUsage += $memoryUsage

        # Calculer le temps de réponse moyen (temps d'exécution / nombre de runspaces)
        $responseTime = $elapsedMs / $RunspaceCount
        $results.ResponseTimes += $responseTime

        # Traiter les résultats des runspaces
        $processedResults = Invoke-RunspaceProcessor -CompletedRunspaces $completedRunspaces.Results -NoProgress

        # Calculer les temps de complétion individuels
        $completionTimes = $processedResults.Results | ForEach-Object {
            if ($_.Output.EndTime -and $_.Output.StartTime) {
                ($_.Output.EndTime - $_.Output.StartTime).TotalMilliseconds
            } else {
                0
            }
        }

        # Ajouter les temps de complétion à la liste
        $results.CompletionTimes += ($completionTimes | Measure-Object -Average -Minimum -Maximum)

        # Afficher les résultats de l'itération
        Write-Host "  Temps d'exécution: $elapsedMs ms" -ForegroundColor Cyan
        Write-Host "  Temps CPU: $([Math]::Round($cpuTime, 2)) ms" -ForegroundColor Cyan
        Write-Host "  Utilisation mémoire: $([Math]::Round($memoryUsage, 2)) MB" -ForegroundColor Cyan
        Write-Host "  Temps de réponse moyen: $([Math]::Round($responseTime, 2)) ms/runspace" -ForegroundColor Cyan

        if ($completionTimes.Count -gt 0) {
            $avgCompletion = ($completionTimes | Measure-Object -Average).Average
            $minCompletion = ($completionTimes | Measure-Object -Minimum).Minimum
            $maxCompletion = ($completionTimes | Measure-Object -Maximum).Maximum

            Write-Host "  Temps de complétion moyen: $([Math]::Round($avgCompletion, 2)) ms" -ForegroundColor Cyan
            Write-Host "  Temps de complétion min: $([Math]::Round($minCompletion, 2)) ms" -ForegroundColor Cyan
            Write-Host "  Temps de complétion max: $([Math]::Round($maxCompletion, 2)) ms" -ForegroundColor Cyan
        }

        # Nettoyer
        $pool.Close()
        $pool.Dispose()
    }

    # Calculer les moyennes
    $results.TotalTime = $results.TotalTime / $Iterations
    $results.CPUTime = $results.CPUTime / $Iterations
    $results.MemoryUsage = $results.MemoryUsage / $Iterations
    $results.AvgResponseTime = ($results.ResponseTimes | Measure-Object -Average).Average

    # Calculer les moyennes des temps de complétion
    $avgCompletionTimes = $results.CompletionTimes | ForEach-Object { $_.Average }
    $minCompletionTimes = $results.CompletionTimes | ForEach-Object { $_.Minimum }
    $maxCompletionTimes = $results.CompletionTimes | ForEach-Object { $_.Maximum }

    $results.AvgCompletionTime = ($avgCompletionTimes | Measure-Object -Average).Average
    $results.MinCompletionTime = ($minCompletionTimes | Measure-Object -Average).Average
    $results.MaxCompletionTime = ($maxCompletionTimes | Measure-Object -Average).Average

    return [PSCustomObject]$results
}

# Fonction pour exécuter les tests de temps de réponse
function Test-ResponseTimeScenarios {
    param(
        [int[]]$RunspaceCounts = @(20, 50, 100),
        [ValidateSet("Sleep", "CPU", "IO", "Mixed")]
        [string[]]$WorkloadTypes = @("Sleep", "CPU", "IO", "Mixed"),
        [int]$BatchSize = 10,
        [int]$SleepMilliseconds = 50,
        [int]$Iterations = 3
    )

    $results = @()

    foreach ($runspaceCount in $RunspaceCounts) {
        foreach ($workloadType in $WorkloadTypes) {
            Write-Host "`nTest avec $runspaceCount runspaces de type $($workloadType):" -ForegroundColor Green

            # Ajuster les délais en fonction du type de charge
            $delaysMilliseconds = switch ($workloadType) {
                "Sleep" { @(10, 20, 30, 40, 50) }
                "CPU" { @(5, 10, 15, 20, 25) }
                "IO" { @(5, 10, 15, 20, 25) }
                "Mixed" { @(10, 20, 30, 40, 50) }
            }

            $scenarioResults = Measure-ResponseTime -RunspaceCount $runspaceCount -DelaysMilliseconds $delaysMilliseconds -WorkloadType $workloadType -BatchSize $BatchSize -SleepMilliseconds $SleepMilliseconds -Iterations $Iterations
            $results += $scenarioResults

            # Afficher les résultats
            Write-Host "`nRésultats pour $runspaceCount runspaces de type $($workloadType):" -ForegroundColor Green
            Write-Host "  Temps d'exécution moyen: $([Math]::Round($scenarioResults.TotalTime, 2)) ms" -ForegroundColor Cyan
            Write-Host "  Temps CPU moyen: $([Math]::Round($scenarioResults.CPUTime, 2)) ms" -ForegroundColor Cyan
            Write-Host "  Utilisation mémoire moyenne: $([Math]::Round($scenarioResults.MemoryUsage, 2)) MB" -ForegroundColor Cyan
            Write-Host "  Temps de réponse moyen: $([Math]::Round($scenarioResults.AvgResponseTime, 2)) ms/runspace" -ForegroundColor Cyan
            Write-Host "  Temps de complétion moyen: $([Math]::Round($scenarioResults.AvgCompletionTime, 2)) ms" -ForegroundColor Cyan
            Write-Host "  Temps de complétion min: $([Math]::Round($scenarioResults.MinCompletionTime, 2)) ms" -ForegroundColor Cyan
            Write-Host "  Temps de complétion max: $([Math]::Round($scenarioResults.MaxCompletionTime, 2)) ms" -ForegroundColor Cyan
        }
    }

    return $results
}

# Exécuter les tests
Write-Host "Test de collecte des métriques de temps de réponse pour différents scénarios" -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor Yellow

# Exécuter les tests avec différents scénarios
$results = Test-ResponseTimeScenarios -RunspaceCounts @(20, 50) -WorkloadTypes @("Sleep", "CPU", "Mixed") -BatchSize 10 -SleepMilliseconds 50 -Iterations 2

# Afficher le résumé des résultats
Write-Host "`nRésumé des tests de temps de réponse:" -ForegroundColor Yellow
$summary = $results | ForEach-Object {
    [PSCustomObject]@{
        "Runspaces"             = $_.RunspaceCount
        "Type"                  = $_.WorkloadType
        "Temps (ms)"            = [Math]::Round($_.TotalTime, 2)
        "CPU (ms)"              = [Math]::Round($_.CPUTime, 2)
        "Mémoire (MB)"          = [Math]::Round($_.MemoryUsage, 2)
        "Réponse (ms/runspace)" = [Math]::Round($_.AvgResponseTime, 2)
        "Complétion (ms)"       = [Math]::Round($_.AvgCompletionTime, 2)
    }
}
$summary | Format-Table -AutoSize

# Identifier les scénarios avec les meilleurs et les pires temps de réponse
$bestResponseTime = $results | Sort-Object AvgResponseTime | Select-Object -First 1
$worstResponseTime = $results | Sort-Object AvgResponseTime -Descending | Select-Object -First 1

Write-Host "`nMeilleur temps de réponse:" -ForegroundColor Green
Write-Host "  Scénario: $($bestResponseTime.RunspaceCount) runspaces de type $($bestResponseTime.WorkloadType)" -ForegroundColor Green
Write-Host "  Temps de réponse: $([Math]::Round($bestResponseTime.AvgResponseTime, 2)) ms/runspace" -ForegroundColor Green

Write-Host "`nPire temps de réponse:" -ForegroundColor Red
Write-Host "  Scénario: $($worstResponseTime.RunspaceCount) runspaces de type $($worstResponseTime.WorkloadType)" -ForegroundColor Red
Write-Host "  Temps de réponse: $([Math]::Round($worstResponseTime.AvgResponseTime, 2)) ms/runspace" -ForegroundColor Red

# Sauvegarder les résultats dans un fichier CSV
$csvPath = Join-Path -Path $PSScriptRoot -ChildPath "ResponseTime-Metrics-Results.csv"
$summary | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

Write-Host "`nRésultats sauvegardés dans $csvPath" -ForegroundColor Green

# Nettoyer
Clear-UnifiedParallel -Verbose

Write-Host "`nTests terminés." -ForegroundColor Green
