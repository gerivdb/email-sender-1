@echo off
echo Arret de n8n...
echo.
cd /d "%~dp0"
call n8n\automation\n8n-manager.cmd -Action stop
