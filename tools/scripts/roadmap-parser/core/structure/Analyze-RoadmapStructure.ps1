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

# VÃ©rifier si le fichier existe
if (-not (Test-Path -Path $RoadmapFilePath)) {
    Write-Error "Le fichier '$RoadmapFilePath' n'existe pas."
    exit 1
}

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputDir)) {
    New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
    Write-Host "RÃ©pertoire de sortie crÃ©Ã©: $OutputDir" -ForegroundColor Green
}

# Analyser la structure du fichier
Write-Host "Analyse de la structure du fichier: $RoadmapFilePath" -ForegroundColor Cyan
$structure = Get-MarkdownStructure -FilePath $RoadmapFilePath

# Afficher les rÃ©sultats
Write-Host "`nRÃ©sultats de l'analyse:" -ForegroundColor Green

# Marqueurs de liste
Write-Host "`n1. Marqueurs de liste utilisÃ©s:" -ForegroundColor Yellow
if ($structure.ListMarkers.Count -eq 0) {
    Write-Host "  Aucun marqueur de liste dÃ©tectÃ©."
} else {
    foreach ($marker in $structure.ListMarkers.GetEnumerator()) {
        Write-Host "  $($marker.Key): $($marker.Value) occurrences"
    }
}

# Conventions d'indentation
Write-Host "`n2. Conventions d'indentation:" -ForegroundColor Yellow
Write-Host "  Espaces par niveau: $($structure.Indentation.SpacesPerLevel)"
Write-Host "  Indentation cohÃ©rente: $($structure.Indentation.ConsistentIndentation)"

# Formats de titres
Write-Host "`n3. Formats de titres et sous-titres:" -ForegroundColor Yellow
Write-Host "  Titres avec #:"
if ($structure.Headers.HashHeaders.Count -eq 0) {
    Write-Host "    Aucun titre avec # dÃ©tectÃ©."
} else {
    foreach ($level in $structure.Headers.HashHeaders.GetEnumerator() | Sort-Object -Property Key) {
        Write-Host "    Niveau $($level.Key): $($level.Value) occurrences"
    }
}

Write-Host "  Titres avec soulignement:"
if ($structure.Headers.UnderlineHeaders.Count -eq 0) {
    Write-Host "    Aucun titre avec soulignement dÃ©tectÃ©."
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

# HiÃ©rarchie des tÃ¢ches
Write-Host "`n5. HiÃ©rarchie des tÃ¢ches:" -ForegroundColor Yellow
Write-Host "  Profondeur maximale: $($structure.TaskHierarchy.MaxDepth) niveaux"

Write-Host "  Conventions de numÃ©rotation:"
if ($structure.TaskHierarchy.NumberingConventions.Count -eq 0) {
    Write-Host "    Aucune convention de numÃ©rotation dÃ©tectÃ©e."
} else {
    foreach ($convention in $structure.TaskHierarchy.NumberingConventions.GetEnumerator()) {
        Write-Host "    $($convention.Key): $($convention.Value) occurrences"
    }
}

Write-Host "  Relations parent-enfant par niveau:"
if ($structure.TaskHierarchy.ParentChildRelations.Count -eq 0) {
    Write-Host "    Aucune relation parent-enfant dÃ©tectÃ©e."
} else {
    foreach ($relation in $structure.TaskHierarchy.ParentChildRelations.GetEnumerator() | Sort-Object -Property Key) {
        Write-Host "    Niveau $($relation.Key): $($relation.Value) enfants"
    }
}

# Marqueurs de statut
Write-Host "`n6. Marqueurs de statut:" -ForegroundColor Yellow
Write-Host "  [ ] (Incomplet): $($structure.StatusMarkers.Incomplete) occurrences"
Write-Host "  [x] (Complet): $($structure.StatusMarkers.Complete) occurrences"

Write-Host "  Marqueurs personnalisÃ©s:"
if ($structure.StatusMarkers.Custom.Count -eq 0) {
    Write-Host "    Aucun marqueur personnalisÃ© dÃ©tectÃ©."
} else {
    foreach ($marker in $structure.StatusMarkers.Custom.GetEnumerator()) {
        Write-Host "    [$($marker.Key)]: $($marker.Value) occurrences"
    }
}

Write-Host "  Indicateurs textuels de progression:"
if ($structure.StatusMarkers.TextualIndicators.Count -eq 0) {
    Write-Host "    Aucun indicateur textuel dÃ©tectÃ©."
} else {
    foreach ($indicator in $structure.StatusMarkers.TextualIndicators.GetEnumerator()) {
        Write-Host "    '$($indicator.Key)': $($indicator.Value) occurrences"
    }
}

# GÃ©nÃ©rer un rapport au format Markdown
$reportPath = Join-Path -Path $OutputDir -ChildPath "roadmap-structure-report.md"
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

- **Espaces par niveau:** $($structure.Indentation.SpacesPerLevel)
- **Indentation cohÃ©rente:** $($structure.Indentation.ConsistentIndentation)

## 3. Formats de Titres et Sous-titres

### 3.1 Titres avec #

"@

if ($structure.Headers.HashHeaders.Count -eq 0) {
    $report += "Aucun titre avec # dÃ©tectÃ©.`n`n"
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
    $report += "Aucun titre avec soulignement dÃ©tectÃ©.`n`n"
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

- **Avec astÃ©risques (`**texte**`):** $($structure.Emphasis.Bold.Asterisks) occurrences
- **Avec underscores (`__texte__`):** $($structure.Emphasis.Bold.Underscores) occurrences

### 4.2 Italique

- **Avec astÃ©risques (`*texte*`):** $($structure.Emphasis.Italic.Asterisks) occurrences
- **Avec underscores (`_texte_`):** $($structure.Emphasis.Italic.Underscores) occurrences

### 4.3 Gras-Italique

- **Avec astÃ©risques (`***texte***`):** $($structure.Emphasis.BoldItalic.Asterisks) occurrences
- **Avec underscores (`___texte___`):** $($structure.Emphasis.BoldItalic.Underscores) occurrences
- **Mixte (`**_texte_**` ou `_**texte**_`):** $($structure.Emphasis.BoldItalic.Mixed) occurrences

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
if ($structure.Indentation.ConsistentIndentation) {
    $recommendations += "- **Indentation:** Maintenir l'indentation cohÃ©rente de $($structure.Indentation.SpacesPerLevel) espaces par niveau."
} else {
    $recommendations += "- **Indentation:** Standardiser l'indentation Ã  2 ou 4 espaces par niveau pour amÃ©liorer la lisibilitÃ©."
}

# Recommandation pour les formats de titres
if ($structure.Headers.HashHeaders.Count -gt 0 -and $structure.Headers.UnderlineHeaders.Count -gt 0) {
    $recommendations += "- **Formats de titres:** Choisir un seul style de titre (# ou soulignement) pour plus de cohÃ©rence."
} elseif ($structure.Headers.HashHeaders.Count -gt 0) {
    $recommendations += "- **Formats de titres:** Continuer Ã  utiliser la syntaxe # pour les titres de maniÃ¨re cohÃ©rente."
} elseif ($structure.Headers.UnderlineHeaders.Count -gt 0) {
    $recommendations += "- **Formats de titres:** Continuer Ã  utiliser la syntaxe de soulignement pour les titres de maniÃ¨re cohÃ©rente."
}

# Recommandation pour les styles d'emphase
$boldStyle = if ($structure.Emphasis.Bold.Asterisks -gt $structure.Emphasis.Bold.Underscores) { "**" } else { "__" }
$italicStyle = if ($structure.Emphasis.Italic.Asterisks -gt $structure.Emphasis.Italic.Underscores) { "*" } else { "_" }
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
$report | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host "`nRapport gÃ©nÃ©rÃ©: $reportPath" -ForegroundColor Green

# Analyser les conventions spÃ©cifiques au projet
Write-Host "`nAnalyse des conventions spÃ©cifiques au projet..." -ForegroundColor Yellow
$conventions = Get-ProjectConventions -Content (Get-Content -Path $RoadmapFilePath -Encoding UTF8 -Raw)

# Afficher les rÃ©sultats des conventions
Write-Host "`nConventions spÃ©cifiques au projet dÃ©tectÃ©es:" -ForegroundColor Green

# Identifiants de tÃ¢ches
Write-Host "`n1. Identifiants de tÃ¢ches:" -ForegroundColor Yellow
if ($null -eq $conventions.TaskIdentifiers.Pattern) {
    Write-Host "  Aucun format d'identifiant de tÃ¢che spÃ©cifique dÃ©tectÃ©."
} else {
    Write-Host "  Format dÃ©tectÃ©: $($conventions.TaskIdentifiers.Pattern)"
    Write-Host "  Exemples:"
    foreach ($example in $conventions.TaskIdentifiers.Examples) {
        Write-Host "    - $example"
    }
}

# Indicateurs de prioritÃ©
Write-Host "`n2. Indicateurs de prioritÃ©:" -ForegroundColor Yellow
if ($null -eq $conventions.PriorityIndicators.Pattern) {
    Write-Host "  Aucun indicateur de prioritÃ© spÃ©cifique dÃ©tectÃ©."
} else {
    Write-Host "  Format dÃ©tectÃ©: $($conventions.PriorityIndicators.Pattern)"
    Write-Host "  Exemples:"
    foreach ($example in $conventions.PriorityIndicators.Examples) {
        Write-Host "    - $example"
    }
}

# Indicateurs de statut
Write-Host "`n3. Indicateurs de statut:" -ForegroundColor Yellow
if ($null -eq $conventions.StatusIndicators.Pattern) {
    Write-Host "  Aucun indicateur de statut spÃ©cifique dÃ©tectÃ©."
} else {
    Write-Host "  Format dÃ©tectÃ©: $($conventions.StatusIndicators.Pattern)"
    Write-Host "  Exemples:"
    foreach ($example in $conventions.StatusIndicators.Examples) {
        Write-Host "    - $example"
    }
}

# Sections spÃ©ciales
Write-Host "`n4. Sections spÃ©ciales:" -ForegroundColor Yellow
if ($conventions.SpecialSections.Count -eq 0) {
    Write-Host "  Aucune section spÃ©ciale dÃ©tectÃ©e."
} else {
    Write-Host "  Sections dÃ©tectÃ©es:"
    foreach ($section in $conventions.SpecialSections) {
        Write-Host "    - $section"
    }
}

# Format des mÃ©tadonnÃ©es
Write-Host "`n5. Format des mÃ©tadonnÃ©es:" -ForegroundColor Yellow
if ($null -eq $conventions.MetadataFormat) {
    Write-Host "  Aucun format de mÃ©tadonnÃ©es spÃ©cifique dÃ©tectÃ©."
} else {
    Write-Host "  Format dÃ©tectÃ©: $($conventions.MetadataFormat)"
}

# GÃ©nÃ©rer un rapport des conventions au format Markdown
$conventionsReportPath = Join-Path -Path $OutputDir -ChildPath "project-conventions.md"
$conventionsReport = @"
# Conventions SpÃ©cifiques au Projet

**Fichier analysÃ©:** `$RoadmapFilePath`  
**Date d'analyse:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## 1. Identifiants de TÃ¢ches

"@

if ($null -eq $conventions.TaskIdentifiers.Pattern) {
    $conventionsReport += "Aucun format d'identifiant de tÃ¢che spÃ©cifique dÃ©tectÃ©.`n`n"
} else {
    $conventionsReport += "**Format dÃ©tectÃ©:** `$($conventions.TaskIdentifiers.Pattern)`\n\n"
    $conventionsReport += "**Exemples:**\n\n"
    foreach ($example in $conventions.TaskIdentifiers.Examples) {
        $conventionsReport += "- $example\n"
    }
    $conventionsReport += "\n"
}

$conventionsReport += @"
## 2. Indicateurs de PrioritÃ©

"@

if ($null -eq $conventions.PriorityIndicators.Pattern) {
    $conventionsReport += "Aucun indicateur de prioritÃ© spÃ©cifique dÃ©tectÃ©.`n`n"
} else {
    $conventionsReport += "**Format dÃ©tectÃ©:** `$($conventions.PriorityIndicators.Pattern)`\n\n"
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
    $conventionsReport += "Aucun indicateur de statut spÃ©cifique dÃ©tectÃ©.`n`n"
} else {
    $conventionsReport += "**Format dÃ©tectÃ©:** `$($conventions.StatusIndicators.Pattern)`\n\n"
    $conventionsReport += "**Exemples:**\n\n"
    foreach ($example in $conventions.StatusIndicators.Examples) {
        $conventionsReport += "- $example\n"
    }
    $conventionsReport += "\n"
}

$conventionsReport += @"
## 4. Sections SpÃ©ciales

"@

if ($conventions.SpecialSections.Count -eq 0) {
    $conventionsReport += "Aucune section spÃ©ciale dÃ©tectÃ©e.`n`n"
} else {
    $conventionsReport += "**Sections dÃ©tectÃ©es:**\n\n"
    foreach ($section in $conventions.SpecialSections) {
        $conventionsReport += "- $section\n"
    }
    $conventionsReport += "\n"
}

$conventionsReport += @"
## 5. Format des MÃ©tadonnÃ©es

"@

if ($null -eq $conventions.MetadataFormat) {
    $conventionsReport += "Aucun format de mÃ©tadonnÃ©es spÃ©cifique dÃ©tectÃ©.`n`n"
} else {
    $conventionsReport += "**Format dÃ©tectÃ©:** `$($conventions.MetadataFormat)`\n\n"
}

# Enregistrer le rapport des conventions dans un fichier
$conventionsReport | Out-File -FilePath $conventionsReportPath -Encoding UTF8

Write-Host "`nRapport des conventions gÃ©nÃ©rÃ©: $conventionsReportPath" -ForegroundColor Green
Write-Host "`nAnalyse terminÃ©e." -ForegroundColor Cyan
