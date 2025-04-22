@echo off
echo Liste des workflows via l'API n8n...
echo.
cd /d "%~dp0"
call n8n\automation\monitoring\list-workflows-api.cmd %*
