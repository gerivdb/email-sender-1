@echo off
cd /d "%~dp0"

echo Démarrage de n8n avec npx...

npx n8n start --tunnel

echo n8n arrêté.
