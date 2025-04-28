# Script pour automatiser l'exÃ©cution des scripts d'analyse

# Configuration
$AnalysisConfig = @{
    # Dossier racine pour l'analyse
    RootFolder = Join-Path -Path $env:TEMP -ChildPath "ErrorAnalysis"
    
    # Dossier des scripts d'analyse
    ScriptsFolder = Join-Path -Path (Split-Path -Parent $PSCommandPath) -ChildPath ".."
    
    # Dossier des rÃ©sultats
    ResultsFolder = Join-Path -Path $env:TEMP -ChildPath "ErrorAnalysis\Results"
    
    # Fichier de configuration des tÃ¢ches
    TasksFile = Join-Path -Path $env:TEMP -ChildPath "ErrorAnalysis\analysis-tasks.json"
    
    # Nombre maximum d'exÃ©cutions parallÃ¨les
    MaxParallelJobs = 3
    
    # DÃ©lai d'attente maximum (en secondes)
    MaxWaitTime = 3600
    
    # Journalisation
    LogFile = Join-Path -Path $env:TEMP -ChildPath "ErrorAnalysis\analysis.log"
}

# Fonction pour initialiser l'automatisation
function Initialize-AutomatedAnalysis {
    param (
        [Parameter(Mandatory = $false)]
        [string]$RootFolder = "",
        
        [Parameter(Mandatory = $false)]
        [string]$ScriptsFolder = "",
        
        [Parameter(Mandatory = $false)]
        [string]$ResultsFolder = "",
        
        [Parameter(Mandatory = $false)]
        [int]$MaxParallelJobs = 0,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxWaitTime = 0
    )
    
    # Mettre Ã  jour la configuration
    if (-not [string]::IsNullOrEmpty($RootFolder)) {
        $AnalysisConfig.RootFolder = $RootFolder
    }
    
    if (-not [string]::IsNullOrEmpty($ScriptsFolder)) {
        $AnalysisConfig.ScriptsFolder = $ScriptsFolder
    }
    
    if (-not [string]::IsNullOrEmpty($ResultsFolder)) {
        $AnalysisConfig.ResultsFolder = $ResultsFolder
    }
    
    if ($MaxParallelJobs -gt 0) {
        $AnalysisConfig.MaxParallelJobs = $MaxParallelJobs
    }
    
    if ($MaxWaitTime -gt 0) {
        $AnalysisConfig.MaxWaitTime = $MaxWaitTime
    }
    
    # CrÃ©er les dossiers s'ils n'existent pas
    foreach ($folder in @($AnalysisConfig.RootFolder, $AnalysisConfig.ResultsFolder)) {
        if (-not (Test-Path -Path $folder)) {
            New-Item -Path $folder -ItemType Directory -Force | Out-Null
        }
    }
    
    # CrÃ©er le fichier de configuration des tÃ¢ches s'il n'existe pas
    if (-not (Test-Path -Path $AnalysisConfig.TasksFile)) {
        $initialTasks = @{
            Tasks = @()
            LastUpdate = Get-Date -Format "o"
        }
        
        $initialTasks | ConvertTo-Json -Depth 5 | Set-Content -Path $AnalysisConfig.TasksFile
    }
    
    # VÃ©rifier si les scripts d'analyse existent
    $scriptsExist = Test-Path -Path $AnalysisConfig.ScriptsFolder
    
    if (-not $scriptsExist) {
        Write-Error "Le dossier des scripts d'analyse n'existe pas: $($AnalysisConfig.ScriptsFolder)"
        return $false
    }
    
    return $AnalysisConfig
}

# Fonction pour ajouter une tÃ¢che d'analyse
function Add-AnalysisTask {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{},
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Daily", "Weekly", "Monthly", "OnDemand", "OnEvent")]
        [string]$Schedule = "OnDemand",
        
        [Parameter(Mandatory = $false)]
        [string]$Time = "00:00",
        
        [Parameter(Mandatory = $false)]
        [string[]]$DaysOfWeek = @("Monday"),
        
        [Parameter(Mandatory = $false)]
        [int]$DayOfMonth = 1,
        
        [Parameter(Mandatory = $false)]
        [string]$EventTrigger = "",
        
        [Parameter(Mandatory = $false)]
        [string]$OutputFolder = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$Enabled = $true
    )
    
    # VÃ©rifier si le script existe
    if (-not (Test-Path -Path $ScriptPath)) {
        Write-Error "Le script n'existe pas: $ScriptPath"
        return $false
    }
    
    # Charger les tÃ¢ches existantes
    $tasksFile = $AnalysisConfig.TasksFile
    $tasks = Get-Content -Path $tasksFile -Raw | ConvertFrom-Json
    
    # VÃ©rifier si la tÃ¢che existe dÃ©jÃ 
    $existingTask = $tasks.Tasks | Where-Object { $_.Name -eq $Name }
    
    if ($existingTask) {
        Write-Warning "La tÃ¢che '$Name' existe dÃ©jÃ . Elle sera mise Ã  jour."
        $tasks.Tasks = $tasks.Tasks | Where-Object { $_.Name -ne $Name }
    }
    
    # DÃ©terminer le dossier de sortie
    if ([string]::IsNullOrEmpty($OutputFolder)) {
        $OutputFolder = Join-Path -Path $AnalysisConfig.ResultsFolder -ChildPath $Name
    }
    
    # CrÃ©er la tÃ¢che
    $task = @{
        Name = $Name
        ScriptPath = $ScriptPath
        Parameters = $Parameters
        Schedule = $Schedule
        Time = $Time
        DaysOfWeek = $DaysOfWeek
        DayOfMonth = $DayOfMonth
        EventTrigger = $EventTrigger
        OutputFolder = $OutputFolder
        Enabled = $Enabled
        LastRun = $null
        NextRun = $null
        Status = "Pending"
    }
    
    # Calculer la prochaine exÃ©cution
    $task.NextRun = Get-NextRunTime -Task $task
    
    # Ajouter la tÃ¢che
    $tasks.Tasks += $task
    $tasks.LastUpdate = Get-Date -Format "o"
    
    # Enregistrer les tÃ¢ches
    $tasks | ConvertTo-Json -Depth 5 | Set-Content -Path $tasksFile
    
    # CrÃ©er le dossier de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputFolder)) {
        New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
    }
    
    return $task
}

# Fonction pour calculer la prochaine exÃ©cution d'une tÃ¢che
function Get-NextRunTime {
    param (
        [Parameter(Mandatory = $true)]
        [object]$Task
    )
    
    # Si la tÃ¢che n'est pas activÃ©e, pas de prochaine exÃ©cution
    if (-not $Task.Enabled) {
        return $null
    }
    
    # Si la tÃ¢che est Ã  la demande ou sur Ã©vÃ©nement, pas de prochaine exÃ©cution planifiÃ©e
    if ($Task.Schedule -in @("OnDemand", "OnEvent")) {
        return $null
    }
    
    # Obtenir l'heure d'exÃ©cution
    $timeComponents = $Task.Time -split ":"
    $hour = [int]$timeComponents[0]
    $minute = [int]$timeComponents[1]
    
    # Date de base (aujourd'hui Ã  l'heure spÃ©cifiÃ©e)
    $baseDate = (Get-Date).Date.AddHours($hour).AddMinutes($minute)
    
    # Si l'heure est dÃ©jÃ  passÃ©e, commencer Ã  partir de demain
    if ($baseDate -lt (Get-Date)) {
        $baseDate = $baseDate.AddDays(1)
    }
    
    # Calculer la prochaine exÃ©cution selon le calendrier
    switch ($Task.Schedule) {
        "Daily" {
            return $baseDate
        }
        "Weekly" {
            # Trouver le prochain jour de la semaine correspondant
            $currentDayOfWeek = (Get-Date).DayOfWeek.ToString()
            $daysUntilNext = 7
            
            foreach ($day in $Task.DaysOfWeek) {
                $targetDay = [System.DayOfWeek]$day
                $daysUntil = ($targetDay - (Get-Date).DayOfWeek + 7) % 7
                
                if ($daysUntil -eq 0 -and $baseDate -gt (Get-Date)) {
                    # C'est aujourd'hui et l'heure n'est pas encore passÃ©e
                    $daysUntilNext = 0
                    break
                }
                elseif ($daysUntil -gt 0 -and $daysUntil -lt $daysUntilNext) {
                    # Trouver le jour le plus proche
                    $daysUntilNext = $daysUntil
                }
            }
            
            return $baseDate.AddDays($daysUntilNext)
        }
        "Monthly" {
            # Trouver le prochain mois avec le jour spÃ©cifiÃ©
            $day = $Task.DayOfMonth
            $currentMonth = (Get-Date).Month
            $currentYear = (Get-Date).Year
            
            # CrÃ©er une date pour le jour spÃ©cifiÃ© de ce mois
            $targetDate = Get-Date -Year $currentYear -Month $currentMonth -Day $day -Hour $hour -Minute $minute -Second 0
            
            # Si la date est dÃ©jÃ  passÃ©e, passer au mois suivant
            if ($targetDate -lt (Get-Date)) {
                $currentMonth++
                if ($currentMonth -gt 12) {
                    $currentMonth = 1
                    $currentYear++
                }
                
                $targetDate = Get-Date -Year $currentYear -Month $currentMonth -Day $day -Hour $hour -Minute $minute -Second 0
            }
            
            return $targetDate
        }
    }
    
    return $null
}

# Fonction pour exÃ©cuter une tÃ¢che d'analyse
function Invoke-AnalysisTask {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskName,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force,
        
        [Parameter(Mandatory = $false)]
        [switch]$Wait
    )
    
    # Charger les tÃ¢ches
    $tasksFile = $AnalysisConfig.TasksFile
    $tasks = Get-Content -Path $tasksFile -Raw | ConvertFrom-Json
    
    # Trouver la tÃ¢che
    $task = $tasks.Tasks | Where-Object { $_.Name -eq $TaskName }
    
    if (-not $task) {
        Write-Error "La tÃ¢che '$TaskName' n'existe pas."
        return $false
    }
    
    # VÃ©rifier si la tÃ¢che est activÃ©e
    if (-not $task.Enabled -and -not $Force) {
        Write-Warning "La tÃ¢che '$TaskName' est dÃ©sactivÃ©e. Utilisez -Force pour l'exÃ©cuter quand mÃªme."
        return $false
    }
    
    # VÃ©rifier si le script existe
    if (-not (Test-Path -Path $task.ScriptPath)) {
        Write-Error "Le script n'existe pas: $($task.ScriptPath)"
        return $false
    }
    
    # CrÃ©er le dossier de sortie s'il n'existe pas
    if (-not (Test-Path -Path $task.OutputFolder)) {
        New-Item -Path $task.OutputFolder -ItemType Directory -Force | Out-Null
    }
    
    # PrÃ©parer les paramÃ¨tres du script
    $scriptParams = @{}
    
    foreach ($param in $task.Parameters.PSObject.Properties) {
        $scriptParams[$param.Name] = $param.Value
    }
    
    # Ajouter le dossier de sortie aux paramÃ¨tres
    $scriptParams["OutputFolder"] = $task.OutputFolder
    
    # Mettre Ã  jour le statut de la tÃ¢che
    $task.Status = "Running"
    $task.LastRun = Get-Date -Format "o"
    $tasks.LastUpdate = Get-Date -Format "o"
    $tasks | ConvertTo-Json -Depth 5 | Set-Content -Path $tasksFile
    
    # Journaliser le dÃ©but de l'exÃ©cution
    Write-Log -Message "DÃ©but de l'exÃ©cution de la tÃ¢che '$TaskName'"
    
    # ExÃ©cuter le script
    $jobName = "AnalysisTask_$TaskName"
    $scriptBlock = {
        param($scriptPath, $params, $outputFolder, $logFile)
        
        try {
            # CrÃ©er un dossier pour cette exÃ©cution
            $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
            $runFolder = Join-Path -Path $outputFolder -ChildPath $timestamp
            New-Item -Path $runFolder -ItemType Directory -Force | Out-Null
            
            # Rediriger la sortie vers un fichier de log
            $logPath = Join-Path -Path $runFolder -ChildPath "execution.log"
            Start-Transcript -Path $logPath
            
            # ExÃ©cuter le script
            Write-Host "ExÃ©cution du script: $scriptPath"
            Write-Host "ParamÃ¨tres: $($params | ConvertTo-Json -Compress)"
            
            # Ajouter le dossier de sortie aux paramÃ¨tres
            $params["OutputFolder"] = $runFolder
            
            # Charger et exÃ©cuter le script
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptBlock = [ScriptBlock]::Create($scriptContent)
            
            # ExÃ©cuter le script avec les paramÃ¨tres
            & $scriptBlock @params
            
            # CrÃ©er un fichier de statut
            $status = @{
                Success = $true
                CompletedAt = Get-Date -Format "o"
                Error = $null
            }
            
            $status | ConvertTo-Json | Set-Content -Path (Join-Path -Path $runFolder -ChildPath "status.json")
            
            Write-Host "ExÃ©cution terminÃ©e avec succÃ¨s."
            Stop-Transcript
            
            return @{
                Success = $true
                OutputFolder = $runFolder
            }
        }
        catch {
            # Journaliser l'erreur
            Write-Host "Erreur lors de l'exÃ©cution du script: $_"
            
            # CrÃ©er un fichier de statut
            $status = @{
                Success = $false
                CompletedAt = Get-Date -Format "o"
                Error = $_.ToString()
            }
            
            $status | ConvertTo-Json | Set-Content -Path (Join-Path -Path $runFolder -ChildPath "status.json")
            
            Stop-Transcript
            
            return @{
                Success = $false
                Error = $_.ToString()
                OutputFolder = $runFolder
            }
        }
    }
    
    # DÃ©marrer le job
    $job = Start-Job -Name $jobName -ScriptBlock $scriptBlock -ArgumentList $task.ScriptPath, $scriptParams, $task.OutputFolder, $AnalysisConfig.LogFile
    
    # Attendre si demandÃ©
    if ($Wait) {
        $job | Wait-Job -Timeout $AnalysisConfig.MaxWaitTime | Out-Null
        $result = $job | Receive-Job
        $job | Remove-Job
        
        # Mettre Ã  jour le statut de la tÃ¢che
        $tasks = Get-Content -Path $tasksFile -Raw | ConvertFrom-Json
        $task = $tasks.Tasks | Where-Object { $_.Name -eq $TaskName }
        
        if ($result.Success) {
            $task.Status = "Completed"
            Write-Log -Message "TÃ¢che '$TaskName' terminÃ©e avec succÃ¨s."
        }
        else {
            $task.Status = "Failed"
            Write-Log -Message "TÃ¢che '$TaskName' Ã©chouÃ©e: $($result.Error)"
        }
        
        # Calculer la prochaine exÃ©cution
        $task.NextRun = Get-NextRunTime -Task $task
        
        $tasks.LastUpdate = Get-Date -Format "o"
        $tasks | ConvertTo-Json -Depth 5 | Set-Content -Path $tasksFile
        
        return $result
    }
    else {
        Write-Log -Message "TÃ¢che '$TaskName' dÃ©marrÃ©e en arriÃ¨re-plan (Job ID: $($job.Id))"
        return $job
    }
}

# Fonction pour exÃ©cuter les tÃ¢ches planifiÃ©es
function Invoke-ScheduledAnalysisTasks {
    param (
        [Parameter(Mandatory = $false)]
        [switch]$Force,
        
        [Parameter(Mandatory = $false)]
        [switch]$WaitForCompletion
    )
    
    # Charger les tÃ¢ches
    $tasksFile = $AnalysisConfig.TasksFile
    $tasks = Get-Content -Path $tasksFile -Raw | ConvertFrom-Json
    
    # Obtenir les tÃ¢ches Ã  exÃ©cuter
    $now = Get-Date
    $tasksToRun = @()
    
    foreach ($task in $tasks.Tasks) {
        if (-not $task.Enabled -and -not $Force) {
            continue
        }
        
        if ($Force -or ($task.NextRun -and [DateTime]::Parse($task.NextRun) -le $now)) {
            $tasksToRun += $task
        }
    }
    
    if ($tasksToRun.Count -eq 0) {
        Write-Verbose "Aucune tÃ¢che Ã  exÃ©cuter."
        return $null
    }
    
    # ExÃ©cuter les tÃ¢ches
    $results = @()
    $runningJobs = @()
    
    foreach ($task in $tasksToRun) {
        # VÃ©rifier le nombre de jobs en cours
        $currentJobs = Get-Job -Name "AnalysisTask_*" -ErrorAction SilentlyContinue
        
        while ($currentJobs.Count -ge $AnalysisConfig.MaxParallelJobs) {
            Write-Verbose "Nombre maximum de jobs atteint. Attente..."
            Start-Sleep -Seconds 5
            $currentJobs = Get-Job -Name "AnalysisTask_*" -ErrorAction SilentlyContinue
        }
        
        # ExÃ©cuter la tÃ¢che
        $job = Invoke-AnalysisTask -TaskName $task.Name -Force:$Force
        
        if ($job -is [System.Management.Automation.Job]) {
            $runningJobs += $job
        }
        else {
            $results += @{
                TaskName = $task.Name
                Result = $job
            }
        }
    }
    
    # Attendre la fin des jobs si demandÃ©
    if ($WaitForCompletion -and $runningJobs.Count -gt 0) {
        Write-Verbose "Attente de la fin des jobs..."
        $runningJobs | Wait-Job -Timeout $AnalysisConfig.MaxWaitTime | Out-Null
        
        foreach ($job in $runningJobs) {
            $result = $job | Receive-Job
            $job | Remove-Job
            
            $taskName = $job.Name -replace "AnalysisTask_", ""
            
            $results += @{
                TaskName = $taskName
                Result = $result
            }
            
            # Mettre Ã  jour le statut de la tÃ¢che
            $tasks = Get-Content -Path $tasksFile -Raw | ConvertFrom-Json
            $task = $tasks.Tasks | Where-Object { $_.Name -eq $taskName }
            
            if ($result.Success) {
                $task.Status = "Completed"
                Write-Log -Message "TÃ¢che '$taskName' terminÃ©e avec succÃ¨s."
            }
            else {
                $task.Status = "Failed"
                Write-Log -Message "TÃ¢che '$taskName' Ã©chouÃ©e: $($result.Error)"
            }
            
            # Calculer la prochaine exÃ©cution
            $task.NextRun = Get-NextRunTime -Task $task
            
            $tasks.LastUpdate = Get-Date -Format "o"
            $tasks | ConvertTo-Json -Depth 5 | Set-Content -Path $tasksFile
        }
    }
    
    return $results
}

# Fonction pour dÃ©marrer le service d'analyse automatique
function Start-AnalysisService {
    param (
        [Parameter(Mandatory = $false)]
        [int]$CheckIntervalSeconds = 60,
        
        [Parameter(Mandatory = $false)]
        [switch]$RunOnce
    )
    
    # Initialiser le service
    Initialize-AutomatedAnalysis
    
    if ($RunOnce) {
        # ExÃ©cuter une seule fois
        $results = Invoke-ScheduledAnalysisTasks -WaitForCompletion
        
        if ($results) {
            Write-Host "TÃ¢ches exÃ©cutÃ©es: $($results.Count)"
        }
        else {
            Write-Host "Aucune tÃ¢che exÃ©cutÃ©e."
        }
        
        return $results
    }
    else {
        # ExÃ©cuter en boucle
        Write-Host "Service d'analyse dÃ©marrÃ©. Intervalle de vÃ©rification: $CheckIntervalSeconds secondes."
        Write-Host "Appuyez sur Ctrl+C pour arrÃªter le service."
        
        try {
            while ($true) {
                $results = Invoke-ScheduledAnalysisTasks
                
                if ($results) {
                    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - TÃ¢ches dÃ©marrÃ©es: $($results.Count)"
                }
                else {
                    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Aucune tÃ¢che Ã  exÃ©cuter."
                }
                
                # Attendre l'intervalle
                Start-Sleep -Seconds $CheckIntervalSeconds
            }
        }
        finally {
            Write-Host "Service d'analyse arrÃªtÃ©."
        }
    }
}

# Fonction pour journaliser les messages
function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Information", "Warning", "Error")]
        [string]$Level = "Information"
    )
    
    # CrÃ©er le dossier de log s'il n'existe pas
    $logFolder = Split-Path -Path $AnalysisConfig.LogFile -Parent
    if (-not (Test-Path -Path $logFolder)) {
        New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
    }
    
    # Formater le message
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $formattedMessage = "[$timestamp] [$Level] $Message"
    
    # Ã‰crire dans le fichier de log
    $formattedMessage | Out-File -FilePath $AnalysisConfig.LogFile -Append
    
    # Afficher le message
    switch ($Level) {
        "Warning" { Write-Warning $Message }
        "Error" { Write-Error $Message }
        default { Write-Verbose $Message }
    }
}

# Fonction pour obtenir les tÃ¢ches d'analyse
function Get-AnalysisTasks {
    param (
        [Parameter(Mandatory = $false)]
        [switch]$EnabledOnly,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Pending", "Running", "Completed", "Failed")]
        [string]$Status = ""
    )
    
    # Charger les tÃ¢ches
    $tasksFile = $AnalysisConfig.TasksFile
    $tasks = Get-Content -Path $tasksFile -Raw | ConvertFrom-Json
    
    # Filtrer les tÃ¢ches
    $filteredTasks = $tasks.Tasks
    
    if ($EnabledOnly) {
        $filteredTasks = $filteredTasks | Where-Object { $_.Enabled }
    }
    
    if (-not [string]::IsNullOrEmpty($Status)) {
        $filteredTasks = $filteredTasks | Where-Object { $_.Status -eq $Status }
    }
    
    return $filteredTasks
}

# Fonction pour crÃ©er une tÃ¢che planifiÃ©e Windows
function Register-AnalysisScheduledTask {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskName,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Daily", "Weekly", "Monthly")]
        [string]$Schedule = "Daily",
        
        [Parameter(Mandatory = $false)]
        [string]$Time = "03:00",
        
        [Parameter(Mandatory = $false)]
        [string[]]$DaysOfWeek = @("Monday"),
        
        [Parameter(Mandatory = $false)]
        [int]$DayOfMonth = 1
    )
    
    # VÃ©rifier si le module ScheduledTasks est disponible
    if (-not (Get-Module -ListAvailable -Name ScheduledTasks)) {
        Write-Error "Le module ScheduledTasks n'est pas disponible."
        return $false
    }
    
    # CrÃ©er le script d'exÃ©cution
    $scriptFolder = Join-Path -Path $AnalysisConfig.RootFolder -ChildPath "ScheduledTasks"
    if (-not (Test-Path -Path $scriptFolder)) {
        New-Item -Path $scriptFolder -ItemType Directory -Force | Out-Null
    }
    
    $scriptPath = Join-Path -Path $scriptFolder -ChildPath "$TaskName.ps1"
    
    $scriptContent = @"
# Script d'exÃ©cution automatique pour la tÃ¢che '$TaskName'
# GÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

# Importer le module d'analyse
`$modulePath = "$PSCommandPath"
if (Test-Path -Path `$modulePath) {
    . `$modulePath
}
else {
    Write-Error "Le module d'analyse est introuvable: `$modulePath"
    exit 1
}

# Initialiser l'automatisation
Initialize-AutomatedAnalysis

# ExÃ©cuter la tÃ¢che
Invoke-AnalysisTask -TaskName "$TaskName" -Wait
"@
    
    $scriptContent | Set-Content -Path $scriptPath -Encoding UTF8
    
    # CrÃ©er le dÃ©clencheur
    $trigger = switch ($Schedule) {
        "Daily" { New-ScheduledTaskTrigger -Daily -At $Time }
        "Weekly" { New-ScheduledTaskTrigger -Weekly -DaysOfWeek $DaysOfWeek -At $Time }
        "Monthly" { New-ScheduledTaskTrigger -Monthly -DaysOfMonth $DayOfMonth -At $Time }
    }
    
    # CrÃ©er l'action
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`""
    
    # VÃ©rifier si la tÃ¢che existe dÃ©jÃ 
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    
    if ($existingTask) {
        Write-Warning "La tÃ¢che planifiÃ©e '$TaskName' existe dÃ©jÃ . Elle sera remplacÃ©e."
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    }
    
    # CrÃ©er la tÃ¢che
    $task = Register-ScheduledTask -TaskName $TaskName -Trigger $trigger -Action $action -RunLevel Highest
    
    if ($task) {
        Write-Host "TÃ¢che planifiÃ©e '$TaskName' crÃ©Ã©e avec succÃ¨s."
        return $true
    }
    else {
        Write-Error "Erreur lors de la crÃ©ation de la tÃ¢che planifiÃ©e '$TaskName'."
        return $false
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-AutomatedAnalysis, Add-AnalysisTask, Invoke-AnalysisTask
Export-ModuleMember -Function Invoke-ScheduledAnalysisTasks, Start-AnalysisService, Get-AnalysisTasks
Export-ModuleMember -Function Register-AnalysisScheduledTask
