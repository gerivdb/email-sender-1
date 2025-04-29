# Script d'application de la matrice d'évaluation des compétences
param(
    [string]$ExpertiseLevelsPath = "..\..\..\data\planning\expertise-levels.md",
    [string]$SkillsListPath = "..\..\..\data\planning\skills-list.md",
    [string]$OutputPath = "..\..\..\data\planning\skills-evaluation.md"
)

# Structure pour stocker les critères d'évaluation
class EvaluationCriterion {
    [string]$Name
    [hashtable]$Levels
    [double]$Weight
}

# Structure pour stocker une compétence évaluée
class EvaluatedSkill {
    [string]$Name
    [string]$Category
    [hashtable]$Scores
    [double]$GlobalScore
    [string]$ExpertiseLevel
    [string]$Justification
}

# Fonction pour extraire les critères d'évaluation
function Get-EvaluationCriteria {
    param([string]$FilePath)
    
    $content = Get-Content -Path $FilePath -Raw
    $criteria = @()
    
    # Extraction des sections de critères
    $criteriaPattern = '(?ms)### ([^
]+)\r?\n((?:- [^\r\n]+\r?\n?)+)'
    $matches = [regex]::Matches($content, $criteriaPattern)
    
    foreach ($match in $matches) {
        $criterion = [EvaluationCriterion]::new()
        $criterion.Name = $match.Groups[1].Value.Trim()
        $criterion.Levels = @{}
        $criterion.Weight = 0.25 # Poids par défaut
        
        # Extraction des niveaux
        $levelPattern = '- (Niveau \d+): ([^\r\n]+)'
        $levelMatches = [regex]::Matches($match.Groups[2].Value, $levelPattern)
        
        foreach ($levelMatch in $levelMatches) {
            $level = $levelMatch.Groups[1].Value
            $description = $levelMatch.Groups[2].Value
            $criterion.Levels[$level] = $description
        }
        
        $criteria += $criterion
    }
    
    return $criteria
}

# Fonction pour lire et parser les compétences
function Get-SkillsList {
    param([string]$FilePath)
    
    $content = Get-Content -Path $FilePath -Raw
    $skills = @()
    
    # Pattern pour extraire les catégories et compétences
    $categoryPattern = '(?ms)## ([^\r\n]+)\r?\n((?:### [^\r\n]+\r?\n(?:(?!##)[^\r\n]+\r?\n)*)+)'
    $categoryMatches = [regex]::Matches($content, $categoryPattern)
    
    foreach ($categoryMatch in $categoryMatches) {
        $category = $categoryMatch.Groups[1].Value.Trim()
        
        # Pattern pour extraire les compétences individuelles
        $skillPattern = '### ([^\r\n]+)\r?\n([^#][^\r\n]+)'
        $skillMatches = [regex]::Matches($categoryMatch.Groups[2].Value, $skillPattern)
        
        foreach ($skillMatch in $skillMatches) {
            $skill = [EvaluatedSkill]::new()
            $skill.Name = $skillMatch.Groups[1].Value.Trim()
            $skill.Category = $category
            $skill.Scores = @{}
            $skill.Justification = $skillMatch.Groups[2].Value.Trim()
            $skills += $skill
        }
    }
    
    return $skills
}

# Fonction pour évaluer une compétence
function Evaluate-Skill {
    param(
        [EvaluatedSkill]$Skill,
        [array]$Criteria
    )
    
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
    
    $Skill.GlobalScore = $totalScore / $totalWeight
    
    # Détermination du niveau d'expertise
    $Skill.ExpertiseLevel = switch ($Skill.GlobalScore) {
        {$_ -le 1.5} { 'Débutant' }
        {$_ -le 2.5} { 'Intermédiaire' }
        {$_ -le 3.5} { 'Avancé' }
        default { 'Expert' }
    }
    
    return $Skill
}

# Fonction pour générer le rapport
function New-EvaluationReport {
    param(
        [array]$EvaluatedSkills,
        [string]$OutputPath
    )
    
    # Calcul de la distribution des niveaux
    $levelDistribution = @{
        'Débutant' = 0
        'Intermédiaire' = 0
        'Avancé' = 0
        'Expert' = 0
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
| Compétence | Catégorie | Score Global | Niveau d'Expertise | Justification |
|------------|-----------|--------------|-------------------|---------------|
$($EvaluatedSkills | ForEach-Object {
    "| $($_.Name) | $($_.Category) | $([math]::Round($_.GlobalScore, 2)) | $($_.ExpertiseLevel) | $($_.Justification) |"
} | Join-String -Separator "`n")

## Distribution des Niveaux
- Débutant: $($levelDistribution['Débutant']) compétences
- Intermédiaire: $($levelDistribution['Intermédiaire']) compétences
- Avancé: $($levelDistribution['Avancé']) compétences
- Expert: $($levelDistribution['Expert']) compétences

## Recommandations
Basé sur l'évaluation:
- Concentrer la formation sur les compétences de niveau Débutant/Intermédiaire
- Allouer les ressources seniors aux tâches de niveau Expert
- Revoir les compétences avec des scores faibles pour une potentielle automatisation
"@
    
    Set-Content -Path $OutputPath -Value $report -Encoding UTF8
}

# Exécution principale
try {
    # Validation des fichiers d'entrée
    if (-not (Test-Path $ExpertiseLevelsPath)) { throw "Fichier des niveaux d'expertise non trouvé" }
    if (-not (Test-Path $SkillsListPath)) { throw "Fichier des compétences non trouvé" }
    
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
    
    Write-Host "Évaluation terminée. Rapport généré à: $OutputPath"
} catch {
    Write-Error "Erreur: $_"
    exit 1
}