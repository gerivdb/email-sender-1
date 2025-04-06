@echo off
echo Ajout des secrets pour GitHub Actions...
echo.
echo Ce script va ajouter les secrets necessaires pour GitHub Actions
echo a votre depot GitHub.
echo.
echo Prerequis:
echo 1. Le fichier config.json doit etre configure avec votre token GitHub
echo 2. Le fichier token.json doit exister dans le repertoire gcp-mcp
echo.
echo Appuyez sur une touche pour continuer...
pause > nul

:: Installer les dependances
echo Installation des dependances...
cd "%~dp0"
npm install @octokit/rest libsodium-wrappers

:: Executer le script
node "%~dp0add-secrets.js"

echo.
echo Processus termine. Verifiez les instructions ci-dessus.
echo.
pause
