<#
.SYNOPSIS
    Identifie et priorise les améliorations nécessaires pour les gestionnaires.

.DESCRIPTION
    Ce script identifie et priorise les améliorations nécessaires pour les gestionnaires
    en fonction de critères définis. Il évalue chaque amélioration selon ces critères,
    calcule les scores de priorité et classe les améliorations par ordre de priorité.

.PARAMETER InputFile
    Chemin vers le fichier JSON contenant les améliorations à prioriser.

.PARAMETER OutputFile
    Chemin vers le fichier de sortie pour le rapport de priorisation.

.PARAMETER Format
    Format du rapport de sortie. Les valeurs possibles sont : JSON, CSV, HTML, Markdown.
    Par défaut : Markdown

.EXAMPLE
    .\prioritize-improvements.ps1 -InputFile "data\improvements.json" -OutputFile "reports\improvement-priorities.md"
    Génère un rapport de priorisation au format Markdown.

.NOTES
    Auteur: Analysis Team
    Version: 1.0
    Date de création: 2025-05-06
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$InputFile,

    [Parameter(Mandatory = $true)]
    [string]$OutputFile,

    [Parameter(Mandatory = $false)]
    [ValidateSet("JSON", "CSV", "HTML", "Markdown")]
    [string]$Format = "Markdown"
)

# Vérifier que le fichier d'entrée existe
if (-not (Test-Path -Path $InputFile)) {
    Write-Error "Le fichier d'entrée n'existe pas : $InputFile"
    exit 1
}

# Créer le répertoire de sortie s'il n'existe pas
$outputDir = Split-Path -Path $OutputFile -Parent
if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

# Charger les données des améliorations
try {
    $improvementsData = Get-Content -Path $InputFile -Raw | ConvertFrom-Json
} catch {
    Write-Error "Erreur lors du chargement du fichier d'entrée : $_"
    exit 1
}

# Fonction pour définir les critères de priorisation
function Define-PrioritizationCriteria {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$ImprovementsData
    )

    # Utiliser les critères définis dans le fichier d'entrée
    $criteria = $ImprovementsData.Criteria

    # Vérifier que les poids des critères totalisent 1.0
    $totalWeight = 0
    foreach ($criterion in $criteria.PSObject.Properties) {
        $totalWeight += $criterion.Value.Weight
    }

    if ([math]::Abs($totalWeight - 1.0) -gt 0.001) {
        Write-Warning "La somme des poids des critères n'est pas égale à 1.0 (Total: $totalWeight). Les poids seront normalisés."
        
        # Normaliser les poids
        foreach ($criterion in $criteria.PSObject.Properties) {
            $criteria.($criterion.Name).Weight = $criterion.Value.Weight / $totalWeight
        }
    }

    return $criteria
}

# Fonction pour évaluer chaque amélioration selon les critères
function Evaluate-Improvements {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$ImprovementsData,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Criteria
    )

    $evaluatedImprovements = @()

    foreach ($manager in $ImprovementsData.Managers) {
        foreach ($improvement in $manager.Improvements) {
            # Vérifier que tous les critères sont présents
            foreach ($criterion in $Criteria.PSObject.Properties.Name) {
                if (-not $improvement.Scores.PSObject.Properties.Name.Contains($criterion)) {
                    Write-Warning "Le critère '$criterion' est manquant pour l'amélioration '$($improvement.Name)' du gestionnaire '$($manager.Name)'. Une valeur par défaut de 5 sera utilisée."
                    Add-Member -InputObject $improvement.Scores -MemberType NoteProperty -Name $criterion -Value 5
                }
            }

            # Créer un objet avec l'amélioration évaluée
            $evaluatedImprovement = [PSCustomObject]@{
                ManagerName = $manager.Name
                ManagerCategory = $manager.Category
                Name = $improvement.Name
                Description = $improvement.Description
                Type = $improvement.Type
                Effort = $improvement.Effort
                Impact = $improvement.Impact
                Dependencies = $improvement.Dependencies
                Scores = $improvement.Scores
                PriorityScore = 0 # Sera calculé ultérieurement
            }

            $evaluatedImprovements += $evaluatedImprovement
        }
    }

    return $evaluatedImprovements
}

# Fonction pour calculer les scores de priorité
function Calculate-PriorityScores {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$EvaluatedImprovements,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Criteria
    )

    foreach ($improvement in $EvaluatedImprovements) {
        $priorityScore = 0

        # Calculer le score pondéré pour chaque critère
        foreach ($criterion in $Criteria.PSObject.Properties) {
            $criterionName = $criterion.Name
            $criterionWeight = $criterion.Value.Weight
            $criterionScore = $improvement.Scores.$criterionName

            $priorityScore += $criterionScore * $criterionWeight
        }

        # Arrondir le score à deux décimales
        $improvement.PriorityScore = [math]::Round($priorityScore, 2)
    }

    return $EvaluatedImprovements
}

# Fonction pour classer les améliorations par ordre de priorité
function Rank-Improvements {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$ScoredImprovements
    )

    # Trier les améliorations par score de priorité (décroissant)
    $rankedImprovements = $ScoredImprovements | Sort-Object -Property PriorityScore -Descending

    # Ajouter le rang à chaque amélioration
    for ($i = 0; $i -lt $rankedImprovements.Count; $i++) {
        Add-Member -InputObject $rankedImprovements[$i] -MemberType NoteProperty -Name Rank -Value ($i + 1)
    }

    return $rankedImprovements
}

# Fonction pour générer le rapport au format Markdown
function Generate-MarkdownReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Report
    )

    $markdown = "# Rapport de Priorisation des Améliorations`n`n"
    $markdown += "Date de génération : $($Report.GeneratedAt)`n`n"
    
    # Ajouter les critères de priorisation
    $markdown += "## Critères de Priorisation`n`n"
    $markdown += "| Critère | Poids | Description |`n"
    $markdown += "|---------|-------|-------------|`n"
    
    foreach ($criterion in $Report.Criteria.PSObject.Properties) {
        $markdown += "| $($criterion.Name) | $($criterion.Value.Weight) | $($criterion.Value.Description) |`n"
    }
    
    # Ajouter les améliorations priorisées
    $markdown += "`n## Améliorations Priorisées`n`n"
    $markdown += "| Rang | Amélioration | Gestionnaire | Score | Type | Effort | Impact |`n"
    $markdown += "|------|--------------|--------------|-------|------|--------|--------|`n"
    
    foreach ($improvement in $Report.RankedImprovements) {
        $markdown += "| $($improvement.Rank) | $($improvement.Name) | $($improvement.ManagerName) | $($improvement.PriorityScore) | $($improvement.Type) | $($improvement.Effort) | $($improvement.Impact) |`n"
    }
    
    # Ajouter les détails des améliorations
    $markdown += "`n## Détails des Améliorations`n`n"
    
    foreach ($improvement in $Report.RankedImprovements) {
        $markdown += "### $($improvement.Rank). $($improvement.Name) (Score: $($improvement.PriorityScore))`n`n"
        $markdown += "**Gestionnaire :** $($improvement.ManagerName) ($($improvement.ManagerCategory))`n`n"
        $markdown += "**Description :** $($improvement.Description)`n`n"
        $markdown += "**Type :** $($improvement.Type)`n`n"
        $markdown += "**Effort :** $($improvement.Effort)`n`n"
        $markdown += "**Impact :** $($improvement.Impact)`n`n"
        
        if ($improvement.Dependencies -and $improvement.Dependencies.Count -gt 0) {
            $markdown += "**Dépendances :**`n`n"
            foreach ($dependency in $improvement.Dependencies) {
                $markdown += "- $dependency`n"
            }
            $markdown += "`n"
        }
        
        $markdown += "**Scores par critère :**`n`n"
        $markdown += "| Critère | Score |`n"
        $markdown += "|---------|-------|`n"
        
        foreach ($criterion in $improvement.Scores.PSObject.Properties) {
            $markdown += "| $($criterion.Name) | $($criterion.Value) |`n"
        }
        
        $markdown += "`n"
    }
    
    # Ajouter des recommandations
    $markdown += "## Recommandations`n`n"
    
    $markdown += "### Améliorations à court terme (priorité élevée)`n`n"
    $highPriorityImprovements = $Report.RankedImprovements | Where-Object { $_.PriorityScore -ge $Report.Thresholds.HighPriorityThreshold }
    if ($highPriorityImprovements.Count -gt 0) {
        foreach ($improvement in $highPriorityImprovements) {
            $markdown += "- **$($improvement.Name)** ($($improvement.ManagerName)) - Score: $($improvement.PriorityScore)`n"
        }
    } else {
        $markdown += "Aucune amélioration à priorité élevée identifiée.`n"
    }
    
    $markdown += "`n### Améliorations à moyen terme (priorité moyenne)`n`n"
    $mediumPriorityImprovements = $Report.RankedImprovements | Where-Object { $_.PriorityScore -ge $Report.Thresholds.MediumPriorityThreshold -and $_.PriorityScore -lt $Report.Thresholds.HighPriorityThreshold }
    if ($mediumPriorityImprovements.Count -gt 0) {
        foreach ($improvement in $mediumPriorityImprovements) {
            $markdown += "- **$($improvement.Name)** ($($improvement.ManagerName)) - Score: $($improvement.PriorityScore)`n"
        }
    } else {
        $markdown += "Aucune amélioration à priorité moyenne identifiée.`n"
    }
    
    $markdown += "`n### Améliorations à long terme (priorité basse)`n`n"
    $lowPriorityImprovements = $Report.RankedImprovements | Where-Object { $_.PriorityScore -lt $Report.Thresholds.MediumPriorityThreshold }
    if ($lowPriorityImprovements.Count -gt 0) {
        foreach ($improvement in $lowPriorityImprovements) {
            $markdown += "- **$($improvement.Name)** ($($improvement.ManagerName)) - Score: $($improvement.PriorityScore)`n"
        }
    } else {
        $markdown += "Aucune amélioration à priorité basse identifiée.`n"
    }
    
    return $markdown
}

# Fonction pour générer le rapport au format HTML
function Generate-HtmlReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Report
    )

    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de Priorisation des Améliorations</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2, h3, h4 { color: #333; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .priority-high { background-color: #ffcccc; }
        .priority-medium { background-color: #ffffcc; }
        .priority-low { background-color: #ccffcc; }
        .details { margin-bottom: 30px; padding: 10px; border: 1px solid #ddd; border-radius: 5px; }
        .recommendations { margin-top: 30px; }
        .high-priority { color: #cc0000; }
        .medium-priority { color: #cccc00; }
        .low-priority { color: #00cc00; }
    </style>
</head>
<body>
    <h1>Rapport de Priorisation des Améliorations</h1>
    <p>Date de génération : $($Report.GeneratedAt)</p>
    
    <h2>Critères de Priorisation</h2>
    <table>
        <tr>
            <th>Critère</th>
            <th>Poids</th>
            <th>Description</th>
        </tr>
"@

    foreach ($criterion in $Report.Criteria.PSObject.Properties) {
        $html += @"
        <tr>
            <td>$($criterion.Name)</td>
            <td>$($criterion.Value.Weight)</td>
            <td>$($criterion.Value.Description)</td>
        </tr>
"@
    }

    $html += @"
    </table>
    
    <h2>Améliorations Priorisées</h2>
    <table>
        <tr>
            <th>Rang</th>
            <th>Amélioration</th>
            <th>Gestionnaire</th>
            <th>Score</th>
            <th>Type</th>
            <th>Effort</th>
            <th>Impact</th>
        </tr>
"@

    foreach ($improvement in $Report.RankedImprovements) {
        $priorityClass = "priority-medium"
        if ($improvement.PriorityScore -ge $Report.Thresholds.HighPriorityThreshold) {
            $priorityClass = "priority-high"
        } elseif ($improvement.PriorityScore -lt $Report.Thresholds.MediumPriorityThreshold) {
            $priorityClass = "priority-low"
        }
        
        $html += @"
        <tr class="$priorityClass">
            <td>$($improvement.Rank)</td>
            <td>$($improvement.Name)</td>
            <td>$($improvement.ManagerName)</td>
            <td>$($improvement.PriorityScore)</td>
            <td>$($improvement.Type)</td>
            <td>$($improvement.Effort)</td>
            <td>$($improvement.Impact)</td>
        </tr>
"@
    }

    $html += @"
    </table>
    
    <h2>Détails des Améliorations</h2>
"@

    foreach ($improvement in $Report.RankedImprovements) {
        $priorityClass = "priority-medium"
        if ($improvement.PriorityScore -ge $Report.Thresholds.HighPriorityThreshold) {
            $priorityClass = "priority-high"
        } elseif ($improvement.PriorityScore -lt $Report.Thresholds.MediumPriorityThreshold) {
            $priorityClass = "priority-low"
        }
        
        $html += @"
    <div class="details $priorityClass">
        <h3>$($improvement.Rank). $($improvement.Name) (Score: $($improvement.PriorityScore))</h3>
        <p><strong>Gestionnaire :</strong> $($improvement.ManagerName) ($($improvement.ManagerCategory))</p>
        <p><strong>Description :</strong> $($improvement.Description)</p>
        <p><strong>Type :</strong> $($improvement.Type)</p>
        <p><strong>Effort :</strong> $($improvement.Effort)</p>
        <p><strong>Impact :</strong> $($improvement.Impact)</p>
"@

        if ($improvement.Dependencies -and $improvement.Dependencies.Count -gt 0) {
            $html += @"
        <p><strong>Dépendances :</strong></p>
        <ul>
"@
            foreach ($dependency in $improvement.Dependencies) {
                $html += @"
            <li>$dependency</li>
"@
            }
            $html += @"
        </ul>
"@
        }

        $html += @"
        <p><strong>Scores par critère :</strong></p>
        <table>
            <tr>
                <th>Critère</th>
                <th>Score</th>
            </tr>
"@

        foreach ($criterion in $improvement.Scores.PSObject.Properties) {
            $html += @"
            <tr>
                <td>$($criterion.Name)</td>
                <td>$($criterion.Value)</td>
            </tr>
"@
        }

        $html += @"
        </table>
    </div>
"@
    }

    $html += @"
    <div class="recommendations">
        <h2>Recommandations</h2>
        
        <h3>Améliorations à court terme (priorité élevée)</h3>
"@

    $highPriorityImprovements = $Report.RankedImprovements | Where-Object { $_.PriorityScore -ge $Report.Thresholds.HighPriorityThreshold }
    if ($highPriorityImprovements.Count -gt 0) {
        $html += @"
        <ul>
"@
        foreach ($improvement in $highPriorityImprovements) {
            $html += @"
            <li class="high-priority"><strong>$($improvement.Name)</strong> ($($improvement.ManagerName)) - Score: $($improvement.PriorityScore)</li>
"@
        }
        $html += @"
        </ul>
"@
    } else {
        $html += @"
        <p>Aucune amélioration à priorité élevée identifiée.</p>
"@
    }

    $html += @"
        <h3>Améliorations à moyen terme (priorité moyenne)</h3>
"@

    $mediumPriorityImprovements = $Report.RankedImprovements | Where-Object { $_.PriorityScore -ge $Report.Thresholds.MediumPriorityThreshold -and $_.PriorityScore -lt $Report.Thresholds.HighPriorityThreshold }
    if ($mediumPriorityImprovements.Count -gt 0) {
        $html += @"
        <ul>
"@
        foreach ($improvement in $mediumPriorityImprovements) {
            $html += @"
            <li class="medium-priority"><strong>$($improvement.Name)</strong> ($($improvement.ManagerName)) - Score: $($improvement.PriorityScore)</li>
"@
        }
        $html += @"
        </ul>
"@
    } else {
        $html += @"
        <p>Aucune amélioration à priorité moyenne identifiée.</p>
"@
    }

    $html += @"
        <h3>Améliorations à long terme (priorité basse)</h3>
"@

    $lowPriorityImprovements = $Report.RankedImprovements | Where-Object { $_.PriorityScore -lt $Report.Thresholds.MediumPriorityThreshold }
    if ($lowPriorityImprovements.Count -gt 0) {
        $html += @"
        <ul>
"@
        foreach ($improvement in $lowPriorityImprovements) {
            $html += @"
            <li class="low-priority"><strong>$($improvement.Name)</strong> ($($improvement.ManagerName)) - Score: $($improvement.PriorityScore)</li>
"@
        }
        $html += @"
        </ul>
"@
    } else {
        $html += @"
        <p>Aucune amélioration à priorité basse identifiée.</p>
"@
    }

    $html += @"
    </div>
</body>
</html>
"@

    return $html
}

# Fonction pour générer le rapport au format CSV
function Generate-CsvReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Report
    )

    $csv = "Rang,Amélioration,Gestionnaire,Score,Type,Effort,Impact`n"
    
    foreach ($improvement in $Report.RankedImprovements) {
        $csv += "$($improvement.Rank),$($improvement.Name),$($improvement.ManagerName),$($improvement.PriorityScore),$($improvement.Type),$($improvement.Effort),$($improvement.Impact)`n"
    }
    
    return $csv
}

# Exécuter le processus de priorisation
$criteria = Define-PrioritizationCriteria -ImprovementsData $improvementsData
$evaluatedImprovements = Evaluate-Improvements -ImprovementsData $improvementsData -Criteria $criteria
$scoredImprovements = Calculate-PriorityScores -EvaluatedImprovements $evaluatedImprovements -Criteria $criteria
$rankedImprovements = Rank-Improvements -ScoredImprovements $scoredImprovements

# Créer le rapport de priorisation
$prioritizationReport = [PSCustomObject]@{
    GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Criteria = $criteria
    RankedImprovements = $rankedImprovements
    Thresholds = $improvementsData.Thresholds
}

# Générer le rapport dans le format spécifié
switch ($Format) {
    "Markdown" {
        $reportContent = Generate-MarkdownReport -Report $prioritizationReport
    }
    "HTML" {
        $reportContent = Generate-HtmlReport -Report $prioritizationReport
    }
    "CSV" {
        $reportContent = Generate-CsvReport -Report $prioritizationReport
    }
    "JSON" {
        $reportContent = $prioritizationReport | ConvertTo-Json -Depth 10
    }
}

# Enregistrer le rapport
try {
    $reportContent | Out-File -FilePath $OutputFile -Encoding UTF8
    Write-Host "Rapport de priorisation généré avec succès : $OutputFile"
} catch {
    Write-Error "Erreur lors de l'enregistrement du rapport : $_"
    exit 1
}

# Afficher un résumé des résultats
Write-Host "`nRésumé de la priorisation :"
Write-Host "--------------------------------"
Write-Host "  Améliorations évaluées : $($rankedImprovements.Count)"

$highPriorityCount = ($rankedImprovements | Where-Object { $_.PriorityScore -ge $improvementsData.Thresholds.HighPriorityThreshold }).Count
$mediumPriorityCount = ($rankedImprovements | Where-Object { $_.PriorityScore -ge $improvementsData.Thresholds.MediumPriorityThreshold -and $_.PriorityScore -lt $improvementsData.Thresholds.HighPriorityThreshold }).Count
$lowPriorityCount = ($rankedImprovements | Where-Object { $_.PriorityScore -lt $improvementsData.Thresholds.MediumPriorityThreshold }).Count

Write-Host "  Améliorations à priorité élevée : $highPriorityCount"
Write-Host "  Améliorations à priorité moyenne : $mediumPriorityCount"
Write-Host "  Améliorations à priorité basse : $lowPriorityCount"
