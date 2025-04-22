@echo off
echo Arret de n8n (instance)...
echo.
cd /d "%~dp0"
call n8n\automation\deployment\stop-n8n-instance.cmd %*
