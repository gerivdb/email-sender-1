<#
.SYNOPSIS
    Script pour créer une clé API pour n8n.

.DESCRIPTION
    Ce script génère une nouvelle clé API pour n8n et l'enregistre dans un fichier de configuration.

.PARAMETER Force
    Force la création d'une nouvelle clé API même si une existe déjà.

.EXAMPLE
    .\create-api-key.ps1
    .\create-api-key.ps1 -Force
#>

param (
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Définir les chemins
$rootPath = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
$configPath = Join-Path -Path $rootPath -ChildPath "config"
$apiKeyPath = Join-Path -Path $configPath -ChildPath "api-key.json"

# Vérifier si le dossier de configuration existe, sinon le créer
if (-not (Test-Path -Path $configPath)) {
    New-Item -Path $configPath -ItemType Directory -Force | Out-Null
    Write-Host "Dossier de configuration créé: $configPath"
}

# Vérifier si une clé API existe déjà
if ((Test-Path -Path $apiKeyPath) -and -not $Force) {
    $apiKeyObject = Get-Content -Path $apiKeyPath -Raw | ConvertFrom-Json
    Write-Host "Une clé API existe déjà: $($apiKeyObject.apiKey)"
    Write-Host "Utilisez le paramètre -Force pour générer une nouvelle clé."
    exit 0
}

# Générer une nouvelle clé API
$apiKey = [System.Guid]::NewGuid().ToString("N")

# Créer l'objet de configuration
$apiKeyObject = @{
    apiKey = $apiKey
    created = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")
}

# Enregistrer la clé API
$apiKeyJson = $apiKeyObject | ConvertTo-Json
Set-Content -Path $apiKeyPath -Value $apiKeyJson -Encoding UTF8

Write-Host "Nouvelle clé API générée: $apiKey"
Write-Host "La clé API a été enregistrée dans: $apiKeyPath"

# Afficher les instructions pour configurer n8n
Write-Host ""
Write-Host "Pour utiliser cette clé API avec n8n, ajoutez la variable d'environnement suivante:"
Write-Host "N8N_API_KEY=$apiKey"
Write-Host ""
Write-Host "Ou ajoutez-la à votre fichier .env:"
Write-Host "N8N_API_KEY=$apiKey"
