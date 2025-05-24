<#
.SYNOPSIS
    Identifie les compÃ©tences communes Ã  plusieurs amÃ©liorations.

.DESCRIPTION
    Ce script analyse la liste des compÃ©tences extraites et identifie celles qui sont
    communes Ã  plusieurs amÃ©liorations, ce qui permet de dÃ©terminer les compÃ©tences
    les plus importantes et polyvalentes.

.PARAMETER SkillsListPath
    Chemin vers le fichier de la liste des compÃ©tences extraites.

.PARAMETER OutputPath
    Chemin vers le fichier de sortie pour la liste des compÃ©tences communes.

.PARAMETER MinimumOccurrences
    Nombre minimum d'occurrences pour qu'une compÃ©tence soit considÃ©rÃ©e comme commune.
    Par dÃ©faut : 2

.PARAMETER Format
    Format du fichier de sortie. Les valeurs possibles sont : JSON, CSV, Markdown.
    Par dÃ©faut : Markdown

.EXAMPLE
    .\identify-common-skills.ps1 -SkillsListPath "data\planning\skills-list.md" -OutputPath "data\planning\common-skills.md"
    Identifie les compÃ©tences communes Ã  plusieurs amÃ©liorations et gÃ©nÃ¨re un fichier Markdown.

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
    [int]$MinimumOccurrences = 2,

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
function Export-SkillsFromList {
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

# Fonction pour identifier les compÃ©tences communes
function Find-CommonSkills {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$Skills,
        
        [Parameter(Mandatory = $true)]
        [int]$MinimumOccurrences
    )

    # Regrouper les compÃ©tences par nom et compter les occurrences
    $skillOccurrences = $Skills | Group-Object -Property Skill | Sort-Object -Property Count -Descending
    
    # Filtrer les compÃ©tences qui apparaissent au moins le nombre minimum de fois
    $commonSkills = $skillOccurrences | Where-Object { $_.Count -ge $MinimumOccurrences }
    
    # Pour chaque compÃ©tence commune, identifier les amÃ©liorations qui l'utilisent
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
        
        # Regrouper par catÃ©gorie
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
        
        # Identifier les amÃ©liorations qui utilisent cette compÃ©tence
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

# Fonction pour gÃ©nÃ©rer le rapport au format Markdown
function New-MarkdownReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$CommonSkills,
        
        [Parameter(Mandatory = $true)]
        [int]$MinimumOccurrences
    )

    $markdown = "# CompÃ©tences Communes Ã  Plusieurs AmÃ©liorations`n`n"
    $markdown += "Ce document prÃ©sente les compÃ©tences qui sont communes Ã  plusieurs amÃ©liorations, ce qui permet de dÃ©terminer les compÃ©tences les plus importantes et polyvalentes.`n`n"
    
    $markdown += "## CritÃ¨res d'Identification`n`n"
    $markdown += "Une compÃ©tence est considÃ©rÃ©e comme commune si elle apparaÃ®t dans au moins $MinimumOccurrences amÃ©liorations diffÃ©rentes.`n`n"
    
    $markdown += "## Table des MatiÃ¨res`n`n"
    $markdown += "- [RÃ©sumÃ©](#rÃ©sumÃ©)`n"
    $markdown += "- [CompÃ©tences Communes](#compÃ©tences-communes)`n"
    foreach ($skill in $CommonSkills) {
        $markdown += "  - [$($skill.Skill)](#$($skill.Skill.ToLower().Replace(' ', '-').Replace('/', '-').Replace('(', '').Replace(')', '').Replace('.', '')))`n"
    }
    
    # RÃ©sumÃ©
    $markdown += "`n## <a name='rÃ©sumÃ©'></a>RÃ©sumÃ©`n`n"
    
    $totalCommonSkills = $CommonSkills.Count
    $totalOccurrences = ($CommonSkills | Measure-Object -Property Occurrences -Sum).Sum
    
    $markdown += "**Nombre total de compÃ©tences communes :** $totalCommonSkills`n`n"
    $markdown += "**Nombre total d'occurrences :** $totalOccurrences`n`n"
    
    $markdown += "### CompÃ©tences les Plus Communes`n`n"
    $markdown += "| CompÃ©tence | Occurrences | Pourcentage |`n"
    $markdown += "|------------|-------------|-------------|`n"
    
    foreach ($skill in $CommonSkills | Sort-Object -Property Occurrences -Descending | Select-Object -First 10) {
        $percentage = [Math]::Round(($skill.Occurrences / $totalOccurrences) * 100, 1)
        $markdown += "| $($skill.Skill) | $($skill.Occurrences) | $percentage% |`n"
    }
    
    # CompÃ©tences communes
    $markdown += "`n## <a name='compÃ©tences-communes'></a>CompÃ©tences Communes`n`n"
    
    foreach ($skill in $CommonSkills) {
        $markdown += "### <a name='$($skill.Skill.ToLower().Replace(' ', '-').Replace('/', '-').Replace('(', '').Replace(')', '').Replace('.', ''))'></a>$($skill.Skill)`n`n"
        $markdown += "**Occurrences :** $($skill.Occurrences)`n`n"
        
        $markdown += "#### Distribution par Niveau d'Expertise`n`n"
        $markdown += "| Niveau | Occurrences | Pourcentage |`n"
        $markdown += "|--------|-------------|-------------|`n"
        
        foreach ($level in $skill.LevelDistribution | Sort-Object -Property Count -Descending) {
            $markdown += "| $($level.Level) | $($level.Count) | $($level.Percentage)% |`n"
        }
        
        $markdown += "`n#### Distribution par CatÃ©gorie`n`n"
        $markdown += "| CatÃ©gorie | Occurrences | Pourcentage |`n"
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
        
        $markdown += "`n#### AmÃ©liorations Utilisant cette CompÃ©tence`n`n"
        $markdown += "| Gestionnaire | AmÃ©lioration |`n"
        $markdown += "|--------------|--------------|`n"
        
        foreach ($improvement in $skill.Improvements | Sort-Object -Property Manager, Improvement) {
            $markdown += "| $($improvement.Manager) | $($improvement.Improvement) |`n"
        }
        
        $markdown += "`n"
    }
    
    $markdown += "## Implications pour la Planification des Ressources`n`n"
    $markdown += "Les compÃ©tences communes identifiÃ©es dans ce document ont plusieurs implications importantes pour la planification des ressources humaines :`n`n"
    $markdown += "1. **PrioritÃ© de formation** : Ces compÃ©tences devraient Ãªtre prioritaires dans les programmes de formation, car elles sont nÃ©cessaires pour plusieurs amÃ©liorations.`n"
    $markdown += "2. **Recrutement ciblÃ©** : Lors du recrutement, il est judicieux de rechercher des candidats possÃ©dant ces compÃ©tences communes.`n"
    $markdown += "3. **Allocation des ressources** : Les membres de l'Ã©quipe possÃ©dant ces compÃ©tences communes peuvent Ãªtre allouÃ©s de maniÃ¨re plus flexible entre diffÃ©rentes amÃ©liorations.`n"
    $markdown += "4. **DÃ©veloppement de l'expertise** : Il est stratÃ©gique de dÃ©velopper une expertise approfondie dans ces compÃ©tences communes au sein de l'Ã©quipe.`n"
    $markdown += "5. **Gestion des connaissances** : Une documentation et un partage des connaissances solides devraient Ãªtre mis en place pour ces compÃ©tences communes.`n"
    
    return $markdown
}

# Fonction pour gÃ©nÃ©rer le rapport au format CSV
function New-CsvReport {
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

# Fonction pour gÃ©nÃ©rer le rapport au format JSON
function New-JsonReport {
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

# Lire le contenu de la liste des compÃ©tences
$listContent = Get-Content -Path $SkillsListPath -Raw

# Extraire les compÃ©tences de la liste
$extractionResult = Export-SkillsFromList -MarkdownContent $listContent
$skills = $extractionResult.Skills

# Identifier les compÃ©tences communes
$commonSkills = Find-CommonSkills -Skills $skills -MinimumOccurrences $MinimumOccurrences

# GÃ©nÃ©rer le rapport dans le format spÃ©cifiÃ©
switch ($Format) {
    "Markdown" {
        $reportContent = New-MarkdownReport -CommonSkills $commonSkills -MinimumOccurrences $MinimumOccurrences
    }
    "CSV" {
        $reportContent = New-CsvReport -CommonSkills $commonSkills
    }
    "JSON" {
        $reportContent = New-JsonReport -CommonSkills $commonSkills -MinimumOccurrences $MinimumOccurrences
    }
}

# Enregistrer le rapport
try {
    $reportContent | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "CompÃ©tences communes identifiÃ©es avec succÃ¨s : $OutputPath"
} catch {
    Write-Error "Erreur lors de l'enregistrement du rapport : $_"
    exit 1
}

# Afficher un rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ© de l'identification des compÃ©tences communes :"
Write-Host "---------------------------------------------------"

$totalCommonSkills = $commonSkills.Count
$totalOccurrences = ($commonSkills | Measure-Object -Property Occurrences -Sum).Sum

Write-Host "  Nombre total de compÃ©tences communes : $totalCommonSkills"
Write-Host "  Nombre total d'occurrences : $totalOccurrences"

Write-Host "`nTop 5 des compÃ©tences les plus communes :"
foreach ($skill in $commonSkills | Sort-Object -Property Occurrences -Descending | Select-Object -First 5) {
    $percentage = [Math]::Round(($skill.Occurrences / $totalOccurrences) * 100, 1)
    Write-Host "  $($skill.Skill) : $($skill.Occurrences) occurrences ($percentage%)"
}


