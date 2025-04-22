<#
.SYNOPSIS
    Script amélioré pour démarrer n8n avec la nouvelle structure.

.DESCRIPTION
    Ce script démarre n8n en utilisant la nouvelle structure de dossiers et résout les problèmes courants.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  21/04/2025
#>

# Définir les chemins
$rootPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$n8nPath = Join-Path -Path $rootPath -ChildPath "n8n"
$dataPath = Join-Path -Path $n8nPath -ChildPath "data"
$databasePath = Join-Path -Path $dataPath -ChildPath ".n8n"
$databaseFile = Join-Path -Path $databasePath -ChildPath "database.sqlite"
$envPath = Join-Path -Path $n8nPath -ChildPath ".env"

# Vérifier si le dossier de base de données existe
if (-not (Test-Path -Path $databasePath)) {
    Write-Host "Création du dossier de base de données: $databasePath" -ForegroundColor Yellow
    New-Item -Path $databasePath -ItemType Directory -Force | Out-Null
}

# Vérifier si le fichier .env existe
if (-not (Test-Path -Path $envPath)) {
    Write-Error "Le fichier .env n'existe pas: $envPath"
    exit 1
}

# Charger les variables d'environnement
$envContent = Get-Content -Path $envPath
foreach ($line in $envContent) {
    if (-not [string]::IsNullOrWhiteSpace($line) -and -not $line.StartsWith("#")) {
        $key, $value = $line.Split("=", 2)
        [Environment]::SetEnvironmentVariable($key, $value, "Process")
    }
}

# Ajouter des variables d'environnement supplémentaires
[Environment]::SetEnvironmentVariable("N8N_DATABASE_SQLITE_PATH", $databaseFile, "Process")
[Environment]::SetEnvironmentVariable("N8N_USER_FOLDER", $dataPath, "Process")
[Environment]::SetEnvironmentVariable("N8N_BASIC_AUTH_ACTIVE", "false", "Process")
[Environment]::SetEnvironmentVariable("N8N_USER_MANAGEMENT_DISABLED", "true", "Process")
[Environment]::SetEnvironmentVariable("N8N_DIAGNOSTICS_ENABLED", "false", "Process")
[Environment]::SetEnvironmentVariable("N8N_DIAGNOSTICS_CONFIG_ENABLED", "false", "Process")
[Environment]::SetEnvironmentVariable("N8N_LOG_LEVEL", "debug", "Process")

# Afficher les informations de démarrage
Write-Host "`nDémarrage de n8n..." -ForegroundColor Cyan
Write-Host "URL: $($env:N8N_PROTOCOL)://$($env:N8N_HOST):$($env:N8N_PORT)$($env:N8N_PATH)"
Write-Host "Dossier des workflows: $($env:N8N_WORKFLOW_IMPORT_PATH)"
Write-Host "Dossier des données: $($env:N8N_USER_FOLDER)"
Write-Host "Base de données: $($env:N8N_DATABASE_SQLITE_PATH)"
Write-Host "Authentification de base: $($env:N8N_BASIC_AUTH_ACTIVE)"
Write-Host "Gestion des utilisateurs désactivée: $($env:N8N_USER_MANAGEMENT_DISABLED)"
Write-Host "`nAppuyez sur Ctrl+C pour arrêter n8n`n"

# Démarrer n8n
npx n8n start
