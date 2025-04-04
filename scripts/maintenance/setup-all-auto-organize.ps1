# Script pour configurer toutes les méthodes d'organisation automatique
# Ce script configure:
# 1. La tâche planifiée quotidienne
# 2. La surveillance en temps réel
# 3. Le hook Git pre-commit

Write-Host "=== Configuration de toutes les méthodes d'organisation automatique ===" -ForegroundColor Cyan

# Obtenir le chemin racine du projet
$projectRoot = (Get-Item $PSScriptRoot).Parent.Parent.FullName
Set-Location $projectRoot

# 1. Configurer la tâche planifiée quotidienne
Write-Host "`n1. Configuration de la tâche planifiée quotidienne..." -ForegroundColor Yellow

$autoOrganizeScriptPath = (Resolve-Path ".\scripts\maintenance\auto-organize-silent.ps1").Path
$taskName1 = "N8N_AutoOrganize_Daily"

# Vérifier si la tâche existe déjà
$taskExists1 = Get-ScheduledTask -TaskName $taskName1 -ErrorAction SilentlyContinue

if ($taskExists1) {
    Write-Host "  La tâche $taskName1 existe déjà. Elle sera remplacée." -ForegroundColor Yellow
    # Supprimer la tâche existante
    Unregister-ScheduledTask -TaskName $taskName1 -Confirm:$false
}

# Créer l'action
$action1 = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$autoOrganizeScriptPath`""

# Créer le déclencheur (tous les jours à 9h00)
$trigger1 = New-ScheduledTaskTrigger -Daily -At 9am

# Créer les paramètres
$settings1 = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -AllowStartIfOnBatteries

# Créer la tâche
Register-ScheduledTask -TaskName $taskName1 -Action $action1 -Trigger $trigger1 -Settings $settings1 -Description "Organise automatiquement les fichiers du projet N8N Email Sender (quotidien)"

Write-Host "  ✅ Tâche planifiée $taskName1 créée avec succès" -ForegroundColor Green

# 2. Configurer la surveillance en temps réel
Write-Host "`n2. Configuration de la surveillance en temps réel..." -ForegroundColor Yellow

$watchScriptPath = (Resolve-Path ".\scripts\maintenance\watch-and-organize.ps1").Path
$taskName2 = "N8N_AutoWatch_Startup"

# Vérifier si la tâche existe déjà
$taskExists2 = Get-ScheduledTask -TaskName $taskName2 -ErrorAction SilentlyContinue

if ($taskExists2) {
    Write-Host "  La tâche $taskName2 existe déjà. Elle sera remplacée." -ForegroundColor Yellow
    # Supprimer la tâche existante
    Unregister-ScheduledTask -TaskName $taskName2 -Confirm:$false
}

# Créer l'action
$action2 = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$watchScriptPath`""

# Créer le déclencheur (au démarrage)
$trigger2 = New-ScheduledTaskTrigger -AtStartup

# Créer les paramètres
$settings2 = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -AllowStartIfOnBatteries -RunOnlyIfNetworkAvailable

# Créer la tâche
Register-ScheduledTask -TaskName $taskName2 -Action $action2 -Trigger $trigger2 -Settings $settings2 -Description "Surveille et organise automatiquement les nouveaux fichiers du projet N8N Email Sender"

Write-Host "  ✅ Tâche planifiée $taskName2 créée avec succès" -ForegroundColor Green

# Créer un raccourci sur le bureau pour démarrer manuellement la surveillance
$desktopPath = [Environment]::GetFolderPath("Desktop")
$shortcutPath = "$desktopPath\Démarrer Surveillance N8N.lnk"

$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$watchScriptPath`""
$Shortcut.WorkingDirectory = Split-Path $watchScriptPath -Parent
$Shortcut.Description = "Démarrer la surveillance des fichiers N8N"
$Shortcut.IconLocation = "powershell.exe,0"
$Shortcut.Save()

Write-Host "  ✅ Raccourci créé sur le bureau: 'Démarrer Surveillance N8N'" -ForegroundColor Green

# 3. Configurer le hook Git pre-commit
Write-Host "`n3. Configuration du hook Git pre-commit..." -ForegroundColor Yellow

$gitHooksDir = "$projectRoot\.git\hooks"
if (Test-Path "$projectRoot\.git") {
    if (-not (Test-Path $gitHooksDir)) {
        New-Item -ItemType Directory -Path $gitHooksDir -Force | Out-Null
        Write-Host "  Dossier hooks Git créé" -ForegroundColor Green
    }

    $preCommitHookPath = "$gitHooksDir\pre-commit"
    $preCommitHookContent = @"
#!/bin/sh
# Pre-commit hook pour organiser automatiquement les fichiers

echo "Organisation automatique des fichiers avant commit..."
powershell -ExecutionPolicy Bypass -File "$projectRoot\scripts\maintenance\auto-organize-silent.ps1"

# Ajouter les fichiers déplacés au commit
git add .

exit 0
"@

    Set-Content -Path $preCommitHookPath -Value $preCommitHookContent -NoNewline

    # Rendre le hook exécutable sous Unix
    if ($IsLinux -or $IsMacOS) {
        & chmod +x $preCommitHookPath
    }

    Write-Host "  ✅ Hook Git pre-commit configuré pour l'organisation automatique" -ForegroundColor Green
} else {
    Write-Host "  ⚠️ Dossier .git non trouvé. Le hook pre-commit n'a pas été configuré." -ForegroundColor Yellow
}

# 4. Exécuter une première organisation
Write-Host "`n4. Exécution d'une première organisation..." -ForegroundColor Yellow

& "$projectRoot\scripts\maintenance\auto-organize-silent.ps1"

Write-Host "  ✅ Organisation initiale terminée" -ForegroundColor Green

Write-Host "`n=== Configuration terminée ===" -ForegroundColor Cyan
Write-Host "Toutes les méthodes d'organisation automatique ont été configurées:" -ForegroundColor Green
Write-Host "1. Tâche planifiée quotidienne (9h00)" -ForegroundColor Green
Write-Host "2. Surveillance en temps réel au démarrage" -ForegroundColor Green
Write-Host "3. Hook Git pre-commit" -ForegroundColor Green
Write-Host "`nVoulez-vous démarrer la surveillance en temps réel maintenant ? (O/N)" -ForegroundColor Yellow
$startNow = Read-Host

if ($startNow -eq "O" -or $startNow -eq "o") {
    Write-Host "Démarrage de la surveillance..." -ForegroundColor Green
    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$watchScriptPath`""
}
