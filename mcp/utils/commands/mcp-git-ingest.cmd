@echo off
set N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
cd /d "%~dp0"

echo Démarrage du MCP Git Ingest...

:: Utiliser le script Python pour lancer le MCP Git Ingest en mode STDIO
python "..\..\scripts\python\utils\run_mcp_git_ingest.py" --stdio

