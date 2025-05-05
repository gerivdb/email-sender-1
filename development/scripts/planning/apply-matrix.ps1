# Script d'application de la matrice d'Ã©valuation des compÃ©tences
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ParamÃ¨tres
$ExpertiseLevelsPath = ".\development\data\planning\expertise-levels.md"
$SkillsListPath = ".\development\data\planning\skills-list-formatted.md"
$OutputPath = ".\development\data\planning\skills-evaluation.md"
$Format = "Markdown"
$DetailLevel = "Detailed"
$WeightingMethod = "Custom"

# Afficher les informations de dÃ©marrage
Write-Host "DÃ©marrage de l'application de la matrice d'Ã©valuation des compÃ©tences"
Write-Host "ParamÃ¨tres:"
Write-Host "  - Fichier des niveaux d'expertise: $ExpertiseLevelsPath"
Write-Host "  - Fichier des compÃ©tences: $SkillsListPath"
Write-Host "  - Fichier de sortie: $OutputPath"
Write-Host "  - Format: $Format"
Write-Host "  - Niveau de dÃ©tail: $DetailLevel"
Write-Host "  - MÃ©thode de pondÃ©ration: $WeightingMethod"

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

# Structure pour stocker les critÃ¨res d'Ã©valuation
class EvaluationCriterion {
    [string]$Name
    [hashtable]$Levels
    [double]$Weight
    [string]$Description
    [string]$Category
    [int]$Priority

    EvaluationCriterion() {
        $this.Levels = @{}
        $this.Weight = 0.25 # Poids par dÃ©faut
        $this.Priority = 1
    }
}

# Structure pour stocker une compÃ©tence Ã©valuÃ©e
class EvaluatedSkill {
    [string]$Name
    [string]$Category
    [hashtable]$Scores
    [double]$GlobalScore
    [string]$ExpertiseLevel
    [string]$Justification
    [string]$Manager
    [string]$Improvement

    EvaluatedSkill() {
        $this.Scores = @{}
    }

    EvaluatedSkill([string]$Name, [string]$Category) {
        $this.Name = $Name
        $this.Category = $Category
        $this.Scores = @{}
    }
}

# Fonction pour extraire les critÃ¨res d'Ã©valuation
function Get-EvaluationCriteria {
    param([string]$FilePath)

    Write-Host "Extraction des critÃ¨res d'Ã©valuation depuis $FilePath"

    $content = Get-Content -Path $FilePath -Raw
    $criteria = @()

    # Extraction des sections de critÃ¨res
    $criteriaPattern = '(?ms)## CritÃ¨res d''Ã©valuation\r?\n(.*?)(?=##|\z)'
    $criteriaSection = [regex]::Match($content, $criteriaPattern).Groups[1].Value

    if ([string]::IsNullOrEmpty($criteriaSection)) {
        Write-Warning "Aucune section 'CritÃ¨res d'Ã©valuation' trouvÃ©e dans le fichier."
        return $criteria
    }

    # Extraction des catÃ©gories de critÃ¨res
    $categoryPattern = '(?ms)### ([^\r\n]+)\r?\n((?:(?!###)[^\r\n]+\r?\n?)+)'
    $categoryMatches = [regex]::Matches($criteriaSection, $categoryPattern)

    foreach ($categoryMatch in $categoryMatches) {
        $category = $categoryMatch.Groups[1].Value.Trim()
        $categoryContent = $categoryMatch.Groups[2].Value

        # Extraction des critÃ¨res individuels
        $criterionPattern = '(?ms)#### ([^\r\n]+)\r?\n((?:(?!####)[^\r\n]+\r?\n?)+)'
        $criterionMatches = [regex]::Matches($categoryContent, $criterionPattern)

        foreach ($criterionMatch in $criterionMatches) {
            $criterion = [EvaluationCriterion]::new()
            $criterion.Name = $criterionMatch.Groups[1].Value.Trim()
            $criterion.Category = $category
            $criterion.Levels = @{}

            $criterionContent = $criterionMatch.Groups[2].Value

            # Extraction de la description
            $descriptionPattern = '(?ms)Description: ([^\r\n]+)'
            $descriptionMatch = [regex]::Match($criterionContent, $descriptionPattern)
            if ($descriptionMatch.Success) {
                $criterion.Description = $descriptionMatch.Groups[1].Value.Trim()
            }

            # Extraction du poids
            $weightPattern = '(?ms)Poids: ([0-9.]+)'
            $weightMatch = [regex]::Match($criterionContent, $weightPattern)
            if ($weightMatch.Success) {
                $criterion.Weight = [double]$weightMatch.Groups[1].Value
            }

            # Extraction de la prioritÃ©
            $priorityPattern = '(?ms)PrioritÃ©: ([0-9]+)'
            $priorityMatch = [regex]::Match($criterionContent, $priorityPattern)
            if ($priorityMatch.Success) {
                $criterion.Priority = [int]$priorityMatch.Groups[1].Value
            }

            # Extraction des niveaux
            $levelPattern = '- (Niveau \d+): ([^\r\n]+)'
            $levelMatches = [regex]::Matches($criterionContent, $levelPattern)

            foreach ($levelMatch in $levelMatches) {
                $level = $levelMatch.Groups[1].Value
                $description = $levelMatch.Groups[2].Value
                $criterion.Levels[$level] = $description
            }

            # Ajuster les poids en fonction de la mÃ©thode de pondÃ©ration
            if ($WeightingMethod -eq "Equal") {
                $criterion.Weight = 1.0
            }

            $criteria += $criterion
        }
    }

    Write-Host "$($criteria.Count) critÃ¨res d'Ã©valuation extraits."

    return $criteria
}

# Fonction pour lire et parser les compÃ©tences
function Get-SkillsList {
    param([string]$FilePath)

    Write-Host "Extraction des compÃ©tences depuis $FilePath"

    $content = Get-Content -Path $FilePath -Raw
    $skills = @()

    # Pattern pour extraire les gestionnaires
    $managerPattern = '(?ms)## <a name=''([^'']+)''></a>([^\n]+)\r?\n(.*?)(?=## <a name=|\z)'
    $managerMatches = [regex]::Matches($content, $managerPattern)

    foreach ($managerMatch in $managerMatches) {
        $managerName = $managerMatch.Groups[2].Value.Trim()
        $managerContent = $managerMatch.Groups[3].Value

        # Pattern pour extraire les amÃ©liorations
        $improvementPattern = '(?ms)### ([^\r\n]+)\r?\n(.*?)(?=###|\z)'
        $improvementMatches = [regex]::Matches($managerContent, $improvementPattern)

        foreach ($improvementMatch in $improvementMatches) {
            $improvementName = $improvementMatch.Groups[1].Value.Trim()
            $improvementContent = $improvementMatch.Groups[2].Value

            # Pattern pour extraire la table des compÃ©tences
            $tablePattern = '(?ms)\| CatÃ©gorie \| CompÃ©tence \| Niveau \| Justification \|\r?\n\|[^\r\n]+\|\r?\n((?:\|[^\r\n]+\|\r?\n)+)'
            $tableMatch = [regex]::Match($improvementContent, $tablePattern)

            if ($tableMatch.Success) {
                $tableContent = $tableMatch.Groups[1].Value

                # Pattern pour extraire les lignes de la table
                $rowPattern = '\| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \|'
                $rowMatches = [regex]::Matches($tableContent, $rowPattern)

                foreach ($rowMatch in $rowMatches) {
                    $category = $rowMatch.Groups[1].Value.Trim()
                    $skillName = $rowMatch.Groups[2].Value.Trim()
                    $level = $rowMatch.Groups[3].Value.Trim()
                    $justification = $rowMatch.Groups[4].Value.Trim()

                    $skill = [EvaluatedSkill]::new()
                    $skill.Name = $skillName
                    $skill.Category = $category
                    $skill.Manager = $managerName
                    $skill.Improvement = $improvementName
                    $skill.Justification = $justification

                    $skills += $skill
                }
            }
        }
    }

    Write-Host "$($skills.Count) compÃ©tences extraites."

    return $skills
}

# Fonction pour Ã©valuer une compÃ©tence
function Evaluate-Skill {
    param(
        [EvaluatedSkill]$Skill,
        [array]$Criteria
    )

    Write-Host "Ã‰valuation de la compÃ©tence '$($Skill.Name)' dans la catÃ©gorie '$($Skill.Category)'"

    $totalScore = 0
    $totalWeight = 0

    foreach ($criterion in $Criteria) {
        # Analyse de la justification pour dÃ©terminer le niveau
        $score = 1 # Niveau par dÃ©faut
        foreach ($level in $criterion.Levels.Keys | Sort-Object) {
            $description = $criterion.Levels[$level]
            if ($Skill.Justification -match [regex]::Escape($description)) {
                $score = [int]($level -replace 'Niveau ', '')
                break
            }
        }

        $Skill.Scores[$criterion.Name] = $score
        $totalScore += $score * $criterion.Weight
        $totalWeight += $criterion.Weight
    }

    if ($totalWeight -gt 0) {
        $Skill.GlobalScore = $totalScore / $totalWeight
    } else {
        $Skill.GlobalScore = 0
    }

    # DÃ©termination du niveau d'expertise
    $Skill.ExpertiseLevel = switch ($Skill.GlobalScore) {
        { $_ -le 1.5 } { 'DÃ©butant' }
        { $_ -le 2.5 } { 'IntermÃ©diaire' }
        { $_ -le 3.5 } { 'AvancÃ©' }
        default { 'Expert' }
    }

    Write-Host "CompÃ©tence '$($Skill.Name)' Ã©valuÃ©e avec un score global de $([math]::Round($Skill.GlobalScore, 2)) ($($Skill.ExpertiseLevel))"

    return $Skill
}

# Fonction pour gÃ©nÃ©rer le rapport
function New-EvaluationReport {
    param(
        [array]$EvaluatedSkills,
        [string]$OutputPath
    )

    Write-Host "GÃ©nÃ©ration du rapport d'Ã©valuation au format $Format avec niveau de dÃ©tail $DetailLevel"

    # Calcul de la distribution des niveaux
    $levelDistribution = @{
        'DÃ©butant'      = 0
        'IntermÃ©diaire' = 0
        'AvancÃ©'        = 0
        'Expert'        = 0
    }

    foreach ($skill in $EvaluatedSkills) {
        $levelDistribution[$skill.ExpertiseLevel]++
    }

    # GÃ©nÃ©ration du rapport
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
| CompÃ©tence | CatÃ©gorie | Manager | AmÃ©lioration | Score Global | Niveau d'Expertise | Justification |
|------------|-----------|---------|--------------|--------------|-------------------|---------------|
"@

    foreach ($skill in $EvaluatedSkills) {
        $report += "| $($skill.Name) | $($skill.Category) | $($skill.Manager) | $($skill.Improvement) | $([math]::Round($skill.GlobalScore, 2)) | $($skill.ExpertiseLevel) | $($skill.Justification) |`n"
    }

    $report += @"

## Distribution des Niveaux
"@

    if ($EvaluatedSkills.Count -gt 0) {
        $report += @"
- DÃ©butant: $($levelDistribution['DÃ©butant']) compÃ©tences ($([math]::Round(($levelDistribution['DÃ©butant'] / $EvaluatedSkills.Count) * 100, 1))%)
- IntermÃ©diaire: $($levelDistribution['IntermÃ©diaire']) compÃ©tences ($([math]::Round(($levelDistribution['IntermÃ©diaire'] / $EvaluatedSkills.Count) * 100, 1))%)
- AvancÃ©: $($levelDistribution['AvancÃ©']) compÃ©tences ($([math]::Round(($levelDistribution['AvancÃ©'] / $EvaluatedSkills.Count) * 100, 1))%)
- Expert: $($levelDistribution['Expert']) compÃ©tences ($([math]::Round(($levelDistribution['Expert'] / $EvaluatedSkills.Count) * 100, 1))%)
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

    # Utiliser BOM pour assurer l'encodage UTF-8 correct
    $utf8WithBom = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::WriteAllText($OutputPath, $report, $utf8WithBom)

    Write-Host "Rapport d'Ã©valuation gÃ©nÃ©rÃ© avec succÃ¨s Ã : $OutputPath"
}

# ExÃ©cution principale
try {
    # Extraction des critÃ¨res et des compÃ©tences
    $criteria = Get-EvaluationCriteria -FilePath $ExpertiseLevelsPath
    $skills = Get-SkillsList -FilePath $SkillsListPath

    # Ã‰valuation des compÃ©tences
    $evaluatedSkills = @()
    foreach ($skill in $skills) {
        $evaluatedSkill = Evaluate-Skill -Skill $skill -Criteria $criteria
        $evaluatedSkills += $evaluatedSkill
    }

    # GÃ©nÃ©ration du rapport
    New-EvaluationReport -EvaluatedSkills $evaluatedSkills -OutputPath $OutputPath

    # Afficher un rÃ©sumÃ© des rÃ©sultats
    $levelDistribution = @{
        'DÃ©butant'      = 0
        'IntermÃ©diaire' = 0
        'AvancÃ©'        = 0
        'Expert'        = 0
    }

    foreach ($skill in $evaluatedSkills) {
        $levelDistribution[$skill.ExpertiseLevel]++
    }

    Write-Host "`nRÃ©sumÃ© de l'Ã©valuation des compÃ©tences :"
    Write-Host "---------------------------------------------------"
    Write-Host "  Nombre total de compÃ©tences Ã©valuÃ©es : $($evaluatedSkills.Count)"

    if ($evaluatedSkills.Count -gt 0) {
        Write-Host "  Distribution des niveaux d'expertise :"
        Write-Host "    - DÃ©butant      : $($levelDistribution['DÃ©butant']) ($([math]::Round(($levelDistribution['DÃ©butant'] / $evaluatedSkills.Count) * 100, 1))%)"
        Write-Host "    - IntermÃ©diaire : $($levelDistribution['IntermÃ©diaire']) ($([math]::Round(($levelDistribution['IntermÃ©diaire'] / $evaluatedSkills.Count) * 100, 1))%)"
        Write-Host "    - AvancÃ©        : $($levelDistribution['AvancÃ©']) ($([math]::Round(($levelDistribution['AvancÃ©'] / $evaluatedSkills.Count) * 100, 1))%)"
        Write-Host "    - Expert        : $($levelDistribution['Expert']) ($([math]::Round(($levelDistribution['Expert'] / $evaluatedSkills.Count) * 100, 1))%)"
    } else {
        Write-Host "  Aucune compÃ©tence Ã©valuÃ©e"
    }

    Write-Host "  Rapport gÃ©nÃ©rÃ© Ã  : $OutputPath"

    # Retourner un code de succÃ¨s
    exit 0
} catch {
    Write-Error "Erreur lors de l'application de la matrice d'Ã©valuation : $_"

    # Afficher la pile d'appels pour faciliter le dÃ©bogage
    Write-Host "Pile d'appels :"
    Write-Host $_.ScriptStackTrace

    # Retourner un code d'erreur
    exit 1
}
