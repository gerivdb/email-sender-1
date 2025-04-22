<#
.SYNOPSIS
    Script d'installation de n8n en local (sans Docker).

.DESCRIPTION
    Ce script installe n8n en local (sans Docker) et configure les dossiers nécessaires.
    Il utilise npm pour installer n8n globalement.

.PARAMETER Port
    Port sur lequel n8n sera accessible. Par défaut: 5678.

.PARAMETER DisableAuth
    Désactive l'authentification pour n8n.

.EXAMPLE
    .\install-n8n-local.ps1
    .\install-n8n-local.ps1 -Port 5679 -DisableAuth
#>

param (
    [Parameter(Mandatory = $false)]
    [int]$Port = 5678,

    [Parameter(Mandatory = $false)]
    [switch]$DisableAuth = $true
)

# Définir les chemins
$rootPath = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
$configPath = Join-Path -Path $rootPath -ChildPath "config"
$dataPath = Join-Path -Path $rootPath -ChildPath "data"
$n8nConfigPath = Join-Path -Path $configPath -ChildPath "n8n-config.json"
$envPath = Join-Path -Path $rootPath -ChildPath ".env"

# Vérifier si le dossier de configuration existe, sinon le créer
if (-not (Test-Path -Path $configPath)) {
    New-Item -Path $configPath -ItemType Directory -Force | Out-Null
    Write-Host "Dossier de configuration créé: $configPath"
}

# Vérifier si le dossier de données existe, sinon le créer
if (-not (Test-Path -Path $dataPath)) {
    New-Item -Path $dataPath -ItemType Directory -Force | Out-Null
    Write-Host "Dossier de données créé: $dataPath"
}

# Créer les sous-dossiers de données
$credentialsPath = Join-Path -Path $dataPath -ChildPath "credentials"
$databasePath = Join-Path -Path $dataPath -ChildPath "database"
$storagePath = Join-Path -Path $dataPath -ChildPath "storage"

if (-not (Test-Path -Path $credentialsPath)) {
    New-Item -Path $credentialsPath -ItemType Directory -Force | Out-Null
    Write-Host "Dossier de credentials créé: $credentialsPath"
}

if (-not (Test-Path -Path $databasePath)) {
    New-Item -Path $databasePath -ItemType Directory -Force | Out-Null
    Write-Host "Dossier de base de données créé: $databasePath"
}

if (-not (Test-Path -Path $storagePath)) {
    New-Item -Path $storagePath -ItemType Directory -Force | Out-Null
    Write-Host "Dossier de stockage créé: $storagePath"
}

# Vérifier si Node.js est installé
try {
    $nodeVersion = node --version
    Write-Host "Node.js est installé (version $nodeVersion)."
} catch {
    Write-Error "Node.js n'est pas installé. Veuillez installer Node.js avant de continuer."
    Write-Host "Vous pouvez télécharger Node.js à l'adresse: https://nodejs.org/"
    exit 1
}

# Vérifier si npm est installé
try {
    $npmVersion = npm --version
    Write-Host "npm est installé (version $npmVersion)."
} catch {
    Write-Error "npm n'est pas installé. Veuillez installer Node.js et npm avant de continuer."
    Write-Host "Vous pouvez télécharger Node.js à l'adresse: https://nodejs.org/"
    exit 1
}

# Vérifier si n8n est installé
try {
    $n8nVersion = n8n --version
    Write-Host "n8n est installé (version $n8nVersion)."
} catch {
    Write-Host "n8n n'est pas installé. Installation en cours..."
    
    # Installer n8n globalement
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
    dataFolder = $dataPath
    disableAuth = $DisableAuth
    created = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")
}

# Enregistrer la configuration
$n8nConfigJson = $n8nConfig | ConvertTo-Json
Set-Content -Path $n8nConfigPath -Value $n8nConfigJson -Encoding UTF8

Write-Host "Configuration n8n enregistrée dans: $n8nConfigPath"

# Créer le fichier .env pour n8n
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
