@echo off
echo Extraction des secrets pour GitHub Actions...
echo.
echo Ce script va extraire les secrets necessaires pour GitHub Actions
echo a partir du fichier token.json.
echo.
echo Prerequis:
echo 1. Le fichier token.json doit exister
echo.
echo Appuyez sur une touche pour continuer...
pause > nul

:: Executer le script
node "%~dp0extract-secrets.js"

echo.
echo Processus termine. Verifiez les instructions ci-dessus.
echo.
pause
