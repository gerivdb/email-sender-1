<#
.SYNOPSIS
    Analyse la frÃ©quence d'utilisation de chaque compÃ©tence.

.DESCRIPTION
    Ce script analyse la frÃ©quence d'utilisation de chaque compÃ©tence dans les amÃ©liorations
    et gÃ©nÃ¨re un rapport dÃ©taillÃ© pour aider Ã  la planification des ressources humaines.

.PARAMETER SkillsListPath
    Chemin vers le fichier de la liste des compÃ©tences extraites.

.PARAMETER OutputPath
    Chemin vers le fichier de sortie pour le rapport de frÃ©quence d'utilisation.

.PARAMETER Format
    Format du fichier de sortie. Les valeurs possibles sont : JSON, CSV, Markdown.
    Par dÃ©faut : Markdown

.EXAMPLE
    .\analyze-skill-frequency.ps1 -SkillsListPath "data\planning\skills-list.md" -OutputPath "data\planning\skill-frequency.md"
    Analyse la frÃ©quence d'utilisation de chaque compÃ©tence et gÃ©nÃ¨re un fichier Markdown.

.NOTES
    Auteur: Planning Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-10
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$SkillsListPath,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [ValidateSet("JSON", "CSV", "Markdown")]
    [string]$Format = "Markdown"
)

# VÃ©rifier que le fichier d'entrÃ©e existe
if (-not (Test-Path -Path $SkillsListPath)) {
    Write-Error "Le fichier de la liste des compÃ©tences n'existe pas : $SkillsListPath"
    exit 1
}

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
$outputDir = Split-Path -Path $OutputPath -Parent
if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

# Fonction pour extraire les compÃ©tences de la liste Markdown
function Extract-SkillsFromList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$MarkdownContent
    )

    $skills = @()
    $managers = @()
    $currentManager = $null
    $currentImprovement = $null

    # Utiliser une expression rÃ©guliÃ¨re pour extraire les sections des gestionnaires
    $managerPattern = '## <a name=''([^'']+)''></a>([^\n]+)'
    $improvementPattern = '### ([^\n]+)'
    $skillsTablePattern = '\| CatÃ©gorie \| CompÃ©tence \| Niveau \| Justification \|[\r\n]+\|[^\n]+\|[\r\n]+((?:\|[^\n]+\|[\r\n]+)+)'
    $skillRowPattern = '\| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \|'

    # Extraire les gestionnaires
    $managerMatches = [regex]::Matches($MarkdownContent, $managerPattern)
    foreach ($managerMatch in $managerMatches) {
        $managerName = $managerMatch.Groups[2].Value.Trim()
        $managers += $managerName
        
        # Extraire le contenu de la section du gestionnaire
        $managerContent = $MarkdownContent.Substring($managerMatch.Index)
        $nextManagerMatch = [regex]::Match($managerContent.Substring($managerMatch.Length), $managerPattern)
        if ($nextManagerMatch.Success) {
            $managerContent = $managerContent.Substring(0, $managerMatch.Length + $nextManagerMatch.Index)
        }
        
        # Extraire les amÃ©liorations
        $improvementMatches = [regex]::Matches($managerContent, $improvementPattern)
        foreach ($improvementMatch in $improvementMatches) {
            $improvementName = $improvementMatch.Groups[1].Value.Trim()
            
            # Extraire le contenu de la section de l'amÃ©lioration
            $improvementContent = $managerContent.Substring($improvementMatch.Index)
            $nextImprovementMatch = [regex]::Match($improvementContent.Substring($improvementMatch.Length), $improvementPattern)
            if ($nextImprovementMatch.Success) {
                $improvementContent = $improvementContent.Substring(0, $improvementMatch.Length + $nextImprovementMatch.Index)
            }
            
            # Extraire la table des compÃ©tences
            $skillsTableMatch = [regex]::Match($improvementContent, $skillsTablePattern)
            if ($skillsTableMatch.Success) {
                $skillsTable = $skillsTableMatch.Groups[1].Value
                
                # Extraire les lignes de compÃ©tences
                $skillRowMatches = [regex]::Matches($skillsTable, $skillRowPattern)
                foreach ($skillRowMatch in $skillRowMatches) {
                    $category = $skillRowMatch.Groups[1].Value.Trim()
                    $skill = $skillRowMatch.Groups[2].Value.Trim()
                    $level = $skillRowMatch.Groups[3].Value.Trim()
                    $justification = $skillRowMatch.Groups[4].Value.Trim()
                    
                    $skills += [PSCustomObject]@{
                        Manager = $managerName
                        Improvement = $improvementName
                        Category = $category
                        Skill = $skill
                        Level = $level
                        Justification = $justification
                    }
                }
            }
        }
    }

    return @{
        Skills = $skills
        Managers = $managers
    }
}

# Fonction pour analyser la frÃ©quence d'utilisation des compÃ©tences
function Analyze-SkillFrequency {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$Skills
    )

    # Calculer le nombre total d'amÃ©liorations
    $improvements = $Skills | Select-Object -Property Manager, Improvement -Unique
    $totalImprovements = $improvements.Count
    
    # Calculer le nombre total de compÃ©tences
    $totalSkills = $Skills.Count
    
    # Calculer le nombre de compÃ©tences uniques
    $uniqueSkills = $Skills | Select-Object -Property Skill -Unique
    $totalUniqueSkills = $uniqueSkills.Count
    
    # Calculer la frÃ©quence d'utilisation de chaque compÃ©tence
    $skillFrequency = $Skills | Group-Object -Property Skill | ForEach-Object {
        $skillName = $_.Name
        $occurrences = $_.Count
        $percentage = [Math]::Round(($occurrences / $totalSkills) * 100, 1)
        
        # Calculer le nombre d'amÃ©liorations qui utilisent cette compÃ©tence
        $improvementsUsingSkill = $Skills | Where-Object { $_.Skill -eq $skillName } | Select-Object -Property Manager, Improvement -Unique
        $improvementCount = $improvementsUsingSkill.Count
        $improvementPercentage = [Math]::Round(($improvementCount / $totalImprovements) * 100, 1)
        
        # Calculer la distribution par niveau d'expertise
        $levelDistribution = $Skills | Where-Object { $_.Skill -eq $skillName } | Group-Object -Property Level | ForEach-Object {
            [PSCustomObject]@{
                Level = $_.Name
                Count = $_.Count
                Percentage = [Math]::Round(($_.Count / $occurrences) * 100, 1)
            }
        }
        
        # Calculer la distribution par catÃ©gorie
        $categoryDistribution = $Skills | Where-Object { $_.Skill -eq $skillName } | Group-Object -Property Category | ForEach-Object {
            [PSCustomObject]@{
                Category = $_.Name
                Count = $_.Count
                Percentage = [Math]::Round(($_.Count / $occurrences) * 100, 1)
            }
        }
        
        # Calculer la distribution par gestionnaire
        $managerDistribution = $Skills | Where-Object { $_.Skill -eq $skillName } | Group-Object -Property Manager | ForEach-Object {
            [PSCustomObject]@{
                Manager = $_.Name
                Count = $_.Count
                Percentage = [Math]::Round(($_.Count / $occurrences) * 100, 1)
            }
        }
        
        [PSCustomObject]@{
            Skill = $skillName
            Occurrences = $occurrences
            Percentage = $percentage
            ImprovementCount = $improvementCount
            ImprovementPercentage = $improvementPercentage
            LevelDistribution = $levelDistribution
            CategoryDistribution = $categoryDistribution
            ManagerDistribution = $managerDistribution
        }
    } | Sort-Object -Property Occurrences -Descending
    
    # Calculer la frÃ©quence d'utilisation par catÃ©gorie
    $categoryFrequency = $Skills | Group-Object -Property Category | ForEach-Object {
        $categoryName = $_.Name
        $occurrences = $_.Count
        $percentage = [Math]::Round(($occurrences / $totalSkills) * 100, 1)
        
        # Calculer le nombre de compÃ©tences uniques dans cette catÃ©gorie
        $uniqueCategorySkills = $Skills | Where-Object { $_.Category -eq $categoryName } | Select-Object -Property Skill -Unique
        $uniqueCategorySkillCount = $uniqueCategorySkills.Count
        
        [PSCustomObject]@{
            Category = $categoryName
            Occurrences = $occurrences
            Percentage = $percentage
            UniqueSkillCount = $uniqueCategorySkillCount
        }
    } | Sort-Object -Property Occurrences -Descending
    
    # Calculer la frÃ©quence d'utilisation par niveau d'expertise
    $levelFrequency = $Skills | Group-Object -Property Level | ForEach-Object {
        $levelName = $_.Name
        $occurrences = $_.Count
        $percentage = [Math]::Round(($occurrences / $totalSkills) * 100, 1)
        
        [PSCustomObject]@{
            Level = $levelName
            Occurrences = $occurrences
            Percentage = $percentage
        }
    } | Sort-Object -Property Occurrences -Descending
    
    # Calculer la frÃ©quence d'utilisation par gestionnaire
    $managerFrequency = $Skills | Group-Object -Property Manager | ForEach-Object {
        $managerName = $_.Name
        $occurrences = $_.Count
        $percentage = [Math]::Round(($occurrences / $totalSkills) * 100, 1)
        
        # Calculer le nombre de compÃ©tences uniques pour ce gestionnaire
        $uniqueManagerSkills = $Skills | Where-Object { $_.Manager -eq $managerName } | Select-Object -Property Skill -Unique
        $uniqueManagerSkillCount = $uniqueManagerSkills.Count
        
        # Calculer le nombre d'amÃ©liorations pour ce gestionnaire
        $managerImprovements = $Skills | Where-Object { $_.Manager -eq $managerName } | Select-Object -Property Improvement -Unique
        $managerImprovementCount = $managerImprovements.Count
        
        [PSCustomObject]@{
            Manager = $managerName
            Occurrences = $occurrences
            Percentage = $percentage
            UniqueSkillCount = $uniqueManagerSkillCount
            ImprovementCount = $managerImprovementCount
        }
    } | Sort-Object -Property Occurrences -Descending
    
    return [PSCustomObject]@{
        TotalSkills = $totalSkills
        TotalUniqueSkills = $totalUniqueSkills
        TotalImprovements = $totalImprovements
        SkillFrequency = $skillFrequency
        CategoryFrequency = $categoryFrequency
        LevelFrequency = $levelFrequency
        ManagerFrequency = $managerFrequency
    }
}

# Fonction pour gÃ©nÃ©rer le rapport au format Markdown
function Generate-MarkdownReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$FrequencyAnalysis
    )

    $markdown = "# Analyse de la FrÃ©quence d'Utilisation des CompÃ©tences`n`n"
    $markdown += "Ce document prÃ©sente une analyse dÃ©taillÃ©e de la frÃ©quence d'utilisation des compÃ©tences dans les amÃ©liorations identifiÃ©es.`n`n"
    
    $markdown += "## Table des MatiÃ¨res`n`n"
    $markdown += "- [RÃ©sumÃ©](#rÃ©sumÃ©)`n"
    $markdown += "- [FrÃ©quence par CompÃ©tence](#frÃ©quence-par-compÃ©tence)`n"
    $markdown += "- [FrÃ©quence par CatÃ©gorie](#frÃ©quence-par-catÃ©gorie)`n"
    $markdown += "- [FrÃ©quence par Niveau d'Expertise](#frÃ©quence-par-niveau-dexpertise)`n"
    $markdown += "- [FrÃ©quence par Gestionnaire](#frÃ©quence-par-gestionnaire)`n"
    $markdown += "- [CompÃ©tences les Plus UtilisÃ©es](#compÃ©tences-les-plus-utilisÃ©es)`n"
    $markdown += "- [Implications pour la Planification](#implications-pour-la-planification)`n"
    
    # RÃ©sumÃ©
    $markdown += "`n## <a name='rÃ©sumÃ©'></a>RÃ©sumÃ©`n`n"
    
    $markdown += "**Nombre total de compÃ©tences :** $($FrequencyAnalysis.TotalSkills)`n`n"
    $markdown += "**Nombre de compÃ©tences uniques :** $($FrequencyAnalysis.TotalUniqueSkills)`n`n"
    $markdown += "**Nombre total d'amÃ©liorations :** $($FrequencyAnalysis.TotalImprovements)`n`n"
    
    $markdown += "### RÃ©partition Globale`n`n"
    $markdown += "| MÃ©trique | Valeur |`n"
    $markdown += "|---------|--------|`n"
    $markdown += "| Nombre moyen de compÃ©tences par amÃ©lioration | $([Math]::Round($FrequencyAnalysis.TotalSkills / $FrequencyAnalysis.TotalImprovements, 1)) |`n"
    $markdown += "| Nombre moyen d'amÃ©liorations par compÃ©tence | $([Math]::Round($FrequencyAnalysis.TotalImprovements / $FrequencyAnalysis.TotalUniqueSkills, 1)) |`n"
    $markdown += "| Ratio compÃ©tences uniques / total | $([Math]::Round($FrequencyAnalysis.TotalUniqueSkills / $FrequencyAnalysis.TotalSkills, 2)) |`n"
    
    # FrÃ©quence par compÃ©tence
    $markdown += "`n## <a name='frÃ©quence-par-compÃ©tence'></a>FrÃ©quence par CompÃ©tence`n`n"
    $markdown += "Cette section prÃ©sente la frÃ©quence d'utilisation de chaque compÃ©tence dans les amÃ©liorations.`n`n"
    
    $markdown += "| CompÃ©tence | Occurrences | % du Total | AmÃ©liorations | % des AmÃ©liorations |`n"
    $markdown += "|------------|-------------|-----------|---------------|---------------------|`n"
    
    foreach ($skill in $FrequencyAnalysis.SkillFrequency | Select-Object -First 20) {
        $markdown += "| $($skill.Skill) | $($skill.Occurrences) | $($skill.Percentage)% | $($skill.ImprovementCount) | $($skill.ImprovementPercentage)% |`n"
    }
    
    if ($FrequencyAnalysis.SkillFrequency.Count -gt 20) {
        $markdown += "| ... | ... | ... | ... | ... |`n"
    }
    
    # FrÃ©quence par catÃ©gorie
    $markdown += "`n## <a name='frÃ©quence-par-catÃ©gorie'></a>FrÃ©quence par CatÃ©gorie`n`n"
    $markdown += "Cette section prÃ©sente la frÃ©quence d'utilisation des compÃ©tences par catÃ©gorie.`n`n"
    
    $markdown += "| CatÃ©gorie | Occurrences | % du Total | CompÃ©tences Uniques |`n"
    $markdown += "|-----------|-------------|-----------|---------------------|`n"
    
    foreach ($category in $FrequencyAnalysis.CategoryFrequency) {
        $markdown += "| $($category.Category) | $($category.Occurrences) | $($category.Percentage)% | $($category.UniqueSkillCount) |`n"
    }
    
    # FrÃ©quence par niveau d'expertise
    $markdown += "`n## <a name='frÃ©quence-par-niveau-dexpertise'></a>FrÃ©quence par Niveau d'Expertise`n`n"
    $markdown += "Cette section prÃ©sente la frÃ©quence d'utilisation des compÃ©tences par niveau d'expertise.`n`n"
    
    $markdown += "| Niveau | Occurrences | % du Total |`n"
    $markdown += "|--------|-------------|-----------|`n"
    
    foreach ($level in $FrequencyAnalysis.LevelFrequency) {
        $markdown += "| $($level.Level) | $($level.Occurrences) | $($level.Percentage)% |`n"
    }
    
    # FrÃ©quence par gestionnaire
    $markdown += "`n## <a name='frÃ©quence-par-gestionnaire'></a>FrÃ©quence par Gestionnaire`n`n"
    $markdown += "Cette section prÃ©sente la frÃ©quence d'utilisation des compÃ©tences par gestionnaire.`n`n"
    
    $markdown += "| Gestionnaire | Occurrences | % du Total | CompÃ©tences Uniques | AmÃ©liorations |`n"
    $markdown += "|--------------|-------------|-----------|---------------------|---------------|`n"
    
    foreach ($manager in $FrequencyAnalysis.ManagerFrequency) {
        $markdown += "| $($manager.Manager) | $($manager.Occurrences) | $($manager.Percentage)% | $($manager.UniqueSkillCount) | $($manager.ImprovementCount) |`n"
    }
    
    # CompÃ©tences les plus utilisÃ©es
    $markdown += "`n## <a name='compÃ©tences-les-plus-utilisÃ©es'></a>CompÃ©tences les Plus UtilisÃ©es`n`n"
    $markdown += "Cette section prÃ©sente une analyse dÃ©taillÃ©e des 5 compÃ©tences les plus utilisÃ©es.`n`n"
    
    $topSkills = $FrequencyAnalysis.SkillFrequency | Select-Object -First 5
    
    foreach ($skill in $topSkills) {
        $markdown += "### $($skill.Skill)`n`n"
        $markdown += "**Occurrences :** $($skill.Occurrences) ($($skill.Percentage)% du total)`n`n"
        $markdown += "**AmÃ©liorations :** $($skill.ImprovementCount) ($($skill.ImprovementPercentage)% des amÃ©liorations)`n`n"
        
        $markdown += "#### Distribution par Niveau d'Expertise`n`n"
        $markdown += "| Niveau | Occurrences | % |`n"
        $markdown += "|--------|-------------|---|`n"
        
        foreach ($level in $skill.LevelDistribution | Sort-Object -Property Count -Descending) {
            $markdown += "| $($level.Level) | $($level.Count) | $($level.Percentage)% |`n"
        }
        
        $markdown += "`n#### Distribution par CatÃ©gorie`n`n"
        $markdown += "| CatÃ©gorie | Occurrences | % |`n"
        $markdown += "|-----------|-------------|---|`n"
        
        foreach ($category in $skill.CategoryDistribution | Sort-Object -Property Count -Descending) {
            $markdown += "| $($category.Category) | $($category.Count) | $($category.Percentage)% |`n"
        }
        
        $markdown += "`n#### Distribution par Gestionnaire`n`n"
        $markdown += "| Gestionnaire | Occurrences | % |`n"
        $markdown += "|--------------|-------------|---|`n"
        
        foreach ($manager in $skill.ManagerDistribution | Sort-Object -Property Count -Descending) {
            $markdown += "| $($manager.Manager) | $($manager.Count) | $($manager.Percentage)% |`n"
        }
        
        $markdown += "`n"
    }
    
    # Implications pour la planification
    $markdown += "`n## <a name='implications-pour-la-planification'></a>Implications pour la Planification`n`n"
    $markdown += "Cette analyse de la frÃ©quence d'utilisation des compÃ©tences a plusieurs implications importantes pour la planification des ressources humaines :`n`n"
    
    $markdown += "### PrioritÃ©s de Formation`n`n"
    $markdown += "1. **CompÃ©tences Ã  haute frÃ©quence** : Les compÃ©tences les plus frÃ©quemment utilisÃ©es devraient Ãªtre prioritaires dans les programmes de formation.`n"
    $markdown += "   - " + ($topSkills | Select-Object -First 3 | ForEach-Object { $_.Skill }) -join "`n   - " + "`n"
    $markdown += "2. **Niveaux d'expertise les plus demandÃ©s** : Les niveaux d'expertise les plus frÃ©quemment requis devraient Ãªtre ciblÃ©s dans les programmes de formation.`n"
    $markdown += "   - " + ($FrequencyAnalysis.LevelFrequency | Select-Object -First 2 | ForEach-Object { $_.Level }) -join "`n   - " + "`n"
    
    $markdown += "`n### Recrutement`n`n"
    $markdown += "1. **Profils recherchÃ©s** : Les profils de recrutement devraient mettre l'accent sur les compÃ©tences les plus frÃ©quemment utilisÃ©es.`n"
    $markdown += "2. **Niveaux d'expertise** : Les niveaux d'expertise les plus demandÃ©s devraient Ãªtre ciblÃ©s lors du recrutement.`n"
    
    $markdown += "`n### Allocation des Ressources`n`n"
    $markdown += "1. **Ã‰quipes polyvalentes** : Former des Ã©quipes polyvalentes possÃ©dant les compÃ©tences les plus frÃ©quemment utilisÃ©es.`n"
    $markdown += "2. **SpÃ©cialistes** : Identifier les besoins en spÃ©cialistes pour les compÃ©tences moins frÃ©quentes mais critiques.`n"
    
    $markdown += "`n### Gestion des Connaissances`n`n"
    $markdown += "1. **Documentation** : Prioriser la documentation des compÃ©tences les plus frÃ©quemment utilisÃ©es.`n"
    $markdown += "2. **Partage des connaissances** : Mettre en place des mÃ©canismes de partage des connaissances pour les compÃ©tences les plus frÃ©quemment utilisÃ©es.`n"
    
    return $markdown
}

# Fonction pour gÃ©nÃ©rer le rapport au format CSV
function Generate-CsvReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$FrequencyAnalysis
    )

    $csv = "Type,Name,Occurrences,Percentage,ImprovementCount,ImprovementPercentage,UniqueSkillCount`n"
    
    foreach ($skill in $FrequencyAnalysis.SkillFrequency) {
        $csv += "Skill,$($skill.Skill),$($skill.Occurrences),$($skill.Percentage),$($skill.ImprovementCount),$($skill.ImprovementPercentage),`n"
    }
    
    foreach ($category in $FrequencyAnalysis.CategoryFrequency) {
        $csv += "Category,$($category.Category),$($category.Occurrences),$($category.Percentage),,,$($category.UniqueSkillCount)`n"
    }
    
    foreach ($level in $FrequencyAnalysis.LevelFrequency) {
        $csv += "Level,$($level.Level),$($level.Occurrences),$($level.Percentage),,,`n"
    }
    
    foreach ($manager in $FrequencyAnalysis.ManagerFrequency) {
        $csv += "Manager,$($manager.Manager),$($manager.Occurrences),$($manager.Percentage),$($manager.ImprovementCount),,$($manager.UniqueSkillCount)`n"
    }
    
    return $csv
}

# Fonction pour gÃ©nÃ©rer le rapport au format JSON
function Generate-JsonReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$FrequencyAnalysis
    )

    $jsonData = [PSCustomObject]@{
        Summary = [PSCustomObject]@{
            TotalSkills = $FrequencyAnalysis.TotalSkills
            TotalUniqueSkills = $FrequencyAnalysis.TotalUniqueSkills
            TotalImprovements = $FrequencyAnalysis.TotalImprovements
            AverageSkillsPerImprovement = [Math]::Round($FrequencyAnalysis.TotalSkills / $FrequencyAnalysis.TotalImprovements, 1)
            AverageImprovementsPerSkill = [Math]::Round($FrequencyAnalysis.TotalImprovements / $FrequencyAnalysis.TotalUniqueSkills, 1)
            UniqueToTotalRatio = [Math]::Round($FrequencyAnalysis.TotalUniqueSkills / $FrequencyAnalysis.TotalSkills, 2)
        }
        SkillFrequency = $FrequencyAnalysis.SkillFrequency
        CategoryFrequency = $FrequencyAnalysis.CategoryFrequency
        LevelFrequency = $FrequencyAnalysis.LevelFrequency
        ManagerFrequency = $FrequencyAnalysis.ManagerFrequency
    }
    
    return $jsonData | ConvertTo-Json -Depth 10
}

# Lire le contenu de la liste des compÃ©tences
$listContent = Get-Content -Path $SkillsListPath -Raw

# Extraire les compÃ©tences de la liste
$extractionResult = Extract-SkillsFromList -MarkdownContent $listContent
$skills = $extractionResult.Skills

# Analyser la frÃ©quence d'utilisation des compÃ©tences
$frequencyAnalysis = Analyze-SkillFrequency -Skills $skills

# GÃ©nÃ©rer le rapport dans le format spÃ©cifiÃ©
switch ($Format) {
    "Markdown" {
        $reportContent = Generate-MarkdownReport -FrequencyAnalysis $frequencyAnalysis
    }
    "CSV" {
        $reportContent = Generate-CsvReport -FrequencyAnalysis $frequencyAnalysis
    }
    "JSON" {
        $reportContent = Generate-JsonReport -FrequencyAnalysis $frequencyAnalysis
    }
}

# Enregistrer le rapport
try {
    $reportContent | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "Analyse de la frÃ©quence d'utilisation des compÃ©tences gÃ©nÃ©rÃ©e avec succÃ¨s : $OutputPath"
} catch {
    Write-Error "Erreur lors de l'enregistrement du rapport : $_"
    exit 1
}

# Afficher un rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ© de l'analyse de la frÃ©quence d'utilisation des compÃ©tences :"
Write-Host "------------------------------------------------------------"

Write-Host "  Nombre total de compÃ©tences : $($frequencyAnalysis.TotalSkills)"
Write-Host "  Nombre de compÃ©tences uniques : $($frequencyAnalysis.TotalUniqueSkills)"
Write-Host "  Nombre total d'amÃ©liorations : $($frequencyAnalysis.TotalImprovements)"

Write-Host "`nTop 5 des compÃ©tences les plus utilisÃ©es :"
foreach ($skill in $frequencyAnalysis.SkillFrequency | Select-Object -First 5) {
    Write-Host "  $($skill.Skill) : $($skill.Occurrences) occurrences ($($skill.Percentage)%), utilisÃ©e dans $($skill.ImprovementCount) amÃ©liorations ($($skill.ImprovementPercentage)%)"
}

Write-Host "`nRÃ©partition par niveau d'expertise :"
foreach ($level in $frequencyAnalysis.LevelFrequency) {
    Write-Host "  $($level.Level) : $($level.Occurrences) occurrences ($($level.Percentage)%)"
}
