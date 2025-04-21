@echo off
cd /d "%~dp0"

echo Réinitialisation de n8n...

node_modules\.bin\n8n reset

echo Réinitialisation terminée.
