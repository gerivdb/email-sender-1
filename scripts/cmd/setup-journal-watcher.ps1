# Script PowerShell pour configurer le service de surveillance du journal de bord

# Vérifier si le script est exécuté en tant qu'administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Ce script doit être exécuté en tant qu'administrateur." -ForegroundColor Red
    Write-Host "Veuillez redémarrer le script avec des privilèges d'administrateur."
    exit
}

# Chemin absolu vers le répertoire du projet
$ProjectDir = (Get-Location).Path
$ScriptsDir = Join-Path $ProjectDir "scripts\python\journal"
$WatcherScript = Join-Path $ScriptsDir "journal_watcher.py"

# Installer les dépendances nécessaires
Write-Host "Installation des dépendances..." -ForegroundColor Cyan
pip install watchdog pywin32

# Créer un script batch pour démarrer le watcher
$BatchScript = @"
@echo off
cd /d "$ProjectDir"
python "$WatcherScript" %*
"@

$BatchPath = Join-Path $ProjectDir "scripts\cmd\start-journal-watcher.bat"
Set-Content -Path $BatchPath -Value $BatchScript -Encoding ASCII

Write-Host "Script batch créé: $BatchPath" -ForegroundColor Green

# Créer une tâche planifiée pour démarrer le watcher au démarrage
$TaskName = "Journal_Watcher"
$Action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c `"$BatchPath`" --background" -WorkingDirectory $ProjectDir
$Trigger = New-ScheduledTaskTrigger -AtLogon
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable:$false

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

# Démarrer le watcher immédiatement
Write-Host "Démarrage du watcher..." -ForegroundColor Cyan
Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$BatchPath`" --background" -WindowStyle Hidden

Write-Host "Configuration du watcher terminée." -ForegroundColor Green
Write-Host "Le watcher démarrera automatiquement à chaque connexion."
