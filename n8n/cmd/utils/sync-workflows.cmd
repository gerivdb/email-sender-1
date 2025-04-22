@echo off
cd /d "%~dp0\..\..\"

echo Synchronisation des workflows...
powershell -ExecutionPolicy Bypass -File "scripts\sync\sync-workflows.ps1" %*
