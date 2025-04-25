


# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()
# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
    
    # Ã‰crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃ©er le rÃ©pertoire de logs si nÃ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
    }
}
try {
    # Script principal
# Script PowerShell pour configurer le service de surveillance du journal de bord

# VÃ©rifier si le script est exÃ©cutÃ© en tant qu'administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Ce script doit Ãªtre exÃ©cutÃ© en tant qu'administrateur." -ForegroundColor Red
    Write-Host "Veuillez redÃ©marrer le script avec des privilÃ¨ges d'administrateur."
    exit
}

# Chemin absolu vers le rÃ©pertoire du projet
$ProjectDir = (Get-Location).Path
$ScriptsDir = Join-Path $ProjectDir "scripts\python\journal"
$WatcherScript = Join-Path $ScriptsDir "journal_watcher.py"

# Installer les dÃ©pendances nÃ©cessaires
Write-Host "Installation des dÃ©pendances..." -ForegroundColor Cyan
pip install watchdog pywin32

# CrÃ©er un script batch pour dÃ©marrer le watcher
$BatchScript = @"
@echo off
cd /d "$ProjectDir"
python "$WatcherScript" %*
"@

$BatchPath = Join-Path $ProjectDir "scripts\cmd\start-journal-watcher.bat"
Set-Content -Path $BatchPath -Value $BatchScript -Encoding ASCII

Write-Host "Script batch crÃ©Ã©: $BatchPath" -ForegroundColor Green

# CrÃ©er une tÃ¢che planifiÃ©e pour dÃ©marrer le watcher au dÃ©marrage
$TaskName = "Journal_Watcher"
$Action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c `"$BatchPath`" --background" -WorkingDirectory $ProjectDir
$Trigger = New-ScheduledTaskTrigger -AtLogon
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable:$false

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

# DÃ©marrer le watcher immÃ©diatement
Write-Host "DÃ©marrage du watcher..." -ForegroundColor Cyan
Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$BatchPath`" --background" -WindowStyle Hidden

Write-Host "Configuration du watcher terminÃ©e." -ForegroundColor Green
Write-Host "Le watcher dÃ©marrera automatiquement Ã  chaque connexion."

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
