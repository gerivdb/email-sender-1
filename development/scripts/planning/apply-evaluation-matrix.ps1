# Définir l'encodage UTF-8 pour les caractères accentués
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

<#
.SYNOPSIS
    Applique la matrice d'évaluation des compétences pour déterminer le niveau d'expertise requis.

.DESCRIPTION
    Ce script analyse les compétences identifiées et applique la matrice d'évaluation
    définie dans le document des niveaux d'expertise pour déterminer le niveau d'expertise
    requis pour chaque compétence. Il génère ensuite un rapport détaillé des résultats.

.PARAMETER ExpertiseLevelsPath
    Chemin vers le fichier contenant la définition des niveaux d'expertise et la matrice d'évaluation.
    Par défaut : "..\..\..\data\planning\expertise-levels.md"

.PARAMETER SkillsListPath
    Chemin vers le fichier contenant la liste des compétences à évaluer.
    Par défaut : "..\..\..\data\planning\skills-list.md"

.PARAMETER OutputPath
    Chemin vers le fichier de sortie pour le rapport d'évaluation des compétences.
    Par défaut : "..\..\..\data\planning\skills-evaluation.md"

.PARAMETER Format
    Format du rapport de sortie. Les valeurs possibles sont : JSON, CSV, Markdown.
    Par défaut : Markdown

.PARAMETER DetailLevel
    Niveau de détail du rapport. Les valeurs possibles sont : Basic, Standard, Detailed.
    Par défaut : Standard

.PARAMETER WeightingMethod
    Méthode de pondération des critères. Les valeurs possibles sont : Equal, Custom, Adaptive.
    Par défaut : Equal

.EXAMPLE
    .\apply-evaluation-matrix.ps1
    Applique la matrice d'évaluation avec les paramètres par défaut.

.EXAMPLE
    .\apply-evaluation-matrix.ps1 -ExpertiseLevelsPath "data\expertise-levels.md" -SkillsListPath "data\skills-list.md" -OutputPath "data\skills-evaluation.md" -Format "JSON" -DetailLevel "Detailed"
    Applique la matrice d'évaluation avec des chemins personnalisés et génère un rapport JSON détaillé.

.NOTES
    Auteur: Planning Team
    Version: 1.0
    Date de création: 2025-05-10
#>

param(
    [string]$ExpertiseLevelsPath,
    [string]$SkillsListPath,
    [string]$OutputPath,
    [string]$Format,
    [string]$DetailLevel,
    [string]$WeightingMethod
)

# Définir les valeurs par défaut si les paramètres ne sont pas spécifiés
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$dataPath = Join-Path (Split-Path -Parent (Split-Path -Parent $scriptPath)) "data\planning"

if (-not $ExpertiseLevelsPath) { $ExpertiseLevelsPath = Join-Path $dataPath "expertise-levels.md" }
if (-not $SkillsListPath) { $SkillsListPath = Join-Path $dataPath "skills-list.md" }
if (-not $OutputPath) { $OutputPath = Join-Path $dataPath "skills-evaluation.md" }
if (-not $Format) { $Format = "Markdown" }
if (-not $DetailLevel) { $DetailLevel = "Standard" }
if (-not $WeightingMethod) { $WeightingMethod = "Equal" }

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
    param(
        [string]$FilePath,
        [string]$WeightingMethod = "Equal"
    )

    Write-Host "Extraction des critères d'évaluation depuis $FilePath"

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
    $categoryPattern = '(?ms)### ([^
]+)\r?\n((?:(?!###)[^\r\n]+\r?\n?)+)'
    $categoryMatches = [regex]::Matches($criteriaSection, $categoryPattern)

    foreach ($categoryMatch in $categoryMatches) {
        $category = $categoryMatch.Groups[1].Value.Trim()
        $categoryContent = $categoryMatch.Groups[2].Value

        # Extraction des critères individuels
        $criterionPattern = '#### ([^
]+)\r?\n((?:(?!####)[^\r\n]+\r?\n?)+)'
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

    Write-Host "$($criteria.Count) critères d'évaluation extraits."

    return $criteria
}

# Fonction pour lire et parser les compétences à partir du fichier de la liste des compétences
function Get-SkillsList {
    param(
        [string]$FilePath
    )

    Write-Host "Extraction des compétences depuis $FilePath"

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

    Write-Host "$($skills.Count) compétences extraites."

    return $skills
}

# Fonction pour évaluer une compétence selon les critères définis
function Evaluate-Skill {
    param(
        [EvaluatedSkill]$Skill,
        [array]$Criteria,
        [string]$WeightingMethod = "Equal",
        [string]$DetailLevel = "Standard"
    )

    Write-Host "Évaluation de la compétence '$($Skill.Name)' dans la catégorie '$($Skill.Category)'"

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

    Write-Host "Compétence '$($Skill.Name)' évaluée avec un score global de $([math]::Round($Skill.GlobalScore, 2)) ($($Skill.ExpertiseLevel))"

    return $Skill
}

# Fonction pour générer le rapport d'évaluation des compétences
function New-EvaluationReport {
    param(
        [array]$EvaluatedSkills,
        [string]$OutputPath,
        [string]$Format = "Markdown",
        [string]$DetailLevel = "Standard"
    )

    Write-Host "Génération du rapport d'évaluation au format $Format avec niveau de détail $DetailLevel"

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
                        $report += "- **Priorité Haute**: Formation intensive requise pour cette catégorie (score moyen faible)\n"
                    } elseif ($stats.AverageScore -lt 3.0) {
                        $report += "- **Priorité Moyenne**: Formation ciblée recommandée pour cette catégorie\n"
                    } else {
                        $report += "- **Priorité Basse**: Maintenir le niveau d'expertise actuel\n"
                    }

                    $report += "- Nombre de compétences: $($stats.Count)\n"
                    $report += "- Distribution des niveaux: Débutant ($($stats.LevelDistribution['Débutant'])), Intermédiaire ($($stats.LevelDistribution['Intermédiaire'])), Avancé ($($stats.LevelDistribution['Avancé'])), Expert ($($stats.LevelDistribution['Expert']))\n"
                }
            }

            # Écriture dans le fichier
            Set-Content -Path $OutputPath -Value $report -Encoding UTF8
        }
    }

    Write-Host "Rapport d'évaluation généré avec succès à: $OutputPath"
}

# Exécution principale
try {
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
        throw "Fichier des niveaux d'expertise non trouvé: $ExpertiseLevelsPath"
    }

    if (-not (Test-Path $SkillsListPath)) {
        throw "Fichier des compétences non trouvé: $SkillsListPath"
    }

    # Créer le répertoire de sortie s'il n'existe pas
    $outputDir = Split-Path -Path $OutputPath -Parent
    if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path -Path $outputDir)) {
        Write-Host "Création du répertoire de sortie: $outputDir"
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }

    # Extraction des critères d'évaluation
    Write-Host "Extraction des critères d'évaluation..."
    $criteria = Get-EvaluationCriteria -FilePath $ExpertiseLevelsPath -WeightingMethod $WeightingMethod
    Write-Host "$($criteria.Count) critères d'évaluation extraits."

    # Extraction des compétences
    Write-Host "Extraction des compétences..."
    $skills = Get-SkillsList -FilePath $SkillsListPath
    Write-Host "$($skills.Count) compétences extraites."

    # Évaluation des compétences
    Write-Host "Évaluation des compétences..."
    $evaluatedSkills = @()

    for ($i = 0; $i -lt $skills.Count; $i++) {
        $skill = $skills[$i]
        Write-Host "Évaluation de la compétence $($i+1)/$($skills.Count): $($skill.Name)"

        $evaluatedSkill = Evaluate-Skill -Skill $skill -Criteria $criteria -WeightingMethod $WeightingMethod -DetailLevel $DetailLevel
        $evaluatedSkills += $evaluatedSkill
    }

    Write-Host "Évaluation terminée. $($evaluatedSkills.Count) compétences évaluées."

    # Génération du rapport
    Write-Host "Génération du rapport..."
    New-EvaluationReport -EvaluatedSkills $evaluatedSkills -OutputPath $OutputPath -Format $Format -DetailLevel $DetailLevel

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
    Write-Host "  Distribution des niveaux d'expertise :"
    Write-Host "    - Débutant      : $($levelDistribution['Débutant']) ($([math]::Round(($levelDistribution['Débutant'] / $evaluatedSkills.Count) * 100, 1))%)"
    Write-Host "    - Intermédiaire : $($levelDistribution['Intermédiaire']) ($([math]::Round(($levelDistribution['Intermédiaire'] / $evaluatedSkills.Count) * 100, 1))%)"
    Write-Host "    - Avancé        : $($levelDistribution['Avancé']) ($([math]::Round(($levelDistribution['Avancé'] / $evaluatedSkills.Count) * 100, 1))%)"
    Write-Host "    - Expert        : $($levelDistribution['Expert']) ($([math]::Round(($levelDistribution['Expert'] / $evaluatedSkills.Count) * 100, 1))%)"
    Write-Host "  Rapport généré à : $OutputPath"

    # Retourner un code de succès
    return 0
} catch {
    Write-Error "Erreur lors de l'application de la matrice d'évaluation : $_"

    # Afficher la pile d'appels pour faciliter le débogage
    Write-Host "Pile d'appels :"
    Write-Host $_.ScriptStackTrace

    # Retourner un code d'erreur
    exit 1
}
