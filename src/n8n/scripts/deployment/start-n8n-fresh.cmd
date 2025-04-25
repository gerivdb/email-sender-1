@echo off
echo Demarrage de n8n avec une configuration fraiche...
echo.
cd /d "%~dp0"

:: Supprimer les fichiers de configuration existants
if exist "C:\Users\user\.n8n\config" del /F /Q "C:\Users\user\.n8n\config"

:: Définir les variables d'environnement
set N8N_BASIC_AUTH_ACTIVE=false
set N8N_USER_MANAGEMENT_DISABLED=true
set N8N_DIAGNOSTICS_ENABLED=false
set N8N_ENCRYPTION_KEY=n8n-encryption-key-12345
set N8N_LOG_LEVEL=info
set N8N_PORT=5678
set N8N_PROTOCOL=http
set N8N_HOST=localhost
set N8N_LISTEN_ADDRESS=0.0.0.0
set N8N_CONFIG_FILES=

echo Configuration:
echo - Port: %N8N_PORT%
echo - Protocole: %N8N_PROTOCOL%
echo - Hote: %N8N_HOST%
echo - Adresse d'ecoute: %N8N_LISTEN_ADDRESS%
echo - Authentification: Desactivee
echo - Gestion des utilisateurs: Desactivee
echo - Diagnostics: Desactives
echo - Niveau de log: %N8N_LOG_LEVEL%
echo - Cle de chiffrement: Definie
echo.

npx n8n start
