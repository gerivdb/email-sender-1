@echo off
set N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
cd /d "%~dp0"

echo Démarrage du MCP Git Ingest...

:: Utiliser la commande directe avec le dépôt GitHub
npx -y --package=git+https://github.com/adhikasp/mcp-git-ingest mcp-git-ingest
