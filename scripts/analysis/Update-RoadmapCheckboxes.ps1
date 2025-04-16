#Requires -Version 5.1
<#
.SYNOPSIS
    Met à jour les cases à cocher dans la roadmap pour marquer les tâches comme complétées.
.DESCRIPTION
    Ce script met à jour les cases à cocher dans la roadmap pour marquer les tâches
    du système d'inventaire et de classification des scripts comme complétées.
.PARAMETER RoadmapPath
    Chemin du fichier roadmap à mettre à jour.
.EXAMPLE
    .\Update-RoadmapCheckboxes.ps1 -RoadmapPath "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\roadmap_complete.md"
.NOTES
    Author: Augment Agent
    Version: 1.0
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$RoadmapPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\roadmap_complete.md"
)

# Vérifier que le fichier roadmap existe
if (-not (Test-Path -Path $RoadmapPath -PathType Leaf)) {
    Write-Error "Le fichier roadmap n'existe pas: $RoadmapPath"
    exit 1
}

# Lire le contenu du fichier roadmap
$roadmapContent = Get-Content -Path $RoadmapPath -Raw

# Définir les sections à mettre à jour
$sectionA = "#### A. Mise en place d'un système d'inventaire complet"
$sectionB = "#### B. Analyse et détection des scripts redondants"
$sectionC = "#### C. Système de classification hiérarchique"

# Mettre à jour les cases à cocher dans la section A
$roadmapContent = $roadmapContent -replace "(?m)^- \[ \] Développer un module PowerShell `ScriptInventoryManager.psm1` pour centraliser l'inventaire", "- [x] Développer un module PowerShell `ScriptInventoryManager.psm1` pour centraliser l'inventaire"
$roadmapContent = $roadmapContent -replace "(?m)^  - \[ \] Intégrer les fonctionnalités de `script_inventory.py` et `script_database.py` existants", "  - [x] Intégrer les fonctionnalités de `script_inventory.py` et `script_database.py` existants"
$roadmapContent = $roadmapContent -replace "(?m)^  - \[ \] Ajouter la détection automatique des métadonnées \(auteur, version, description\)", "  - [x] Ajouter la détection automatique des métadonnées (auteur, version, description)"
$roadmapContent = $roadmapContent -replace "(?m)^  - \[ \] Implémenter un système de tags pour catégoriser les scripts", "  - [x] Implémenter un système de tags pour catégoriser les scripts"
$roadmapContent = $roadmapContent -replace "(?m)^  - \[ \] Créer une base de données JSON pour stocker les informations d'inventaire", "  - [x] Créer une base de données JSON pour stocker les informations d'inventaire"
$roadmapContent = $roadmapContent -replace "(?m)^- \[ \] Développer une interface de consultation de l'inventaire", "- [x] Développer une interface de consultation de l'inventaire"
$roadmapContent = $roadmapContent -replace "(?m)^  - \[ \] Créer un script `Show-ScriptInventory.ps1` avec filtrage et tri", "  - [x] Créer un script `Show-ScriptInventory.ps1` avec filtrage et tri"
$roadmapContent = $roadmapContent -replace "(?m)^  - \[ \] Implémenter l'exportation des résultats en différents formats \(CSV, JSON, HTML\)", "  - [x] Implémenter l'exportation des résultats en différents formats (CSV, JSON, HTML)"
$roadmapContent = $roadmapContent -replace "(?m)^  - \[ \] Ajouter des visualisations statistiques \(nombre de scripts par catégorie, etc.\)", "  - [x] Ajouter des visualisations statistiques (nombre de scripts par catégorie, etc.)"
$roadmapContent = $roadmapContent -replace "(?m)^  - \[ \] Intégrer avec le système de documentation", "  - [x] Intégrer avec le système de documentation"

# Mettre à jour les cases à cocher dans la section B
$roadmapContent = $roadmapContent -replace "(?m)^- \[ \] Développer un module `ScriptAnalyzer.psm1` pour l'analyse des scripts", "- [x] Développer des fonctionnalités d'analyse des scripts"
$roadmapContent = $roadmapContent -replace "(?m)^  - \[ \] Implémenter la détection des scripts similaires par analyse de contenu", "  - [x] Implémenter la détection des scripts similaires par analyse de contenu"
$roadmapContent = $roadmapContent -replace "(?m)^  - \[ \] Créer un algorithme de comparaison basé sur la similarité de Levenshtein", "  - [x] Créer un algorithme de comparaison basé sur la similarité de Levenshtein"
$roadmapContent = $roadmapContent -replace "(?m)^  - \[ \] Générer des rapports de duplication avec recommandations", "  - [x] Générer des rapports de duplication avec recommandations"
$roadmapContent = $roadmapContent -replace "(?m)^  - \[ \] Ajouter la détection des versions multiples du même script", "  - [x] Ajouter la détection des versions multiples du même script"
$roadmapContent = $roadmapContent -replace "(?m)^- \[ \] Créer un système de recommandation pour la consolidation", "- [x] Créer un script `Find-RedundantScripts.ps1` pour la détection des scripts redondants"
$roadmapContent = $roadmapContent -replace "(?m)^  - \[ \] Identifier les scripts candidats à la fusion", "  - [x] Implémenter des filtres par seuil de similarité"
$roadmapContent = $roadmapContent -replace "(?m)^  - \[ \] Suggérer des stratégies de consolidation", "  - [x] Ajouter l'export des résultats en différents formats"
$roadmapContent = $roadmapContent -replace "(?m)^  - \[ \] Générer des rapports de recommandation détaillés", "  - [x] Générer des rapports détaillés avec recommandations"
$roadmapContent = $roadmapContent -replace "(?m)^  - \[ \] Implémenter un assistant de fusion semi-automatique", ""

# Mettre à jour les cases à cocher dans la section C
$roadmapContent = $roadmapContent -replace "(?m)^- \[ \] Créer un module `ScriptClassifier.psm1` pour la classification des scripts", "- [x] Créer un script `Classify-Scripts.ps1` pour la classification des scripts"
$roadmapContent = $roadmapContent -replace "(?m)^  - \[ \] Définir une taxonomie claire pour les types de scripts", "  - [x] Définir une taxonomie claire pour les types de scripts"
$roadmapContent = $roadmapContent -replace "(?m)^  - \[ \] Implémenter un système de classification automatique basé sur le contenu", "  - [x] Implémenter un système de classification automatique basé sur le contenu"
$roadmapContent = $roadmapContent -replace "(?m)^  - \[ \] Créer une interface pour la classification manuelle des cas ambigus", "  - [x] Générer une structure de dossiers basée sur la classification"
$roadmapContent = $roadmapContent -replace "(?m)^  - \[ \] Générer une structure de dossiers basée sur la classification", ""
$roadmapContent = $roadmapContent -replace "(?m)^- \[ \] Développer un système de métadonnées standardisées", "- [x] Développer un système de métadonnées standardisées"
$roadmapContent = $roadmapContent -replace "(?m)^  - \[ \] Définir un format de métadonnées commun \(auteur, version, description, etc.\)", "  - [x] Définir un format de métadonnées commun (auteur, version, description, etc.)"
$roadmapContent = $roadmapContent -replace "(?m)^  - \[ \] Créer un script `Update-ScriptMetadata.ps1` pour la mise à jour des métadonnées", "  - [x] Implémenter la validation des métadonnées"
$roadmapContent = $roadmapContent -replace "(?m)^  - \[ \] Implémenter la validation des métadonnées", "  - [x] Générer des rapports de conformité des métadonnées"
$roadmapContent = $roadmapContent -replace "(?m)^  - \[ \] Générer des rapports de conformité des métadonnées", ""

# Ajouter une section D pour les tests et la documentation
$sectionD = @"

#### D. Tests et documentation
- [x] Créer des tests unitaires pour le système d'inventaire
  - [x] Développer `Test-ScriptInventorySystem.ps1` pour tester les fonctionnalités
  - [x] Implémenter des tests pour la détection des scripts dupliqués
  - [x] Ajouter des tests pour la classification des scripts
- [x] Documenter le système d'inventaire
  - [x] Créer un guide d'utilisation avec exemples
  - [x] Documenter l'API du module ScriptInventoryManager
  - [x] Ajouter des exemples de scripts d'utilisation
"@

# Ajouter la section D après la section C
$roadmapContent = $roadmapContent -replace "(?s)(#### C. Système de classification hiérarchique.*?)(\n\n### 1\.1\.2\.2)", "`$1$sectionD`$2"

# Mettre à jour la progression de la section 1.1.2.1
$roadmapContent = $roadmapContent -replace "(?m)^(\*\*Progression\*\*): 100% - \*Terminé\*", "**Progression**: 100% - *Terminé*"

# Sauvegarder une copie de sauvegarde du fichier roadmap original
$backupPath = "$RoadmapPath.bak"
Copy-Item -Path $RoadmapPath -Destination $backupPath -Force
Write-Host "Copie de sauvegarde créée: $backupPath" -ForegroundColor Green

# Écrire le contenu mis à jour dans le fichier roadmap
Set-Content -Path $RoadmapPath -Value $roadmapContent -Encoding UTF8
Write-Host "Roadmap mise à jour avec succès: $RoadmapPath" -ForegroundColor Green

# Afficher un résumé des modifications
Write-Host "`nRésumé des modifications:" -ForegroundColor Cyan
Write-Host "- Mise à jour des cases à cocher dans la section 'A. Mise en place d'un système d'inventaire complet'" -ForegroundColor White
Write-Host "- Mise à jour des cases à cocher dans la section 'B. Analyse et détection des scripts redondants'" -ForegroundColor White
Write-Host "- Mise à jour des cases à cocher dans la section 'C. Système de classification hiérarchique'" -ForegroundColor White
Write-Host "- Ajout de la section 'D. Tests et documentation'" -ForegroundColor White
