@echo off
cd /d "%~dp0"

echo Renommage des dossiers n8n...

powershell -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -File ""rename-n8n-folders.ps1""' -Verb RunAs"

echo.
echo Le script de renommage a été lancé avec des privilèges d'administrateur.
echo Veuillez suivre les instructions dans la fenêtre PowerShell.
