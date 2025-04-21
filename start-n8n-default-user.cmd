@echo off
cd /d "%~dp0"

echo Démarrage de n8n avec un utilisateur par défaut...

set N8N_BASIC_AUTH_ACTIVE=true
set N8N_USER_MANAGEMENT_DISABLED=false
set N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
set N8N_DEFAULT_USER_EMAIL=admin@example.com
set N8N_DEFAULT_USER_PASSWORD=admin
set N8N_DEFAULT_USER_FIRSTNAME=Admin
set N8N_DEFAULT_USER_LASTNAME=User

npx n8n start

echo n8n arrêté.
