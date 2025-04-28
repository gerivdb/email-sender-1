# Test-RoadmapStructure.ps1
# Script pour tester l'analyse de la structure d'un fichier markdown de roadmap

param (
    [Parameter(Mandatory = $true)]
    [string]$RoadmapFilePath
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
Write-Host "  Espaces par niveau: $($structure.IndentationPattern.SpacesPerLevel)"
Write-Host "  Indentation cohÃ©rente: $($structure.IndentationPattern.ConsistentIndentation)"

# Formats de titres
Write-Host "`n3. Formats de titres et sous-titres:" -ForegroundColor Yellow
Write-Host "  Titres avec #:"
if ($structure.HeaderFormats.HashHeaders.Count -eq 0) {
    Write-Host "    Aucun titre avec # dÃ©tectÃ©."
} else {
    foreach ($level in $structure.HeaderFormats.HashHeaders.GetEnumerator() | Sort-Object -Property Key) {
        Write-Host "    Niveau $($level.Key): $($level.Value) occurrences"
    }
}

Write-Host "  Titres avec soulignement:"
if ($structure.HeaderFormats.UnderlineHeaders.Count -eq 0) {
    Write-Host "    Aucun titre avec soulignement dÃ©tectÃ©."
} else {
    foreach ($level in $structure.HeaderFormats.UnderlineHeaders.GetEnumerator() | Sort-Object -Property Key) {
        $levelName = if ($level.Key -eq 1) { "= (niveau 1)" } else { "- (niveau 2)" }
        Write-Host "    $levelName - $($level.Value) occurrences"
    }
}

# Styles d'emphase
Write-Host "`n4. Styles d'emphase:" -ForegroundColor Yellow
Write-Host "  Gras:"
Write-Host "    **texte**: $($structure.EmphasisStyles.Bold.Asterisks) occurrences"
Write-Host "    __texte__: $($structure.EmphasisStyles.Bold.Underscores) occurrences"

Write-Host "  Italique:"
Write-Host "    *texte*: $($structure.EmphasisStyles.Italic.Asterisks) occurrences"
Write-Host "    _texte_: $($structure.EmphasisStyles.Italic.Underscores) occurrences"

Write-Host "  Gras-Italique:"
Write-Host "    ***texte***: $($structure.EmphasisStyles.BoldItalic.Asterisks) occurrences"
Write-Host "    ___texte___: $($structure.EmphasisStyles.BoldItalic.Underscores) occurrences"
Write-Host "    **_texte_** ou _**texte**_: $($structure.EmphasisStyles.BoldItalic.Mixed) occurrences"

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

Write-Host "`nAnalyse terminÃ©e." -ForegroundColor Cyan
