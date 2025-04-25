@echo off
echo ===================================================
echo Configuration d'EMAIL_PASSWORD pour GitHub Actions
echo ===================================================
echo.
echo Ce script va:
echo 1. Creer un compte de service GCP avec acces Gmail
echo 2. Generer une cle pour ce compte de service
echo 3. Configurer EMAIL_PASSWORD dans le fichier .env local
echo 4. Configurer EMAIL_PASSWORD comme secret dans GitHub Actions
echo.
echo Prerequis:
echo - Le serveur GCP-MCP doit etre configure (token.json)
echo - Le token GitHub doit etre configure dans le fichier .env
echo.
echo Appuyez sur une touche pour continuer...
pause > nul

echo.
echo [1/4] Creation du compte de service GCP...
call "%~dp0create-service-account.cmd"

echo.
echo [2/4] Configuration d'EMAIL_PASSWORD dans le fichier .env local...
powershell -ExecutionPolicy Bypass -File "%~dp0configure-email-password.ps1"

echo.
echo [3/4] Installation des dependances pour GitHub...
npm install @octokit/rest libsodium-wrappers --save

echo.
echo [4/4] Configuration du secret dans GitHub Actions...
call "%~dp0configure-github-secret.cmd"

echo.
echo ===================================================
echo Configuration terminee!
echo ===================================================
echo.
echo Vous pouvez maintenant utiliser EMAIL_PASSWORD dans vos workflows GitHub Actions.
echo.
pause
