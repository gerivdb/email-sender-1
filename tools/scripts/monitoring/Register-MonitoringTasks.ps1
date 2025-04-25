#Requires -Version 5.1
<#
.SYNOPSIS
    Enregistre les tâches planifiées pour le monitoring.
.DESCRIPTION
    Ce script crée et enregistre des tâches planifiées pour le monitoring
    des différents composants du système.
.PARAMETER TasksPath
    Chemin du dossier pour les scripts de tâches.
.PARAMETER Force
    Force la recréation des tâches même si elles existent déjà.
.EXAMPLE
    .\Register-MonitoringTasks.ps1 -TasksPath ".\tasks"
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-05-21
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$TasksPath = ".\tasks",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Fonction pour écrire dans le journal
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

# Créer le dossier des tâches s'il n'existe pas
if (-not (Test-Path -Path $TasksPath)) {
    New-Item -Path $TasksPath -ItemType Directory -Force | Out-Null
    Write-Log "Dossier des tâches créé: $TasksPath" -Level "INFO"
}

# Obtenir le chemin absolu du dossier des tâches
$TasksPath = (Resolve-Path -Path $TasksPath).Path

# Obtenir le chemin du projet
$projectPath = (Get-Location).Path

# Définir les tâches à créer
$tasks = @(
    @{
        Name = "EMAIL_SENDER_1_CycleDetection"
        Description = "Détecte les cycles dans les scripts EMAIL_SENDER_1"
        ScriptName = "Detect-CyclicDependencies.ps1"
        ScriptContent = @"
# Detect-CyclicDependencies.ps1
`$projectPath = "$projectPath"
`$scriptsPath = Join-Path -Path `$projectPath -ChildPath "scripts"
`$reportsPath = Join-Path -Path `$projectPath -ChildPath "reports"
`$logsPath = Join-Path -Path `$projectPath -ChildPath "logs\cycles"

# Créer les dossiers nécessaires
if (-not (Test-Path -Path `$reportsPath)) {
    New-Item -Path `$reportsPath -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path -Path `$logsPath)) {
    New-Item -Path `$logsPath -ItemType Directory -Force | Out-Null
}

# Exécuter la détection de cycles
`$modulePath = Join-Path -Path `$projectPath -ChildPath "modules\CycleDetector.psm1"
Import-Module `$modulePath -Force

# Journaliser l'exécution
`$logFile = Join-Path -Path `$logsPath -ChildPath "cycle_detection_`$(Get-Date -Format 'yyyyMMdd').log"
"[`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Début de la détection de cycles" | Out-File -FilePath `$logFile -Append

# Détecter les cycles
`$outputPath = Join-Path -Path `$reportsPath -ChildPath "dependencies_`$(Get-Date -Format 'yyyyMMdd').json"
`$result = & "`$projectPath\scripts\maintenance\error-prevention\Detect-CyclicDependencies.ps1" -Path `$scriptsPath -Recursive -OutputPath `$outputPath

# Journaliser le résultat
"[`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Fin de la détection de cycles. Résultat: `$(`$result | ConvertTo-Json -Compress)" | Out-File -FilePath `$logFile -Append
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

# Créer les dossiers nécessaires
if (-not (Test-Path -Path `$reportsPath)) {
    New-Item -Path `$reportsPath -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path -Path `$logsPath)) {
    New-Item -Path `$logsPath -ItemType Directory -Force | Out-Null
}

# Journaliser l'exécution
`$logFile = Join-Path -Path `$logsPath -ChildPath "performance_monitoring_`$(Get-Date -Format 'yyyyMMdd').log"
"[`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Début de la surveillance des performances" | Out-File -FilePath `$logFile -Append

# Liste des scripts critiques à surveiller
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
        "Performances mesurées. Résultat: `$(`$result | ConvertTo-Json -Compress)" | Out-File -FilePath `$logFile -Append
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

# Créer le dossier des rapports s'il n'existe pas
if (-not (Test-Path -Path `$reportsPath)) {
    New-Item -Path `$reportsPath -ItemType Directory -Force | Out-Null
}

# Journaliser l'exécution
`$logFile = Join-Path -Path `$logsPath -ChildPath "log_analysis_`$(Get-Date -Format 'yyyyMMdd').log"
"[`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Début de l'analyse des logs" | Out-File -FilePath `$logFile -Append

# Analyser les logs de détection de cycles
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
        `$cyclesDetected = (`$content | Select-String -Pattern "cycles? détecté" -AllMatches).Matches.Count
        `$cycleStats.TotalCyclesDetected += `$cyclesDetected
        
        `$date = `$log.BaseName -replace "cycle_detection_", ""
        `$cycleStats.CyclesByDate[`$date] = `$cyclesDetected
    }
    
    "Analyse des logs de détection de cycles terminée. `$(`$cycleStats.TotalCyclesDetected) cycles détectés au total." | Out-File -FilePath `$logFile -Append
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
        `$segmentations = `$content | Select-String -Pattern "Entrée segmentée en (\d+) parties" -AllMatches
        
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
    
    "Analyse des logs de segmentation terminée. `$(`$segmentationStats.TotalSegmentations) segmentations effectuées, moyenne de `$(`$segmentationStats.AverageSegments) segments par segmentation." | Out-File -FilePath `$logFile -Append
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
        `$scripts = `$content | Select-String -Pattern "Mesure des performances de (.*?)\.\.\..*?Performances mesurées\. Résultat: (.*)" -AllMatches
        
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
    
    "Analyse des logs de performance terminée. `$(`$performanceStats.LogCount) logs analysés." | Out-File -FilePath `$logFile -Append
}

# Générer un rapport
`$report = [PSCustomObject]@{
    GeneratedAt = (Get-Date).ToString("o")
    CycleDetection = `$cycleStats
    Segmentation = `$segmentationStats
    Performance = `$performanceStats
}

`$reportPath = Join-Path -Path `$reportsPath -ChildPath "log_analysis_`$(Get-Date -Format 'yyyyMMdd').json"
`$report | ConvertTo-Json -Depth 10 | Out-File -FilePath `$reportPath -Encoding utf8

# Journaliser la fin
"[`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Fin de l'analyse des logs. Rapport généré: `$reportPath" | Out-File -FilePath `$logFile -Append
"@
        Schedule = "Daily"
        Time = "05:00"
    }
)

# Créer et enregistrer les tâches
foreach ($task in $tasks) {
    $scriptPath = Join-Path -Path $TasksPath -ChildPath $task.ScriptName
    
    # Vérifier si la tâche existe déjà
    $existingTask = Get-ScheduledTask -TaskName $task.Name -ErrorAction SilentlyContinue
    
    if ($existingTask -and -not $Force) {
        Write-Log "La tâche $($task.Name) existe déjà. Utilisez -Force pour la recréer." -Level "WARNING"
        continue
    }
    
    # Supprimer la tâche existante si nécessaire
    if ($existingTask) {
        Unregister-ScheduledTask -TaskName $task.Name -Confirm:$false
        Write-Log "Tâche existante supprimée: $($task.Name)" -Level "INFO"
    }
    
    # Créer le script
    $task.ScriptContent | Out-File -FilePath $scriptPath -Encoding utf8
    Write-Log "Script créé: $scriptPath" -Level "INFO"
    
    # Créer l'action
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`""
    
    # Créer le déclencheur
    $trigger = New-ScheduledTaskTrigger -Daily -At $task.Time
    
    # Enregistrer la tâche
    Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $task.Name -Description $task.Description
    
    Write-Log "Tâche enregistrée: $($task.Name)" -Level "SUCCESS"
}

# Afficher un résumé
Write-Log "`nRésumé de l'enregistrement des tâches:" -Level "INFO"
Write-Log "  Tâches créées: $($tasks.Count)" -Level "INFO"
Write-Log "  Dossier des scripts: $TasksPath" -Level "INFO"

# Afficher les tâches enregistrées
Write-Log "`nTâches enregistrées:" -Level "INFO"
foreach ($task in $tasks) {
    Write-Log "  $($task.Name) - $($task.Description) - Exécution: $($task.Schedule) à $($task.Time)" -Level "INFO"
}
