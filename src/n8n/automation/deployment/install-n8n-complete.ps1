<#
.SYNOPSIS
    Script d'installation complète de n8n avec la nouvelle structure.

.DESCRIPTION
    Ce script installe n8n, crée la nouvelle structure de dossiers, migre les fichiers existants et configure l'environnement.

.PARAMETER Port
    Port sur lequel n8n sera accessible (par défaut: 5678).

.PARAMETER DisableAuth
    Désactive l'authentification n8n (par défaut: $true).

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  21/04/2025
#>

param (
    [Parameter(Mandatory = $false)]
    [int]$Port = 5678,
    
    [Parameter(Mandatory = $false)]
    [bool]$DisableAuth = $true
)

# Définir les chemins
$rootPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$n8nPath = Join-Path -Path $rootPath -ChildPath "n8n"
$dataPath = Join-Path -Path $n8nPath -ChildPath "data"
$configPath = Join-Path -Path $n8nPath -ChildPath "core"
$n8nConfigPath = Join-Path -Path $configPath -ChildPath "n8n-config.json"
$envPath = Join-Path -Path $n8nPath -ChildPath ".env"

# Fonction pour créer un dossier s'il n'existe pas
function Confirm-FolderExists {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path)) {
        Write-Host "Création du dossier $Path..."
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
    }
}

# Créer la structure de dossiers
Write-Host "`n=== Création de la structure de dossiers ===" -ForegroundColor Cyan
$n8nFolders = @(
    "n8n/core",
    "n8n/core/workflows",
    "n8n/core/workflows/local",
    "n8n/core/workflows/ide",
    "n8n/core/credentials",
    "n8n/core/triggers",
    "n8n/integrations",
    "n8n/integrations/mcp",
    "n8n/integrations/ide",
    "n8n/integrations/api",
    "n8n/automation",
    "n8n/automation/deployment",
    "n8n/automation/maintenance",
    "n8n/automation/monitoring",
    "n8n/docs",
    "n8n/docs/architecture",
    "n8n/docs/workflows",
    "n8n/docs/api",
    "n8n/data",
    "n8n/data/database",
    "n8n/data/storage"
)

foreach ($folder in $n8nFolders) {
    Confirm-FolderExists -Path (Join-Path -Path $rootPath -ChildPath $folder)
}

# Vérifier si n8n est installé
Write-Host "`n=== Vérification de l'installation de n8n ===" -ForegroundColor Cyan
try {
    $n8nVersion = n8n --version
    Write-Host "n8n est installé (version $n8nVersion)."
} catch {
    Write-Host "n8n n'est pas installé. Installation en cours..."
    npm install -g n8n
    
    # Vérifier si l'installation a réussi
    try {
        $n8nVersion = n8n --version
        Write-Host "n8n a été installé avec succès (version $n8nVersion)."
    } catch {
        Write-Error "Échec de l'installation de n8n. Veuillez l'installer manuellement avec 'npm install -g n8n'."
        exit 1
    }
}

# Créer le fichier de configuration n8n
Write-Host "`n=== Création du fichier de configuration n8n ===" -ForegroundColor Cyan
$n8nConfig = @{
    port = $Port
    protocol = "http"
    host = "localhost"
    baseUrl = "/"
    path = "/"
    userFolder = $dataPath
    database = @{
        type = "sqlite"
        sqlite = @{
            path = Join-Path -Path $dataPath -ChildPath "database.sqlite"
        }
    }
    disableAuth = $DisableAuth
    created = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")
}

$configJson = $n8nConfig | ConvertTo-Json -Depth 10
Set-Content -Path $n8nConfigPath -Value $configJson -Encoding UTF8

Write-Host "Fichier de configuration n8n créé: $n8nConfigPath"

# Créer le fichier .env
Write-Host "`n=== Création du fichier .env ===" -ForegroundColor Cyan
$envContent = @"
# Configuration n8n
N8N_PORT=$Port
N8N_PROTOCOL=http
N8N_HOST=localhost
N8N_PATH=/

# Dossiers de données
N8N_USER_FOLDER=$dataPath
N8N_DIAGNOSTICS_ENABLED=false
N8N_DIAGNOSTICS_CONFIG_ENABLED=false

# Authentification
N8N_BASIC_AUTH_ACTIVE=$(if (-not $DisableAuth) { "true" } else { "false" })
N8N_USER_MANAGEMENT_DISABLED=$(if ($DisableAuth) { "true" } else { "false" })

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

Set-Content -Path $envPath -Value $envContent -Encoding UTF8

Write-Host "Fichier .env créé: $envPath"

# Migrer les fichiers existants
Write-Host "`n=== Migration des fichiers existants ===" -ForegroundColor Cyan
$migrateScriptPath = Join-Path -Path $n8nPath -ChildPath "automation\deployment\migrate-n8n-structure.ps1"
if (Test-Path -Path $migrateScriptPath) {
    & $migrateScriptPath
} else {
    Write-Warning "Le script de migration n'existe pas: $migrateScriptPath"
    Write-Warning "Veuillez migrer manuellement les fichiers existants."
}

# Créer le script de démarrage à la racine
Write-Host "`n=== Création du script de démarrage ===" -ForegroundColor Cyan
$startScriptContent = @"
@echo off
echo Demarrage de n8n avec la nouvelle structure...
echo.
cd /d "%~dp0"
call n8n\automation\deployment\start-n8n.cmd
"@

$startScriptPath = Join-Path -Path $rootPath -ChildPath "start-n8n-new.cmd"
Set-Content -Path $startScriptPath -Value $startScriptContent -Encoding ASCII

Write-Host "Script de démarrage créé: $startScriptPath"

Write-Host "`n=== Installation terminée ===" -ForegroundColor Green
Write-Host "Pour démarrer n8n, exécutez: $startScriptPath"

