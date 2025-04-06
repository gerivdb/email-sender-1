@echo off
echo Verification des API activees dans votre projet GCP...
echo.
echo Ce script va verifier quelles API sont activees dans votre projet GCP
echo et vous indiquer lesquelles doivent etre activees pour creer un compte de service.
echo.
echo Appuyez sur une touche pour continuer...
pause > nul

:: Configuration des variables d'environnement pour l'authentification
set GOOGLE_APPLICATION_CREDENTIALS=%~dp0\token.json

:: Variables d'environnement pour N8N
set N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true

node "%~dp0check-enabled-apis.js"

echo.
echo Processus termine. Verifiez les instructions ci-dessus.
echo.
pause
