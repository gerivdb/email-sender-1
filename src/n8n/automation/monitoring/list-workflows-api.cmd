@echo off
echo Liste des workflows via l'API n8n...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0\list-workflows-api.ps1" %*
