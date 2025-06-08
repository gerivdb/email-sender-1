@echo off
REM SCRIPT DE PUSH GITHUB SIMPLIFIÉ
REM Date: 8 juin 2025
REM Exécutez simplement ce fichier en double-cliquant dessus

echo === PUSH GITHUB SIMPLIFIÉ ===
echo Date: 8 juin 2025
echo.

cd /d "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"

echo 1. Branche actuelle:
git branch
echo.

echo 2. Configuration du dépôt distant:
git remote set-url origin https://github.com/gerivdb/email-sender-1.git
echo.

echo 3. Push vers GitHub (branche manager/powershell-optimization):
git push origin manager/powershell-optimization
echo.

echo === PUSH TERMINÉ ===
echo Si vous rencontrez des erreurs d'authentification, référez-vous au document SOLUTION_GITHUB_PUSH_UPDATED.md
echo.
pause
