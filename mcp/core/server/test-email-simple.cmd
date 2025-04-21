@echo off
echo Test d'envoi d'email (methode simple)...
echo.
echo Ce script va tenter d'envoyer un email de test en utilisant
echo le compte de service que nous venons de creer.
echo.
echo Prerequis:
echo 1. Le fichier service-account-key.json doit exister
echo 2. Le compte de service doit avoir le role "Gmail API User"
echo 3. L'API Gmail doit etre activee dans votre projet GCP
echo 4. L'utilisateur doit avoir accorde les permissions necessaires au compte de service
echo.
echo Appuyez sur une touche pour continuer...
pause > nul

:: Executer le script
node "%~dp0test-email-simple.js"

echo.
echo Processus termine. Verifiez les instructions ci-dessus.
echo.
pause
