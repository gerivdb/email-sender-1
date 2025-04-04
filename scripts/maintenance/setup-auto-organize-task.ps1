# Script pour configurer une tache planifiee pour l'organisation automatique des fichiers

Write-Host "=== Configuration de la tache planifiee pour l'organisation automatique ===" -ForegroundColor Cyan

# Obtenir le chemin absolu du script auto-organize.ps1
$scriptPath = (Resolve-Path ".\scripts\maintenance\auto-organize.ps1").Path

# Nom de la tache
$taskName = "N8N_AutoOrganize"

# Verifier si la tache existe deja
$taskExists = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if ($taskExists) {
    Write-Host "La tache $taskName existe deja. Voulez-vous la remplacer ? (O/N)" -ForegroundColor Yellow
    $confirmation = Read-Host
    
    if ($confirmation -ne "O" -and $confirmation -ne "o") {
        Write-Host "Configuration annulee" -ForegroundColor Red
        exit
    }
    
    # Supprimer la tache existante
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Write-Host "Tache existante supprimee" -ForegroundColor Green
}

# Creer l'action
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`""

# Creer le declencheur (tous les jours a 9h00)
$trigger = New-ScheduledTaskTrigger -Daily -At 9am

# Creer les parametres
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -AllowStartIfOnBatteries

# Creer la tache
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Description "Organise automatiquement les fichiers du projet N8N Email Sender"

Write-Host "Tache planifiee $taskName creee avec succes" -ForegroundColor Green
Write-Host "La tache s'executera tous les jours a 9h00" -ForegroundColor Green
Write-Host "Vous pouvez modifier les parametres de la tache dans le Planificateur de taches Windows" -ForegroundColor Yellow

Write-Host "`n=== Configuration terminee ===" -ForegroundColor Cyan
