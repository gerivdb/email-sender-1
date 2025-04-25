@echo off
set N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
cd /d "%~dp0"

echo Démarrage de la Gateway MCP...

:: Utiliser le script Python pour lancer la Gateway MCP en mode STDIO
python "..\..\..\scripts\python\run_mcp_gateway.py" --stdio
