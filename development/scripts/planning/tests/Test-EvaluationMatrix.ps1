using module Pester

# Définir l'encodage UTF-8 pour les caractères accentués
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Créer une version simplifiée du script pour les tests
$scriptContent = @'
# Définir l'encodage UTF-8 pour les caractères accentués
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

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

    EvaluationCriterion([string]$Name, [double]$Weight) {
        $this.Name = $Name
        $this.Levels = @{}
        $this.Weight = $Weight
        $this.Priority = 1
    }

    EvaluationCriterion([string]$Name, [hashtable]$Levels, [double]$Weight, [string]$Description, [string]$Category, [int]$Priority) {
        $this.Name = $Name
        $this.Levels = $Levels
        $this.Weight = $Weight
        $this.Description = $Description
        $this.Category = $Category
        $this.Priority = $Priority
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
    [hashtable]$DetailedScores
    [hashtable]$CriteriaJustifications
    [datetime]$EvaluationDate
    [string]$EvaluatedBy

    EvaluatedSkill() {
        $this.Scores = @{}
        $this.DetailedScores = @{}
        $this.CriteriaJustifications = @{}
        $this.EvaluationDate = Get-Date
    }

    EvaluatedSkill([string]$Name, [string]$Category) {
        $this.Name = $Name
        $this.Category = $Category
        $this.Scores = @{}
        $this.DetailedScores = @{}
        $this.CriteriaJustifications = @{}
        $this.EvaluationDate = Get-Date
    }

    [void] AddScore([string]$CriterionName, [int]$Score, [string]$Justification) {
        $this.Scores[$CriterionName] = $Score
        $this.CriteriaJustifications[$CriterionName] = $Justification
    }

    [void] CalculateGlobalScore([array]$Criteria, [string]$WeightingMethod) {
        $totalScore = 0
        $totalWeight = 0

        foreach ($criterion in $Criteria) {
            if ($this.Scores.ContainsKey($criterion.Name)) {
                $score = $this.Scores[$criterion.Name]
                [double]$criterionWeight = 1.0

                # Appliquer la méthode de pondération
                switch ($WeightingMethod) {
                    "Equal" {
                        $criterionWeight = 1.0
                    }
                    "Custom" {
                        $criterionWeight = $criterion.Weight
                    }
                    "Adaptive" {
                        # Pondération adaptative basée sur la priorité du critère
                        $criterionWeight = $criterion.Weight * $criterion.Priority
                    }
                    default {
                        $criterionWeight = 1.0
                    }
                }

                $totalScore += $score * $criterionWeight
                $totalWeight += $criterionWeight

                # Stocker le score détaillé
                $this.DetailedScores[$criterion.Name] = @{
                    "Score"         = $score
                    "Weight"        = $criterionWeight
                    "WeightedScore" = $score * $criterionWeight
                }
            }
        }

        if ($totalWeight -gt 0) {
            $this.GlobalScore = $totalScore / $totalWeight
        } else {
            $this.GlobalScore = 0
        }

        # Détermination du niveau d'expertise
        $this.ExpertiseLevel = switch ($this.GlobalScore) {
            { $_ -le 1.5 } { 'Débutant' }
            { $_ -le 2.5 } { 'Intermédiaire' }
            { $_ -le 3.5 } { 'Avancé' }
            default { 'Expert' }
        }
    }
}

# Fonction pour extraire les critères d'évaluation du document des niveaux d'expertise
function Get-EvaluationCriteria {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [string]$WeightingMethod = "Equal"
    )

    Write-Verbose "Extraction des critères d'évaluation depuis $FilePath"

    # Vérifier que le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        throw "Le fichier des niveaux d'expertise n'existe pas : $FilePath"
    }

    $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
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
            } elseif ($WeightingMethod -eq "Adaptive") {
                # La pondération adaptative sera appliquée lors de l'évaluation
            }

            $criteria += $criterion
        }
    }

    Write-Verbose "$($criteria.Count) critères d'évaluation extraits."

    return $criteria
}

# Fonction pour lire et parser les compétences à partir du fichier de la liste des compétences
function Get-SkillsList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    Write-Verbose "Extraction des compétences depuis $FilePath"

    # Vérifier que le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        throw "Le fichier de la liste des compétences n'existe pas : $FilePath"
    }

    $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
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

                    $skill = [EvaluatedSkill]::new($skillName, $category)
                    $skill.Manager = $managerName
                    $skill.Improvement = $improvementName
                    $skill.Justification = $justification
                    $skill.EvaluatedBy = "System"

                    $skills += $skill
                }
            }
        }
    }

    # Si aucun gestionnaire n'est trouvé, essayer le format alternatif
    if ($skills.Count -eq 0) {
        # Pattern pour extraire les catégories et compétences (format alternatif)
        $categoryPattern = '(?ms)## ([^\r\n]+)\r?\n((?:### [^\r\n]+\r?\n(?:(?!##)[^\r\n]+\r?\n)*)+)'
        $categoryMatches = [regex]::Matches($content, $categoryPattern)

        foreach ($categoryMatch in $categoryMatches) {
            $category = $categoryMatch.Groups[1].Value.Trim()

            # Pattern pour extraire les compétences individuelles
            $skillPattern = '### ([^\r\n]+)\r?\n([^#][^\r\n]+)'
            $skillMatches = [regex]::Matches($categoryMatch.Groups[2].Value, $skillPattern)

            foreach ($skillMatch in $skillMatches) {
                $skillName = $skillMatch.Groups[1].Value.Trim()
                $justification = $skillMatch.Groups[2].Value.Trim()

                $skill = [EvaluatedSkill]::new($skillName, $category)
                $skill.Justification = $justification
                $skill.EvaluatedBy = "System"

                $skills += $skill
            }
        }
    }

    Write-Verbose "$($skills.Count) compétences extraites."

    return $skills
}

# Fonction pour évaluer une compétence selon les critères définis
function Test-Skill {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [EvaluatedSkill]$Skill,

        [Parameter(Mandatory = $true)]
        [array]$Criteria,

        [Parameter(Mandatory = $false)]
        [string]$WeightingMethod = "Equal",

        [Parameter(Mandatory = $false)]
        [string]$DetailLevel = "Standard"
    )

    Write-Verbose "Évaluation de la compétence '$($Skill.Name)' dans la catégorie '$($Skill.Category)'"

    foreach ($criterion in $Criteria) {
        # Analyse de la justification pour déterminer le niveau
        $score = 1 # Niveau par défaut
        $justification = ""

        # Recherche des mots-clés dans la justification
        foreach ($level in $criterion.Levels.Keys | Sort-Object) {
            $levelNumber = [int]($level -replace 'Niveau ', '')
            $description = $criterion.Levels[$level]

            # Vérifier si la description du niveau est présente dans la justification
            if ($Skill.Justification -match [regex]::Escape($description)) {
                $score = $levelNumber
                $justification = "Correspondance exacte avec le niveau $levelNumber : $description"
                break
            }

            # Recherche de mots-clés
            $keywords = $description -split ',' | ForEach-Object { $_.Trim() }
            $matchCount = 0
            $matchedKeywords = @()

            foreach ($keyword in $keywords) {
                if ($Skill.Justification -match [regex]::Escape($keyword)) {
                    $matchCount++
                    $matchedKeywords += $keyword
                }
            }

            # Si plus de 50% des mots-clés correspondent, utiliser ce niveau
            if ($keywords.Count -gt 0 -and ($matchCount / $keywords.Count) -gt 0.5) {
                if ($levelNumber -gt $score) {
                    $score = $levelNumber
                    $justification = "Correspondance partielle ($matchCount/$($keywords.Count)) avec le niveau $levelNumber : $($matchedKeywords -join ', ')"
                }
            }
        }

        # Ajouter le score et la justification
        $Skill.AddScore($criterion.Name, $score, $justification)
    }

    # Calculer le score global en fonction de la méthode de pondération
    $Skill.CalculateGlobalScore($Criteria, $WeightingMethod)

    # Ajouter des détails supplémentaires en fonction du niveau de détail
    if ($DetailLevel -eq "Detailed") {
        # Ajouter des analyses supplémentaires ici
        $Skill.CriteriaJustifications["GlobalAnalysis"] = "Analyse détaillée de la compétence '$($Skill.Name)' : Score global de $([math]::Round($Skill.GlobalScore, 2)) correspondant au niveau '$($Skill.ExpertiseLevel)'."
    }

    Write-Verbose "Compétence '$($Skill.Name)' évaluée avec un score global de $([math]::Round($Skill.GlobalScore, 2)) ($($Skill.ExpertiseLevel))"

    return $Skill
}

# Fonction pour générer le rapport d'évaluation des compétences
function New-EvaluationReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$EvaluatedSkills,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [string]$Format = "Markdown",

        [Parameter(Mandatory = $false)]
        [string]$DetailLevel = "Standard"
    )

    Write-Verbose "Génération du rapport d'évaluation au format $Format avec niveau de détail $DetailLevel"

    # Calcul de la distribution des niveaux
    $levelDistribution = @{
        'Débutant'      = 0
        'Intermédiaire' = 0
        'Avancé'        = 0
        'Expert'        = 0
    }

    # Calcul des statistiques par catégorie
    $categoryStats = @{}

    foreach ($skill in $EvaluatedSkills) {
        $levelDistribution[$skill.ExpertiseLevel]++

        # Statistiques par catégorie
        if (-not $categoryStats.ContainsKey($skill.Category)) {
            $categoryStats[$skill.Category] = @{
                Count             = 0
                TotalScore        = 0
                LevelDistribution = @{
                    'Débutant'      = 0
                    'Intermédiaire' = 0
                    'Avancé'        = 0
                    'Expert'        = 0
                }
            }
        }

        $categoryStats[$skill.Category].Count++
        $categoryStats[$skill.Category].TotalScore += $skill.GlobalScore
        $categoryStats[$skill.Category].LevelDistribution[$skill.ExpertiseLevel]++
    }

    # Calcul des moyennes par catégorie
    foreach ($category in $categoryStats.Keys) {
        if ($categoryStats[$category].Count -gt 0) {
            $categoryStats[$category].AverageScore = $categoryStats[$category].TotalScore / $categoryStats[$category].Count
        } else {
            $categoryStats[$category].AverageScore = 0
        }
    }

    # Génération du rapport selon le format spécifié
    switch ($Format) {
        "JSON" {
            # Création de l'objet JSON
            $reportData = @{
                GeneratedAt       = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                TotalSkills       = $EvaluatedSkills.Count
                LevelDistribution = $levelDistribution
                CategoryStats     = $categoryStats
                Skills            = $EvaluatedSkills | ForEach-Object {
                    @{
                        Name           = $_.Name
                        Category       = $_.Category
                        Manager        = $_.Manager
                        Improvement    = $_.Improvement
                        GlobalScore    = [math]::Round($_.GlobalScore, 2)
                        ExpertiseLevel = $_.ExpertiseLevel
                        Justification  = $_.Justification
                        DetailedScores = $_.DetailedScores
                    }
                }
            }

            # Conversion en JSON et écriture dans le fichier
            $reportJson = $reportData | ConvertTo-Json -Depth 10
            Set-Content -Path $OutputPath -Value $reportJson -Encoding UTF8
        }

        "CSV" {
            # Création des lignes CSV
            $csvLines = @()
            $csvLines += "Name,Category,Manager,Improvement,GlobalScore,ExpertiseLevel,Justification"

            foreach ($skill in $EvaluatedSkills) {
                $csvLines += "$($skill.Name),$($skill.Category),$($skill.Manager),$($skill.Improvement),$([math]::Round($skill.GlobalScore, 2)),$($skill.ExpertiseLevel),`"$($skill.Justification -replace '"', '""')`""
            }

            # Écriture dans le fichier
            $csvLines | Out-File -FilePath $OutputPath -Encoding UTF8
        }

        "Markdown" {
            # Génération du rapport Markdown
            $report = @"
# Rapport d'Évaluation des Compétences

## Table des Matières
1. [Méthodologie](#méthodologie)
2. [Résultats d'Évaluation](#résultats-dévaluation)
3. [Distribution des Niveaux](#distribution-des-niveaux)
4. [Analyse par Catégorie](#analyse-par-catégorie)
5. [Recommandations](#recommandations)

## Méthodologie
L'évaluation des compétences est basée sur une analyse détaillée de chaque compétence selon plusieurs critères:
- Complexité technique
- Niveau de supervision requis
- Capacité de résolution de problèmes
- Impact sur le projet

## Résultats d'Évaluation
"@

            # Ajout du tableau des résultats selon le niveau de détail
            switch ($DetailLevel) {
                "Basic" {
                    $report += @"

| Compétence | Catégorie | Niveau d'Expertise |
|------------|-----------|-------------------|
$(($EvaluatedSkills | ForEach-Object {
    "| $($_.Name) | $($_.Category) | $($_.ExpertiseLevel) |"
}) -join "`n")
"@
                }

                "Standard" {
                    $report += @"

| Compétence | Catégorie | Score Global | Niveau d'Expertise | Justification |
|------------|-----------|--------------|-------------------|---------------|
$(($EvaluatedSkills | ForEach-Object {
    "| $($_.Name) | $($_.Category) | $([math]::Round($_.GlobalScore, 2)) | $($_.ExpertiseLevel) | $($_.Justification) |"
}) -join "`n")
"@
                }

                "Detailed" {
                    $report += @"

| Compétence | Catégorie | Manager | Amélioration | Score Global | Niveau d'Expertise | Justification |
|------------|-----------|---------|--------------|--------------|-------------------|---------------|
$(($EvaluatedSkills | ForEach-Object {
    "| $($_.Name) | $($_.Category) | $($_.Manager) | $($_.Improvement) | $([math]::Round($_.GlobalScore, 2)) | $($_.ExpertiseLevel) | $($_.Justification) |"
}) -join "`n")
"@

                    # Ajout des scores détaillés pour chaque compétence
                    $report += "`n`n### Scores Détaillés par Critère`n"

                    foreach ($skill in $EvaluatedSkills) {
                        $report += "`n#### $($skill.Name) ($($skill.Category))`n"
                        $report += "| Critère | Score | Poids | Score Pondéré | Justification |`n"
                        $report += "|---------|-------|-------|---------------|---------------|`n"

                        foreach ($criterionName in $skill.DetailedScores.Keys) {
                            $detailedScore = $skill.DetailedScores[$criterionName]
                            $justification = $skill.CriteriaJustifications[$criterionName]
                            $report += "| $criterionName | $($detailedScore.Score) | $($detailedScore.Weight) | $($detailedScore.WeightedScore) | $justification |`n"
                        }
                    }
                }
            }

            # Ajout de la distribution des niveaux
            $report += @"

## Distribution des Niveaux
- Débutant: $($levelDistribution['Débutant']) compétences ($([math]::Round(($levelDistribution['Débutant'] / $EvaluatedSkills.Count) * 100, 1))%)
- Intermédiaire: $($levelDistribution['Intermédiaire']) compétences ($([math]::Round(($levelDistribution['Intermédiaire'] / $EvaluatedSkills.Count) * 100, 1))%)
- Avancé: $($levelDistribution['Avancé']) compétences ($([math]::Round(($levelDistribution['Avancé'] / $EvaluatedSkills.Count) * 100, 1))%)
- Expert: $($levelDistribution['Expert']) compétences ($([math]::Round(($levelDistribution['Expert'] / $EvaluatedSkills.Count) * 100, 1))%)
"@

            # Ajout de l'analyse par catégorie
            $report += @"

## Analyse par Catégorie
| Catégorie | Nombre de Compétences | Score Moyen | Niveau Prédominant |
|-----------|----------------------|------------|-------------------|
"@

            foreach ($category in $categoryStats.Keys | Sort-Object) {
                $stats = $categoryStats[$category]
                $predominantLevel = $stats.LevelDistribution.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1 -ExpandProperty Key
                $report += "| $category | $($stats.Count) | $([math]::Round($stats.AverageScore, 2)) | $predominantLevel |`n"
            }

            # Ajout des recommandations
            $report += @"

## Recommandations
Basé sur l'évaluation:
- Concentrer la formation sur les compétences de niveau Débutant/Intermédiaire
- Allouer les ressources seniors aux tâches de niveau Expert
- Revoir les compétences avec des scores faibles pour une potentielle automatisation
"@

            # Ajout de recommandations spécifiques par catégorie
            if ($DetailLevel -eq "Detailed") {
                $report += "`n### Recommandations par Catégorie`n"

                foreach ($category in $categoryStats.Keys | Sort-Object) {
                    $stats = $categoryStats[$category]
                    $report += "`n#### $category`n"

                    if ($stats.AverageScore -lt 2.0) {
                        $report += "- **Priorité Haute**: Formation intensive requise pour cette catégorie (score moyen faible)`n"
                    } elseif ($stats.AverageScore -lt 3.0) {
                        $report += "- **Priorité Moyenne**: Formation ciblée recommandée pour cette catégorie`n"
                    } else {
                        $report += "- **Priorité Basse**: Maintenir le niveau d'expertise actuel`n"
                    }

                    $report += "- Nombre de compétences: $($stats.Count)`n"
                    $report += "- Distribution des niveaux: Débutant ($($stats.LevelDistribution['Débutant'])), Intermédiaire ($($stats.LevelDistribution['Intermédiaire'])), Avancé ($($stats.LevelDistribution['Avancé'])), Expert ($($stats.LevelDistribution['Expert']))`n"
                }
            }

            # Écriture dans le fichier
            Set-Content -Path $OutputPath -Value $report -Encoding UTF8
        }
    }

    Write-Verbose "Rapport d'évaluation généré avec succès à: $OutputPath"
}
'@

# Créer un fichier temporaire pour le script
$tempScriptPath = Join-Path $TestDrive "apply-evaluation-matrix.ps1"
Set-Content -Path $tempScriptPath -Value $scriptContent -Encoding UTF8

# Charger le script temporaire
. $tempScriptPath

# Créer les répertoires de test si nécessaires
$testDataPath = Join-Path $TestDrive "data"
New-Item -ItemType Directory -Path $testDataPath -Force | Out-Null

# Créer les fichiers de test
$expertiseLevelsPath = Join-Path $testDataPath "expertise-levels.md"
$skillsListPath = Join-Path $testDataPath "skills-list.md"

# Contenu du fichier des niveaux d'expertise
$expertiseLevelsContent = @"
# Niveaux d'Expertise et Matrice d'Évaluation

Ce document définit les niveaux d'expertise et la matrice d'évaluation utilisés pour évaluer les compétences.

## Niveaux d'Expertise

### Débutant
- Connaissances de base
- Nécessite une supervision constante
- Peut exécuter des tâches simples et routinières
- Peu d'expérience pratique

### Intermédiaire
- Bonnes connaissances théoriques
- Nécessite une supervision occasionnelle
- Peut exécuter des tâches courantes de manière autonome
- Expérience pratique modérée

## Critères d'évaluation

### Complexité Technique

#### Complexité des tâches
Description: Évalue la complexité des tâches associées à la compétence.
Poids: 0.3
Priorité: 2
- Niveau 1: Tâches simples et routinières
- Niveau 2: Tâches courantes avec quelques variations
- Niveau 3: Tâches complexes nécessitant une analyse approfondie
- Niveau 4: Tâches très complexes nécessitant une expertise pointue
"@

# Contenu du fichier des compétences
$skillsListContent = @"
# Liste des Compétences

## <a name='manager1'></a>Manager 1

### Amélioration de la performance

#### Description
Cette amélioration vise à optimiser les performances des applications.

| Catégorie | Compétence | Niveau | Justification |
|-----------|------------|--------|---------------|
| Développement | Optimisation de code | Avancé | Capacité à identifier et résoudre des problèmes de performance complexes nécessitant une analyse approfondie |
| Développement | Profiling | Intermédiaire | Peut exécuter des tâches courantes de manière autonome avec une supervision occasionnelle |
"@

# Écrire les fichiers de test
Set-Content -Path $expertiseLevelsPath -Value $expertiseLevelsContent -Encoding UTF8
Set-Content -Path $skillsListPath -Value $skillsListContent -Encoding UTF8
}

Describe 'Matrice Evaluation Tests' {

    Context 'Validation des paramètres du script' {
        It 'Vérifie les paramètres obligatoires' {
            (Get-Command $PSScriptRoot\..\apply-evaluation-matrix.ps1).Parameters.ContainsKey('ExpertiseLevelsPath') | Should -Be $true
            (Get-Command $PSScriptRoot\..\apply-evaluation-matrix.ps1).Parameters.ContainsKey('SkillsListPath') | Should -Be $true
            (Get-Command $PSScriptRoot\..\apply-evaluation-matrix.ps1).Parameters.ContainsKey('OutputPath') | Should -Be $true
        }

        It 'Vérifie les paramètres optionnels' {
            (Get-Command $PSScriptRoot\..\apply-evaluation-matrix.ps1).Parameters.ContainsKey('Format') | Should -Be $true
            (Get-Command $PSScriptRoot\..\apply-evaluation-matrix.ps1).Parameters.ContainsKey('DetailLevel') | Should -Be $true
            (Get-Command $PSScriptRoot\..\apply-evaluation-matrix.ps1).Parameters.ContainsKey('WeightingMethod') | Should -Be $true
        }
    }

    Context 'Validation des fichiers' {
        It 'Vérifie la création du fichier de sortie' {
            $outputPath = Join-Path $testDataPath "skills-evaluation.md"
            $evaluatedSkills = @(
                [EvaluatedSkill]::new("Test Skill", "Test Category")
            )
            $evaluatedSkills[0].GlobalScore = 2.5
            $evaluatedSkills[0].ExpertiseLevel = "Intermédiaire"
            $evaluatedSkills[0].Justification = "Test justification"

            New-EvaluationReport -EvaluatedSkills $evaluatedSkills -OutputPath $outputPath -Format "Markdown" -DetailLevel "Standard"
            Test-Path $outputPath | Should -Be $true
        }
    }

    Context 'Extraction des critères' {

        It 'Extrait correctement les critères' {
            $criteria = Get-EvaluationCriteria -FilePath $expertiseLevelsPath -WeightingMethod "Custom"
            $criteria.Count | Should -BeGreaterThan 0
            $criteria[0].Name | Should -Be 'Complexité des tâches'
            $criteria[0].Category | Should -Be 'Complexité Technique'
            $criteria[0].Weight | Should -Be 0.3
            $criteria[0].Priority | Should -Be 2
            $criteria[0].Levels.Count | Should -Be 4
            $criteria[0].Levels['Niveau 1'] | Should -Be 'Tâches simples et routinières'
        }
    }

    Context 'Extraction des compétences' {

        It 'Extrait correctement les compétences' {
            $skills = Get-SkillsList -FilePath $skillsListPath
            $skills.Count | Should -BeGreaterThan 0
            $skills[0].Name | Should -Be 'Optimisation de code'
            $skills[0].Category | Should -Be 'Développement'
            $skills[0].Manager | Should -Be 'Manager 1'
            $skills[0].Improvement | Should -Be 'Amélioration de la performance'
            $skills[0].Justification | Should -Be 'Capacité à identifier et résoudre des problèmes de performance complexes nécessitant une analyse approfondie'
        }
    }

    Context 'Évaluation des compétences' {
        It 'Calcule correctement le score global' {
            $skill = [EvaluatedSkill]::new("Test Skill", "Test Category")
            $skill.Justification = "Tâches complexes nécessitant une analyse approfondie"

            $criterion = [EvaluationCriterion]::new()
            $criterion.Name = "Complexité des tâches"
            $criterion.Category = "Complexité Technique"
            $criterion.Weight = 0.3
            $criterion.Priority = 2
            $criterion.Levels = @{
                "Niveau 1" = "Tâches simples et routinières"
                "Niveau 2" = "Tâches courantes avec quelques variations"
                "Niveau 3" = "Tâches complexes nécessitant une analyse approfondie"
                "Niveau 4" = "Tâches très complexes nécessitant une expertise pointue"
            }

            $criteria = @($criterion)

            $evaluatedSkill = Test-Skill -Skill $skill -Criteria $criteria -WeightingMethod "Equal" -DetailLevel "Standard"
            $evaluatedSkill | Should -Not -BeNullOrEmpty
            $evaluatedSkill.Scores["Complexité des tâches"] | Should -Be 3
            $evaluatedSkill.GlobalScore | Should -Be 3
            $evaluatedSkill.ExpertiseLevel | Should -Be "Avancé"
        }
    }

    Context 'Génération du rapport' {
        It 'Génère correctement le rapport Markdown' {
            $outputPath = Join-Path $testDataPath "skills-evaluation.md"
            $skill = [EvaluatedSkill]::new("Test Skill", "Test Category")
            $skill.Manager = "Manager 1"
            $skill.Improvement = "Amélioration de la performance"
            $skill.GlobalScore = 3
            $skill.ExpertiseLevel = "Avancé"
            $skill.Justification = "Tâches complexes nécessitant une analyse approfondie"
            $skill.Scores = @{ "Complexité des tâches" = 3 }
            $skill.DetailedScores = @{
                "Complexité des tâches" = @{
                    "Score"         = 3
                    "Weight"        = 1
                    "WeightedScore" = 3
                }
            }
            $skill.CriteriaJustifications = @{
                "Complexité des tâches" = "Correspondance exacte avec le niveau 3 : Tâches complexes nécessitant une analyse approfondie"
            }

            $evaluatedSkills = @($skill)

            New-EvaluationReport -EvaluatedSkills $evaluatedSkills -OutputPath $outputPath -Format "Markdown" -DetailLevel "Detailed"
            $content = Get-Content $outputPath -Raw

            $content | Should -Match "# Rapport d'Évaluation des Compétences"
            $content | Should -Match "## Table des Matières"
            $content | Should -Match "## Méthodologie"
            $content | Should -Match "## Résultats d'Évaluation"
            $content | Should -Match "## Distribution des Niveaux"
            $content | Should -Match "## Analyse par Catégorie"
            $content | Should -Match "## Recommandations"
            $content | Should -Match "\| Compétence \| Catégorie \| Manager \| Amélioration \| Score Global \| Niveau d'Expertise \| Justification \|"
            $content | Should -Match "\| Test Skill \| Test Category \| Manager 1 \| Amélioration de la performance \| 3 \| Avancé \| Tâches complexes nécessitant une analyse approfondie \|"
        }

        It 'Génère correctement le rapport CSV' {
            $outputPath = Join-Path $testDataPath "skills-evaluation.csv"
            $skill = [EvaluatedSkill]::new("Test Skill", "Test Category")
            $skill.Manager = "Manager 1"
            $skill.Improvement = "Amélioration de la performance"
            $skill.GlobalScore = 3
            $skill.ExpertiseLevel = "Avancé"
            $skill.Justification = "Tâches complexes nécessitant une analyse approfondie"

            $evaluatedSkills = @($skill)

            New-EvaluationReport -EvaluatedSkills $evaluatedSkills -OutputPath $outputPath -Format "CSV" -DetailLevel "Standard"
            $content = Get-Content $outputPath -Raw

            $content | Should -Match "Name,Category,Manager,Improvement,GlobalScore,ExpertiseLevel,Justification"
            $content | Should -Match "Test Skill,Test Category,Manager 1,Amélioration de la performance,3,Avancé,""Tâches complexes nécessitant une analyse approfondie"""
        }

        It 'Génère correctement le rapport JSON' {
            $outputPath = Join-Path $testDataPath "skills-evaluation.json"
            $skill = [EvaluatedSkill]::new("Test Skill", "Test Category")
            $skill.Manager = "Manager 1"
            $skill.Improvement = "Amélioration de la performance"
            $skill.GlobalScore = 3
            $skill.ExpertiseLevel = "Avancé"
            $skill.Justification = "Tâches complexes nécessitant une analyse approfondie"

            $evaluatedSkills = @($skill)

            New-EvaluationReport -EvaluatedSkills $evaluatedSkills -OutputPath $outputPath -Format "JSON" -DetailLevel "Standard"
            $content = Get-Content $outputPath -Raw

            $content | Should -Match '"Name": "Test Skill"'
            $content | Should -Match '"Category": "Test Category"'
            $content | Should -Match '"Manager": "Manager 1"'
            $content | Should -Match '"Improvement": "Amélioration de la performance"'
            $content | Should -Match '"GlobalScore": 3'
            $content | Should -Match '"ExpertiseLevel": "Avancé"'
            $content | Should -Match '"Justification": "Tâches complexes nécessitant une analyse approfondie"'
        }
    }
}

