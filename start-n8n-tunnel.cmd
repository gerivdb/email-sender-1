@echo off
cd /d "%~dp0"

echo Démarrage de n8n avec tunnel...

set N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true

npx n8n start --tunnel

echo n8n arrêté.
