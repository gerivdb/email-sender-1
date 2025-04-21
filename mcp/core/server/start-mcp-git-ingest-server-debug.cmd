@echo off
set N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
cd /d "%~dp0"

echo Démarrage du serveur MCP Git Ingest en mode HTTP avec debug...

:: Utiliser le script Python pour lancer le MCP Git Ingest en mode HTTP avec debug
python "..\..\scripts\python\utils\run_mcp_git_ingest.py" --debug

echo Serveur MCP Git Ingest arrêté.
