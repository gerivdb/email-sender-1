# Script pour configurer le token GitHub pour MCP
# Ce script permet de configurer facilement le token GitHub pour le serveur MCP GitHub

# Fonction pour masquer la saisie du token
function Read-SecureInput {
    param (
        [string]$prompt
    )
    
    $secureString = Read-Host -Prompt $prompt -AsSecureString
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
    $plainText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    
    return $plainText
}

Write-Host "=== Configuration du token GitHub pour MCP ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Ce script va vous aider Ã  configurer le token GitHub pour le serveur MCP GitHub." -ForegroundColor Yellow
Write-Host "Le token sera stockÃ© dans un fichier .env Ã  la racine du projet." -ForegroundColor Yellow
Write-Host ""
Write-Host "Si vous n'avez pas encore de token GitHub, suivez ces Ã©tapes :" -ForegroundColor Yellow
Write-Host "1. Connectez-vous Ã  votre compte GitHub" -ForegroundColor Yellow
Write-Host "2. AccÃ©dez aux paramÃ¨tres de votre compte (cliquez sur votre photo de profil en haut Ã  droite, puis sur 'Settings')" -ForegroundColor Yellow
Write-Host "3. Dans le menu de gauche, cliquez sur 'Developer settings'" -ForegroundColor Yellow
Write-Host "4. Cliquez sur 'Personal access tokens' puis 'Tokens (classic)'" -ForegroundColor Yellow
Write-Host "5. Cliquez sur 'Generate new token' puis 'Generate new token (classic)'" -ForegroundColor Yellow
Write-Host "6. Donnez un nom Ã  votre token (par exemple 'MCP GitHub Access')" -ForegroundColor Yellow
Write-Host "7. SÃ©lectionnez les autorisations nÃ©cessaires :" -ForegroundColor Yellow
Write-Host "   - repo (accÃ¨s complet aux dÃ©pÃ´ts)" -ForegroundColor Yellow
Write-Host "   - read:org (lecture des informations sur l'organisation)" -ForegroundColor Yellow
Write-Host "   - read:user (lecture des informations sur l'utilisateur)" -ForegroundColor Yellow
Write-Host "   - read:project (lecture des projets)" -ForegroundColor Yellow
Write-Host "8. Cliquez sur 'Generate token'" -ForegroundColor Yellow
Write-Host "9. Copiez le token gÃ©nÃ©rÃ©" -ForegroundColor Yellow
Write-Host ""

# VÃ©rifier si un fichier .env existe dÃ©jÃ 
$envPath = Join-Path $PSScriptRoot "..\..\\.env"
$envExists = Test-Path $envPath
$currentToken = $null

if ($envExists) {
    $envContent = Get-Content -Path $envPath -Raw
    $tokenMatch = [regex]::Match($envContent, "GITHUB_TOKEN=([^\r\n]+)")
    
    if ($tokenMatch.Success) {
        $currentToken = $tokenMatch.Groups[1].Value
        Write-Host "Un token GitHub est dÃ©jÃ  configurÃ© dans le fichier .env." -ForegroundColor Green
        $updateToken = Read-Host "Voulez-vous le mettre Ã  jour ? (O/N)"
        
        if ($updateToken -ne "O" -and $updateToken -ne "o") {
            Write-Host "Configuration du token GitHub annulÃ©e." -ForegroundColor Yellow
            exit 0
        }
    }
}

# Demander le token GitHub
Write-Host ""
$githubToken = Read-SecureInput "Entrez votre token GitHub"

if ([string]::IsNullOrEmpty($githubToken)) {
    Write-Host "Aucun token GitHub fourni. Configuration annulÃ©e." -ForegroundColor Red
    exit 1
}

# Demander les informations supplÃ©mentaires (optionnelles)
Write-Host ""
Write-Host "Informations supplÃ©mentaires (optionnelles) :" -ForegroundColor Yellow
$githubOwner = Read-Host "Entrez votre nom d'utilisateur ou d'organisation GitHub (laissez vide pour ignorer)"
$githubRepo = Read-Host "Entrez le nom du dÃ©pÃ´t principal (laissez vide pour ignorer)"

# CrÃ©er ou mettre Ã  jour le fichier .env
$envContent = "# Configuration GitHub pour l'intÃ©gration avec MCP`nGITHUB_TOKEN=$githubToken`n"

if (-not [string]::IsNullOrEmpty($githubOwner)) {
    $envContent += "GITHUB_OWNER=$githubOwner`n"
}

if (-not [string]::IsNullOrEmpty($githubRepo)) {
    $envContent += "GITHUB_REPO=$githubRepo`n"
}

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
