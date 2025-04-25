@echo off
echo Demarrage direct de n8n...
echo.
cd /d "%~dp0"
npx n8n start --tunnel
