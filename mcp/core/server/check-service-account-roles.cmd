@echo off
echo Verification des roles du compte de service...
echo.
echo Ce script va verifier si le compte de service a les roles necessaires
echo pour envoyer des emails via l'API Gmail.
echo.
echo Appuyez sur une touche pour continuer...
pause > nul

:: Configuration des variables d'environnement pour l'authentification
set GOOGLE_APPLICATION_CREDENTIALS=%~dp0\token.json

:: Variables d'environnement pour N8N
set N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true

node "%~dp0check-service-account-roles.js"

echo.
echo Processus termine. Verifiez les instructions ci-dessus.
echo.
pause
