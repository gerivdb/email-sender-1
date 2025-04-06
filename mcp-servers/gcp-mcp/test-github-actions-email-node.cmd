@echo off
echo Test d'envoi d'email pour GitHub Actions (Node.js)...
echo.
echo Ce script va tenter d'envoyer un email de test en utilisant
echo les variables d'environnement pour l'authentification OAuth2.
echo.
echo Prerequis:
echo 1. Le fichier token.json doit exister
echo 2. L'API Gmail doit etre activee dans votre projet GCP
echo.
echo Appuyez sur une touche pour continuer...
pause > nul

:: Executer le script
node "%~dp0test-github-actions-email.js"

echo.
echo Processus termine. Verifiez les instructions ci-dessus.
echo.
pause
