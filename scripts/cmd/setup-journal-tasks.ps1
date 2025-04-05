# Script PowerShell pour configurer les tâches planifiées du journal de bord

# Chemin absolu vers le répertoire du projet
$ProjectDir = (Get-Location).Path
$ScriptsDir = Join-Path $ProjectDir "scripts\cmd"

# Fonction pour créer une tâche planifiée
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
    
    # Vérifier si la tâche existe déjà
    $ExistingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    
    if ($ExistingTask) {
        # Mettre à jour la tâche existante
        Set-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings
        Write-Host "Tâche mise à jour: $TaskName"
    } else {
        # Créer une nouvelle tâche
        Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -User "$env:USERDOMAIN\$env:USERNAME"
        Write-Host "Tâche créée: $TaskName"
    }
}

# Créer la tâche quotidienne
$DailyScriptPath = Join-Path $ScriptsDir "journal-daily.ps1"
Create-ScheduledTask -TaskName "Journal_Quotidien" -ScriptPath $DailyScriptPath -Arguments "" -Schedule "DAILY" -StartTime "09:00"

# Créer la tâche hebdomadaire
Create-ScheduledTask -TaskName "Journal_Hebdomadaire" -ScriptPath $DailyScriptPath -Arguments "-Weekly" -Schedule "WEEKLY" -StartTime "08:00"

Write-Host "Configuration des tâches planifiées terminée."
Write-Host "Tâches créées:"
Write-Host "  - Journal_Quotidien: Exécution quotidienne à 09:00"
Write-Host "  - Journal_Hebdomadaire: Exécution hebdomadaire le lundi à 08:00"
