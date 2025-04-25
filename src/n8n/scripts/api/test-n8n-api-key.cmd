@echo off
echo Test de l'API Key pour n8n...
echo.
cd /d "%~dp0"
call n8n\automation\monitoring\test-n8n-api-key.cmd %*
