@echo off
echo Configuration de l'API Key pour n8n...
echo.
cd /d "%~dp0"
call n8n\automation\deployment\configure-n8n-api-key.cmd %*
