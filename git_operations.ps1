# Script pour effectuer les opérations Git

# Définir le répertoire de travail
$workingDir = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
Set-Location $workingDir

# Ajouter les fichiers
Write-Host "Ajout des fichiers au staging..."
git add AugmentAutoKeepAll.ahk
git add AugmentAutoKeepAll_Enhanced.ahk
git add AugmentAutoKeepAll_Pro.ahk
git add AugmentAutoKeepAll_Guide.md
git add "Roadmap\roadmap_perso.md"
git add -f "logs\dev_journal\2025-04-11_AutoHotkey_Augment.md"

# Vérifier le statut
Write-Host "Statut Git actuel :"
git status

# Effectuer le commit
Write-Host "Création du commit..."
git commit -m "Ajout de scripts AutoHotkey pour automatiser la validation des boîtes de dialogue 'Keep All' dans Augment Agent"

# Pousser les modifications
Write-Host "Push des modifications..."
git push

Write-Host "Opérations Git terminées."
