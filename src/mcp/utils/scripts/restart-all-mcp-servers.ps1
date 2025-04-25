# Script pour redémarrer tous les serveurs MCP
# Ce script arrête tous les serveurs MCP en cours d'exécution, puis les redémarre

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()

# Chemin du répertoire racine du projet
$projectRoot = Join-Path -Path $PSScriptRoot -ChildPath "..\..\"
$projectRoot = (Resolve-Path $projectRoot).Path

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "      REDÉMARRAGE DES SERVEURS MCP EMAIL_SENDER_1        " -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Arrêter tous les serveurs MCP
Write-Host "1. Arrêt de tous les serveurs MCP..." -ForegroundColor Cyan
& "$PSScriptRoot\stop-all-mcp-servers.ps1"

# 2. Attendre quelques secondes
Write-Host "2. Attente de 3 secondes..." -ForegroundColor Cyan
Start-Sleep -Seconds 3

# 3. Démarrer tous les serveurs MCP
Write-Host "3. Démarrage de tous les serveurs MCP..." -ForegroundColor Cyan
& "$PSScriptRoot\start-all-mcp-servers.ps1"

Write-Host ""
Write-Host "Redémarrage des serveurs MCP terminé." -ForegroundColor Green
Write-Host ""
