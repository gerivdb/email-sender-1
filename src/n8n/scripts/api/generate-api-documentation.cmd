@echo off
echo Generation de la documentation API de n8n...
echo.
cd /d "%~dp0"
call n8n\automation\documentation\generate-api-documentation.cmd %*
