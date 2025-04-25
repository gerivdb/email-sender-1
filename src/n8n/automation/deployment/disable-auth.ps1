<#
.SYNOPSIS
    Script pour désactiver complètement l'authentification n8n.

.DESCRIPTION
    Ce script désactive complètement l'authentification n8n en modifiant les fichiers de configuration.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  21/04/2025
#>

# Définir les chemins
$rootPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$n8nPath = Join-Path -Path $rootPath -ChildPath "n8n"
$configPath = Join-Path -Path $n8nPath -ChildPath "core\n8n-config.json"
$envPath = Join-Path -Path $n8nPath -ChildPath ".env"

# Vérifier si le fichier de configuration existe
if (-not (Test-Path -Path $configPath)) {
    Write-Error "Le fichier de configuration n'existe pas: $configPath"
    exit 1
}

# Mettre à jour le fichier de configuration
Write-Host "Mise à jour du fichier de configuration: $configPath" -ForegroundColor Cyan
$config = Get-Content -Path $configPath -Raw | ConvertFrom-Json

# Désactiver l'authentification de base
$config.security.basicAuth.active = $false

# Désactiver la gestion des utilisateurs
$config.security.userManagement.disabled = $true

# Enregistrer le fichier de configuration
$configJson = $config | ConvertTo-Json -Depth 10
Set-Content -Path $configPath -Value $configJson -Encoding UTF8

Write-Host "Fichier de configuration mis à jour." -ForegroundColor Green

# Mettre à jour le fichier .env
Write-Host "Mise à jour du fichier .env: $envPath" -ForegroundColor Cyan
$envContent = Get-Content -Path $envPath

# Mettre à jour les variables d'authentification
$envContent = $envContent -replace "N8N_BASIC_AUTH_ACTIVE=.*", "N8N_BASIC_AUTH_ACTIVE=false"
$envContent = $envContent -replace "N8N_USER_MANAGEMENT_DISABLED=.*", "N8N_USER_MANAGEMENT_DISABLED=true"

# Ajouter des variables supplémentaires
if (-not ($envContent -match "N8N_AUTH_DISABLED")) {
    $envContent += "`nN8N_AUTH_DISABLED=true"
}

# Enregistrer le fichier .env
Set-Content -Path $envPath -Value $envContent -Encoding UTF8

Write-Host "Fichier .env mis à jour." -ForegroundColor Green

# Créer un script de démarrage sans authentification
$startScriptPath = Join-Path -Path $n8nPath -ChildPath "automation\deployment\start-n8n-no-auth.ps1"
$startScriptContent = @"
<#
.SYNOPSIS
    Script pour démarrer n8n sans authentification.

.DESCRIPTION
    Ce script démarre n8n en désactivant complètement l'authentification.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  21/04/2025
#>

# Définir les chemins
`$rootPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
`$n8nPath = Join-Path -Path `$rootPath -ChildPath "n8n"
`$dataPath = Join-Path -Path `$n8nPath -ChildPath "data"
`$databasePath = Join-Path -Path `$dataPath -ChildPath ".n8n"
`$databaseFile = Join-Path -Path `$databasePath -ChildPath "database.sqlite"
`$envPath = Join-Path -Path `$n8nPath -ChildPath ".env"

# Vérifier si le dossier de base de données existe
if (-not (Test-Path -Path `$databasePath)) {
    Write-Host "Création du dossier de base de données: `$databasePath" -ForegroundColor Yellow
    New-Item -Path `$databasePath -ItemType Directory -Force | Out-Null
}

# Définir les variables d'environnement
`$env:N8N_PORT = 5678
`$env:N8N_PROTOCOL = "http"
`$env:N8N_HOST = "localhost"
`$env:N8N_PATH = "/"
`$env:N8N_USER_FOLDER = `$dataPath
`$env:N8N_DATABASE_SQLITE_PATH = `$databaseFile
`$env:N8N_BASIC_AUTH_ACTIVE = "false"
`$env:N8N_USER_MANAGEMENT_DISABLED = "true"
`$env:N8N_AUTH_DISABLED = "true"
`$env:N8N_DIAGNOSTICS_ENABLED = "false"
`$env:N8N_DIAGNOSTICS_CONFIG_ENABLED = "false"
`$env:N8N_LOG_LEVEL = "debug"
`$env:N8N_WORKFLOW_IMPORT_PATH = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\n8n\core\workflows"
`$env:N8N_IMPORT_WORKFLOW_AUTO_ENABLE = "true"
`$env:N8N_IMPORT_WORKFLOW_AUTO_UPDATE = "true"
`$env:GENERIC_TIMEZONE = "Europe/Paris"
`$env:N8N_DEFAULT_LOCALE = "fr"
`$env:N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE = "true"

# Afficher les informations de démarrage
Write-Host "`nDémarrage de n8n sans authentification..." -ForegroundColor Cyan
Write-Host "URL: `$(`$env:N8N_PROTOCOL)://`$(`$env:N8N_HOST):`$(`$env:N8N_PORT)`$(`$env:N8N_PATH)"
Write-Host "Dossier des workflows: `$(`$env:N8N_WORKFLOW_IMPORT_PATH)"
Write-Host "Dossier des données: `$(`$env:N8N_USER_FOLDER)"
Write-Host "Base de données: `$(`$env:N8N_DATABASE_SQLITE_PATH)"
Write-Host "Authentification de base: `$(`$env:N8N_BASIC_AUTH_ACTIVE)"
Write-Host "Gestion des utilisateurs désactivée: `$(`$env:N8N_USER_MANAGEMENT_DISABLED)"
Write-Host "`nAppuyez sur Ctrl+C pour arrêter n8n`n"

# Démarrer n8n
npx n8n start
"@

Set-Content -Path $startScriptPath -Value $startScriptContent -Encoding UTF8

Write-Host "Script de démarrage sans authentification créé: $startScriptPath" -ForegroundColor Green

# Créer un script CMD pour démarrer n8n sans authentification
$startCmdPath = Join-Path -Path $n8nPath -ChildPath "automation\deployment\start-n8n-no-auth.cmd"
$startCmdContent = @"
@echo off
echo Demarrage de n8n sans authentification...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0\start-n8n-no-auth.ps1"
"@

Set-Content -Path $startCmdPath -Value $startCmdContent -Encoding UTF8

Write-Host "Script CMD de démarrage sans authentification créé: $startCmdPath" -ForegroundColor Green

# Créer un script à la racine du projet
$rootStartCmdPath = Join-Path -Path $rootPath -ChildPath "start-n8n-no-auth.cmd"
$rootStartCmdContent = @"
@echo off
echo Demarrage de n8n sans authentification...
echo.
cd /d "%~dp0"
call n8n\automation\deployment\start-n8n-no-auth.cmd
"@

Set-Content -Path $rootStartCmdPath -Value $rootStartCmdContent -Encoding UTF8

Write-Host "Script de démarrage sans authentification créé à la racine: $rootStartCmdPath" -ForegroundColor Green

Write-Host "`nL'authentification a été désactivée avec succès." -ForegroundColor Green
Write-Host "Pour démarrer n8n sans authentification, exécutez: $rootStartCmdPath" -ForegroundColor Yellow
