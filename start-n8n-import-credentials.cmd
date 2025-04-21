@echo off
cd /d "%~dp0"

echo Démarrage de n8n avec importation des identifiants...

set N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
set N8N_USER_MANAGEMENT_DISABLED=true
set N8N_BASIC_AUTH_ACTIVE=false

npx n8n import:credentials --input=.\.n8n\credentials

npx n8n start

echo n8n arrêté.
