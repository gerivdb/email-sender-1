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
Write-Host "Ce script va vous aider à configurer le token GitHub pour le serveur MCP GitHub." -ForegroundColor Yellow
Write-Host "Le token sera stocké dans un fichier .env à la racine du projet." -ForegroundColor Yellow
Write-Host ""
Write-Host "Si vous n'avez pas encore de token GitHub, suivez ces étapes :" -ForegroundColor Yellow
Write-Host "1. Connectez-vous à votre compte GitHub" -ForegroundColor Yellow
Write-Host "2. Accédez aux paramètres de votre compte (cliquez sur votre photo de profil en haut à droite, puis sur 'Settings')" -ForegroundColor Yellow
Write-Host "3. Dans le menu de gauche, cliquez sur 'Developer settings'" -ForegroundColor Yellow
Write-Host "4. Cliquez sur 'Personal access tokens' puis 'Tokens (classic)'" -ForegroundColor Yellow
Write-Host "5. Cliquez sur 'Generate new token' puis 'Generate new token (classic)'" -ForegroundColor Yellow
Write-Host "6. Donnez un nom à votre token (par exemple 'MCP GitHub Access')" -ForegroundColor Yellow
Write-Host "7. Sélectionnez les autorisations nécessaires :" -ForegroundColor Yellow
Write-Host "   - repo (accès complet aux dépôts)" -ForegroundColor Yellow
Write-Host "   - read:org (lecture des informations sur l'organisation)" -ForegroundColor Yellow
Write-Host "   - read:user (lecture des informations sur l'utilisateur)" -ForegroundColor Yellow
Write-Host "   - read:project (lecture des projets)" -ForegroundColor Yellow
Write-Host "8. Cliquez sur 'Generate token'" -ForegroundColor Yellow
Write-Host "9. Copiez le token généré" -ForegroundColor Yellow
Write-Host ""

# Vérifier si un fichier .env existe déjà
$envPath = Join-Path $PSScriptRoot "..\..\\.env"
$envExists = Test-Path $envPath
$currentToken = $null

if ($envExists) {
    $envContent = Get-Content -Path $envPath -Raw
    $tokenMatch = [regex]::Match($envContent, "GITHUB_TOKEN=([^\r\n]+)")
    
    if ($tokenMatch.Success) {
        $currentToken = $tokenMatch.Groups[1].Value
        Write-Host "Un token GitHub est déjà configuré dans le fichier .env." -ForegroundColor Green
        $updateToken = Read-Host "Voulez-vous le mettre à jour ? (O/N)"
        
        if ($updateToken -ne "O" -and $updateToken -ne "o") {
            Write-Host "Configuration du token GitHub annulée." -ForegroundColor Yellow
            exit 0
        }
    }
}

# Demander le token GitHub
Write-Host ""
$githubToken = Read-SecureInput "Entrez votre token GitHub"

if ([string]::IsNullOrEmpty($githubToken)) {
    Write-Host "Aucun token GitHub fourni. Configuration annulée." -ForegroundColor Red
    exit 1
}

# Demander les informations supplémentaires (optionnelles)
Write-Host ""
Write-Host "Informations supplémentaires (optionnelles) :" -ForegroundColor Yellow
$githubOwner = Read-Host "Entrez votre nom d'utilisateur ou d'organisation GitHub (laissez vide pour ignorer)"
$githubRepo = Read-Host "Entrez le nom du dépôt principal (laissez vide pour ignorer)"

# Créer ou mettre à jour le fichier .env
$envContent = "# Configuration GitHub pour l'intégration avec MCP`nGITHUB_TOKEN=$githubToken`n"

if (-not [string]::IsNullOrEmpty($githubOwner)) {
    $envContent += "GITHUB_OWNER=$githubOwner`n"
}

if (-not [string]::IsNullOrEmpty($githubRepo)) {
    $envContent += "GITHUB_REPO=$githubRepo`n"
}

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
