# Script PowerShell pour dÃ©marrer le serveur MCP avec le provider du journal de bord

# Chemin absolu vers le rÃ©pertoire du projet
$ProjectDir = (Get-Location).Path
$McpConfigPath = Join-Path $ProjectDir "scripts\mcp\config.js"

# VÃ©rifier si le module MCP est installÃ©
$mcpInstalled = npm list -g @modelcontextprotocol/server | Select-String "@modelcontextprotocol/server"

if (-not $mcpInstalled) {
    Write-Host "Le module @modelcontextprotocol/server n'est pas installÃ© globalement." -ForegroundColor Yellow
    Write-Host "Installation en cours..." -ForegroundColor Yellow
    
    npm install -g @modelcontextprotocol/server
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Erreur lors de l'installation de @modelcontextprotocol/server." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "@modelcontextprotocol/server installÃ© avec succÃ¨s." -ForegroundColor Green
}

# Installer les dÃ©pendances nÃ©cessaires pour le provider
Write-Host "Installation des dÃ©pendances pour le provider du journal..." -ForegroundColor Cyan
npm install --prefix scripts/mcp js-yaml

# DÃ©marrer le serveur MCP
Write-Host "DÃ©marrage du serveur MCP avec le provider du journal de bord..." -ForegroundColor Cyan
Write-Host "Configuration: $McpConfigPath" -ForegroundColor Cyan

# CrÃ©er un fichier batch temporaire pour exÃ©cuter le serveur
$BatchContent = @"
@echo off
cd /d "$ProjectDir"
mcp-server --config "$McpConfigPath"
"@

$BatchPath = Join-Path $ProjectDir "scripts\cmd\temp-mcp-server.bat"
Set-Content -Path $BatchPath -Value $BatchContent -Encoding ASCII

# DÃ©marrer le serveur MCP
Start-Process -FilePath $BatchPath -NoNewWindow

Write-Host "Serveur MCP dÃ©marrÃ© avec le provider du journal de bord." -ForegroundColor Green
Write-Host "Le serveur est accessible Ã  l'adresse: http://localhost:8080" -ForegroundColor Green
Write-Host "Pour arrÃªter le serveur, fermez la fenÃªtre du terminal ou utilisez Ctrl+C." -ForegroundColor Yellow
