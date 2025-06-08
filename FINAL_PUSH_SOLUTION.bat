@echo off
echo === SOLUTION DE PUSH GITHUB FINALE ===
echo Date: 8 juin 2025
echo.

cd /d "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"

echo 1. Verification de la branche actuelle...
git branch
echo.

echo 2. Configuration du depot distant...
git remote set-url origin https://github.com/gerivdb/email-sender-1.git 2>nul
if %errorlevel% neq 0 (
    echo Ajout du depot distant...
    git remote add origin https://github.com/gerivdb/email-sender-1.git
)
echo.

echo 3. Affichage des depots distants...
git remote -v
echo.

echo 4. PUSH vers GitHub (branche manager/powershell-optimization)...
git push origin manager/powershell-optimization
if %errorlevel% neq 0 (
    echo ECHEC du push normal, tentative avec force push...
    git push -f origin manager/powershell-optimization
    if %errorlevel% neq 0 (
        echo ERREUR: Impossible de pusher meme avec force.
        echo PUSH FAILED - %date% %time% > GITHUB_PUSH_ERROR.txt
    ) else (
        echo SUCCESS AVEC FORCE PUSH!
        echo PUSH SUCCESS (FORCE) - %date% %time% > GITHUB_PUSH_SUCCESS_FORCE.txt
    )
) else (
    echo SUCCESS!
    echo PUSH SUCCESS - %date% %time% > GITHUB_PUSH_SUCCESS.txt
)

echo.
echo 5. Verification du statut actuel...
git status
echo.

echo === FIN DU SCRIPT ===
pause
