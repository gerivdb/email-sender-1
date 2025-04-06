@echo off
echo Obtention d'un nouveau token OAuth2...
echo.
echo Ce script va generer un nouveau token OAuth2 avec les scopes necessaires
echo pour envoyer des emails via l'API Gmail.
echo.
echo Prerequis:
echo 1. Le fichier credentials.json doit exister
echo 2. L'API Gmail doit etre activee dans votre projet GCP
echo.
echo Appuyez sur une touche pour continuer...
pause > nul

:: Executer le script
node "%~dp0get-oauth-token.js"

echo.
echo Processus termine. Verifiez les instructions ci-dessus.
echo.
pause
