@echo off
git add README.md
git add docs\guides\GUIDE_NOUVELLES_FONCTIONNALITES.md
git add docs\communications\ANNONCE_NOUVELLES_FONCTIONNALITES.md
git commit -m "docs: Mise à jour de la documentation et préparation de l'annonce des nouvelles fonctionnalités"
git push origin main
pause
