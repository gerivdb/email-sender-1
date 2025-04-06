@echo off
echo Test d'envoi d'email (methode OAuth2)...
echo.
echo Ce script va tenter d'envoyer un email de test en utilisant
echo l'authentification OAuth2.
echo.
echo Prerequis:
echo 1. Le fichier token.json doit exister
echo 2. L'API Gmail doit etre activee dans votre projet GCP
echo 3. L'utilisateur doit avoir accorde les permissions necessaires
echo.
echo Appuyez sur une touche pour continuer...
pause > nul

:: Executer le script
node "%~dp0test-email-oauth.js"

echo.
echo Processus termine. Verifiez les instructions ci-dessus.
echo.
pause
