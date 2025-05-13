@echo off
cd /d "%~dp0"

echo Vérification de l'état des serveurs MCP...

:: Exécuter le script PowerShell
powershell -ExecutionPolicy Bypass -File "check-mcp-servers.ps1"

echo Vérification terminée.
pause
