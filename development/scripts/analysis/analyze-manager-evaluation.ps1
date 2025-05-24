<#
.SYNOPSIS
    Analyse les rÃ©sultats de l'Ã©valuation des gestionnaires par rapport aux piliers.

.DESCRIPTION
    Ce script analyse les rÃ©sultats de l'Ã©valuation des gestionnaires par rapport aux piliers
    de programmation. Il compile les scores d'Ã©valuation, identifie les points forts et points
    faibles, analyse les Ã©carts par rapport aux piliers et Ã©value l'impact des lacunes identifiÃ©es.

.PARAMETER InputFile
    Chemin vers le fichier JSON contenant les rÃ©sultats de l'Ã©valuation des gestionnaires.

.PARAMETER OutputFile
    Chemin vers le fichier de sortie pour le rapport d'analyse.

.PARAMETER Format
    Format du rapport de sortie. Les valeurs possibles sont : JSON, CSV, HTML, Markdown.
    Par dÃ©faut : Markdown

.EXAMPLE
    .\analyze-manager-evaluation.ps1 -InputFile "data\manager-evaluation.json" -OutputFile "reports\manager-analysis.md"
    GÃ©nÃ¨re un rapport d'analyse au format Markdown.

.NOTES
    Auteur: Analysis Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-05
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

# Charger les donnÃ©es d'Ã©valuation des gestionnaires
try {
    $evaluationData = Get-Content -Path $InputFile -Raw | ConvertFrom-Json
} catch {
    Write-Error "Erreur lors du chargement du fichier d'entrÃ©e : $_"
    exit 1
}

# Fonction pour compiler les scores d'Ã©valuation par gestionnaire
function New-EvaluationScores {
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

        # Calculer le score total et les scores par critÃ¨re
        foreach ($criterion in $manager.Scores.PSObject.Properties) {
            $criteriaScores[$criterion.Name] = $criterion.Value
            $totalScore += $criterion.Value
            $criteriaCount++
        }

        # Calculer le score moyen
        $averageScore = if ($criteriaCount -gt 0) { $totalScore / $criteriaCount } else { 0 }

        # CrÃ©er un objet avec les scores compilÃ©s
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

    # Trier les gestionnaires par score moyen (dÃ©croissant)
    $compiledScores = $compiledScores | Sort-Object -Property AverageScore -Descending

    return $compiledScores
}

# Fonction pour identifier les points forts et points faibles
function Find-StrengthsWeaknesses {
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

        # Identifier les critÃ¨res avec des scores Ã©levÃ©s (points forts)
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

        # Identifier les critÃ¨res avec des scores faibles (points faibles)
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

        # CrÃ©er un objet avec les points forts et points faibles
        $strengthWeakness = [PSCustomObject]@{
            Name = $manager.Name
            Strengths = $strengths
            Weaknesses = $weaknesses
        }

        $strengthsWeaknesses += $strengthWeakness
    }

    return $strengthsWeaknesses
}

# Fonction pour analyser les Ã©carts par rapport aux piliers
function Test-PillarGaps {
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

        # DÃ©terminer l'Ã©cart par rapport Ã  la couverture cible
        $targetCoverage = $EvaluationData.Thresholds.TargetPillarCoverage
        $gap = $targetCoverage - $averageCoverage

        # CrÃ©er un objet avec les Ã©carts par rapport au pilier
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

    # Trier les piliers par Ã©cart (dÃ©croissant)
    $pillarGaps = $pillarGaps | Sort-Object -Property Gap -Descending

    return $pillarGaps
}

# Fonction pour Ã©valuer l'impact des lacunes identifiÃ©es
function Test-GapImpact {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$PillarGaps,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$EvaluationData
    )

    $gapImpacts = @()

    foreach ($pillarGap in $PillarGaps) {
        # DÃ©terminer le niveau d'impact en fonction de l'Ã©cart
        $impactLevel = "Faible"
        if ($pillarGap.Gap -ge $EvaluationData.Thresholds.HighImpactThreshold) {
            $impactLevel = "Ã‰levÃ©"
        } elseif ($pillarGap.Gap -ge $EvaluationData.Thresholds.MediumImpactThreshold) {
            $impactLevel = "Moyen"
        }

        # DÃ©terminer les consÃ©quences potentielles
        $consequences = @()
        foreach ($consequence in $EvaluationData.ImpactConsequences.$impactLevel) {
            $consequences += $consequence
        }

        # CrÃ©er un objet avec l'impact des lacunes
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

# Analyser les rÃ©sultats de l'Ã©valuation
$compiledScores = New-EvaluationScores -EvaluationData $evaluationData
$strengthsWeaknesses = Find-StrengthsWeaknesses -CompiledScores $compiledScores -EvaluationData $evaluationData
$pillarGaps = Test-PillarGaps -CompiledScores $compiledScores -EvaluationData $evaluationData
$gapImpacts = Test-GapImpact -PillarGaps $pillarGaps -EvaluationData $evaluationData

# CrÃ©er le rapport d'analyse
$analysisReport = [PSCustomObject]@{
    GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    CompiledScores = $compiledScores
    StrengthsWeaknesses = $strengthsWeaknesses
    PillarGaps = $pillarGaps
    GapImpacts = $gapImpacts
}

# Fonction pour gÃ©nÃ©rer le rapport au format Markdown
function New-MarkdownReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Report
    )

    $markdown = "# Rapport d'Analyse des Gestionnaires`n`n"
    $markdown += "Date de gÃ©nÃ©ration : $($Report.GeneratedAt)`n`n"
    
    # Ajouter les scores compilÃ©s
    $markdown += "## Scores d'Ã‰valuation des Gestionnaires`n`n"
    $markdown += "| Gestionnaire | Score Moyen | CatÃ©gorie |`n"
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
            $markdown += "| CritÃ¨re | Score |`n"
            $markdown += "|---------|-------|`n"
            
            foreach ($strength in $manager.Strengths) {
                $markdown += "| $($strength.Criterion) | $($strength.Score) |`n"
            }
        } else {
            $markdown += "Aucun point fort identifiÃ©.`n"
        }
        
        $markdown += "`n#### Points Faibles`n`n"
        if ($manager.Weaknesses.Count -gt 0) {
            $markdown += "| CritÃ¨re | Score |`n"
            $markdown += "|---------|-------|`n"
            
            foreach ($weakness in $manager.Weaknesses) {
                $markdown += "| $($weakness.Criterion) | $($weakness.Score) |`n"
            }
        } else {
            $markdown += "Aucun point faible identifiÃ©.`n"
        }
        
        $markdown += "`n"
    }
    
    # Ajouter les Ã©carts par rapport aux piliers
    $markdown += "## Ã‰carts par Rapport aux Piliers`n`n"
    $markdown += "| Pilier | Couverture Moyenne | Couverture Cible | Ã‰cart |`n"
    $markdown += "|--------|-------------------|------------------|-------|`n"
    
    foreach ($pillarGap in $Report.PillarGaps) {
        $markdown += "| $($pillarGap.PillarName) | $($pillarGap.AverageCoverage)% | $($pillarGap.TargetCoverage)% | $($pillarGap.Gap)% |`n"
    }
    
    # Ajouter l'impact des lacunes
    $markdown += "`n## Impact des Lacunes IdentifiÃ©es`n`n"
    
    foreach ($gapImpact in $Report.GapImpacts) {
        $markdown += "### $($gapImpact.PillarName) (Impact : $($gapImpact.ImpactLevel))`n`n"
        
        $markdown += "#### ConsÃ©quences Potentielles`n`n"
        foreach ($consequence in $gapImpact.Consequences) {
            $markdown += "- $consequence`n"
        }
        
        $markdown += "`n#### Actions RecommandÃ©es`n`n"
        foreach ($action in $gapImpact.RecommendedActions) {
            $markdown += "- $action`n"
        }
        
        $markdown += "`n"
    }
    
    # Ajouter un rÃ©sumÃ©
    $markdown += "## RÃ©sumÃ©`n`n"
    
    $highImpactCount = ($Report.GapImpacts | Where-Object { $_.ImpactLevel -eq "Ã‰levÃ©" }).Count
    $mediumImpactCount = ($Report.GapImpacts | Where-Object { $_.ImpactLevel -eq "Moyen" }).Count
    $lowImpactCount = ($Report.GapImpacts | Where-Object { $_.ImpactLevel -eq "Faible" }).Count
    
    $markdown += "- Nombre de gestionnaires Ã©valuÃ©s : $($Report.CompiledScores.Count)`n"
    $markdown += "- Nombre de piliers avec un impact Ã©levÃ© : $highImpactCount`n"
    $markdown += "- Nombre de piliers avec un impact moyen : $mediumImpactCount`n"
    $markdown += "- Nombre de piliers avec un impact faible : $lowImpactCount`n"
    
    return $markdown
}

# Fonction pour gÃ©nÃ©rer le rapport au format HTML
function New-HtmlReport {
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
    <p>Date de gÃ©nÃ©ration : $($Report.GeneratedAt)</p>
    
    <h2>Scores d'Ã‰valuation des Gestionnaires</h2>
    <table>
        <tr>
            <th>Gestionnaire</th>
            <th>Score Moyen</th>
            <th>CatÃ©gorie</th>
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
            <th>CritÃ¨re</th>
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
    <p>Aucun point fort identifiÃ©.</p>
"@
        }
        
        $html += @"
    <h4>Points Faibles</h4>
"@
        if ($manager.Weaknesses.Count -gt 0) {
            $html += @"
    <table>
        <tr>
            <th>CritÃ¨re</th>
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
    <p>Aucun point faible identifiÃ©.</p>
"@
        }
    }

    $html += @"
    <h2>Ã‰carts par Rapport aux Piliers</h2>
    <table>
        <tr>
            <th>Pilier</th>
            <th>Couverture Moyenne</th>
            <th>Couverture Cible</th>
            <th>Ã‰cart</th>
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
    
    <h2>Impact des Lacunes IdentifiÃ©es</h2>
"@

    foreach ($gapImpact in $Report.GapImpacts) {
        $impactClass = "impact-low"
        if ($gapImpact.ImpactLevel -eq "Ã‰levÃ©") {
            $impactClass = "impact-high"
        } elseif ($gapImpact.ImpactLevel -eq "Moyen") {
            $impactClass = "impact-medium"
        }
        
        $html += @"
    <div class="$impactClass" style="padding: 10px; margin-bottom: 20px; border-radius: 5px;">
        <h3>$($gapImpact.PillarName) (Impact : $($gapImpact.ImpactLevel))</h3>
        
        <h4>ConsÃ©quences Potentielles</h4>
        <ul>
"@
        foreach ($consequence in $gapImpact.Consequences) {
            $html += @"
            <li>$consequence</li>
"@
        }
        
        $html += @"
        </ul>
        
        <h4>Actions RecommandÃ©es</h4>
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

    $highImpactCount = ($Report.GapImpacts | Where-Object { $_.ImpactLevel -eq "Ã‰levÃ©" }).Count
    $mediumImpactCount = ($Report.GapImpacts | Where-Object { $_.ImpactLevel -eq "Moyen" }).Count
    $lowImpactCount = ($Report.GapImpacts | Where-Object { $_.ImpactLevel -eq "Faible" }).Count

    $html += @"
    <div class="summary">
        <h2>RÃ©sumÃ©</h2>
        <ul>
            <li>Nombre de gestionnaires Ã©valuÃ©s : $($Report.CompiledScores.Count)</li>
            <li>Nombre de piliers avec un impact Ã©levÃ© : $highImpactCount</li>
            <li>Nombre de piliers avec un impact moyen : $mediumImpactCount</li>
            <li>Nombre de piliers avec un impact faible : $lowImpactCount</li>
        </ul>
    </div>
</body>
</html>
"@

    return $html
}

# Fonction pour gÃ©nÃ©rer le rapport au format CSV
function New-CsvReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Report
    )

    $csv = "Gestionnaire,Score Moyen,CatÃ©gorie`n"
    
    foreach ($manager in $Report.CompiledScores) {
        $csv += "$($manager.Name),$($manager.AverageScore),$($manager.Category)`n"
    }
    
    $csv += "`nPilier,Couverture Moyenne,Couverture Cible,Ã‰cart,Impact`n"
    
    foreach ($pillarGap in $Report.PillarGaps) {
        $impact = ($Report.GapImpacts | Where-Object { $_.PillarName -eq $pillarGap.PillarName }).ImpactLevel
        $csv += "$($pillarGap.PillarName),$($pillarGap.AverageCoverage),$($pillarGap.TargetCoverage),$($pillarGap.Gap),$impact`n"
    }
    
    return $csv
}

# GÃ©nÃ©rer le rapport dans le format spÃ©cifiÃ©
switch ($Format) {
    "Markdown" {
        $reportContent = New-MarkdownReport -Report $analysisReport
    }
    "HTML" {
        $reportContent = New-HtmlReport -Report $analysisReport
    }
    "CSV" {
        $reportContent = New-CsvReport -Report $analysisReport
    }
    "JSON" {
        $reportContent = $analysisReport | ConvertTo-Json -Depth 10
    }
}

# Enregistrer le rapport
try {
    $reportContent | Out-File -FilePath $OutputFile -Encoding UTF8
    Write-Host "Rapport d'analyse gÃ©nÃ©rÃ© avec succÃ¨s : $OutputFile"
} catch {
    Write-Error "Erreur lors de l'enregistrement du rapport : $_"
    exit 1
}

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Host "`nRÃ©sumÃ© de l'analyse :"
Write-Host "--------------------------------"
Write-Host "  Gestionnaires Ã©valuÃ©s : $($compiledScores.Count)"

$highImpactCount = ($gapImpacts | Where-Object { $_.ImpactLevel -eq "Ã‰levÃ©" }).Count
$mediumImpactCount = ($gapImpacts | Where-Object { $_.ImpactLevel -eq "Moyen" }).Count
$lowImpactCount = ($gapImpacts | Where-Object { $_.ImpactLevel -eq "Faible" }).Count

Write-Host "  Piliers avec impact Ã©levÃ© : $highImpactCount"
Write-Host "  Piliers avec impact moyen : $mediumImpactCount"
Write-Host "  Piliers avec impact faible : $lowImpactCount"


