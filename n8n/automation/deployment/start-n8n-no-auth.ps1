<#
.SYNOPSIS
    Script pour dÃ©marrer n8n sans authentification.

.DESCRIPTION
    Ce script dÃ©marre n8n en dÃ©sactivant complÃ¨tement l'authentification.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  21/04/2025
#>

# DÃ©finir les chemins
$rootPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$n8nPath = Join-Path -Path $rootPath -ChildPath "n8n"
$dataPath = Join-Path -Path $n8nPath -ChildPath "data"
$databasePath = Join-Path -Path $dataPath -ChildPath ".n8n"
$databaseFile = Join-Path -Path $databasePath -ChildPath "database.sqlite"
$envPath = Join-Path -Path $n8nPath -ChildPath ".env"

# VÃ©rifier si le dossier de base de donnÃ©es existe
if (-not (Test-Path -Path $databasePath)) {
    Write-Host "CrÃ©ation du dossier de base de donnÃ©es: $databasePath" -ForegroundColor Yellow
    New-Item -Path $databasePath -ItemType Directory -Force | Out-Null
}

# DÃ©finir les variables d'environnement
$env:N8N_PORT = 5678
$env:N8N_PROTOCOL = "http"
$env:N8N_HOST = "localhost"
$env:N8N_PATH = "/"
$env:N8N_USER_FOLDER = $dataPath
$env:N8N_DATABASE_SQLITE_PATH = $databaseFile
$env:N8N_BASIC_AUTH_ACTIVE = "false"
$env:N8N_USER_MANAGEMENT_DISABLED = "true"
$env:N8N_AUTH_DISABLED = "true"
$env:N8N_DIAGNOSTICS_ENABLED = "false"
$env:N8N_DIAGNOSTICS_CONFIG_ENABLED = "false"
$env:N8N_LOG_LEVEL = "debug"
$env:N8N_WORKFLOW_IMPORT_PATH = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\n8n\core\workflows"
$env:N8N_IMPORT_WORKFLOW_AUTO_ENABLE = "true"
$env:N8N_IMPORT_WORKFLOW_AUTO_UPDATE = "true"
$env:GENERIC_TIMEZONE = "Europe/Paris"
$env:N8N_DEFAULT_LOCALE = "fr"
$env:N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE = "true"

# Afficher les informations de dÃ©marrage
Write-Host "
DÃ©marrage de n8n sans authentification..." -ForegroundColor Cyan
Write-Host "URL: $($env:N8N_PROTOCOL)://$($env:N8N_HOST):$($env:N8N_PORT)$($env:N8N_PATH)"
Write-Host "Dossier des workflows: $($env:N8N_WORKFLOW_IMPORT_PATH)"
Write-Host "Dossier des donnÃ©es: $($env:N8N_USER_FOLDER)"
Write-Host "Base de donnÃ©es: $($env:N8N_DATABASE_SQLITE_PATH)"
Write-Host "Authentification de base: $($env:N8N_BASIC_AUTH_ACTIVE)"
Write-Host "Gestion des utilisateurs dÃ©sactivÃ©e: $($env:N8N_USER_MANAGEMENT_DISABLED)"
Write-Host "
Appuyez sur Ctrl+C pour arrÃªter n8n
"

# DÃ©marrer n8n
npx n8n start
