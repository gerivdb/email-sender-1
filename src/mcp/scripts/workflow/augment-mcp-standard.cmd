@echo off
set N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
cd /d "%~dp0"

echo Démarrage du MCP Standard...

:: Utiliser npx pour exécuter directement
npx -y n8n-nodes-mcp
