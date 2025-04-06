@echo off
echo Test d'envoi d'email pour GitHub Actions...
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

:: Lire le fichier token.json
for /f "tokens=*" %%a in ('type "%~dp0token.json" ^| findstr "client_id"') do (
  set client_id_line=%%a
)
for /f "tokens=*" %%a in ('type "%~dp0token.json" ^| findstr "client_secret"') do (
  set client_secret_line=%%a
)
for /f "tokens=*" %%a in ('type "%~dp0token.json" ^| findstr "refresh_token"') do (
  set refresh_token_line=%%a
)

:: Extraire les valeurs
set client_id_line=%client_id_line:"client_id": "=%
set client_id_line=%client_id_line:",=%
set client_id_line=%client_id_line:"=%
set GMAIL_CLIENT_ID=%client_id_line%

set client_secret_line=%client_secret_line:"client_secret": "=%
set client_secret_line=%client_secret_line:",=%
set client_secret_line=%client_secret_line:"=%
set GMAIL_CLIENT_SECRET=%client_secret_line%

set refresh_token_line=%refresh_token_line:"refresh_token": "=%
set refresh_token_line=%refresh_token_line:",=%
set refresh_token_line=%refresh_token_line:"=%
set GMAIL_REFRESH_TOKEN=%refresh_token_line%

:: Afficher les variables
echo Variables d'environnement:
echo GMAIL_CLIENT_ID=%GMAIL_CLIENT_ID%
echo GMAIL_CLIENT_SECRET=%GMAIL_CLIENT_SECRET:~0,5%...
echo GMAIL_REFRESH_TOKEN=%GMAIL_REFRESH_TOKEN:~0,5%...
echo.

:: Executer le script
node "%~dp0github-actions-email.js" "{\"to\":\"gerivonderbitsh@gmail.com\",\"subject\":\"Test GitHub Actions Email\",\"body\":\"Ceci est un test d'envoi d'email depuis GitHub Actions.\\n\\nSi vous recevez cet email, cela signifie que la configuration a été effectuée avec succès.\\n\\nCordialement,\\nLe script de test\"}"

echo.
echo Processus termine. Verifiez les instructions ci-dessus.
echo.
pause
