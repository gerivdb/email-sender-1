@echo on
REM Script ultra-simple pour le push GitHub
REM Date: 8 juin 2025

cd /d "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"

echo ===== DEBUT PUSH GITHUB =====
echo Date et heure: %date% %time%
echo.

echo 1) Branche actuelle:
git branch
echo.

echo 2) Configuration du remote:
git remote -v
echo.

echo 3) PUSH VERS GITHUB:
git push origin manager/powershell-optimization
echo Code de retour: %errorlevel%
echo.

echo 4) Si erreur, essai avec authentification token:
echo Entrez votre nom d'utilisateur GitHub:
set /p username=
echo Entrez votre token GitHub:
set /p token=

echo Configuration du remote avec token...
git remote set-url origin https://%username%:%token%@github.com/gerivdb/email-sender-1.git

echo Push avec token...
git push origin manager/powershell-optimization
echo Code de retour: %errorlevel%
echo.

echo ===== FIN PUSH GITHUB =====
echo Verifiez: https://github.com/gerivdb/email-sender-1/tree/manager/powershell-optimization
echo.

echo Appuyez sur une touche pour fermer cette fenetre...
pause >nul
