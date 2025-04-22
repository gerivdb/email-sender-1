@echo off
cd /d "%~dp0"

echo Démarrage de n8n avec synchronisation IDE...
echo.

powershell -ExecutionPolicy Bypass -File "..\..\scripts\start-n8n-with-ide-sync.ps1" -NoAuth

pause
