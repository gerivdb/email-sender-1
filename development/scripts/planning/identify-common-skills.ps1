<#
.SYNOPSIS
    Identifie les compétences communes à plusieurs améliorations.

.DESCRIPTION
    Ce script analyse la liste des compétences extraites et identifie celles qui sont
    communes à plusieurs améliorations, ce qui permet de déterminer les compétences
    les plus importantes et polyvalentes.

.PARAMETER SkillsListPath
    Chemin vers le fichier de la liste des compétences extraites.

.PARAMETER OutputPath
    Chemin vers le fichier de sortie pour la liste des compétences communes.

.PARAMETER MinimumOccurrences
    Nombre minimum d'occurrences pour qu'une compétence soit considérée comme commune.
    Par défaut : 2

.PARAMETER Format
    Format du fichier de sortie. Les valeurs possibles sont : JSON, CSV, Markdown.
    Par défaut : Markdown

.EXAMPLE
    .\identify-common-skills.ps1 -SkillsListPath "data\planning\skills-list.md" -OutputPath "data\planning\common-skills.md"
    Identifie les compétences communes à plusieurs améliorations et génère un fichier Markdown.

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
    [int]$MinimumOccurrences = 2,

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

# Fonction pour identifier les compétences communes
function Identify-CommonSkills {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$Skills,
        
        [Parameter(Mandatory = $true)]
        [int]$MinimumOccurrences
    )

    # Regrouper les compétences par nom et compter les occurrences
    $skillOccurrences = $Skills | Group-Object -Property Skill | Sort-Object -Property Count -Descending
    
    # Filtrer les compétences qui apparaissent au moins le nombre minimum de fois
    $commonSkills = $skillOccurrences | Where-Object { $_.Count -ge $MinimumOccurrences }
    
    # Pour chaque compétence commune, identifier les améliorations qui l'utilisent
    $commonSkillsDetails = $commonSkills | ForEach-Object {
        $skillName = $_.Name
        $occurrences = $_.Count
        $skillInstances = $Skills | Where-Object { $_.Skill -eq $skillName }
        
        # Regrouper par niveau d'expertise
        $levelDistribution = $skillInstances | Group-Object -Property Level | ForEach-Object {
            [PSCustomObject]@{
                Level = $_.Name
                Count = $_.Count
                Percentage = [Math]::Round(($_.Count / $occurrences) * 100, 1)
            }
        }
        
        # Regrouper par catégorie
        $categoryDistribution = $skillInstances | Group-Object -Property Category | ForEach-Object {
            [PSCustomObject]@{
                Category = $_.Name
                Count = $_.Count
                Percentage = [Math]::Round(($_.Count / $occurrences) * 100, 1)
            }
        }
        
        # Regrouper par gestionnaire
        $managerDistribution = $skillInstances | Group-Object -Property Manager | ForEach-Object {
            [PSCustomObject]@{
                Manager = $_.Name
                Count = $_.Count
                Percentage = [Math]::Round(($_.Count / $occurrences) * 100, 1)
            }
        }
        
        # Identifier les améliorations qui utilisent cette compétence
        $improvements = $skillInstances | Select-Object -Property Manager, Improvement -Unique | ForEach-Object {
            [PSCustomObject]@{
                Manager = $_.Manager
                Improvement = $_.Improvement
            }
        }
        
        [PSCustomObject]@{
            Skill = $skillName
            Occurrences = $occurrences
            LevelDistribution = $levelDistribution
            CategoryDistribution = $categoryDistribution
            ManagerDistribution = $managerDistribution
            Improvements = $improvements
        }
    }
    
    return $commonSkillsDetails
}

# Fonction pour générer le rapport au format Markdown
function Generate-MarkdownReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$CommonSkills,
        
        [Parameter(Mandatory = $true)]
        [int]$MinimumOccurrences
    )

    $markdown = "# Compétences Communes à Plusieurs Améliorations`n`n"
    $markdown += "Ce document présente les compétences qui sont communes à plusieurs améliorations, ce qui permet de déterminer les compétences les plus importantes et polyvalentes.`n`n"
    
    $markdown += "## Critères d'Identification`n`n"
    $markdown += "Une compétence est considérée comme commune si elle apparaît dans au moins $MinimumOccurrences améliorations différentes.`n`n"
    
    $markdown += "## Table des Matières`n`n"
    $markdown += "- [Résumé](#résumé)`n"
    $markdown += "- [Compétences Communes](#compétences-communes)`n"
    foreach ($skill in $CommonSkills) {
        $markdown += "  - [$($skill.Skill)](#$($skill.Skill.ToLower().Replace(' ', '-').Replace('/', '-').Replace('(', '').Replace(')', '').Replace('.', '')))`n"
    }
    
    # Résumé
    $markdown += "`n## <a name='résumé'></a>Résumé`n`n"
    
    $totalCommonSkills = $CommonSkills.Count
    $totalOccurrences = ($CommonSkills | Measure-Object -Property Occurrences -Sum).Sum
    
    $markdown += "**Nombre total de compétences communes :** $totalCommonSkills`n`n"
    $markdown += "**Nombre total d'occurrences :** $totalOccurrences`n`n"
    
    $markdown += "### Compétences les Plus Communes`n`n"
    $markdown += "| Compétence | Occurrences | Pourcentage |`n"
    $markdown += "|------------|-------------|-------------|`n"
    
    foreach ($skill in $CommonSkills | Sort-Object -Property Occurrences -Descending | Select-Object -First 10) {
        $percentage = [Math]::Round(($skill.Occurrences / $totalOccurrences) * 100, 1)
        $markdown += "| $($skill.Skill) | $($skill.Occurrences) | $percentage% |`n"
    }
    
    # Compétences communes
    $markdown += "`n## <a name='compétences-communes'></a>Compétences Communes`n`n"
    
    foreach ($skill in $CommonSkills) {
        $markdown += "### <a name='$($skill.Skill.ToLower().Replace(' ', '-').Replace('/', '-').Replace('(', '').Replace(')', '').Replace('.', ''))'></a>$($skill.Skill)`n`n"
        $markdown += "**Occurrences :** $($skill.Occurrences)`n`n"
        
        $markdown += "#### Distribution par Niveau d'Expertise`n`n"
        $markdown += "| Niveau | Occurrences | Pourcentage |`n"
        $markdown += "|--------|-------------|-------------|`n"
        
        foreach ($level in $skill.LevelDistribution | Sort-Object -Property Count -Descending) {
            $markdown += "| $($level.Level) | $($level.Count) | $($level.Percentage)% |`n"
        }
        
        $markdown += "`n#### Distribution par Catégorie`n`n"
        $markdown += "| Catégorie | Occurrences | Pourcentage |`n"
        $markdown += "|-----------|-------------|-------------|`n"
        
        foreach ($category in $skill.CategoryDistribution | Sort-Object -Property Count -Descending) {
            $markdown += "| $($category.Category) | $($category.Count) | $($category.Percentage)% |`n"
        }
        
        $markdown += "`n#### Distribution par Gestionnaire`n`n"
        $markdown += "| Gestionnaire | Occurrences | Pourcentage |`n"
        $markdown += "|--------------|-------------|-------------|`n"
        
        foreach ($manager in $skill.ManagerDistribution | Sort-Object -Property Count -Descending) {
            $markdown += "| $($manager.Manager) | $($manager.Count) | $($manager.Percentage)% |`n"
        }
        
        $markdown += "`n#### Améliorations Utilisant cette Compétence`n`n"
        $markdown += "| Gestionnaire | Amélioration |`n"
        $markdown += "|--------------|--------------|`n"
        
        foreach ($improvement in $skill.Improvements | Sort-Object -Property Manager, Improvement) {
            $markdown += "| $($improvement.Manager) | $($improvement.Improvement) |`n"
        }
        
        $markdown += "`n"
    }
    
    $markdown += "## Implications pour la Planification des Ressources`n`n"
    $markdown += "Les compétences communes identifiées dans ce document ont plusieurs implications importantes pour la planification des ressources humaines :`n`n"
    $markdown += "1. **Priorité de formation** : Ces compétences devraient être prioritaires dans les programmes de formation, car elles sont nécessaires pour plusieurs améliorations.`n"
    $markdown += "2. **Recrutement ciblé** : Lors du recrutement, il est judicieux de rechercher des candidats possédant ces compétences communes.`n"
    $markdown += "3. **Allocation des ressources** : Les membres de l'équipe possédant ces compétences communes peuvent être alloués de manière plus flexible entre différentes améliorations.`n"
    $markdown += "4. **Développement de l'expertise** : Il est stratégique de développer une expertise approfondie dans ces compétences communes au sein de l'équipe.`n"
    $markdown += "5. **Gestion des connaissances** : Une documentation et un partage des connaissances solides devraient être mis en place pour ces compétences communes.`n"
    
    return $markdown
}

# Fonction pour générer le rapport au format CSV
function Generate-CsvReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$CommonSkills
    )

    $csv = "Skill,Occurrences,Level,LevelCount,LevelPercentage,Category,CategoryCount,CategoryPercentage,Manager,ManagerCount,ManagerPercentage,ImprovementManager,Improvement`n"
    
    foreach ($skill in $CommonSkills) {
        foreach ($level in $skill.LevelDistribution) {
            foreach ($category in $skill.CategoryDistribution) {
                foreach ($manager in $skill.ManagerDistribution) {
                    foreach ($improvement in $skill.Improvements) {
                        $csv += "$($skill.Skill),$($skill.Occurrences),$($level.Level),$($level.Count),$($level.Percentage),$($category.Category),$($category.Count),$($category.Percentage),$($manager.Manager),$($manager.Count),$($manager.Percentage),$($improvement.Manager),$($improvement.Improvement)`n"
                    }
                }
            }
        }
    }
    
    return $csv
}

# Fonction pour générer le rapport au format JSON
function Generate-JsonReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$CommonSkills,
        
        [Parameter(Mandatory = $true)]
        [int]$MinimumOccurrences
    )

    $totalCommonSkills = $CommonSkills.Count
    $totalOccurrences = ($CommonSkills | Measure-Object -Property Occurrences -Sum).Sum
    
    $topSkills = $CommonSkills | Sort-Object -Property Occurrences -Descending | Select-Object -First 10 | ForEach-Object {
        $percentage = [Math]::Round(($_.Occurrences / $totalOccurrences) * 100, 1)
        
        [PSCustomObject]@{
            Skill = $_.Skill
            Occurrences = $_.Occurrences
            Percentage = $percentage
        }
    }
    
    $jsonData = [PSCustomObject]@{
        Summary = [PSCustomObject]@{
            TotalCommonSkills = $totalCommonSkills
            TotalOccurrences = $totalOccurrences
            MinimumOccurrences = $MinimumOccurrences
            TopSkills = $topSkills
        }
        CommonSkills = $CommonSkills
    }
    
    return $jsonData | ConvertTo-Json -Depth 10
}

# Lire le contenu de la liste des compétences
$listContent = Get-Content -Path $SkillsListPath -Raw

# Extraire les compétences de la liste
$extractionResult = Extract-SkillsFromList -MarkdownContent $listContent
$skills = $extractionResult.Skills

# Identifier les compétences communes
$commonSkills = Identify-CommonSkills -Skills $skills -MinimumOccurrences $MinimumOccurrences

# Générer le rapport dans le format spécifié
switch ($Format) {
    "Markdown" {
        $reportContent = Generate-MarkdownReport -CommonSkills $commonSkills -MinimumOccurrences $MinimumOccurrences
    }
    "CSV" {
        $reportContent = Generate-CsvReport -CommonSkills $commonSkills
    }
    "JSON" {
        $reportContent = Generate-JsonReport -CommonSkills $commonSkills -MinimumOccurrences $MinimumOccurrences
    }
}

# Enregistrer le rapport
try {
    $reportContent | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "Compétences communes identifiées avec succès : $OutputPath"
} catch {
    Write-Error "Erreur lors de l'enregistrement du rapport : $_"
    exit 1
}

# Afficher un résumé
Write-Host "`nRésumé de l'identification des compétences communes :"
Write-Host "---------------------------------------------------"

$totalCommonSkills = $commonSkills.Count
$totalOccurrences = ($commonSkills | Measure-Object -Property Occurrences -Sum).Sum

Write-Host "  Nombre total de compétences communes : $totalCommonSkills"
Write-Host "  Nombre total d'occurrences : $totalOccurrences"

Write-Host "`nTop 5 des compétences les plus communes :"
foreach ($skill in $commonSkills | Sort-Object -Property Occurrences -Descending | Select-Object -First 5) {
    $percentage = [Math]::Round(($skill.Occurrences / $totalOccurrences) * 100, 1)
    Write-Host "  $($skill.Skill) : $($skill.Occurrences) occurrences ($percentage%)"
}
