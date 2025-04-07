# Script pour mettre à jour manuellement la roadmap

# Importer le module de mise à jour de la roadmap
$updaterPath = Join-Path -Path $PSScriptRoot -ChildPath "RoadmapUpdater.ps1"
if (Test-Path -Path $updaterPath) {
    . $updaterPath
}
else {
    Write-Error "Le module de mise à jour de la roadmap est introuvable: $updaterPath"
    exit 1
}

# Mettre à jour la roadmap
Write-Host "Mise à jour de la roadmap..."
$changes = Update-Roadmap

if ($changes) {
    Write-Host "La roadmap a été mise à jour avec succès."
}
else {
    Write-Host "Aucune modification n'a été apportée à la roadmap."
}

# Afficher les instructions pour l'installation des hooks Git
Write-Host "`nPour installer les hooks Git qui mettront à jour automatiquement la roadmap :"
Write-Host "1. Exécutez le script Install-RoadmapHook.ps1"
Write-Host "2. La roadmap sera mise à jour avant chaque commit et après chaque fusion"

# Afficher les instructions pour marquer manuellement des tâches comme terminées
Write-Host "`nPour marquer manuellement une tâche comme terminée :"
Write-Host "1. Importez le module RoadmapUpdater.ps1"
Write-Host "2. Utilisez la fonction Set-TaskCompleted -PhaseTitle 'Titre de la phase' -TaskTitle 'Titre de la tâche'"
Write-Host "3. Utilisez la fonction Set-PhaseCompleted -PhaseTitle 'Titre de la phase' pour marquer une phase entière"
