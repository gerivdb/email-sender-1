<#
.SYNOPSIS
    Identifie les compÃ©tences requises pour chaque amÃ©lioration.

.DESCRIPTION
    Ce script identifie les compÃ©tences requises pour chaque amÃ©lioration en analysant
    le type d'amÃ©lioration, les technologies impliquÃ©es, la complexitÃ© technique et les risques.

.PARAMETER InputFile
    Chemin vers le fichier JSON contenant les amÃ©liorations Ã  analyser.

.PARAMETER TechnicalAnalysisFile
    Chemin vers le fichier d'analyse technique gÃ©nÃ©rÃ© prÃ©cÃ©demment.

.PARAMETER ComplexityScoresFile
    Chemin vers le fichier des scores de complexitÃ© technique gÃ©nÃ©rÃ© prÃ©cÃ©demment.

.PARAMETER OutputFile
    Chemin vers le fichier de sortie pour le rapport des compÃ©tences requises.

.PARAMETER Format
    Format du rapport de sortie. Les valeurs possibles sont : JSON, Markdown.
    Par dÃ©faut : Markdown

.EXAMPLE
    .\identify-required-skills.ps1 -InputFile "data\improvements.json" -TechnicalAnalysisFile "data\planning\technical-analysis.md" -ComplexityScoresFile "data\planning\complexity-scores.md" -OutputFile "data\planning\required-skills.md"
    GÃ©nÃ¨re un rapport des compÃ©tences requises au format Markdown.

.NOTES
    Auteur: Planning Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-09
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$InputFile,

    [Parameter(Mandatory = $true)]
    [string]$TechnicalAnalysisFile,

    [Parameter(Mandatory = $true)]
    [string]$ComplexityScoresFile,

    [Parameter(Mandatory = $true)]
    [string]$OutputFile,

    [Parameter(Mandatory = $false)]
    [ValidateSet("JSON", "Markdown")]
    [string]$Format = "Markdown"
)

# VÃ©rifier que les fichiers d'entrÃ©e existent
if (-not (Test-Path -Path $InputFile)) {
    Write-Error "Le fichier d'entrÃ©e n'existe pas : $InputFile"
    exit 1
}

if (-not (Test-Path -Path $TechnicalAnalysisFile)) {
    Write-Error "Le fichier d'analyse technique n'existe pas : $TechnicalAnalysisFile"
    exit 1
}

if (-not (Test-Path -Path $ComplexityScoresFile)) {
    Write-Error "Le fichier des scores de complexitÃ© technique n'existe pas : $ComplexityScoresFile"
    exit 1
}

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
$outputDir = Split-Path -Path $OutputFile -Parent
if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

# Charger les donnÃ©es des amÃ©liorations
try {
    $improvementsData = Get-Content -Path $InputFile -Raw | ConvertFrom-Json
} catch {
    Write-Error "Erreur lors du chargement du fichier d'entrÃ©e : $_"
    exit 1
}

# Fonction pour identifier les compÃ©tences techniques requises
function Identify-TechnicalSkills {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Improvement,
        
        [Parameter(Mandatory = $true)]
        [string]$ManagerName,
        
        [Parameter(Mandatory = $true)]
        [string]$ComplexityLevel
    )

    $skills = @()
    
    # CompÃ©tences de base requises pour tous les types d'amÃ©lioration
    $skills += [PSCustomObject]@{
        Category = "DÃ©veloppement"
        Skill = "PowerShell"
        Level = "IntermÃ©diaire"
        Justification = "Langage principal utilisÃ© dans le projet"
    }
    
    # CompÃ©tences spÃ©cifiques au type d'amÃ©lioration
    switch ($Improvement.Type) {
        "FonctionnalitÃ©" {
            $skills += [PSCustomObject]@{
                Category = "DÃ©veloppement"
                Skill = "Conception de fonctionnalitÃ©s"
                Level = "AvancÃ©"
                Justification = "NÃ©cessaire pour concevoir de nouvelles fonctionnalitÃ©s"
            }
            $skills += [PSCustomObject]@{
                Category = "DÃ©veloppement"
                Skill = "Tests unitaires"
                Level = "IntermÃ©diaire"
                Justification = "NÃ©cessaire pour tester les nouvelles fonctionnalitÃ©s"
            }
        }
        "AmÃ©lioration" {
            $skills += [PSCustomObject]@{
                Category = "DÃ©veloppement"
                Skill = "Refactoring"
                Level = "IntermÃ©diaire"
                Justification = "NÃ©cessaire pour amÃ©liorer le code existant"
            }
            $skills += [PSCustomObject]@{
                Category = "DÃ©veloppement"
                Skill = "Tests de rÃ©gression"
                Level = "IntermÃ©diaire"
                Justification = "NÃ©cessaire pour vÃ©rifier que les amÃ©liorations n'introduisent pas de rÃ©gressions"
            }
        }
        "Optimisation" {
            $skills += [PSCustomObject]@{
                Category = "DÃ©veloppement"
                Skill = "Optimisation de performances"
                Level = "AvancÃ©"
                Justification = "NÃ©cessaire pour optimiser les performances"
            }
            $skills += [PSCustomObject]@{
                Category = "DÃ©veloppement"
                Skill = "Profilage"
                Level = "AvancÃ©"
                Justification = "NÃ©cessaire pour identifier les goulots d'Ã©tranglement"
            }
            $skills += [PSCustomObject]@{
                Category = "DÃ©veloppement"
                Skill = "Tests de performance"
                Level = "AvancÃ©"
                Justification = "NÃ©cessaire pour mesurer les amÃ©liorations de performance"
            }
        }
        "IntÃ©gration" {
            $skills += [PSCustomObject]@{
                Category = "DÃ©veloppement"
                Skill = "IntÃ©gration de systÃ¨mes"
                Level = "AvancÃ©"
                Justification = "NÃ©cessaire pour intÃ©grer des systÃ¨mes externes"
            }
            $skills += [PSCustomObject]@{
                Category = "DÃ©veloppement"
                Skill = "API"
                Level = "AvancÃ©"
                Justification = "NÃ©cessaire pour interagir avec des API externes"
            }
            $skills += [PSCustomObject]@{
                Category = "DÃ©veloppement"
                Skill = "Tests d'intÃ©gration"
                Level = "AvancÃ©"
                Justification = "NÃ©cessaire pour tester les intÃ©grations"
            }
        }
        "SÃ©curitÃ©" {
            $skills += [PSCustomObject]@{
                Category = "SÃ©curitÃ©"
                Skill = "SÃ©curitÃ© des applications"
                Level = "Expert"
                Justification = "NÃ©cessaire pour implÃ©menter des mÃ©canismes de sÃ©curitÃ©"
            }
            $skills += [PSCustomObject]@{
                Category = "SÃ©curitÃ©"
                Skill = "Cryptographie"
                Level = "AvancÃ©"
                Justification = "NÃ©cessaire pour implÃ©menter des mÃ©canismes de chiffrement"
            }
            $skills += [PSCustomObject]@{
                Category = "SÃ©curitÃ©"
                Skill = "Tests de sÃ©curitÃ©"
                Level = "AvancÃ©"
                Justification = "NÃ©cessaire pour tester les mÃ©canismes de sÃ©curitÃ©"
            }
        }
    }
    
    # CompÃ©tences spÃ©cifiques au gestionnaire
    switch ($ManagerName) {
        "Process Manager" {
            $skills += [PSCustomObject]@{
                Category = "DÃ©veloppement"
                Skill = "Gestion de processus"
                Level = "AvancÃ©"
                Justification = "NÃ©cessaire pour travailler avec le gestionnaire de processus"
            }
            $skills += [PSCustomObject]@{
                Category = "DÃ©veloppement"
                Skill = "Programmation concurrente"
                Level = "AvancÃ©"
                Justification = "NÃ©cessaire pour gÃ©rer les processus concurrents"
            }
            $skills += [PSCustomObject]@{
                Category = "DÃ©veloppement"
                Skill = "Runspace Pools"
                Level = "AvancÃ©"
                Justification = "NÃ©cessaire pour utiliser les Runspace Pools de PowerShell"
            }
        }
        "Mode Manager" {
            $skills += [PSCustomObject]@{
                Category = "DÃ©veloppement"
                Skill = "Gestion d'Ã©tats"
                Level = "AvancÃ©"
                Justification = "NÃ©cessaire pour gÃ©rer les Ã©tats des modes"
            }
            $skills += [PSCustomObject]@{
                Category = "DÃ©veloppement"
                Skill = "Machines Ã  Ã©tats"
                Level = "IntermÃ©diaire"
                Justification = "NÃ©cessaire pour implÃ©menter les transitions entre modes"
            }
        }
        "Roadmap Manager" {
            $skills += [PSCustomObject]@{
                Category = "DÃ©veloppement"
                Skill = "Parsing de Markdown"
                Level = "AvancÃ©"
                Justification = "NÃ©cessaire pour parser les fichiers Markdown de roadmap"
            }
            $skills += [PSCustomObject]@{
                Category = "DÃ©veloppement"
                Skill = "Graphes"
                Level = "IntermÃ©diaire"
                Justification = "NÃ©cessaire pour gÃ©rer les dÃ©pendances entre tÃ¢ches"
            }
        }
        "Integrated Manager" {
            $skills += [PSCustomObject]@{
                Category = "DÃ©veloppement"
                Skill = "IntÃ©gration de systÃ¨mes"
                Level = "Expert"
                Justification = "NÃ©cessaire pour intÃ©grer diffÃ©rents systÃ¨mes"
            }
            $skills += [PSCustomObject]@{
                Category = "DÃ©veloppement"
                Skill = "API REST"
                Level = "AvancÃ©"
                Justification = "NÃ©cessaire pour interagir avec des API REST"
            }
            $skills += [PSCustomObject]@{
                Category = "DÃ©veloppement"
                Skill = "JSON"
                Level = "AvancÃ©"
                Justification = "NÃ©cessaire pour manipuler des donnÃ©es JSON"
            }
        }
        "Script Manager" {
            $skills += [PSCustomObject]@{
                Category = "DÃ©veloppement"
                Skill = "PowerShell"
                Level = "Expert"
                Justification = "NÃ©cessaire pour gÃ©rer des scripts PowerShell"
            }
            $skills += [PSCustomObject]@{
                Category = "DÃ©veloppement"
                Skill = "Modules PowerShell"
                Level = "AvancÃ©"
                Justification = "NÃ©cessaire pour crÃ©er et gÃ©rer des modules PowerShell"
            }
        }
        "Error Manager" {
            $skills += [PSCustomObject]@{
                Category = "DÃ©veloppement"
                Skill = "Gestion d'erreurs"
                Level = "Expert"
                Justification = "NÃ©cessaire pour implÃ©menter des mÃ©canismes de gestion d'erreurs"
            }
            $skills += [PSCustomObject]@{
                Category = "DÃ©veloppement"
                Skill = "Journalisation"
                Level = "AvancÃ©"
                Justification = "NÃ©cessaire pour journaliser les erreurs"
            }
            $skills += [PSCustomObject]@{
                Category = "DÃ©veloppement"
                Skill = "Diagnostic"
                Level = "AvancÃ©"
                Justification = "NÃ©cessaire pour diagnostiquer les erreurs"
            }
        }
        "Configuration Manager" {
            $skills += [PSCustomObject]@{
                Category = "DÃ©veloppement"
                Skill = "Gestion de configuration"
                Level = "AvancÃ©"
                Justification = "NÃ©cessaire pour gÃ©rer les configurations"
            }
            $skills += [PSCustomObject]@{
                Category = "DÃ©veloppement"
                Skill = "YAML"
                Level = "IntermÃ©diaire"
                Justification = "NÃ©cessaire pour manipuler des fichiers YAML"
            }
            $skills += [PSCustomObject]@{
                Category = "DÃ©veloppement"
                Skill = "JSON"
                Level = "AvancÃ©"
                Justification = "NÃ©cessaire pour manipuler des fichiers JSON"
            }
        }
        "Logging Manager" {
            $skills += [PSCustomObject]@{
                Category = "DÃ©veloppement"
                Skill = "Journalisation"
                Level = "Expert"
                Justification = "NÃ©cessaire pour implÃ©menter des mÃ©canismes de journalisation"
            }
            $skills += [PSCustomObject]@{
                Category = "DÃ©veloppement"
                Skill = "Rotation de logs"
                Level = "IntermÃ©diaire"
                Justification = "NÃ©cessaire pour gÃ©rer la rotation des logs"
            }
        }
    }
    
    # CompÃ©tences supplÃ©mentaires basÃ©es sur la complexitÃ©
    switch ($ComplexityLevel) {
        "TrÃ¨s Ã©levÃ©e" {
            $skills += [PSCustomObject]@{
                Category = "DÃ©veloppement"
                Skill = "Architecture logicielle"
                Level = "Expert"
                Justification = "NÃ©cessaire pour concevoir des solutions complexes"
            }
            $skills += [PSCustomObject]@{
                Category = "DÃ©veloppement"
                Skill = "Optimisation avancÃ©e"
                Level = "Expert"
                Justification = "NÃ©cessaire pour optimiser des solutions complexes"
            }
        }
        "Ã‰levÃ©e" {
            $skills += [PSCustomObject]@{
                Category = "DÃ©veloppement"
                Skill = "Architecture logicielle"
                Level = "AvancÃ©"
                Justification = "NÃ©cessaire pour concevoir des solutions de complexitÃ© Ã©levÃ©e"
            }
            $skills += [PSCustomObject]@{
                Category = "DÃ©veloppement"
                Skill = "Optimisation"
                Level = "AvancÃ©"
                Justification = "NÃ©cessaire pour optimiser des solutions de complexitÃ© Ã©levÃ©e"
            }
        }
    }
    
    # Supprimer les doublons (en conservant le niveau le plus Ã©levÃ©)
    $uniqueSkills = @{}
    foreach ($skill in $skills) {
        $key = "$($skill.Category):$($skill.Skill)"
        $levelValue = switch ($skill.Level) {
            "DÃ©butant" { 1 }
            "IntermÃ©diaire" { 2 }
            "AvancÃ©" { 3 }
            "Expert" { 4 }
            default { 0 }
        }
        
        if (-not $uniqueSkills.ContainsKey($key) -or $levelValue -gt $uniqueSkills[$key].LevelValue) {
            $uniqueSkills[$key] = @{
                Skill = $skill
                LevelValue = $levelValue
            }
        }
    }
    
    return $uniqueSkills.Values | ForEach-Object { $_.Skill } | Sort-Object -Property Category, Skill
}

# Fonction pour gÃ©nÃ©rer le rapport au format Markdown
function Generate-MarkdownReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$SkillsResults
    )

    $markdown = "# Identification des CompÃ©tences Requises pour les AmÃ©liorations`n`n"
    $markdown += "Ce document prÃ©sente l'identification des compÃ©tences requises pour les amÃ©liorations identifiÃ©es pour les diffÃ©rents gestionnaires.`n`n"
    
    $markdown += "## Table des MatiÃ¨res`n`n"
    
    foreach ($manager in $SkillsResults.Managers) {
        $markdown += "- [$($manager.Name)](#$($manager.Name.ToLower().Replace(' ', '-')))`n"
    }
    
    $markdown += "`n## MÃ©thodologie`n`n"
    $markdown += "L'identification des compÃ©tences requises a Ã©tÃ© rÃ©alisÃ©e en analysant :`n`n"
    $markdown += "1. **Type d'amÃ©lioration** : CompÃ©tences spÃ©cifiques au type d'amÃ©lioration (FonctionnalitÃ©, AmÃ©lioration, Optimisation, etc.)`n"
    $markdown += "2. **Gestionnaire concernÃ©** : CompÃ©tences spÃ©cifiques au gestionnaire (Process Manager, Mode Manager, etc.)`n"
    $markdown += "3. **ComplexitÃ© technique** : CompÃ©tences supplÃ©mentaires basÃ©es sur la complexitÃ© technique`n`n"
    
    $markdown += "### Niveaux de CompÃ©tence`n`n"
    $markdown += "Les compÃ©tences sont Ã©valuÃ©es selon quatre niveaux :`n`n"
    $markdown += "| Niveau | Description |`n"
    $markdown += "|--------|-------------|`n"
    $markdown += "| DÃ©butant | Connaissances de base, supervision nÃ©cessaire |`n"
    $markdown += "| IntermÃ©diaire | Bonnes connaissances, autonomie sur des tÃ¢ches standard |`n"
    $markdown += "| AvancÃ© | Expertise solide, autonomie sur des tÃ¢ches complexes |`n"
    $markdown += "| Expert | MaÃ®trise approfondie, rÃ©fÃ©rent technique |`n`n"
    
    foreach ($manager in $SkillsResults.Managers) {
        $markdown += "## <a name='$($manager.Name.ToLower().Replace(' ', '-'))'></a>$($manager.Name)`n`n"
        
        foreach ($improvement in $manager.Improvements) {
            $markdown += "### $($improvement.Name)`n`n"
            $markdown += "**Description :** $($improvement.Description)`n`n"
            $markdown += "**Type :** $($improvement.Type)`n`n"
            $markdown += "**ComplexitÃ© technique :** $($improvement.ComplexityLevel)`n`n"
            
            if ($improvement.Skills.Count -gt 0) {
                $markdown += "#### CompÃ©tences Requises`n`n"
                $markdown += "| CatÃ©gorie | CompÃ©tence | Niveau | Justification |`n"
                $markdown += "|-----------|------------|--------|---------------|`n"
                
                foreach ($skill in $improvement.Skills) {
                    $markdown += "| $($skill.Category) | $($skill.Skill) | $($skill.Level) | $($skill.Justification) |`n"
                }
            } else {
                $markdown += "#### CompÃ©tences Requises`n`n"
                $markdown += "Aucune compÃ©tence spÃ©cifique identifiÃ©e pour cette amÃ©lioration.`n"
            }
            
            $markdown += "`n"
        }
    }
    
    $markdown += "## RÃ©sumÃ©`n`n"
    
    $totalImprovements = 0
    $totalSkills = 0
    $skillsByCategory = @{}
    $skillsByLevel = @{
        "DÃ©butant" = 0
        "IntermÃ©diaire" = 0
        "AvancÃ©" = 0
        "Expert" = 0
    }
    
    foreach ($manager in $SkillsResults.Managers) {
        $totalImprovements += $manager.Improvements.Count
        
        foreach ($improvement in $manager.Improvements) {
            $totalSkills += $improvement.Skills.Count
            
            foreach ($skill in $improvement.Skills) {
                if (-not $skillsByCategory.ContainsKey($skill.Category)) {
                    $skillsByCategory[$skill.Category] = @{}
                }
                
                if (-not $skillsByCategory[$skill.Category].ContainsKey($skill.Skill)) {
                    $skillsByCategory[$skill.Category][$skill.Skill] = 0
                }
                
                $skillsByCategory[$skill.Category][$skill.Skill]++
                $skillsByLevel[$skill.Level]++
            }
        }
    }
    
    $markdown += "Cette analyse a identifiÃ© $totalSkills compÃ©tences requises pour $totalImprovements amÃ©liorations rÃ©parties sur $($SkillsResults.Managers.Count) gestionnaires.`n`n"
    
    $markdown += "### RÃ©partition par CatÃ©gorie`n`n"
    $markdown += "| CatÃ©gorie | Nombre de CompÃ©tences |`n"
    $markdown += "|-----------|------------------------|`n"
    
    foreach ($category in $skillsByCategory.Keys | Sort-Object) {
        $categorySkillsCount = ($skillsByCategory[$category].Values | Measure-Object -Sum).Sum
        $markdown += "| $category | $categorySkillsCount |`n"
    }
    
    $markdown += "`n### RÃ©partition par Niveau`n`n"
    $markdown += "| Niveau | Nombre | Pourcentage |`n"
    $markdown += "|--------|--------|------------|`n"
    
    foreach ($level in @("DÃ©butant", "IntermÃ©diaire", "AvancÃ©", "Expert")) {
        $percentage = if ($totalSkills -gt 0) { [Math]::Round(($skillsByLevel[$level] / $totalSkills) * 100, 1) } else { 0 }
        $markdown += "| $level | $($skillsByLevel[$level]) | $percentage% |`n"
    }
    
    $markdown += "`n### CompÃ©tences les Plus DemandÃ©es`n`n"
    $markdown += "| CatÃ©gorie | CompÃ©tence | Nombre d'AmÃ©liorations |`n"
    $markdown += "|-----------|------------|------------------------|`n"
    
    $topSkills = @()
    foreach ($category in $skillsByCategory.Keys) {
        foreach ($skill in $skillsByCategory[$category].Keys) {
            $topSkills += [PSCustomObject]@{
                Category = $category
                Skill = $skill
                Count = $skillsByCategory[$category][$skill]
            }
        }
    }
    
    $topSkills = $topSkills | Sort-Object -Property Count -Descending | Select-Object -First 10
    
    foreach ($skill in $topSkills) {
        $markdown += "| $($skill.Category) | $($skill.Skill) | $($skill.Count) |`n"
    }
    
    $markdown += "`n### Recommandations`n`n"
    $markdown += "1. **Formation** : Organiser des formations pour les compÃ©tences les plus demandÃ©es, en particulier celles de niveau AvancÃ© et Expert.`n"
    $markdown += "2. **Recrutement** : Recruter des profils possÃ©dant les compÃ©tences les plus demandÃ©es, en particulier celles de niveau Expert.`n"
    $markdown += "3. **Partenariats** : Ã‰tablir des partenariats avec des experts externes pour les compÃ©tences rares ou trÃ¨s spÃ©cialisÃ©es.`n"
    $markdown += "4. **Documentation** : AmÃ©liorer la documentation pour faciliter la montÃ©e en compÃ©tence des Ã©quipes.`n"
    $markdown += "5. **Mentorat** : Mettre en place un systÃ¨me de mentorat pour partager les connaissances au sein de l'Ã©quipe.`n"
    
    return $markdown
}

# Fonction pour gÃ©nÃ©rer le rapport au format JSON
function Generate-JsonReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$SkillsResults
    )

    return $SkillsResults | ConvertTo-Json -Depth 10
}

# Identifier les compÃ©tences requises pour chaque amÃ©lioration
$skillsResults = [PSCustomObject]@{
    GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Managers = @()
}

foreach ($manager in $improvementsData.Managers) {
    $managerSkills = [PSCustomObject]@{
        Name = $manager.Name
        Category = $manager.Category
        Improvements = @()
    }
    
    foreach ($improvement in $manager.Improvements) {
        # DÃ©terminer le niveau de complexitÃ© (Ã  partir de l'Ã©valuation prÃ©cÃ©dente)
        $complexityLevel = "Moyenne" # Valeur par dÃ©faut
        
        # Dans un cas rÃ©el, on rÃ©cupÃ©rerait cette information du fichier des scores de complexitÃ©
        # Pour simplifier, on utilise une logique basÃ©e sur l'effort et le type
        if ($improvement.Effort -eq "Ã‰levÃ©") {
            if ($improvement.Type -eq "Optimisation" -or $improvement.Type -eq "IntÃ©gration" -or $improvement.Type -eq "SÃ©curitÃ©") {
                $complexityLevel = "Ã‰levÃ©e"
            }
        } elseif ($improvement.Effort -eq "Faible") {
            $complexityLevel = "Faible"
        }
        
        # Identifier les compÃ©tences requises
        $skills = Identify-TechnicalSkills -Improvement $improvement -ManagerName $manager.Name -ComplexityLevel $complexityLevel
        
        $improvementSkills = [PSCustomObject]@{
            Name = $improvement.Name
            Description = $improvement.Description
            Type = $improvement.Type
            Effort = $improvement.Effort
            ComplexityLevel = $complexityLevel
            Skills = $skills
        }
        
        $managerSkills.Improvements += $improvementSkills
    }
    
    $skillsResults.Managers += $managerSkills
}

# GÃ©nÃ©rer le rapport dans le format spÃ©cifiÃ©
switch ($Format) {
    "Markdown" {
        $reportContent = Generate-MarkdownReport -SkillsResults $skillsResults
    }
    "JSON" {
        $reportContent = Generate-JsonReport -SkillsResults $skillsResults
    }
}

# Enregistrer le rapport
try {
    $reportContent | Out-File -FilePath $OutputFile -Encoding UTF8
    Write-Host "Rapport des compÃ©tences requises gÃ©nÃ©rÃ© avec succÃ¨s : $OutputFile"
} catch {
    Write-Error "Erreur lors de l'enregistrement du rapport : $_"
    exit 1
}

# Afficher un rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ© de l'identification des compÃ©tences requises :"
Write-Host "---------------------------------------------------"

$totalImprovements = 0
$totalSkills = 0
$skillsByCategory = @{}
$skillsByLevel = @{
    "DÃ©butant" = 0
    "IntermÃ©diaire" = 0
    "AvancÃ©" = 0
    "Expert" = 0
}

foreach ($manager in $skillsResults.Managers) {
    $managerImprovements = $manager.Improvements.Count
    $managerSkills = 0
    
    foreach ($improvement in $manager.Improvements) {
        $managerSkills += $improvement.Skills.Count
        
        foreach ($skill in $improvement.Skills) {
            if (-not $skillsByCategory.ContainsKey($skill.Category)) {
                $skillsByCategory[$skill.Category] = 0
            }
            
            $skillsByCategory[$skill.Category]++
            $skillsByLevel[$skill.Level]++
        }
    }
    
    $totalImprovements += $managerImprovements
    $totalSkills += $managerSkills
    
    Write-Host "  $($manager.Name) : $managerSkills compÃ©tences pour $managerImprovements amÃ©liorations"
}

Write-Host "  Total : $totalSkills compÃ©tences pour $totalImprovements amÃ©liorations"
Write-Host "`nRÃ©partition par catÃ©gorie :"
foreach ($category in $skillsByCategory.Keys | Sort-Object) {
    Write-Host "  $category : $($skillsByCategory[$category])"
}

Write-Host "`nRÃ©partition par niveau :"
foreach ($level in @("DÃ©butant", "IntermÃ©diaire", "AvancÃ©", "Expert")) {
    $percentage = if ($totalSkills -gt 0) { [Math]::Round(($skillsByLevel[$level] / $totalSkills) * 100, 1) } else { 0 }
    Write-Host "  $level : $($skillsByLevel[$level]) ($percentage%)"
}
