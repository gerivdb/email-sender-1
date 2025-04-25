# Script pour dÃ©marrer le serveur MCP GitHub
# Ce script permet d'accÃ©der aux dÃ©pÃ´ts GitHub via le Model Context Protocol

# VÃ©rifier si le serveur MCP GitHub est installÃ©
$mcpInstalled = Get-Command mcp-server-github -ErrorAction SilentlyContinue

if ($null -eq $mcpInstalled) {
    Write-Host "Le serveur MCP GitHub n'est pas installÃ©." -ForegroundColor Yellow
    $installChoice = Read-Host "Voulez-vous l'installer maintenant ? (O/N)"
    
    if ($installChoice -eq "O" -or $installChoice -eq "o") {
        Write-Host "Installation en cours..." -ForegroundColor Cyan
        npm install -g @modelcontextprotocol/server-github
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Ã‰chec de l'installation. Veuillez installer manuellement avec :" -ForegroundColor Red
            Write-Host "npm install -g @modelcontextprotocol/server-github" -ForegroundColor Red
            exit 1
        }
        
        Write-Host "Installation rÃ©ussie." -ForegroundColor Green
    } else {
        Write-Host "Installation annulÃ©e. Le script ne peut pas continuer sans MCP GitHub." -ForegroundColor Red
        exit 1
    }
}

# VÃ©rifier si un token GitHub est fourni
$githubToken = $env:GITHUB_TOKEN

if ([string]::IsNullOrEmpty($githubToken)) {
    # VÃ©rifier si un fichier .env existe avec le token
    if (Test-Path ".env") {
        $envContent = Get-Content ".env" -Raw
        $match = [regex]::Match($envContent, "GITHUB_TOKEN=([^\r\n]+)")
        if ($match.Success) {
            $githubToken = $match.Groups[1].Value
            Write-Host "Token GitHub trouvÃ© dans le fichier .env" -ForegroundColor Green
        }
    }
    
    # Si toujours pas de token, demander Ã  l'utilisateur
    if ([string]::IsNullOrEmpty($githubToken)) {
        Write-Host "Aucun token GitHub trouvÃ© dans les variables d'environnement ou le fichier .env" -ForegroundColor Yellow
        $githubToken = Read-Host "Veuillez entrer votre token GitHub (ou laissez vide pour utiliser l'authentification anonyme)"
    }
}

# Configurer les variables d'environnement
if (-not [string]::IsNullOrEmpty($githubToken)) {
    $env:GITHUB_TOKEN = $githubToken
    Write-Host "Token GitHub configurÃ©" -ForegroundColor Green
} else {
    Write-Host "Aucun token GitHub fourni. Le serveur fonctionnera en mode anonyme avec des limites de taux plus strictes." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "DÃ©marrage du serveur MCP GitHub..." -ForegroundColor Green
Write-Host "Le serveur sera accessible pour Claude et d'autres modÃ¨les d'IA." -ForegroundColor Cyan
Write-Host "Appuyez sur Ctrl+C pour arrÃªter le serveur." -ForegroundColor Yellow
Write-Host ""

# ExÃ©cuter la commande
mcp-server-github

# Ce script ne devrait jamais atteindre cette ligne sauf en cas d'erreur
Write-Host "Le serveur s'est arrÃªtÃ© de maniÃ¨re inattendue." -ForegroundColor Red
