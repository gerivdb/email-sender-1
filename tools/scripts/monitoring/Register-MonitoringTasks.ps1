#Requires -Version 5.1
<#
.SYNOPSIS
    Enregistre les tÃ¢ches planifiÃ©es pour le monitoring.
.DESCRIPTION
    Ce script crÃ©e et enregistre des tÃ¢ches planifiÃ©es pour le monitoring
    des diffÃ©rents composants du systÃ¨me.
.PARAMETER TasksPath
    Chemin du dossier pour les scripts de tÃ¢ches.
.PARAMETER Force
    Force la recrÃ©ation des tÃ¢ches mÃªme si elles existent dÃ©jÃ .
.EXAMPLE
    .\Register-MonitoringTasks.ps1 -TasksPath ".\tasks"
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-05-21
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$TasksPath = ".\tasks",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Fonction pour Ã©crire dans le journal
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
    }
    
    Write-Host $logMessage -ForegroundColor $color
}

# CrÃ©er le dossier des tÃ¢ches s'il n'existe pas
if (-not (Test-Path -Path $TasksPath)) {
    New-Item -Path $TasksPath -ItemType Directory -Force | Out-Null
    Write-Log "Dossier des tÃ¢ches crÃ©Ã©: $TasksPath" -Level "INFO"
}

# Obtenir le chemin absolu du dossier des tÃ¢ches
$TasksPath = (Resolve-Path -Path $TasksPath).Path

# Obtenir le chemin du projet
$projectPath = (Get-Location).Path

# DÃ©finir les tÃ¢ches Ã  crÃ©er
$tasks = @(
    @{
        Name = "EMAIL_SENDER_1_CycleDetection"
        Description = "DÃ©tecte les cycles dans les scripts EMAIL_SENDER_1"
        ScriptName = "Detect-CyclicDependencies.ps1"
        ScriptContent = @"
# Detect-CyclicDependencies.ps1
`$projectPath = "$projectPath"
`$scriptsPath = Join-Path -Path `$projectPath -ChildPath "scripts"
`$reportsPath = Join-Path -Path `$projectPath -ChildPath "reports"
`$logsPath = Join-Path -Path `$projectPath -ChildPath "logs\cycles"

# CrÃ©er les dossiers nÃ©cessaires
if (-not (Test-Path -Path `$reportsPath)) {
    New-Item -Path `$reportsPath -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path -Path `$logsPath)) {
    New-Item -Path `$logsPath -ItemType Directory -Force | Out-Null
}

# ExÃ©cuter la dÃ©tection de cycles
`$modulePath = Join-Path -Path `$projectPath -ChildPath "modules\CycleDetector.psm1"
Import-Module `$modulePath -Force

# Journaliser l'exÃ©cution
`$logFile = Join-Path -Path `$logsPath -ChildPath "cycle_detection_`$(Get-Date -Format 'yyyyMMdd').log"
"[`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] DÃ©but de la dÃ©tection de cycles" | Out-File -FilePath `$logFile -Append

# DÃ©tecter les cycles
`$outputPath = Join-Path -Path `$reportsPath -ChildPath "dependencies_`$(Get-Date -Format 'yyyyMMdd').json"
`$result = & "`$projectPath\scripts\maintenance\error-prevention\Detect-CyclicDependencies.ps1" -Path `$scriptsPath -Recursive -OutputPath `$outputPath

# Journaliser le rÃ©sultat
"[`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Fin de la dÃ©tection de cycles. RÃ©sultat: `$(`$result | ConvertTo-Json -Compress)" | Out-File -FilePath `$logFile -Append
"@
        Schedule = "Daily"
        Time = "03:00"
    },
    @{
        Name = "EMAIL_SENDER_1_PerformanceMonitoring"
        Description = "Surveille les performances des scripts critiques EMAIL_SENDER_1"
        ScriptName = "Measure-Performance.ps1"
        ScriptContent = @"
# Measure-Performance.ps1
`$projectPath = "$projectPath"
`$scriptsPath = Join-Path -Path `$projectPath -ChildPath "scripts"
`$reportsPath = Join-Path -Path `$projectPath -ChildPath "reports\performance"
`$logsPath = Join-Path -Path `$projectPath -ChildPath "logs\performance"

# CrÃ©er les dossiers nÃ©cessaires
if (-not (Test-Path -Path `$reportsPath)) {
    New-Item -Path `$reportsPath -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path -Path `$logsPath)) {
    New-Item -Path `$logsPath -ItemType Directory -Force | Out-Null
}

# Journaliser l'exÃ©cution
`$logFile = Join-Path -Path `$logsPath -ChildPath "performance_monitoring_`$(Get-Date -Format 'yyyyMMdd').log"
"[`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] DÃ©but de la surveillance des performances" | Out-File -FilePath `$logFile -Append

# Liste des scripts critiques Ã  surveiller
`$criticalScripts = @(
    "scripts\n8n\cache\Example-PredictiveCache.ps1",
    "scripts\agent-auto\Example-AgentAutoSegmentation.ps1",
    "scripts\performance\Optimize-ParallelExecution.ps1"
)

foreach (`$script in `$criticalScripts) {
    `$scriptPath = Join-Path -Path `$projectPath -ChildPath `$script
    `$scriptName = [System.IO.Path]::GetFileNameWithoutExtension(`$script)
    `$outputPath = Join-Path -Path `$reportsPath -ChildPath "`$scriptName`_`$(Get-Date -Format 'yyyyMMdd').json"
    
    "Mesure des performances de `$scriptPath..." | Out-File -FilePath `$logFile -Append
    
    try {
        `$result = & "`$projectPath\scripts\performance\Measure-ScriptPerformance.ps1" -ScriptPath `$scriptPath -Iterations 5 -OutputPath `$outputPath
        "Performances mesurÃ©es. RÃ©sultat: `$(`$result | ConvertTo-Json -Compress)" | Out-File -FilePath `$logFile -Append
    }
    catch {
        "Erreur lors de la mesure des performances: `$_" | Out-File -FilePath `$logFile -Append
    }
}

# Journaliser la fin
"[`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Fin de la surveillance des performances" | Out-File -FilePath `$logFile -Append
"@
        Schedule = "Daily"
        Time = "04:00"
    },
    @{
        Name = "EMAIL_SENDER_1_LogAnalysis"
        Description = "Analyse les logs EMAIL_SENDER_1"
        ScriptName = "Analyze-Logs.ps1"
        ScriptContent = @"
# Analyze-Logs.ps1
`$projectPath = "$projectPath"
`$logsPath = Join-Path -Path `$projectPath -ChildPath "logs"
`$reportsPath = Join-Path -Path `$projectPath -ChildPath "reports"

# CrÃ©er le dossier des rapports s'il n'existe pas
if (-not (Test-Path -Path `$reportsPath)) {
    New-Item -Path `$reportsPath -ItemType Directory -Force | Out-Null
}

# Journaliser l'exÃ©cution
`$logFile = Join-Path -Path `$logsPath -ChildPath "log_analysis_`$(Get-Date -Format 'yyyyMMdd').log"
"[`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] DÃ©but de l'analyse des logs" | Out-File -FilePath `$logFile -Append

# Analyser les logs de dÃ©tection de cycles
`$cycleLogsPath = Join-Path -Path `$logsPath -ChildPath "cycles"
if (Test-Path -Path `$cycleLogsPath) {
    `$cycleLogs = Get-ChildItem -Path `$cycleLogsPath -Filter "cycle_*.log"
    `$cycleStats = @{
        LogCount = `$cycleLogs.Count
        TotalCyclesDetected = 0
        CyclesByDate = @{}
    }
    
    foreach (`$log in `$cycleLogs) {
        `$content = Get-Content -Path `$log.FullName
        `$cyclesDetected = (`$content | Select-String -Pattern "cycles? dÃ©tectÃ©" -AllMatches).Matches.Count
        `$cycleStats.TotalCyclesDetected += `$cyclesDetected
        
        `$date = `$log.BaseName -replace "cycle_detection_", ""
        `$cycleStats.CyclesByDate[`$date] = `$cyclesDetected
    }
    
    "Analyse des logs de dÃ©tection de cycles terminÃ©e. `$(`$cycleStats.TotalCyclesDetected) cycles dÃ©tectÃ©s au total." | Out-File -FilePath `$logFile -Append
}

# Analyser les logs de segmentation
`$segmentationLogsPath = Join-Path -Path `$logsPath -ChildPath "segmentation"
if (Test-Path -Path `$segmentationLogsPath) {
    `$segmentationLogs = Get-ChildItem -Path `$segmentationLogsPath -Filter "segmentation_*.log"
    `$segmentationStats = @{
        LogCount = `$segmentationLogs.Count
        TotalSegmentations = 0
        AverageSegments = 0
        SegmentationsByDate = @{}
    }
    
    `$totalSegments = 0
    `$segmentationCount = 0
    
    foreach (`$log in `$segmentationLogs) {
        `$content = Get-Content -Path `$log.FullName
        `$segmentations = `$content | Select-String -Pattern "EntrÃ©e segmentÃ©e en (\d+) parties" -AllMatches
        
        `$segmentationStats.TotalSegmentations += `$segmentations.Matches.Count
        
        `$segments = 0
        foreach (`$match in `$segmentations.Matches) {
            `$segments += [int]`$match.Groups[1].Value
        }
        
        if (`$segmentations.Matches.Count -gt 0) {
            `$totalSegments += `$segments
            `$segmentationCount += `$segmentations.Matches.Count
        }
        
        `$date = `$log.BaseName -replace "segmentation_", ""
        `$segmentationStats.SegmentationsByDate[`$date] = `$segmentations.Matches.Count
    }
    
    if (`$segmentationCount -gt 0) {
        `$segmentationStats.AverageSegments = `$totalSegments / `$segmentationCount
    }
    
    "Analyse des logs de segmentation terminÃ©e. `$(`$segmentationStats.TotalSegmentations) segmentations effectuÃ©es, moyenne de `$(`$segmentationStats.AverageSegments) segments par segmentation." | Out-File -FilePath `$logFile -Append
}

# Analyser les logs de performance
`$performanceLogsPath = Join-Path -Path `$logsPath -ChildPath "performance"
if (Test-Path -Path `$performanceLogsPath) {
    `$performanceLogs = Get-ChildItem -Path `$performanceLogsPath -Filter "performance_*.log"
    `$performanceStats = @{
        LogCount = `$performanceLogs.Count
        ScriptPerformance = @{}
    }
    
    foreach (`$log in `$performanceLogs) {
        `$content = Get-Content -Path `$log.FullName
        `$scripts = `$content | Select-String -Pattern "Mesure des performances de (.*?)\.\.\..*?Performances mesurÃ©es\. RÃ©sultat: (.*)" -AllMatches
        
        foreach (`$match in `$scripts.Matches) {
            `$scriptPath = `$match.Groups[1].Value
            `$scriptName = [System.IO.Path]::GetFileNameWithoutExtension(`$scriptPath)
            
            if (-not `$performanceStats.ScriptPerformance.ContainsKey(`$scriptName)) {
                `$performanceStats.ScriptPerformance[`$scriptName] = @{
                    ExecutionTimes = @()
                    Dates = @()
                }
            }
            
            try {
                `$result = `$match.Groups[2].Value | ConvertFrom-Json
                `$performanceStats.ScriptPerformance[`$scriptName].ExecutionTimes += `$result.Statistics.AvgExecutionTimeMs
                `$performanceStats.ScriptPerformance[`$scriptName].Dates += `$log.BaseName -replace "performance_monitoring_", ""
            }
            catch {
                # Ignorer les erreurs de conversion JSON
            }
        }
    }
    
    "Analyse des logs de performance terminÃ©e. `$(`$performanceStats.LogCount) logs analysÃ©s." | Out-File -FilePath `$logFile -Append
}

# GÃ©nÃ©rer un rapport
`$report = [PSCustomObject]@{
    GeneratedAt = (Get-Date).ToString("o")
    CycleDetection = `$cycleStats
    Segmentation = `$segmentationStats
    Performance = `$performanceStats
}

`$reportPath = Join-Path -Path `$reportsPath -ChildPath "log_analysis_`$(Get-Date -Format 'yyyyMMdd').json"
`$report | ConvertTo-Json -Depth 10 | Out-File -FilePath `$reportPath -Encoding utf8

# Journaliser la fin
"[`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Fin de l'analyse des logs. Rapport gÃ©nÃ©rÃ©: `$reportPath" | Out-File -FilePath `$logFile -Append
"@
        Schedule = "Daily"
        Time = "05:00"
    }
)

# CrÃ©er et enregistrer les tÃ¢ches
foreach ($task in $tasks) {
    $scriptPath = Join-Path -Path $TasksPath -ChildPath $task.ScriptName
    
    # VÃ©rifier si la tÃ¢che existe dÃ©jÃ 
    $existingTask = Get-ScheduledTask -TaskName $task.Name -ErrorAction SilentlyContinue
    
    if ($existingTask -and -not $Force) {
        Write-Log "La tÃ¢che $($task.Name) existe dÃ©jÃ . Utilisez -Force pour la recrÃ©er." -Level "WARNING"
        continue
    }
    
    # Supprimer la tÃ¢che existante si nÃ©cessaire
    if ($existingTask) {
        Unregister-ScheduledTask -TaskName $task.Name -Confirm:$false
        Write-Log "TÃ¢che existante supprimÃ©e: $($task.Name)" -Level "INFO"
    }
    
    # CrÃ©er le script
    $task.ScriptContent | Out-File -FilePath $scriptPath -Encoding utf8
    Write-Log "Script crÃ©Ã©: $scriptPath" -Level "INFO"
    
    # CrÃ©er l'action
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`""
    
    # CrÃ©er le dÃ©clencheur
    $trigger = New-ScheduledTaskTrigger -Daily -At $task.Time
    
    # Enregistrer la tÃ¢che
    Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $task.Name -Description $task.Description
    
    Write-Log "TÃ¢che enregistrÃ©e: $($task.Name)" -Level "SUCCESS"
}

# Afficher un rÃ©sumÃ©
Write-Log "`nRÃ©sumÃ© de l'enregistrement des tÃ¢ches:" -Level "INFO"
Write-Log "  TÃ¢ches crÃ©Ã©es: $($tasks.Count)" -Level "INFO"
Write-Log "  Dossier des scripts: $TasksPath" -Level "INFO"

# Afficher les tÃ¢ches enregistrÃ©es
Write-Log "`nTÃ¢ches enregistrÃ©es:" -Level "INFO"
foreach ($task in $tasks) {
    Write-Log "  $($task.Name) - $($task.Description) - ExÃ©cution: $($task.Schedule) Ã  $($task.Time)" -Level "INFO"
}
