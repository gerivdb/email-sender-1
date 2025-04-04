@echo off
setlocal EnableDelayedExpansion

:: Définir les variables d'environnement
set "N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true"
set "NOTION_API_TOKEN=secret_ntn_3470013019778Q0IyMcDeftn5d1pnBWjTWTiTWEha2D1Lo"

:: Obtenir le chemin absolu du script sans espaces (format 8.3)
for %%i in ("%~dp0") do set "SCRIPT_DIR=%%~si"
cd /d "%SCRIPT_DIR%"

echo Démarrage du MCP Notion Server...

:: Méthode simple et directe avec chemin court
npx -y @suekou/mcp-notion-server
