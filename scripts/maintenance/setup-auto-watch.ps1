# Script pour configurer le dÃ©marrage automatique de la surveillance des fichiers
# Ce script crÃ©e une tÃ¢che planifiÃ©e qui dÃ©marre au dÃ©marrage de Windows

Write-Host "=== Configuration de la surveillance automatique au dÃ©marrage ===" -ForegroundColor Cyan

# Obtenir le chemin absolu du script watch-and-organize.ps1
$scriptPath = (Resolve-Path ".\scripts\maintenance\watch-and-organize.ps1").Path

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
