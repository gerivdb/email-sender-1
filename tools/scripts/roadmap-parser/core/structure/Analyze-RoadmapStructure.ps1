# Analyze-RoadmapStructure.ps1
# Script pour analyser la structure d'un fichier markdown de roadmap

param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapFilePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\roadmap_complete_converted.md",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputDir = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\analysis"
)

# Importer le module RoadmapAnalyzer
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "RoadmapAnalyzer.psm1"
Import-Module $modulePath -Force

# Vérifier si le fichier existe
if (-not (Test-Path -Path $RoadmapFilePath)) {
    Write-Error "Le fichier '$RoadmapFilePath' n'existe pas."
    exit 1
}

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputDir)) {
    New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
    Write-Host "Répertoire de sortie créé: $OutputDir" -ForegroundColor Green
}

# Analyser la structure du fichier
Write-Host "Analyse de la structure du fichier: $RoadmapFilePath" -ForegroundColor Cyan
$structure = Get-MarkdownStructure -FilePath $RoadmapFilePath

# Afficher les résultats
Write-Host "`nRésultats de l'analyse:" -ForegroundColor Green

# Marqueurs de liste
Write-Host "`n1. Marqueurs de liste utilisés:" -ForegroundColor Yellow
if ($structure.ListMarkers.Count -eq 0) {
    Write-Host "  Aucun marqueur de liste détecté."
} else {
    foreach ($marker in $structure.ListMarkers.GetEnumerator()) {
        Write-Host "  $($marker.Key): $($marker.Value) occurrences"
    }
}

# Conventions d'indentation
Write-Host "`n2. Conventions d'indentation:" -ForegroundColor Yellow
Write-Host "  Espaces par niveau: $($structure.Indentation.SpacesPerLevel)"
Write-Host "  Indentation cohérente: $($structure.Indentation.ConsistentIndentation)"

# Formats de titres
Write-Host "`n3. Formats de titres et sous-titres:" -ForegroundColor Yellow
Write-Host "  Titres avec #:"
if ($structure.Headers.HashHeaders.Count -eq 0) {
    Write-Host "    Aucun titre avec # détecté."
} else {
    foreach ($level in $structure.Headers.HashHeaders.GetEnumerator() | Sort-Object -Property Key) {
        Write-Host "    Niveau $($level.Key): $($level.Value) occurrences"
    }
}

Write-Host "  Titres avec soulignement:"
if ($structure.Headers.UnderlineHeaders.Count -eq 0) {
    Write-Host "    Aucun titre avec soulignement détecté."
} else {
    foreach ($level in $structure.Headers.UnderlineHeaders.GetEnumerator() | Sort-Object -Property Key) {
        $levelType = if ($level.Key -eq 1) { "= (niveau 1)" } else { "- (niveau 2)" }
        Write-Host "    $levelType - $($level.Value) occurrences"
    }
}

# Styles d'emphase
Write-Host "`n4. Styles d'emphase:" -ForegroundColor Yellow
Write-Host "  Gras:"
Write-Host "    **texte**: $($structure.Emphasis.Bold.Asterisks) occurrences"
Write-Host "    __texte__: $($structure.Emphasis.Bold.Underscores) occurrences"

Write-Host "  Italique:"
Write-Host "    *texte*: $($structure.Emphasis.Italic.Asterisks) occurrences"
Write-Host "    _texte_: $($structure.Emphasis.Italic.Underscores) occurrences"

Write-Host "  Gras-Italique:"
Write-Host "    ***texte***: $($structure.Emphasis.BoldItalic.Asterisks) occurrences"
Write-Host "    ___texte___: $($structure.Emphasis.BoldItalic.Underscores) occurrences"
Write-Host "    **_texte_** ou _**texte**_: $($structure.Emphasis.BoldItalic.Mixed) occurrences"

# Hiérarchie des tâches
Write-Host "`n5. Hiérarchie des tâches:" -ForegroundColor Yellow
Write-Host "  Profondeur maximale: $($structure.TaskHierarchy.MaxDepth) niveaux"

Write-Host "  Conventions de numérotation:"
if ($structure.TaskHierarchy.NumberingConventions.Count -eq 0) {
    Write-Host "    Aucune convention de numérotation détectée."
} else {
    foreach ($convention in $structure.TaskHierarchy.NumberingConventions.GetEnumerator()) {
        Write-Host "    $($convention.Key): $($convention.Value) occurrences"
    }
}

Write-Host "  Relations parent-enfant par niveau:"
if ($structure.TaskHierarchy.ParentChildRelations.Count -eq 0) {
    Write-Host "    Aucune relation parent-enfant détectée."
} else {
    foreach ($relation in $structure.TaskHierarchy.ParentChildRelations.GetEnumerator() | Sort-Object -Property Key) {
        Write-Host "    Niveau $($relation.Key): $($relation.Value) enfants"
    }
}

# Marqueurs de statut
Write-Host "`n6. Marqueurs de statut:" -ForegroundColor Yellow
Write-Host "  [ ] (Incomplet): $($structure.StatusMarkers.Incomplete) occurrences"
Write-Host "  [x] (Complet): $($structure.StatusMarkers.Complete) occurrences"

Write-Host "  Marqueurs personnalisés:"
if ($structure.StatusMarkers.Custom.Count -eq 0) {
    Write-Host "    Aucun marqueur personnalisé détecté."
} else {
    foreach ($marker in $structure.StatusMarkers.Custom.GetEnumerator()) {
        Write-Host "    [$($marker.Key)]: $($marker.Value) occurrences"
    }
}

Write-Host "  Indicateurs textuels de progression:"
if ($structure.StatusMarkers.TextualIndicators.Count -eq 0) {
    Write-Host "    Aucun indicateur textuel détecté."
} else {
    foreach ($indicator in $structure.StatusMarkers.TextualIndicators.GetEnumerator()) {
        Write-Host "    '$($indicator.Key)': $($indicator.Value) occurrences"
    }
}

# Générer un rapport au format Markdown
$reportPath = Join-Path -Path $OutputDir -ChildPath "roadmap-structure-report.md"
$report = @"
# Rapport d'Analyse de Structure de Roadmap

**Fichier analysé:** `$RoadmapFilePath`  
**Date d'analyse:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## 1. Marqueurs de Liste

"@

if ($structure.ListMarkers.Count -eq 0) {
    $report += "Aucun marqueur de liste détecté.`n`n"
} else {
    $report += "| Marqueur | Occurrences |`n|----------|-------------|`n"
    foreach ($marker in $structure.ListMarkers.GetEnumerator()) {
        $report += "| `$($marker.Key)` | $($marker.Value) |`n"
    }
    $report += "`n"
}

$report += @"
## 2. Conventions d'Indentation

- **Espaces par niveau:** $($structure.Indentation.SpacesPerLevel)
- **Indentation cohérente:** $($structure.Indentation.ConsistentIndentation)

## 3. Formats de Titres et Sous-titres

### 3.1 Titres avec #

"@

if ($structure.Headers.HashHeaders.Count -eq 0) {
    $report += "Aucun titre avec # détecté.`n`n"
} else {
    $report += "| Niveau | Occurrences |`n|--------|-------------|`n"
    foreach ($level in $structure.Headers.HashHeaders.GetEnumerator() | Sort-Object -Property Key) {
        $report += "| $($level.Key) | $($level.Value) |`n"
    }
    $report += "`n"
}

$report += @"
### 3.2 Titres avec soulignement

"@

if ($structure.Headers.UnderlineHeaders.Count -eq 0) {
    $report += "Aucun titre avec soulignement détecté.`n`n"
} else {
    $report += "| Type | Niveau | Occurrences |`n|------|--------|-------------|`n"
    foreach ($level in $structure.Headers.UnderlineHeaders.GetEnumerator() | Sort-Object -Property Key) {
        $levelChar = if ($level.Key -eq 1) { "=" } else { "-" }
        $report += "| $levelChar | $($level.Key) | $($level.Value) |`n"
    }
    $report += "`n"
}

$report += @"
## 4. Styles d'Emphase

### 4.1 Gras

- **Avec astérisques (`**texte**`):** $($structure.Emphasis.Bold.Asterisks) occurrences
- **Avec underscores (`__texte__`):** $($structure.Emphasis.Bold.Underscores) occurrences

### 4.2 Italique

- **Avec astérisques (`*texte*`):** $($structure.Emphasis.Italic.Asterisks) occurrences
- **Avec underscores (`_texte_`):** $($structure.Emphasis.Italic.Underscores) occurrences

### 4.3 Gras-Italique

- **Avec astérisques (`***texte***`):** $($structure.Emphasis.BoldItalic.Asterisks) occurrences
- **Avec underscores (`___texte___`):** $($structure.Emphasis.BoldItalic.Underscores) occurrences
- **Mixte (`**_texte_**` ou `_**texte**_`):** $($structure.Emphasis.BoldItalic.Mixed) occurrences

## 5. Hiérarchie des Tâches

- **Profondeur maximale:** $($structure.TaskHierarchy.MaxDepth) niveaux

### 5.1 Conventions de Numérotation

"@

if ($structure.TaskHierarchy.NumberingConventions.Count -eq 0) {
    $report += "Aucune convention de numérotation détectée.`n`n"
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
    $report += "Aucune relation parent-enfant détectée.`n`n"
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

### 6.1 Marqueurs Personnalisés

"@

if ($structure.StatusMarkers.Custom.Count -eq 0) {
    $report += "Aucun marqueur personnalisé détecté.`n`n"
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
    $report += "Aucun indicateur textuel détecté.`n`n"
} else {
    $report += "| Indicateur | Occurrences |`n|-----------|-------------|`n"
    foreach ($indicator in $structure.StatusMarkers.TextualIndicators.GetEnumerator()) {
        $report += "| $($indicator.Key) | $($indicator.Value) |`n"
    }
    $report += "`n"
}

$report += @"
## 7. Recommandations

Basé sur l'analyse de la structure du fichier, voici quelques recommandations pour maintenir la cohérence:

"@

# Générer des recommandations basées sur l'analyse
$recommendations = @()

# Recommandation pour les marqueurs de liste
if ($structure.ListMarkers.Count -gt 1) {
    $mostUsedMarker = $structure.ListMarkers.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1
    $recommendations += "- **Marqueurs de liste:** Standardiser l'utilisation du marqueur `$($mostUsedMarker.Key)` pour toutes les listes."
} elseif ($structure.ListMarkers.Count -eq 1) {
    $marker = $structure.ListMarkers.GetEnumerator() | Select-Object -First 1
    $recommendations += "- **Marqueurs de liste:** Continuer à utiliser le marqueur `$($marker.Key)` de manière cohérente."
}

# Recommandation pour l'indentation
if ($structure.Indentation.ConsistentIndentation) {
    $recommendations += "- **Indentation:** Maintenir l'indentation cohérente de $($structure.Indentation.SpacesPerLevel) espaces par niveau."
} else {
    $recommendations += "- **Indentation:** Standardiser l'indentation à 2 ou 4 espaces par niveau pour améliorer la lisibilité."
}

# Recommandation pour les formats de titres
if ($structure.Headers.HashHeaders.Count -gt 0 -and $structure.Headers.UnderlineHeaders.Count -gt 0) {
    $recommendations += "- **Formats de titres:** Choisir un seul style de titre (# ou soulignement) pour plus de cohérence."
} elseif ($structure.Headers.HashHeaders.Count -gt 0) {
    $recommendations += "- **Formats de titres:** Continuer à utiliser la syntaxe # pour les titres de manière cohérente."
} elseif ($structure.Headers.UnderlineHeaders.Count -gt 0) {
    $recommendations += "- **Formats de titres:** Continuer à utiliser la syntaxe de soulignement pour les titres de manière cohérente."
}

# Recommandation pour les styles d'emphase
$boldStyle = if ($structure.Emphasis.Bold.Asterisks -gt $structure.Emphasis.Bold.Underscores) { "**" } else { "__" }
$italicStyle = if ($structure.Emphasis.Italic.Asterisks -gt $structure.Emphasis.Italic.Underscores) { "*" } else { "_" }
$recommendations += "- **Styles d'emphase:** Standardiser l'utilisation de $boldStyle pour le gras et $italicStyle pour l'italique."

# Recommandation pour les marqueurs de statut
if ($structure.StatusMarkers.Custom.Count -gt 0) {
    $recommendations += "- **Marqueurs de statut:** Documenter la signification des marqueurs personnalisés pour assurer une compréhension commune."
}

# Ajouter les recommandations au rapport
if ($recommendations.Count -gt 0) {
    $report += $recommendations -join "`n"
} else {
    $report += "Aucune recommandation spécifique. La structure du fichier semble cohérente."
}

# Enregistrer le rapport dans un fichier
$report | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host "`nRapport généré: $reportPath" -ForegroundColor Green

# Analyser les conventions spécifiques au projet
Write-Host "`nAnalyse des conventions spécifiques au projet..." -ForegroundColor Yellow
$conventions = Get-ProjectConventions -Content (Get-Content -Path $RoadmapFilePath -Encoding UTF8 -Raw)

# Afficher les résultats des conventions
Write-Host "`nConventions spécifiques au projet détectées:" -ForegroundColor Green

# Identifiants de tâches
Write-Host "`n1. Identifiants de tâches:" -ForegroundColor Yellow
if ($null -eq $conventions.TaskIdentifiers.Pattern) {
    Write-Host "  Aucun format d'identifiant de tâche spécifique détecté."
} else {
    Write-Host "  Format détecté: $($conventions.TaskIdentifiers.Pattern)"
    Write-Host "  Exemples:"
    foreach ($example in $conventions.TaskIdentifiers.Examples) {
        Write-Host "    - $example"
    }
}

# Indicateurs de priorité
Write-Host "`n2. Indicateurs de priorité:" -ForegroundColor Yellow
if ($null -eq $conventions.PriorityIndicators.Pattern) {
    Write-Host "  Aucun indicateur de priorité spécifique détecté."
} else {
    Write-Host "  Format détecté: $($conventions.PriorityIndicators.Pattern)"
    Write-Host "  Exemples:"
    foreach ($example in $conventions.PriorityIndicators.Examples) {
        Write-Host "    - $example"
    }
}

# Indicateurs de statut
Write-Host "`n3. Indicateurs de statut:" -ForegroundColor Yellow
if ($null -eq $conventions.StatusIndicators.Pattern) {
    Write-Host "  Aucun indicateur de statut spécifique détecté."
} else {
    Write-Host "  Format détecté: $($conventions.StatusIndicators.Pattern)"
    Write-Host "  Exemples:"
    foreach ($example in $conventions.StatusIndicators.Examples) {
        Write-Host "    - $example"
    }
}

# Sections spéciales
Write-Host "`n4. Sections spéciales:" -ForegroundColor Yellow
if ($conventions.SpecialSections.Count -eq 0) {
    Write-Host "  Aucune section spéciale détectée."
} else {
    Write-Host "  Sections détectées:"
    foreach ($section in $conventions.SpecialSections) {
        Write-Host "    - $section"
    }
}

# Format des métadonnées
Write-Host "`n5. Format des métadonnées:" -ForegroundColor Yellow
if ($null -eq $conventions.MetadataFormat) {
    Write-Host "  Aucun format de métadonnées spécifique détecté."
} else {
    Write-Host "  Format détecté: $($conventions.MetadataFormat)"
}

# Générer un rapport des conventions au format Markdown
$conventionsReportPath = Join-Path -Path $OutputDir -ChildPath "project-conventions.md"
$conventionsReport = @"
# Conventions Spécifiques au Projet

**Fichier analysé:** `$RoadmapFilePath`  
**Date d'analyse:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## 1. Identifiants de Tâches

"@

if ($null -eq $conventions.TaskIdentifiers.Pattern) {
    $conventionsReport += "Aucun format d'identifiant de tâche spécifique détecté.`n`n"
} else {
    $conventionsReport += "**Format détecté:** `$($conventions.TaskIdentifiers.Pattern)`\n\n"
    $conventionsReport += "**Exemples:**\n\n"
    foreach ($example in $conventions.TaskIdentifiers.Examples) {
        $conventionsReport += "- $example\n"
    }
    $conventionsReport += "\n"
}

$conventionsReport += @"
## 2. Indicateurs de Priorité

"@

if ($null -eq $conventions.PriorityIndicators.Pattern) {
    $conventionsReport += "Aucun indicateur de priorité spécifique détecté.`n`n"
} else {
    $conventionsReport += "**Format détecté:** `$($conventions.PriorityIndicators.Pattern)`\n\n"
    $conventionsReport += "**Exemples:**\n\n"
    foreach ($example in $conventions.PriorityIndicators.Examples) {
        $conventionsReport += "- $example\n"
    }
    $conventionsReport += "\n"
}

$conventionsReport += @"
## 3. Indicateurs de Statut

"@

if ($null -eq $conventions.StatusIndicators.Pattern) {
    $conventionsReport += "Aucun indicateur de statut spécifique détecté.`n`n"
} else {
    $conventionsReport += "**Format détecté:** `$($conventions.StatusIndicators.Pattern)`\n\n"
    $conventionsReport += "**Exemples:**\n\n"
    foreach ($example in $conventions.StatusIndicators.Examples) {
        $conventionsReport += "- $example\n"
    }
    $conventionsReport += "\n"
}

$conventionsReport += @"
## 4. Sections Spéciales

"@

if ($conventions.SpecialSections.Count -eq 0) {
    $conventionsReport += "Aucune section spéciale détectée.`n`n"
} else {
    $conventionsReport += "**Sections détectées:**\n\n"
    foreach ($section in $conventions.SpecialSections) {
        $conventionsReport += "- $section\n"
    }
    $conventionsReport += "\n"
}

$conventionsReport += @"
## 5. Format des Métadonnées

"@

if ($null -eq $conventions.MetadataFormat) {
    $conventionsReport += "Aucun format de métadonnées spécifique détecté.`n`n"
} else {
    $conventionsReport += "**Format détecté:** `$($conventions.MetadataFormat)`\n\n"
}

# Enregistrer le rapport des conventions dans un fichier
$conventionsReport | Out-File -FilePath $conventionsReportPath -Encoding UTF8

Write-Host "`nRapport des conventions généré: $conventionsReportPath" -ForegroundColor Green
Write-Host "`nAnalyse terminée." -ForegroundColor Cyan
