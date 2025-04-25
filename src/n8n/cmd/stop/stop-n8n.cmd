@echo off
cd /d "%~dp0\..\..\"

echo Arrêt de n8n...
powershell -ExecutionPolicy Bypass -File "scripts\stop-n8n.ps1"
