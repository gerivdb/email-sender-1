# Schedule-SqlPermissionComplianceReport.ps1
# Script pour planifier l'exÃ©cution automatique du rapport de conformitÃ© des permissions SQL Server

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true)]
    [string]$ServerInstance,

    [Parameter(Mandatory = $false)]
    [string]$OutputFolder = "C:\Reports\SqlPermissionCompliance",

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
    [string]$TaskName = "SqlPermissionComplianceReport_$ServerInstance",

    [Parameter(Mandatory = $false)]
    [string]$TaskDescription = "GÃ©nÃ¨re un rapport de conformitÃ© des permissions SQL Server",

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.PSCredential]$TaskCredential
)

begin {
    # VÃ©rifier que le dossier de sortie existe
    if (-not (Test-Path -Path $OutputFolder)) {
        if ($PSCmdlet.ShouldProcess($OutputFolder, "CrÃ©er le dossier de sortie")) {
            New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
            Write-Verbose "Dossier de sortie crÃ©Ã©: $OutputFolder"
        }
    }

    # Chemin du script de gÃ©nÃ©ration de rapport
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Generate-SqlPermissionComplianceReport.ps1"
    if (-not (Test-Path -Path $scriptPath)) {
        throw "Script de gÃ©nÃ©ration de rapport non trouvÃ©: $scriptPath"
    }

    # Construire la commande PowerShell Ã  exÃ©cuter
    $outputPath = Join-Path -Path $OutputFolder -ChildPath "SqlPermissionComplianceReport_`$(Get-Date -Format 'yyyyMMdd').html"
    
    $command = "& '$scriptPath' -ServerInstance '$ServerInstance' -OutputPath '$outputPath'"
    
    if ($SendEmail) {
        if (-not $SmtpServer -or -not $FromAddress -or -not $ToAddress) {
            throw "ParamÃ¨tres d'email manquants. Veuillez spÃ©cifier SmtpServer, FromAddress et ToAddress."
        }
        
        $toAddressString = "'" + ($ToAddress -join "','") + "'"
        $command += " -SendEmail -SmtpServer '$SmtpServer' -FromAddress '$FromAddress' -ToAddress @($toAddressString)"
    }
    
    $command += " -Verbose"
    
    # Construire l'action de la tÃ¢che planifiÃ©e
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -Command `"$command`""
    
    # Construire le dÃ©clencheur de la tÃ¢che planifiÃ©e
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
    
    # Construire les paramÃ¨tres de la tÃ¢che planifiÃ©e
    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
}

process {
    try {
        # VÃ©rifier si la tÃ¢che existe dÃ©jÃ 
        $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        
        if ($existingTask) {
            if ($PSCmdlet.ShouldProcess($TaskName, "Mettre Ã  jour la tÃ¢che planifiÃ©e")) {
                # Mettre Ã  jour la tÃ¢che existante
                if ($TaskCredential) {
                    Set-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -User $TaskCredential.UserName -Password $TaskCredential.GetNetworkCredential().Password -Description $TaskDescription
                }
                else {
                    Set-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Description $TaskDescription
                }
                
                Write-Verbose "TÃ¢che planifiÃ©e mise Ã  jour: $TaskName"
            }
        }
        else {
            if ($PSCmdlet.ShouldProcess($TaskName, "CrÃ©er la tÃ¢che planifiÃ©e")) {
                # CrÃ©er une nouvelle tÃ¢che
                if ($TaskCredential) {
                    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -User $TaskCredential.UserName -Password $TaskCredential.GetNetworkCredential().Password -Description $TaskDescription
                }
                else {
                    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Description $TaskDescription
                }
                
                Write-Verbose "TÃ¢che planifiÃ©e crÃ©Ã©e: $TaskName"
            }
        }
        
        # Afficher les dÃ©tails de la tÃ¢che
        if ($PSCmdlet.ShouldProcess($TaskName, "Afficher les dÃ©tails de la tÃ¢che planifiÃ©e")) {
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
        Write-Error "Erreur lors de la planification du rapport de conformitÃ©: $_"
    }
}
