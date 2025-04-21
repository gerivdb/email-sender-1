@echo off
cd /d "%~dp0"

echo Redirection vers le script de démarrage n8n...
call n8n-unified\scripts\start-n8n-docker.cmd
