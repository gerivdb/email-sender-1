@echo off
cd /d "%~dp0\..\..\"

echo Démarrage de n8n sans authentification...
set N8N_BASIC_AUTH_ACTIVE=false
set N8N_USER_MANAGEMENT_DISABLED=true
powershell -ExecutionPolicy Bypass -File "scripts\start-n8n.ps1"
