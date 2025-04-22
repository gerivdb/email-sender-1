@echo off
cd /d "%~dp0\..\..\"

echo Démarrage de n8n en local...
powershell -ExecutionPolicy Bypass -File "scripts\start-n8n.ps1"
