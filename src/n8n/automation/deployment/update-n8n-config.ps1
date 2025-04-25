<#
.SYNOPSIS
    Script de mise à jour de la configuration n8n.

.DESCRIPTION
    Ce script met à jour les fichiers de configuration n8n pour refléter la nouvelle structure.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  21/04/2025
#>

# Définir les chemins
$rootPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$n8nPath = Join-Path -Path $rootPath -ChildPath "n8n"
$n8nConfigPath = Join-Path -Path $n8nPath -ChildPath "core\n8n-config.json"
$envPath = Join-Path -Path $n8nPath -ChildPath ".env"

# Vérifier si le fichier de configuration existe
if (-not (Test-Path -Path $n8nConfigPath)) {
    Write-Error "Le fichier de configuration n8n-config.json n'existe pas."
    exit 1
}

# Lire la configuration
$config = Get-Content -Path $n8nConfigPath -Raw | ConvertFrom-Json

# Mettre à jour les chemins
$dataPath = Join-Path -Path $n8nPath -ChildPath "data"
$config.userFolder = $dataPath
$config.database.sqlite.path = Join-Path -Path $dataPath -ChildPath "database.sqlite"

# Enregistrer la configuration
$configJson = $config | ConvertTo-Json -Depth 10
Set-Content -Path $n8nConfigPath -Value $configJson -Encoding UTF8

Write-Host "Fichier n8n-config.json mis à jour: $n8nConfigPath"

# Créer le contenu du fichier .env
$envContent = @"
# Configuration n8n
N8N_PORT=$($config.port)
N8N_PROTOCOL=$($config.protocol)
N8N_HOST=$($config.host)
N8N_PATH=$($config.path)

# Dossiers de données
N8N_USER_FOLDER=$dataPath
N8N_DIAGNOSTICS_ENABLED=false
N8N_DIAGNOSTICS_CONFIG_ENABLED=false

# Authentification
N8N_BASIC_AUTH_ACTIVE=false
N8N_USER_MANAGEMENT_DISABLED=true

# Workflows
N8N_WORKFLOW_IMPORT_PATH=$(Join-Path -Path $n8nPath -ChildPath "core\workflows")
N8N_IMPORT_WORKFLOW_AUTO_ENABLE=true
N8N_IMPORT_WORKFLOW_AUTO_UPDATE=true

# Autres paramètres
GENERIC_TIMEZONE=Europe/Paris
N8N_DEFAULT_LOCALE=fr
N8N_LOG_LEVEL=info
N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
"@

# Enregistrer le fichier .env
Set-Content -Path $envPath -Value $envContent -Encoding UTF8

Write-Host "Fichier .env créé: $envPath"
