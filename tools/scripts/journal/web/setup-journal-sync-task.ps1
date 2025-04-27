# Script PowerShell pour configurer une tÃ¢che planifiÃ©e de synchronisation du journal

# VÃ©rifier si le script est exÃ©cutÃ© en tant qu'administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Ce script doit Ãªtre exÃ©cutÃ© en tant qu'administrateur." -ForegroundColor Red
    Write-Host "Veuillez redÃ©marrer le script avec des privilÃ¨ges d'administrateur."
    exit
}

# Chemin absolu vers le rÃ©pertoire du projet
$ProjectDir = (Get-Location).Path
$SyncScriptPath = Join-Path $ProjectDir "..\..\D"

# Fonction pour crÃ©er une tÃ¢che planifiÃ©e
function New-CustomScheduledTask {
    param (
        [string]$TaskName,
        [string]$ScriptPath,
        [string]$Schedule,
        [string]$StartTime,
        [int]$DaysInterval = 1
    )

    $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`"" -WorkingDirectory $ProjectDir

    if ($Schedule -eq "DAILY") {
        $Trigger = New-ScheduledTaskTrigger -Daily -At $StartTime -DaysInterval $DaysInterval
    } elseif ($Schedule -eq "HOURLY") {
        $Trigger = New-ScheduledTaskTrigger -Once -At $StartTime -RepetitionInterval (New-TimeSpan -Hours 1) -RepetitionDuration (New-TimeSpan -Days 1)
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
        Write-Host "TÃ¢che mise Ã  jour: $TaskName" -ForegroundColor Green
    } else {
        # CrÃ©er une nouvelle tÃ¢che
        Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -User "SYSTEM" -RunLevel Highest
        Write-Host "TÃ¢che crÃ©Ã©e: $TaskName" -ForegroundColor Green
    }
}

# Afficher un message d'introduction
Write-Host "Configuration de la tÃ¢che planifiÃ©e de synchronisation du journal" -ForegroundColor Cyan
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""

# Demander la frÃ©quence de synchronisation
$frequency = Read-Host "FrÃ©quence de synchronisation (1: Horaire, 2: Quotidienne) [2]"
if (-not $frequency) { $frequency = "2" }

if ($frequency -eq "1") {
    $schedule = "HOURLY"
    $startTime = "08:00"
    $intervalText = "toutes les heures"
} else {
    $schedule = "DAILY"
    $startTime = "20:00"
    $intervalText = "tous les jours Ã  20:00"
}

# CrÃ©er la tÃ¢che planifiÃ©e
Write-Host "CrÃ©ation de la tÃ¢che planifiÃ©e pour synchroniser le journal $intervalText..." -ForegroundColor Cyan
New-CustomScheduledTask -TaskName "Journal_Sync" -ScriptPath $SyncScriptPath -Schedule $schedule -StartTime $startTime

# Afficher un message de conclusion
Write-Host ""
Write-Host "Configuration terminÃ©e!" -ForegroundColor Green
Write-Host "Le journal sera automatiquement synchronisÃ© avec l'Ã©cosystÃ¨me $intervalText."
Write-Host "Vous pouvez modifier cette tÃ¢che dans le Planificateur de tÃ¢ches Windows."

