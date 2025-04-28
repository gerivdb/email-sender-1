# Export-RoadmapStructureReport.ps1
# Script pour gÃ©nÃ©rer un rapport dÃ©taillÃ© sur la structure d'un fichier markdown de roadmap

param (
    [Parameter(Mandatory = $true)]
    [string]$RoadmapFilePath,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "roadmap-structure-report.md"
)

# Importer le module RoadmapParser
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "RoadmapParser.psm1"
Import-Module $modulePath -Force

# VÃ©rifier si le fichier existe
if (-not (Test-Path -Path $RoadmapFilePath)) {
    Write-Error "Le fichier '$RoadmapFilePath' n'existe pas."
    exit 1
}

# Analyser la structure du fichier
Write-Host "Analyse de la structure du fichier: $RoadmapFilePath" -ForegroundColor Cyan
$structure = Get-RoadmapStructure -FilePath $RoadmapFilePath

# GÃ©nÃ©rer le rapport au format Markdown
$report = @"
# Rapport d'Analyse de Structure de Roadmap

**Fichier analysÃ©:** `$RoadmapFilePath`  
**Date d'analyse:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## 1. Marqueurs de Liste

"@

if ($structure.ListMarkers.Count -eq 0) {
    $report += "Aucun marqueur de liste dÃ©tectÃ©.`n`n"
} else {
    $report += "| Marqueur | Occurrences |`n|----------|-------------|`n"
    foreach ($marker in $structure.ListMarkers.GetEnumerator()) {
        $report += "| `$($marker.Key)` | $($marker.Value) |`n"
    }
    $report += "`n"
}

$report += @"
## 2. Conventions d'Indentation

- **Espaces par niveau:** $($structure.IndentationPattern.SpacesPerLevel)
- **Indentation cohÃ©rente:** $($structure.IndentationPattern.ConsistentIndentation)

## 3. Formats de Titres et Sous-titres

### 3.1 Titres avec #

"@

if ($structure.HeaderFormats.HashHeaders.Count -eq 0) {
    $report += "Aucun titre avec # dÃ©tectÃ©.`n`n"
} else {
    $report += "| Niveau | Occurrences |`n|--------|-------------|`n"
    foreach ($level in $structure.HeaderFormats.HashHeaders.GetEnumerator() | Sort-Object -Property Key) {
        $report += "| $($level.Key) | $($level.Value) |`n"
    }
    $report += "`n"
}

$report += @"
### 3.2 Titres avec soulignement

"@

if ($structure.HeaderFormats.UnderlineHeaders.Count -eq 0) {
    $report += "Aucun titre avec soulignement dÃ©tectÃ©.`n`n"
} else {
    $report += "| Type | Niveau | Occurrences |`n|------|--------|-------------|`n"
    foreach ($level in $structure.HeaderFormats.UnderlineHeaders.GetEnumerator() | Sort-Object -Property Key) {
        $levelChar = if ($level.Key -eq 1) { "=" } else { "-" }
        $report += "| $levelChar | $($level.Key) | $($level.Value) |`n"
    }
    $report += "`n"
}

$report += @"
## 4. Styles d'Emphase

### 4.1 Gras

- **Avec astÃ©risques (`**texte**`):** $($structure.EmphasisStyles.Bold.Asterisks) occurrences
- **Avec underscores (`__texte__`):** $($structure.EmphasisStyles.Bold.Underscores) occurrences

### 4.2 Italique

- **Avec astÃ©risques (`*texte*`):** $($structure.EmphasisStyles.Italic.Asterisks) occurrences
- **Avec underscores (`_texte_`):** $($structure.EmphasisStyles.Italic.Underscores) occurrences

### 4.3 Gras-Italique

- **Avec astÃ©risques (`***texte***`):** $($structure.EmphasisStyles.BoldItalic.Asterisks) occurrences
- **Avec underscores (`___texte___`):** $($structure.EmphasisStyles.BoldItalic.Underscores) occurrences
- **Mixte (`**_texte_**` ou `_**texte**_`):** $($structure.EmphasisStyles.BoldItalic.Mixed) occurrences

## 5. HiÃ©rarchie des TÃ¢ches

- **Profondeur maximale:** $($structure.TaskHierarchy.MaxDepth) niveaux

### 5.1 Conventions de NumÃ©rotation

"@

if ($structure.TaskHierarchy.NumberingConventions.Count -eq 0) {
    $report += "Aucune convention de numÃ©rotation dÃ©tectÃ©e.`n`n"
} else {
    $report += "| Format | Occurrences |`n|--------|-------------|`n"
    foreach ($convention in $structure.TaskHierarchy.NumberingConventions.GetEnumerator()) {
        $report += "| `$($convention.Key)` | $($convention.Value) |`n"
    }
    $report += "`n"
}

$report += @"
### 5.2 Relations Parent-Enfant

"@

if ($structure.TaskHierarchy.ParentChildRelations.Count -eq 0) {
    $report += "Aucune relation parent-enfant dÃ©tectÃ©e.`n`n"
} else {
    $report += "| Niveau | Nombre d'Enfants |`n|--------|-----------------|`n"
    foreach ($relation in $structure.TaskHierarchy.ParentChildRelations.GetEnumerator() | Sort-Object -Property Key) {
        $report += "| $($relation.Key) | $($relation.Value) |`n"
    }
    $report += "`n"
}

$report += @"
## 6. Marqueurs de Statut

- **Incomplet (`[ ]`):** $($structure.StatusMarkers.Incomplete) occurrences
- **Complet (`[x]`):** $($structure.StatusMarkers.Complete) occurrences

### 6.1 Marqueurs PersonnalisÃ©s

"@

if ($structure.StatusMarkers.Custom.Count -eq 0) {
    $report += "Aucun marqueur personnalisÃ© dÃ©tectÃ©.`n`n"
} else {
    $report += "| Marqueur | Occurrences |`n|----------|-------------|`n"
    foreach ($marker in $structure.StatusMarkers.Custom.GetEnumerator()) {
        $report += "| [$($marker.Key)] | $($marker.Value) |`n"
    }
    $report += "`n"
}

$report += @"
### 6.2 Indicateurs Textuels de Progression

"@

if ($structure.StatusMarkers.TextualIndicators.Count -eq 0) {
    $report += "Aucun indicateur textuel dÃ©tectÃ©.`n`n"
} else {
    $report += "| Indicateur | Occurrences |`n|-----------|-------------|`n"
    foreach ($indicator in $structure.StatusMarkers.TextualIndicators.GetEnumerator()) {
        $report += "| $($indicator.Key) | $($indicator.Value) |`n"
    }
    $report += "`n"
}

$report += @"
## 7. Recommandations

BasÃ© sur l'analyse de la structure du fichier, voici quelques recommandations pour maintenir la cohÃ©rence:

"@

# GÃ©nÃ©rer des recommandations basÃ©es sur l'analyse
$recommendations = @()

# Recommandation pour les marqueurs de liste
if ($structure.ListMarkers.Count -gt 1) {
    $mostUsedMarker = $structure.ListMarkers.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1
    $recommendations += "- **Marqueurs de liste:** Standardiser l'utilisation du marqueur `$($mostUsedMarker.Key)` pour toutes les listes."
} elseif ($structure.ListMarkers.Count -eq 1) {
    $marker = $structure.ListMarkers.GetEnumerator() | Select-Object -First 1
    $recommendations += "- **Marqueurs de liste:** Continuer Ã  utiliser le marqueur `$($marker.Key)` de maniÃ¨re cohÃ©rente."
}

# Recommandation pour l'indentation
if ($structure.IndentationPattern.ConsistentIndentation) {
    $recommendations += "- **Indentation:** Maintenir l'indentation cohÃ©rente de $($structure.IndentationPattern.SpacesPerLevel) espaces par niveau."
} else {
    $recommendations += "- **Indentation:** Standardiser l'indentation Ã  2 ou 4 espaces par niveau pour amÃ©liorer la lisibilitÃ©."
}

# Recommandation pour les formats de titres
if ($structure.HeaderFormats.HashHeaders.Count -gt 0 -and $structure.HeaderFormats.UnderlineHeaders.Count -gt 0) {
    $recommendations += "- **Formats de titres:** Choisir un seul style de titre (# ou soulignement) pour plus de cohÃ©rence."
} elseif ($structure.HeaderFormats.HashHeaders.Count -gt 0) {
    $recommendations += "- **Formats de titres:** Continuer Ã  utiliser la syntaxe # pour les titres de maniÃ¨re cohÃ©rente."
} elseif ($structure.HeaderFormats.UnderlineHeaders.Count -gt 0) {
    $recommendations += "- **Formats de titres:** Continuer Ã  utiliser la syntaxe de soulignement pour les titres de maniÃ¨re cohÃ©rente."
}

# Recommandation pour les styles d'emphase
$boldStyle = if ($structure.EmphasisStyles.Bold.Asterisks -gt $structure.EmphasisStyles.Bold.Underscores) { "**" } else { "__" }
$italicStyle = if ($structure.EmphasisStyles.Italic.Asterisks -gt $structure.EmphasisStyles.Italic.Underscores) { "*" } else { "_" }
$recommendations += "- **Styles d'emphase:** Standardiser l'utilisation de $boldStyle pour le gras et $italicStyle pour l'italique."

# Recommandation pour les marqueurs de statut
if ($structure.StatusMarkers.Custom.Count -gt 0) {
    $recommendations += "- **Marqueurs de statut:** Documenter la signification des marqueurs personnalisÃ©s pour assurer une comprÃ©hension commune."
}

# Ajouter les recommandations au rapport
if ($recommendations.Count -gt 0) {
    $report += $recommendations -join "`n"
} else {
    $report += "Aucune recommandation spÃ©cifique. La structure du fichier semble cohÃ©rente."
}

# Enregistrer le rapport dans un fichier
$report | Out-File -FilePath $OutputPath -Encoding UTF8

Write-Host "Rapport gÃ©nÃ©rÃ© avec succÃ¨s: $OutputPath" -ForegroundColor Green
