@echo off
echo Generation de la documentation API de n8n...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0\generate-api-documentation.ps1" %*
