@echo off
cd /d "%~dp0\..\..\"

echo Création d'un workflow de test...
powershell -ExecutionPolicy Bypass -File "scripts\create-test-workflow.ps1" %*
