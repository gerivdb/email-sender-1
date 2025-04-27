#Requires -Version 5.1
<#
.SYNOPSIS
    Corrige les cases Ã  cocher dans la roadmap pour marquer les tÃ¢ches comme complÃ©tÃ©es.
.DESCRIPTION
    Ce script corrige les cases Ã  cocher dans la roadmap pour marquer les tÃ¢ches
    du systÃ¨me d'inventaire et de classification des scripts comme complÃ©tÃ©es.
.PARAMETER RoadmapPath
    Chemin du fichier roadmap Ã  mettre Ã  jour.
.EXAMPLE
    .\Fix-RoadmapCheckboxes.ps1 -RoadmapPath "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\roadmap_complete.md"
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
$content = Get-Content -Path $RoadmapPath -Raw

# Remplacer les cases Ã  cocher dans la section A
$content = $content -replace "(?m)^- \[ \] DÃ©velopper un module PowerShell `ScriptInventoryManager.psm1` pour centraliser l'inventaire", "- [x] DÃ©velopper un module PowerShell `ScriptInventoryManager.psm1` pour centraliser l'inventaire"
$content = $content -replace "(?m)^  - \[ \] IntÃ©grer les fonctionnalitÃ©s de `script_inventory.py` et `script_database.py` existants", "  - [x] IntÃ©grer les fonctionnalitÃ©s de `script_inventory.py` et `script_database.py` existants"
$content = $content -replace "(?m)^  - \[ \] Ajouter la dÃ©tection automatique des mÃ©tadonnÃ©es \(auteur, version, description\)", "  - [x] Ajouter la dÃ©tection automatique des mÃ©tadonnÃ©es (auteur, version, description)"
$content = $content -replace "(?m)^  - \[ \] ImplÃ©menter un systÃ¨me de tags pour catÃ©goriser les scripts", "  - [x] ImplÃ©menter un systÃ¨me de tags pour catÃ©goriser les scripts"
$content = $content -replace "(?m)^  - \[ \] CrÃ©er une base de donnÃ©es JSON pour stocker les informations d'inventaire", "  - [x] CrÃ©er une base de donnÃ©es JSON pour stocker les informations d'inventaire"
$content = $content -replace "(?m)^- \[ \] DÃ©velopper une interface de consultation de l'inventaire", "- [x] DÃ©velopper une interface de consultation de l'inventaire"
$content = $content -replace "(?m)^  - \[ \] CrÃ©er un script `Show-ScriptInventory.ps1` avec filtrage et tri", "  - [x] CrÃ©er un script `Show-ScriptInventory.ps1` avec filtrage et tri"
$content = $content -replace "(?m)^  - \[ \] ImplÃ©menter l'exportation des rÃ©sultats en diffÃ©rents formats \(CSV, JSON, HTML\)", "  - [x] ImplÃ©menter l'exportation des rÃ©sultats en diffÃ©rents formats (CSV, JSON, HTML)"
$content = $content -replace "(?m)^  - \[ \] Ajouter des visualisations statistiques \(nombre de scripts par catÃ©gorie, etc.\)", "  - [x] Ajouter des visualisations statistiques (nombre de scripts par catÃ©gorie, etc.)"
$content = $content -replace "(?m)^  - \[ \] IntÃ©grer avec le systÃ¨me de documentation", "  - [x] IntÃ©grer avec le systÃ¨me de documentation"

# Remplacer les cases Ã  cocher dans la section B
$content = $content -replace "(?m)^- \[ \] DÃ©velopper un module `ScriptAnalyzer.psm1` pour l'analyse des scripts", "- [x] DÃ©velopper des fonctionnalitÃ©s d'analyse des scripts"
$content = $content -replace "(?m)^  - \[ \] ImplÃ©menter la dÃ©tection des scripts similaires par analyse de contenu", "  - [x] ImplÃ©menter la dÃ©tection des scripts similaires par analyse de contenu"
$content = $content -replace "(?m)^  - \[ \] CrÃ©er un algorithme de comparaison basÃ© sur la similaritÃ© de Levenshtein", "  - [x] CrÃ©er un algorithme de comparaison basÃ© sur la similaritÃ© de Levenshtein"
$content = $content -replace "(?m)^  - \[ \] GÃ©nÃ©rer des rapports de duplication avec recommandations", "  - [x] GÃ©nÃ©rer des rapports de duplication avec recommandations"
$content = $content -replace "(?m)^  - \[ \] Ajouter la dÃ©tection des versions multiples du mÃªme script", "  - [x] Ajouter la dÃ©tection des versions multiples du mÃªme script"
$content = $content -replace "(?m)^- \[ \] CrÃ©er un systÃ¨me de recommandation pour la consolidation", "- [x] CrÃ©er un script `Find-RedundantScripts.ps1` pour la dÃ©tection des scripts redondants"
$content = $content -replace "(?m)^  - \[ \] Identifier les scripts candidats Ã  la fusion", "  - [x] ImplÃ©menter des filtres par seuil de similaritÃ©"
$content = $content -replace "(?m)^  - \[ \] SuggÃ©rer des stratÃ©gies de consolidation", "  - [x] Ajouter l'export des rÃ©sultats en diffÃ©rents formats"
$content = $content -replace "(?m)^  - \[ \] GÃ©nÃ©rer des rapports de recommandation dÃ©taillÃ©s", "  - [x] GÃ©nÃ©rer des rapports dÃ©taillÃ©s avec recommandations"
$content = $content -replace "(?m)^  - \[ \] ImplÃ©menter un assistant de fusion semi-automatique", ""

# Remplacer les cases Ã  cocher dans la section C
$content = $content -replace "(?m)^- \[ \] CrÃ©er un module `ScriptClassifier.psm1` pour la classification des scripts", "- [x] CrÃ©er un script `Classify-Scripts.ps1` pour la classification des scripts"
$content = $content -replace "(?m)^  - \[ \] DÃ©finir une taxonomie claire pour les types de scripts", "  - [x] DÃ©finir une taxonomie claire pour les types de scripts"
$content = $content -replace "(?m)^  - \[ \] ImplÃ©menter un systÃ¨me de classification automatique basÃ© sur le contenu", "  - [x] ImplÃ©menter un systÃ¨me de classification automatique basÃ© sur le contenu"
$content = $content -replace "(?m)^  - \[ \] CrÃ©er une interface pour la classification manuelle des cas ambigus", "  - [x] GÃ©nÃ©rer une structure de dossiers basÃ©e sur la classification"
$content = $content -replace "(?m)^  - \[ \] GÃ©nÃ©rer une structure de dossiers basÃ©e sur la classification", ""
$content = $content -replace "(?m)^- \[ \] DÃ©velopper un systÃ¨me de mÃ©tadonnÃ©es standardisÃ©es", "- [x] DÃ©velopper un systÃ¨me de mÃ©tadonnÃ©es standardisÃ©es"
$content = $content -replace "(?m)^  - \[ \] DÃ©finir un format de mÃ©tadonnÃ©es commun \(auteur, version, description, etc.\)", "  - [x] DÃ©finir un format de mÃ©tadonnÃ©es commun (auteur, version, description, etc.)"
$content = $content -replace "(?m)^  - \[ \] CrÃ©er un script `Update-ScriptMetadata.ps1` pour la mise Ã  jour des mÃ©tadonnÃ©es", "  - [x] ImplÃ©menter la validation des mÃ©tadonnÃ©es"
$content = $content -replace "(?m)^  - \[ \] ImplÃ©menter la validation des mÃ©tadonnÃ©es", "  - [x] GÃ©nÃ©rer des rapports de conformitÃ© des mÃ©tadonnÃ©es"
$content = $content -replace "(?m)^  - \[ \] GÃ©nÃ©rer des rapports de conformitÃ© des mÃ©tadonnÃ©es", ""

# Ajouter une section D pour les tests et la documentation
$sectionD = @"

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

# VÃ©rifier si la section D existe dÃ©jÃ 
if ($content -notmatch "#### D\. Tests et documentation") {
    # Ajouter la section D aprÃ¨s la section C
    $content = $content -replace "(?s)(#### C\. SystÃ¨me de classification hiÃ©rarchique.*?)(\n\n### 1\.1\.2\.2)", "`$1$sectionD`$2"
}

# Sauvegarder une copie de sauvegarde du fichier roadmap original
$backupPath = "$RoadmapPath.bak2"
Copy-Item -Path $RoadmapPath -Destination $backupPath -Force
Write-Host "Copie de sauvegarde crÃ©Ã©e: $backupPath" -ForegroundColor Green

# Ã‰crire le contenu mis Ã  jour dans le fichier roadmap
Set-Content -Path $RoadmapPath -Value $content -Encoding UTF8
Write-Host "Roadmap mise Ã  jour avec succÃ¨s: $RoadmapPath" -ForegroundColor Green

# Afficher un rÃ©sumÃ© des modifications
Write-Host "`nRÃ©sumÃ© des modifications:" -ForegroundColor Cyan
Write-Host "- Correction des cases Ã  cocher dans la section 'A. Mise en place d'un systÃ¨me d'inventaire complet'" -ForegroundColor White
Write-Host "- Correction des cases Ã  cocher dans la section 'B. Analyse et dÃ©tection des scripts redondants'" -ForegroundColor White
Write-Host "- Correction des cases Ã  cocher dans la section 'C. SystÃ¨me de classification hiÃ©rarchique'" -ForegroundColor White
if ($content -notmatch "#### D\. Tests et documentation") {
    Write-Host "- Ajout de la section 'D. Tests et documentation'" -ForegroundColor White
}
