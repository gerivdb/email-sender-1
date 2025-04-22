@echo off
echo Importation en masse des workflows n8n...
echo.
cd /d "%~dp0"
call n8n\automation\deployment\import-workflows-bulk.cmd %*
