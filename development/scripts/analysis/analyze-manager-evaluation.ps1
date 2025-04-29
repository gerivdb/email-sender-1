<#
.SYNOPSIS
    Analyse les résultats de l'évaluation des gestionnaires par rapport aux piliers.

.DESCRIPTION
    Ce script analyse les résultats de l'évaluation des gestionnaires par rapport aux piliers
    de programmation. Il compile les scores d'évaluation, identifie les points forts et points
    faibles, analyse les écarts par rapport aux piliers et évalue l'impact des lacunes identifiées.

.PARAMETER InputFile
    Chemin vers le fichier JSON contenant les résultats de l'évaluation des gestionnaires.

.PARAMETER OutputFile
    Chemin vers le fichier de sortie pour le rapport d'analyse.

.PARAMETER Format
    Format du rapport de sortie. Les valeurs possibles sont : JSON, CSV, HTML, Markdown.
    Par défaut : Markdown

.EXAMPLE
    .\analyze-manager-evaluation.ps1 -InputFile "data\manager-evaluation.json" -OutputFile "reports\manager-analysis.md"
    Génère un rapport d'analyse au format Markdown.

.NOTES
    Auteur: Analysis Team
    Version: 1.0
    Date de création: 2025-05-05
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

# Charger les données d'évaluation des gestionnaires
try {
    $evaluationData = Get-Content -Path $InputFile -Raw | ConvertFrom-Json
} catch {
    Write-Error "Erreur lors du chargement du fichier d'entrée : $_"
    exit 1
}

# Fonction pour compiler les scores d'évaluation par gestionnaire
function Compile-EvaluationScores {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$EvaluationData
    )

    $compiledScores = @()

    foreach ($manager in $EvaluationData.Managers) {
        $totalScore = 0
        $criteriaCount = 0
        $criteriaScores = @{}

        # Calculer le score total et les scores par critère
        foreach ($criterion in $manager.Scores.PSObject.Properties) {
            $criteriaScores[$criterion.Name] = $criterion.Value
            $totalScore += $criterion.Value
            $criteriaCount++
        }

        # Calculer le score moyen
        $averageScore = if ($criteriaCount -gt 0) { $totalScore / $criteriaCount } else { 0 }

        # Créer un objet avec les scores compilés
        $compiledScore = [PSCustomObject]@{
            Name = $manager.Name
            Description = $manager.Description
            Category = $manager.Category
            TotalScore = $totalScore
            AverageScore = [math]::Round($averageScore, 2)
            CriteriaScores = $criteriaScores
            Strengths = $manager.Strengths
            Weaknesses = $manager.Weaknesses
            PillarCoverage = $manager.PillarCoverage
        }

        $compiledScores += $compiledScore
    }

    # Trier les gestionnaires par score moyen (décroissant)
    $compiledScores = $compiledScores | Sort-Object -Property AverageScore -Descending

    return $compiledScores
}

# Fonction pour identifier les points forts et points faibles
function Identify-StrengthsWeaknesses {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$CompiledScores,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$EvaluationData
    )

    $strengthsWeaknesses = @()

    foreach ($manager in $CompiledScores) {
        $strengths = @()
        $weaknesses = @()

        # Identifier les critères avec des scores élevés (points forts)
        foreach ($criterion in $manager.CriteriaScores.Keys) {
            $score = $manager.CriteriaScores[$criterion]
            $threshold = $EvaluationData.Thresholds.StrengthThreshold

            if ($score -ge $threshold) {
                $strengths += [PSCustomObject]@{
                    Criterion = $criterion
                    Score = $score
                    Description = $EvaluationData.Criteria.$criterion.Description
                }
            }
        }

        # Identifier les critères avec des scores faibles (points faibles)
        foreach ($criterion in $manager.CriteriaScores.Keys) {
            $score = $manager.CriteriaScores[$criterion]
            $threshold = $EvaluationData.Thresholds.WeaknessThreshold

            if ($score -le $threshold) {
                $weaknesses += [PSCustomObject]@{
                    Criterion = $criterion
                    Score = $score
                    Description = $EvaluationData.Criteria.$criterion.Description
                }
            }
        }

        # Trier les points forts et points faibles par score
        $strengths = $strengths | Sort-Object -Property Score -Descending
        $weaknesses = $weaknesses | Sort-Object -Property Score

        # Créer un objet avec les points forts et points faibles
        $strengthWeakness = [PSCustomObject]@{
            Name = $manager.Name
            Strengths = $strengths
            Weaknesses = $weaknesses
        }

        $strengthsWeaknesses += $strengthWeakness
    }

    return $strengthsWeaknesses
}

# Fonction pour analyser les écarts par rapport aux piliers
function Analyze-PillarGaps {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$CompiledScores,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$EvaluationData
    )

    $pillarGaps = @()

    foreach ($pillar in $EvaluationData.Pillars) {
        $pillarName = $pillar.Name
        $pillarCoverage = @()
        $totalCoverage = 0
        $managerCount = 0

        # Calculer la couverture du pilier pour chaque gestionnaire
        foreach ($manager in $CompiledScores) {
            if ($manager.PillarCoverage.PSObject.Properties.Name -contains $pillarName) {
                $coverage = $manager.PillarCoverage.$pillarName
                $pillarCoverage += [PSCustomObject]@{
                    ManagerName = $manager.Name
                    Coverage = $coverage
                }
                $totalCoverage += $coverage
                $managerCount++
            }
        }

        # Calculer la couverture moyenne du pilier
        $averageCoverage = if ($managerCount -gt 0) { $totalCoverage / $managerCount } else { 0 }

        # Déterminer l'écart par rapport à la couverture cible
        $targetCoverage = $EvaluationData.Thresholds.TargetPillarCoverage
        $gap = $targetCoverage - $averageCoverage

        # Créer un objet avec les écarts par rapport au pilier
        $pillarGap = [PSCustomObject]@{
            PillarName = $pillarName
            PillarDescription = $pillar.Description
            AverageCoverage = [math]::Round($averageCoverage, 2)
            TargetCoverage = $targetCoverage
            Gap = [math]::Round($gap, 2)
            ManagerCoverage = $pillarCoverage | Sort-Object -Property Coverage -Descending
        }

        $pillarGaps += $pillarGap
    }

    # Trier les piliers par écart (décroissant)
    $pillarGaps = $pillarGaps | Sort-Object -Property Gap -Descending

    return $pillarGaps
}

# Fonction pour évaluer l'impact des lacunes identifiées
function Evaluate-GapImpact {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$PillarGaps,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$EvaluationData
    )

    $gapImpacts = @()

    foreach ($pillarGap in $PillarGaps) {
        # Déterminer le niveau d'impact en fonction de l'écart
        $impactLevel = "Faible"
        if ($pillarGap.Gap -ge $EvaluationData.Thresholds.HighImpactThreshold) {
            $impactLevel = "Élevé"
        } elseif ($pillarGap.Gap -ge $EvaluationData.Thresholds.MediumImpactThreshold) {
            $impactLevel = "Moyen"
        }

        # Déterminer les conséquences potentielles
        $consequences = @()
        foreach ($consequence in $EvaluationData.ImpactConsequences.$impactLevel) {
            $consequences += $consequence
        }

        # Créer un objet avec l'impact des lacunes
        $gapImpact = [PSCustomObject]@{
            PillarName = $pillarGap.PillarName
            Gap = $pillarGap.Gap
            ImpactLevel = $impactLevel
            Consequences = $consequences
            RecommendedActions = $EvaluationData.RecommendedActions.$impactLevel
        }

        $gapImpacts += $gapImpact
    }

    return $gapImpacts
}

# Analyser les résultats de l'évaluation
$compiledScores = Compile-EvaluationScores -EvaluationData $evaluationData
$strengthsWeaknesses = Identify-StrengthsWeaknesses -CompiledScores $compiledScores -EvaluationData $evaluationData
$pillarGaps = Analyze-PillarGaps -CompiledScores $compiledScores -EvaluationData $evaluationData
$gapImpacts = Evaluate-GapImpact -PillarGaps $pillarGaps -EvaluationData $evaluationData

# Créer le rapport d'analyse
$analysisReport = [PSCustomObject]@{
    GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    CompiledScores = $compiledScores
    StrengthsWeaknesses = $strengthsWeaknesses
    PillarGaps = $pillarGaps
    GapImpacts = $gapImpacts
}

# Fonction pour générer le rapport au format Markdown
function Generate-MarkdownReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Report
    )

    $markdown = "# Rapport d'Analyse des Gestionnaires`n`n"
    $markdown += "Date de génération : $($Report.GeneratedAt)`n`n"
    
    # Ajouter les scores compilés
    $markdown += "## Scores d'Évaluation des Gestionnaires`n`n"
    $markdown += "| Gestionnaire | Score Moyen | Catégorie |`n"
    $markdown += "|--------------|-------------|-----------|`n"
    
    foreach ($manager in $Report.CompiledScores) {
        $markdown += "| $($manager.Name) | $($manager.AverageScore) | $($manager.Category) |`n"
    }
    
    # Ajouter les points forts et points faibles
    $markdown += "`n## Points Forts et Points Faibles`n`n"
    
    foreach ($manager in $Report.StrengthsWeaknesses) {
        $markdown += "### $($manager.Name)`n`n"
        
        $markdown += "#### Points Forts`n`n"
        if ($manager.Strengths.Count -gt 0) {
            $markdown += "| Critère | Score |`n"
            $markdown += "|---------|-------|`n"
            
            foreach ($strength in $manager.Strengths) {
                $markdown += "| $($strength.Criterion) | $($strength.Score) |`n"
            }
        } else {
            $markdown += "Aucun point fort identifié.`n"
        }
        
        $markdown += "`n#### Points Faibles`n`n"
        if ($manager.Weaknesses.Count -gt 0) {
            $markdown += "| Critère | Score |`n"
            $markdown += "|---------|-------|`n"
            
            foreach ($weakness in $manager.Weaknesses) {
                $markdown += "| $($weakness.Criterion) | $($weakness.Score) |`n"
            }
        } else {
            $markdown += "Aucun point faible identifié.`n"
        }
        
        $markdown += "`n"
    }
    
    # Ajouter les écarts par rapport aux piliers
    $markdown += "## Écarts par Rapport aux Piliers`n`n"
    $markdown += "| Pilier | Couverture Moyenne | Couverture Cible | Écart |`n"
    $markdown += "|--------|-------------------|------------------|-------|`n"
    
    foreach ($pillarGap in $Report.PillarGaps) {
        $markdown += "| $($pillarGap.PillarName) | $($pillarGap.AverageCoverage)% | $($pillarGap.TargetCoverage)% | $($pillarGap.Gap)% |`n"
    }
    
    # Ajouter l'impact des lacunes
    $markdown += "`n## Impact des Lacunes Identifiées`n`n"
    
    foreach ($gapImpact in $Report.GapImpacts) {
        $markdown += "### $($gapImpact.PillarName) (Impact : $($gapImpact.ImpactLevel))`n`n"
        
        $markdown += "#### Conséquences Potentielles`n`n"
        foreach ($consequence in $gapImpact.Consequences) {
            $markdown += "- $consequence`n"
        }
        
        $markdown += "`n#### Actions Recommandées`n`n"
        foreach ($action in $gapImpact.RecommendedActions) {
            $markdown += "- $action`n"
        }
        
        $markdown += "`n"
    }
    
    # Ajouter un résumé
    $markdown += "## Résumé`n`n"
    
    $highImpactCount = ($Report.GapImpacts | Where-Object { $_.ImpactLevel -eq "Élevé" }).Count
    $mediumImpactCount = ($Report.GapImpacts | Where-Object { $_.ImpactLevel -eq "Moyen" }).Count
    $lowImpactCount = ($Report.GapImpacts | Where-Object { $_.ImpactLevel -eq "Faible" }).Count
    
    $markdown += "- Nombre de gestionnaires évalués : $($Report.CompiledScores.Count)`n"
    $markdown += "- Nombre de piliers avec un impact élevé : $highImpactCount`n"
    $markdown += "- Nombre de piliers avec un impact moyen : $mediumImpactCount`n"
    $markdown += "- Nombre de piliers avec un impact faible : $lowImpactCount`n"
    
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
    <title>Rapport d'Analyse des Gestionnaires</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2, h3, h4 { color: #333; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .impact-high { background-color: #ffcccc; }
        .impact-medium { background-color: #ffffcc; }
        .impact-low { background-color: #ccffcc; }
        .summary { margin-top: 30px; padding: 15px; background-color: #f0f0f0; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>Rapport d'Analyse des Gestionnaires</h1>
    <p>Date de génération : $($Report.GeneratedAt)</p>
    
    <h2>Scores d'Évaluation des Gestionnaires</h2>
    <table>
        <tr>
            <th>Gestionnaire</th>
            <th>Score Moyen</th>
            <th>Catégorie</th>
        </tr>
"@

    foreach ($manager in $Report.CompiledScores) {
        $html += @"
        <tr>
            <td>$($manager.Name)</td>
            <td>$($manager.AverageScore)</td>
            <td>$($manager.Category)</td>
        </tr>
"@
    }

    $html += @"
    </table>
    
    <h2>Points Forts et Points Faibles</h2>
"@

    foreach ($manager in $Report.StrengthsWeaknesses) {
        $html += @"
    <h3>$($manager.Name)</h3>
    
    <h4>Points Forts</h4>
"@
        if ($manager.Strengths.Count -gt 0) {
            $html += @"
    <table>
        <tr>
            <th>Critère</th>
            <th>Score</th>
        </tr>
"@
            foreach ($strength in $manager.Strengths) {
                $html += @"
        <tr>
            <td>$($strength.Criterion)</td>
            <td>$($strength.Score)</td>
        </tr>
"@
            }
            $html += @"
    </table>
"@
        } else {
            $html += @"
    <p>Aucun point fort identifié.</p>
"@
        }
        
        $html += @"
    <h4>Points Faibles</h4>
"@
        if ($manager.Weaknesses.Count -gt 0) {
            $html += @"
    <table>
        <tr>
            <th>Critère</th>
            <th>Score</th>
        </tr>
"@
            foreach ($weakness in $manager.Weaknesses) {
                $html += @"
        <tr>
            <td>$($weakness.Criterion)</td>
            <td>$($weakness.Score)</td>
        </tr>
"@
            }
            $html += @"
    </table>
"@
        } else {
            $html += @"
    <p>Aucun point faible identifié.</p>
"@
        }
    }

    $html += @"
    <h2>Écarts par Rapport aux Piliers</h2>
    <table>
        <tr>
            <th>Pilier</th>
            <th>Couverture Moyenne</th>
            <th>Couverture Cible</th>
            <th>Écart</th>
        </tr>
"@

    foreach ($pillarGap in $Report.PillarGaps) {
        $html += @"
        <tr>
            <td>$($pillarGap.PillarName)</td>
            <td>$($pillarGap.AverageCoverage)%</td>
            <td>$($pillarGap.TargetCoverage)%</td>
            <td>$($pillarGap.Gap)%</td>
        </tr>
"@
    }

    $html += @"
    </table>
    
    <h2>Impact des Lacunes Identifiées</h2>
"@

    foreach ($gapImpact in $Report.GapImpacts) {
        $impactClass = "impact-low"
        if ($gapImpact.ImpactLevel -eq "Élevé") {
            $impactClass = "impact-high"
        } elseif ($gapImpact.ImpactLevel -eq "Moyen") {
            $impactClass = "impact-medium"
        }
        
        $html += @"
    <div class="$impactClass" style="padding: 10px; margin-bottom: 20px; border-radius: 5px;">
        <h3>$($gapImpact.PillarName) (Impact : $($gapImpact.ImpactLevel))</h3>
        
        <h4>Conséquences Potentielles</h4>
        <ul>
"@
        foreach ($consequence in $gapImpact.Consequences) {
            $html += @"
            <li>$consequence</li>
"@
        }
        
        $html += @"
        </ul>
        
        <h4>Actions Recommandées</h4>
        <ul>
"@
        foreach ($action in $gapImpact.RecommendedActions) {
            $html += @"
            <li>$action</li>
"@
        }
        
        $html += @"
        </ul>
    </div>
"@
    }

    $highImpactCount = ($Report.GapImpacts | Where-Object { $_.ImpactLevel -eq "Élevé" }).Count
    $mediumImpactCount = ($Report.GapImpacts | Where-Object { $_.ImpactLevel -eq "Moyen" }).Count
    $lowImpactCount = ($Report.GapImpacts | Where-Object { $_.ImpactLevel -eq "Faible" }).Count

    $html += @"
    <div class="summary">
        <h2>Résumé</h2>
        <ul>
            <li>Nombre de gestionnaires évalués : $($Report.CompiledScores.Count)</li>
            <li>Nombre de piliers avec un impact élevé : $highImpactCount</li>
            <li>Nombre de piliers avec un impact moyen : $mediumImpactCount</li>
            <li>Nombre de piliers avec un impact faible : $lowImpactCount</li>
        </ul>
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

    $csv = "Gestionnaire,Score Moyen,Catégorie`n"
    
    foreach ($manager in $Report.CompiledScores) {
        $csv += "$($manager.Name),$($manager.AverageScore),$($manager.Category)`n"
    }
    
    $csv += "`nPilier,Couverture Moyenne,Couverture Cible,Écart,Impact`n"
    
    foreach ($pillarGap in $Report.PillarGaps) {
        $impact = ($Report.GapImpacts | Where-Object { $_.PillarName -eq $pillarGap.PillarName }).ImpactLevel
        $csv += "$($pillarGap.PillarName),$($pillarGap.AverageCoverage),$($pillarGap.TargetCoverage),$($pillarGap.Gap),$impact`n"
    }
    
    return $csv
}

# Générer le rapport dans le format spécifié
switch ($Format) {
    "Markdown" {
        $reportContent = Generate-MarkdownReport -Report $analysisReport
    }
    "HTML" {
        $reportContent = Generate-HtmlReport -Report $analysisReport
    }
    "CSV" {
        $reportContent = Generate-CsvReport -Report $analysisReport
    }
    "JSON" {
        $reportContent = $analysisReport | ConvertTo-Json -Depth 10
    }
}

# Enregistrer le rapport
try {
    $reportContent | Out-File -FilePath $OutputFile -Encoding UTF8
    Write-Host "Rapport d'analyse généré avec succès : $OutputFile"
} catch {
    Write-Error "Erreur lors de l'enregistrement du rapport : $_"
    exit 1
}

# Afficher un résumé des résultats
Write-Host "`nRésumé de l'analyse :"
Write-Host "--------------------------------"
Write-Host "  Gestionnaires évalués : $($compiledScores.Count)"

$highImpactCount = ($gapImpacts | Where-Object { $_.ImpactLevel -eq "Élevé" }).Count
$mediumImpactCount = ($gapImpacts | Where-Object { $_.ImpactLevel -eq "Moyen" }).Count
$lowImpactCount = ($gapImpacts | Where-Object { $_.ImpactLevel -eq "Faible" }).Count

Write-Host "  Piliers avec impact élevé : $highImpactCount"
Write-Host "  Piliers avec impact moyen : $mediumImpactCount"
Write-Host "  Piliers avec impact faible : $lowImpactCount"
