@echo off
echo Verification de l'etat de n8n...
echo.
cd /d "%~dp0"
call n8n\automation\monitoring\check-n8n-pid-status.cmd %*
