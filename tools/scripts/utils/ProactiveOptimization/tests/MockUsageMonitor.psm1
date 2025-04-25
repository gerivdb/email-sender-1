# Module de mock pour UsageMonitor
# Ce module simule les fonctions du module UsageMonitor pour les tests

# Variables globales du module
$script:UsageDatabase = [PSCustomObject]@{
    InMemoryData                = @{}
    DatabasePath                = "TestPath\usage_data.xml"

    GetAllScriptPaths           = {
        return @(
            "C:\Scripts\Test1.ps1",
            "C:\Scripts\Test2.ps1",
            "C:\Scripts\Test3.ps1"
        )
    }

    GetMetricsForScript         = {
        param($ScriptPath)

        $baseDate = (Get-Date).AddDays(-30)
        $metrics = @()

        # Générer des métriques différentes selon le script
        switch ($ScriptPath) {
            "C:\Scripts\Test1.ps1" {
                # Script avec amélioration de performance
                for ($i = 0; $i -lt 20; $i++) {
                    $date = $baseDate.AddDays($i)
                    $duration = if ($i -lt 10) { 2000 - ($i * 50) } else { 1500 - ($i * 25) }

                    $metrics += [PSCustomObject]@{
                        ScriptPath    = $ScriptPath
                        ScriptName    = "Test1.ps1"
                        StartTime     = $date
                        EndTime       = $date.AddMilliseconds($duration)
                        Duration      = [timespan]::FromMilliseconds($duration)
                        Success       = $true
                        Parameters    = @{ Param1 = "Value1" }
                        ResourceUsage = @{
                            CpuUsageStart    = 10
                            CpuUsageEnd      = 50
                            MemoryUsageStart = 100MB
                            MemoryUsageEnd   = 200MB
                        }
                    }
                }
            }
            "C:\Scripts\Test2.ps1" {
                # Script avec dégradation de performance
                for ($i = 0; $i -lt 20; $i++) {
                    $date = $baseDate.AddDays($i)
                    $duration = 1000 + ($i * 50)
                    $success = $i % 5 -ne 0  # Échec tous les 5 jours

                    $metrics += [PSCustomObject]@{
                        ScriptPath    = $ScriptPath
                        ScriptName    = "Test2.ps1"
                        StartTime     = $date
                        EndTime       = $date.AddMilliseconds($duration)
                        Duration      = [timespan]::FromMilliseconds($duration)
                        Success       = $success
                        Parameters    = @{ Param1 = "Value1" }
                        ResourceUsage = @{
                            CpuUsageStart    = 20
                            CpuUsageEnd      = 70
                            MemoryUsageStart = 150MB
                            MemoryUsageEnd   = 300MB
                        }
                    }
                }
            }
            "C:\Scripts\Test3.ps1" {
                # Script avec utilisation variable selon l'heure
                for ($i = 0; $i -lt 30; $i++) {
                    $date = $baseDate.AddDays($i)

                    # Plus d'exécutions pendant les heures de bureau (9h-17h)
                    $executions = 1..3
                    if ($i % 7 -lt 5) {
                        # Jours de semaine
                        $executions = 1..5
                    }

                    foreach ($exec in $executions) {
                        $hour = if ($i % 7 -lt 5) { 9 + ($exec % 8) } else { 12 + ($exec % 4) }
                        $execDate = $date.AddHours($hour)

                        $metrics += [PSCustomObject]@{
                            ScriptPath    = $ScriptPath
                            ScriptName    = "Test3.ps1"
                            StartTime     = $execDate
                            EndTime       = $execDate.AddMilliseconds(800)
                            Duration      = [timespan]::FromMilliseconds(800)
                            Success       = $true
                            Parameters    = @{ Param1 = "Value1" }
                            ResourceUsage = @{
                                CpuUsageStart    = 5
                                CpuUsageEnd      = 30
                                MemoryUsageStart = 50MB
                                MemoryUsageEnd   = 100MB
                            }
                        }
                    }
                }
            }
            default {
                # Script par défaut
                for ($i = 0; $i -lt 5; $i++) {
                    $date = $baseDate.AddDays($i)

                    $metrics += [PSCustomObject]@{
                        ScriptPath    = $ScriptPath
                        ScriptName    = Split-Path -Path $ScriptPath -Leaf
                        StartTime     = $date
                        EndTime       = $date.AddMilliseconds(500)
                        Duration      = [timespan]::FromMilliseconds(500)
                        Success       = $true
                        Parameters    = @{ Param1 = "Value1" }
                        ResourceUsage = @{
                            CpuUsageStart    = 5
                            CpuUsageEnd      = 20
                            MemoryUsageStart = 50MB
                            MemoryUsageEnd   = 100MB
                        }
                    }
                }
            }
        }

        return $metrics
    }

    GetTopUsedScripts           = {
        param($count)

        return @{
            "C:\Scripts\Test1.ps1" = 10
            "C:\Scripts\Test2.ps1" = 5
        }
    }

    GetSlowestScripts           = {
        param($count)

        return @{
            "C:\Scripts\Test3.ps1" = 1500
            "C:\Scripts\Test1.ps1" = 1000
        }
    }

    MostFailingScripts          = {
        param($count)

        return @{
            "C:\Scripts\Test2.ps1" = 20
            "C:\Scripts\Test4.ps1" = 10
        }
    }

    GetMostFailingScripts       = {
        param($count)

        return @{
            "C:\Scripts\Test2.ps1" = 20
            "C:\Scripts\Test4.ps1" = 10
        }
    }

    GetResourceIntensiveScripts = {
        param($count)

        return @{
            "C:\Scripts\Test3.ps1" = 85
            "C:\Scripts\Test4.ps1" = 70
        }
    }

    AnalyzeBottlenecks          = {
        return @(
            [PSCustomObject]@{
                ScriptPath              = "C:\Scripts\Test1.ps1"
                ScriptName              = "Test1.ps1"
                AverageDuration         = 1000
                SlowThreshold           = 1500
                SlowExecutionsCount     = 5
                TotalExecutionsCount    = 10
                SlowExecutionPercentage = 50
                SlowExecutions          = @(
                    [PSCustomObject]@{
                        StartTime     = (Get-Date).AddHours(-1)
                        Duration      = [timespan]::FromMilliseconds(2000)
                        Success       = $true
                        Parameters    = @{ Param1 = "Value1" }
                        ResourceUsage = @{
                            CpuUsageStart    = 10
                            CpuUsageEnd      = 60
                            MemoryUsageStart = 100MB
                            MemoryUsageEnd   = 200MB
                        }
                    }
                )
            }
        )
    }
}

$script:IsInitialized = $false

# Fonctions publiques du module
function Initialize-UsageMonitor {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$DatabasePath = "TestPath\usage_data.xml"
    )

    $script:IsInitialized = $true
    Write-Verbose "UsageMonitor initialisé avec succès. Base de données: $DatabasePath"

    return $true
}

function Get-ScriptUsageStatistics {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ScriptPath,

        [Parameter(Mandatory = $false)]
        [int]$TopCount = 10
    )

    if ($ScriptPath) {
        return $script:UsageDatabase.GetMetricsForScript.Invoke($ScriptPath)
    } else {
        $result = [PSCustomObject]@{
            TopUsedScripts           = $script:UsageDatabase.GetTopUsedScripts.Invoke($TopCount)
            SlowestScripts           = $script:UsageDatabase.GetSlowestScripts.Invoke($TopCount)
            MostFailingScripts       = $script:UsageDatabase.GetMostFailingScripts.Invoke($TopCount)
            ResourceIntensiveScripts = $script:UsageDatabase.GetResourceIntensiveScripts.Invoke($TopCount)
        }

        return $result
    }
}

function Find-ScriptBottlenecks {
    [CmdletBinding()]
    param ()

    return $script:UsageDatabase.AnalyzeBottlenecks.Invoke()
}

# Fonctions additionnelles pour les tests
function Get-AllScriptPaths {
    [CmdletBinding()]
    param ()

    # Toujours retourner des chemins de script valides pour les tests
    return @(
        "C:\Scripts\Test1.ps1",
        "C:\Scripts\Test2.ps1",
        "C:\Scripts\Test3.ps1"
    )
}

function Get-MetricsForScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath
    )

    # Simuler des métriques différentes selon le script
    $baseDate = (Get-Date).AddDays(-30)
    $metrics = @()

    switch ($ScriptPath) {
        "C:\Scripts\Test1.ps1" {
            # Script avec amélioration de performance
            for ($i = 0; $i -lt 20; $i++) {
                $date = $baseDate.AddDays($i)
                $duration = if ($i -lt 10) { 2000 - ($i * 50) } else { 1500 - ($i * 25) }

                $metrics += [PSCustomObject]@{
                    ScriptPath    = $ScriptPath
                    ScriptName    = "Test1.ps1"
                    StartTime     = $date
                    EndTime       = $date.AddMilliseconds($duration)
                    Duration      = [timespan]::FromMilliseconds($duration)
                    Success       = $true
                    Parameters    = @{ Param1 = "Value1" }
                    ResourceUsage = @{
                        CpuUsageStart    = 10
                        CpuUsageEnd      = 50
                        MemoryUsageStart = 100MB
                        MemoryUsageEnd   = 200MB
                    }
                }
            }
        }
        "C:\Scripts\Test2.ps1" {
            # Script avec dégradation de performance
            for ($i = 0; $i -lt 20; $i++) {
                $date = $baseDate.AddDays($i)
                $duration = 1000 + ($i * 50)
                $success = $i % 5 -ne 0  # Échec tous les 5 jours

                $metrics += [PSCustomObject]@{
                    ScriptPath    = $ScriptPath
                    ScriptName    = "Test2.ps1"
                    StartTime     = $date
                    EndTime       = $date.AddMilliseconds($duration)
                    Duration      = [timespan]::FromMilliseconds($duration)
                    Success       = $success
                    Parameters    = @{ Param1 = "Value1" }
                    ResourceUsage = @{
                        CpuUsageStart    = 20
                        CpuUsageEnd      = 70
                        MemoryUsageStart = 150MB
                        MemoryUsageEnd   = 300MB
                    }
                }
            }
        }
        default {
            # Script par défaut
            for ($i = 0; $i -lt 5; $i++) {
                $date = $baseDate.AddDays($i)

                $metrics += [PSCustomObject]@{
                    ScriptPath    = $ScriptPath
                    ScriptName    = Split-Path -Path $ScriptPath -Leaf
                    StartTime     = $date
                    EndTime       = $date.AddMilliseconds(500)
                    Duration      = [timespan]::FromMilliseconds(500)
                    Success       = $true
                    Parameters    = @{ Param1 = "Value1" }
                    ResourceUsage = @{
                        CpuUsageStart    = 5
                        CpuUsageEnd      = 20
                        MemoryUsageStart = 50MB
                        MemoryUsageEnd   = 100MB
                    }
                }
            }
        }
    }

    return $metrics
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Initialize-UsageMonitor, Get-ScriptUsageStatistics, Find-ScriptBottlenecks, Get-AllScriptPaths, Get-MetricsForScript
