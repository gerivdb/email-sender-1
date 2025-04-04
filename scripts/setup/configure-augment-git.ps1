# Script pour configurer le MCP Git Ingest dans Augment

Write-Host "=== Configuration du MCP Git Ingest dans Augment ===" -ForegroundColor Cyan

# Vérifier si le dossier scripts\cmd\augment existe
$augmentDir = "scripts\cmd\augment"
if (-not (Test-Path $augmentDir)) {
    Write-Host "Création du dossier $augmentDir..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $augmentDir -Force | Out-Null
    Write-Host "✅ Dossier $augmentDir créé" -ForegroundColor Green
} else {
    Write-Host "✅ Dossier $augmentDir existe déjà" -ForegroundColor Green
}

# Vérifier si le fichier augment-mcp-git-ingest.cmd existe
$gitIngestCmdPath = "$augmentDir\augment-mcp-git-ingest.cmd"
if (-not (Test-Path $gitIngestCmdPath)) {
    Write-Host "Création du fichier $gitIngestCmdPath..." -ForegroundColor Yellow
    $gitIngestCmdContent = @"
@echo off
set N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
cd /d "%~dp0"

echo Démarrage du MCP Git Ingest...

:: Utiliser la commande directe avec le dépôt GitHub
npx -y --package=git+https://github.com/adhikasp/mcp-git-ingest mcp-git-ingest
"@
    Set-Content -Path $gitIngestCmdPath -Value $gitIngestCmdContent
    Write-Host "✅ Fichier $gitIngestCmdPath créé" -ForegroundColor Green
} else {
    Write-Host "✅ Fichier $gitIngestCmdPath existe déjà" -ForegroundColor Green
}

# Instructions pour configurer Augment
Write-Host "`nInstructions pour configurer le MCP Git Ingest dans Augment :" -ForegroundColor Cyan
Write-Host "1. Ouvrez Augment Settings (Ctrl+Shift+P puis 'Augment: Open Settings')"
Write-Host "2. Dans la section 'MCP Servers', cliquez sur 'Add MCP Server'"
Write-Host "3. Entrez les informations suivantes :"
Write-Host "   - Name: MCP Git Ingest"
Write-Host "   - Command: $((Resolve-Path $gitIngestCmdPath).Path)"
Write-Host "4. Cliquez sur 'Save'"

Write-Host "`n=== Configuration du MCP Git Ingest dans Augment terminée ===" -ForegroundColor Cyan
