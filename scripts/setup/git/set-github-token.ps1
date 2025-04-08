# Script simplifiÃ© pour configurer le token GitHub
# Ce script permet de configurer facilement le token GitHub sans utiliser de saisie sÃ©curisÃ©e

Write-Host "=== Configuration simplifiÃ©e du token GitHub pour MCP ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Ce script va vous aider Ã  configurer le token GitHub pour le serveur MCP GitHub." -ForegroundColor Yellow
Write-Host "Le token sera stockÃ© dans un fichier .env Ã  la racine du projet." -ForegroundColor Yellow
Write-Host ""

# Demander le token GitHub
Write-Host "Entrez votre token GitHub (vous pouvez le coller avec Ctrl+V) :" -ForegroundColor Green
$githubToken = Read-Host

if ([string]::IsNullOrEmpty($githubToken)) {
    Write-Host "Aucun token GitHub fourni. Configuration annulÃ©e." -ForegroundColor Red
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
    # CrÃ©er un nouveau fichier .env
    $envContent = "# Configuration GitHub pour l'intÃ©gration avec MCP`nGITHUB_TOKEN=$githubToken`n"
}

# Ã‰crire le fichier .env
Set-Content -Path $envPath -Value $envContent
Write-Host ""
Write-Host "âœ… Token GitHub configurÃ© avec succÃ¨s dans le fichier .env" -ForegroundColor Green
Write-Host "Vous pouvez maintenant utiliser le serveur MCP GitHub avec votre token." -ForegroundColor Green

# Tester la configuration
Write-Host ""
Write-Host "Voulez-vous tester la configuration en dÃ©marrant le serveur MCP GitHub ? (O/N)" -ForegroundColor Yellow
$testConfig = Read-Host

if ($testConfig -eq "O" -or $testConfig -eq "o") {
    Write-Host "DÃ©marrage du serveur MCP GitHub..." -ForegroundColor Cyan
    Write-Host "Appuyez sur Ctrl+C pour arrÃªter le serveur." -ForegroundColor Yellow
    Write-Host ""
    
    # DÃ©finir la variable d'environnement pour ce processus
    $env:GITHUB_TOKEN = $githubToken
    
    # ExÃ©cuter la commande
    mcp-server-github
}
