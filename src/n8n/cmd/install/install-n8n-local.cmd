@echo off
cd /d "%~dp0\..\..\"

echo Installation de n8n en local...
powershell -ExecutionPolicy Bypass -File "scripts\setup\install-n8n-local.ps1"

echo.
echo Installation terminée.
echo Pour démarrer n8n, exécutez: .\cmd\start\start-n8n-local.cmd
