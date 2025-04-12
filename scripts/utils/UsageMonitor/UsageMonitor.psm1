#Requires -Version 5.1

<#
.SYNOPSIS
    Module de monitoring et d'analyse comportementale pour les scripts PowerShell.
.DESCRIPTION
    Ce module fournit des fonctionnalités pour collecter, stocker et analyser des métriques
    d'utilisation des scripts PowerShell, permettant une optimisation proactive basée sur l'usage.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-05-15
    Compatibilité: PowerShell 5.1 et supérieur
#>

# Définition des classes
class UsageMetric {
    [string]$ScriptPath
    [string]$ScriptName
    [string]$Function
    [datetime]$StartTime
    [datetime]$EndTime
    [timespan]$Duration
    [bool]$Success
    [string]$ErrorMessage
    [hashtable]$ResourceUsage
    [hashtable]$Parameters
    [guid]$ExecutionId

    UsageMetric([string]$scriptPath) {
        $this.ScriptPath = $scriptPath
        $this.ScriptName = Split-Path -Path $scriptPath -Leaf
        $this.StartTime = Get-Date
        $this.ExecutionId = [guid]::NewGuid()
        $this.ResourceUsage = @{
            CpuUsageStart    = $null
            MemoryUsageStart = $null
            CpuUsageEnd      = $null
            MemoryUsageEnd   = $null
        }
    }

    [void] Complete([bool]$success, [string]$errorMessage = "") {
        $this.EndTime = Get-Date
        $this.Duration = $this.EndTime - $this.StartTime
        $this.Success = $success
        $this.ErrorMessage = $errorMessage
    }

    [void] SetFunction([string]$function) {
        $this.Function = $function
    }

    [void] SetParameters([hashtable]$parameters) {
        $this.Parameters = $parameters
    }

    [void] CaptureResourceUsageStart() {
        $processId = [System.Diagnostics.Process]::GetCurrentProcess().Id
        $process = Get-Process -Id $processId
        $this.ResourceUsage.CpuUsageStart = $process.CPU
        $this.ResourceUsage.MemoryUsageStart = $process.WorkingSet64
    }

    [void] CaptureResourceUsageEnd() {
        $processId = [System.Diagnostics.Process]::GetCurrentProcess().Id
        $process = Get-Process -Id $processId
        $this.ResourceUsage.CpuUsageEnd = $process.CPU
        $this.ResourceUsage.MemoryUsageEnd = $process.WorkingSet64
    }
}

class UsageDatabase {
    [string]$DatabasePath
    [System.Collections.Concurrent.ConcurrentDictionary[string, System.Collections.ArrayList]]$InMemoryData

    UsageDatabase([string]$databasePath) {
        $this.DatabasePath = $databasePath
        $this.InMemoryData = [System.Collections.Concurrent.ConcurrentDictionary[string, System.Collections.ArrayList]]::new()

        # Créer le répertoire de la base de données s'il n'existe pas
        $dbDir = Split-Path -Path $databasePath -Parent
        if (-not (Test-Path -Path $dbDir -PathType Container)) {
            New-Item -Path $dbDir -ItemType Directory -Force | Out-Null
        }

        # Charger les données existantes si le fichier existe
        if (Test-Path -Path $databasePath -PathType Leaf) {
            try {
                $data = Import-Clixml -Path $databasePath -ErrorAction Stop
                foreach ($key in $data.Keys) {
                    $list = [System.Collections.ArrayList]::new()
                    foreach ($item in $data[$key]) {
                        $list.Add($item) | Out-Null
                    }
                    $this.InMemoryData[$key] = $list
                }
            } catch {
                Write-Warning "Impossible de charger la base de données d'utilisation: $_"
            }
        }
    }

    [void] AddMetric([UsageMetric]$metric) {
        $key = $metric.ScriptPath

        if (-not $this.InMemoryData.ContainsKey($key)) {
            $list = [System.Collections.ArrayList]::new()
            $this.InMemoryData[$key] = $list
        }

        $this.InMemoryData[$key].Add($metric) | Out-Null

        # Limiter le nombre d'entrées par script (garder les 100 dernières)
        if ($this.InMemoryData[$key].Count -gt 100) {
            $this.InMemoryData[$key].RemoveAt(0)
        }

        # Sauvegarder périodiquement (toutes les 10 entrées)
        if ($this.InMemoryData.Values.Count % 10 -eq 0) {
            $this.SaveToFile()
        }
    }

    [void] SaveToFile() {
        try {
            $this.InMemoryData | Export-Clixml -Path $this.DatabasePath -Force -ErrorAction Stop
        } catch {
            Write-Warning "Impossible de sauvegarder la base de données d'utilisation: $_"
        }
    }

    [System.Collections.ArrayList] GetMetricsForScript([string]$scriptPath) {
        if ($this.InMemoryData.ContainsKey($scriptPath)) {
            return $this.InMemoryData[$scriptPath]
        }
        return [System.Collections.ArrayList]::new()
    }

    [hashtable] GetTopUsedScripts([int]$count = 10) {
        $result = @{}
        $scriptCounts = @{}

        foreach ($key in $this.InMemoryData.Keys) {
            $scriptCounts[$key] = $this.InMemoryData[$key].Count
        }

        $topScripts = $scriptCounts.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First $count

        foreach ($script in $topScripts) {
            $result[$script.Key] = $script.Value
        }

        return $result
    }

    [hashtable] GetSlowestScripts([int]$count = 10) {
        $result = @{}
        $scriptAvgDurations = @{}

        foreach ($key in $this.InMemoryData.Keys) {
            $totalDuration = [timespan]::Zero
            $successfulExecutions = 0

            foreach ($metric in $this.InMemoryData[$key]) {
                if ($metric.Success) {
                    $totalDuration += $metric.Duration
                    $successfulExecutions++
                }
            }

            if ($successfulExecutions -gt 0) {
                $avgDuration = $totalDuration.TotalMilliseconds / $successfulExecutions
                $scriptAvgDurations[$key] = $avgDuration
            }
        }

        $slowestScripts = $scriptAvgDurations.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First $count

        foreach ($script in $slowestScripts) {
            $result[$script.Key] = $script.Value
        }

        return $result
    }

    [hashtable] GetMostFailingScripts([int]$count = 10) {
        $result = @{}
        $scriptFailureRates = @{}

        foreach ($key in $this.InMemoryData.Keys) {
            $totalExecutions = $this.InMemoryData[$key].Count
            $failedExecutions = 0

            foreach ($metric in $this.InMemoryData[$key]) {
                if (-not $metric.Success) {
                    $failedExecutions++
                }
            }

            if ($totalExecutions -gt 0) {
                $failureRate = ($failedExecutions / $totalExecutions) * 100
                $scriptFailureRates[$key] = $failureRate
            }
        }

        $mostFailingScripts = $scriptFailureRates.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First $count

        foreach ($script in $mostFailingScripts) {
            $result[$script.Key] = $script.Value
        }

        return $result
    }

    [hashtable] GetResourceIntensiveScripts([int]$count = 10) {
        $result = @{}
        $scriptResourceUsage = @{}

        foreach ($key in $this.InMemoryData.Keys) {
            $totalMemoryUsage = 0
            $validExecutions = 0

            foreach ($metric in $this.InMemoryData[$key]) {
                if ($metric.ResourceUsage.MemoryUsageEnd -and $metric.ResourceUsage.MemoryUsageStart) {
                    $memoryDelta = $metric.ResourceUsage.MemoryUsageEnd - $metric.ResourceUsage.MemoryUsageStart
                    $totalMemoryUsage += $memoryDelta
                    $validExecutions++
                }
            }

            if ($validExecutions -gt 0) {
                $avgMemoryUsage = $totalMemoryUsage / $validExecutions
                $scriptResourceUsage[$key] = $avgMemoryUsage
            }
        }

        $resourceIntensiveScripts = $scriptResourceUsage.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First $count

        foreach ($script in $resourceIntensiveScripts) {
            $result[$script.Key] = $script.Value
        }

        return $result
    }

    [PSCustomObject[]] AnalyzeBottlenecks() {
        $bottlenecks = [System.Collections.ArrayList]::new()

        foreach ($key in $this.InMemoryData.Keys) {
            $metrics = $this.InMemoryData[$key]

            # Ignorer les scripts avec moins de 5 exécutions
            if ($metrics.Count -lt 5) {
                continue
            }

            $durations = $metrics | Where-Object { $_.Success } | ForEach-Object { $_.Duration.TotalMilliseconds }

            if ($durations.Count -lt 5) {
                continue
            }

            # Calculer la moyenne et l'écart-type
            $avgDuration = ($durations | Measure-Object -Average).Average
            $stdDeviation = [Math]::Sqrt(($durations | ForEach-Object { [Math]::Pow($_ - $avgDuration, 2) } | Measure-Object -Average).Average)

            # Identifier les exécutions anormalement lentes (> moyenne + 2*écart-type)
            $threshold = $avgDuration + (2 * $stdDeviation)
            $slowExecutions = $metrics | Where-Object { $_.Success -and $_.Duration.TotalMilliseconds -gt $threshold }

            if ($slowExecutions.Count -gt 0) {
                $bottleneck = [PSCustomObject]@{
                    ScriptPath              = $key
                    ScriptName              = Split-Path -Path $key -Leaf
                    AverageDuration         = $avgDuration
                    SlowThreshold           = $threshold
                    SlowExecutionsCount     = $slowExecutions.Count
                    TotalExecutionsCount    = $metrics.Count
                    SlowExecutionPercentage = ($slowExecutions.Count / $metrics.Count) * 100
                    SlowExecutions          = $slowExecutions
                }

                $bottlenecks.Add($bottleneck) | Out-Null
            }
        }

        return $bottlenecks | Sort-Object -Property SlowExecutionPercentage -Descending
    }
}

# Variables globales du module
$script:UsageDatabase = $null
$script:IsInitialized = $false
$script:DefaultDatabasePath = Join-Path -Path $env:TEMP -ChildPath "UsageMonitor\usage_data.xml"
$script:ActiveMetrics = @{}

# Fonctions publiques du module
function Initialize-UsageMonitor {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$DatabasePath = $script:DefaultDatabasePath
    )

    try {
        $script:UsageDatabase = [UsageDatabase]::new($DatabasePath)
        $script:IsInitialized = $true
        Write-Verbose "UsageMonitor initialisé avec succès. Base de données: $DatabasePath"
    } catch {
        Write-Error "Impossible d'initialiser UsageMonitor: $_"
        $script:IsInitialized = $false
    }
}

function Start-ScriptUsageTracking {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,

        [Parameter(Mandatory = $false)]
        [string]$Function = "",

        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{}
    )

    if (-not $script:IsInitialized) {
        Initialize-UsageMonitor
    }

    try {
        $metric = [UsageMetric]::new($ScriptPath)
        $metric.SetFunction($Function)
        $metric.SetParameters($Parameters)
        $metric.CaptureResourceUsageStart()

        $script:ActiveMetrics[$metric.ExecutionId] = $metric

        return $metric.ExecutionId
    } catch {
        Write-Error "Erreur lors du démarrage du suivi d'utilisation: $_"
        return $null
    }
}

function Stop-ScriptUsageTracking {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [guid]$ExecutionId,

        [Parameter(Mandatory = $false)]
        [bool]$Success = $true,

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage = ""
    )

    if (-not $script:IsInitialized) {
        Write-Error "UsageMonitor n'est pas initialisé. Appelez Initialize-UsageMonitor d'abord."
        return
    }

    if (-not $script:ActiveMetrics.ContainsKey($ExecutionId)) {
        Write-Error "Aucun suivi d'utilisation trouvé pour l'ID d'exécution spécifié: $ExecutionId"
        return
    }

    try {
        $metric = $script:ActiveMetrics[$ExecutionId]
        $metric.CaptureResourceUsageEnd()
        $metric.Complete($Success, $ErrorMessage)

        $script:UsageDatabase.AddMetric($metric)
        $script:ActiveMetrics.Remove($ExecutionId)

        Write-Verbose "Suivi d'utilisation terminé pour $($metric.ScriptPath). Durée: $($metric.Duration.TotalMilliseconds) ms"
    } catch {
        Write-Error "Erreur lors de l'arrêt du suivi d'utilisation: $_"
    }
}

function Get-ScriptUsageStatistics {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ScriptPath,

        [Parameter(Mandatory = $false)]
        [int]$TopCount = 10
    )

    if (-not $script:IsInitialized) {
        Write-Error "UsageMonitor n'est pas initialisé. Appelez Initialize-UsageMonitor d'abord."
        return
    }

    if ($ScriptPath) {
        return $script:UsageDatabase.GetMetricsForScript($ScriptPath)
    } else {
        $result = [PSCustomObject]@{
            TopUsedScripts           = $script:UsageDatabase.GetTopUsedScripts($TopCount)
            SlowestScripts           = $script:UsageDatabase.GetSlowestScripts($TopCount)
            MostFailingScripts       = $script:UsageDatabase.GetMostFailingScripts($TopCount)
            ResourceIntensiveScripts = $script:UsageDatabase.GetResourceIntensiveScripts($TopCount)
        }

        return $result
    }
}

function Find-ScriptBottlenecks {
    [CmdletBinding()]
    param ()

    if (-not $script:IsInitialized) {
        Write-Error "UsageMonitor n'est pas initialisé. Appelez Initialize-UsageMonitor d'abord."
        return
    }

    return $script:UsageDatabase.AnalyzeBottlenecks()
}

function Save-UsageDatabase {
    [CmdletBinding()]
    param ()

    if (-not $script:IsInitialized) {
        Write-Error "UsageMonitor n'est pas initialisé. Appelez Initialize-UsageMonitor d'abord."
        return
    }

    $script:UsageDatabase.SaveToFile()
    Write-Verbose "Base de données d'utilisation sauvegardée avec succès."
}

# Fonctions additionnelles pour les tests
function Get-AllScriptPaths {
    [CmdletBinding()]
    param ()

    if (-not $script:IsInitialized) {
        Write-Error "UsageMonitor n'est pas initialisé. Appelez Initialize-UsageMonitor d'abord."
        return @()
    }

    return $script:UsageDatabase.InMemoryData.Keys
}

function Get-MetricsForScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath
    )

    if (-not $script:IsInitialized) {
        Write-Error "UsageMonitor n'est pas initialisé. Appelez Initialize-UsageMonitor d'abord."
        return @()
    }

    return $script:UsageDatabase.GetMetricsForScript($ScriptPath)
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Initialize-UsageMonitor, Start-ScriptUsageTracking, Stop-ScriptUsageTracking, Get-ScriptUsageStatistics, Find-ScriptBottlenecks, Save-UsageDatabase, Get-AllScriptPaths, Get-MetricsForScript
