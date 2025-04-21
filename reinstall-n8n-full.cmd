@echo off
cd /d "%~dp0"

echo Réinstallation complète de n8n...

npm uninstall -g n8n
npm cache clean --force
npm install -g n8n

echo Réinstallation terminée.
