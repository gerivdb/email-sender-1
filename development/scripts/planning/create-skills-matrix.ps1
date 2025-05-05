<#
.SYNOPSIS
    CrÃ©e une matrice de compÃ©tences par gestionnaire.

.DESCRIPTION
    Ce script analyse la liste des compÃ©tences extraites et crÃ©e une matrice
    de compÃ©tences par gestionnaire, ce qui permet de visualiser les compÃ©tences
    requises pour chaque gestionnaire et d'identifier les synergies potentielles.

.PARAMETER SkillsListPath
    Chemin vers le fichier de la liste des compÃ©tences extraites.

.PARAMETER OutputPath
    Chemin vers le fichier de sortie pour la matrice de compÃ©tences.

.PARAMETER Format
    Format du fichier de sortie. Les valeurs possibles sont : JSON, CSV, Markdown.
    Par dÃ©faut : Markdown

.EXAMPLE
    .\create-skills-matrix.ps1 -SkillsListPath "data\planning\skills-list.md" -OutputPath "data\planning\skills-matrix.md"
    CrÃ©e une matrice de compÃ©tences par gestionnaire et gÃ©nÃ¨re un fichier Markdown.

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

# Fonction pour crÃ©er une matrice de compÃ©tences par gestionnaire
function Create-SkillsMatrix {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$Skills,
        
        [Parameter(Mandatory = $true)]
        [string[]]$Managers
    )

    # CrÃ©er une liste de toutes les compÃ©tences uniques
    $uniqueSkills = $Skills | Select-Object -Property Skill, Category -Unique | Sort-Object -Property Category, Skill
    
    # CrÃ©er une matrice de compÃ©tences par gestionnaire
    $skillsMatrix = @()
    
    foreach ($skill in $uniqueSkills) {
        $skillName = $skill.Skill
        $category = $skill.Category
        
        $managerSkills = @{}
        
        foreach ($manager in $Managers) {
            $managerSkill = $Skills | Where-Object { $_.Manager -eq $manager -and $_.Skill -eq $skillName } | Select-Object -First 1
            
            if ($managerSkill) {
                $managerSkills[$manager] = [PSCustomObject]@{
                    Level = $managerSkill.Level
                    Improvement = $managerSkill.Improvement
                    Justification = $managerSkill.Justification
                }
            } else {
                $managerSkills[$manager] = $null
            }
        }
        
        $skillsMatrix += [PSCustomObject]@{
            Skill = $skillName
            Category = $category
            ManagerSkills = $managerSkills
        }
    }
    
    # CrÃ©er une matrice d'amÃ©liorations par gestionnaire
    $improvementsMatrix = @()
    
    foreach ($manager in $Managers) {
        $managerImprovements = $Skills | Where-Object { $_.Manager -eq $manager } | Select-Object -Property Improvement -Unique | ForEach-Object { $_.Improvement }
        
        $improvementsMatrix += [PSCustomObject]@{
            Manager = $manager
            Improvements = $managerImprovements
        }
    }
    
    # CrÃ©er une matrice de compÃ©tences par catÃ©gorie
    $categoryMatrix = @()
    
    $categories = $uniqueSkills | Select-Object -Property Category -Unique | ForEach-Object { $_.Category }
    
    foreach ($category in $categories) {
        $categorySkills = $uniqueSkills | Where-Object { $_.Category -eq $category } | ForEach-Object { $_.Skill }
        
        $managerCategoryCounts = @{}
        
        foreach ($manager in $Managers) {
            $managerCategorySkills = $Skills | Where-Object { $_.Manager -eq $manager -and $_.Category -eq $category } | Select-Object -Property Skill -Unique | ForEach-Object { $_.Skill }
            $managerCategoryCounts[$manager] = $managerCategorySkills.Count
        }
        
        $categoryMatrix += [PSCustomObject]@{
            Category = $category
            Skills = $categorySkills
            ManagerCounts = $managerCategoryCounts
        }
    }
    
    # CrÃ©er une matrice de niveaux d'expertise par gestionnaire
    $levelMatrix = @()
    
    $levels = $Skills | Select-Object -Property Level -Unique | ForEach-Object { $_.Level }
    
    foreach ($level in $levels) {
        $managerLevelCounts = @{}
        
        foreach ($manager in $Managers) {
            $managerLevelSkills = $Skills | Where-Object { $_.Manager -eq $manager -and $_.Level -eq $level } | Select-Object -Property Skill -Unique | ForEach-Object { $_.Skill }
            $managerLevelCounts[$manager] = $managerLevelSkills.Count
        }
        
        $levelMatrix += [PSCustomObject]@{
            Level = $level
            ManagerCounts = $managerLevelCounts
        }
    }
    
    # CrÃ©er une matrice de synergies entre gestionnaires
    $synergyMatrix = @()
    
    foreach ($manager1 in $Managers) {
        $manager1Skills = $Skills | Where-Object { $_.Manager -eq $manager1 } | Select-Object -Property Skill -Unique | ForEach-Object { $_.Skill }
        
        $managerSynergies = @{}
        
        foreach ($manager2 in $Managers) {
            if ($manager1 -ne $manager2) {
                $manager2Skills = $Skills | Where-Object { $_.Manager -eq $manager2 } | Select-Object -Property Skill -Unique | ForEach-Object { $_.Skill }
                
                $commonSkills = $manager1Skills | Where-Object { $manager2Skills -contains $_ }
                
                $managerSynergies[$manager2] = [PSCustomObject]@{
                    CommonSkillCount = $commonSkills.Count
                    CommonSkills = $commonSkills
                }
            }
        }
        
        $synergyMatrix += [PSCustomObject]@{
            Manager = $manager1
            Synergies = $managerSynergies
        }
    }
    
    return [PSCustomObject]@{
        SkillsMatrix = $skillsMatrix
        ImprovementsMatrix = $improvementsMatrix
        CategoryMatrix = $categoryMatrix
        LevelMatrix = $levelMatrix
        SynergyMatrix = $synergyMatrix
    }
}

# Fonction pour gÃ©nÃ©rer le rapport au format Markdown
function Generate-MarkdownReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Matrix,
        
        [Parameter(Mandatory = $true)]
        [string[]]$Managers
    )

    $markdown = "# Matrice de CompÃ©tences par Gestionnaire`n`n"
    $markdown += "Ce document prÃ©sente une matrice de compÃ©tences par gestionnaire, ce qui permet de visualiser les compÃ©tences requises pour chaque gestionnaire et d'identifier les synergies potentielles.`n`n"
    
    $markdown += "## Table des MatiÃ¨res`n`n"
    $markdown += "- [RÃ©sumÃ©](#rÃ©sumÃ©)`n"
    $markdown += "- [Matrice de CompÃ©tences](#matrice-de-compÃ©tences)`n"
    $markdown += "- [Matrice par CatÃ©gorie](#matrice-par-catÃ©gorie)`n"
    $markdown += "- [Matrice par Niveau d'Expertise](#matrice-par-niveau-dexpertise)`n"
    $markdown += "- [Synergies entre Gestionnaires](#synergies-entre-gestionnaires)`n"
    $markdown += "- [AmÃ©liorations par Gestionnaire](#amÃ©liorations-par-gestionnaire)`n"
    $markdown += "- [Implications pour la Planification](#implications-pour-la-planification)`n"
    
    # RÃ©sumÃ©
    $markdown += "`n## <a name='rÃ©sumÃ©'></a>RÃ©sumÃ©`n`n"
    
    $totalSkills = $Matrix.SkillsMatrix.Count
    $totalCategories = $Matrix.CategoryMatrix.Count
    $totalLevels = $Matrix.LevelMatrix.Count
    
    $markdown += "**Nombre total de compÃ©tences uniques :** $totalSkills`n`n"
    $markdown += "**Nombre de catÃ©gories :** $totalCategories`n`n"
    $markdown += "**Nombre de niveaux d'expertise :** $totalLevels`n`n"
    
    $markdown += "### RÃ©partition des CompÃ©tences par Gestionnaire`n`n"
    $markdown += "| Gestionnaire | Nombre de CompÃ©tences | % du Total |`n"
    $markdown += "|--------------|----------------------|-----------|`n"
    
    foreach ($manager in $Managers) {
        $managerSkillCount = ($Matrix.SkillsMatrix | Where-Object { $_.ManagerSkills[$manager] -ne $null }).Count
        $percentage = [Math]::Round(($managerSkillCount / $totalSkills) * 100, 1)
        
        $markdown += "| $manager | $managerSkillCount | $percentage% |`n"
    }
    
    # Matrice de compÃ©tences
    $markdown += "`n## <a name='matrice-de-compÃ©tences'></a>Matrice de CompÃ©tences`n`n"
    $markdown += "Cette section prÃ©sente une matrice de toutes les compÃ©tences requises pour chaque gestionnaire.`n`n"
    
    $markdown += "| CatÃ©gorie | CompÃ©tence |"
    foreach ($manager in $Managers) {
        $markdown += " $manager |"
    }
    $markdown += "`n|-----------|------------|"
    foreach ($manager in $Managers) {
        $markdown += "------------|"
    }
    $markdown += "`n"
    
    $currentCategory = ""
    
    foreach ($skill in $Matrix.SkillsMatrix) {
        if ($skill.Category -ne $currentCategory) {
            $currentCategory = $skill.Category
            $markdown += "| **$currentCategory** | |"
            foreach ($manager in $Managers) {
                $markdown += " |"
            }
            $markdown += "`n"
        }
        
        $markdown += "| | $($skill.Skill) |"
        
        foreach ($manager in $Managers) {
            if ($skill.ManagerSkills[$manager]) {
                $markdown += " $($skill.ManagerSkills[$manager].Level) |"
            } else {
                $markdown += " |"
            }
        }
        
        $markdown += "`n"
    }
    
    # Matrice par catÃ©gorie
    $markdown += "`n## <a name='matrice-par-catÃ©gorie'></a>Matrice par CatÃ©gorie`n`n"
    $markdown += "Cette section prÃ©sente une matrice du nombre de compÃ©tences par catÃ©gorie pour chaque gestionnaire.`n`n"
    
    $markdown += "| CatÃ©gorie | Nombre de CompÃ©tences |"
    foreach ($manager in $Managers) {
        $markdown += " $manager |"
    }
    $markdown += "`n|-----------|----------------------|"
    foreach ($manager in $Managers) {
        $markdown += "------------|"
    }
    $markdown += "`n"
    
    foreach ($category in $Matrix.CategoryMatrix) {
        $markdown += "| $($category.Category) | $($category.Skills.Count) |"
        
        foreach ($manager in $Managers) {
            $markdown += " $($category.ManagerCounts[$manager]) |"
        }
        
        $markdown += "`n"
    }
    
    # Matrice par niveau d'expertise
    $markdown += "`n## <a name='matrice-par-niveau-dexpertise'></a>Matrice par Niveau d'Expertise`n`n"
    $markdown += "Cette section prÃ©sente une matrice du nombre de compÃ©tences par niveau d'expertise pour chaque gestionnaire.`n`n"
    
    $markdown += "| Niveau d'Expertise |"
    foreach ($manager in $Managers) {
        $markdown += " $manager |"
    }
    $markdown += "`n|-------------------|"
    foreach ($manager in $Managers) {
        $markdown += "------------|"
    }
    $markdown += "`n"
    
    foreach ($level in $Matrix.LevelMatrix) {
        $markdown += "| $($level.Level) |"
        
        foreach ($manager in $Managers) {
            $markdown += " $($level.ManagerCounts[$manager]) |"
        }
        
        $markdown += "`n"
    }
    
    # Synergies entre gestionnaires
    $markdown += "`n## <a name='synergies-entre-gestionnaires'></a>Synergies entre Gestionnaires`n`n"
    $markdown += "Cette section prÃ©sente les synergies potentielles entre gestionnaires en termes de compÃ©tences communes.`n`n"
    
    $markdown += "| Gestionnaire 1 | Gestionnaire 2 | CompÃ©tences Communes | % des CompÃ©tences de G1 | % des CompÃ©tences de G2 |`n"
    $markdown += "|---------------|---------------|---------------------|------------------------|------------------------|`n"
    
    foreach ($manager1 in $Managers) {
        $manager1SkillCount = ($Matrix.SkillsMatrix | Where-Object { $_.ManagerSkills[$manager1] -ne $null }).Count
        
        foreach ($manager2 in $Managers) {
            if ($manager1 -ne $manager2) {
                $manager2SkillCount = ($Matrix.SkillsMatrix | Where-Object { $_.ManagerSkills[$manager2] -ne $null }).Count
                
                $synergy = ($Matrix.SynergyMatrix | Where-Object { $_.Manager -eq $manager1 }).Synergies[$manager2]
                
                $commonSkillCount = $synergy.CommonSkillCount
                $percentageOfManager1 = [Math]::Round(($commonSkillCount / $manager1SkillCount) * 100, 1)
                $percentageOfManager2 = [Math]::Round(($commonSkillCount / $manager2SkillCount) * 100, 1)
                
                $markdown += "| $manager1 | $manager2 | $commonSkillCount | $percentageOfManager1% | $percentageOfManager2% |`n"
            }
        }
    }
    
    # DÃ©tails des synergies
    $markdown += "`n### DÃ©tails des Synergies`n`n"
    
    foreach ($manager1 in $Managers) {
        foreach ($manager2 in $Managers) {
            if ($manager1 -ne $manager2) {
                $synergy = ($Matrix.SynergyMatrix | Where-Object { $_.Manager -eq $manager1 }).Synergies[$manager2]
                
                if ($synergy.CommonSkillCount -gt 0) {
                    $markdown += "#### $manager1 - $manager2`n`n"
                    $markdown += "CompÃ©tences communes : $($synergy.CommonSkillCount)`n`n"
                    $markdown += "| CompÃ©tence | CatÃ©gorie | Niveau ($manager1) | Niveau ($manager2) |`n"
                    $markdown += "|------------|-----------|-----------------|-----------------|`n"
                    
                    foreach ($skillName in $synergy.CommonSkills) {
                        $skill = $Matrix.SkillsMatrix | Where-Object { $_.Skill -eq $skillName } | Select-Object -First 1
                        
                        $level1 = $skill.ManagerSkills[$manager1].Level
                        $level2 = $skill.ManagerSkills[$manager2].Level
                        
                        $markdown += "| $skillName | $($skill.Category) | $level1 | $level2 |`n"
                    }
                    
                    $markdown += "`n"
                }
            }
        }
    }
    
    # AmÃ©liorations par gestionnaire
    $markdown += "`n## <a name='amÃ©liorations-par-gestionnaire'></a>AmÃ©liorations par Gestionnaire`n`n"
    $markdown += "Cette section prÃ©sente les amÃ©liorations identifiÃ©es pour chaque gestionnaire.`n`n"
    
    foreach ($manager in $Managers) {
        $markdown += "### $manager`n`n"
        
        $improvements = ($Matrix.ImprovementsMatrix | Where-Object { $_.Manager -eq $manager }).Improvements
        
        if ($improvements.Count -gt 0) {
            $markdown += "| AmÃ©lioration | CompÃ©tences Requises |`n"
            $markdown += "|--------------|---------------------|`n"
            
            foreach ($improvement in $improvements) {
                $improvementSkills = $Skills | Where-Object { $_.Manager -eq $manager -and $_.Improvement -eq $improvement } | Select-Object -Property Skill -Unique | ForEach-Object { $_.Skill }
                
                $markdown += "| $improvement | $($improvementSkills.Count) |`n"
            }
        } else {
            $markdown += "Aucune amÃ©lioration identifiÃ©e pour ce gestionnaire.`n"
        }
        
        $markdown += "`n"
    }
    
    # Implications pour la planification
    $markdown += "`n## <a name='implications-pour-la-planification'></a>Implications pour la Planification`n`n"
    $markdown += "Cette matrice de compÃ©tences par gestionnaire a plusieurs implications importantes pour la planification des ressources humaines :`n`n"
    
    $markdown += "### Allocation des Ressources`n`n"
    $markdown += "1. **Ã‰quipes transversales** : Former des Ã©quipes transversales pour les gestionnaires ayant des compÃ©tences communes.`n"
    $markdown += "2. **Partage des ressources** : Partager les ressources humaines entre gestionnaires pour les compÃ©tences communes.`n"
    $markdown += "3. **SpÃ©cialisation** : Identifier les besoins en spÃ©cialistes pour les compÃ©tences uniques Ã  certains gestionnaires.`n"
    
    $markdown += "`n### Formation et DÃ©veloppement`n`n"
    $markdown += "1. **Programmes de formation** : DÃ©velopper des programmes de formation ciblÃ©s pour les compÃ©tences les plus demandÃ©es.`n"
    $markdown += "2. **DÃ©veloppement des compÃ©tences** : Encourager le dÃ©veloppement des compÃ©tences communes pour faciliter la mobilitÃ© entre gestionnaires.`n"
    $markdown += "3. **Mentorat** : Mettre en place des programmes de mentorat pour les compÃ©tences rares ou spÃ©cialisÃ©es.`n"
    
    $markdown += "`n### Recrutement`n`n"
    $markdown += "1. **Profils polyvalents** : Recruter des profils polyvalents possÃ©dant des compÃ©tences communes Ã  plusieurs gestionnaires.`n"
    $markdown += "2. **SpÃ©cialistes** : Recruter des spÃ©cialistes pour les compÃ©tences uniques Ã  certains gestionnaires.`n"
    $markdown += "3. **Ã‰quilibre des compÃ©tences** : Veiller Ã  maintenir un Ã©quilibre des compÃ©tences au sein de l'Ã©quipe.`n"
    
    return $markdown
}

# Fonction pour gÃ©nÃ©rer le rapport au format CSV
function Generate-CsvReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Matrix,
        
        [Parameter(Mandatory = $true)]
        [string[]]$Managers
    )

    $csv = "Type,Category,Skill"
    foreach ($manager in $Managers) {
        $csv += ",$manager"
    }
    $csv += "`n"
    
    foreach ($skill in $Matrix.SkillsMatrix) {
        $csv += "Skill,$($skill.Category),$($skill.Skill)"
        
        foreach ($manager in $Managers) {
            if ($skill.ManagerSkills[$manager]) {
                $csv += ",$($skill.ManagerSkills[$manager].Level)"
            } else {
                $csv += ","
            }
        }
        
        $csv += "`n"
    }
    
    $csv += "`nType,Category,SkillCount"
    foreach ($manager in $Managers) {
        $csv += ",$manager"
    }
    $csv += "`n"
    
    foreach ($category in $Matrix.CategoryMatrix) {
        $csv += "Category,$($category.Category),$($category.Skills.Count)"
        
        foreach ($manager in $Managers) {
            $csv += ",$($category.ManagerCounts[$manager])"
        }
        
        $csv += "`n"
    }
    
    $csv += "`nType,Level"
    foreach ($manager in $Managers) {
        $csv += ",$manager"
    }
    $csv += "`n"
    
    foreach ($level in $Matrix.LevelMatrix) {
        $csv += "Level,$($level.Level)"
        
        foreach ($manager in $Managers) {
            $csv += ",$($level.ManagerCounts[$manager])"
        }
        
        $csv += "`n"
    }
    
    $csv += "`nType,Manager1,Manager2,CommonSkillCount,PercentageOfManager1,PercentageOfManager2`n"
    
    foreach ($manager1 in $Managers) {
        $manager1SkillCount = ($Matrix.SkillsMatrix | Where-Object { $_.ManagerSkills[$manager1] -ne $null }).Count
        
        foreach ($manager2 in $Managers) {
            if ($manager1 -ne $manager2) {
                $manager2SkillCount = ($Matrix.SkillsMatrix | Where-Object { $_.ManagerSkills[$manager2] -ne $null }).Count
                
                $synergy = ($Matrix.SynergyMatrix | Where-Object { $_.Manager -eq $manager1 }).Synergies[$manager2]
                
                $commonSkillCount = $synergy.CommonSkillCount
                $percentageOfManager1 = [Math]::Round(($commonSkillCount / $manager1SkillCount) * 100, 1)
                $percentageOfManager2 = [Math]::Round(($commonSkillCount / $manager2SkillCount) * 100, 1)
                
                $csv += "Synergy,$manager1,$manager2,$commonSkillCount,$percentageOfManager1,$percentageOfManager2`n"
            }
        }
    }
    
    return $csv
}

# Fonction pour gÃ©nÃ©rer le rapport au format JSON
function Generate-JsonReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Matrix
    )

    return $Matrix | ConvertTo-Json -Depth 10
}

# Lire le contenu de la liste des compÃ©tences
$listContent = Get-Content -Path $SkillsListPath -Raw

# Extraire les compÃ©tences de la liste
$extractionResult = Extract-SkillsFromList -MarkdownContent $listContent
$skills = $extractionResult.Skills
$managers = $extractionResult.Managers

# CrÃ©er une matrice de compÃ©tences par gestionnaire
$matrix = Create-SkillsMatrix -Skills $skills -Managers $managers

# GÃ©nÃ©rer le rapport dans le format spÃ©cifiÃ©
switch ($Format) {
    "Markdown" {
        $reportContent = Generate-MarkdownReport -Matrix $matrix -Managers $managers
    }
    "CSV" {
        $reportContent = Generate-CsvReport -Matrix $matrix -Managers $managers
    }
    "JSON" {
        $reportContent = Generate-JsonReport -Matrix $matrix
    }
}

# Enregistrer le rapport
try {
    $reportContent | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "Matrice de compÃ©tences par gestionnaire gÃ©nÃ©rÃ©e avec succÃ¨s : $OutputPath"
} catch {
    Write-Error "Erreur lors de l'enregistrement du rapport : $_"
    exit 1
}

# Afficher un rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ© de la matrice de compÃ©tences par gestionnaire :"
Write-Host "---------------------------------------------------"

$totalSkills = $matrix.SkillsMatrix.Count
$totalCategories = $matrix.CategoryMatrix.Count
$totalLevels = $matrix.LevelMatrix.Count

Write-Host "  Nombre total de compÃ©tences uniques : $totalSkills"
Write-Host "  Nombre de catÃ©gories : $totalCategories"
Write-Host "  Nombre de niveaux d'expertise : $totalLevels"

Write-Host "`nRÃ©partition des compÃ©tences par gestionnaire :"
foreach ($manager in $managers) {
    $managerSkillCount = ($matrix.SkillsMatrix | Where-Object { $_.ManagerSkills[$manager] -ne $null }).Count
    $percentage = [Math]::Round(($managerSkillCount / $totalSkills) * 100, 1)
    
    Write-Host "  $manager : $managerSkillCount compÃ©tences ($percentage%)"
}

Write-Host "`nSynergies entre gestionnaires :"
foreach ($manager1 in $managers) {
    foreach ($manager2 in $managers) {
        if ($manager1 -ne $manager2) {
            $synergy = ($matrix.SynergyMatrix | Where-Object { $_.Manager -eq $manager1 }).Synergies[$manager2]
            
            if ($synergy.CommonSkillCount -gt 0) {
                Write-Host "  $manager1 - $manager2 : $($synergy.CommonSkillCount) compÃ©tences communes"
            }
        }
    }
}
