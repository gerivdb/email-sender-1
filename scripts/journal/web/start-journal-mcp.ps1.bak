# Script PowerShell pour démarrer le serveur MCP avec le provider du journal de bord

# Chemin absolu vers le répertoire du projet
$ProjectDir = (Get-Location).Path
$McpConfigPath = Join-Path $ProjectDir "..\..\D"

# Vérifier si le module MCP est installé
$mcpInstalled = npm list -g @modelcontextprotocol/server | Select-String "@modelcontextprotocol/server"

if (-not $mcpInstalled) {
    Write-Host "Le module @modelcontextprotocol/server n'est pas installé globalement." -ForegroundColor Yellow
    Write-Host "Installation en cours..." -ForegroundColor Yellow
    
    npm install -g @modelcontextprotocol/server
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Erreur lors de l'installation de @modelcontextprotocol/server." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "@modelcontextprotocol/server installé avec succès." -ForegroundColor Green
}

# Installer les dépendances nécessaires pour le provider
Write-Host "Installation des dépendances pour le provider du journal..." -ForegroundColor Cyan
npm install --prefix scripts/mcp js-yaml

# Démarrer le serveur MCP
Write-Host "Démarrage du serveur MCP avec le provider du journal de bord..." -ForegroundColor Cyan
Write-Host "Configuration: $McpConfigPath" -ForegroundColor Cyan

# Créer un fichier batch temporaire pour exécuter le serveur
$BatchContent = @"
@echo off
cd /d "$ProjectDir"
mcp-server --config "$McpConfigPath"
"@

$BatchPath = Join-Path $ProjectDir "scripts\cmd\temp-mcp-server.bat"
Set-Content -Path $BatchPath -Value $BatchContent -Encoding ASCII

# Démarrer le serveur MCP
Start-Process -FilePath $BatchPath -NoNewWindow

Write-Host "Serveur MCP démarré avec le provider du journal de bord." -ForegroundColor Green
Write-Host "Le serveur est accessible à l'adresse: http://localhost:8080" -ForegroundColor Green
Write-Host "Pour arrêter le serveur, fermez la fenêtre du terminal ou utilisez Ctrl+C." -ForegroundColor Yellow

