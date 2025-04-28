# Script PowerShell pour configurer les tÃ¢ches planifiÃ©es du journal de bord

# Chemin absolu vers le rÃ©pertoire du projet
$ProjectDir = (Get-Location).Path
$ScriptsDir = Join-Path $ProjectDir "scripts\cmd"

# Fonction pour crÃ©er une tÃ¢che planifiÃ©e
function Create-ScheduledTask {
    param (
        [string]$TaskName,
        [string]$ScriptPath,
        [string]$Arguments,
        [string]$Schedule,
        [string]$StartTime,
        [int]$DaysInterval = 1
    )
    
    $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`" $Arguments" -WorkingDirectory $ProjectDir
    
    if ($Schedule -eq "DAILY") {
        $Trigger = New-ScheduledTaskTrigger -Daily -At $StartTime -DaysInterval $DaysInterval
    } elseif ($Schedule -eq "WEEKLY") {
        $Trigger = New-ScheduledTaskTrigger -Weekly -At $StartTime -DaysOfWeek Monday
    } else {
        Write-Error "Schedule type not supported: $Schedule"
        return
    }
    
    $Settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -AllowStartIfOnBatteries
    
    # VÃ©rifier si la tÃ¢che existe dÃ©jÃ 
    $ExistingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    
    if ($ExistingTask) {
        # Mettre Ã  jour la tÃ¢che existante
        Set-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings
        Write-Host "TÃ¢che mise Ã  jour: $TaskName"
    } else {
        # CrÃ©er une nouvelle tÃ¢che
        Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -User "$env:USERDOMAIN\$env:USERNAME"
        Write-Host "TÃ¢che crÃ©Ã©e: $TaskName"
    }
}

# CrÃ©er la tÃ¢che quotidienne
$DailyScriptPath = Join-Path $ScriptsDir "journal-daily.ps1"
Create-ScheduledTask -TaskName "Journal_Quotidien" -ScriptPath $DailyScriptPath -Arguments "" -Schedule "DAILY" -StartTime "09:00"

# CrÃ©er la tÃ¢che hebdomadaire
Create-ScheduledTask -TaskName "Journal_Hebdomadaire" -ScriptPath $DailyScriptPath -Arguments "-Weekly" -Schedule "WEEKLY" -StartTime "08:00"

Write-Host "Configuration des tÃ¢ches planifiÃ©es terminÃ©e."
Write-Host "TÃ¢ches crÃ©Ã©es:"
Write-Host "  - Journal_Quotidien: ExÃ©cution quotidienne Ã  09:00"
Write-Host "  - Journal_Hebdomadaire: ExÃ©cution hebdomadaire le lundi Ã  08:00"
