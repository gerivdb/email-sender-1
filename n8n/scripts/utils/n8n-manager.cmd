@echo off
echo n8n Manager
echo.
cd /d "%~dp0"
call n8n\automation\n8n-manager.cmd %*
