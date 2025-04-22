@echo off
echo Liste des instances n8n...
echo.
cd /d "%~dp0"
call n8n\automation\monitoring\list-n8n-instances.cmd %*
