<#
.SYNOPSIS
    Extrait la liste des compÃ©tences du rapport des compÃ©tences requises.

.DESCRIPTION
    Ce script analyse le rapport des compÃ©tences requises et extrait la liste complÃ¨te
    des compÃ©tences identifiÃ©es pour chaque amÃ©lioration.

.PARAMETER SkillsReportPath
    Chemin vers le fichier du rapport des compÃ©tences requises.

.PARAMETER OutputPath
    Chemin vers le fichier de sortie pour la liste des compÃ©tences extraites.

.PARAMETER Format
    Format du fichier de sortie. Les valeurs possibles sont : JSON, CSV, Markdown.
    Par dÃ©faut : Markdown

.EXAMPLE
    .\extract-required-skills.ps1 -SkillsReportPath "data\planning\required-skills.md" -OutputPath "data\planning\skills-list.md"
    Extrait la liste des compÃ©tences du rapport des compÃ©tences requises et gÃ©nÃ¨re un fichier Markdown.

.NOTES
    Auteur: Planning Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-10
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$SkillsReportPath,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [ValidateSet("JSON", "CSV", "Markdown")]
    [string]$Format = "Markdown"
)

# VÃ©rifier que le fichier d'entrÃ©e existe
if (-not (Test-Path -Path $SkillsReportPath)) {
    Write-Error "Le fichier du rapport des compÃ©tences requises n'existe pas : $SkillsReportPath"
    exit 1
}

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
$outputDir = Split-Path -Path $OutputPath -Parent
if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

# Fonction pour extraire les compÃ©tences du rapport Markdown
function Export-SkillsFromMarkdown {
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

# Fonction pour gÃ©nÃ©rer le rapport au format Markdown
function New-MarkdownReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$Skills,
        
        [Parameter(Mandatory = $true)]
        [string[]]$Managers
    )

    $markdown = "# Liste des CompÃ©tences Requises`n`n"
    $markdown += "Ce document prÃ©sente la liste des compÃ©tences requises extraites du rapport des compÃ©tences requises.`n`n"
    
    $markdown += "## Table des MatiÃ¨res`n`n"
    $markdown += "- [RÃ©sumÃ© des CompÃ©tences](#rÃ©sumÃ©-des-compÃ©tences)`n"
    $markdown += "- [CompÃ©tences par CatÃ©gorie](#compÃ©tences-par-catÃ©gorie)`n"
    foreach ($manager in $Managers) {
        $markdown += "- [$manager](#$($manager.ToLower().Replace(' ', '-')))`n"
    }
    
    # RÃ©sumÃ© des compÃ©tences
    $markdown += "`n## RÃ©sumÃ© des CompÃ©tences`n`n"
    
    $uniqueSkills = $Skills | Select-Object -Property Category, Skill -Unique | Sort-Object -Property Category, Skill
    $totalSkills = $uniqueSkills.Count
    $totalOccurrences = $Skills.Count
    
    $markdown += "**Nombre total de compÃ©tences uniques :** $totalSkills`n`n"
    $markdown += "**Nombre total d'occurrences :** $totalOccurrences`n`n"
    
    # CompÃ©tences les plus demandÃ©es
    $skillOccurrences = $Skills | Group-Object -Property Skill | Sort-Object -Property Count -Descending | Select-Object -First 10
    
    $markdown += "### CompÃ©tences les Plus DemandÃ©es`n`n"
    $markdown += "| CompÃ©tence | Occurrences | Pourcentage |`n"
    $markdown += "|------------|-------------|-------------|`n"
    
    foreach ($skillOccurrence in $skillOccurrences) {
        $percentage = [Math]::Round(($skillOccurrence.Count / $totalOccurrences) * 100, 1)
        $markdown += "| $($skillOccurrence.Name) | $($skillOccurrence.Count) | $percentage% |`n"
    }
    
    # CompÃ©tences par catÃ©gorie
    $markdown += "`n## CompÃ©tences par CatÃ©gorie`n`n"
    
    $categories = $uniqueSkills | Group-Object -Property Category | Sort-Object -Property Name
    
    foreach ($category in $categories) {
        $markdown += "### $($category.Name)`n`n"
        $markdown += "| CompÃ©tence | Occurrences |`n"
        $markdown += "|------------|-------------|`n"
        
        $categorySkills = $Skills | Where-Object { $_.Category -eq $category.Name } | Group-Object -Property Skill | Sort-Object -Property Count -Descending
        
        foreach ($skill in $categorySkills) {
            $markdown += "| $($skill.Name) | $($skill.Count) |`n"
        }
        
        $markdown += "`n"
    }
    
    # CompÃ©tences par gestionnaire
    foreach ($manager in $Managers) {
        $markdown += "## <a name='$($manager.ToLower().Replace(' ', '-'))'></a>$manager`n`n"
        
        $managerSkills = $Skills | Where-Object { $_.Manager -eq $manager }
        $managerImprovements = $managerSkills | Select-Object -Property Improvement -Unique
        
        foreach ($improvement in $managerImprovements) {
            $markdown += "### $($improvement.Improvement)`n`n"
            $markdown += "| CatÃ©gorie | CompÃ©tence | Niveau | Justification |`n"
            $markdown += "|-----------|------------|--------|---------------|`n"
            
            $improvementSkills = $managerSkills | Where-Object { $_.Improvement -eq $improvement.Improvement } | Sort-Object -Property Category, Skill
            
            foreach ($skill in $improvementSkills) {
                $markdown += "| $($skill.Category) | $($skill.Skill) | $($skill.Level) | $($skill.Justification) |`n"
            }
            
            $markdown += "`n"
        }
    }
    
    return $markdown
}

# Fonction pour gÃ©nÃ©rer le rapport au format CSV
function New-CsvReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$Skills
    )

    $csv = "Manager,Improvement,Category,Skill,Level,Justification`n"
    
    foreach ($skill in $Skills) {
        $csv += "$($skill.Manager),$($skill.Improvement),$($skill.Category),$($skill.Skill),$($skill.Level),$($skill.Justification)`n"
    }
    
    return $csv
}

# Fonction pour gÃ©nÃ©rer le rapport au format JSON
function New-JsonReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$Skills,
        
        [Parameter(Mandatory = $true)]
        [string[]]$Managers
    )

    $uniqueSkills = $Skills | Select-Object -Property Category, Skill -Unique | Sort-Object -Property Category, Skill
    $skillOccurrences = $Skills | Group-Object -Property Skill | Sort-Object -Property Count -Descending | Select-Object -First 10 | ForEach-Object {
        [PSCustomObject]@{
            Skill = $_.Name
            Occurrences = $_.Count
            Percentage = [Math]::Round(($_.Count / $Skills.Count) * 100, 1)
        }
    }
    
    $categories = $uniqueSkills | Group-Object -Property Category | Sort-Object -Property Name | ForEach-Object {
        $categorySkills = $Skills | Where-Object { $_.Category -eq $_.Name } | Group-Object -Property Skill | Sort-Object -Property Count -Descending | ForEach-Object {
            [PSCustomObject]@{
                Skill = $_.Name
                Occurrences = $_.Count
            }
        }
        
        [PSCustomObject]@{
            Category = $_.Name
            Skills = $categorySkills
        }
    }
    
    $managerData = $Managers | ForEach-Object {
        $managerName = $_
        $managerSkills = $Skills | Where-Object { $_.Manager -eq $managerName }
        $managerImprovements = $managerSkills | Select-Object -Property Improvement -Unique | ForEach-Object {
            $improvementName = $_.Improvement
            $improvementSkills = $managerSkills | Where-Object { $_.Improvement -eq $improvementName } | Sort-Object -Property Category, Skill
            
            [PSCustomObject]@{
                Improvement = $improvementName
                Skills = $improvementSkills
            }
        }
        
        [PSCustomObject]@{
            Manager = $managerName
            Improvements = $managerImprovements
        }
    }
    
    $jsonData = [PSCustomObject]@{
        Summary = [PSCustomObject]@{
            TotalUniqueSkills = $uniqueSkills.Count
            TotalOccurrences = $Skills.Count
            MostDemandedSkills = $skillOccurrences
        }
        SkillsByCategory = $categories
        SkillsByManager = $managerData
    }
    
    return $jsonData | ConvertTo-Json -Depth 10
}

# Lire le contenu du rapport des compÃ©tences requises
$reportContent = Get-Content -Path $SkillsReportPath -Raw

# Extraire les compÃ©tences du rapport
$extractionResult = Export-SkillsFromMarkdown -MarkdownContent $reportContent
$skills = $extractionResult.Skills
$managers = $extractionResult.Managers

# GÃ©nÃ©rer le rapport dans le format spÃ©cifiÃ©
switch ($Format) {
    "Markdown" {
        $reportContent = New-MarkdownReport -Skills $skills -Managers $managers
    }
    "CSV" {
        $reportContent = New-CsvReport -Skills $skills
    }
    "JSON" {
        $reportContent = New-JsonReport -Skills $skills -Managers $managers
    }
}

# Enregistrer le rapport
try {
    $reportContent | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "Liste des compÃ©tences extraite avec succÃ¨s : $OutputPath"
} catch {
    Write-Error "Erreur lors de l'enregistrement du rapport : $_"
    exit 1
}

# Afficher un rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ© de l'extraction des compÃ©tences :"
Write-Host "--------------------------------------"

$uniqueSkills = $skills | Select-Object -Property Category, Skill -Unique | Sort-Object -Property Category, Skill
$totalSkills = $uniqueSkills.Count
$totalOccurrences = $skills.Count

Write-Host "  Nombre total de compÃ©tences uniques : $totalSkills"
Write-Host "  Nombre total d'occurrences : $totalOccurrences"

$categories = $uniqueSkills | Group-Object -Property Category | Sort-Object -Property Name

Write-Host "`nRÃ©partition par catÃ©gorie :"
foreach ($category in $categories) {
    Write-Host "  $($category.Name) : $($category.Count) compÃ©tences"
}

$skillOccurrences = $skills | Group-Object -Property Skill | Sort-Object -Property Count -Descending | Select-Object -First 5

Write-Host "`nTop 5 des compÃ©tences les plus demandÃ©es :"
foreach ($skillOccurrence in $skillOccurrences) {
    $percentage = [Math]::Round(($skillOccurrence.Count / $totalOccurrences) * 100, 1)
    Write-Host "  $($skillOccurrence.Name) : $($skillOccurrence.Count) occurrences ($percentage%)"
}

