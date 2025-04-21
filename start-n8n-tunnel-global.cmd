@echo off
cd /d "%~dp0"

echo Démarrage de n8n avec l'installation globale et l'option tunnel...

n8n start --tunnel

echo n8n arrêté.
