@echo off
cd /d "%~dp0"

echo Démarrage de n8n en mode simple...

n8n start --tunnel

echo n8n arrêté.
