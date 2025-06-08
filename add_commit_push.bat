@echo on
REM Script ultra-simple pour committer et pousser les fichiers restants
REM Date: 8 juin 2025

cd /d "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"

echo ===== AJOUT ET COMMIT DES FICHIERS RESTANTS =====

echo.
echo Statut actuel:
git status

echo.
echo Ajout des fichiers:
git add .

echo.
echo Creation du commit:
git commit -m "fix: ajout des 22 fichiers restants"

echo.
echo Push vers GitHub:
git push origin manager/powershell-optimization

echo.
echo ===== OPERATION TERMINEE =====
echo Verifiez: https://github.com/gerivdb/email-sender-1/tree/manager/powershell-optimization
pause
