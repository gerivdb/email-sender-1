# Test de l'impact du délai adaptatif sur l'utilisation CPU
# Ce script mesure l'impact du délai adaptatif sur l'utilisation CPU dans Wait-ForCompletedRunspace

# Importer le module UnifiedParallel
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Import-Module $modulePath -Force

# Importer l'implémentation originale (sans délai adaptatif)
$originalImplementationPath = Join-Path -Path $PSScriptRoot -ChildPath "Original-WaitForCompletedRunspace.ps1"
. $originalImplementationPath

# Initialiser le module
Initialize-UnifiedParallel -Verbose

# Fonction pour créer des runspaces de test
function New-TestRunspaces {
    param(
        [int]$Count = 50,
        [int[]]$DelaysMilliseconds = @(10, 20, 30, 40, 50)
    )

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

# Fonction pour mesurer l'utilisation CPU pendant l'exécution
function Measure-CPUUsage {
    param(
        [scriptblock]$ScriptBlock,
        [int]$SamplingIntervalMs = 100,
        [int]$TimeoutSeconds = 60
    )

    $cpuSamples = [System.Collections.Generic.List[double]]::new()
    $process = Get-Process -Id $PID
    $startCPU = $process.TotalProcessorTime
    $startTime = [datetime]::Now
    $timeout = $startTime.AddSeconds($TimeoutSeconds)
    
    # Démarrer un job en arrière-plan pour exécuter le script
    $job = Start-Job -ScriptBlock $ScriptBlock
    
    # Mesurer l'utilisation CPU pendant l'exécution du job
    while ($job.State -eq "Running" -and [datetime]::Now -lt $timeout) {
        $process = Get-Process -Id $PID
        $currentCPU = $process.TotalProcessorTime
        $currentTime = [datetime]::Now
        
        $cpuTime = ($currentCPU - $startCPU).TotalMilliseconds
        $elapsedTime = ($currentTime - $startTime).TotalMilliseconds
        
        if ($elapsedTime -gt 0) {
            $cpuPercentage = ($cpuTime / $elapsedTime) * 100
            $cpuSamples.Add($cpuPercentage)
        }
        
        $startCPU = $currentCPU
        $startTime = $currentTime
        
        Start-Sleep -Milliseconds $SamplingIntervalMs
    }
    
    # Attendre que le job se termine
    $result = Receive-Job -Job $job -Wait
    Remove-Job -Job $job
    
    # Calculer les statistiques d'utilisation CPU
    $avgCPU = if ($cpuSamples.Count -gt 0) { ($cpuSamples | Measure-Object -Average).Average } else { 0 }
    $maxCPU = if ($cpuSamples.Count -gt 0) { ($cpuSamples | Measure-Object -Maximum).Maximum } else { 0 }
    $minCPU = if ($cpuSamples.Count -gt 0) { ($cpuSamples | Measure-Object -Minimum).Minimum } else { 0 }
    
    return [PSCustomObject]@{
        Result = $result
        CPUSamples = $cpuSamples
        AverageCPU = $avgCPU
        MaximumCPU = $maxCPU
        MinimumCPU = $minCPU
        SampleCount = $cpuSamples.Count
    }
}

# Fonction pour tester l'impact du délai adaptatif sur l'utilisation CPU
function Test-AdaptiveSleepCPUImpact {
    param(
        [int]$RunspaceCount = 50,
        [int]$Iterations = 3,
        [int[]]$SleepMilliseconds = @(10, 50, 100)
    )

    $results = @()

    foreach ($sleepMs in $SleepMilliseconds) {
        Write-Host "`nTest avec délai fixe de $sleepMs ms:" -ForegroundColor Yellow
        
        $fixedDelayResults = @{
            SleepType = "Fixe"
            SleepMilliseconds = $sleepMs
            RunspaceCount = $RunspaceCount
            TotalTime = 0
            AverageCPU = 0
            MaximumCPU = 0
            Iterations = $Iterations
        }
        
        $adaptiveDelayResults = @{
            SleepType = "Adaptatif"
            SleepMilliseconds = $sleepMs
            RunspaceCount = $RunspaceCount
            TotalTime = 0
            AverageCPU = 0
            MaximumCPU = 0
            Iterations = $Iterations
        }
        
        for ($iter = 1; $iter -le $Iterations; $iter++) {
            Write-Host "  Itération $iter/$Iterations..." -ForegroundColor Gray
            
            # Test avec délai fixe (implémentation originale)
            Write-Host "    Test avec délai fixe..." -ForegroundColor Cyan
            $fixedDelayTest = Measure-CPUUsage -ScriptBlock {
                # Créer des runspaces de test
                $testData = New-TestRunspaces -Count $using:RunspaceCount
                $runspaces = $testData.Runspaces
                $pool = $testData.Pool
                
                # Exécuter l'implémentation originale avec délai fixe
                $completedRunspaces = Wait-ForCompletedRunspaceOriginal -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 60 -SleepMilliseconds $using:sleepMs
                
                # Nettoyer
                $pool.Close()
                $pool.Dispose()
                
                return @{
                    ElapsedTime = $completedRunspaces.ElapsedTime
                    CompletedCount = $completedRunspaces.Count
                }
            }
            
            # Test avec délai adaptatif (implémentation optimisée)
            Write-Host "    Test avec délai adaptatif..." -ForegroundColor Cyan
            $adaptiveDelayTest = Measure-CPUUsage -ScriptBlock {
                # Créer des runspaces de test
                $testData = New-TestRunspaces -Count $using:RunspaceCount
                $runspaces = $testData.Runspaces
                $pool = $testData.Pool
                
                # Exécuter l'implémentation optimisée avec délai adaptatif
                $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 60 -SleepMilliseconds $using:sleepMs
                
                # Nettoyer
                $pool.Close()
                $pool.Dispose()
                
                return @{
                    ElapsedTime = $completedRunspaces.ElapsedTime
                    CompletedCount = $completedRunspaces.Count
                }
            }
            
            # Ajouter les résultats
            $fixedDelayResults.TotalTime += $fixedDelayTest.Result.ElapsedTime
            $fixedDelayResults.AverageCPU += $fixedDelayTest.AverageCPU
            $fixedDelayResults.MaximumCPU = [Math]::Max($fixedDelayResults.MaximumCPU, $fixedDelayTest.MaximumCPU)
            
            $adaptiveDelayResults.TotalTime += $adaptiveDelayTest.Result.ElapsedTime
            $adaptiveDelayResults.AverageCPU += $adaptiveDelayTest.AverageCPU
            $adaptiveDelayResults.MaximumCPU = [Math]::Max($adaptiveDelayResults.MaximumCPU, $adaptiveDelayTest.MaximumCPU)
            
            # Afficher les résultats de l'itération
            Write-Host "    Délai fixe - CPU moyen: $([Math]::Round($fixedDelayTest.AverageCPU, 2))%, CPU max: $([Math]::Round($fixedDelayTest.MaximumCPU, 2))%" -ForegroundColor Yellow
            Write-Host "    Délai adaptatif - CPU moyen: $([Math]::Round($adaptiveDelayTest.AverageCPU, 2))%, CPU max: $([Math]::Round($adaptiveDelayTest.MaximumCPU, 2))%" -ForegroundColor Cyan
        }
        
        # Calculer les moyennes
        $fixedDelayResults.TotalTime = $fixedDelayResults.TotalTime / $Iterations
        $fixedDelayResults.AverageCPU = $fixedDelayResults.AverageCPU / $Iterations
        
        $adaptiveDelayResults.TotalTime = $adaptiveDelayResults.TotalTime / $Iterations
        $adaptiveDelayResults.AverageCPU = $adaptiveDelayResults.AverageCPU / $Iterations
        
        # Calculer l'amélioration
        $cpuImprovement = (($fixedDelayResults.AverageCPU - $adaptiveDelayResults.AverageCPU) / $fixedDelayResults.AverageCPU) * 100
        
        # Ajouter aux résultats
        $results += [PSCustomObject]@{
            SleepMilliseconds = $sleepMs
            RunspaceCount = $RunspaceCount
            FixedDelay = [PSCustomObject]$fixedDelayResults
            AdaptiveDelay = [PSCustomObject]$adaptiveDelayResults
            CPUImprovement = $cpuImprovement
        }
        
        # Afficher les résultats
        Write-Host "`n  Résultats pour délai de $sleepMs ms:" -ForegroundColor Green
        Write-Host "    Délai fixe - CPU moyen: $([Math]::Round($fixedDelayResults.AverageCPU, 2))%, CPU max: $([Math]::Round($fixedDelayResults.MaximumCPU, 2))%" -ForegroundColor Yellow
        Write-Host "    Délai adaptatif - CPU moyen: $([Math]::Round($adaptiveDelayResults.AverageCPU, 2))%, CPU max: $([Math]::Round($adaptiveDelayResults.MaximumCPU, 2))%" -ForegroundColor Cyan
        Write-Host "    Amélioration CPU: $([Math]::Round($cpuImprovement, 2))%" -ForegroundColor $(if ($cpuImprovement -gt 0) { "Green" } else { "Red" })
    }
    
    return $results
}

# Exécuter les tests
Write-Host "Test de l'impact du délai adaptatif sur l'utilisation CPU" -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor Yellow

# Exécuter les tests avec différents délais
$results = Test-AdaptiveSleepCPUImpact -RunspaceCount 50 -Iterations 3 -SleepMilliseconds @(10, 50, 100)

# Afficher le résumé des résultats
Write-Host "`nRésumé des tests d'impact CPU:" -ForegroundColor Yellow
$summary = $results | ForEach-Object {
    [PSCustomObject]@{
        "Délai (ms)" = $_.SleepMilliseconds
        "CPU Fixe (%)" = [Math]::Round($_.FixedDelay.AverageCPU, 2)
        "CPU Adaptatif (%)" = [Math]::Round($_.AdaptiveDelay.AverageCPU, 2)
        "Amélioration (%)" = [Math]::Round($_.CPUImprovement, 2)
        "CPU Max Fixe (%)" = [Math]::Round($_.FixedDelay.MaximumCPU, 2)
        "CPU Max Adaptatif (%)" = [Math]::Round($_.AdaptiveDelay.MaximumCPU, 2)
    }
}
$summary | Format-Table -AutoSize

# Identifier le délai optimal pour l'utilisation CPU
$optimalDelay = $results | Sort-Object CPUImprovement -Descending | Select-Object -First 1

Write-Host "`nDélai optimal pour l'utilisation CPU:" -ForegroundColor Yellow
Write-Host "  Délai: $($optimalDelay.SleepMilliseconds) ms (Amélioration CPU: $([Math]::Round($optimalDelay.CPUImprovement, 2))%)" -ForegroundColor Green

# Sauvegarder les résultats dans un fichier CSV
$csvPath = Join-Path -Path $PSScriptRoot -ChildPath "AdaptiveSleep-CPUImpact-Results.csv"
$summary | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

Write-Host "`nRésultats sauvegardés dans $csvPath" -ForegroundColor Green

# Nettoyer
Clear-UnifiedParallel -Verbose

Write-Host "`nTests terminés." -ForegroundColor Green
