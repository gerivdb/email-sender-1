@echo off
cd /d "%~dp0"

echo Démarrage de n8n avec synchronisation IDE...
echo.

call "n8n\cmd\start\start-n8n-with-ide-sync.cmd"
