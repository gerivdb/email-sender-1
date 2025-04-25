@echo off
echo Verification des ports n8n...
echo.
cd /d "%~dp0"
call n8n\automation\monitoring\check-n8n-ports.cmd %*
