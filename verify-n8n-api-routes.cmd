@echo off
echo Verification des routes API de n8n...
echo.
cd /d "%~dp0"
call n8n\automation\monitoring\verify-n8n-api-routes.cmd %*
