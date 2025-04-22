<#
.SYNOPSIS
    Script pour démarrer n8n.

.DESCRIPTION
    Ce script démarre n8n avec la configuration spécifiée dans le fichier n8n-config.json.

.PARAMETER Tunnel
    Démarre n8n avec un tunnel pour le rendre accessible depuis Internet.

.EXAMPLE
    .\start-n8n.ps1
    .\start-n8n.ps1 -Tunnel
#>

param (
    [Parameter(Mandatory = $false)]
    [switch]$Tunnel
)

# Définir les chemins
$rootPath = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$configPath = Join-Path -Path $rootPath -ChildPath "config"
$n8nConfigPath = Join-Path -Path $configPath -ChildPath "n8n-config.json"
$envPath = Join-Path -Path $rootPath -ChildPath ".env"

# Vérifier si le fichier de configuration existe
if (-not (Test-Path -Path $n8nConfigPath)) {
    Write-Error "Le fichier de configuration n8n-config.json n'existe pas. Veuillez exécuter .\scripts\setup\install-n8n.ps1 d'abord."
    exit 1
}

# Lire la configuration
$config = Get-Content -Path $n8nConfigPath -Raw | ConvertFrom-Json

# Vérifier si n8n est déjà en cours d'exécution
try {
    $response = Invoke-WebRequest -Uri "http://localhost:$($config.port)/healthz" -Method Get -TimeoutSec 2 -ErrorAction SilentlyContinue
    if ($response.StatusCode -eq 200) {
        Write-Host "n8n est déjà en cours d'exécution sur le port $($config.port)."
        Write-Host "Accédez à n8n à l'adresse: http://localhost:$($config.port)"
        exit 0
    }
} catch {
    # n8n n'est pas en cours d'exécution, c'est normal
}

# Vérifier si le fichier .env existe
if (-not (Test-Path -Path $envPath)) {
    Write-Warning "Le fichier .env n'existe pas. Création d'un fichier .env par défaut."
    
    $envContent = @"
# Configuration n8n
N8N_PORT=$($config.port)
N8N_PROTOCOL=http
N8N_HOST=localhost
N8N_PATH=/

# Dossiers de données
N8N_USER_FOLDER=$($config.dataFolder)
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

    Set-Content -Path $envPath -Value $envContent -Encoding UTF8
    Write-Host "Fichier .env créé: $envPath"
}

# Démarrer n8n
Write-Host "Démarrage de n8n sur le port $($config.port)..."

if ($Tunnel) {
    Write-Host "Démarrage de n8n avec un tunnel..."
    Start-Process -FilePath "n8n" -ArgumentList "start", "--tunnel" -NoNewWindow
} else {
    Start-Process -FilePath "n8n" -ArgumentList "start" -NoNewWindow
}

# Attendre que n8n soit prêt
$maxAttempts = 30
$attempts = 0
$ready = $false

Write-Host "Attente du démarrage de n8n..."
while (-not $ready -and $attempts -lt $maxAttempts) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:$($config.port)/healthz" -Method Get -TimeoutSec 2 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            $ready = $true
        }
    } catch {
        # n8n n'est pas encore prêt
    }
    
    $attempts++
    Start-Sleep -Seconds 1
}

if ($ready) {
    Write-Host "n8n est prêt!"
    Write-Host "Accédez à n8n à l'adresse: http://localhost:$($config.port)"
    
    # Ouvrir n8n dans le navigateur par défaut
    Start-Process "http://localhost:$($config.port)"
} else {
    Write-Warning "n8n n'a pas démarré dans le délai imparti. Vérifiez manuellement à l'adresse: http://localhost:$($config.port)"
}

Write-Host ""
Write-Host "Pour arrêter n8n, appuyez sur Ctrl+C dans la fenêtre de terminal où n8n est en cours d'exécution."
Write-Host "Ou exécutez: .\scripts\stop-n8n.ps1"
