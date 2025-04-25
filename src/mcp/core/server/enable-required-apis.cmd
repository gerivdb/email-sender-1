@echo off
echo Activation des API requises dans votre projet GCP...
echo.
echo Ce script va tenter d'activer les API necessaires pour creer un compte de service
echo avec acces Gmail dans votre projet GCP.
echo.
echo API a activer :
echo - iam.googleapis.com (Identity and Access Management)
echo - gmail.googleapis.com (Gmail API)
echo - servicemanagement.googleapis.com (Service Management API)
echo - serviceusage.googleapis.com (Service Usage API)
echo.
echo Appuyez sur une touche pour continuer...
pause > nul

:: Configuration des variables d'environnement pour l'authentification
set GOOGLE_APPLICATION_CREDENTIALS=%~dp0\token.json

:: Variables d'environnement pour N8N
set N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true

node "%~dp0enable-required-apis.js"

echo.
echo Processus termine. Verifiez les instructions ci-dessus.
echo.
echo Si l'activation a reussi, attendez quelques minutes puis executez create-service-account.cmd
echo pour creer le compte de service.
echo.
pause
