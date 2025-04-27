# Schedule-SqlPermissionRules.ps1
# Script pour planifier l'exécution automatique de toutes les règles de détection d'anomalies SQL Server

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true)]
    [string]$ServerInstance,

    [Parameter(Mandatory = $false)]
    [string]$OutputFolder = "C:\Reports\SqlPermissionAnomalies",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Daily", "Weekly", "Monthly")]
    [string]$Frequency = "Weekly",

    [Parameter(Mandatory = $false)]
    [int]$DayOfWeek = 1,  # 1 = Lundi, 7 = Dimanche

    [Parameter(Mandatory = $false)]
    [int]$DayOfMonth = 1,

    [Parameter(Mandatory = $false)]
    [string]$Time = "03:00",

    [Parameter(Mandatory = $false)]
    [switch]$SendEmail,

    [Parameter(Mandatory = $false)]
    [string]$SmtpServer,

    [Parameter(Mandatory = $false)]
    [string]$FromAddress,

    [Parameter(Mandatory = $false)]
    [string[]]$ToAddress,

    [Parameter(Mandatory = $false)]
    [string]$TaskName = "SqlPermissionRules_$ServerInstance",

    [Parameter(Mandatory = $false)]
    [string]$TaskDescription = "Exécute toutes les règles de détection d'anomalies SQL Server",

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.PSCredential]$TaskCredential
)

begin {
    # Vérifier que le dossier de sortie existe
    if (-not (Test-Path -Path $OutputFolder)) {
        if ($PSCmdlet.ShouldProcess($OutputFolder, "Créer le dossier de sortie")) {
            New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
            Write-Verbose "Dossier de sortie créé: $OutputFolder"
        }
    }

    # Chemin du script d'exécution de toutes les règles
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Run-AllSqlPermissionRules.ps1"
    if (-not (Test-Path -Path $scriptPath)) {
        throw "Script d'exécution de toutes les règles non trouvé: $scriptPath"
    }

    # Construire la commande PowerShell à exécuter
    $outputPath = Join-Path -Path $OutputFolder -ChildPath "SqlPermissionAnomaliesReport_`$(Get-Date -Format 'yyyyMMdd').html"
    
    $command = "& '$scriptPath' -ServerInstance '$ServerInstance' -OutputPath '$outputPath' -IncludeObjectLevel"
    
    if ($SendEmail) {
        if (-not $SmtpServer -or -not $FromAddress -or -not $ToAddress) {
            throw "Paramètres d'email manquants. Veuillez spécifier SmtpServer, FromAddress et ToAddress."
        }
        
        $toAddressString = "'" + ($ToAddress -join "','") + "'"
        $command += " -SendEmail -SmtpServer '$SmtpServer' -FromAddress '$FromAddress' -ToAddress @($toAddressString)"
    }
    
    $command += " -Verbose"
    
    # Construire l'action de la tâche planifiée
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -Command `"$command`""
    
    # Construire le déclencheur de la tâche planifiée
    switch ($Frequency) {
        "Daily" {
            $trigger = New-ScheduledTaskTrigger -Daily -At $Time
        }
        "Weekly" {
            $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $DayOfWeek -At $Time
        }
        "Monthly" {
            $trigger = New-ScheduledTaskTrigger -Monthly -DaysOfMonth $DayOfMonth -At $Time
        }
    }
    
    # Construire les paramètres de la tâche planifiée
    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
}

process {
    try {
        # Vérifier si la tâche existe déjà
        $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        
        if ($existingTask) {
            if ($PSCmdlet.ShouldProcess($TaskName, "Mettre à jour la tâche planifiée")) {
                # Mettre à jour la tâche existante
                if ($TaskCredential) {
                    Set-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -User $TaskCredential.UserName -Password $TaskCredential.GetNetworkCredential().Password -Description $TaskDescription
                }
                else {
                    Set-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Description $TaskDescription
                }
                
                Write-Verbose "Tâche planifiée mise à jour: $TaskName"
            }
        }
        else {
            if ($PSCmdlet.ShouldProcess($TaskName, "Créer la tâche planifiée")) {
                # Créer une nouvelle tâche
                if ($TaskCredential) {
                    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -User $TaskCredential.UserName -Password $TaskCredential.GetNetworkCredential().Password -Description $TaskDescription
                }
                else {
                    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Description $TaskDescription
                }
                
                Write-Verbose "Tâche planifiée créée: $TaskName"
            }
        }
        
        # Afficher les détails de la tâche
        if ($PSCmdlet.ShouldProcess($TaskName, "Afficher les détails de la tâche planifiée")) {
            $task = Get-ScheduledTask -TaskName $TaskName
            $taskInfo = [PSCustomObject]@{
                TaskName = $task.TaskName
                Status = $task.State
                NextRunTime = $task.NextRunTime
                LastRunTime = $task.LastRunTime
                LastRunResult = $task.LastTaskResult
                Frequency = $Frequency
                Time = $Time
                OutputFolder = $OutputFolder
                SendEmail = $SendEmail
            }
            
            return $taskInfo
        }
    }
    catch {
        Write-Error "Erreur lors de la planification de l'exécution des règles: $_"
    }
}
