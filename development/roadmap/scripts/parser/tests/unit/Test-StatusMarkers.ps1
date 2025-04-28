# Test-StatusMarkers.ps1
# Script pour tester l'analyse des marqueurs de statut dans un fichier markdown de roadmap

param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapFilePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\roadmap_complete_converted.md"
)

# VÃ©rifier si le fichier existe
if (-not (Test-Path -Path $RoadmapFilePath)) {
    Write-Error "Le fichier '$RoadmapFilePath' n'existe pas."
    exit 1
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

# Analyser les marqueurs de statut
Write-Host "Analyse des marqueurs de statut dans: $RoadmapFilePath" -ForegroundColor Cyan
$statusMarkers = Get-StatusMarkers -Content $content

# Afficher les rÃ©sultats
Write-Host "`nMarqueurs de statut dÃ©tectÃ©s:" -ForegroundColor Green
Write-Host "  [ ] (Incomplet): $($statusMarkers.Incomplete) occurrences"
Write-Host "  [x] (Complet): $($statusMarkers.Complete) occurrences"

Write-Host "`nMarqueurs personnalisÃ©s:" -ForegroundColor Yellow
if ($statusMarkers.Custom.Count -eq 0) {
    Write-Host "  Aucun marqueur personnalisÃ© dÃ©tectÃ©."
} else {
    foreach ($marker in $statusMarkers.Custom.GetEnumerator()) {
        Write-Host "  [$($marker.Key)]: $($marker.Value) occurrences"
    }
}

Write-Host "`nIndicateurs textuels de progression:" -ForegroundColor Yellow
if ($statusMarkers.TextualIndicators.Count -eq 0) {
    Write-Host "  Aucun indicateur textuel dÃ©tectÃ©."
} else {
    foreach ($indicator in $statusMarkers.TextualIndicators.GetEnumerator()) {
        Write-Host "  '$($indicator.Key)': $($indicator.Value) occurrences"
    }
}

# Calculer le pourcentage de complÃ©tion
$totalTasks = $statusMarkers.Incomplete + $statusMarkers.Complete
foreach ($customCount in $statusMarkers.Custom.Values) {
    $totalTasks += $customCount
}

$completionPercentage = if ($totalTasks -gt 0) {
    [Math]::Round(($statusMarkers.Complete / $totalTasks) * 100, 2)
} else {
    0
}

Write-Host "`nStatistiques de progression:" -ForegroundColor Green
Write-Host "  TÃ¢ches totales: $totalTasks"
Write-Host "  TÃ¢ches terminÃ©es: $($statusMarkers.Complete)"
Write-Host "  TÃ¢ches en cours: $($statusMarkers.Incomplete)"
Write-Host "  Pourcentage de complÃ©tion: $completionPercentage%"

Write-Host "`nAnalyse terminÃ©e." -ForegroundColor Cyan
