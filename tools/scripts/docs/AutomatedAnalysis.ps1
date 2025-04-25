# Script pour automatiser l'exécution des scripts d'analyse

# Configuration
$AnalysisConfig = @{
    # Dossier racine pour l'analyse
    RootFolder = Join-Path -Path $env:TEMP -ChildPath "ErrorAnalysis"
    
    # Dossier des scripts d'analyse
    ScriptsFolder = Join-Path -Path (Split-Path -Parent $PSCommandPath) -ChildPath ".."
    
    # Dossier des résultats
    ResultsFolder = Join-Path -Path $env:TEMP -ChildPath "ErrorAnalysis\Results"
    
    # Fichier de configuration des tâches
    TasksFile = Join-Path -Path $env:TEMP -ChildPath "ErrorAnalysis\analysis-tasks.json"
    
    # Nombre maximum d'exécutions parallèles
    MaxParallelJobs = 3
    
    # Délai d'attente maximum (en secondes)
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
    
    # Mettre à jour la configuration
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
    
    # Créer les dossiers s'ils n'existent pas
    foreach ($folder in @($AnalysisConfig.RootFolder, $AnalysisConfig.ResultsFolder)) {
        if (-not (Test-Path -Path $folder)) {
            New-Item -Path $folder -ItemType Directory -Force | Out-Null
        }
    }
    
    # Créer le fichier de configuration des tâches s'il n'existe pas
    if (-not (Test-Path -Path $AnalysisConfig.TasksFile)) {
        $initialTasks = @{
            Tasks = @()
            LastUpdate = Get-Date -Format "o"
        }
        
        $initialTasks | ConvertTo-Json -Depth 5 | Set-Content -Path $AnalysisConfig.TasksFile
    }
    
    # Vérifier si les scripts d'analyse existent
    $scriptsExist = Test-Path -Path $AnalysisConfig.ScriptsFolder
    
    if (-not $scriptsExist) {
        Write-Error "Le dossier des scripts d'analyse n'existe pas: $($AnalysisConfig.ScriptsFolder)"
        return $false
    }
    
    return $AnalysisConfig
}

# Fonction pour ajouter une tâche d'analyse
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
    
    # Vérifier si le script existe
    if (-not (Test-Path -Path $ScriptPath)) {
        Write-Error "Le script n'existe pas: $ScriptPath"
        return $false
    }
    
    # Charger les tâches existantes
    $tasksFile = $AnalysisConfig.TasksFile
    $tasks = Get-Content -Path $tasksFile -Raw | ConvertFrom-Json
    
    # Vérifier si la tâche existe déjà
    $existingTask = $tasks.Tasks | Where-Object { $_.Name -eq $Name }
    
    if ($existingTask) {
        Write-Warning "La tâche '$Name' existe déjà. Elle sera mise à jour."
        $tasks.Tasks = $tasks.Tasks | Where-Object { $_.Name -ne $Name }
    }
    
    # Déterminer le dossier de sortie
    if ([string]::IsNullOrEmpty($OutputFolder)) {
        $OutputFolder = Join-Path -Path $AnalysisConfig.ResultsFolder -ChildPath $Name
    }
    
    # Créer la tâche
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
    
    # Calculer la prochaine exécution
    $task.NextRun = Get-NextRunTime -Task $task
    
    # Ajouter la tâche
    $tasks.Tasks += $task
    $tasks.LastUpdate = Get-Date -Format "o"
    
    # Enregistrer les tâches
    $tasks | ConvertTo-Json -Depth 5 | Set-Content -Path $tasksFile
    
    # Créer le dossier de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputFolder)) {
        New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
    }
    
    return $task
}

# Fonction pour calculer la prochaine exécution d'une tâche
function Get-NextRunTime {
    param (
        [Parameter(Mandatory = $true)]
        [object]$Task
    )
    
    # Si la tâche n'est pas activée, pas de prochaine exécution
    if (-not $Task.Enabled) {
        return $null
    }
    
    # Si la tâche est à la demande ou sur événement, pas de prochaine exécution planifiée
    if ($Task.Schedule -in @("OnDemand", "OnEvent")) {
        return $null
    }
    
    # Obtenir l'heure d'exécution
    $timeComponents = $Task.Time -split ":"
    $hour = [int]$timeComponents[0]
    $minute = [int]$timeComponents[1]
    
    # Date de base (aujourd'hui à l'heure spécifiée)
    $baseDate = (Get-Date).Date.AddHours($hour).AddMinutes($minute)
    
    # Si l'heure est déjà passée, commencer à partir de demain
    if ($baseDate -lt (Get-Date)) {
        $baseDate = $baseDate.AddDays(1)
    }
    
    # Calculer la prochaine exécution selon le calendrier
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
                    # C'est aujourd'hui et l'heure n'est pas encore passée
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
            # Trouver le prochain mois avec le jour spécifié
            $day = $Task.DayOfMonth
            $currentMonth = (Get-Date).Month
            $currentYear = (Get-Date).Year
            
            # Créer une date pour le jour spécifié de ce mois
            $targetDate = Get-Date -Year $currentYear -Month $currentMonth -Day $day -Hour $hour -Minute $minute -Second 0
            
            # Si la date est déjà passée, passer au mois suivant
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

# Fonction pour exécuter une tâche d'analyse
function Invoke-AnalysisTask {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskName,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force,
        
        [Parameter(Mandatory = $false)]
        [switch]$Wait
    )
    
    # Charger les tâches
    $tasksFile = $AnalysisConfig.TasksFile
    $tasks = Get-Content -Path $tasksFile -Raw | ConvertFrom-Json
    
    # Trouver la tâche
    $task = $tasks.Tasks | Where-Object { $_.Name -eq $TaskName }
    
    if (-not $task) {
        Write-Error "La tâche '$TaskName' n'existe pas."
        return $false
    }
    
    # Vérifier si la tâche est activée
    if (-not $task.Enabled -and -not $Force) {
        Write-Warning "La tâche '$TaskName' est désactivée. Utilisez -Force pour l'exécuter quand même."
        return $false
    }
    
    # Vérifier si le script existe
    if (-not (Test-Path -Path $task.ScriptPath)) {
        Write-Error "Le script n'existe pas: $($task.ScriptPath)"
        return $false
    }
    
    # Créer le dossier de sortie s'il n'existe pas
    if (-not (Test-Path -Path $task.OutputFolder)) {
        New-Item -Path $task.OutputFolder -ItemType Directory -Force | Out-Null
    }
    
    # Préparer les paramètres du script
    $scriptParams = @{}
    
    foreach ($param in $task.Parameters.PSObject.Properties) {
        $scriptParams[$param.Name] = $param.Value
    }
    
    # Ajouter le dossier de sortie aux paramètres
    $scriptParams["OutputFolder"] = $task.OutputFolder
    
    # Mettre à jour le statut de la tâche
    $task.Status = "Running"
    $task.LastRun = Get-Date -Format "o"
    $tasks.LastUpdate = Get-Date -Format "o"
    $tasks | ConvertTo-Json -Depth 5 | Set-Content -Path $tasksFile
    
    # Journaliser le début de l'exécution
    Write-Log -Message "Début de l'exécution de la tâche '$TaskName'"
    
    # Exécuter le script
    $jobName = "AnalysisTask_$TaskName"
    $scriptBlock = {
        param($scriptPath, $params, $outputFolder, $logFile)
        
        try {
            # Créer un dossier pour cette exécution
            $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
            $runFolder = Join-Path -Path $outputFolder -ChildPath $timestamp
            New-Item -Path $runFolder -ItemType Directory -Force | Out-Null
            
            # Rediriger la sortie vers un fichier de log
            $logPath = Join-Path -Path $runFolder -ChildPath "execution.log"
            Start-Transcript -Path $logPath
            
            # Exécuter le script
            Write-Host "Exécution du script: $scriptPath"
            Write-Host "Paramètres: $($params | ConvertTo-Json -Compress)"
            
            # Ajouter le dossier de sortie aux paramètres
            $params["OutputFolder"] = $runFolder
            
            # Charger et exécuter le script
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptBlock = [ScriptBlock]::Create($scriptContent)
            
            # Exécuter le script avec les paramètres
            & $scriptBlock @params
            
            # Créer un fichier de statut
            $status = @{
                Success = $true
                CompletedAt = Get-Date -Format "o"
                Error = $null
            }
            
            $status | ConvertTo-Json | Set-Content -Path (Join-Path -Path $runFolder -ChildPath "status.json")
            
            Write-Host "Exécution terminée avec succès."
            Stop-Transcript
            
            return @{
                Success = $true
                OutputFolder = $runFolder
            }
        }
        catch {
            # Journaliser l'erreur
            Write-Host "Erreur lors de l'exécution du script: $_"
            
            # Créer un fichier de statut
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
    
    # Démarrer le job
    $job = Start-Job -Name $jobName -ScriptBlock $scriptBlock -ArgumentList $task.ScriptPath, $scriptParams, $task.OutputFolder, $AnalysisConfig.LogFile
    
    # Attendre si demandé
    if ($Wait) {
        $job | Wait-Job -Timeout $AnalysisConfig.MaxWaitTime | Out-Null
        $result = $job | Receive-Job
        $job | Remove-Job
        
        # Mettre à jour le statut de la tâche
        $tasks = Get-Content -Path $tasksFile -Raw | ConvertFrom-Json
        $task = $tasks.Tasks | Where-Object { $_.Name -eq $TaskName }
        
        if ($result.Success) {
            $task.Status = "Completed"
            Write-Log -Message "Tâche '$TaskName' terminée avec succès."
        }
        else {
            $task.Status = "Failed"
            Write-Log -Message "Tâche '$TaskName' échouée: $($result.Error)"
        }
        
        # Calculer la prochaine exécution
        $task.NextRun = Get-NextRunTime -Task $task
        
        $tasks.LastUpdate = Get-Date -Format "o"
        $tasks | ConvertTo-Json -Depth 5 | Set-Content -Path $tasksFile
        
        return $result
    }
    else {
        Write-Log -Message "Tâche '$TaskName' démarrée en arrière-plan (Job ID: $($job.Id))"
        return $job
    }
}

# Fonction pour exécuter les tâches planifiées
function Invoke-ScheduledAnalysisTasks {
    param (
        [Parameter(Mandatory = $false)]
        [switch]$Force,
        
        [Parameter(Mandatory = $false)]
        [switch]$WaitForCompletion
    )
    
    # Charger les tâches
    $tasksFile = $AnalysisConfig.TasksFile
    $tasks = Get-Content -Path $tasksFile -Raw | ConvertFrom-Json
    
    # Obtenir les tâches à exécuter
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
        Write-Verbose "Aucune tâche à exécuter."
        return $null
    }
    
    # Exécuter les tâches
    $results = @()
    $runningJobs = @()
    
    foreach ($task in $tasksToRun) {
        # Vérifier le nombre de jobs en cours
        $currentJobs = Get-Job -Name "AnalysisTask_*" -ErrorAction SilentlyContinue
        
        while ($currentJobs.Count -ge $AnalysisConfig.MaxParallelJobs) {
            Write-Verbose "Nombre maximum de jobs atteint. Attente..."
            Start-Sleep -Seconds 5
            $currentJobs = Get-Job -Name "AnalysisTask_*" -ErrorAction SilentlyContinue
        }
        
        # Exécuter la tâche
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
    
    # Attendre la fin des jobs si demandé
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
            
            # Mettre à jour le statut de la tâche
            $tasks = Get-Content -Path $tasksFile -Raw | ConvertFrom-Json
            $task = $tasks.Tasks | Where-Object { $_.Name -eq $taskName }
            
            if ($result.Success) {
                $task.Status = "Completed"
                Write-Log -Message "Tâche '$taskName' terminée avec succès."
            }
            else {
                $task.Status = "Failed"
                Write-Log -Message "Tâche '$taskName' échouée: $($result.Error)"
            }
            
            # Calculer la prochaine exécution
            $task.NextRun = Get-NextRunTime -Task $task
            
            $tasks.LastUpdate = Get-Date -Format "o"
            $tasks | ConvertTo-Json -Depth 5 | Set-Content -Path $tasksFile
        }
    }
    
    return $results
}

# Fonction pour démarrer le service d'analyse automatique
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
        # Exécuter une seule fois
        $results = Invoke-ScheduledAnalysisTasks -WaitForCompletion
        
        if ($results) {
            Write-Host "Tâches exécutées: $($results.Count)"
        }
        else {
            Write-Host "Aucune tâche exécutée."
        }
        
        return $results
    }
    else {
        # Exécuter en boucle
        Write-Host "Service d'analyse démarré. Intervalle de vérification: $CheckIntervalSeconds secondes."
        Write-Host "Appuyez sur Ctrl+C pour arrêter le service."
        
        try {
            while ($true) {
                $results = Invoke-ScheduledAnalysisTasks
                
                if ($results) {
                    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Tâches démarrées: $($results.Count)"
                }
                else {
                    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Aucune tâche à exécuter."
                }
                
                # Attendre l'intervalle
                Start-Sleep -Seconds $CheckIntervalSeconds
            }
        }
        finally {
            Write-Host "Service d'analyse arrêté."
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
    
    # Créer le dossier de log s'il n'existe pas
    $logFolder = Split-Path -Path $AnalysisConfig.LogFile -Parent
    if (-not (Test-Path -Path $logFolder)) {
        New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
    }
    
    # Formater le message
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $formattedMessage = "[$timestamp] [$Level] $Message"
    
    # Écrire dans le fichier de log
    $formattedMessage | Out-File -FilePath $AnalysisConfig.LogFile -Append
    
    # Afficher le message
    switch ($Level) {
        "Warning" { Write-Warning $Message }
        "Error" { Write-Error $Message }
        default { Write-Verbose $Message }
    }
}

# Fonction pour obtenir les tâches d'analyse
function Get-AnalysisTasks {
    param (
        [Parameter(Mandatory = $false)]
        [switch]$EnabledOnly,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Pending", "Running", "Completed", "Failed")]
        [string]$Status = ""
    )
    
    # Charger les tâches
    $tasksFile = $AnalysisConfig.TasksFile
    $tasks = Get-Content -Path $tasksFile -Raw | ConvertFrom-Json
    
    # Filtrer les tâches
    $filteredTasks = $tasks.Tasks
    
    if ($EnabledOnly) {
        $filteredTasks = $filteredTasks | Where-Object { $_.Enabled }
    }
    
    if (-not [string]::IsNullOrEmpty($Status)) {
        $filteredTasks = $filteredTasks | Where-Object { $_.Status -eq $Status }
    }
    
    return $filteredTasks
}

# Fonction pour créer une tâche planifiée Windows
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
    
    # Vérifier si le module ScheduledTasks est disponible
    if (-not (Get-Module -ListAvailable -Name ScheduledTasks)) {
        Write-Error "Le module ScheduledTasks n'est pas disponible."
        return $false
    }
    
    # Créer le script d'exécution
    $scriptFolder = Join-Path -Path $AnalysisConfig.RootFolder -ChildPath "ScheduledTasks"
    if (-not (Test-Path -Path $scriptFolder)) {
        New-Item -Path $scriptFolder -ItemType Directory -Force | Out-Null
    }
    
    $scriptPath = Join-Path -Path $scriptFolder -ChildPath "$TaskName.ps1"
    
    $scriptContent = @"
# Script d'exécution automatique pour la tâche '$TaskName'
# Généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

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

# Exécuter la tâche
Invoke-AnalysisTask -TaskName "$TaskName" -Wait
"@
    
    $scriptContent | Set-Content -Path $scriptPath -Encoding UTF8
    
    # Créer le déclencheur
    $trigger = switch ($Schedule) {
        "Daily" { New-ScheduledTaskTrigger -Daily -At $Time }
        "Weekly" { New-ScheduledTaskTrigger -Weekly -DaysOfWeek $DaysOfWeek -At $Time }
        "Monthly" { New-ScheduledTaskTrigger -Monthly -DaysOfMonth $DayOfMonth -At $Time }
    }
    
    # Créer l'action
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`""
    
    # Vérifier si la tâche existe déjà
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    
    if ($existingTask) {
        Write-Warning "La tâche planifiée '$TaskName' existe déjà. Elle sera remplacée."
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    }
    
    # Créer la tâche
    $task = Register-ScheduledTask -TaskName $TaskName -Trigger $trigger -Action $action -RunLevel Highest
    
    if ($task) {
        Write-Host "Tâche planifiée '$TaskName' créée avec succès."
        return $true
    }
    else {
        Write-Error "Erreur lors de la création de la tâche planifiée '$TaskName'."
        return $false
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-AutomatedAnalysis, Add-AnalysisTask, Invoke-AnalysisTask
Export-ModuleMember -Function Invoke-ScheduledAnalysisTasks, Start-AnalysisService, Get-AnalysisTasks
Export-ModuleMember -Function Register-AnalysisScheduledTask
