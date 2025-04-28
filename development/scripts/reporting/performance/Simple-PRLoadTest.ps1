#Requires -Version 5.1
<#
.SYNOPSIS
    Version simplifiÃ©e du script de test de charge pour les fonctions PowerShell.
.DESCRIPTION
    Ce script exÃ©cute des tests de charge simplifiÃ©s pour simuler l'utilisation
    de fonctions PowerShell sous charge.
.PARAMETER Duration
    DurÃ©e du test en secondes.
.PARAMETER Concurrency
    Nombre d'exÃ©cutions concurrentes.
.PARAMETER OutputPath
    Chemin du fichier de sortie pour les rÃ©sultats du test.
.EXAMPLE
    .\Simple-PRLoadTest.ps1 -Duration 10 -Concurrency 2 -OutputPath "load_test_results.json"
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [int]$Duration = 10,

    [Parameter(Mandatory = $false)]
    [int]$Concurrency = 2,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [switch]$StabilityTest,

    [Parameter(Mandatory = $false)]
    [int]$StabilityDuration = 60,

    [Parameter(Mandatory = $false)]
    [int]$SamplingInterval = 5
)

# Fonction pour gÃ©nÃ©rer des donnÃ©es de test
function New-TestData {
    # GÃ©nÃ©rer des donnÃ©es alÃ©atoires
    $data = @{
        Labels     = @("Label1", "Label2", "Label3", "Label4", "Label5")
        Values     = @(
            (Get-Random -Minimum 1 -Maximum 100),
            (Get-Random -Minimum 1 -Maximum 100),
            (Get-Random -Minimum 1 -Maximum 100),
            (Get-Random -Minimum 1 -Maximum 100),
            (Get-Random -Minimum 1 -Maximum 100)
        )
        Categories = @("Category1", "Category2", "Category3", "Category4", "Category5")
    }

    return $data
}

# Fonction pour surveiller les performances
function Get-ProcessPerformance {
    param (
        [int]$ProcessId,
        [int]$Duration,
        [int]$Interval = 1
    )

    $startTime = Get-Date
    $endTime = $startTime.AddSeconds($Duration)
    $performance = @()

    while ((Get-Date) -lt $endTime) {
        $process = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
        if ($process) {
            $performance += [PSCustomObject]@{
                Timestamp     = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
                CPU           = $process.CPU
                WorkingSet    = $process.WorkingSet64
                PrivateMemory = $process.PrivateMemorySize64
                Handles       = $process.HandleCount
                Threads       = $process.Threads.Count
            }
        }

        Start-Sleep -Seconds $Interval
    }

    return $performance
}

# Fonction pour simuler une charge
function Invoke-DummyFunction {
    param (
        [object]$Data
    )

    # Simuler un traitement
    $result = @{
        ProcessedLabels = $Data.Labels
        ProcessedValues = $Data.Values | ForEach-Object { $_ * 2 }
        Summary         = "Processed $($Data.Labels.Count) items"
    }

    # Simuler un dÃ©lai
    Start-Sleep -Milliseconds (Get-Random -Minimum 50 -Maximum 200)

    return $result
}

# Fonction pour exÃ©cuter un test de stabilitÃ©
function Start-StabilityTest {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [int]$Duration,
        [int]$Concurrency,
        [int]$SamplingInterval,
        [string]$OutputPath
    )

    Write-Host "`nDÃ©marrage du test de stabilitÃ©..." -ForegroundColor Cyan
    Write-Host "  DurÃ©e totale: $Duration secondes"
    Write-Host "  Concurrence: $Concurrency exÃ©cutions simultanÃ©es"
    Write-Host "  Intervalle d'Ã©chantillonnage: $SamplingInterval secondes"

    $startTime = Get-Date
    $endTime = $startTime.AddSeconds($Duration)
    $nextSampleTime = $startTime.AddSeconds($SamplingInterval)

    $samples = @()
    $iteration = 1

    while ((Get-Date) -lt $endTime) {
        Write-Host "ExÃ©cution de l'Ã©chantillon $iteration..." -ForegroundColor Yellow

        # ExÃ©cuter un test de charge court pour cet Ã©chantillon
        $sampleOutputPath = "$($OutputPath.TrimEnd('.json'))_sample_$iteration.json"
        $sampleDuration = [Math]::Min($SamplingInterval * 0.8, 5) # 80% de l'intervalle ou max 5 secondes

        # Utiliser la fonction Main pour exÃ©cuter un test de charge
        $sampleResults = Main -Duration $sampleDuration -Concurrency $Concurrency -OutputPath $sampleOutputPath

        # Ajouter les rÃ©sultats de l'Ã©chantillon
        $samples += [PSCustomObject]@{
            Iteration         = $iteration
            Timestamp         = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            RequestsPerSecond = $sampleResults.RequestsPerSecond
            AvgResponseMs     = $sampleResults.AvgResponseMs
            P95ResponseMs     = $sampleResults.P95ResponseMs
            ErrorRate         = if ($sampleResults.TotalRequests -gt 0) { $sampleResults.ErrorCount / $sampleResults.TotalRequests * 100 } else { 0 }
        }

        # Attendre jusqu'au prochain Ã©chantillon
        $now = Get-Date
        if ($now -lt $nextSampleTime) {
            $waitTime = ($nextSampleTime - $now).TotalSeconds
            if ($waitTime -gt 0) {
                Write-Host "Attente de $([Math]::Round($waitTime, 1)) secondes jusqu'au prochain Ã©chantillon..." -ForegroundColor Gray
                Start-Sleep -Seconds ([Math]::Floor($waitTime))
            }
        }

        $iteration++
        $nextSampleTime = $nextSampleTime.AddSeconds($SamplingInterval)
    }

    # Analyser les rÃ©sultats de stabilitÃ©
    $stabilityResults = @{
        StartTime        = $startTime.ToString("yyyy-MM-dd HH:mm:ss")
        EndTime          = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Duration         = $Duration
        SamplingInterval = $SamplingInterval
        SampleCount      = $samples.Count
        Samples          = $samples
        Summary          = @{
            AvgRequestsPerSecond    = ($samples | Measure-Object -Property RequestsPerSecond -Average).Average
            MinRequestsPerSecond    = ($samples | Measure-Object -Property RequestsPerSecond -Minimum).Minimum
            MaxRequestsPerSecond    = ($samples | Measure-Object -Property RequestsPerSecond -Maximum).Maximum
            StdDevRequestsPerSecond = [Math]::Sqrt(($samples | ForEach-Object { [Math]::Pow($_.RequestsPerSecond - (($samples | Measure-Object -Property RequestsPerSecond -Average).Average), 2) } | Measure-Object -Average).Average)
            AvgResponseTime         = ($samples | Measure-Object -Property AvgResponseMs -Average).Average
            AvgP95ResponseTime      = ($samples | Measure-Object -Property P95ResponseMs -Average).Average
            AvgErrorRate            = ($samples | Measure-Object -Property ErrorRate -Average).Average
        }
    }

    # Enregistrer les rÃ©sultats
    $stabilityResults | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8

    # Afficher un rÃ©sumÃ©
    Write-Host "`nRÃ©sumÃ© du test de stabilitÃ©:" -ForegroundColor Cyan
    Write-Host "==========================" -ForegroundColor Cyan
    Write-Host "DurÃ©e totale: $Duration secondes"
    Write-Host "Nombre d'Ã©chantillons: $($samples.Count)"
    Write-Host "`nPerformances moyennes:" -ForegroundColor Yellow
    Write-Host "  RequÃªtes par seconde: $([Math]::Round($stabilityResults.Summary.AvgRequestsPerSecond, 2))"
    Write-Host "  Temps de rÃ©ponse moyen: $([Math]::Round($stabilityResults.Summary.AvgResponseTime, 2)) ms"
    Write-Host "  P95 moyen: $([Math]::Round($stabilityResults.Summary.AvgP95ResponseTime, 2)) ms"
    Write-Host "  Taux d'erreur moyen: $([Math]::Round($stabilityResults.Summary.AvgErrorRate, 2))%"

    Write-Host "`nStabilitÃ©:" -ForegroundColor Yellow
    Write-Host "  Min RPS: $([Math]::Round($stabilityResults.Summary.MinRequestsPerSecond, 2))"
    Write-Host "  Max RPS: $([Math]::Round($stabilityResults.Summary.MaxRequestsPerSecond, 2))"
    Write-Host "  Ã‰cart type RPS: $([Math]::Round($stabilityResults.Summary.StdDevRequestsPerSecond, 2))"
    Write-Host "  Coefficient de variation: $([Math]::Round($stabilityResults.Summary.StdDevRequestsPerSecond / $stabilityResults.Summary.AvgRequestsPerSecond * 100, 2))%"

    return $stabilityResults
}

# Fonction principale
function Main {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    if ($StabilityTest) {
        Write-Verbose "DÃ©marrage du test de stabilitÃ©..."
        Write-Verbose "  DurÃ©e: $StabilityDuration secondes"
        Write-Verbose "  Concurrence: $Concurrency exÃ©cutions simultanÃ©es"
        Write-Verbose "  Intervalle d'Ã©chantillonnage: $SamplingInterval secondes"

        return Start-StabilityTest -Duration $StabilityDuration -Concurrency $Concurrency -SamplingInterval $SamplingInterval -OutputPath $OutputPath
    } else {
        Write-Verbose "DÃ©marrage du test de charge simplifiÃ©..."
        Write-Verbose "  DurÃ©e: $Duration secondes"
        Write-Verbose "  Concurrence: $Concurrency exÃ©cutions simultanÃ©es"

        # VÃ©rifier que le rÃ©pertoire de sortie existe
        $outputDir = Split-Path -Path $OutputPath -Parent
        if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path -Path $outputDir)) {
            if ($PSCmdlet.ShouldProcess($outputDir, "CrÃ©er le rÃ©pertoire")) {
                New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
            }
        }

        # GÃ©nÃ©rer les donnÃ©es de test
        $testData = New-TestData
        Write-Verbose "DonnÃ©es de test gÃ©nÃ©rÃ©es"

        # Initialiser les rÃ©sultats
        $results = @{
            StartTime     = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Duration      = $Duration
            Concurrency   = $Concurrency
            TotalRequests = 0
            SuccessCount  = 0
            ErrorCount    = 0
            AvgResponseMs = 0
            MinResponseMs = [double]::MaxValue
            MaxResponseMs = 0
            TotalExecTime = 0
            Performance   = @()
        }

        # DÃ©marrer la surveillance des performances
        $processId = $PID  # Stocker la valeur de $PID dans une variable normale
        $monitorJob = Start-Job -ScriptBlock {
            param ($ProcessId, $Duration, $Interval)

            $startTime = Get-Date
            $endTime = $startTime.AddSeconds($Duration)
            $performance = @()

            while ((Get-Date) -lt $endTime) {
                $process = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
                if ($process) {
                    $performance += [PSCustomObject]@{
                        Timestamp     = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
                        CPU           = $process.CPU
                        WorkingSet    = $process.WorkingSet64
                        PrivateMemory = $process.PrivateMemorySize64
                        Handles       = $process.HandleCount
                        Threads       = $process.Threads.Count
                    }
                }

                Start-Sleep -Seconds $Interval
            }

            return $performance
        } -ArgumentList $processId, $Duration, 1

        # DÃ©marrer le test de charge
        $startTime = Get-Date
        $endTime = $startTime.AddSeconds($Duration)
        $responseTimes = @()
        $jobs = @()

        Write-Verbose "ExÃ©cution du test de charge jusqu'Ã  $(Get-Date -Date $endTime -Format "HH:mm:ss")..."

        while ((Get-Date) -lt $endTime) {
            # VÃ©rifier le nombre de jobs en cours
            $runningJobs = $jobs | Where-Object { $_.State -eq "Running" }

            # DÃ©marrer de nouveaux jobs si nÃ©cessaire
            while ($runningJobs.Count -lt $Concurrency -and (Get-Date) -lt $endTime) {
                $jobStartTime = Get-Date
                $job = Start-Job -ScriptBlock {
                    param ($TestData)

                    try {
                        # Simuler une fonction
                        $result = @{
                            ProcessedLabels = $TestData.Labels
                            ProcessedValues = $TestData.Values | ForEach-Object { $_ * 2 }
                            Summary         = "Processed $($TestData.Labels.Count) items"
                        }

                        # Simuler un dÃ©lai
                        Start-Sleep -Milliseconds (Get-Random -Minimum 50 -Maximum 200)

                        return @{
                            Success = $true
                            Result  = $result
                        }
                    } catch {
                        return @{
                            Success = $false
                            Error   = $_.Exception.Message
                        }
                    }
                } -ArgumentList $testData

                $jobs += [PSCustomObject]@{
                    Job       = $job
                    StartTime = $jobStartTime
                }

                $runningJobs = $jobs | Where-Object { $_.Job.State -eq "Running" }
            }

            # VÃ©rifier les jobs terminÃ©s
            $completedJobs = $jobs | Where-Object { $_.Job.State -eq "Completed" -and -not $_.Processed }

            foreach ($jobInfo in $completedJobs) {
                $jobResult = Receive-Job -Job $jobInfo.Job
                $endTime = Get-Date
                $responseTime = ($endTime - $jobInfo.StartTime).TotalMilliseconds

                $results.TotalRequests++
                $responseTimes += $responseTime

                if ($jobResult.Success) {
                    $results.SuccessCount++
                } else {
                    $results.ErrorCount++
                }

                if ($responseTime -lt $results.MinResponseMs) {
                    $results.MinResponseMs = $responseTime
                }

                if ($responseTime -gt $results.MaxResponseMs) {
                    $results.MaxResponseMs = $responseTime
                }

                # Marquer le job comme traitÃ©
                $jobInfo | Add-Member -MemberType NoteProperty -Name "Processed" -Value $true -Force
            }

            # Attendre un peu avant de vÃ©rifier Ã  nouveau
            Start-Sleep -Milliseconds 100
        }

        # Attendre que tous les jobs se terminent
        $remainingJobs = $jobs | Where-Object { -not $_.Processed }
        foreach ($jobInfo in $remainingJobs) {
            $jobResult = Receive-Job -Job $jobInfo.Job -Wait
            $endTime = Get-Date
            $responseTime = ($endTime - $jobInfo.StartTime).TotalMilliseconds

            $results.TotalRequests++
            $responseTimes += $responseTime

            if ($jobResult.Success) {
                $results.SuccessCount++
            } else {
                $results.ErrorCount++
            }

            if ($responseTime -lt $results.MinResponseMs) {
                $results.MinResponseMs = $responseTime
            }

            if ($responseTime -gt $results.MaxResponseMs) {
                $results.MaxResponseMs = $responseTime
            }
        }

        # Nettoyer les jobs
        $jobs | ForEach-Object { Remove-Job -Job $_.Job -Force }

        # RÃ©cupÃ©rer les donnÃ©es de performance
        $results.Performance = Receive-Job -Job $monitorJob -Wait
        Remove-Job -Job $monitorJob -Force

        # Calculer les statistiques
        if ($responseTimes.Count -gt 0) {
            $responseStats = $responseTimes | Measure-Object -Average -Maximum -Minimum -Sum
            $results.AvgResponseMs = $responseStats.Average
            $results.MedianResponseMs = ($responseTimes | Sort-Object)[[Math]::Floor($responseTimes.Count / 2)]
            $results.TotalExecTime = ($endTime - $startTime).TotalSeconds
            $results.RequestsPerSecond = $results.TotalRequests / $results.TotalExecTime
            $results.P90ResponseMs = ($responseTimes | Sort-Object)[[Math]::Floor($responseTimes.Count * 0.9)]
            $results.P95ResponseMs = ($responseTimes | Sort-Object)[[Math]::Floor($responseTimes.Count * 0.95)]
            $results.P99ResponseMs = ($responseTimes | Sort-Object)[[Math]::Floor($responseTimes.Count * 0.99)]
            $results.StandardDeviation = [Math]::Sqrt(($responseTimes | ForEach-Object { [Math]::Pow($_ - $results.AvgResponseMs, 2) } | Measure-Object -Average).Average)
        }

        # Ajouter des informations systÃ¨me
        $results.System = @{
            PSVersion      = $PSVersionTable.PSVersion.ToString()
            OS             = [System.Environment]::OSVersion.VersionString
            ProcessorCount = [System.Environment]::ProcessorCount
            Memory         = [Math]::Round((Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
        }

        # Enregistrer les rÃ©sultats
        if ($PSCmdlet.ShouldProcess($OutputPath, "Enregistrer les rÃ©sultats du test de charge")) {
            $results | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
            Write-Verbose "RÃ©sultats du test de charge enregistrÃ©s dans $OutputPath"
        }

        # Afficher un rÃ©sumÃ©
        Write-Host "`nRÃ©sumÃ© du test de charge:" -ForegroundColor Cyan
        Write-Host "=========================" -ForegroundColor Cyan

        Write-Host "`nMÃ©triques gÃ©nÃ©rales:" -ForegroundColor Yellow
        Write-Host "  DurÃ©e totale: $($results.TotalExecTime) secondes"
        Write-Host "  RequÃªtes totales: $($results.TotalRequests)"
        Write-Host "  RequÃªtes rÃ©ussies: $($results.SuccessCount)"
        Write-Host "  RequÃªtes en erreur: $($results.ErrorCount)"
        Write-Host "  RequÃªtes par seconde: $([Math]::Round($results.RequestsPerSecond, 2))"

        Write-Host "`nTemps de rÃ©ponse:" -ForegroundColor Yellow
        Write-Host "  Minimum: $([Math]::Round($results.MinResponseMs, 2)) ms"
        Write-Host "  Maximum: $([Math]::Round($results.MaxResponseMs, 2)) ms"
        Write-Host "  Moyenne: $([Math]::Round($results.AvgResponseMs, 2)) ms"
        Write-Host "  MÃ©diane: $([Math]::Round($results.MedianResponseMs, 2)) ms"
        Write-Host "  Ã‰cart type: $([Math]::Round($results.StandardDeviation, 2)) ms"

        Write-Host "`nPercentiles:" -ForegroundColor Yellow
        Write-Host "  P90: $([Math]::Round($results.P90ResponseMs, 2)) ms"
        Write-Host "  P95: $([Math]::Round($results.P95ResponseMs, 2)) ms"
        Write-Host "  P99: $([Math]::Round($results.P99ResponseMs, 2)) ms"

        return $results
    }

}

# ExÃ©cuter le script
Main
