@echo off
cd /d "%~dp0"

echo Réinstallation de n8n...

npx n8n update --reinstall-dependencies

echo Réinstallation terminée.
