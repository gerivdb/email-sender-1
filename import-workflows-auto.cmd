@echo off
echo Importation automatique des workflows n8n...
echo.
cd /d "%~dp0"
call n8n\automation\deployment\import-workflows-auto.cmd %*
