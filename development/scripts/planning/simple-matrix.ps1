# Script d'application de la matrice d'évaluation des compétences

# Paramètres
$ExpertiseLevelsPath = ".\development\data\planning\expertise-levels.md"
$SkillsListPath = ".\development\data\planning\skills-list-formatted.md"
$OutputPath = ".\development\data\planning\skills-evaluation.md"
$OutputPathHtml = ".\development\data\planning\skills-evaluation.html"

# Afficher les informations de démarrage
Write-Host "Démarrage de l'application de la matrice d'évaluation des compétences"
Write-Host "Paramètres:"
Write-Host "  - Fichier des niveaux d'expertise: $ExpertiseLevelsPath"
Write-Host "  - Fichier des compétences: $SkillsListPath"
Write-Host "  - Fichier de sortie: $OutputPath"

# Validation des fichiers d'entrée
if (-not (Test-Path $ExpertiseLevelsPath)) {
    Write-Error "Fichier des niveaux d'expertise non trouvé: $ExpertiseLevelsPath"
    exit 1
}

if (-not (Test-Path $SkillsListPath)) {
    Write-Error "Fichier des compétences non trouvé: $SkillsListPath"
    exit 1
}

# Créer le répertoire de sortie s'il n'existe pas
$outputDir = Split-Path -Path $OutputPath -Parent
if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path -Path $outputDir)) {
    Write-Host "Création du répertoire de sortie: $outputDir"
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

# Lire le contenu des fichiers
$expertiseLevelsContent = Get-Content -Path $ExpertiseLevelsPath -Raw
$skillsListContent = Get-Content -Path $SkillsListPath -Raw

# Extraire les compétences
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

        $tablePattern = '(?ms)\| Catégorie \| Compétence \| Niveau \| Justification \|\r?\n\|[^\r\n]+\|\r?\n((?:\|[^\r\n]+\|\r?\n)+)'
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

Write-Host "Nombre de compétences extraites: $($skills.Count)"

# Générer le rapport
$report = @"
# Rapport d'Évaluation des Compétences

## Table des Matières
1. [Méthodologie](#méthodologie)
2. [Résultats d'Évaluation](#résultats-dévaluation)
3. [Distribution des Niveaux](#distribution-des-niveaux)
4. [Recommandations](#recommandations)

## Méthodologie
L'évaluation des compétences est basée sur une analyse détaillée de chaque compétence selon plusieurs critères:
- Complexité technique
- Niveau de supervision requis
- Capacité de résolution de problèmes
- Impact sur le projet

## Résultats d'Évaluation
| Compétence | Catégorie | Manager | Amélioration | Niveau | Justification |
|------------|-----------|---------|--------------|--------|---------------|
"@

foreach ($skill in $skills) {
    $report += "| $($skill.Name) | $($skill.Category) | $($skill.Manager) | $($skill.Improvement) | $($skill.Level) | $($skill.Justification) |`r`n"
}

# Calculer la distribution des niveaux
$levelDistribution = @{
    'Débutant'      = 0
    'Intermédiaire' = 0
    'Avancé'        = 0
    'Expert'        = 0
}

foreach ($skill in $skills) {
    switch ($skill.Level) {
        'Débutant' { $levelDistribution['Débutant']++ }
        'Intermédiaire' { $levelDistribution['Intermédiaire']++ }
        'Avancé' { $levelDistribution['Avancé']++ }
        'Expert' { $levelDistribution['Expert']++ }
    }
}

$report += @"

## Distribution des Niveaux
"@

if ($skills.Count -gt 0) {
    $report += @"
- Débutant: $($levelDistribution['Débutant']) compétences ($([math]::Round(($levelDistribution['Débutant'] / $skills.Count) * 100, 1))%)
- Intermédiaire: $($levelDistribution['Intermédiaire']) compétences ($([math]::Round(($levelDistribution['Intermédiaire'] / $skills.Count) * 100, 1))%)
- Avancé: $($levelDistribution['Avancé']) compétences ($([math]::Round(($levelDistribution['Avancé'] / $skills.Count) * 100, 1))%)
- Expert: $($levelDistribution['Expert']) compétences ($([math]::Round(($levelDistribution['Expert'] / $skills.Count) * 100, 1))%)
"@
} else {
    $report += @"
- Aucune compétence évaluée
"@
}

$report += @"

## Recommandations
Basé sur l'évaluation:
- Concentrer la formation sur les compétences de niveau Débutant/Intermédiaire
- Allouer les ressources seniors aux tâches de niveau Expert
- Revoir les compétences avec des scores faibles pour une potentielle automatisation
"@

# Enregistrer le rapport
$report | Out-File -FilePath $OutputPath -Encoding ascii

# Générer un rapport HTML
$htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Rapport d'Évaluation des Compétences</title>
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
    <h1>Rapport d'Évaluation des Compétences</h1>

    <h2>Méthodologie</h2>
    <p>L'évaluation des compétences est basée sur une analyse détaillée de chaque compétence selon plusieurs critères:</p>
    <ul>
        <li>Complexité technique</li>
        <li>Niveau de supervision requis</li>
        <li>Capacité de résolution de problèmes</li>
        <li>Impact sur le projet</li>
    </ul>

    <h2>Résultats d'Évaluation</h2>
    <table>
        <tr>
            <th>Compétence</th>
            <th>Catégorie</th>
            <th>Manager</th>
            <th>Amélioration</th>
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
        <li>Débutant: $($levelDistribution['Débutant']) compétences ($([math]::Round(($levelDistribution['Débutant'] / $skills.Count) * 100, 1))%)</li>
        <li>Intermédiaire: $($levelDistribution['Intermédiaire']) compétences ($([math]::Round(($levelDistribution['Intermédiaire'] / $skills.Count) * 100, 1))%)</li>
        <li>Avancé: $($levelDistribution['Avancé']) compétences ($([math]::Round(($levelDistribution['Avancé'] / $skills.Count) * 100, 1))%)</li>
        <li>Expert: $($levelDistribution['Expert']) compétences ($([math]::Round(($levelDistribution['Expert'] / $skills.Count) * 100, 1))%)</li>
    </ul>

    <h2>Recommandations</h2>
    <p>Basé sur l'évaluation:</p>
    <ul>
        <li>Concentrer la formation sur les compétences de niveau Débutant/Intermédiaire</li>
        <li>Allouer les ressources seniors aux tâches de niveau Expert</li>
        <li>Revoir les compétences avec des scores faibles pour une potentielle automatisation</li>
    </ul>
</body>
</html>
"@

# Enregistrer le rapport HTML
$htmlReport | Out-File -FilePath $OutputPathHtml -Encoding utf8

Write-Host "Rapport d'évaluation généré avec succès à: $OutputPath"
Write-Host "Rapport HTML généré avec succès à: $OutputPathHtml"

# Afficher un résumé
Write-Host "`nRésumé de l'évaluation des compétences :"
Write-Host "---------------------------------------------------"
Write-Host "  Nombre total de compétences évaluées : $($skills.Count)"

if ($skills.Count -gt 0) {
    Write-Host "  Distribution des niveaux d'expertise :"
    Write-Host "    - Débutant      : $($levelDistribution['Débutant']) ($([math]::Round(($levelDistribution['Débutant'] / $skills.Count) * 100, 1))%)"
    Write-Host "    - Intermédiaire : $($levelDistribution['Intermédiaire']) ($([math]::Round(($levelDistribution['Intermédiaire'] / $skills.Count) * 100, 1))%)"
    Write-Host "    - Avancé        : $($levelDistribution['Avancé']) ($([math]::Round(($levelDistribution['Avancé'] / $skills.Count) * 100, 1))%)"
    Write-Host "    - Expert        : $($levelDistribution['Expert']) ($([math]::Round(($levelDistribution['Expert'] / $skills.Count) * 100, 1))%)"
} else {
    Write-Host "  Aucune compétence évaluée"
}

Write-Host "  Rapport généré à : $OutputPath"
