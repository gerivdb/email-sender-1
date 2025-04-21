@echo off
cd /d "%~dp0"

echo Réinitialisation de n8n...

npx n8n reset

echo Réinitialisation terminée.
