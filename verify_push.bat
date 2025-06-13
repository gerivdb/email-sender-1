@echo off
echo === VÉRIFICATION DU STATUT GIT ===
cd /d "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
echo.
echo Current branch:
git branch --show-current
echo.
echo Status:
git status
echo.
echo Remote repositories:
git remote -v
echo.
echo Last commit:
git log -1 --oneline
echo.
echo === FIN DE LA VÉRIFICATION ===
pause
