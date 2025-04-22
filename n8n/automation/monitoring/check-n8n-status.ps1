<#
.SYNOPSIS
    Script pour vérifier l'état de n8n.

.DESCRIPTION
    Ce script vérifie si n8n est en cours d'exécution et accessible.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  21/04/2025
#>

# Vérifier si n8n est en cours d'exécution
try {
    $health = Invoke-RestMethod -Uri "http://localhost:5678/healthz" -Method Get -ErrorAction Stop
    Write-Host "n8n est en cours d'exécution. Statut: $($health.status)" -ForegroundColor Green
} catch {
    Write-Host "n8n n'est pas en cours d'exécution ou n'est pas accessible." -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
    exit 1
}

# Vérifier si l'API est accessible
try {
    $response = Invoke-RestMethod -Uri "http://localhost:5678/rest/settings" -Method Get -ErrorAction Stop
    Write-Host "L'API n8n est accessible." -ForegroundColor Green
    Write-Host "Version n8n: $($response.version)" -ForegroundColor Green
    Write-Host "Mode d'exécution: $($response.executionMode)" -ForegroundColor Green
    Write-Host "Authentification de base: $($response.basicAuthActive)" -ForegroundColor Green
    Write-Host "Gestion des utilisateurs désactivée: $($response.userManagementDisabled)" -ForegroundColor Green
} catch {
    Write-Host "L'API n8n n'est pas accessible." -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Vérifier si les workflows sont accessibles
try {
    $workflows = Invoke-RestMethod -Uri "http://localhost:5678/rest/workflows" -Method Get -ErrorAction Stop
    Write-Host "Les workflows sont accessibles." -ForegroundColor Green
    Write-Host "Nombre de workflows: $($workflows.Count)" -ForegroundColor Green
    
    if ($workflows.Count -gt 0) {
        Write-Host "`nListe des workflows:" -ForegroundColor Cyan
        foreach ($workflow in $workflows) {
            $status = if ($workflow.active) { "Actif" } else { "Inactif" }
            Write-Host "- $($workflow.name) ($status)" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "Les workflows ne sont pas accessibles." -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Vérifier les dossiers de données
Write-Host "`n=== Vérification des dossiers de données ===" -ForegroundColor Cyan
$dataPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\n8n\data"
$databasePath = Join-Path -Path $dataPath -ChildPath "database\n8n.sqlite"

if (Test-Path -Path $dataPath) {
    Write-Host "Le dossier de données existe: $dataPath" -ForegroundColor Green
} else {
    Write-Host "Le dossier de données n'existe pas: $dataPath" -ForegroundColor Red
}

if (Test-Path -Path $databasePath) {
    Write-Host "La base de données existe: $databasePath" -ForegroundColor Green
    $dbSize = (Get-Item -Path $databasePath).Length / 1KB
    Write-Host "Taille de la base de données: $([Math]::Round($dbSize, 2)) KB" -ForegroundColor Green
} else {
    Write-Host "La base de données n'existe pas: $databasePath" -ForegroundColor Red
}

# Vérifier les processus n8n
Write-Host "`n=== Vérification des processus n8n ===" -ForegroundColor Cyan
$n8nProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*n8n*" }

if ($n8nProcesses) {
    Write-Host "Nombre de processus n8n en cours d'exécution: $($n8nProcesses.Count)" -ForegroundColor Green
    foreach ($process in $n8nProcesses) {
        Write-Host "- PID: $($process.Id), Mémoire: $([Math]::Round($process.WorkingSet / 1MB, 2)) MB" -ForegroundColor Green
    }
} else {
    Write-Host "Aucun processus n8n en cours d'exécution." -ForegroundColor Red
}
