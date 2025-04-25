@echo off
echo Demarrage de n8n (multi-instance)...
echo.
cd /d "%~dp0"
call n8n\automation\deployment\start-n8n-multi-instance.cmd %*
