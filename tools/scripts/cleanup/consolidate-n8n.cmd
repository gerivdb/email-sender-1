@echo off
cd /d "%~dp0"

echo Consolidation de tous les dossiers n8n en un seul...

powershell -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -File ""consolidate-n8n.ps1""' -Verb RunAs"

echo.
echo Le script de consolidation a été lancé avec des privilèges d'administrateur.
echo Veuillez suivre les instructions dans la fenêtre PowerShell.
