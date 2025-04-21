@echo off
set N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
cd /d "%~dp0"

echo Démarrage du MCP Standard...

:: Utiliser le script Python pour lancer le MCP Standard en mode STDIO
python "..\..\..\scripts\python\run_mcp_standard.py" --stdio
