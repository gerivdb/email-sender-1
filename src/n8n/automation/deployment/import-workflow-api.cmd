@echo off
echo Importation de workflows via l'API n8n...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0\import-workflow-api.ps1" %*
