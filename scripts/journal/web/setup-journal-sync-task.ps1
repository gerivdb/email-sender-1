# Script PowerShell pour configurer une tâche planifiée de synchronisation du journal

# Vérifier si le script est exécuté en tant qu'administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Ce script doit être exécuté en tant qu'administrateur." -ForegroundColor Red
    Write-Host "Veuillez redémarrer le script avec des privilèges d'administrateur."
    exit
}

# Chemin absolu vers le répertoire du projet
$ProjectDir = (Get-Location).Path
$SyncScriptPath = Join-Path $ProjectDir "..\..\D"

# Fonction pour créer une tâche planifiée
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

    # Vérifier si la tâche existe déjà
    $ExistingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

    if ($ExistingTask) {
        # Mettre à jour la tâche existante
        Set-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings
        Write-Host "Tâche mise à jour: $TaskName" -ForegroundColor Green
    } else {
        # Créer une nouvelle tâche
        Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -User "SYSTEM" -RunLevel Highest
        Write-Host "Tâche créée: $TaskName" -ForegroundColor Green
    }
}

# Afficher un message d'introduction
Write-Host "Configuration de la tâche planifiée de synchronisation du journal" -ForegroundColor Cyan
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""

# Demander la fréquence de synchronisation
$frequency = Read-Host "Fréquence de synchronisation (1: Horaire, 2: Quotidienne) [2]"
if (-not $frequency) { $frequency = "2" }

if ($frequency -eq "1") {
    $schedule = "HOURLY"
    $startTime = "08:00"
    $intervalText = "toutes les heures"
} else {
    $schedule = "DAILY"
    $startTime = "20:00"
    $intervalText = "tous les jours à 20:00"
}

# Créer la tâche planifiée
Write-Host "Création de la tâche planifiée pour synchroniser le journal $intervalText..." -ForegroundColor Cyan
New-CustomScheduledTask -TaskName "Journal_Sync" -ScriptPath $SyncScriptPath -Schedule $schedule -StartTime $startTime

# Afficher un message de conclusion
Write-Host ""
Write-Host "Configuration terminée!" -ForegroundColor Green
Write-Host "Le journal sera automatiquement synchronisé avec l'écosystème $intervalText."
Write-Host "Vous pouvez modifier cette tâche dans le Planificateur de tâches Windows."

