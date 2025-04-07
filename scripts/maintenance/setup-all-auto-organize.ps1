# Script pour configurer toutes les mÃ©thodes d'organisation automatique
# Ce script configure:
# 1. La tÃ¢che planifiÃ©e quotidienne
# 2. La surveillance en temps rÃ©el
# 3. Le hook Git pre-commit

Write-Host "=== Configuration de toutes les mÃ©thodes d'organisation automatique ===" -ForegroundColor Cyan

# Obtenir le chemin racine du projet
$projectRoot = (Get-Item $PSScriptRoot).Parent.Parent.FullName
Set-Location $projectRoot

# 1. Configurer la tÃ¢che planifiÃ©e quotidienne
Write-Host "`n1. Configuration de la tÃ¢che planifiÃ©e quotidienne..." -ForegroundColor Yellow

$autoOrganizeScriptPath = (Resolve-Path ".\scripts\maintenance\auto-organize-silent.ps1").Path
$taskName1 = "N8N_AutoOrganize_Daily"

# VÃ©rifier si la tÃ¢che existe dÃ©jÃ 
$taskExists1 = Get-ScheduledTask -TaskName $taskName1 -ErrorAction SilentlyContinue

if ($taskExists1) {
    Write-Host "  La tÃ¢che $taskName1 existe dÃ©jÃ . Elle sera remplacÃ©e." -ForegroundColor Yellow
    # Supprimer la tÃ¢che existante
    Unregister-ScheduledTask -TaskName $taskName1 -Confirm:$false
}

# CrÃ©er l'action
$action1 = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$autoOrganizeScriptPath`""

# CrÃ©er le dÃ©clencheur (tous les jours Ã  9h00)
$trigger1 = New-ScheduledTaskTrigger -Daily -At 9am

# CrÃ©er les paramÃ¨tres
$settings1 = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -AllowStartIfOnBatteries

# CrÃ©er la tÃ¢che
Register-ScheduledTask -TaskName $taskName1 -Action $action1 -Trigger $trigger1 -Settings $settings1 -Description "Organise automatiquement les fichiers du projet N8N Email Sender (quotidien)"

Write-Host "  âœ… TÃ¢che planifiÃ©e $taskName1 crÃ©Ã©e avec succÃ¨s" -ForegroundColor Green

# 2. Configurer la surveillance en temps rÃ©el
Write-Host "`n2. Configuration de la surveillance en temps rÃ©el..." -ForegroundColor Yellow

$watchScriptPath = (Resolve-Path ".\scripts\maintenance\watch-and-organize.ps1").Path
$taskName2 = "N8N_AutoWatch_Startup"

# VÃ©rifier si la tÃ¢che existe dÃ©jÃ 
$taskExists2 = Get-ScheduledTask -TaskName $taskName2 -ErrorAction SilentlyContinue

if ($taskExists2) {
    Write-Host "  La tÃ¢che $taskName2 existe dÃ©jÃ . Elle sera remplacÃ©e." -ForegroundColor Yellow
    # Supprimer la tÃ¢che existante
    Unregister-ScheduledTask -TaskName $taskName2 -Confirm:$false
}

# CrÃ©er l'action
$action2 = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$watchScriptPath`""

# CrÃ©er le dÃ©clencheur (au dÃ©marrage)
$trigger2 = New-ScheduledTaskTrigger -AtStartup

# CrÃ©er les paramÃ¨tres
$settings2 = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -AllowStartIfOnBatteries -RunOnlyIfNetworkAvailable

# CrÃ©er la tÃ¢che
Register-ScheduledTask -TaskName $taskName2 -Action $action2 -Trigger $trigger2 -Settings $settings2 -Description "Surveille et organise automatiquement les nouveaux fichiers du projet N8N Email Sender"

Write-Host "  âœ… TÃ¢che planifiÃ©e $taskName2 crÃ©Ã©e avec succÃ¨s" -ForegroundColor Green

# CrÃ©er un raccourci sur le bureau pour dÃ©marrer manuellement la surveillance
$desktopPath = [Environment]::GetFolderPath("Desktop")
$shortcutPath = "$desktopPath\DÃ©marrer Surveillance N8N.lnk"

$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$watchScriptPath`""
$Shortcut.WorkingDirectory = Split-Path $watchScriptPath -Parent
$Shortcut.Description = "DÃ©marrer la surveillance des fichiers N8N"
$Shortcut.IconLocation = "powershell.exe,0"
$Shortcut.Save()

Write-Host "  âœ… Raccourci crÃ©Ã© sur le bureau: 'DÃ©marrer Surveillance N8N'" -ForegroundColor Green

# 3. Configurer le hook Git pre-commit
Write-Host "`n3. Configuration du hook Git pre-commit..." -ForegroundColor Yellow

$gitHooksDir = "$projectRoot\.git\hooks"
if (Test-Path "$projectRoot\.git") {
    if (-not (Test-Path $gitHooksDir)) {
        New-Item -ItemType Directory -Path $gitHooksDir -Force | Out-Null
        Write-Host "  Dossier hooks Git crÃ©Ã©" -ForegroundColor Green
    }

    $preCommitHookPath = "$gitHooksDir\pre-commit"
    $preCommitHookContent = @"
#!/bin/sh
# Pre-commit hook pour organiser automatiquement les fichiers

echo "Organisation automatique des fichiers avant commit..."
powershell -ExecutionPolicy Bypass -File "$projectRoot\scripts\maintenance\auto-organize-silent.ps1"

# Ajouter les fichiers dÃ©placÃ©s au commit
git add .

exit 0
"@

    Set-Content -Path $preCommitHookPath -Value $preCommitHookContent -NoNewline

    # Rendre le hook exÃ©cutable sous Unix
    if ($IsLinux -or $IsMacOS) {
        & chmod +x $preCommitHookPath
    }

    Write-Host "  âœ… Hook Git pre-commit configurÃ© pour l'organisation automatique" -ForegroundColor Green
} else {
    Write-Host "  âš ï¸ Dossier .git non trouvÃ©. Le hook pre-commit n'a pas Ã©tÃ© configurÃ©." -ForegroundColor Yellow
}

# 4. ExÃ©cuter une premiÃ¨re organisation
Write-Host "`n4. ExÃ©cution d'une premiÃ¨re organisation..." -ForegroundColor Yellow

& "$projectRoot\scripts\maintenance\auto-organize-silent.ps1"

Write-Host "  âœ… Organisation initiale terminÃ©e" -ForegroundColor Green

Write-Host "`n=== Configuration terminÃ©e ===" -ForegroundColor Cyan
Write-Host "Toutes les mÃ©thodes d'organisation automatique ont Ã©tÃ© configurÃ©es:" -ForegroundColor Green
Write-Host "1. TÃ¢che planifiÃ©e quotidienne (9h00)" -ForegroundColor Green
Write-Host "2. Surveillance en temps rÃ©el au dÃ©marrage" -ForegroundColor Green
Write-Host "3. Hook Git pre-commit" -ForegroundColor Green
Write-Host "`nVoulez-vous dÃ©marrer la surveillance en temps rÃ©el maintenant ? (O/N)" -ForegroundColor Yellow
$startNow = Read-Host

if ($startNow -eq "O" -or $startNow -eq "o") {
    Write-Host "DÃ©marrage de la surveillance..." -ForegroundColor Green
    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$watchScriptPath`""
}
