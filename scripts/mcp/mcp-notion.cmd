@echo off
set N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
cd /d "%~dp0"

echo Démarrage du MCP Notion...

:: Utiliser le script Python pour lancer le MCP Notion en mode STDIO
python "..\..\..\scripts\python\run_mcp_notion.py" --stdio
