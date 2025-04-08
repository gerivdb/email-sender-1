@echo off
echo Test d'impersonification...
echo.
echo Ce script va tester si le compte de service peut impersonifier
echo l'utilisateur gerivonderbitsh+dev@gmail.com.
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
node "%~dp0test-impersonation.js"

echo.
echo Processus termine. Verifiez les instructions ci-dessus.
echo.
pause
