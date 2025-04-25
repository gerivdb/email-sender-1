#Requires -Version 5.1
<#
.SYNOPSIS
    Met à jour la roadmap avec les nouvelles fonctionnalités d'inventaire et de classification des scripts.
.DESCRIPTION
    Ce script met à jour la roadmap complète avec les nouvelles fonctionnalités d'inventaire
    et de classification des scripts que nous avons développées.
.PARAMETER RoadmapPath
    Chemin du fichier roadmap à mettre à jour.
.EXAMPLE
    .\Update-RoadmapWithInventory.ps1 -RoadmapPath "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\roadmap_complete.md"
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

# Définir le motif pour trouver la section "1.1.2.1 Système d'inventaire et de classification des scripts"
$sectionPattern = "(?s)(### 1\.1\.2\.1 Système d'inventaire et de classification des scripts.*?)(\n+### 1\.1\.2\.2|\Z)"

# Vérifier si la section existe
if (-not ($roadmapContent -match $sectionPattern)) {
    Write-Error "La section '1.1.2.1 Système d'inventaire et de classification des scripts' n'a pas été trouvée dans le fichier roadmap."
    exit 1
}

# Extraire la section existante
$existingSection = $matches[1]
$afterSection = $matches[2]

# Définir les nouvelles sous-sections à ajouter
$newSubsections = @"

#### A. Mise en place d'un système d'inventaire complet
- [x] Développer un module PowerShell `ScriptInventoryManager.psm1` pour centraliser l'inventaire
  - [x] Intégrer les fonctionnalités de `script_inventory.py` et `script_database.py` existants
  - [x] Ajouter la détection automatique des métadonnées (auteur, version, description)
  - [x] Implémenter un système de tags pour catégoriser les scripts
  - [x] Créer une base de données JSON pour stocker les informations d'inventaire
- [x] Développer une interface de consultation de l'inventaire
  - [x] Créer un script `Show-ScriptInventory.ps1` avec filtrage et tri
  - [x] Implémenter l'exportation des résultats en différents formats (CSV, JSON, HTML)
  - [x] Ajouter des visualisations statistiques (nombre de scripts par catégorie, etc.)
  - [x] Intégrer avec le système de documentation

#### B. Analyse et détection des scripts redondants
- [x] Développer des fonctionnalités d'analyse des scripts
  - [x] Implémenter la détection des scripts similaires par analyse de contenu
  - [x] Créer un algorithme de comparaison basé sur la similarité de Levenshtein
  - [x] Générer des rapports de duplication avec recommandations
  - [x] Ajouter la détection des versions multiples du même script
- [x] Créer un script `Find-RedundantScripts.ps1` pour la détection des scripts redondants
  - [x] Implémenter des filtres par seuil de similarité
  - [x] Ajouter l'export des résultats en différents formats
  - [x] Générer des rapports détaillés avec recommandations

#### C. Système de classification hiérarchique
- [x] Créer un script `Classify-Scripts.ps1` pour la classification des scripts
  - [x] Définir une taxonomie claire pour les types de scripts
  - [x] Implémenter un système de classification automatique basé sur le contenu
  - [x] Générer une structure de dossiers basée sur la classification
- [x] Développer un système de métadonnées standardisées
  - [x] Définir un format de métadonnées commun (auteur, version, description, etc.)
  - [x] Implémenter la validation des métadonnées
  - [x] Générer des rapports de conformité des métadonnées

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

# Vérifier si les nouvelles sous-sections sont déjà présentes
if ($existingSection -match [regex]::Escape("#### A. Mise en place d'un système d'inventaire complet")) {
    Write-Host "Les nouvelles sous-sections sont déjà présentes dans la roadmap." -ForegroundColor Yellow
    exit 0
}

# Ajouter les nouvelles sous-sections à la fin de la section existante
$updatedSection = $existingSection + $newSubsections

# Mettre à jour le contenu de la roadmap
$updatedRoadmapContent = $roadmapContent -replace [regex]::Escape($existingSection), $updatedSection

# Sauvegarder une copie de sauvegarde du fichier roadmap original
$backupPath = "$RoadmapPath.bak"
Copy-Item -Path $RoadmapPath -Destination $backupPath -Force
Write-Host "Copie de sauvegarde créée: $backupPath" -ForegroundColor Green

# Écrire le contenu mis à jour dans le fichier roadmap
Set-Content -Path $RoadmapPath -Value $updatedRoadmapContent -Encoding UTF8
Write-Host "Roadmap mise à jour avec succès: $RoadmapPath" -ForegroundColor Green

# Afficher un résumé des modifications
Write-Host "`nRésumé des modifications:" -ForegroundColor Cyan
Write-Host "- Mise à jour de la section '1.1.2.1 Système d'inventaire et de classification des scripts'" -ForegroundColor White
Write-Host "- Ajout de 4 sous-sections (A, B, C, D) avec 28 tâches complétées" -ForegroundColor White
