# Script pour configurer le dÃ©marrage automatique de la surveillance des fichiers
# Ce script crÃ©e une tÃ¢che planifiÃ©e qui dÃ©marre au dÃ©marrage de Windows

Write-Host "=== Configuration de la surveillance automatique au dÃ©marrage ===" -ForegroundColor Cyan

# Obtenir le chemin absolu du script watch-and-organize.ps1
$scriptPath = (Resolve-Path "..\D").Path

# Nom de la tÃ¢che
$taskName = "N8N_AutoWatch"

# VÃ©rifier si la tÃ¢che existe dÃ©jÃ 
$taskExists = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if ($taskExists) {
    Write-Host "La tÃ¢che $taskName existe dÃ©jÃ . Voulez-vous la remplacer ? (O/N)" -ForegroundColor Yellow
    $confirmation = Read-Host
    
    if ($confirmation -ne "O" -and $confirmation -ne "o") {
        Write-Host "Configuration annulÃ©e" -ForegroundColor Red
        exit
    }
    
    # Supprimer la tÃ¢che existante
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Write-Host "TÃ¢che existante supprimÃ©e" -ForegroundColor Green
}

# CrÃ©er l'action
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""

# CrÃ©er le dÃ©clencheur (au dÃ©marrage)
$trigger = New-ScheduledTaskTrigger -AtStartup

# CrÃ©er les 


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
# Script pour configurer le dÃ©marrage automatique de la surveillance des fichiers
# Ce script crÃ©e une tÃ¢che planifiÃ©e qui dÃ©marre au dÃ©marrage de Windows

Write-Host "=== Configuration de la surveillance automatique au dÃ©marrage ===" -ForegroundColor Cyan

# Obtenir le chemin absolu du script watch-and-organize.ps1
$scriptPath = (Resolve-Path "..\D").Path

# Nom de la tÃ¢che
$taskName = "N8N_AutoWatch"

# VÃ©rifier si la tÃ¢che existe dÃ©jÃ 
$taskExists = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if ($taskExists) {
    Write-Host "La tÃ¢che $taskName existe dÃ©jÃ . Voulez-vous la remplacer ? (O/N)" -ForegroundColor Yellow
    $confirmation = Read-Host
    
    if ($confirmation -ne "O" -and $confirmation -ne "o") {
        Write-Host "Configuration annulÃ©e" -ForegroundColor Red
        exit
    }
    
    # Supprimer la tÃ¢che existante
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Write-Host "TÃ¢che existante supprimÃ©e" -ForegroundColor Green
}

# CrÃ©er l'action
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""

# CrÃ©er le dÃ©clencheur (au dÃ©marrage)
$trigger = New-ScheduledTaskTrigger -AtStartup

# CrÃ©er les paramÃ¨tres
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -AllowStartIfOnBatteries -RunOnlyIfNetworkAvailable

# CrÃ©er la tÃ¢che
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Description "Surveille et organise automatiquement les nouveaux fichiers du projet N8N Email Sender"

Write-Host "TÃ¢che planifiÃ©e $taskName crÃ©Ã©e avec succÃ¨s" -ForegroundColor Green
Write-Host "La surveillance dÃ©marrera automatiquement au dÃ©marrage de Windows" -ForegroundColor Green

# CrÃ©er un raccourci sur le bureau pour dÃ©marrer manuellement la surveillance
$desktopPath = [Environment]::GetFolderPath("Desktop")
$shortcutPath = "$desktopPath\DÃ©marrer Surveillance N8N.lnk"

$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$scriptPath`""
$Shortcut.WorkingDirectory = Split-Path $scriptPath -Parent
$Shortcut.Description = "DÃ©marrer la surveillance des fichiers N8N"
$Shortcut.IconLocation = "powershell.exe,0"
$Shortcut.Save()

Write-Host "Raccourci crÃ©Ã© sur le bureau: 'DÃ©marrer Surveillance N8N'" -ForegroundColor Green

Write-Host "`nVoulez-vous dÃ©marrer la surveillance maintenant ? (O/N)" -ForegroundColor Yellow
$startNow = Read-Host

if ($startNow -eq "O" -or $startNow -eq "o") {
    Write-Host "DÃ©marrage de la surveillance..." -ForegroundColor Green
    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`""
}

Write-Host "`n=== Configuration terminÃ©e ===" -ForegroundColor Cyan


}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
