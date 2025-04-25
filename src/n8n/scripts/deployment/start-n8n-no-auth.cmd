@echo off
echo Demarrage de n8n sans authentification...
echo.
cd /d "%~dp0"
call n8n\automation\deployment\start-n8n-no-auth.cmd
