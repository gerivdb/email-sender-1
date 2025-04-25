@echo off
cd /d "%~dp0"

echo Création d'une API key pour n8n...
echo.

powershell -ExecutionPolicy Bypass -File "..\..\scripts\setup\create-api-key.ps1"

echo.
pause
