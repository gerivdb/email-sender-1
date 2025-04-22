@echo off
echo Tableau de bord n8n...
echo.
cd /d "%~dp0"
call n8n\automation\dashboard\n8n-dashboard.cmd %*
