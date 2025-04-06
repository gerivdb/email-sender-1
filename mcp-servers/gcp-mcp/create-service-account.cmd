@echo off
echo Creation d'un compte de service GCP pour Gmail...
echo.
echo Ce script va creer un compte de service avec acces Gmail
echo et generer une cle pour l'utiliser dans GitHub Actions.
echo.
echo Appuyez sur une touche pour continuer...
pause > nul

:: Configuration des variables d'environnement pour l'authentification
set GOOGLE_APPLICATION_CREDENTIALS=%~dp0\token.json

:: Variables d'environnement pour N8N
set N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true

node "%~dp0create-service-account.js"

echo.
echo Processus termine. Verifiez les instructions ci-dessus.
echo.
pause
