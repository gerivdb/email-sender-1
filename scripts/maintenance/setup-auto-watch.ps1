# Script pour configurer le démarrage automatique de la surveillance des fichiers
# Ce script crée une tâche planifiée qui démarre au démarrage de Windows

Write-Host "=== Configuration de la surveillance automatique au démarrage ===" -ForegroundColor Cyan

# Obtenir le chemin absolu du script watch-and-organize.ps1
$scriptPath = (Resolve-Path ".\scripts\maintenance\watch-and-organize.ps1").Path

# Nom de la tâche
$taskName = "N8N_AutoWatch"

# Vérifier si la tâche existe déjà
$taskExists = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if ($taskExists) {
    Write-Host "La tâche $taskName existe déjà. Voulez-vous la remplacer ? (O/N)" -ForegroundColor Yellow
    $confirmation = Read-Host
    
    if ($confirmation -ne "O" -and $confirmation -ne "o") {
        Write-Host "Configuration annulée" -ForegroundColor Red
        exit
    }
    
    # Supprimer la tâche existante
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Write-Host "Tâche existante supprimée" -ForegroundColor Green
}

# Créer l'action
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""

# Créer le déclencheur (au démarrage)
$trigger = New-ScheduledTaskTrigger -AtStartup

# Créer les paramètres
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -AllowStartIfOnBatteries -RunOnlyIfNetworkAvailable

# Créer la tâche
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Description "Surveille et organise automatiquement les nouveaux fichiers du projet N8N Email Sender"

Write-Host "Tâche planifiée $taskName créée avec succès" -ForegroundColor Green
Write-Host "La surveillance démarrera automatiquement au démarrage de Windows" -ForegroundColor Green

# Créer un raccourci sur le bureau pour démarrer manuellement la surveillance
$desktopPath = [Environment]::GetFolderPath("Desktop")
$shortcutPath = "$desktopPath\Démarrer Surveillance N8N.lnk"

$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$scriptPath`""
$Shortcut.WorkingDirectory = Split-Path $scriptPath -Parent
$Shortcut.Description = "Démarrer la surveillance des fichiers N8N"
$Shortcut.IconLocation = "powershell.exe,0"
$Shortcut.Save()

Write-Host "Raccourci créé sur le bureau: 'Démarrer Surveillance N8N'" -ForegroundColor Green

Write-Host "`nVoulez-vous démarrer la surveillance maintenant ? (O/N)" -ForegroundColor Yellow
$startNow = Read-Host

if ($startNow -eq "O" -or $startNow -eq "o") {
    Write-Host "Démarrage de la surveillance..." -ForegroundColor Green
    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`""
}

Write-Host "`n=== Configuration terminée ===" -ForegroundColor Cyan
