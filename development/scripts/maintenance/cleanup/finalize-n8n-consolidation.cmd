@echo off
cd /d "%~dp0"

echo Finalisation de la consolidation des dossiers n8n...

powershell -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -File ""finalize-n8n-consolidation.ps1""' -Verb RunAs"

echo.
echo Le script de finalisation a été lancé avec des privilèges d'administrateur.
echo Veuillez suivre les instructions dans la fenêtre PowerShell.
