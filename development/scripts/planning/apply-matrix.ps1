# Script d'application de la matrice d'évaluation des compétences
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Paramètres
$ExpertiseLevelsPath = ".\development\data\planning\expertise-levels.md"
$SkillsListPath = ".\development\data\planning\skills-list-formatted.md"
$OutputPath = ".\development\data\planning\skills-evaluation.md"
$Format = "Markdown"
$DetailLevel = "Detailed"
$WeightingMethod = "Custom"

# Afficher les informations de démarrage
Write-Host "Démarrage de l'application de la matrice d'évaluation des compétences"
Write-Host "Paramètres:"
Write-Host "  - Fichier des niveaux d'expertise: $ExpertiseLevelsPath"
Write-Host "  - Fichier des compétences: $SkillsListPath"
Write-Host "  - Fichier de sortie: $OutputPath"
Write-Host "  - Format: $Format"
Write-Host "  - Niveau de détail: $DetailLevel"
Write-Host "  - Méthode de pondération: $WeightingMethod"

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

# Structure pour stocker les critères d'évaluation
class EvaluationCriterion {
    [string]$Name
    [hashtable]$Levels
    [double]$Weight
    [string]$Description
    [string]$Category
    [int]$Priority

    EvaluationCriterion() {
        $this.Levels = @{}
        $this.Weight = 0.25 # Poids par défaut
        $this.Priority = 1
    }
}

# Structure pour stocker une compétence évaluée
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

# Fonction pour extraire les critères d'évaluation
function Get-EvaluationCriteria {
    param([string]$FilePath)

    Write-Host "Extraction des critères d'évaluation depuis $FilePath"

    $content = Get-Content -Path $FilePath -Raw
    $criteria = @()

    # Extraction des sections de critères
    $criteriaPattern = '(?ms)## Critères d''évaluation\r?\n(.*?)(?=##|\z)'
    $criteriaSection = [regex]::Match($content, $criteriaPattern).Groups[1].Value

    if ([string]::IsNullOrEmpty($criteriaSection)) {
        Write-Warning "Aucune section 'Critères d'évaluation' trouvée dans le fichier."
        return $criteria
    }

    # Extraction des catégories de critères
    $categoryPattern = '(?ms)### ([^\r\n]+)\r?\n((?:(?!###)[^\r\n]+\r?\n?)+)'
    $categoryMatches = [regex]::Matches($criteriaSection, $categoryPattern)

    foreach ($categoryMatch in $categoryMatches) {
        $category = $categoryMatch.Groups[1].Value.Trim()
        $categoryContent = $categoryMatch.Groups[2].Value

        # Extraction des critères individuels
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

            # Extraction de la priorité
            $priorityPattern = '(?ms)Priorité: ([0-9]+)'
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

            # Ajuster les poids en fonction de la méthode de pondération
            if ($WeightingMethod -eq "Equal") {
                $criterion.Weight = 1.0
            }

            $criteria += $criterion
        }
    }

    Write-Host "$($criteria.Count) critères d'évaluation extraits."

    return $criteria
}

# Fonction pour lire et parser les compétences
function Get-SkillsList {
    param([string]$FilePath)

    Write-Host "Extraction des compétences depuis $FilePath"

    $content = Get-Content -Path $FilePath -Raw
    $skills = @()

    # Pattern pour extraire les gestionnaires
    $managerPattern = '(?ms)## <a name=''([^'']+)''></a>([^\n]+)\r?\n(.*?)(?=## <a name=|\z)'
    $managerMatches = [regex]::Matches($content, $managerPattern)

    foreach ($managerMatch in $managerMatches) {
        $managerName = $managerMatch.Groups[2].Value.Trim()
        $managerContent = $managerMatch.Groups[3].Value

        # Pattern pour extraire les améliorations
        $improvementPattern = '(?ms)### ([^\r\n]+)\r?\n(.*?)(?=###|\z)'
        $improvementMatches = [regex]::Matches($managerContent, $improvementPattern)

        foreach ($improvementMatch in $improvementMatches) {
            $improvementName = $improvementMatch.Groups[1].Value.Trim()
            $improvementContent = $improvementMatch.Groups[2].Value

            # Pattern pour extraire la table des compétences
            $tablePattern = '(?ms)\| Catégorie \| Compétence \| Niveau \| Justification \|\r?\n\|[^\r\n]+\|\r?\n((?:\|[^\r\n]+\|\r?\n)+)'
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

    Write-Host "$($skills.Count) compétences extraites."

    return $skills
}

# Fonction pour évaluer une compétence
function Evaluate-Skill {
    param(
        [EvaluatedSkill]$Skill,
        [array]$Criteria
    )

    Write-Host "Évaluation de la compétence '$($Skill.Name)' dans la catégorie '$($Skill.Category)'"

    $totalScore = 0
    $totalWeight = 0

    foreach ($criterion in $Criteria) {
        # Analyse de la justification pour déterminer le niveau
        $score = 1 # Niveau par défaut
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

    # Détermination du niveau d'expertise
    $Skill.ExpertiseLevel = switch ($Skill.GlobalScore) {
        { $_ -le 1.5 } { 'Débutant' }
        { $_ -le 2.5 } { 'Intermédiaire' }
        { $_ -le 3.5 } { 'Avancé' }
        default { 'Expert' }
    }

    Write-Host "Compétence '$($Skill.Name)' évaluée avec un score global de $([math]::Round($Skill.GlobalScore, 2)) ($($Skill.ExpertiseLevel))"

    return $Skill
}

# Fonction pour générer le rapport
function New-EvaluationReport {
    param(
        [array]$EvaluatedSkills,
        [string]$OutputPath
    )

    Write-Host "Génération du rapport d'évaluation au format $Format avec niveau de détail $DetailLevel"

    # Calcul de la distribution des niveaux
    $levelDistribution = @{
        'Débutant'      = 0
        'Intermédiaire' = 0
        'Avancé'        = 0
        'Expert'        = 0
    }

    foreach ($skill in $EvaluatedSkills) {
        $levelDistribution[$skill.ExpertiseLevel]++
    }

    # Génération du rapport
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
| Compétence | Catégorie | Manager | Amélioration | Score Global | Niveau d'Expertise | Justification |
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
- Débutant: $($levelDistribution['Débutant']) compétences ($([math]::Round(($levelDistribution['Débutant'] / $EvaluatedSkills.Count) * 100, 1))%)
- Intermédiaire: $($levelDistribution['Intermédiaire']) compétences ($([math]::Round(($levelDistribution['Intermédiaire'] / $EvaluatedSkills.Count) * 100, 1))%)
- Avancé: $($levelDistribution['Avancé']) compétences ($([math]::Round(($levelDistribution['Avancé'] / $EvaluatedSkills.Count) * 100, 1))%)
- Expert: $($levelDistribution['Expert']) compétences ($([math]::Round(($levelDistribution['Expert'] / $EvaluatedSkills.Count) * 100, 1))%)
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

    # Utiliser BOM pour assurer l'encodage UTF-8 correct
    $utf8WithBom = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::WriteAllText($OutputPath, $report, $utf8WithBom)

    Write-Host "Rapport d'évaluation généré avec succès à: $OutputPath"
}

# Exécution principale
try {
    # Extraction des critères et des compétences
    $criteria = Get-EvaluationCriteria -FilePath $ExpertiseLevelsPath
    $skills = Get-SkillsList -FilePath $SkillsListPath

    # Évaluation des compétences
    $evaluatedSkills = @()
    foreach ($skill in $skills) {
        $evaluatedSkill = Evaluate-Skill -Skill $skill -Criteria $criteria
        $evaluatedSkills += $evaluatedSkill
    }

    # Génération du rapport
    New-EvaluationReport -EvaluatedSkills $evaluatedSkills -OutputPath $OutputPath

    # Afficher un résumé des résultats
    $levelDistribution = @{
        'Débutant'      = 0
        'Intermédiaire' = 0
        'Avancé'        = 0
        'Expert'        = 0
    }

    foreach ($skill in $evaluatedSkills) {
        $levelDistribution[$skill.ExpertiseLevel]++
    }

    Write-Host "`nRésumé de l'évaluation des compétences :"
    Write-Host "---------------------------------------------------"
    Write-Host "  Nombre total de compétences évaluées : $($evaluatedSkills.Count)"

    if ($evaluatedSkills.Count -gt 0) {
        Write-Host "  Distribution des niveaux d'expertise :"
        Write-Host "    - Débutant      : $($levelDistribution['Débutant']) ($([math]::Round(($levelDistribution['Débutant'] / $evaluatedSkills.Count) * 100, 1))%)"
        Write-Host "    - Intermédiaire : $($levelDistribution['Intermédiaire']) ($([math]::Round(($levelDistribution['Intermédiaire'] / $evaluatedSkills.Count) * 100, 1))%)"
        Write-Host "    - Avancé        : $($levelDistribution['Avancé']) ($([math]::Round(($levelDistribution['Avancé'] / $evaluatedSkills.Count) * 100, 1))%)"
        Write-Host "    - Expert        : $($levelDistribution['Expert']) ($([math]::Round(($levelDistribution['Expert'] / $evaluatedSkills.Count) * 100, 1))%)"
    } else {
        Write-Host "  Aucune compétence évaluée"
    }

    Write-Host "  Rapport généré à : $OutputPath"

    # Retourner un code de succès
    exit 0
} catch {
    Write-Error "Erreur lors de l'application de la matrice d'évaluation : $_"

    # Afficher la pile d'appels pour faciliter le débogage
    Write-Host "Pile d'appels :"
    Write-Host $_.ScriptStackTrace

    # Retourner un code d'erreur
    exit 1
}
