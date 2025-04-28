@echo off
echo Demarrage de n8n en mode local...
echo.
cd /d "%~dp0"
set N8N_BASIC_AUTH_ACTIVE=false
set N8N_USER_MANAGEMENT_DISABLED=true
set N8N_PATH=%~dp0n8n
set N8N_CONFIG_FILES=%~dp0n8n\config\n8n-local.json
set N8N_DIAGNOSTICS_ENABLED=false
set N8N_ENCRYPTION_KEY=
set N8N_LOG_LEVEL=info
set N8N_PORT=5678
set N8N_PROTOCOL=http
set N8N_HOST=127.0.0.1
set N8N_LISTEN_ADDRESS=127.0.0.1

echo Configuration:
echo - Port: %N8N_PORT%
echo - Protocole: %N8N_PROTOCOL%
echo - Hote: %N8N_HOST%
echo - Adresse d'ecoute: %N8N_LISTEN_ADDRESS%
echo.

npx n8n start


