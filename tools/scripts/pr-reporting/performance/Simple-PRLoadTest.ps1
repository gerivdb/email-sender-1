#Requires -Version 5.1
<#
.SYNOPSIS
    Version simplifiée du script de test de charge pour les fonctions PowerShell.
.DESCRIPTION
    Ce script exécute des tests de charge simplifiés pour simuler l'utilisation
    de fonctions PowerShell sous charge.
.PARAMETER Duration
    Durée du test en secondes.
.PARAMETER Concurrency
    Nombre d'exécutions concurrentes.
.PARAMETER OutputPath
    Chemin du fichier de sortie pour les résultats du test.
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

# Fonction pour générer des données de test
function New-TestData {
    # Générer des données aléatoires
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

    # Simuler un délai
    Start-Sleep -Milliseconds (Get-Random -Minimum 50 -Maximum 200)

    return $result
}

# Fonction pour exécuter un test de stabilité
function Start-StabilityTest {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [int]$Duration,
        [int]$Concurrency,
        [int]$SamplingInterval,
        [string]$OutputPath
    )

    Write-Host "`nDémarrage du test de stabilité..." -ForegroundColor Cyan
    Write-Host "  Durée totale: $Duration secondes"
    Write-Host "  Concurrence: $Concurrency exécutions simultanées"
    Write-Host "  Intervalle d'échantillonnage: $SamplingInterval secondes"

    $startTime = Get-Date
    $endTime = $startTime.AddSeconds($Duration)
    $nextSampleTime = $startTime.AddSeconds($SamplingInterval)

    $samples = @()
    $iteration = 1

    while ((Get-Date) -lt $endTime) {
        Write-Host "Exécution de l'échantillon $iteration..." -ForegroundColor Yellow

        # Exécuter un test de charge court pour cet échantillon
        $sampleOutputPath = "$($OutputPath.TrimEnd('.json'))_sample_$iteration.json"
        $sampleDuration = [Math]::Min($SamplingInterval * 0.8, 5) # 80% de l'intervalle ou max 5 secondes

        # Utiliser la fonction Main pour exécuter un test de charge
        $sampleResults = Main -Duration $sampleDuration -Concurrency $Concurrency -OutputPath $sampleOutputPath

        # Ajouter les résultats de l'échantillon
        $samples += [PSCustomObject]@{
            Iteration         = $iteration
            Timestamp         = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            RequestsPerSecond = $sampleResults.RequestsPerSecond
            AvgResponseMs     = $sampleResults.AvgResponseMs
            P95ResponseMs     = $sampleResults.P95ResponseMs
            ErrorRate         = if ($sampleResults.TotalRequests -gt 0) { $sampleResults.ErrorCount / $sampleResults.TotalRequests * 100 } else { 0 }
        }

        # Attendre jusqu'au prochain échantillon
        $now = Get-Date
        if ($now -lt $nextSampleTime) {
            $waitTime = ($nextSampleTime - $now).TotalSeconds
            if ($waitTime -gt 0) {
                Write-Host "Attente de $([Math]::Round($waitTime, 1)) secondes jusqu'au prochain échantillon..." -ForegroundColor Gray
                Start-Sleep -Seconds ([Math]::Floor($waitTime))
            }
        }

        $iteration++
        $nextSampleTime = $nextSampleTime.AddSeconds($SamplingInterval)
    }

    # Analyser les résultats de stabilité
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

    # Enregistrer les résultats
    $stabilityResults | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8

    # Afficher un résumé
    Write-Host "`nRésumé du test de stabilité:" -ForegroundColor Cyan
    Write-Host "==========================" -ForegroundColor Cyan
    Write-Host "Durée totale: $Duration secondes"
    Write-Host "Nombre d'échantillons: $($samples.Count)"
    Write-Host "`nPerformances moyennes:" -ForegroundColor Yellow
    Write-Host "  Requêtes par seconde: $([Math]::Round($stabilityResults.Summary.AvgRequestsPerSecond, 2))"
    Write-Host "  Temps de réponse moyen: $([Math]::Round($stabilityResults.Summary.AvgResponseTime, 2)) ms"
    Write-Host "  P95 moyen: $([Math]::Round($stabilityResults.Summary.AvgP95ResponseTime, 2)) ms"
    Write-Host "  Taux d'erreur moyen: $([Math]::Round($stabilityResults.Summary.AvgErrorRate, 2))%"

    Write-Host "`nStabilité:" -ForegroundColor Yellow
    Write-Host "  Min RPS: $([Math]::Round($stabilityResults.Summary.MinRequestsPerSecond, 2))"
    Write-Host "  Max RPS: $([Math]::Round($stabilityResults.Summary.MaxRequestsPerSecond, 2))"
    Write-Host "  Écart type RPS: $([Math]::Round($stabilityResults.Summary.StdDevRequestsPerSecond, 2))"
    Write-Host "  Coefficient de variation: $([Math]::Round($stabilityResults.Summary.StdDevRequestsPerSecond / $stabilityResults.Summary.AvgRequestsPerSecond * 100, 2))%"

    return $stabilityResults
}

# Fonction principale
function Main {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    if ($StabilityTest) {
        Write-Verbose "Démarrage du test de stabilité..."
        Write-Verbose "  Durée: $StabilityDuration secondes"
        Write-Verbose "  Concurrence: $Concurrency exécutions simultanées"
        Write-Verbose "  Intervalle d'échantillonnage: $SamplingInterval secondes"

        return Start-StabilityTest -Duration $StabilityDuration -Concurrency $Concurrency -SamplingInterval $SamplingInterval -OutputPath $OutputPath
    } else {
        Write-Verbose "Démarrage du test de charge simplifié..."
        Write-Verbose "  Durée: $Duration secondes"
        Write-Verbose "  Concurrence: $Concurrency exécutions simultanées"

        # Vérifier que le répertoire de sortie existe
        $outputDir = Split-Path -Path $OutputPath -Parent
        if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path -Path $outputDir)) {
            if ($PSCmdlet.ShouldProcess($outputDir, "Créer le répertoire")) {
                New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
            }
        }

        # Générer les données de test
        $testData = New-TestData
        Write-Verbose "Données de test générées"

        # Initialiser les résultats
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

        # Démarrer la surveillance des performances
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

        # Démarrer le test de charge
        $startTime = Get-Date
        $endTime = $startTime.AddSeconds($Duration)
        $responseTimes = @()
        $jobs = @()

        Write-Verbose "Exécution du test de charge jusqu'à $(Get-Date -Date $endTime -Format "HH:mm:ss")..."

        while ((Get-Date) -lt $endTime) {
            # Vérifier le nombre de jobs en cours
            $runningJobs = $jobs | Where-Object { $_.State -eq "Running" }

            # Démarrer de nouveaux jobs si nécessaire
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

                        # Simuler un délai
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

            # Vérifier les jobs terminés
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

                # Marquer le job comme traité
                $jobInfo | Add-Member -MemberType NoteProperty -Name "Processed" -Value $true -Force
            }

            # Attendre un peu avant de vérifier à nouveau
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

        # Récupérer les données de performance
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

        # Ajouter des informations système
        $results.System = @{
            PSVersion      = $PSVersionTable.PSVersion.ToString()
            OS             = [System.Environment]::OSVersion.VersionString
            ProcessorCount = [System.Environment]::ProcessorCount
            Memory         = [Math]::Round((Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
        }

        # Enregistrer les résultats
        if ($PSCmdlet.ShouldProcess($OutputPath, "Enregistrer les résultats du test de charge")) {
            $results | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
            Write-Verbose "Résultats du test de charge enregistrés dans $OutputPath"
        }

        # Afficher un résumé
        Write-Host "`nRésumé du test de charge:" -ForegroundColor Cyan
        Write-Host "=========================" -ForegroundColor Cyan

        Write-Host "`nMétriques générales:" -ForegroundColor Yellow
        Write-Host "  Durée totale: $($results.TotalExecTime) secondes"
        Write-Host "  Requêtes totales: $($results.TotalRequests)"
        Write-Host "  Requêtes réussies: $($results.SuccessCount)"
        Write-Host "  Requêtes en erreur: $($results.ErrorCount)"
        Write-Host "  Requêtes par seconde: $([Math]::Round($results.RequestsPerSecond, 2))"

        Write-Host "`nTemps de réponse:" -ForegroundColor Yellow
        Write-Host "  Minimum: $([Math]::Round($results.MinResponseMs, 2)) ms"
        Write-Host "  Maximum: $([Math]::Round($results.MaxResponseMs, 2)) ms"
        Write-Host "  Moyenne: $([Math]::Round($results.AvgResponseMs, 2)) ms"
        Write-Host "  Médiane: $([Math]::Round($results.MedianResponseMs, 2)) ms"
        Write-Host "  Écart type: $([Math]::Round($results.StandardDeviation, 2)) ms"

        Write-Host "`nPercentiles:" -ForegroundColor Yellow
        Write-Host "  P90: $([Math]::Round($results.P90ResponseMs, 2)) ms"
        Write-Host "  P95: $([Math]::Round($results.P95ResponseMs, 2)) ms"
        Write-Host "  P99: $([Math]::Round($results.P99ResponseMs, 2)) ms"

        return $results
    }

}

# Exécuter le script
Main
