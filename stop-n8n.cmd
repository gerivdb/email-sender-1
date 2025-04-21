@echo off
cd /d "%~dp0"

echo Redirection vers le script d'arrêt n8n...
call n8n-unified\scripts\stop-n8n-docker.cmd
