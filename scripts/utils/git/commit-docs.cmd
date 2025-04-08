@echo off
cd /d "%~dp0\..\..\..\"
echo Répertoire courant : %CD%

echo.
echo Vérification du statut Git...
git status

echo.
echo Ajout des fichiers de documentation...
git add README.md docs\guides\GUIDE_NOUVELLES_FONCTIONNALITES.md docs\communications\ANNONCE_NOUVELLES_FONCTIONNALITES.md

echo.
echo Commit des modifications...
git commit -m "docs: Mise à jour de la documentation et préparation de l'annonce des nouvelles fonctionnalités"

echo.
echo Push vers GitHub...
git push origin main

echo.
echo Opération terminée !
pause
