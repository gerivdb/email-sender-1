@echo off
cd /d "%~dp0"

echo Migration de l'ancienne structure vers la nouvelle structure n8n...

powershell -ExecutionPolicy Bypass -File "scripts\setup\migrate-all.ps1" %*

echo.
echo Migration terminée.
echo Pour installer et configurer n8n, exécutez: .\n8n\scripts\setup\install-n8n-local.ps1
