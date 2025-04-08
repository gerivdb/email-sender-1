@echo off
echo Activation de l'API Gmail...
echo.
echo Ce script va tenter d'activer l'API Gmail dans votre projet GCP.
echo.
echo Appuyez sur une touche pour continuer...
pause > nul

:: Configuration des variables d'environnement pour l'authentification
set GOOGLE_APPLICATION_CREDENTIALS=%~dp0\token.json

:: Variables d'environnement pour N8N
set N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true

node "%~dp0enable-gmail-api.js"

echo.
echo Processus termine. Verifiez les instructions ci-dessus.
echo.
pause
