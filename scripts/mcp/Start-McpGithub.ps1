# Script pour démarrer le serveur MCP GitHub
# Ce script permet d'accéder aux dépôts GitHub via le Model Context Protocol

# Vérifier si le serveur MCP GitHub est installé
$mcpInstalled = Get-Command mcp-server-github -ErrorAction SilentlyContinue

if ($null -eq $mcpInstalled) {
    Write-Host "Le serveur MCP GitHub n'est pas installé." -ForegroundColor Yellow
    $installChoice = Read-Host "Voulez-vous l'installer maintenant ? (O/N)"
    
    if ($installChoice -eq "O" -or $installChoice -eq "o") {
        Write-Host "Installation en cours..." -ForegroundColor Cyan
        npm install -g @modelcontextprotocol/server-github
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Échec de l'installation. Veuillez installer manuellement avec :" -ForegroundColor Red
            Write-Host "npm install -g @modelcontextprotocol/server-github" -ForegroundColor Red
            exit 1
        }
        
        Write-Host "Installation réussie." -ForegroundColor Green
    } else {
        Write-Host "Installation annulée. Le script ne peut pas continuer sans MCP GitHub." -ForegroundColor Red
        exit 1
    }
}

# Vérifier si un token GitHub est fourni
$githubToken = $env:GITHUB_TOKEN

if ([string]::IsNullOrEmpty($githubToken)) {
    # Vérifier si un fichier .env existe avec le token
    if (Test-Path ".env") {
        $envContent = Get-Content ".env" -Raw
        $match = [regex]::Match($envContent, "GITHUB_TOKEN=([^\r\n]+)")
        if ($match.Success) {
            $githubToken = $match.Groups[1].Value
            Write-Host "Token GitHub trouvé dans le fichier .env" -ForegroundColor Green
        }
    }
    
    # Si toujours pas de token, demander à l'utilisateur
    if ([string]::IsNullOrEmpty($githubToken)) {
        Write-Host "Aucun token GitHub trouvé dans les variables d'environnement ou le fichier .env" -ForegroundColor Yellow
        $githubToken = Read-Host "Veuillez entrer votre token GitHub (ou laissez vide pour utiliser l'authentification anonyme)"
    }
}

# Configurer les variables d'environnement
if (-not [string]::IsNullOrEmpty($githubToken)) {
    $env:GITHUB_TOKEN = $githubToken
    Write-Host "Token GitHub configuré" -ForegroundColor Green
} else {
    Write-Host "Aucun token GitHub fourni. Le serveur fonctionnera en mode anonyme avec des limites de taux plus strictes." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Démarrage du serveur MCP GitHub..." -ForegroundColor Green
Write-Host "Le serveur sera accessible pour Claude et d'autres modèles d'IA." -ForegroundColor Cyan
Write-Host "Appuyez sur Ctrl+C pour arrêter le serveur." -ForegroundColor Yellow
Write-Host ""

# Exécuter la commande
mcp-server-github

# Ce script ne devrait jamais atteindre cette ligne sauf en cas d'erreur
Write-Host "Le serveur s'est arrêté de manière inattendue." -ForegroundColor Red
