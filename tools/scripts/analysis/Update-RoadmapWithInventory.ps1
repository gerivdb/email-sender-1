#Requires -Version 5.1
<#
.SYNOPSIS
    Met Ã  jour la roadmap avec les nouvelles fonctionnalitÃ©s d'inventaire et de classification des scripts.
.DESCRIPTION
    Ce script met Ã  jour la roadmap complÃ¨te avec les nouvelles fonctionnalitÃ©s d'inventaire
    et de classification des scripts que nous avons dÃ©veloppÃ©es.
.PARAMETER RoadmapPath
    Chemin du fichier roadmap Ã  mettre Ã  jour.
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

# VÃ©rifier que le fichier roadmap existe
if (-not (Test-Path -Path $RoadmapPath -PathType Leaf)) {
    Write-Error "Le fichier roadmap n'existe pas: $RoadmapPath"
    exit 1
}

# Lire le contenu du fichier roadmap
$roadmapContent = Get-Content -Path $RoadmapPath -Raw

# DÃ©finir le motif pour trouver la section "1.1.2.1 SystÃ¨me d'inventaire et de classification des scripts"
$sectionPattern = "(?s)(### 1\.1\.2\.1 SystÃ¨me d'inventaire et de classification des scripts.*?)(\n+### 1\.1\.2\.2|\Z)"

# VÃ©rifier si la section existe
if (-not ($roadmapContent -match $sectionPattern)) {
    Write-Error "La section '1.1.2.1 SystÃ¨me d'inventaire et de classification des scripts' n'a pas Ã©tÃ© trouvÃ©e dans le fichier roadmap."
    exit 1
}

# Extraire la section existante
$existingSection = $matches[1]
$afterSection = $matches[2]

# DÃ©finir les nouvelles sous-sections Ã  ajouter
$newSubsections = @"

#### A. Mise en place d'un systÃ¨me d'inventaire complet
- [x] DÃ©velopper un module PowerShell `ScriptInventoryManager.psm1` pour centraliser l'inventaire
  - [x] IntÃ©grer les fonctionnalitÃ©s de `script_inventory.py` et `script_database.py` existants
  - [x] Ajouter la dÃ©tection automatique des mÃ©tadonnÃ©es (auteur, version, description)
  - [x] ImplÃ©menter un systÃ¨me de tags pour catÃ©goriser les scripts
  - [x] CrÃ©er une base de donnÃ©es JSON pour stocker les informations d'inventaire
- [x] DÃ©velopper une interface de consultation de l'inventaire
  - [x] CrÃ©er un script `Show-ScriptInventory.ps1` avec filtrage et tri
  - [x] ImplÃ©menter l'exportation des rÃ©sultats en diffÃ©rents formats (CSV, JSON, HTML)
  - [x] Ajouter des visualisations statistiques (nombre de scripts par catÃ©gorie, etc.)
  - [x] IntÃ©grer avec le systÃ¨me de documentation

#### B. Analyse et dÃ©tection des scripts redondants
- [x] DÃ©velopper des fonctionnalitÃ©s d'analyse des scripts
  - [x] ImplÃ©menter la dÃ©tection des scripts similaires par analyse de contenu
  - [x] CrÃ©er un algorithme de comparaison basÃ© sur la similaritÃ© de Levenshtein
  - [x] GÃ©nÃ©rer des rapports de duplication avec recommandations
  - [x] Ajouter la dÃ©tection des versions multiples du mÃªme script
- [x] CrÃ©er un script `Find-RedundantScripts.ps1` pour la dÃ©tection des scripts redondants
  - [x] ImplÃ©menter des filtres par seuil de similaritÃ©
  - [x] Ajouter l'export des rÃ©sultats en diffÃ©rents formats
  - [x] GÃ©nÃ©rer des rapports dÃ©taillÃ©s avec recommandations

#### C. SystÃ¨me de classification hiÃ©rarchique
- [x] CrÃ©er un script `Classify-Scripts.ps1` pour la classification des scripts
  - [x] DÃ©finir une taxonomie claire pour les types de scripts
  - [x] ImplÃ©menter un systÃ¨me de classification automatique basÃ© sur le contenu
  - [x] GÃ©nÃ©rer une structure de dossiers basÃ©e sur la classification
- [x] DÃ©velopper un systÃ¨me de mÃ©tadonnÃ©es standardisÃ©es
  - [x] DÃ©finir un format de mÃ©tadonnÃ©es commun (auteur, version, description, etc.)
  - [x] ImplÃ©menter la validation des mÃ©tadonnÃ©es
  - [x] GÃ©nÃ©rer des rapports de conformitÃ© des mÃ©tadonnÃ©es

#### D. Tests et documentation
- [x] CrÃ©er des tests unitaires pour le systÃ¨me d'inventaire
  - [x] DÃ©velopper `Test-ScriptInventorySystem.ps1` pour tester les fonctionnalitÃ©s
  - [x] ImplÃ©menter des tests pour la dÃ©tection des scripts dupliquÃ©s
  - [x] Ajouter des tests pour la classification des scripts
- [x] Documenter le systÃ¨me d'inventaire
  - [x] CrÃ©er un guide d'utilisation avec exemples
  - [x] Documenter l'API du module ScriptInventoryManager
  - [x] Ajouter des exemples de scripts d'utilisation
"@

# VÃ©rifier si les nouvelles sous-sections sont dÃ©jÃ  prÃ©sentes
if ($existingSection -match [regex]::Escape("#### A. Mise en place d'un systÃ¨me d'inventaire complet")) {
    Write-Host "Les nouvelles sous-sections sont dÃ©jÃ  prÃ©sentes dans la roadmap." -ForegroundColor Yellow
    exit 0
}

# Ajouter les nouvelles sous-sections Ã  la fin de la section existante
$updatedSection = $existingSection + $newSubsections

# Mettre Ã  jour le contenu de la roadmap
$updatedRoadmapContent = $roadmapContent -replace [regex]::Escape($existingSection), $updatedSection

# Sauvegarder une copie de sauvegarde du fichier roadmap original
$backupPath = "$RoadmapPath.bak"
Copy-Item -Path $RoadmapPath -Destination $backupPath -Force
Write-Host "Copie de sauvegarde crÃ©Ã©e: $backupPath" -ForegroundColor Green

# Ã‰crire le contenu mis Ã  jour dans le fichier roadmap
Set-Content -Path $RoadmapPath -Value $updatedRoadmapContent -Encoding UTF8
Write-Host "Roadmap mise Ã  jour avec succÃ¨s: $RoadmapPath" -ForegroundColor Green

# Afficher un rÃ©sumÃ© des modifications
Write-Host "`nRÃ©sumÃ© des modifications:" -ForegroundColor Cyan
Write-Host "- Mise Ã  jour de la section '1.1.2.1 SystÃ¨me d'inventaire et de classification des scripts'" -ForegroundColor White
Write-Host "- Ajout de 4 sous-sections (A, B, C, D) avec 28 tÃ¢ches complÃ©tÃ©es" -ForegroundColor White
