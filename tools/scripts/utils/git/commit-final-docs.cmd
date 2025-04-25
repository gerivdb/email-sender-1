@echo off
echo Ajout des fichiers modifiés...
git add README.md
git add docs\guides\GUIDE_NOUVELLES_FONCTIONNALITES.md
git add docs\communications\ANNONCE_NOUVELLES_FONCTIONNALITES.md

echo.
echo Commit des modifications...
git commit -m "docs: Mise à jour de la documentation et préparation de l'annonce des nouvelles fonctionnalités"

echo.
echo Push vers GitHub...
git push origin main

echo.
echo Opération terminée !
pause
