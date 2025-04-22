@echo off
echo Importation de workflows via l'API n8n...
echo.
cd /d "%~dp0"
call n8n\automation\deployment\import-workflow-api.cmd %*
