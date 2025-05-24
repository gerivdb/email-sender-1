# DÃ©finir l'encodage UTF-8 pour les caractÃ¨res accentuÃ©s
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

<#
.SYNOPSIS
    Applique la matrice d'Ã©valuation des compÃ©tences pour dÃ©terminer le niveau d'expertise requis.

.DESCRIPTION
    Ce script analyse les compÃ©tences identifiÃ©es et applique la matrice d'Ã©valuation
    dÃ©finie dans le document des niveaux d'expertise pour dÃ©terminer le niveau d'expertise
    requis pour chaque compÃ©tence. Il gÃ©nÃ¨re ensuite un rapport dÃ©taillÃ© des rÃ©sultats.

.PARAMETER ExpertiseLevelsPath
    Chemin vers le fichier contenant la dÃ©finition des niveaux d'expertise et la matrice d'Ã©valuation.
    Par dÃ©faut : "..\..\..\data\planning\expertise-levels.md"

.PARAMETER SkillsListPath
    Chemin vers le fichier contenant la liste des compÃ©tences Ã  Ã©valuer.
    Par dÃ©faut : "..\..\..\data\planning\skills-list.md"

.PARAMETER OutputPath
    Chemin vers le fichier de sortie pour le rapport d'Ã©valuation des compÃ©tences.
    Par dÃ©faut : "..\..\..\data\planning\skills-evaluation.md"

.PARAMETER Format
    Format du rapport de sortie. Les valeurs possibles sont : JSON, CSV, Markdown.
    Par dÃ©faut : Markdown

.PARAMETER DetailLevel
    Niveau de dÃ©tail du rapport. Les valeurs possibles sont : Basic, Standard, Detailed.
    Par dÃ©faut : Standard

.PARAMETER WeightingMethod
    MÃ©thode de pondÃ©ration des critÃ¨res. Les valeurs possibles sont : Equal, Custom, Adaptive.
    Par dÃ©faut : Equal

.EXAMPLE
    .\apply-evaluation-matrix.ps1
    Applique la matrice d'Ã©valuation avec les paramÃ¨tres par dÃ©faut.

.EXAMPLE
    .\apply-evaluation-matrix.ps1 -ExpertiseLevelsPath "data\expertise-levels.md" -SkillsListPath "data\skills-list.md" -OutputPath "data\skills-evaluation.md" -Format "JSON" -DetailLevel "Detailed"
    Applique la matrice d'Ã©valuation avec des chemins personnalisÃ©s et gÃ©nÃ¨re un rapport JSON dÃ©taillÃ©.

.NOTES
    Auteur: Planning Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-10
#>

param(
    [string]$ExpertiseLevelsPath,
    [string]$SkillsListPath,
    [string]$OutputPath,
    [string]$Format,
    [string]$DetailLevel,
    [string]$WeightingMethod
)

# DÃ©finir les valeurs par dÃ©faut si les paramÃ¨tres ne sont pas spÃ©cifiÃ©s
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$dataPath = Join-Path (Split-Path -Parent (Split-Path -Parent $scriptPath)) "data\planning"

if (-not $ExpertiseLevelsPath) { $ExpertiseLevelsPath = Join-Path $dataPath "expertise-levels.md" }
if (-not $SkillsListPath) { $SkillsListPath = Join-Path $dataPath "skills-list.md" }
if (-not $OutputPath) { $OutputPath = Join-Path $dataPath "skills-evaluation.md" }
if (-not $Format) { $Format = "Markdown" }
if (-not $DetailLevel) { $DetailLevel = "Standard" }
if (-not $WeightingMethod) { $WeightingMethod = "Equal" }

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

                # Appliquer la mÃ©thode de pondÃ©ration
                switch ($WeightingMethod) {
                    "Equal" {
                        $criterionWeight = 1.0
                    }
                    "Custom" {
                        $criterionWeight = $criterion.Weight
                    }
                    "Adaptive" {
                        # PondÃ©ration adaptative basÃ©e sur la prioritÃ© du critÃ¨re
                        $criterionWeight = $criterion.Weight * $criterion.Priority
                    }
                    default {
                        $criterionWeight = 1.0
                    }
                }

                $totalScore += $score * $criterionWeight
                $totalWeight += $criterionWeight

                # Stocker le score dÃ©taillÃ©
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

        # DÃ©termination du niveau d'expertise
        $this.ExpertiseLevel = switch ($this.GlobalScore) {
            { $_ -le 1.5 } { 'DÃ©butant' }
            { $_ -le 2.5 } { 'IntermÃ©diaire' }
            { $_ -le 3.5 } { 'AvancÃ©' }
            default { 'Expert' }
        }
    }
}

# Fonction pour extraire les critÃ¨res d'Ã©valuation du document des niveaux d'expertise
function Get-EvaluationCriteria {
    param(
        [string]$FilePath,
        [string]$WeightingMethod = "Equal"
    )

    Write-Host "Extraction des critÃ¨res d'Ã©valuation depuis $FilePath"

    # VÃ©rifier que le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        throw "Le fichier des niveaux d'expertise n'existe pas : $FilePath"
    }

    $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
    $criteria = @()

    # Extraction des sections de critÃ¨res
    $criteriaPattern = '(?ms)## CritÃ¨res d''Ã©valuation\r?\n(.*?)(?=##|\z)'
    $criteriaSection = [regex]::Match($content, $criteriaPattern).Groups[1].Value

    if ([string]::IsNullOrEmpty($criteriaSection)) {
        Write-Warning "Aucune section 'CritÃ¨res d'Ã©valuation' trouvÃ©e dans le fichier."
        return $criteria
    }

    # Extraction des catÃ©gories de critÃ¨res
    $categoryPattern = '(?ms)### ([^
]+)\r?\n((?:(?!###)[^\r\n]+\r?\n?)+)'
    $categoryMatches = [regex]::Matches($criteriaSection, $categoryPattern)

    foreach ($categoryMatch in $categoryMatches) {
        $category = $categoryMatch.Groups[1].Value.Trim()
        $categoryContent = $categoryMatch.Groups[2].Value

        # Extraction des critÃ¨res individuels
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
            } elseif ($WeightingMethod -eq "Adaptive") {
                # La pondÃ©ration adaptative sera appliquÃ©e lors de l'Ã©valuation
            }

            $criteria += $criterion
        }
    }

    Write-Host "$($criteria.Count) critÃ¨res d'Ã©valuation extraits."

    return $criteria
}

# Fonction pour lire et parser les compÃ©tences Ã  partir du fichier de la liste des compÃ©tences
function Get-SkillsList {
    param(
        [string]$FilePath
    )

    Write-Host "Extraction des compÃ©tences depuis $FilePath"

    # VÃ©rifier que le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        throw "Le fichier de la liste des compÃ©tences n'existe pas : $FilePath"
    }

    $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
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

    # Si aucun gestionnaire n'est trouvÃ©, essayer le format alternatif
    if ($skills.Count -eq 0) {
        # Pattern pour extraire les catÃ©gories et compÃ©tences (format alternatif)
        $categoryPattern = '(?ms)## ([^\r\n]+)\r?\n((?:### [^\r\n]+\r?\n(?:(?!##)[^\r\n]+\r?\n)*)+)'
        $categoryMatches = [regex]::Matches($content, $categoryPattern)

        foreach ($categoryMatch in $categoryMatches) {
            $category = $categoryMatch.Groups[1].Value.Trim()

            # Pattern pour extraire les compÃ©tences individuelles
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

    Write-Host "$($skills.Count) compÃ©tences extraites."

    return $skills
}

# Fonction pour Ã©valuer une compÃ©tence selon les critÃ¨res dÃ©finis
function Test-Skill {
    param(
        [EvaluatedSkill]$Skill,
        [array]$Criteria,
        [string]$WeightingMethod = "Equal",
        [string]$DetailLevel = "Standard"
    )

    Write-Host "Ã‰valuation de la compÃ©tence '$($Skill.Name)' dans la catÃ©gorie '$($Skill.Category)'"

    foreach ($criterion in $Criteria) {
        # Analyse de la justification pour dÃ©terminer le niveau
        $score = 1 # Niveau par dÃ©faut
        $justification = ""

        # Recherche des mots-clÃ©s dans la justification
        foreach ($level in $criterion.Levels.Keys | Sort-Object) {
            $levelNumber = [int]($level -replace 'Niveau ', '')
            $description = $criterion.Levels[$level]

            # VÃ©rifier si la description du niveau est prÃ©sente dans la justification
            if ($Skill.Justification -match [regex]::Escape($description)) {
                $score = $levelNumber
                $justification = "Correspondance exacte avec le niveau $levelNumber : $description"
                break
            }

            # Recherche de mots-clÃ©s
            $keywords = $description -split ',' | ForEach-Object { $_.Trim() }
            $matchCount = 0
            $matchedKeywords = @()

            foreach ($keyword in $keywords) {
                if ($Skill.Justification -match [regex]::Escape($keyword)) {
                    $matchCount++
                    $matchedKeywords += $keyword
                }
            }

            # Si plus de 50% des mots-clÃ©s correspondent, utiliser ce niveau
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

    # Calculer le score global en fonction de la mÃ©thode de pondÃ©ration
    $Skill.CalculateGlobalScore($Criteria, $WeightingMethod)

    # Ajouter des dÃ©tails supplÃ©mentaires en fonction du niveau de dÃ©tail
    if ($DetailLevel -eq "Detailed") {
        # Ajouter des analyses supplÃ©mentaires ici
        $Skill.CriteriaJustifications["GlobalAnalysis"] = "Analyse dÃ©taillÃ©e de la compÃ©tence '$($Skill.Name)' : Score global de $([math]::Round($Skill.GlobalScore, 2)) correspondant au niveau '$($Skill.ExpertiseLevel)'."
    }

    Write-Host "CompÃ©tence '$($Skill.Name)' Ã©valuÃ©e avec un score global de $([math]::Round($Skill.GlobalScore, 2)) ($($Skill.ExpertiseLevel))"

    return $Skill
}

# Fonction pour gÃ©nÃ©rer le rapport d'Ã©valuation des compÃ©tences
function New-EvaluationReport {
    param(
        [array]$EvaluatedSkills,
        [string]$OutputPath,
        [string]$Format = "Markdown",
        [string]$DetailLevel = "Standard"
    )

    Write-Host "GÃ©nÃ©ration du rapport d'Ã©valuation au format $Format avec niveau de dÃ©tail $DetailLevel"

    # Calcul de la distribution des niveaux
    $levelDistribution = @{
        'DÃ©butant'      = 0
        'IntermÃ©diaire' = 0
        'AvancÃ©'        = 0
        'Expert'        = 0
    }

    # Calcul des statistiques par catÃ©gorie
    $categoryStats = @{}

    foreach ($skill in $EvaluatedSkills) {
        $levelDistribution[$skill.ExpertiseLevel]++

        # Statistiques par catÃ©gorie
        if (-not $categoryStats.ContainsKey($skill.Category)) {
            $categoryStats[$skill.Category] = @{
                Count             = 0
                TotalScore        = 0
                LevelDistribution = @{
                    'DÃ©butant'      = 0
                    'IntermÃ©diaire' = 0
                    'AvancÃ©'        = 0
                    'Expert'        = 0
                }
            }
        }

        $categoryStats[$skill.Category].Count++
        $categoryStats[$skill.Category].TotalScore += $skill.GlobalScore
        $categoryStats[$skill.Category].LevelDistribution[$skill.ExpertiseLevel]++
    }

    # Calcul des moyennes par catÃ©gorie
    foreach ($category in $categoryStats.Keys) {
        if ($categoryStats[$category].Count -gt 0) {
            $categoryStats[$category].AverageScore = $categoryStats[$category].TotalScore / $categoryStats[$category].Count
        } else {
            $categoryStats[$category].AverageScore = 0
        }
    }

    # GÃ©nÃ©ration du rapport selon le format spÃ©cifiÃ©
    switch ($Format) {
        "JSON" {
            # CrÃ©ation de l'objet JSON
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

            # Conversion en JSON et Ã©criture dans le fichier
            $reportJson = $reportData | ConvertTo-Json -Depth 10
            Set-Content -Path $OutputPath -Value $reportJson -Encoding UTF8
        }

        "CSV" {
            # CrÃ©ation des lignes CSV
            $csvLines = @()
            $csvLines += "Name,Category,Manager,Improvement,GlobalScore,ExpertiseLevel,Justification"

            foreach ($skill in $EvaluatedSkills) {
                $csvLines += "$($skill.Name),$($skill.Category),$($skill.Manager),$($skill.Improvement),$([math]::Round($skill.GlobalScore, 2)),$($skill.ExpertiseLevel),`"$($skill.Justification -replace '"', '""')`""
            }

            # Ã‰criture dans le fichier
            $csvLines | Out-File -FilePath $OutputPath -Encoding UTF8
        }

        "Markdown" {
            # GÃ©nÃ©ration du rapport Markdown
            $report = @"
# Rapport d'Ã‰valuation des CompÃ©tences

## Table des MatiÃ¨res
1. [MÃ©thodologie](#mÃ©thodologie)
2. [RÃ©sultats d'Ã‰valuation](#rÃ©sultats-dÃ©valuation)
3. [Distribution des Niveaux](#distribution-des-niveaux)
4. [Analyse par CatÃ©gorie](#analyse-par-catÃ©gorie)
5. [Recommandations](#recommandations)

## MÃ©thodologie
L'Ã©valuation des compÃ©tences est basÃ©e sur une analyse dÃ©taillÃ©e de chaque compÃ©tence selon plusieurs critÃ¨res:
- ComplexitÃ© technique
- Niveau de supervision requis
- CapacitÃ© de rÃ©solution de problÃ¨mes
- Impact sur le projet

## RÃ©sultats d'Ã‰valuation
"@

            # Ajout du tableau des rÃ©sultats selon le niveau de dÃ©tail
            switch ($DetailLevel) {
                "Basic" {
                    $report += @"
| CompÃ©tence | CatÃ©gorie | Niveau d'Expertise |
|------------|-----------|-------------------|
$(($EvaluatedSkills | ForEach-Object {
    "| $($_.Name) | $($_.Category) | $($_.ExpertiseLevel) |"
}) -join "`n")
"@
                }

                "Standard" {
                    $report += @"
| CompÃ©tence | CatÃ©gorie | Score Global | Niveau d'Expertise | Justification |
|------------|-----------|--------------|-------------------|---------------|
$(($EvaluatedSkills | ForEach-Object {
    "| $($_.Name) | $($_.Category) | $([math]::Round($_.GlobalScore, 2)) | $($_.ExpertiseLevel) | $($_.Justification) |"
}) -join "`n")
"@
                }

                "Detailed" {
                    $report += @"
| CompÃ©tence | CatÃ©gorie | Manager | AmÃ©lioration | Score Global | Niveau d'Expertise | Justification |
|------------|-----------|---------|--------------|--------------|-------------------|---------------|
$(($EvaluatedSkills | ForEach-Object {
    "| $($_.Name) | $($_.Category) | $($_.Manager) | $($_.Improvement) | $([math]::Round($_.GlobalScore, 2)) | $($_.ExpertiseLevel) | $($_.Justification) |"
}) -join "`n")
"@

                    # Ajout des scores dÃ©taillÃ©s pour chaque compÃ©tence
                    $report += "`n`n### Scores DÃ©taillÃ©s par CritÃ¨re`n"

                    foreach ($skill in $EvaluatedSkills) {
                        $report += "`n#### $($skill.Name) ($($skill.Category))`n"
                        $report += "| CritÃ¨re | Score | Poids | Score PondÃ©rÃ© | Justification |`n"
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
- DÃ©butant: $($levelDistribution['DÃ©butant']) compÃ©tences ($([math]::Round(($levelDistribution['DÃ©butant'] / $EvaluatedSkills.Count) * 100, 1))%)
- IntermÃ©diaire: $($levelDistribution['IntermÃ©diaire']) compÃ©tences ($([math]::Round(($levelDistribution['IntermÃ©diaire'] / $EvaluatedSkills.Count) * 100, 1))%)
- AvancÃ©: $($levelDistribution['AvancÃ©']) compÃ©tences ($([math]::Round(($levelDistribution['AvancÃ©'] / $EvaluatedSkills.Count) * 100, 1))%)
- Expert: $($levelDistribution['Expert']) compÃ©tences ($([math]::Round(($levelDistribution['Expert'] / $EvaluatedSkills.Count) * 100, 1))%)
"@

            # Ajout de l'analyse par catÃ©gorie
            $report += @"

## Analyse par CatÃ©gorie
| CatÃ©gorie | Nombre de CompÃ©tences | Score Moyen | Niveau PrÃ©dominant |
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
BasÃ© sur l'Ã©valuation:
- Concentrer la formation sur les compÃ©tences de niveau DÃ©butant/IntermÃ©diaire
- Allouer les ressources seniors aux tÃ¢ches de niveau Expert
- Revoir les compÃ©tences avec des scores faibles pour une potentielle automatisation
"@

            # Ajout de recommandations spÃ©cifiques par catÃ©gorie
            if ($DetailLevel -eq "Detailed") {
                $report += "`n### Recommandations par CatÃ©gorie`n"

                foreach ($category in $categoryStats.Keys | Sort-Object) {
                    $stats = $categoryStats[$category]
                    $report += "`n#### $category`n"

                    if ($stats.AverageScore -lt 2.0) {
                        $report += "- **PrioritÃ© Haute**: Formation intensive requise pour cette catÃ©gorie (score moyen faible)\n"
                    } elseif ($stats.AverageScore -lt 3.0) {
                        $report += "- **PrioritÃ© Moyenne**: Formation ciblÃ©e recommandÃ©e pour cette catÃ©gorie\n"
                    } else {
                        $report += "- **PrioritÃ© Basse**: Maintenir le niveau d'expertise actuel\n"
                    }

                    $report += "- Nombre de compÃ©tences: $($stats.Count)\n"
                    $report += "- Distribution des niveaux: DÃ©butant ($($stats.LevelDistribution['DÃ©butant'])), IntermÃ©diaire ($($stats.LevelDistribution['IntermÃ©diaire'])), AvancÃ© ($($stats.LevelDistribution['AvancÃ©'])), Expert ($($stats.LevelDistribution['Expert']))\n"
                }
            }

            # Ã‰criture dans le fichier
            Set-Content -Path $OutputPath -Value $report -Encoding UTF8
        }
    }

    Write-Host "Rapport d'Ã©valuation gÃ©nÃ©rÃ© avec succÃ¨s Ã : $OutputPath"
}

# ExÃ©cution principale
try {
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
        throw "Fichier des niveaux d'expertise non trouvÃ©: $ExpertiseLevelsPath"
    }

    if (-not (Test-Path $SkillsListPath)) {
        throw "Fichier des compÃ©tences non trouvÃ©: $SkillsListPath"
    }

    # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
    $outputDir = Split-Path -Path $OutputPath -Parent
    if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path -Path $outputDir)) {
        Write-Host "CrÃ©ation du rÃ©pertoire de sortie: $outputDir"
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }

    # Extraction des critÃ¨res d'Ã©valuation
    Write-Host "Extraction des critÃ¨res d'Ã©valuation..."
    $criteria = Get-EvaluationCriteria -FilePath $ExpertiseLevelsPath -WeightingMethod $WeightingMethod
    Write-Host "$($criteria.Count) critÃ¨res d'Ã©valuation extraits."

    # Extraction des compÃ©tences
    Write-Host "Extraction des compÃ©tences..."
    $skills = Get-SkillsList -FilePath $SkillsListPath
    Write-Host "$($skills.Count) compÃ©tences extraites."

    # Ã‰valuation des compÃ©tences
    Write-Host "Ã‰valuation des compÃ©tences..."
    $evaluatedSkills = @()

    for ($i = 0; $i -lt $skills.Count; $i++) {
        $skill = $skills[$i]
        Write-Host "Ã‰valuation de la compÃ©tence $($i+1)/$($skills.Count): $($skill.Name)"

        $evaluatedSkill = Test-Skill -Skill $skill -Criteria $criteria -WeightingMethod $WeightingMethod -DetailLevel $DetailLevel
        $evaluatedSkills += $evaluatedSkill
    }

    Write-Host "Ã‰valuation terminÃ©e. $($evaluatedSkills.Count) compÃ©tences Ã©valuÃ©es."

    # GÃ©nÃ©ration du rapport
    Write-Host "GÃ©nÃ©ration du rapport..."
    New-EvaluationReport -EvaluatedSkills $evaluatedSkills -OutputPath $OutputPath -Format $Format -DetailLevel $DetailLevel

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
    Write-Host "  Distribution des niveaux d'expertise :"
    Write-Host "    - DÃ©butant      : $($levelDistribution['DÃ©butant']) ($([math]::Round(($levelDistribution['DÃ©butant'] / $evaluatedSkills.Count) * 100, 1))%)"
    Write-Host "    - IntermÃ©diaire : $($levelDistribution['IntermÃ©diaire']) ($([math]::Round(($levelDistribution['IntermÃ©diaire'] / $evaluatedSkills.Count) * 100, 1))%)"
    Write-Host "    - AvancÃ©        : $($levelDistribution['AvancÃ©']) ($([math]::Round(($levelDistribution['AvancÃ©'] / $evaluatedSkills.Count) * 100, 1))%)"
    Write-Host "    - Expert        : $($levelDistribution['Expert']) ($([math]::Round(($levelDistribution['Expert'] / $evaluatedSkills.Count) * 100, 1))%)"
    Write-Host "  Rapport gÃ©nÃ©rÃ© Ã  : $OutputPath"

    # Retourner un code de succÃ¨s
    return 0
} catch {
    Write-Error "Erreur lors de l'application de la matrice d'Ã©valuation : $_"

    # Afficher la pile d'appels pour faciliter le dÃ©bogage
    Write-Host "Pile d'appels :"
    Write-Host $_.ScriptStackTrace

    # Retourner un code d'erreur
    exit 1
}

