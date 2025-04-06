# Script simplifié pour configurer le token GitHub
# Ce script permet de configurer facilement le token GitHub sans utiliser de saisie sécurisée

Write-Host "=== Configuration simplifiée du token GitHub pour MCP ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Ce script va vous aider à configurer le token GitHub pour le serveur MCP GitHub." -ForegroundColor Yellow
Write-Host "Le token sera stocké dans un fichier .env à la racine du projet." -ForegroundColor Yellow
Write-Host ""

# Demander le token GitHub
Write-Host "Entrez votre token GitHub (vous pouvez le coller avec Ctrl+V) :" -ForegroundColor Green
$githubToken = Read-Host

if ([string]::IsNullOrEmpty($githubToken)) {
    Write-Host "Aucun token GitHub fourni. Configuration annulée." -ForegroundColor Red
    exit 1
}

# Lire le fichier .env existant
$envPath = Join-Path $PSScriptRoot "..\..\\.env"
$envExists = Test-Path $envPath
$envContent = ""

if ($envExists) {
    $envContent = Get-Content -Path $envPath -Raw
    
    # Remplacer ou ajouter le token GitHub
    if ($envContent -match "GITHUB_TOKEN=([^\r\n]*)") {
        $envContent = $envContent -replace "GITHUB_TOKEN=([^\r\n]*)", "GITHUB_TOKEN=$githubToken"
    } else {
        $envContent += "`nGITHUB_TOKEN=$githubToken`n"
    }
} else {
    # Créer un nouveau fichier .env
    $envContent = "# Configuration GitHub pour l'intégration avec MCP`nGITHUB_TOKEN=$githubToken`n"
}

# Écrire le fichier .env
Set-Content -Path $envPath -Value $envContent
Write-Host ""
Write-Host "✅ Token GitHub configuré avec succès dans le fichier .env" -ForegroundColor Green
Write-Host "Vous pouvez maintenant utiliser le serveur MCP GitHub avec votre token." -ForegroundColor Green

# Tester la configuration
Write-Host ""
Write-Host "Voulez-vous tester la configuration en démarrant le serveur MCP GitHub ? (O/N)" -ForegroundColor Yellow
$testConfig = Read-Host

if ($testConfig -eq "O" -or $testConfig -eq "o") {
    Write-Host "Démarrage du serveur MCP GitHub..." -ForegroundColor Cyan
    Write-Host "Appuyez sur Ctrl+C pour arrêter le serveur." -ForegroundColor Yellow
    Write-Host ""
    
    # Définir la variable d'environnement pour ce processus
    $env:GITHUB_TOKEN = $githubToken
    
    # Exécuter la commande
    mcp-server-github
}
