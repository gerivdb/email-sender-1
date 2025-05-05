# Script d'application de la matrice d'Ã©valuation des compÃ©tences

# ParamÃ¨tres
$ExpertiseLevelsPath = ".\development\data\planning\expertise-levels.md"
$SkillsListPath = ".\development\data\planning\skills-list-formatted.md"
$OutputPath = ".\development\data\planning\skills-evaluation.md"
$OutputPathHtml = ".\development\data\planning\skills-evaluation.html"

# Afficher les informations de dÃ©marrage
Write-Host "DÃ©marrage de l'application de la matrice d'Ã©valuation des compÃ©tences"
Write-Host "ParamÃ¨tres:"
Write-Host "  - Fichier des niveaux d'expertise: $ExpertiseLevelsPath"
Write-Host "  - Fichier des compÃ©tences: $SkillsListPath"
Write-Host "  - Fichier de sortie: $OutputPath"

# Validation des fichiers d'entrÃ©e
if (-not (Test-Path $ExpertiseLevelsPath)) {
    Write-Error "Fichier des niveaux d'expertise non trouvÃ©: $ExpertiseLevelsPath"
    exit 1
}

if (-not (Test-Path $SkillsListPath)) {
    Write-Error "Fichier des compÃ©tences non trouvÃ©: $SkillsListPath"
    exit 1
}

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
$outputDir = Split-Path -Path $OutputPath -Parent
if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path -Path $outputDir)) {
    Write-Host "CrÃ©ation du rÃ©pertoire de sortie: $outputDir"
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

# Lire le contenu des fichiers
$expertiseLevelsContent = Get-Content -Path $ExpertiseLevelsPath -Raw
$skillsListContent = Get-Content -Path $SkillsListPath -Raw

# Extraire les compÃ©tences
$skills = @()
$managerPattern = '(?ms)## <a name=''([^'']+)''></a>([^\n]+)\r?\n(.*?)(?=## <a name=|\z)'
$managerMatches = [regex]::Matches($skillsListContent, $managerPattern)

foreach ($managerMatch in $managerMatches) {
    $managerName = $managerMatch.Groups[2].Value.Trim()
    $managerContent = $managerMatch.Groups[3].Value

    $improvementPattern = '(?ms)### ([^\r\n]+)\r?\n(.*?)(?=###|\z)'
    $improvementMatches = [regex]::Matches($managerContent, $improvementPattern)

    foreach ($improvementMatch in $improvementMatches) {
        $improvementName = $improvementMatch.Groups[1].Value.Trim()
        $improvementContent = $improvementMatch.Groups[2].Value

        $tablePattern = '(?ms)\| CatÃ©gorie \| CompÃ©tence \| Niveau \| Justification \|\r?\n\|[^\r\n]+\|\r?\n((?:\|[^\r\n]+\|\r?\n)+)'
        $tableMatch = [regex]::Match($improvementContent, $tablePattern)

        if ($tableMatch.Success) {
            $tableContent = $tableMatch.Groups[1].Value

            $rowPattern = '\| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \|'
            $rowMatches = [regex]::Matches($tableContent, $rowPattern)

            foreach ($rowMatch in $rowMatches) {
                $category = $rowMatch.Groups[1].Value.Trim()
                $skillName = $rowMatch.Groups[2].Value.Trim()
                $level = $rowMatch.Groups[3].Value.Trim()
                $justification = $rowMatch.Groups[4].Value.Trim()

                $skill = [PSCustomObject]@{
                    Name          = $skillName
                    Category      = $category
                    Manager       = $managerName
                    Improvement   = $improvementName
                    Level         = $level
                    Justification = $justification
                }

                $skills += $skill
            }
        }
    }
}

Write-Host "Nombre de compÃ©tences extraites: $($skills.Count)"

# GÃ©nÃ©rer le rapport
$report = @"
# Rapport d'Ã‰valuation des CompÃ©tences

## Table des MatiÃ¨res
1. [MÃ©thodologie](#mÃ©thodologie)
2. [RÃ©sultats d'Ã‰valuation](#rÃ©sultats-dÃ©valuation)
3. [Distribution des Niveaux](#distribution-des-niveaux)
4. [Recommandations](#recommandations)

## MÃ©thodologie
L'Ã©valuation des compÃ©tences est basÃ©e sur une analyse dÃ©taillÃ©e de chaque compÃ©tence selon plusieurs critÃ¨res:
- ComplexitÃ© technique
- Niveau de supervision requis
- CapacitÃ© de rÃ©solution de problÃ¨mes
- Impact sur le projet

## RÃ©sultats d'Ã‰valuation
| CompÃ©tence | CatÃ©gorie | Manager | AmÃ©lioration | Niveau | Justification |
|------------|-----------|---------|--------------|--------|---------------|
"@

foreach ($skill in $skills) {
    $report += "| $($skill.Name) | $($skill.Category) | $($skill.Manager) | $($skill.Improvement) | $($skill.Level) | $($skill.Justification) |`r`n"
}

# Calculer la distribution des niveaux
$levelDistribution = @{
    'DÃ©butant'      = 0
    'IntermÃ©diaire' = 0
    'AvancÃ©'        = 0
    'Expert'        = 0
}

foreach ($skill in $skills) {
    switch ($skill.Level) {
        'DÃ©butant' { $levelDistribution['DÃ©butant']++ }
        'IntermÃ©diaire' { $levelDistribution['IntermÃ©diaire']++ }
        'AvancÃ©' { $levelDistribution['AvancÃ©']++ }
        'Expert' { $levelDistribution['Expert']++ }
    }
}

$report += @"

## Distribution des Niveaux
"@

if ($skills.Count -gt 0) {
    $report += @"
- DÃ©butant: $($levelDistribution['DÃ©butant']) compÃ©tences ($([math]::Round(($levelDistribution['DÃ©butant'] / $skills.Count) * 100, 1))%)
- IntermÃ©diaire: $($levelDistribution['IntermÃ©diaire']) compÃ©tences ($([math]::Round(($levelDistribution['IntermÃ©diaire'] / $skills.Count) * 100, 1))%)
- AvancÃ©: $($levelDistribution['AvancÃ©']) compÃ©tences ($([math]::Round(($levelDistribution['AvancÃ©'] / $skills.Count) * 100, 1))%)
- Expert: $($levelDistribution['Expert']) compÃ©tences ($([math]::Round(($levelDistribution['Expert'] / $skills.Count) * 100, 1))%)
"@
} else {
    $report += @"
- Aucune compÃ©tence Ã©valuÃ©e
"@
}

$report += @"

## Recommandations
BasÃ© sur l'Ã©valuation:
- Concentrer la formation sur les compÃ©tences de niveau DÃ©butant/IntermÃ©diaire
- Allouer les ressources seniors aux tÃ¢ches de niveau Expert
- Revoir les compÃ©tences avec des scores faibles pour une potentielle automatisation
"@

# Enregistrer le rapport
$report | Out-File -FilePath $OutputPath -Encoding ascii

# GÃ©nÃ©rer un rapport HTML
$htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Rapport d'Ã‰valuation des CompÃ©tences</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2 { color: #333; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
    </style>
</head>
<body>
    <h1>Rapport d'Ã‰valuation des CompÃ©tences</h1>

    <h2>MÃ©thodologie</h2>
    <p>L'Ã©valuation des compÃ©tences est basÃ©e sur une analyse dÃ©taillÃ©e de chaque compÃ©tence selon plusieurs critÃ¨res:</p>
    <ul>
        <li>ComplexitÃ© technique</li>
        <li>Niveau de supervision requis</li>
        <li>CapacitÃ© de rÃ©solution de problÃ¨mes</li>
        <li>Impact sur le projet</li>
    </ul>

    <h2>RÃ©sultats d'Ã‰valuation</h2>
    <table>
        <tr>
            <th>CompÃ©tence</th>
            <th>CatÃ©gorie</th>
            <th>Manager</th>
            <th>AmÃ©lioration</th>
            <th>Niveau</th>
            <th>Justification</th>
        </tr>
"@

foreach ($skill in $skills) {
    $htmlReport += @"
        <tr>
            <td>$($skill.Name)</td>
            <td>$($skill.Category)</td>
            <td>$($skill.Manager)</td>
            <td>$($skill.Improvement)</td>
            <td>$($skill.Level)</td>
            <td>$($skill.Justification)</td>
        </tr>
"@
}

$htmlReport += @"
    </table>

    <h2>Distribution des Niveaux</h2>
    <ul>
        <li>DÃ©butant: $($levelDistribution['DÃ©butant']) compÃ©tences ($([math]::Round(($levelDistribution['DÃ©butant'] / $skills.Count) * 100, 1))%)</li>
        <li>IntermÃ©diaire: $($levelDistribution['IntermÃ©diaire']) compÃ©tences ($([math]::Round(($levelDistribution['IntermÃ©diaire'] / $skills.Count) * 100, 1))%)</li>
        <li>AvancÃ©: $($levelDistribution['AvancÃ©']) compÃ©tences ($([math]::Round(($levelDistribution['AvancÃ©'] / $skills.Count) * 100, 1))%)</li>
        <li>Expert: $($levelDistribution['Expert']) compÃ©tences ($([math]::Round(($levelDistribution['Expert'] / $skills.Count) * 100, 1))%)</li>
    </ul>

    <h2>Recommandations</h2>
    <p>BasÃ© sur l'Ã©valuation:</p>
    <ul>
        <li>Concentrer la formation sur les compÃ©tences de niveau DÃ©butant/IntermÃ©diaire</li>
        <li>Allouer les ressources seniors aux tÃ¢ches de niveau Expert</li>
        <li>Revoir les compÃ©tences avec des scores faibles pour une potentielle automatisation</li>
    </ul>
</body>
</html>
"@

# Enregistrer le rapport HTML
$htmlReport | Out-File -FilePath $OutputPathHtml -Encoding utf8

Write-Host "Rapport d'Ã©valuation gÃ©nÃ©rÃ© avec succÃ¨s Ã : $OutputPath"
Write-Host "Rapport HTML gÃ©nÃ©rÃ© avec succÃ¨s Ã : $OutputPathHtml"

# Afficher un rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ© de l'Ã©valuation des compÃ©tences :"
Write-Host "---------------------------------------------------"
Write-Host "  Nombre total de compÃ©tences Ã©valuÃ©es : $($skills.Count)"

if ($skills.Count -gt 0) {
    Write-Host "  Distribution des niveaux d'expertise :"
    Write-Host "    - DÃ©butant      : $($levelDistribution['DÃ©butant']) ($([math]::Round(($levelDistribution['DÃ©butant'] / $skills.Count) * 100, 1))%)"
    Write-Host "    - IntermÃ©diaire : $($levelDistribution['IntermÃ©diaire']) ($([math]::Round(($levelDistribution['IntermÃ©diaire'] / $skills.Count) * 100, 1))%)"
    Write-Host "    - AvancÃ©        : $($levelDistribution['AvancÃ©']) ($([math]::Round(($levelDistribution['AvancÃ©'] / $skills.Count) * 100, 1))%)"
    Write-Host "    - Expert        : $($levelDistribution['Expert']) ($([math]::Round(($levelDistribution['Expert'] / $skills.Count) * 100, 1))%)"
} else {
    Write-Host "  Aucune compÃ©tence Ã©valuÃ©e"
}

Write-Host "  Rapport gÃ©nÃ©rÃ© Ã  : $OutputPath"
