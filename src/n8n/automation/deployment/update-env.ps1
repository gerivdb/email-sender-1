<#
.SYNOPSIS
    Script pour mettre à jour le fichier .env après la migration.

.DESCRIPTION
    Ce script met à jour le fichier .env pour refléter la nouvelle structure de dossiers.

.EXAMPLE
    .\update-env.ps1
#>

# Définir les chemins
$rootPath = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
$configPath = Join-Path -Path $rootPath -ChildPath "config"
$dataPath = Join-Path -Path $rootPath -ChildPath "data"
$n8nConfigPath = Join-Path -Path $configPath -ChildPath "n8n-config.json"
$envPath = Join-Path -Path $rootPath -ChildPath ".env"

# Vérifier si le fichier de configuration existe
if (-not (Test-Path -Path $n8nConfigPath)) {
    Write-Error "Le fichier de configuration n8n-config.json n'existe pas. Veuillez exécuter .\scripts\setup\install-n8n-local.ps1 d'abord."
    exit 1
}

# Lire la configuration
$config = Get-Content -Path $n8nConfigPath -Raw | ConvertFrom-Json

# Créer le contenu du fichier .env
$envContent = @"
# Configuration n8n
N8N_PORT=$($config.port)
N8N_PROTOCOL=http
N8N_HOST=localhost
N8N_PATH=/

# Dossiers de données
N8N_USER_FOLDER=$dataPath
N8N_DIAGNOSTICS_ENABLED=false
N8N_DIAGNOSTICS_CONFIG_ENABLED=false

# Authentification
N8N_BASIC_AUTH_ACTIVE=$(if (-not $config.disableAuth) { "true" } else { "false" })
N8N_USER_MANAGEMENT_DISABLED=$(if ($config.disableAuth) { "true" } else { "false" })

# Autres paramètres
GENERIC_TIMEZONE=Europe/Paris
N8N_DEFAULT_LOCALE=fr
N8N_LOG_LEVEL=info
"@

# Enregistrer le fichier .env
Set-Content -Path $envPath -Value $envContent -Encoding UTF8

Write-Host "Fichier .env mis à jour: $envPath"
