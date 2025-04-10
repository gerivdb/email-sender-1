#Requires -Version 5.1
<#
.SYNOPSIS
    Met à jour la roadmap avec les améliorations implémentées.

.DESCRIPTION
    Ce script met à jour la roadmap avec les améliorations implémentées
    pour la détection de format de fichiers.

.PARAMETER RoadmapPath
    Le chemin vers le fichier de roadmap à mettre à jour.
    Par défaut, utilise 'Roadmap/roadmap_perso.md'.

.EXAMPLE
    .\Update-Roadmap.ps1 -RoadmapPath "D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/Roadmap/roadmap_perso.md"

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$RoadmapPath = (Join-Path -Path (Join-Path -Path (Split-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -Parent) -ChildPath "Roadmap") -ChildPath "roadmap_perso.md")
)

# Vérifier si le fichier de roadmap existe
if (-not (Test-Path -Path $RoadmapPath -PathType Leaf)) {
    Write-Error "Le fichier de roadmap $RoadmapPath n'existe pas."
    return
}

# Lire le contenu du fichier de roadmap
$roadmapContent = Get-Content -Path $RoadmapPath -Raw

# Définir les motifs de recherche et de remplacement
$sectionPattern = '## 2\.1\.2 Implémentation des améliorations\s+- \[ \] Développer des algorithmes de détection plus robustes\s+- \[ \] Implémenter l''analyse de contenu basée sur des expressions régulières avancées\s+- \[ \] Ajouter la détection basée sur les signatures de format \(en-têtes, structure\)\s+- \[ \] Créer un système de score pour déterminer le format le plus probable\s+- \[ \] Implémenter la détection des encodages de caractères'

$sectionReplacement = @"
## 2.1.2 Implémentation des améliorations
- [x] Développer des algorithmes de détection plus robustes
- [x] Implémenter l'analyse de contenu basée sur des expressions régulières avancées
- [x] Ajouter la détection basée sur les signatures de format (en-têtes, structure)
- [x] Créer un système de score pour déterminer le format le plus probable
- [x] Implémenter la détection des encodages de caractères
"@

# Mettre à jour le contenu de la roadmap
$updatedContent = $roadmapContent -replace $sectionPattern, $sectionReplacement

# Enregistrer le contenu mis à jour
$updatedContent | Out-File -FilePath $RoadmapPath -Encoding utf8

Write-Host "Roadmap mise à jour : $RoadmapPath" -ForegroundColor Green

# Afficher les modifications
Write-Host "`nModifications apportées :" -ForegroundColor Cyan
Write-Host "  Section 2.1.2 Implémentation des améliorations mise à jour" -ForegroundColor White
Write-Host "  Toutes les tâches marquées comme terminées" -ForegroundColor White
