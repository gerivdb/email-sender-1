@echo off
echo Test d'une route API de n8n...
echo.
cd /d "%~dp0"
call n8n\automation\monitoring\test-n8n-api-route.cmd %*
