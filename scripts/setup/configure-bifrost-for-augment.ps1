# Script pour configurer BifrostMCP dans Augment Settings

Write-Host "=== Configuration de BifrostMCP pour Augment ===" -ForegroundColor Cyan

# Verifier si supergateway est installe
try {
    $supergatewayVersion = (supergateway --version) 2>&1
    if ($supergatewayVersion -match "\d+\.\d+\.\d+") {
        Write-Host "âœ… supergateway version $supergatewayVersion est installe" -ForegroundColor Green
    } else {
        Write-Host "âŒ supergateway n'est pas correctement installe" -ForegroundColor Red
        Write-Host "Installation de supergateway..." -ForegroundColor Yellow
        npm install -g supergateway
    }
} catch {
    Write-Host "âŒ supergateway n'est pas installe" -ForegroundColor Red
    Write-Host "Installation de supergateway..." -ForegroundColor Yellow
    npm install -g supergateway
}

# Verifier si le fichier bifrost.config.json existe
$bifrostConfigPath = ".\bifrost.config.json"
if (-not (Test-Path $bifrostConfigPath)) {
    Write-Host "âŒ Le fichier bifrost.config.json n'existe pas" -ForegroundColor Red
    Write-Host "Creez d'abord le fichier bifrost.config.json a la racine du projet" -ForegroundColor Yellow
    exit 1
}

# Lire le fichier de configuration
$bifrostConfig = Get-Content -Path $bifrostConfigPath -Raw | ConvertFrom-Json
$port = $bifrostConfig.port
$path = $bifrostConfig.path
$projectName = $bifrostConfig.projectName

Write-Host "`nInformations pour configurer BifrostMCP dans Augment Settings :" -ForegroundColor Cyan
Write-Host "-------------------------------------------------------" -ForegroundColor Cyan
Write-Host "Name    : Bifrost" -ForegroundColor Yellow
Write-Host "Command : supergateway --sse http://localhost:$port$path/sse" -ForegroundColor Yellow
Write-Host "-------------------------------------------------------" -ForegroundColor Cyan

Write-Host "`nInstructions :" -ForegroundColor Cyan
Write-Host "1. Ouvrez VSCode"
Write-Host "2. Cliquez sur l'icone Augment dans la barre laterale"
Write-Host "3. Cliquez sur l'icone d'engrenage (âš™ï¸) pour ouvrir les parametres"
Write-Host "4. Dans la section MCP Servers, ajoutez un nouveau serveur avec les informations ci-dessus"
Write-Host "5. Sauvegardez les parametres"

Write-Host "`nPour verifier que BifrostMCP fonctionne correctement :" -ForegroundColor Cyan
Write-Host "1. Demarrez le serveur BifrostMCP dans VSCode avec la commande 'Bifrost MCP: Start Server'"
Write-Host "2. Ouvrez une conversation avec Claude dans Augment"
Write-Host "3. Demandez a Claude d'utiliser une fonctionnalite de BifrostMCP, comme trouver des references a un symbole"

Write-Host "`n=== Configuration terminee ===" -ForegroundColor Cyan
