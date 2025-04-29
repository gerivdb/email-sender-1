<#
.SYNOPSIS
    Extrait la liste des compétences du rapport des compétences requises.

.DESCRIPTION
    Ce script analyse le rapport des compétences requises et extrait la liste complète
    des compétences identifiées pour chaque amélioration.

.PARAMETER SkillsReportPath
    Chemin vers le fichier du rapport des compétences requises.

.PARAMETER OutputPath
    Chemin vers le fichier de sortie pour la liste des compétences extraites.

.PARAMETER Format
    Format du fichier de sortie. Les valeurs possibles sont : JSON, CSV, Markdown.
    Par défaut : Markdown

.EXAMPLE
    .\extract-required-skills.ps1 -SkillsReportPath "data\planning\required-skills.md" -OutputPath "data\planning\skills-list.md"
    Extrait la liste des compétences du rapport des compétences requises et génère un fichier Markdown.

.NOTES
    Auteur: Planning Team
    Version: 1.0
    Date de création: 2025-05-10
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

# Vérifier que le fichier d'entrée existe
if (-not (Test-Path -Path $SkillsReportPath)) {
    Write-Error "Le fichier du rapport des compétences requises n'existe pas : $SkillsReportPath"
    exit 1
}

# Créer le répertoire de sortie s'il n'existe pas
$outputDir = Split-Path -Path $OutputPath -Parent
if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

# Fonction pour extraire les compétences du rapport Markdown
function Extract-SkillsFromMarkdown {
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

# Fonction pour générer le rapport au format Markdown
function Generate-MarkdownReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$Skills,
        
        [Parameter(Mandatory = $true)]
        [string[]]$Managers
    )

    $markdown = "# Liste des Compétences Requises`n`n"
    $markdown += "Ce document présente la liste des compétences requises extraites du rapport des compétences requises.`n`n"
    
    $markdown += "## Table des Matières`n`n"
    $markdown += "- [Résumé des Compétences](#résumé-des-compétences)`n"
    $markdown += "- [Compétences par Catégorie](#compétences-par-catégorie)`n"
    foreach ($manager in $Managers) {
        $markdown += "- [$manager](#$($manager.ToLower().Replace(' ', '-')))`n"
    }
    
    # Résumé des compétences
    $markdown += "`n## Résumé des Compétences`n`n"
    
    $uniqueSkills = $Skills | Select-Object -Property Category, Skill -Unique | Sort-Object -Property Category, Skill
    $totalSkills = $uniqueSkills.Count
    $totalOccurrences = $Skills.Count
    
    $markdown += "**Nombre total de compétences uniques :** $totalSkills`n`n"
    $markdown += "**Nombre total d'occurrences :** $totalOccurrences`n`n"
    
    # Compétences les plus demandées
    $skillOccurrences = $Skills | Group-Object -Property Skill | Sort-Object -Property Count -Descending | Select-Object -First 10
    
    $markdown += "### Compétences les Plus Demandées`n`n"
    $markdown += "| Compétence | Occurrences | Pourcentage |`n"
    $markdown += "|------------|-------------|-------------|`n"
    
    foreach ($skillOccurrence in $skillOccurrences) {
        $percentage = [Math]::Round(($skillOccurrence.Count / $totalOccurrences) * 100, 1)
        $markdown += "| $($skillOccurrence.Name) | $($skillOccurrence.Count) | $percentage% |`n"
    }
    
    # Compétences par catégorie
    $markdown += "`n## Compétences par Catégorie`n`n"
    
    $categories = $uniqueSkills | Group-Object -Property Category | Sort-Object -Property Name
    
    foreach ($category in $categories) {
        $markdown += "### $($category.Name)`n`n"
        $markdown += "| Compétence | Occurrences |`n"
        $markdown += "|------------|-------------|`n"
        
        $categorySkills = $Skills | Where-Object { $_.Category -eq $category.Name } | Group-Object -Property Skill | Sort-Object -Property Count -Descending
        
        foreach ($skill in $categorySkills) {
            $markdown += "| $($skill.Name) | $($skill.Count) |`n"
        }
        
        $markdown += "`n"
    }
    
    # Compétences par gestionnaire
    foreach ($manager in $Managers) {
        $markdown += "## <a name='$($manager.ToLower().Replace(' ', '-'))'></a>$manager`n`n"
        
        $managerSkills = $Skills | Where-Object { $_.Manager -eq $manager }
        $managerImprovements = $managerSkills | Select-Object -Property Improvement -Unique
        
        foreach ($improvement in $managerImprovements) {
            $markdown += "### $($improvement.Improvement)`n`n"
            $markdown += "| Catégorie | Compétence | Niveau | Justification |`n"
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

# Fonction pour générer le rapport au format CSV
function Generate-CsvReport {
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

# Fonction pour générer le rapport au format JSON
function Generate-JsonReport {
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

# Lire le contenu du rapport des compétences requises
$reportContent = Get-Content -Path $SkillsReportPath -Raw

# Extraire les compétences du rapport
$extractionResult = Extract-SkillsFromMarkdown -MarkdownContent $reportContent
$skills = $extractionResult.Skills
$managers = $extractionResult.Managers

# Générer le rapport dans le format spécifié
switch ($Format) {
    "Markdown" {
        $reportContent = Generate-MarkdownReport -Skills $skills -Managers $managers
    }
    "CSV" {
        $reportContent = Generate-CsvReport -Skills $skills
    }
    "JSON" {
        $reportContent = Generate-JsonReport -Skills $skills -Managers $managers
    }
}

# Enregistrer le rapport
try {
    $reportContent | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "Liste des compétences extraite avec succès : $OutputPath"
} catch {
    Write-Error "Erreur lors de l'enregistrement du rapport : $_"
    exit 1
}

# Afficher un résumé
Write-Host "`nRésumé de l'extraction des compétences :"
Write-Host "--------------------------------------"

$uniqueSkills = $skills | Select-Object -Property Category, Skill -Unique | Sort-Object -Property Category, Skill
$totalSkills = $uniqueSkills.Count
$totalOccurrences = $skills.Count

Write-Host "  Nombre total de compétences uniques : $totalSkills"
Write-Host "  Nombre total d'occurrences : $totalOccurrences"

$categories = $uniqueSkills | Group-Object -Property Category | Sort-Object -Property Name

Write-Host "`nRépartition par catégorie :"
foreach ($category in $categories) {
    Write-Host "  $($category.Name) : $($category.Count) compétences"
}

$skillOccurrences = $skills | Group-Object -Property Skill | Sort-Object -Property Count -Descending | Select-Object -First 5

Write-Host "`nTop 5 des compétences les plus demandées :"
foreach ($skillOccurrence in $skillOccurrences) {
    $percentage = [Math]::Round(($skillOccurrence.Count / $totalOccurrences) * 100, 1)
    Write-Host "  $($skillOccurrence.Name) : $($skillOccurrence.Count) occurrences ($percentage%)"
}
