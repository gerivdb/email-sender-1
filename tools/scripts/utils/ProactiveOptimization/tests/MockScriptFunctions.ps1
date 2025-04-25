<#
.SYNOPSIS
    Mocks pour les fonctions des scripts à tester.
.DESCRIPTION
    Ce script contient des mocks pour les fonctions des scripts à tester.
#>

# Fonctions pour Analyze-UsageTrends.ps1
function Get-ScriptUsageTrends {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$PeriodDays = 30
    )

    # Simuler les tendances d'utilisation
    $baseDate = (Get-Date).AddDays(-$PeriodDays)
    $dailyUsage = @{}
    $hourlyUsage = @{}
    $performanceTrends = @{}
    $failureRateTrends = @{}
    $resourceUsageTrends = @{}

    # Générer des données quotidiennes
    for ($i = 0; $i -lt $PeriodDays; $i++) {
        $date = $baseDate.AddDays($i).ToString("yyyy-MM-dd")
        $dailyUsage[$date] = Get-Random -Minimum 0 -Maximum 20
    }

    # Générer des données horaires
    for ($hour = 0; $hour -lt 24; $hour++) {
        $hourlyUsage[$hour] = Get-Random -Minimum 0 -Maximum 15
    }

    # Générer des tendances de performance
    $scripts = @("Test1.ps1", "Test2.ps1", "Test3.ps1")
    foreach ($script in $scripts) {
        $performanceTrends[$script] = @{}
        $failureRateTrends[$script] = @{}
        $resourceUsageTrends[$script] = @{}

        for ($week = 1; $week -le 4; $week++) {
            $weekKey = "Week$week"
            $performanceTrends[$script][$weekKey] = 1000 - ($week * 50) + (Get-Random -Minimum -100 -Maximum 100)
            $failureRateTrends[$script][$weekKey] = [math]::Max(0, [math]::Min(100, 10 - ($week * 2) + (Get-Random -Minimum -5 -Maximum 5)))
            $resourceUsageTrends[$script][$weekKey] = @{
                CPU    = 50 - ($week * 5) + (Get-Random -Minimum -10 -Maximum 10)
                Memory = 200 - ($week * 20) + (Get-Random -Minimum -20 -Maximum 20)
            }
        }
    }

    return [PSCustomObject]@{
        DailyUsage          = $dailyUsage
        HourlyUsage         = $hourlyUsage
        PerformanceTrends   = $performanceTrends
        FailureRateTrends   = $failureRateTrends
        ResourceUsageTrends = $resourceUsageTrends
    }
}

function New-TrendReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Trends,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "TestReports"
    )

    # Créer le dossier de rapport s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }

    # Générer le nom du fichier de rapport
    $reportFile = Join-Path -Path $OutputPath -ChildPath "trend_report_$(Get-Date -Format 'yyyy-MM-dd').html"

    # Simuler la génération d'un rapport HTML
    $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de Tendances d'Utilisation</title>
</head>
<body>
    <h1>Rapport de Tendances d'Utilisation</h1>
    <p>Rapport généré le $(Get-Date -Format "dd/MM/yyyy à HH:mm:ss")</p>
</body>
</html>
"@

    # Écrire le contenu dans le fichier
    $htmlContent | Out-File -FilePath $reportFile -Encoding UTF8

    return $reportFile
}

# Fonctions pour Detect-Bottlenecks.ps1
function Find-ParallelProcessBottlenecks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$DetailedAnalysis
    )

    # Simuler la détection de goulots d'étranglement
    $bottlenecks = @(
        [PSCustomObject]@{
            ScriptPath              = "C:\Scripts\Test1.ps1"
            ScriptName              = "Test1.ps1"
            AverageDuration         = 1000
            SlowThreshold           = 1500
            SlowExecutionsCount     = 5
            TotalExecutionsCount    = 10
            SlowExecutionPercentage = 50
            IsParallel              = $true
        }
    )

    if ($DetailedAnalysis) {
        $bottlenecks[0] | Add-Member -MemberType NoteProperty -Name "DetailedAnalysis" -Value @{
            ParallelizationType = "ForEach-Object -Parallel (PowerShell 7+)"
            ProbableCause       = "Saturation du CPU"
            Recommendation      = "Réduire le nombre de threads parallèles"
        }
    }

    return $bottlenecks
}

function New-BottleneckReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Bottlenecks,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "TestReports"
    )

    # Créer le dossier de rapport s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }

    # Générer le nom du fichier de rapport
    $reportFile = Join-Path -Path $OutputPath -ChildPath "bottleneck_report_$(Get-Date -Format 'yyyy-MM-dd').html"

    # Simuler la génération d'un rapport HTML
    $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de Goulots d'Étranglement</title>
</head>
<body>
    <h1>Rapport de Goulots d'Étranglement</h1>
    <p>Rapport généré le $(Get-Date -Format "dd/MM/yyyy à HH:mm:ss")</p>
</body>
</html>
"@

    # Écrire le contenu dans le fichier
    $htmlContent | Out-File -FilePath $reportFile -Encoding UTF8

    return $reportFile
}

# Fonctions pour Monitor-ScriptUsage.ps1
function Get-UsageLogs {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$PeriodDays = 30,

        [Parameter(Mandatory = $false)]
        [int]$TopCount = 10
    )

    # Simuler l'analyse des logs d'utilisation
    return [PSCustomObject]@{
        TopUsedScripts           = @{
            "C:\Scripts\Test1.ps1" = 10
            "C:\Scripts\Test2.ps1" = 5
        }
        SlowestScripts           = @{
            "C:\Scripts\Test1.ps1" = 1000
            "C:\Scripts\Test3.ps1" = 1500
        }
        MostFailingScripts       = @{
            "C:\Scripts\Test4.ps1" = 10
            "C:\Scripts\Test2.ps1" = 20
        }
        ResourceIntensiveScripts = @{
            "C:\Scripts\Test4.ps1" = 70
            "C:\Scripts\Test3.ps1" = 85
        }
    }
}

function Detect-ParallelBottlenecks {
    [CmdletBinding()]
    param ()

    # Simuler la détection de goulots d'étranglement
    return @(
        [PSCustomObject]@{
            ScriptPath              = "C:\Scripts\Test1.ps1"
            ScriptName              = "Test1.ps1"
            AverageDuration         = 1000
            SlowThreshold           = 1500
            SlowExecutionsCount     = 5
            TotalExecutionsCount    = 10
            SlowExecutionPercentage = 50
            IsParallel              = $true
        }
    )
}

function Get-SlowExecutionPatterns {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$PeriodDays = 30,

        [Parameter(Mandatory = $false)]
        [int]$TopCount = 10,

        [Parameter(Mandatory = $false)]
        [array]$SlowExecutions = @()
    )

    # Simuler l'analyse des patterns d'exécution lente
    $result = @{
        "Paramètre fréquent" = "Param1=Value1"
        "Taille d'entrée"    = "Grande"
        "Heure d'exécution"  = "Matin"
        "Contention"         = "CPU"
    }

    return $result
}

function New-UsageReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [PSCustomObject]$UsageData,

        [Parameter(Mandatory = $false)]
        [PSCustomObject]$UsageStats,

        [Parameter(Mandatory = $false)]
        [array]$Bottlenecks,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "TestReports"
    )

    # Créer le dossier de rapport s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }

    # Générer le nom du fichier de rapport
    $reportFile = Join-Path -Path $OutputPath -ChildPath "usage_report_$(Get-Date -Format 'yyyy-MM-dd').html"

    # Simuler la génération d'un rapport HTML
    $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport d'Utilisation des Scripts</title>
</head>
<body>
    <h1>Rapport d'Utilisation des Scripts</h1>
    <p>Rapport généré le $(Get-Date -Format "dd/MM/yyyy à HH:mm:ss")</p>
</body>
</html>
"@

    # Écrire le contenu dans le fichier
    $htmlContent | Out-File -FilePath $reportFile -Encoding UTF8

    return $reportFile
}
