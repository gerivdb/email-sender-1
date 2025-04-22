@echo off
echo Demarrage de n8n avec gestion du PID...
echo.
cd /d "%~dp0"
call n8n\automation\deployment\start-n8n-with-pid.cmd %*
