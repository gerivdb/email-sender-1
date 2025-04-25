<#
.SYNOPSIS
    Script d'installation et de configuration de n8n.

.DESCRIPTION
    Ce script installe et configure n8n pour une utilisation locale.
    Il crée les dossiers nécessaires et configure les variables d'environnement.

.PARAMETER Port
    Port sur lequel n8n sera accessible. Par défaut: 5678.

.PARAMETER DisableAuth
    Désactive l'authentification pour n8n.

.PARAMETER DataFolder
    Dossier où les données n8n seront stockées. Par défaut: le dossier "data" dans le répertoire racine.

.EXAMPLE
    .\install-n8n.ps1
    .\install-n8n.ps1 -Port 5679 -DisableAuth
    .\install-n8n.ps1 -DataFolder "D:\custom\path\to\data"
#>

param (
    [Parameter(Mandatory = $false)]
    [int]$Port = 5678,

    [Parameter(Mandatory = $false)]
    [switch]$DisableAuth = $true,

    [Parameter(Mandatory = $false)]
    [string]$DataFolder = $null
)

# Définir les chemins
$rootPath = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
$configPath = Join-Path -Path $rootPath -ChildPath "config"
$n8nConfigPath = Join-Path -Path $configPath -ChildPath "n8n-config.json"

# Définir le dossier de données
if (-not $DataFolder) {
    $DataFolder = Join-Path -Path $rootPath -ChildPath "data"
}

# Vérifier si le dossier de configuration existe, sinon le créer
if (-not (Test-Path -Path $configPath)) {
    New-Item -Path $configPath -ItemType Directory -Force | Out-Null
    Write-Host "Dossier de configuration créé: $configPath"
}

# Vérifier si le dossier de données existe, sinon le créer
if (-not (Test-Path -Path $DataFolder)) {
    New-Item -Path $DataFolder -ItemType Directory -Force | Out-Null
    Write-Host "Dossier de données créé: $DataFolder"
}

# Créer les sous-dossiers de données
$credentialsFolder = Join-Path -Path $DataFolder -ChildPath "credentials"
$databaseFolder = Join-Path -Path $DataFolder -ChildPath "database"
$storageFolder = Join-Path -Path $DataFolder -ChildPath "storage"

if (-not (Test-Path -Path $credentialsFolder)) {
    New-Item -Path $credentialsFolder -ItemType Directory -Force | Out-Null
    Write-Host "Dossier de credentials créé: $credentialsFolder"
}

if (-not (Test-Path -Path $databaseFolder)) {
    New-Item -Path $databaseFolder -ItemType Directory -Force | Out-Null
    Write-Host "Dossier de base de données créé: $databaseFolder"
}

if (-not (Test-Path -Path $storageFolder)) {
    New-Item -Path $storageFolder -ItemType Directory -Force | Out-Null
    Write-Host "Dossier de stockage créé: $storageFolder"
}

# Vérifier si npm est installé
try {
    $npmVersion = npm --version
    Write-Host "npm est installé (version $npmVersion)."
} catch {
    Write-Error "npm n'est pas installé. Veuillez installer Node.js et npm avant de continuer."
    exit 1
}

# Vérifier si n8n est installé
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
$n8nConfig = @{
    port = $Port
    dataFolder = $DataFolder
    disableAuth = $DisableAuth
    created = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")
}

# Enregistrer la configuration
$n8nConfigJson = $n8nConfig | ConvertTo-Json
Set-Content -Path $n8nConfigPath -Value $n8nConfigJson -Encoding UTF8

Write-Host "Configuration n8n enregistrée dans: $n8nConfigPath"

# Créer le fichier .env pour n8n
$envPath = Join-Path -Path $rootPath -ChildPath ".env"
$envContent = @"
# Configuration n8n
N8N_PORT=$Port
N8N_PROTOCOL=http
N8N_HOST=localhost
N8N_PATH=/

# Dossiers de données
N8N_USER_FOLDER=$DataFolder
N8N_DIAGNOSTICS_ENABLED=false
N8N_DIAGNOSTICS_CONFIG_ENABLED=false

# Authentification
N8N_BASIC_AUTH_ACTIVE=$(if (-not $DisableAuth) { "true" } else { "false" })
N8N_USER_MANAGEMENT_DISABLED=$(if ($DisableAuth) { "true" } else { "false" })

# Autres paramètres
GENERIC_TIMEZONE=Europe/Paris
N8N_DEFAULT_LOCALE=fr
N8N_LOG_LEVEL=info
"@

Set-Content -Path $envPath -Value $envContent -Encoding UTF8

Write-Host "Fichier .env créé: $envPath"

# Générer une clé API si l'authentification est désactivée
if ($DisableAuth) {
    $createApiKeyScript = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "create-api-key.ps1"
    if (Test-Path -Path $createApiKeyScript) {
        & $createApiKeyScript -Force
    } else {
        Write-Warning "Le script create-api-key.ps1 n'a pas été trouvé. Veuillez créer une clé API manuellement."
    }
}

Write-Host ""
Write-Host "Installation et configuration de n8n terminées."
Write-Host "Pour démarrer n8n, exécutez: .\scripts\start-n8n.ps1"
