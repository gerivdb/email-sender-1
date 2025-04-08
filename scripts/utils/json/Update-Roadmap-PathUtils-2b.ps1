# Update-Roadmap-PathUtils-2b.ps1
# Script pour mettre à jour la roadmap avec les tâches de gestion des chemins terminées (section 2.b)

# Importer le module Path-Manager
$PathManagerModule = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "path-utils\Path-Manager.psm1"
if (Test-Path -Path $PathManagerModule) {
    Import-Module $PathManagerModule -Force
} else {
    Write-Error "Module Path-Manager non trouve: $PathManagerModule"
    exit 1
}

# Initialiser le gestionnaire de chemins
Initialize-PathManager

# Chemin de la roadmap
$RoadmapPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "roadmap_perso.md"

# Vérifier que le fichier roadmap existe
if (-not (Test-Path -Path $RoadmapPath)) {
    Write-Error "Fichier roadmap non trouve: $RoadmapPath"
    exit 1
}

# Lire le contenu de la roadmap
$RoadmapContent = Get-Content -Path $RoadmapPath -Raw

# Mettre à jour les tâches de la section 2.b
$RoadmapContent = $RoadmapContent -replace "- \[ \] Résoudre les problèmes d'encodage des caractères dans les scripts PowerShell", "- [x] Résoudre les problèmes d'encodage des caractères dans les scripts PowerShell - *Termine le $(Get-Date -Format "dd/MM/yyyy")*"
$RoadmapContent = $RoadmapContent -replace "- \[ \] Améliorer les tests pour s'assurer que toutes les fonctions fonctionnent correctement", "- [x] Améliorer les tests pour s'assurer que toutes les fonctions fonctionnent correctement - *Termine le $(Get-Date -Format "dd/MM/yyyy")*"
$RoadmapContent = $RoadmapContent -replace "- \[ \] Intégrer ces outils dans les autres scripts du projet", "- [x] Intégrer ces outils dans les autres scripts du projet - *Termine le $(Get-Date -Format "dd/MM/yyyy")*"
$RoadmapContent = $RoadmapContent -replace "- \[ \] Documenter les bonnes pratiques pour l'utilisation de ces outils", "- [x] Documenter les bonnes pratiques pour l'utilisation de ces outils - *Termine le $(Get-Date -Format "dd/MM/yyyy")*"

# Mettre à jour la progression de la section 2.b
$RoadmapContent = $RoadmapContent -replace "\*\*Progression\*\*: 0% \(section 2\.b\)", "**Progression**: 100% (section 2.b)"

# Mettre à jour la date de dernière mise à jour
$RoadmapContent = $RoadmapContent -replace "\*Derniere mise a jour: .*\*", "*Derniere mise a jour: $(Get-Date -Format "dd/MM/yyyy HH:mm")*"

# Écrire le contenu mis à jour dans le fichier roadmap
Set-Content -Path $RoadmapPath -Value $RoadmapContent

Write-Host "✅ Roadmap mise à jour avec succès." -ForegroundColor Green
