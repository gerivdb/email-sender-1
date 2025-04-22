@echo off
cd /d "%~dp0"

echo Correction des dossiers n8n...
echo Ce script va corriger les problèmes de dossiers n8n et n8n-new.
echo.
echo ATTENTION : Ce script va arrêter tous les processus Node.js et PowerShell en cours d'exécution.
echo Veuillez enregistrer votre travail avant de continuer.
echo.
pause

powershell -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -File ""scripts\cleanup\fix-n8n-folders.ps1""' -Verb RunAs"

echo.
echo Le script de correction a été lancé avec des privilèges d'administrateur.
echo Veuillez suivre les instructions dans la fenêtre PowerShell.
echo.
echo Une fois terminé, ce fichier sera automatiquement déplacé dans le dossier scripts\cleanup.
echo.
pause

move "%~f0" "scripts\cleanup\fix-n8n-folders.cmd" >nul 2>&1
