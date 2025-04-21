@echo off
cd /d "%~dp0"

echo Démarrage de n8n avec les variables d'environnement du fichier .env...

npx n8n start

echo n8n arrêté.
