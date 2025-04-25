@echo off
echo Maintenance n8n...
echo.
cd /d "%~dp0"
call n8n\automation\maintenance\maintenance.cmd %*
