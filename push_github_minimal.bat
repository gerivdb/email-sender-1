@echo off
REM Script de push GitHub ultra-simple
REM Lancez-le depuis une nouvelle fenêtre cmd

cd /d "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"

echo === PUSH GITHUB - SOLUTION SIMPLE ===
echo.

REM Vérifier la branche actuelle
echo 1. Branche actuelle:
git branch
echo.

REM Créer un fichier temporaire pour le token
echo Entrez votre nom d'utilisateur GitHub:
set /p username=

echo Entrez votre token GitHub:
set /p token=

echo 2. Configuration du remote avec token:
git remote set-url origin https://%username%:%token%@github.com/gerivdb/email-sender-1.git
echo Remote configuré (token masqué)
echo.

echo 3. Push vers la branche manager/powershell-optimization:
git push origin manager/powershell-optimization
if %errorlevel% neq 0 (
  echo Échec du push standard, tentative avec force push...
  git push -f origin manager/powershell-optimization
)

echo.
echo === OPÉRATION TERMINÉE ===
echo Vérifiez: https://github.com/gerivdb/email-sender-1/tree/manager/powershell-optimization

pause
