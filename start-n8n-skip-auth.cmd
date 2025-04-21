@echo off
cd /d "%~dp0"

echo Démarrage de n8n en sautant la gestion des utilisateurs...

set N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true

npx n8n start --skip-user-management

echo n8n arrêté.
