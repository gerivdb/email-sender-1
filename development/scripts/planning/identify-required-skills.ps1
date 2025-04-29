<#
.SYNOPSIS
    Identifie les compétences requises pour chaque amélioration.

.DESCRIPTION
    Ce script identifie les compétences requises pour chaque amélioration en analysant
    le type d'amélioration, les technologies impliquées, la complexité technique et les risques.

.PARAMETER InputFile
    Chemin vers le fichier JSON contenant les améliorations à analyser.

.PARAMETER TechnicalAnalysisFile
    Chemin vers le fichier d'analyse technique généré précédemment.

.PARAMETER ComplexityScoresFile
    Chemin vers le fichier des scores de complexité technique généré précédemment.

.PARAMETER OutputFile
    Chemin vers le fichier de sortie pour le rapport des compétences requises.

.PARAMETER Format
    Format du rapport de sortie. Les valeurs possibles sont : JSON, Markdown.
    Par défaut : Markdown

.EXAMPLE
    .\identify-required-skills.ps1 -InputFile "data\improvements.json" -TechnicalAnalysisFile "data\planning\technical-analysis.md" -ComplexityScoresFile "data\planning\complexity-scores.md" -OutputFile "data\planning\required-skills.md"
    Génère un rapport des compétences requises au format Markdown.

.NOTES
    Auteur: Planning Team
    Version: 1.0
    Date de création: 2025-05-09
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

# Vérifier que les fichiers d'entrée existent
if (-not (Test-Path -Path $InputFile)) {
    Write-Error "Le fichier d'entrée n'existe pas : $InputFile"
    exit 1
}

if (-not (Test-Path -Path $TechnicalAnalysisFile)) {
    Write-Error "Le fichier d'analyse technique n'existe pas : $TechnicalAnalysisFile"
    exit 1
}

if (-not (Test-Path -Path $ComplexityScoresFile)) {
    Write-Error "Le fichier des scores de complexité technique n'existe pas : $ComplexityScoresFile"
    exit 1
}

# Créer le répertoire de sortie s'il n'existe pas
$outputDir = Split-Path -Path $OutputFile -Parent
if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

# Charger les données des améliorations
try {
    $improvementsData = Get-Content -Path $InputFile -Raw | ConvertFrom-Json
} catch {
    Write-Error "Erreur lors du chargement du fichier d'entrée : $_"
    exit 1
}

# Fonction pour identifier les compétences techniques requises
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
    
    # Compétences de base requises pour tous les types d'amélioration
    $skills += [PSCustomObject]@{
        Category = "Développement"
        Skill = "PowerShell"
        Level = "Intermédiaire"
        Justification = "Langage principal utilisé dans le projet"
    }
    
    # Compétences spécifiques au type d'amélioration
    switch ($Improvement.Type) {
        "Fonctionnalité" {
            $skills += [PSCustomObject]@{
                Category = "Développement"
                Skill = "Conception de fonctionnalités"
                Level = "Avancé"
                Justification = "Nécessaire pour concevoir de nouvelles fonctionnalités"
            }
            $skills += [PSCustomObject]@{
                Category = "Développement"
                Skill = "Tests unitaires"
                Level = "Intermédiaire"
                Justification = "Nécessaire pour tester les nouvelles fonctionnalités"
            }
        }
        "Amélioration" {
            $skills += [PSCustomObject]@{
                Category = "Développement"
                Skill = "Refactoring"
                Level = "Intermédiaire"
                Justification = "Nécessaire pour améliorer le code existant"
            }
            $skills += [PSCustomObject]@{
                Category = "Développement"
                Skill = "Tests de régression"
                Level = "Intermédiaire"
                Justification = "Nécessaire pour vérifier que les améliorations n'introduisent pas de régressions"
            }
        }
        "Optimisation" {
            $skills += [PSCustomObject]@{
                Category = "Développement"
                Skill = "Optimisation de performances"
                Level = "Avancé"
                Justification = "Nécessaire pour optimiser les performances"
            }
            $skills += [PSCustomObject]@{
                Category = "Développement"
                Skill = "Profilage"
                Level = "Avancé"
                Justification = "Nécessaire pour identifier les goulots d'étranglement"
            }
            $skills += [PSCustomObject]@{
                Category = "Développement"
                Skill = "Tests de performance"
                Level = "Avancé"
                Justification = "Nécessaire pour mesurer les améliorations de performance"
            }
        }
        "Intégration" {
            $skills += [PSCustomObject]@{
                Category = "Développement"
                Skill = "Intégration de systèmes"
                Level = "Avancé"
                Justification = "Nécessaire pour intégrer des systèmes externes"
            }
            $skills += [PSCustomObject]@{
                Category = "Développement"
                Skill = "API"
                Level = "Avancé"
                Justification = "Nécessaire pour interagir avec des API externes"
            }
            $skills += [PSCustomObject]@{
                Category = "Développement"
                Skill = "Tests d'intégration"
                Level = "Avancé"
                Justification = "Nécessaire pour tester les intégrations"
            }
        }
        "Sécurité" {
            $skills += [PSCustomObject]@{
                Category = "Sécurité"
                Skill = "Sécurité des applications"
                Level = "Expert"
                Justification = "Nécessaire pour implémenter des mécanismes de sécurité"
            }
            $skills += [PSCustomObject]@{
                Category = "Sécurité"
                Skill = "Cryptographie"
                Level = "Avancé"
                Justification = "Nécessaire pour implémenter des mécanismes de chiffrement"
            }
            $skills += [PSCustomObject]@{
                Category = "Sécurité"
                Skill = "Tests de sécurité"
                Level = "Avancé"
                Justification = "Nécessaire pour tester les mécanismes de sécurité"
            }
        }
    }
    
    # Compétences spécifiques au gestionnaire
    switch ($ManagerName) {
        "Process Manager" {
            $skills += [PSCustomObject]@{
                Category = "Développement"
                Skill = "Gestion de processus"
                Level = "Avancé"
                Justification = "Nécessaire pour travailler avec le gestionnaire de processus"
            }
            $skills += [PSCustomObject]@{
                Category = "Développement"
                Skill = "Programmation concurrente"
                Level = "Avancé"
                Justification = "Nécessaire pour gérer les processus concurrents"
            }
            $skills += [PSCustomObject]@{
                Category = "Développement"
                Skill = "Runspace Pools"
                Level = "Avancé"
                Justification = "Nécessaire pour utiliser les Runspace Pools de PowerShell"
            }
        }
        "Mode Manager" {
            $skills += [PSCustomObject]@{
                Category = "Développement"
                Skill = "Gestion d'états"
                Level = "Avancé"
                Justification = "Nécessaire pour gérer les états des modes"
            }
            $skills += [PSCustomObject]@{
                Category = "Développement"
                Skill = "Machines à états"
                Level = "Intermédiaire"
                Justification = "Nécessaire pour implémenter les transitions entre modes"
            }
        }
        "Roadmap Manager" {
            $skills += [PSCustomObject]@{
                Category = "Développement"
                Skill = "Parsing de Markdown"
                Level = "Avancé"
                Justification = "Nécessaire pour parser les fichiers Markdown de roadmap"
            }
            $skills += [PSCustomObject]@{
                Category = "Développement"
                Skill = "Graphes"
                Level = "Intermédiaire"
                Justification = "Nécessaire pour gérer les dépendances entre tâches"
            }
        }
        "Integrated Manager" {
            $skills += [PSCustomObject]@{
                Category = "Développement"
                Skill = "Intégration de systèmes"
                Level = "Expert"
                Justification = "Nécessaire pour intégrer différents systèmes"
            }
            $skills += [PSCustomObject]@{
                Category = "Développement"
                Skill = "API REST"
                Level = "Avancé"
                Justification = "Nécessaire pour interagir avec des API REST"
            }
            $skills += [PSCustomObject]@{
                Category = "Développement"
                Skill = "JSON"
                Level = "Avancé"
                Justification = "Nécessaire pour manipuler des données JSON"
            }
        }
        "Script Manager" {
            $skills += [PSCustomObject]@{
                Category = "Développement"
                Skill = "PowerShell"
                Level = "Expert"
                Justification = "Nécessaire pour gérer des scripts PowerShell"
            }
            $skills += [PSCustomObject]@{
                Category = "Développement"
                Skill = "Modules PowerShell"
                Level = "Avancé"
                Justification = "Nécessaire pour créer et gérer des modules PowerShell"
            }
        }
        "Error Manager" {
            $skills += [PSCustomObject]@{
                Category = "Développement"
                Skill = "Gestion d'erreurs"
                Level = "Expert"
                Justification = "Nécessaire pour implémenter des mécanismes de gestion d'erreurs"
            }
            $skills += [PSCustomObject]@{
                Category = "Développement"
                Skill = "Journalisation"
                Level = "Avancé"
                Justification = "Nécessaire pour journaliser les erreurs"
            }
            $skills += [PSCustomObject]@{
                Category = "Développement"
                Skill = "Diagnostic"
                Level = "Avancé"
                Justification = "Nécessaire pour diagnostiquer les erreurs"
            }
        }
        "Configuration Manager" {
            $skills += [PSCustomObject]@{
                Category = "Développement"
                Skill = "Gestion de configuration"
                Level = "Avancé"
                Justification = "Nécessaire pour gérer les configurations"
            }
            $skills += [PSCustomObject]@{
                Category = "Développement"
                Skill = "YAML"
                Level = "Intermédiaire"
                Justification = "Nécessaire pour manipuler des fichiers YAML"
            }
            $skills += [PSCustomObject]@{
                Category = "Développement"
                Skill = "JSON"
                Level = "Avancé"
                Justification = "Nécessaire pour manipuler des fichiers JSON"
            }
        }
        "Logging Manager" {
            $skills += [PSCustomObject]@{
                Category = "Développement"
                Skill = "Journalisation"
                Level = "Expert"
                Justification = "Nécessaire pour implémenter des mécanismes de journalisation"
            }
            $skills += [PSCustomObject]@{
                Category = "Développement"
                Skill = "Rotation de logs"
                Level = "Intermédiaire"
                Justification = "Nécessaire pour gérer la rotation des logs"
            }
        }
    }
    
    # Compétences supplémentaires basées sur la complexité
    switch ($ComplexityLevel) {
        "Très élevée" {
            $skills += [PSCustomObject]@{
                Category = "Développement"
                Skill = "Architecture logicielle"
                Level = "Expert"
                Justification = "Nécessaire pour concevoir des solutions complexes"
            }
            $skills += [PSCustomObject]@{
                Category = "Développement"
                Skill = "Optimisation avancée"
                Level = "Expert"
                Justification = "Nécessaire pour optimiser des solutions complexes"
            }
        }
        "Élevée" {
            $skills += [PSCustomObject]@{
                Category = "Développement"
                Skill = "Architecture logicielle"
                Level = "Avancé"
                Justification = "Nécessaire pour concevoir des solutions de complexité élevée"
            }
            $skills += [PSCustomObject]@{
                Category = "Développement"
                Skill = "Optimisation"
                Level = "Avancé"
                Justification = "Nécessaire pour optimiser des solutions de complexité élevée"
            }
        }
    }
    
    # Supprimer les doublons (en conservant le niveau le plus élevé)
    $uniqueSkills = @{}
    foreach ($skill in $skills) {
        $key = "$($skill.Category):$($skill.Skill)"
        $levelValue = switch ($skill.Level) {
            "Débutant" { 1 }
            "Intermédiaire" { 2 }
            "Avancé" { 3 }
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

# Fonction pour générer le rapport au format Markdown
function Generate-MarkdownReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$SkillsResults
    )

    $markdown = "# Identification des Compétences Requises pour les Améliorations`n`n"
    $markdown += "Ce document présente l'identification des compétences requises pour les améliorations identifiées pour les différents gestionnaires.`n`n"
    
    $markdown += "## Table des Matières`n`n"
    
    foreach ($manager in $SkillsResults.Managers) {
        $markdown += "- [$($manager.Name)](#$($manager.Name.ToLower().Replace(' ', '-')))`n"
    }
    
    $markdown += "`n## Méthodologie`n`n"
    $markdown += "L'identification des compétences requises a été réalisée en analysant :`n`n"
    $markdown += "1. **Type d'amélioration** : Compétences spécifiques au type d'amélioration (Fonctionnalité, Amélioration, Optimisation, etc.)`n"
    $markdown += "2. **Gestionnaire concerné** : Compétences spécifiques au gestionnaire (Process Manager, Mode Manager, etc.)`n"
    $markdown += "3. **Complexité technique** : Compétences supplémentaires basées sur la complexité technique`n`n"
    
    $markdown += "### Niveaux de Compétence`n`n"
    $markdown += "Les compétences sont évaluées selon quatre niveaux :`n`n"
    $markdown += "| Niveau | Description |`n"
    $markdown += "|--------|-------------|`n"
    $markdown += "| Débutant | Connaissances de base, supervision nécessaire |`n"
    $markdown += "| Intermédiaire | Bonnes connaissances, autonomie sur des tâches standard |`n"
    $markdown += "| Avancé | Expertise solide, autonomie sur des tâches complexes |`n"
    $markdown += "| Expert | Maîtrise approfondie, référent technique |`n`n"
    
    foreach ($manager in $SkillsResults.Managers) {
        $markdown += "## <a name='$($manager.Name.ToLower().Replace(' ', '-'))'></a>$($manager.Name)`n`n"
        
        foreach ($improvement in $manager.Improvements) {
            $markdown += "### $($improvement.Name)`n`n"
            $markdown += "**Description :** $($improvement.Description)`n`n"
            $markdown += "**Type :** $($improvement.Type)`n`n"
            $markdown += "**Complexité technique :** $($improvement.ComplexityLevel)`n`n"
            
            if ($improvement.Skills.Count -gt 0) {
                $markdown += "#### Compétences Requises`n`n"
                $markdown += "| Catégorie | Compétence | Niveau | Justification |`n"
                $markdown += "|-----------|------------|--------|---------------|`n"
                
                foreach ($skill in $improvement.Skills) {
                    $markdown += "| $($skill.Category) | $($skill.Skill) | $($skill.Level) | $($skill.Justification) |`n"
                }
            } else {
                $markdown += "#### Compétences Requises`n`n"
                $markdown += "Aucune compétence spécifique identifiée pour cette amélioration.`n"
            }
            
            $markdown += "`n"
        }
    }
    
    $markdown += "## Résumé`n`n"
    
    $totalImprovements = 0
    $totalSkills = 0
    $skillsByCategory = @{}
    $skillsByLevel = @{
        "Débutant" = 0
        "Intermédiaire" = 0
        "Avancé" = 0
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
    
    $markdown += "Cette analyse a identifié $totalSkills compétences requises pour $totalImprovements améliorations réparties sur $($SkillsResults.Managers.Count) gestionnaires.`n`n"
    
    $markdown += "### Répartition par Catégorie`n`n"
    $markdown += "| Catégorie | Nombre de Compétences |`n"
    $markdown += "|-----------|------------------------|`n"
    
    foreach ($category in $skillsByCategory.Keys | Sort-Object) {
        $categorySkillsCount = ($skillsByCategory[$category].Values | Measure-Object -Sum).Sum
        $markdown += "| $category | $categorySkillsCount |`n"
    }
    
    $markdown += "`n### Répartition par Niveau`n`n"
    $markdown += "| Niveau | Nombre | Pourcentage |`n"
    $markdown += "|--------|--------|------------|`n"
    
    foreach ($level in @("Débutant", "Intermédiaire", "Avancé", "Expert")) {
        $percentage = if ($totalSkills -gt 0) { [Math]::Round(($skillsByLevel[$level] / $totalSkills) * 100, 1) } else { 0 }
        $markdown += "| $level | $($skillsByLevel[$level]) | $percentage% |`n"
    }
    
    $markdown += "`n### Compétences les Plus Demandées`n`n"
    $markdown += "| Catégorie | Compétence | Nombre d'Améliorations |`n"
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
    $markdown += "1. **Formation** : Organiser des formations pour les compétences les plus demandées, en particulier celles de niveau Avancé et Expert.`n"
    $markdown += "2. **Recrutement** : Recruter des profils possédant les compétences les plus demandées, en particulier celles de niveau Expert.`n"
    $markdown += "3. **Partenariats** : Établir des partenariats avec des experts externes pour les compétences rares ou très spécialisées.`n"
    $markdown += "4. **Documentation** : Améliorer la documentation pour faciliter la montée en compétence des équipes.`n"
    $markdown += "5. **Mentorat** : Mettre en place un système de mentorat pour partager les connaissances au sein de l'équipe.`n"
    
    return $markdown
}

# Fonction pour générer le rapport au format JSON
function Generate-JsonReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$SkillsResults
    )

    return $SkillsResults | ConvertTo-Json -Depth 10
}

# Identifier les compétences requises pour chaque amélioration
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
        # Déterminer le niveau de complexité (à partir de l'évaluation précédente)
        $complexityLevel = "Moyenne" # Valeur par défaut
        
        # Dans un cas réel, on récupérerait cette information du fichier des scores de complexité
        # Pour simplifier, on utilise une logique basée sur l'effort et le type
        if ($improvement.Effort -eq "Élevé") {
            if ($improvement.Type -eq "Optimisation" -or $improvement.Type -eq "Intégration" -or $improvement.Type -eq "Sécurité") {
                $complexityLevel = "Élevée"
            }
        } elseif ($improvement.Effort -eq "Faible") {
            $complexityLevel = "Faible"
        }
        
        # Identifier les compétences requises
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

# Générer le rapport dans le format spécifié
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
    Write-Host "Rapport des compétences requises généré avec succès : $OutputFile"
} catch {
    Write-Error "Erreur lors de l'enregistrement du rapport : $_"
    exit 1
}

# Afficher un résumé
Write-Host "`nRésumé de l'identification des compétences requises :"
Write-Host "---------------------------------------------------"

$totalImprovements = 0
$totalSkills = 0
$skillsByCategory = @{}
$skillsByLevel = @{
    "Débutant" = 0
    "Intermédiaire" = 0
    "Avancé" = 0
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
    
    Write-Host "  $($manager.Name) : $managerSkills compétences pour $managerImprovements améliorations"
}

Write-Host "  Total : $totalSkills compétences pour $totalImprovements améliorations"
Write-Host "`nRépartition par catégorie :"
foreach ($category in $skillsByCategory.Keys | Sort-Object) {
    Write-Host "  $category : $($skillsByCategory[$category])"
}

Write-Host "`nRépartition par niveau :"
foreach ($level in @("Débutant", "Intermédiaire", "Avancé", "Expert")) {
    $percentage = if ($totalSkills -gt 0) { [Math]::Round(($skillsByLevel[$level] / $totalSkills) * 100, 1) } else { 0 }
    Write-Host "  $level : $($skillsByLevel[$level]) ($percentage%)"
}
