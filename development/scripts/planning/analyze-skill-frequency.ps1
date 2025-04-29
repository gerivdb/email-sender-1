<#
.SYNOPSIS
    Analyse la fréquence d'utilisation de chaque compétence.

.DESCRIPTION
    Ce script analyse la fréquence d'utilisation de chaque compétence dans les améliorations
    et génère un rapport détaillé pour aider à la planification des ressources humaines.

.PARAMETER SkillsListPath
    Chemin vers le fichier de la liste des compétences extraites.

.PARAMETER OutputPath
    Chemin vers le fichier de sortie pour le rapport de fréquence d'utilisation.

.PARAMETER Format
    Format du fichier de sortie. Les valeurs possibles sont : JSON, CSV, Markdown.
    Par défaut : Markdown

.EXAMPLE
    .\analyze-skill-frequency.ps1 -SkillsListPath "data\planning\skills-list.md" -OutputPath "data\planning\skill-frequency.md"
    Analyse la fréquence d'utilisation de chaque compétence et génère un fichier Markdown.

.NOTES
    Auteur: Planning Team
    Version: 1.0
    Date de création: 2025-05-10
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

# Vérifier que le fichier d'entrée existe
if (-not (Test-Path -Path $SkillsListPath)) {
    Write-Error "Le fichier de la liste des compétences n'existe pas : $SkillsListPath"
    exit 1
}

# Créer le répertoire de sortie s'il n'existe pas
$outputDir = Split-Path -Path $OutputPath -Parent
if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

# Fonction pour extraire les compétences de la liste Markdown
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

    # Utiliser une expression régulière pour extraire les sections des gestionnaires
    $managerPattern = '## <a name=''([^'']+)''></a>([^\n]+)'
    $improvementPattern = '### ([^\n]+)'
    $skillsTablePattern = '\| Catégorie \| Compétence \| Niveau \| Justification \|[\r\n]+\|[^\n]+\|[\r\n]+((?:\|[^\n]+\|[\r\n]+)+)'
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
        
        # Extraire les améliorations
        $improvementMatches = [regex]::Matches($managerContent, $improvementPattern)
        foreach ($improvementMatch in $improvementMatches) {
            $improvementName = $improvementMatch.Groups[1].Value.Trim()
            
            # Extraire le contenu de la section de l'amélioration
            $improvementContent = $managerContent.Substring($improvementMatch.Index)
            $nextImprovementMatch = [regex]::Match($improvementContent.Substring($improvementMatch.Length), $improvementPattern)
            if ($nextImprovementMatch.Success) {
                $improvementContent = $improvementContent.Substring(0, $improvementMatch.Length + $nextImprovementMatch.Index)
            }
            
            # Extraire la table des compétences
            $skillsTableMatch = [regex]::Match($improvementContent, $skillsTablePattern)
            if ($skillsTableMatch.Success) {
                $skillsTable = $skillsTableMatch.Groups[1].Value
                
                # Extraire les lignes de compétences
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

# Fonction pour analyser la fréquence d'utilisation des compétences
function Analyze-SkillFrequency {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$Skills
    )

    # Calculer le nombre total d'améliorations
    $improvements = $Skills | Select-Object -Property Manager, Improvement -Unique
    $totalImprovements = $improvements.Count
    
    # Calculer le nombre total de compétences
    $totalSkills = $Skills.Count
    
    # Calculer le nombre de compétences uniques
    $uniqueSkills = $Skills | Select-Object -Property Skill -Unique
    $totalUniqueSkills = $uniqueSkills.Count
    
    # Calculer la fréquence d'utilisation de chaque compétence
    $skillFrequency = $Skills | Group-Object -Property Skill | ForEach-Object {
        $skillName = $_.Name
        $occurrences = $_.Count
        $percentage = [Math]::Round(($occurrences / $totalSkills) * 100, 1)
        
        # Calculer le nombre d'améliorations qui utilisent cette compétence
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
        
        # Calculer la distribution par catégorie
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
    
    # Calculer la fréquence d'utilisation par catégorie
    $categoryFrequency = $Skills | Group-Object -Property Category | ForEach-Object {
        $categoryName = $_.Name
        $occurrences = $_.Count
        $percentage = [Math]::Round(($occurrences / $totalSkills) * 100, 1)
        
        # Calculer le nombre de compétences uniques dans cette catégorie
        $uniqueCategorySkills = $Skills | Where-Object { $_.Category -eq $categoryName } | Select-Object -Property Skill -Unique
        $uniqueCategorySkillCount = $uniqueCategorySkills.Count
        
        [PSCustomObject]@{
            Category = $categoryName
            Occurrences = $occurrences
            Percentage = $percentage
            UniqueSkillCount = $uniqueCategorySkillCount
        }
    } | Sort-Object -Property Occurrences -Descending
    
    # Calculer la fréquence d'utilisation par niveau d'expertise
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
    
    # Calculer la fréquence d'utilisation par gestionnaire
    $managerFrequency = $Skills | Group-Object -Property Manager | ForEach-Object {
        $managerName = $_.Name
        $occurrences = $_.Count
        $percentage = [Math]::Round(($occurrences / $totalSkills) * 100, 1)
        
        # Calculer le nombre de compétences uniques pour ce gestionnaire
        $uniqueManagerSkills = $Skills | Where-Object { $_.Manager -eq $managerName } | Select-Object -Property Skill -Unique
        $uniqueManagerSkillCount = $uniqueManagerSkills.Count
        
        # Calculer le nombre d'améliorations pour ce gestionnaire
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

# Fonction pour générer le rapport au format Markdown
function Generate-MarkdownReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$FrequencyAnalysis
    )

    $markdown = "# Analyse de la Fréquence d'Utilisation des Compétences`n`n"
    $markdown += "Ce document présente une analyse détaillée de la fréquence d'utilisation des compétences dans les améliorations identifiées.`n`n"
    
    $markdown += "## Table des Matières`n`n"
    $markdown += "- [Résumé](#résumé)`n"
    $markdown += "- [Fréquence par Compétence](#fréquence-par-compétence)`n"
    $markdown += "- [Fréquence par Catégorie](#fréquence-par-catégorie)`n"
    $markdown += "- [Fréquence par Niveau d'Expertise](#fréquence-par-niveau-dexpertise)`n"
    $markdown += "- [Fréquence par Gestionnaire](#fréquence-par-gestionnaire)`n"
    $markdown += "- [Compétences les Plus Utilisées](#compétences-les-plus-utilisées)`n"
    $markdown += "- [Implications pour la Planification](#implications-pour-la-planification)`n"
    
    # Résumé
    $markdown += "`n## <a name='résumé'></a>Résumé`n`n"
    
    $markdown += "**Nombre total de compétences :** $($FrequencyAnalysis.TotalSkills)`n`n"
    $markdown += "**Nombre de compétences uniques :** $($FrequencyAnalysis.TotalUniqueSkills)`n`n"
    $markdown += "**Nombre total d'améliorations :** $($FrequencyAnalysis.TotalImprovements)`n`n"
    
    $markdown += "### Répartition Globale`n`n"
    $markdown += "| Métrique | Valeur |`n"
    $markdown += "|---------|--------|`n"
    $markdown += "| Nombre moyen de compétences par amélioration | $([Math]::Round($FrequencyAnalysis.TotalSkills / $FrequencyAnalysis.TotalImprovements, 1)) |`n"
    $markdown += "| Nombre moyen d'améliorations par compétence | $([Math]::Round($FrequencyAnalysis.TotalImprovements / $FrequencyAnalysis.TotalUniqueSkills, 1)) |`n"
    $markdown += "| Ratio compétences uniques / total | $([Math]::Round($FrequencyAnalysis.TotalUniqueSkills / $FrequencyAnalysis.TotalSkills, 2)) |`n"
    
    # Fréquence par compétence
    $markdown += "`n## <a name='fréquence-par-compétence'></a>Fréquence par Compétence`n`n"
    $markdown += "Cette section présente la fréquence d'utilisation de chaque compétence dans les améliorations.`n`n"
    
    $markdown += "| Compétence | Occurrences | % du Total | Améliorations | % des Améliorations |`n"
    $markdown += "|------------|-------------|-----------|---------------|---------------------|`n"
    
    foreach ($skill in $FrequencyAnalysis.SkillFrequency | Select-Object -First 20) {
        $markdown += "| $($skill.Skill) | $($skill.Occurrences) | $($skill.Percentage)% | $($skill.ImprovementCount) | $($skill.ImprovementPercentage)% |`n"
    }
    
    if ($FrequencyAnalysis.SkillFrequency.Count -gt 20) {
        $markdown += "| ... | ... | ... | ... | ... |`n"
    }
    
    # Fréquence par catégorie
    $markdown += "`n## <a name='fréquence-par-catégorie'></a>Fréquence par Catégorie`n`n"
    $markdown += "Cette section présente la fréquence d'utilisation des compétences par catégorie.`n`n"
    
    $markdown += "| Catégorie | Occurrences | % du Total | Compétences Uniques |`n"
    $markdown += "|-----------|-------------|-----------|---------------------|`n"
    
    foreach ($category in $FrequencyAnalysis.CategoryFrequency) {
        $markdown += "| $($category.Category) | $($category.Occurrences) | $($category.Percentage)% | $($category.UniqueSkillCount) |`n"
    }
    
    # Fréquence par niveau d'expertise
    $markdown += "`n## <a name='fréquence-par-niveau-dexpertise'></a>Fréquence par Niveau d'Expertise`n`n"
    $markdown += "Cette section présente la fréquence d'utilisation des compétences par niveau d'expertise.`n`n"
    
    $markdown += "| Niveau | Occurrences | % du Total |`n"
    $markdown += "|--------|-------------|-----------|`n"
    
    foreach ($level in $FrequencyAnalysis.LevelFrequency) {
        $markdown += "| $($level.Level) | $($level.Occurrences) | $($level.Percentage)% |`n"
    }
    
    # Fréquence par gestionnaire
    $markdown += "`n## <a name='fréquence-par-gestionnaire'></a>Fréquence par Gestionnaire`n`n"
    $markdown += "Cette section présente la fréquence d'utilisation des compétences par gestionnaire.`n`n"
    
    $markdown += "| Gestionnaire | Occurrences | % du Total | Compétences Uniques | Améliorations |`n"
    $markdown += "|--------------|-------------|-----------|---------------------|---------------|`n"
    
    foreach ($manager in $FrequencyAnalysis.ManagerFrequency) {
        $markdown += "| $($manager.Manager) | $($manager.Occurrences) | $($manager.Percentage)% | $($manager.UniqueSkillCount) | $($manager.ImprovementCount) |`n"
    }
    
    # Compétences les plus utilisées
    $markdown += "`n## <a name='compétences-les-plus-utilisées'></a>Compétences les Plus Utilisées`n`n"
    $markdown += "Cette section présente une analyse détaillée des 5 compétences les plus utilisées.`n`n"
    
    $topSkills = $FrequencyAnalysis.SkillFrequency | Select-Object -First 5
    
    foreach ($skill in $topSkills) {
        $markdown += "### $($skill.Skill)`n`n"
        $markdown += "**Occurrences :** $($skill.Occurrences) ($($skill.Percentage)% du total)`n`n"
        $markdown += "**Améliorations :** $($skill.ImprovementCount) ($($skill.ImprovementPercentage)% des améliorations)`n`n"
        
        $markdown += "#### Distribution par Niveau d'Expertise`n`n"
        $markdown += "| Niveau | Occurrences | % |`n"
        $markdown += "|--------|-------------|---|`n"
        
        foreach ($level in $skill.LevelDistribution | Sort-Object -Property Count -Descending) {
            $markdown += "| $($level.Level) | $($level.Count) | $($level.Percentage)% |`n"
        }
        
        $markdown += "`n#### Distribution par Catégorie`n`n"
        $markdown += "| Catégorie | Occurrences | % |`n"
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
    $markdown += "Cette analyse de la fréquence d'utilisation des compétences a plusieurs implications importantes pour la planification des ressources humaines :`n`n"
    
    $markdown += "### Priorités de Formation`n`n"
    $markdown += "1. **Compétences à haute fréquence** : Les compétences les plus fréquemment utilisées devraient être prioritaires dans les programmes de formation.`n"
    $markdown += "   - " + ($topSkills | Select-Object -First 3 | ForEach-Object { $_.Skill }) -join "`n   - " + "`n"
    $markdown += "2. **Niveaux d'expertise les plus demandés** : Les niveaux d'expertise les plus fréquemment requis devraient être ciblés dans les programmes de formation.`n"
    $markdown += "   - " + ($FrequencyAnalysis.LevelFrequency | Select-Object -First 2 | ForEach-Object { $_.Level }) -join "`n   - " + "`n"
    
    $markdown += "`n### Recrutement`n`n"
    $markdown += "1. **Profils recherchés** : Les profils de recrutement devraient mettre l'accent sur les compétences les plus fréquemment utilisées.`n"
    $markdown += "2. **Niveaux d'expertise** : Les niveaux d'expertise les plus demandés devraient être ciblés lors du recrutement.`n"
    
    $markdown += "`n### Allocation des Ressources`n`n"
    $markdown += "1. **Équipes polyvalentes** : Former des équipes polyvalentes possédant les compétences les plus fréquemment utilisées.`n"
    $markdown += "2. **Spécialistes** : Identifier les besoins en spécialistes pour les compétences moins fréquentes mais critiques.`n"
    
    $markdown += "`n### Gestion des Connaissances`n`n"
    $markdown += "1. **Documentation** : Prioriser la documentation des compétences les plus fréquemment utilisées.`n"
    $markdown += "2. **Partage des connaissances** : Mettre en place des mécanismes de partage des connaissances pour les compétences les plus fréquemment utilisées.`n"
    
    return $markdown
}

# Fonction pour générer le rapport au format CSV
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

# Fonction pour générer le rapport au format JSON
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

# Lire le contenu de la liste des compétences
$listContent = Get-Content -Path $SkillsListPath -Raw

# Extraire les compétences de la liste
$extractionResult = Extract-SkillsFromList -MarkdownContent $listContent
$skills = $extractionResult.Skills

# Analyser la fréquence d'utilisation des compétences
$frequencyAnalysis = Analyze-SkillFrequency -Skills $skills

# Générer le rapport dans le format spécifié
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
    Write-Host "Analyse de la fréquence d'utilisation des compétences générée avec succès : $OutputPath"
} catch {
    Write-Error "Erreur lors de l'enregistrement du rapport : $_"
    exit 1
}

# Afficher un résumé
Write-Host "`nRésumé de l'analyse de la fréquence d'utilisation des compétences :"
Write-Host "------------------------------------------------------------"

Write-Host "  Nombre total de compétences : $($frequencyAnalysis.TotalSkills)"
Write-Host "  Nombre de compétences uniques : $($frequencyAnalysis.TotalUniqueSkills)"
Write-Host "  Nombre total d'améliorations : $($frequencyAnalysis.TotalImprovements)"

Write-Host "`nTop 5 des compétences les plus utilisées :"
foreach ($skill in $frequencyAnalysis.SkillFrequency | Select-Object -First 5) {
    Write-Host "  $($skill.Skill) : $($skill.Occurrences) occurrences ($($skill.Percentage)%), utilisée dans $($skill.ImprovementCount) améliorations ($($skill.ImprovementPercentage)%)"
}

Write-Host "`nRépartition par niveau d'expertise :"
foreach ($level in $frequencyAnalysis.LevelFrequency) {
    Write-Host "  $($level.Level) : $($level.Occurrences) occurrences ($($level.Percentage)%)"
}
