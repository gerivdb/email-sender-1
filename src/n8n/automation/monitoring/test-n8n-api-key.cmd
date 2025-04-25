@echo off
echo Test de l'API Key pour n8n...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0\test-n8n-api-key.ps1" %*
