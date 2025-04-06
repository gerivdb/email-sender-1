@echo off
echo Configuration du secret EMAIL_PASSWORD dans GitHub Actions...
echo.
echo Ce script va configurer le secret EMAIL_PASSWORD dans GitHub Actions
echo en utilisant le token GitHub configure dans le fichier .env.
echo.
echo Prerequis:
echo 1. Le fichier service-account-key.json doit exister
echo 2. Le fichier .env doit contenir GITHUB_TOKEN, GITHUB_OWNER et GITHUB_REPO
echo.
echo Appuyez sur une touche pour continuer...
pause > nul

:: Installer les dependances necessaires
echo Installation des dependances...
npm install @octokit/rest libsodium-wrappers --save

:: Executer le script
node "%~dp0configure-github-secret.js"

echo.
echo Processus termine.
echo.
pause
