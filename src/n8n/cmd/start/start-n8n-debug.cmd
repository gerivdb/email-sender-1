@echo off
cd /d "%~dp0\..\..\"

echo Démarrage de n8n en mode debug...
set N8N_LOG_LEVEL=debug
powershell -ExecutionPolicy Bypass -File "scripts\start-n8n.ps1"
