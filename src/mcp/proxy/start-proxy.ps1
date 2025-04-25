# Script de démarrage du proxy MCP unifié
# Auteur: Augment Agent
# Date: 20/04/2025

# Vérifier si Node.js est installé
try {
    $nodeVersion = node -v
    Write-Host "Node.js version $nodeVersion détectée"
}
catch {
    Write-Error "Node.js n'est pas installé ou n'est pas dans le PATH. Veuillez installer Node.js avant de continuer."
    exit 1
}

# Vérifier si npm est installé
try {
    $npmVersion = npm -v
    Write-Host "npm version $npmVersion détectée"
}
catch {
    Write-Error "npm n'est pas installé ou n'est pas dans le PATH. Veuillez installer npm avant de continuer."
    exit 1
}

# Définir le répertoire du proxy
$proxyDir = $PSScriptRoot

# Vérifier si le répertoire node_modules existe
if (-not (Test-Path -Path "$proxyDir\node_modules")) {
    Write-Host "Installation des dépendances..."
    Set-Location $proxyDir
    npm install
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Erreur lors de l'installation des dépendances."
        exit 1
    }
    
    Write-Host "Dépendances installées avec succès."
}

# Vérifier si le fichier de configuration existe
if (-not (Test-Path -Path "$proxyDir\config\default.json")) {
    Write-Error "Fichier de configuration introuvable: $proxyDir\config\default.json"
    exit 1
}

# Démarrer le proxy
Write-Host "Démarrage du proxy MCP unifié..."
Set-Location $proxyDir

# Récupérer la configuration
$config = Get-Content -Path "$proxyDir\config\default.json" | ConvertFrom-Json
$port = $config.server.port
$host = $config.server.host

# Afficher les informations de démarrage
Write-Host "Le proxy sera accessible à l'adresse: http://$host`:$port"
Write-Host "Interface web: http://$host`:$port/ui"
Write-Host "Endpoints API: http://$host`:$port/api/proxy/status, http://$host`:$port/health"

# Démarrer le serveur
npm start

# Gérer la sortie
if ($LASTEXITCODE -ne 0) {
    Write-Error "Erreur lors du démarrage du proxy."
    exit 1
}
