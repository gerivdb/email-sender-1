@echo off
echo Configuration de l'API Key pour n8n...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0\configure-n8n-api-key.ps1" %*
