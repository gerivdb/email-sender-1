# Generate-ProgressReport.ps1
# Script pour gÃ©nÃ©rer un rapport de progression sur un fichier markdown de roadmap

param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapFilePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\roadmap_complete_converted.md",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\analysis\progress-report.md"
)

# VÃ©rifier si le fichier existe
if (-not (Test-Path -Path $RoadmapFilePath)) {
    Write-Error "Le fichier '$RoadmapFilePath' n'existe pas."
    exit 1
}

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
$outputDir = Split-Path -Path $OutputPath -Parent
if (-not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    Write-Host "RÃ©pertoire de sortie crÃ©Ã©: $outputDir" -ForegroundColor Green
}

# Lire le contenu du fichier
$content = Get-Content -Path $RoadmapFilePath -Encoding UTF8 -Raw

# Fonction pour analyser les marqueurs de statut
function Get-StatusMarkers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $statusMarkers = @{
        Incomplete = 0
        Complete = 0
        Custom = @{}
        TextualIndicators = @{}
    }

    # Rechercher les marqueurs de statut standard
    $incompletePattern = "(?m)^\s*[-*+]\s*\[ \]"
    $completePattern = "(?m)^\s*[-*+]\s*\[x\]"
    
    $statusMarkers.Incomplete = [regex]::Matches($Content, $incompletePattern).Count
    $statusMarkers.Complete = [regex]::Matches($Content, $completePattern).Count

    # Rechercher les marqueurs de statut personnalisÃ©s
    $customPattern = "(?m)^\s*[-*+]\s*\[([^x ])\]"
    $customMatches = [regex]::Matches($Content, $customPattern)
    
    foreach ($match in $customMatches) {
        $customMarker = $match.Groups[1].Value
        if (-not $statusMarkers.Custom.ContainsKey($customMarker)) {
            $statusMarkers.Custom[$customMarker] = 1
        } else {
            $statusMarkers.Custom[$customMarker] += 1
        }
    }

    # Rechercher les indicateurs textuels de progression
    $textualIndicators = @(
        "en cours", "en attente", "terminÃ©", "complÃ©tÃ©", "bloquÃ©", 
        "reportÃ©", "annulÃ©", "prioritaire", "urgent"
    )
    
    foreach ($indicator in $textualIndicators) {
        $pattern = "(?i)$indicator"
        $count = [regex]::Matches($Content, $pattern).Count
        if ($count -gt 0) {
            $statusMarkers.TextualIndicators[$indicator] = $count
        }
    }

    return $statusMarkers
}

# Fonction pour analyser les sections principales
function Get-MainSections {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $sections = @()
    $sectionPattern = "(?m)^###\s+(.+)$"
    $sectionMatches = [regex]::Matches($Content, $sectionPattern)
    
    foreach ($match in $sectionMatches) {
        $sectionTitle = $match.Groups[1].Value
        $sections += $sectionTitle
    }

    return $sections
}

# Fonction pour analyser la progression par section
function Get-SectionProgress {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content,
        
        [Parameter(Mandatory = $true)]
        [string[]]$Sections
    )

    $sectionProgress = @{}
    
    foreach ($section in $Sections) {
        # Ã‰chapper les caractÃ¨res spÃ©ciaux dans le titre de la section
        $escapedSection = [regex]::Escape($section)
        
        # Trouver le contenu de la section
        $sectionPattern = "(?ms)^###\s+$escapedSection\s*$(if ($Sections.IndexOf($section) -lt $Sections.Count - 1) { ".*?(?=^###\s+)" } else { ".*" })"
        $sectionMatch = [regex]::Match($Content, $sectionPattern)
        
        if ($sectionMatch.Success) {
            $sectionContent = $sectionMatch.Value
            
            # Compter les tÃ¢ches complÃ¨tes et incomplÃ¨tes dans la section
            $completePattern = "(?m)^\s*[-*+]\s*\[x\]"
            $incompletePattern = "(?m)^\s*[-*+]\s*\[ \]"
            
            $completeCount = [regex]::Matches($sectionContent, $completePattern).Count
            $incompleteCount = [regex]::Matches($sectionContent, $incompletePattern).Count
            
            $totalTasks = $completeCount + $incompleteCount
            $completionPercentage = if ($totalTasks -gt 0) {
                [Math]::Round(($completeCount / $totalTasks) * 100, 2)
            } else {
                0
            }
            
            $sectionProgress[$section] = @{
                TotalTasks = $totalTasks
                CompleteTasks = $completeCount
                IncompleteTasks = $incompleteCount
                CompletionPercentage = $completionPercentage
            }
        }
    }

    return $sectionProgress
}

# Analyser les marqueurs de statut
Write-Host "Analyse des marqueurs de statut dans: $RoadmapFilePath" -ForegroundColor Cyan
$statusMarkers = Get-StatusMarkers -Content $content

# Calculer le pourcentage de complÃ©tion global
$totalTasks = $statusMarkers.Incomplete + $statusMarkers.Complete
foreach ($customCount in $statusMarkers.Custom.Values) {
    $totalTasks += $customCount
}

$completionPercentage = if ($totalTasks -gt 0) {
    [Math]::Round(($statusMarkers.Complete / $totalTasks) * 100, 2)
} else {
    0
}

# Analyser les sections principales
$mainSections = Get-MainSections -Content $content

# Analyser la progression par section
$sectionProgress = Get-SectionProgress -Content $content -Sections $mainSections

# GÃ©nÃ©rer le rapport de progression
$report = "# Rapport de Progression de la Roadmap`r`n`r`n"
$report += "**Fichier analysÃ©:** $RoadmapFilePath`r`n"
$report += "**Date d'analyse:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`r`n`r`n"

$report += "## Progression Globale`r`n`r`n"
$report += "- **TÃ¢ches totales:** $totalTasks`r`n"
$report += "- **TÃ¢ches terminÃ©es:** $($statusMarkers.Complete)`r`n"
$report += "- **TÃ¢ches en cours:** $($statusMarkers.Incomplete)`r`n"
$report += "- **Pourcentage de complÃ©tion:** $completionPercentage%`r`n`r`n"

# CrÃ©er un graphique de progression en ASCII art
$progressBarWidth = 50
$completedChars = [Math]::Round(($completionPercentage / 100) * $progressBarWidth)
$remainingChars = $progressBarWidth - $completedChars

$progressBar = "["
$progressBar += "=" * $completedChars
$progressBar += " " * $remainingChars
$progressBar += "]"

$report += "````r`n"
$report += "$progressBar $completionPercentage%`r`n"
$report += "````r`n`r`n"

$report += "## Progression par Section`r`n`r`n"
$report += "| Section | TÃ¢ches Totales | TerminÃ©es | En Cours | Progression |`r`n"
$report += "|---------|---------------|-----------|----------|-------------|`r`n"

foreach ($section in $mainSections) {
    if ($sectionProgress.ContainsKey($section)) {
        $progress = $sectionProgress[$section]
        $report += "| $section | $($progress.TotalTasks) | $($progress.CompleteTasks) | $($progress.IncompleteTasks) | $($progress.CompletionPercentage)% |`r`n"
    }
}

$report += "`r`n## DÃ©tails des Marqueurs de Statut`r`n`r`n"
$report += "- **Marqueurs standard:**`r`n"
$report += "  - [ ] (Incomplet): $($statusMarkers.Incomplete) occurrences`r`n"
$report += "  - [x] (Complet): $($statusMarkers.Complete) occurrences`r`n`r`n"

if ($statusMarkers.Custom.Count -gt 0) {
    $report += "- **Marqueurs personnalisÃ©s:**`r`n"
    foreach ($marker in $statusMarkers.Custom.GetEnumerator()) {
        $report += "  - [$($marker.Key)]: $($marker.Value) occurrences`r`n"
    }
    $report += "`r`n"
}

if ($statusMarkers.TextualIndicators.Count -gt 0) {
    $report += "- **Indicateurs textuels:**`r`n"
    foreach ($indicator in $statusMarkers.TextualIndicators.GetEnumerator()) {
        $report += "  - '$($indicator.Key)': $($indicator.Value) occurrences`r`n"
    }
    $report += "`r`n"
}

$report += "## Recommandations`r`n`r`n"

# GÃ©nÃ©rer des recommandations basÃ©es sur l'analyse
$recommendations = @()

# Recommandation pour la progression globale
if ($completionPercentage -lt 25) {
    $recommendations += "- **Progression globale:** La progression est encore faible ($completionPercentage%). Concentrez-vous sur la complÃ©tion des tÃ¢ches prioritaires."
} elseif ($completionPercentage -lt 50) {
    $recommendations += "- **Progression globale:** La progression est modÃ©rÃ©e ($completionPercentage%). Continuez Ã  avancer rÃ©guliÃ¨rement."
} elseif ($completionPercentage -lt 75) {
    $recommendations += "- **Progression globale:** La progression est bonne ($completionPercentage%). Concentrez-vous sur les sections les moins avancÃ©es."
} else {
    $recommendations += "- **Progression globale:** La progression est excellente ($completionPercentage%). Finalisez les derniÃ¨res tÃ¢ches restantes."
}

# Recommandation pour les sections les moins avancÃ©es
$leastProgressedSections = $sectionProgress.GetEnumerator() | 
                          Where-Object { $_.Value.TotalTasks -gt 0 } |
                          Sort-Object -Property { $_.Value.CompletionPercentage } |
                          Select-Object -First 3

if ($leastProgressedSections.Count -gt 0) {
    $sectionsList = ($leastProgressedSections | ForEach-Object { "$($_.Key) ($($_.Value.CompletionPercentage)%)" }) -join ", "
    $recommendations += "- **Sections Ã  prioriser:** Les sections suivantes ont la progression la plus faible: $sectionsList."
}

# Recommandation pour les sections les plus avancÃ©es
$mostProgressedSections = $sectionProgress.GetEnumerator() | 
                         Where-Object { $_.Value.TotalTasks -gt 0 -and $_.Value.CompletionPercentage -lt 100 } |
                         Sort-Object -Property { $_.Value.CompletionPercentage } -Descending |
                         Select-Object -First 3

if ($mostProgressedSections.Count -gt 0) {
    $sectionsList = ($mostProgressedSections | ForEach-Object { "$($_.Key) ($($_.Value.CompletionPercentage)%)" }) -join ", "
    $recommendations += "- **Sections presque terminÃ©es:** Les sections suivantes sont presque terminÃ©es: $sectionsList. Envisagez de les finaliser rapidement."
}

# Ajouter les recommandations au rapport
if ($recommendations.Count -gt 0) {
    $report += $recommendations -join "`r`n"
} else {
    $report += "Aucune recommandation spÃ©cifique. Continuez Ã  suivre votre plan de travail."
}

# Enregistrer le rapport dans un fichier
$report | Out-File -FilePath $OutputPath -Encoding UTF8

Write-Host "Rapport de progression gÃ©nÃ©rÃ©: $OutputPath" -ForegroundColor Green
Write-Host "Analyse terminÃ©e." -ForegroundColor Cyan
