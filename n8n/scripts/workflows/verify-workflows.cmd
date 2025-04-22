@echo off
echo Verification de la presence des workflows n8n...
echo.
cd /d "%~dp0"
call n8n\automation\monitoring\verify-workflows.cmd %*
