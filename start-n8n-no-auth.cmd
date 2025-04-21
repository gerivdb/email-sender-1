@echo off
cd /d "%~dp0"

echo Démarrage de n8n sans authentification...

set N8N_BASIC_AUTH_ACTIVE=false
set N8N_USER_MANAGEMENT_DISABLED=true
set N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
set N8N_AUTH_EXCLUDE_ENDPOINTS=*
set N8N_DIAGNOSTICS_ENABLED=false
set N8N_PERSONALIZATION_ENABLED=false
set N8N_HIRING_BANNER_ENABLED=false
set N8N_TEMPLATES_ENABLED=false
set N8N_TEMPLATES_HOST=https://api.n8n.io/
set N8N_PUBLIC_API_DISABLED=true
set NODE_ENV=development

npx n8n start --tunnel

echo n8n arrêté.
