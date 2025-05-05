<#
.SYNOPSIS
    Identifie et priorise les amÃ©liorations nÃ©cessaires pour les gestionnaires.

.DESCRIPTION
    Ce script identifie et priorise les amÃ©liorations nÃ©cessaires pour les gestionnaires
    en fonction de critÃ¨res dÃ©finis. Il Ã©value chaque amÃ©lioration selon ces critÃ¨res,
    calcule les scores de prioritÃ© et classe les amÃ©liorations par ordre de prioritÃ©.

.PARAMETER InputFile
    Chemin vers le fichier JSON contenant les amÃ©liorations Ã  prioriser.

.PARAMETER OutputFile
    Chemin vers le fichier de sortie pour le rapport de priorisation.

.PARAMETER Format
    Format du rapport de sortie. Les valeurs possibles sont : JSON, CSV, HTML, Markdown.
    Par dÃ©faut : Markdown

.EXAMPLE
    .\prioritize-improvements.ps1 -InputFile "data\improvements.json" -OutputFile "reports\improvement-priorities.md"
    GÃ©nÃ¨re un rapport de priorisation au format Markdown.

.NOTES
    Auteur: Analysis Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-06
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

# VÃ©rifier que le fichier d'entrÃ©e existe
if (-not (Test-Path -Path $InputFile)) {
    Write-Error "Le fichier d'entrÃ©e n'existe pas : $InputFile"
    exit 1
}

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
$outputDir = Split-Path -Path $OutputFile -Parent
if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

# Charger les donnÃ©es des amÃ©liorations
try {
    $improvementsData = Get-Content -Path $InputFile -Raw | ConvertFrom-Json
} catch {
    Write-Error "Erreur lors du chargement du fichier d'entrÃ©e : $_"
    exit 1
}

# Fonction pour dÃ©finir les critÃ¨res de priorisation
function Define-PrioritizationCriteria {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$ImprovementsData
    )

    # Utiliser les critÃ¨res dÃ©finis dans le fichier d'entrÃ©e
    $criteria = $ImprovementsData.Criteria

    # VÃ©rifier que les poids des critÃ¨res totalisent 1.0
    $totalWeight = 0
    foreach ($criterion in $criteria.PSObject.Properties) {
        $totalWeight += $criterion.Value.Weight
    }

    if ([math]::Abs($totalWeight - 1.0) -gt 0.001) {
        Write-Warning "La somme des poids des critÃ¨res n'est pas Ã©gale Ã  1.0 (Total: $totalWeight). Les poids seront normalisÃ©s."
        
        # Normaliser les poids
        foreach ($criterion in $criteria.PSObject.Properties) {
            $criteria.($criterion.Name).Weight = $criterion.Value.Weight / $totalWeight
        }
    }

    return $criteria
}

# Fonction pour Ã©valuer chaque amÃ©lioration selon les critÃ¨res
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
            # VÃ©rifier que tous les critÃ¨res sont prÃ©sents
            foreach ($criterion in $Criteria.PSObject.Properties.Name) {
                if (-not $improvement.Scores.PSObject.Properties.Name.Contains($criterion)) {
                    Write-Warning "Le critÃ¨re '$criterion' est manquant pour l'amÃ©lioration '$($improvement.Name)' du gestionnaire '$($manager.Name)'. Une valeur par dÃ©faut de 5 sera utilisÃ©e."
                    Add-Member -InputObject $improvement.Scores -MemberType NoteProperty -Name $criterion -Value 5
                }
            }

            # CrÃ©er un objet avec l'amÃ©lioration Ã©valuÃ©e
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
                PriorityScore = 0 # Sera calculÃ© ultÃ©rieurement
            }

            $evaluatedImprovements += $evaluatedImprovement
        }
    }

    return $evaluatedImprovements
}

# Fonction pour calculer les scores de prioritÃ©
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

        # Calculer le score pondÃ©rÃ© pour chaque critÃ¨re
        foreach ($criterion in $Criteria.PSObject.Properties) {
            $criterionName = $criterion.Name
            $criterionWeight = $criterion.Value.Weight
            $criterionScore = $improvement.Scores.$criterionName

            $priorityScore += $criterionScore * $criterionWeight
        }

        # Arrondir le score Ã  deux dÃ©cimales
        $improvement.PriorityScore = [math]::Round($priorityScore, 2)
    }

    return $EvaluatedImprovements
}

# Fonction pour classer les amÃ©liorations par ordre de prioritÃ©
function Rank-Improvements {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$ScoredImprovements
    )

    # Trier les amÃ©liorations par score de prioritÃ© (dÃ©croissant)
    $rankedImprovements = $ScoredImprovements | Sort-Object -Property PriorityScore -Descending

    # Ajouter le rang Ã  chaque amÃ©lioration
    for ($i = 0; $i -lt $rankedImprovements.Count; $i++) {
        Add-Member -InputObject $rankedImprovements[$i] -MemberType NoteProperty -Name Rank -Value ($i + 1)
    }

    return $rankedImprovements
}

# Fonction pour gÃ©nÃ©rer le rapport au format Markdown
function Generate-MarkdownReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Report
    )

    $markdown = "# Rapport de Priorisation des AmÃ©liorations`n`n"
    $markdown += "Date de gÃ©nÃ©ration : $($Report.GeneratedAt)`n`n"
    
    # Ajouter les critÃ¨res de priorisation
    $markdown += "## CritÃ¨res de Priorisation`n`n"
    $markdown += "| CritÃ¨re | Poids | Description |`n"
    $markdown += "|---------|-------|-------------|`n"
    
    foreach ($criterion in $Report.Criteria.PSObject.Properties) {
        $markdown += "| $($criterion.Name) | $($criterion.Value.Weight) | $($criterion.Value.Description) |`n"
    }
    
    # Ajouter les amÃ©liorations priorisÃ©es
    $markdown += "`n## AmÃ©liorations PriorisÃ©es`n`n"
    $markdown += "| Rang | AmÃ©lioration | Gestionnaire | Score | Type | Effort | Impact |`n"
    $markdown += "|------|--------------|--------------|-------|------|--------|--------|`n"
    
    foreach ($improvement in $Report.RankedImprovements) {
        $markdown += "| $($improvement.Rank) | $($improvement.Name) | $($improvement.ManagerName) | $($improvement.PriorityScore) | $($improvement.Type) | $($improvement.Effort) | $($improvement.Impact) |`n"
    }
    
    # Ajouter les dÃ©tails des amÃ©liorations
    $markdown += "`n## DÃ©tails des AmÃ©liorations`n`n"
    
    foreach ($improvement in $Report.RankedImprovements) {
        $markdown += "### $($improvement.Rank). $($improvement.Name) (Score: $($improvement.PriorityScore))`n`n"
        $markdown += "**Gestionnaire :** $($improvement.ManagerName) ($($improvement.ManagerCategory))`n`n"
        $markdown += "**Description :** $($improvement.Description)`n`n"
        $markdown += "**Type :** $($improvement.Type)`n`n"
        $markdown += "**Effort :** $($improvement.Effort)`n`n"
        $markdown += "**Impact :** $($improvement.Impact)`n`n"
        
        if ($improvement.Dependencies -and $improvement.Dependencies.Count -gt 0) {
            $markdown += "**DÃ©pendances :**`n`n"
            foreach ($dependency in $improvement.Dependencies) {
                $markdown += "- $dependency`n"
            }
            $markdown += "`n"
        }
        
        $markdown += "**Scores par critÃ¨re :**`n`n"
        $markdown += "| CritÃ¨re | Score |`n"
        $markdown += "|---------|-------|`n"
        
        foreach ($criterion in $improvement.Scores.PSObject.Properties) {
            $markdown += "| $($criterion.Name) | $($criterion.Value) |`n"
        }
        
        $markdown += "`n"
    }
    
    # Ajouter des recommandations
    $markdown += "## Recommandations`n`n"
    
    $markdown += "### AmÃ©liorations Ã  court terme (prioritÃ© Ã©levÃ©e)`n`n"
    $highPriorityImprovements = $Report.RankedImprovements | Where-Object { $_.PriorityScore -ge $Report.Thresholds.HighPriorityThreshold }
    if ($highPriorityImprovements.Count -gt 0) {
        foreach ($improvement in $highPriorityImprovements) {
            $markdown += "- **$($improvement.Name)** ($($improvement.ManagerName)) - Score: $($improvement.PriorityScore)`n"
        }
    } else {
        $markdown += "Aucune amÃ©lioration Ã  prioritÃ© Ã©levÃ©e identifiÃ©e.`n"
    }
    
    $markdown += "`n### AmÃ©liorations Ã  moyen terme (prioritÃ© moyenne)`n`n"
    $mediumPriorityImprovements = $Report.RankedImprovements | Where-Object { $_.PriorityScore -ge $Report.Thresholds.MediumPriorityThreshold -and $_.PriorityScore -lt $Report.Thresholds.HighPriorityThreshold }
    if ($mediumPriorityImprovements.Count -gt 0) {
        foreach ($improvement in $mediumPriorityImprovements) {
            $markdown += "- **$($improvement.Name)** ($($improvement.ManagerName)) - Score: $($improvement.PriorityScore)`n"
        }
    } else {
        $markdown += "Aucune amÃ©lioration Ã  prioritÃ© moyenne identifiÃ©e.`n"
    }
    
    $markdown += "`n### AmÃ©liorations Ã  long terme (prioritÃ© basse)`n`n"
    $lowPriorityImprovements = $Report.RankedImprovements | Where-Object { $_.PriorityScore -lt $Report.Thresholds.MediumPriorityThreshold }
    if ($lowPriorityImprovements.Count -gt 0) {
        foreach ($improvement in $lowPriorityImprovements) {
            $markdown += "- **$($improvement.Name)** ($($improvement.ManagerName)) - Score: $($improvement.PriorityScore)`n"
        }
    } else {
        $markdown += "Aucune amÃ©lioration Ã  prioritÃ© basse identifiÃ©e.`n"
    }
    
    return $markdown
}

# Fonction pour gÃ©nÃ©rer le rapport au format HTML
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
    <title>Rapport de Priorisation des AmÃ©liorations</title>
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
    <h1>Rapport de Priorisation des AmÃ©liorations</h1>
    <p>Date de gÃ©nÃ©ration : $($Report.GeneratedAt)</p>
    
    <h2>CritÃ¨res de Priorisation</h2>
    <table>
        <tr>
            <th>CritÃ¨re</th>
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
    
    <h2>AmÃ©liorations PriorisÃ©es</h2>
    <table>
        <tr>
            <th>Rang</th>
            <th>AmÃ©lioration</th>
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
    
    <h2>DÃ©tails des AmÃ©liorations</h2>
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
        <p><strong>DÃ©pendances :</strong></p>
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
        <p><strong>Scores par critÃ¨re :</strong></p>
        <table>
            <tr>
                <th>CritÃ¨re</th>
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
        
        <h3>AmÃ©liorations Ã  court terme (prioritÃ© Ã©levÃ©e)</h3>
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
        <p>Aucune amÃ©lioration Ã  prioritÃ© Ã©levÃ©e identifiÃ©e.</p>
"@
    }

    $html += @"
        <h3>AmÃ©liorations Ã  moyen terme (prioritÃ© moyenne)</h3>
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
        <p>Aucune amÃ©lioration Ã  prioritÃ© moyenne identifiÃ©e.</p>
"@
    }

    $html += @"
        <h3>AmÃ©liorations Ã  long terme (prioritÃ© basse)</h3>
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
        <p>Aucune amÃ©lioration Ã  prioritÃ© basse identifiÃ©e.</p>
"@
    }

    $html += @"
    </div>
</body>
</html>
"@

    return $html
}

# Fonction pour gÃ©nÃ©rer le rapport au format CSV
function Generate-CsvReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Report
    )

    $csv = "Rang,AmÃ©lioration,Gestionnaire,Score,Type,Effort,Impact`n"
    
    foreach ($improvement in $Report.RankedImprovements) {
        $csv += "$($improvement.Rank),$($improvement.Name),$($improvement.ManagerName),$($improvement.PriorityScore),$($improvement.Type),$($improvement.Effort),$($improvement.Impact)`n"
    }
    
    return $csv
}

# ExÃ©cuter le processus de priorisation
$criteria = Define-PrioritizationCriteria -ImprovementsData $improvementsData
$evaluatedImprovements = Evaluate-Improvements -ImprovementsData $improvementsData -Criteria $criteria
$scoredImprovements = Calculate-PriorityScores -EvaluatedImprovements $evaluatedImprovements -Criteria $criteria
$rankedImprovements = Rank-Improvements -ScoredImprovements $scoredImprovements

# CrÃ©er le rapport de priorisation
$prioritizationReport = [PSCustomObject]@{
    GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Criteria = $criteria
    RankedImprovements = $rankedImprovements
    Thresholds = $improvementsData.Thresholds
}

# GÃ©nÃ©rer le rapport dans le format spÃ©cifiÃ©
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
    Write-Host "Rapport de priorisation gÃ©nÃ©rÃ© avec succÃ¨s : $OutputFile"
} catch {
    Write-Error "Erreur lors de l'enregistrement du rapport : $_"
    exit 1
}

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Host "`nRÃ©sumÃ© de la priorisation :"
Write-Host "--------------------------------"
Write-Host "  AmÃ©liorations Ã©valuÃ©es : $($rankedImprovements.Count)"

$highPriorityCount = ($rankedImprovements | Where-Object { $_.PriorityScore -ge $improvementsData.Thresholds.HighPriorityThreshold }).Count
$mediumPriorityCount = ($rankedImprovements | Where-Object { $_.PriorityScore -ge $improvementsData.Thresholds.MediumPriorityThreshold -and $_.PriorityScore -lt $improvementsData.Thresholds.HighPriorityThreshold }).Count
$lowPriorityCount = ($rankedImprovements | Where-Object { $_.PriorityScore -lt $improvementsData.Thresholds.MediumPriorityThreshold }).Count

Write-Host "  AmÃ©liorations Ã  prioritÃ© Ã©levÃ©e : $highPriorityCount"
Write-Host "  AmÃ©liorations Ã  prioritÃ© moyenne : $mediumPriorityCount"
Write-Host "  AmÃ©liorations Ã  prioritÃ© basse : $lowPriorityCount"
