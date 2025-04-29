<#
.SYNOPSIS
    Détermine le nombre de personnes nécessaires pour chaque amélioration.

.DESCRIPTION
    Ce script détermine le nombre de personnes nécessaires pour chaque amélioration en analysant
    la complexité technique, les compétences requises, l'effort estimé et les contraintes de temps.

.PARAMETER InputFile
    Chemin vers le fichier JSON contenant les améliorations à analyser.

.PARAMETER SkillsFile
    Chemin vers le fichier des compétences requises généré précédemment.

.PARAMETER ComplexityScoresFile
    Chemin vers le fichier des scores de complexité technique généré précédemment.

.PARAMETER OutputFile
    Chemin vers le fichier de sortie pour le rapport du personnel requis.

.PARAMETER Format
    Format du rapport de sortie. Les valeurs possibles sont : JSON, Markdown.
    Par défaut : Markdown

.EXAMPLE
    .\determine-required-personnel-fixed.ps1 -InputFile "data\improvements.json" -SkillsFile "data\planning\required-skills.md" -ComplexityScoresFile "data\planning\complexity-scores.md" -OutputFile "data\planning\required-personnel.md"
    Génère un rapport du personnel requis au format Markdown.

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
    [string]$SkillsFile,

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

if (-not (Test-Path -Path $SkillsFile)) {
    Write-Error "Le fichier des compétences requises n'existe pas : $SkillsFile"
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

# Fonction pour déterminer le nombre de personnes nécessaires
function Determine-RequiredPersonnel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Improvement,
        
        [Parameter(Mandatory = $true)]
        [string]$ManagerName,
        
        [Parameter(Mandatory = $true)]
        [string]$ComplexityLevel,
        
        [Parameter(Mandatory = $true)]
        [int]$SkillsCount
    )

    # Facteurs influençant le nombre de personnes nécessaires
    $personnelFactors = @{
        # Complexité technique
        Complexity = @{
            Weight = 0.35
            Score = 0
        }
        
        # Nombre de compétences requises
        Skills = @{
            Weight = 0.25
            Score = 0
        }
        
        # Effort requis
        Effort = @{
            Weight = 0.20
            Score = 0
        }
        
        # Type d'amélioration
        Type = @{
            Weight = 0.20
            Score = 0
        }
    }
    
    # Évaluer la complexité technique
    $complexityScore = switch ($ComplexityLevel) {
        "Très élevée" { 10 }
        "Élevée" { 8 }
        "Moyenne" { 5 }
        "Faible" { 3 }
        "Très faible" { 1 }
        default { 5 }
    }
    
    $personnelFactors.Complexity.Score = $complexityScore
    
    # Évaluer le nombre de compétences requises
    $skillsScore = [Math]::Min(10, $SkillsCount / 2 + 2)
    
    $personnelFactors.Skills.Score = $skillsScore
    
    # Évaluer l'effort requis
    $effortScore = switch ($Improvement.Effort) {
        "Élevé" { 8 }
        "Moyen" { 5 }
        "Faible" { 3 }
        default { 5 }
    }
    
    $personnelFactors.Effort.Score = $effortScore
    
    # Évaluer le type d'amélioration
    $typeScore = switch ($Improvement.Type) {
        "Fonctionnalite" { 7 }
        "Amelioration" { 5 }
        "Optimisation" { 8 }
        "Integration" { 8 }
        "Securite" { 9 }
        default { 6 }
    }
    
    $personnelFactors.Type.Score = $typeScore
    
    # Calculer le score global
    $globalScore = 0
    foreach ($factor in $personnelFactors.Keys) {
        $globalScore += $personnelFactors[$factor].Score * $personnelFactors[$factor].Weight
    }
    
    # Arrondir à deux décimales
    $globalScore = [Math]::Round($globalScore, 2)
    
    # Déterminer le nombre de personnes nécessaires
    $basePersonnel = switch ($globalScore) {
        {$_ -lt 3} { 1 }
        {$_ -ge 3 -and $_ -lt 5} { 2 }
        {$_ -ge 5 -and $_ -lt 7} { 3 }
        {$_ -ge 7 -and $_ -lt 8.5} { 4 }
        {$_ -ge 8.5} { 5 }
    }
    
    # Ajuster en fonction du gestionnaire
    $adjustedPersonnel = $basePersonnel
    switch ($ManagerName) {
        "Process Manager" {
            if ($Improvement.Type -eq "Optimisation") {
                $adjustedPersonnel += 1
            }
        }
        "Integrated Manager" {
            if ($Improvement.Type -eq "Integration") {
                $adjustedPersonnel += 1
            }
        }
        "Error Manager" {
            if ($Improvement.Type -eq "Securite") {
                $adjustedPersonnel += 1
            }
        }
    }
    
    # Déterminer les rôles nécessaires
    $roles = @()
    
    # Rôles de base pour tous les types d'amélioration
    $roles += [PSCustomObject]@{
        Role = "Développeur"
        Count = [Math]::Max(1, [Math]::Floor($adjustedPersonnel * 0.5))
        Justification = "Nécessaire pour l'implémentation"
    }
    
    # Rôles spécifiques au type d'amélioration
    switch ($Improvement.Type) {
        "Fonctionnalite" {
            $roles += [PSCustomObject]@{
                Role = "Analyste"
                Count = 1
                Justification = "Nécessaire pour l'analyse des besoins"
            }
            if ($adjustedPersonnel -ge 3) {
                $roles += [PSCustomObject]@{
                    Role = "Testeur"
                    Count = 1
                    Justification = "Nécessaire pour les tests"
                }
            }
        }
        "Amelioration" {
            if ($adjustedPersonnel -ge 3) {
                $roles += [PSCustomObject]@{
                    Role = "Testeur"
                    Count = 1
                    Justification = "Nécessaire pour les tests de régression"
                }
            }
        }
        "Optimisation" {
            $roles += [PSCustomObject]@{
                Role = "Spécialiste en performance"
                Count = 1
                Justification = "Nécessaire pour l'optimisation des performances"
            }
            if ($adjustedPersonnel -ge 4) {
                $roles += [PSCustomObject]@{
                    Role = "Testeur"
                    Count = 1
                    Justification = "Nécessaire pour les tests de performance"
                }
            }
        }
        "Integration" {
            $roles += [PSCustomObject]@{
                Role = "Spécialiste en intégration"
                Count = 1
                Justification = "Nécessaire pour l'intégration avec des systèmes externes"
            }
            if ($adjustedPersonnel -ge 4) {
                $roles += [PSCustomObject]@{
                    Role = "Testeur"
                    Count = 1
                    Justification = "Nécessaire pour les tests d'intégration"
                }
            }
        }
        "Securite" {
            $roles += [PSCustomObject]@{
                Role = "Spécialiste en sécurité"
                Count = 1
                Justification = "Nécessaire pour l'implémentation des mécanismes de sécurité"
            }
            if ($adjustedPersonnel -ge 4) {
                $roles += [PSCustomObject]@{
                    Role = "Testeur"
                    Count = 1
                    Justification = "Nécessaire pour les tests de sécurité"
                }
            }
        }
    }
    
    # Ajouter un chef de projet pour les améliorations complexes
    if ($adjustedPersonnel -ge 4) {
        $roles += [PSCustomObject]@{
            Role = "Chef de projet"
            Count = 1
            Justification = "Nécessaire pour la coordination de l'équipe"
        }
    }
    
    # Calculer le total de personnes
    $totalPersonnel = ($roles | Measure-Object -Property Count -Sum).Sum
    
    # Créer l'objet d'évaluation du personnel
    $personnelEvaluation = [PSCustomObject]@{
        BasePersonnel = $basePersonnel
        AdjustedPersonnel = $adjustedPersonnel
        TotalPersonnel = $totalPersonnel
        Roles = $roles
        Factors = $personnelFactors
    }
    
    return $personnelEvaluation
}

# Fonction pour générer le rapport au format Markdown
function Generate-MarkdownReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$PersonnelResults
    )

    $markdown = "# Détermination du Nombre de Personnes Nécessaires pour les Améliorations`n`n"
    $markdown += "Ce document présente la détermination du nombre de personnes nécessaires pour les améliorations identifiées pour les différents gestionnaires.`n`n"
    
    $markdown += "## Table des Matières`n`n"
    
    foreach ($manager in $PersonnelResults.Managers) {
        $markdown += "- [$($manager.Name)](#$($manager.Name.ToLower().Replace(' ', '-')))`n"
    }
    
    $markdown += "`n## Méthodologie`n`n"
    $markdown += "La détermination du nombre de personnes nécessaires a été réalisée en analysant les facteurs suivants :`n`n"
    $markdown += "1. **Complexité technique** (Poids : 35%) : Niveau de complexité technique de l'amélioration`n"
    $markdown += "2. **Nombre de compétences requises** (Poids : 25%) : Nombre de compétences différentes nécessaires`n"
    $markdown += "3. **Effort requis** (Poids : 20%) : Niveau d'effort requis pour l'implémentation`n"
    $markdown += "4. **Type d'amélioration** (Poids : 20%) : Type de l'amélioration (Fonctionnalité, Amélioration, Optimisation, etc.)`n`n"
    
    $markdown += "Chaque facteur est évalué sur une échelle de 1 à 10, puis pondéré pour obtenir un score global. Ce score est ensuite utilisé pour déterminer le nombre de personnes nécessaires.`n`n"
    
    $markdown += "### Échelle de Base du Personnel`n`n"
    $markdown += "| Score | Nombre de Personnes |`n"
    $markdown += "|-------|---------------------|`n"
    $markdown += "| < 3 | 1 personne |`n"
    $markdown += "| 3 - 4.99 | 2 personnes |`n"
    $markdown += "| 5 - 6.99 | 3 personnes |`n"
    $markdown += "| 7 - 8.49 | 4 personnes |`n"
    $markdown += "| >= 8.5 | 5 personnes |`n`n"
    
    $markdown += "Ce nombre de base est ensuite ajusté en fonction du gestionnaire et du type d'amélioration.`n`n"
    
    foreach ($manager in $PersonnelResults.Managers) {
        $markdown += "## <a name='$($manager.Name.ToLower().Replace(' ', '-'))'></a>$($manager.Name)`n`n"
        
        foreach ($improvement in $manager.Improvements) {
            $markdown += "### $($improvement.Name)`n`n"
            $markdown += "**Description :** $($improvement.Description)`n`n"
            $markdown += "**Type :** $($improvement.Type)`n`n"
            $markdown += "**Complexité technique :** $($improvement.ComplexityLevel)`n`n"
            $markdown += "**Nombre de compétences requises :** $($improvement.SkillsCount)`n`n"
            
            $markdown += "#### Évaluation du Personnel Nécessaire`n`n"
            $markdown += "**Nombre de personnes de base : $($improvement.PersonnelEvaluation.BasePersonnel)**`n`n"
            $markdown += "**Nombre de personnes ajusté : $($improvement.PersonnelEvaluation.AdjustedPersonnel)**`n`n"
            $markdown += "**Nombre total de personnes : $($improvement.PersonnelEvaluation.TotalPersonnel)**`n`n"
            
            $markdown += "**Facteurs d'évaluation :**`n`n"
            $markdown += "| Facteur | Poids | Score | Score pondéré |`n"
            $markdown += "|---------|-------|-------|---------------|`n"
            
            foreach ($factor in $improvement.PersonnelEvaluation.Factors.Keys) {
                $factorObj = $improvement.PersonnelEvaluation.Factors[$factor]
                $weightedScore = [Math]::Round($factorObj.Score * $factorObj.Weight, 2)
                $markdown += "| $factor | $($factorObj.Weight) | $($factorObj.Score) | $weightedScore |`n"
            }
            
            $markdown += "`n**Répartition par rôle :**`n`n"
            $markdown += "| Rôle | Nombre | Justification |`n"
            $markdown += "|------|--------|---------------|`n"
            
            foreach ($role in $improvement.PersonnelEvaluation.Roles) {
                $markdown += "| $($role.Role) | $($role.Count) | $($role.Justification) |`n"
            }
            
            $markdown += "`n#### Justification`n`n"
            
            # Justification pour la complexité technique
            $complexityScore = $improvement.PersonnelEvaluation.Factors.Complexity.Score
            $markdown += "**Complexité technique (Score : $complexityScore) :**`n"
            $markdown += "- Niveau de complexité : $($improvement.ComplexityLevel)`n"
            switch ($improvement.ComplexityLevel) {
                "Très élevée" {
                    $markdown += "- Complexité technique extrême nécessitant une équipe plus importante`n"
                    $markdown += "- Nombreux défis techniques à surmonter`n"
                }
                "Élevée" {
                    $markdown += "- Complexité technique significative nécessitant une équipe solide`n"
                    $markdown += "- Défis techniques importants à surmonter`n"
                }
                "Moyenne" {
                    $markdown += "- Complexité technique modérée nécessitant une équipe de taille moyenne`n"
                    $markdown += "- Quelques défis techniques à surmonter`n"
                }
                "Faible" {
                    $markdown += "- Complexité technique limitée nécessitant une petite équipe`n"
                    $markdown += "- Peu de défis techniques à surmonter`n"
                }
                "Très faible" {
                    $markdown += "- Complexité technique minimale pouvant être gérée par une seule personne`n"
                    $markdown += "- Défis techniques minimes`n"
                }
            }
            
            # Justification pour le nombre de compétences requises
            $skillsScore = $improvement.PersonnelEvaluation.Factors.Skills.Score
            $markdown += "`n**Nombre de compétences requises (Score : $skillsScore) :**`n"
            $markdown += "- Nombre de compétences : $($improvement.SkillsCount)`n"
            if ($improvement.SkillsCount -ge 10) {
                $markdown += "- Nombreuses compétences différentes nécessitant plusieurs personnes`n"
                $markdown += "- Difficulté à trouver toutes ces compétences chez une seule personne`n"
            } elseif ($improvement.SkillsCount -ge 5) {
                $markdown += "- Plusieurs compétences différentes nécessitant potentiellement plusieurs personnes`n"
                $markdown += "- Possibilité de répartir les compétences entre les membres de l'équipe`n"
            } else {
                $markdown += "- Peu de compétences différentes pouvant être couvertes par une seule personne`n"
                $markdown += "- Facilité à trouver ces compétences chez une seule personne`n"
            }
            
            # Justification pour l'effort requis
            $effortScore = $improvement.PersonnelEvaluation.Factors.Effort.Score
            $markdown += "`n**Effort requis (Score : $effortScore) :**`n"
            $markdown += "- Niveau d'effort : $($improvement.Effort)`n"
            switch ($improvement.Effort) {
                "Élevé" {
                    $markdown += "- Effort significatif nécessitant potentiellement plusieurs personnes`n"
                    $markdown += "- Charge de travail importante à répartir`n"
                }
                "Moyen" {
                    $markdown += "- Effort modéré pouvant nécessiter plusieurs personnes`n"
                    $markdown += "- Charge de travail modérée à répartir`n"
                }
                "Faible" {
                    $markdown += "- Effort limité pouvant être géré par une seule personne`n"
                    $markdown += "- Charge de travail limitée`n"
                }
            }
            
            # Justification pour le type d'amélioration
            $typeScore = $improvement.PersonnelEvaluation.Factors.Type.Score
            $markdown += "`n**Type d'amélioration (Score : $typeScore) :**`n"
            $markdown += "- Type : $($improvement.Type)`n"
            switch ($improvement.Type) {
                "Fonctionnalite" {
                    $markdown += "- Implémentation d'une nouvelle fonctionnalité nécessitant potentiellement plusieurs rôles`n"
                    $markdown += "- Besoin d'analyse, de développement et de tests`n"
                }
                "Amelioration" {
                    $markdown += "- Amélioration d'une fonctionnalité existante nécessitant potentiellement plusieurs rôles`n"
                    $markdown += "- Besoin de développement et de tests de régression`n"
                }
                "Optimisation" {
                    $markdown += "- Optimisation des performances nécessitant des compétences spécifiques`n"
                    $markdown += "- Besoin de spécialistes en performance et de tests de performance`n"
                }
                "Integration" {
                    $markdown += "- Intégration avec des systèmes externes nécessitant des compétences spécifiques`n"
                    $markdown += "- Besoin de spécialistes en intégration et de tests d'intégration`n"
                }
                "Securite" {
                    $markdown += "- Implémentation de mécanismes de sécurité nécessitant des compétences spécifiques`n"
                    $markdown += "- Besoin de spécialistes en sécurité et de tests de sécurité`n"
                }
            }
            
            $markdown += "`n"
        }
    }
    
    $markdown += "## Résumé`n`n"
    
    $totalImprovements = 0
    $totalPersonnel = 0
    $personnelByRole = @{}
    
    foreach ($manager in $PersonnelResults.Managers) {
        $totalImprovements += $manager.Improvements.Count
        
        foreach ($improvement in $manager.Improvements) {
            $totalPersonnel += $improvement.PersonnelEvaluation.TotalPersonnel
            
            foreach ($role in $improvement.PersonnelEvaluation.Roles) {
                if (-not $personnelByRole.ContainsKey($role.Role)) {
                    $personnelByRole[$role.Role] = 0
                }
                
                $personnelByRole[$role.Role] += $role.Count
            }
        }
    }
    
    $markdown += "Cette analyse a déterminé un besoin total de $totalPersonnel personnes pour $totalImprovements améliorations réparties sur $($PersonnelResults.Managers.Count) gestionnaires.`n`n"
    
    $markdown += "### Répartition par Rôle`n`n"
    $markdown += "| Rôle | Nombre | Pourcentage |`n"
    $markdown += "|------|--------|------------|`n"
    
    foreach ($role in $personnelByRole.Keys | Sort-Object) {
        $percentage = if ($totalPersonnel -gt 0) { [Math]::Round(($personnelByRole[$role] / $totalPersonnel) * 100, 1) } else { 0 }
        $markdown += "| $role | $($personnelByRole[$role]) | $percentage% |`n"
    }
    
    $markdown += "`n### Recommandations`n`n"
    $markdown += "1. **Optimisation des ressources** : Certaines personnes peuvent travailler sur plusieurs améliorations en parallèle, ce qui peut réduire le nombre total de personnes nécessaires.`n"
    $markdown += "2. **Priorisation** : Prioriser les améliorations en fonction des ressources disponibles et des besoins métier.`n"
    $markdown += "3. **Formation** : Former les membres de l'équipe aux compétences requises pour réduire le besoin de recruter de nouvelles personnes.`n"
    $markdown += "4. **Externalisation** : Envisager l'externalisation de certaines tâches spécifiques nécessitant des compétences rares ou très spécialisées.`n"
    $markdown += "5. **Planification** : Planifier les améliorations de manière à optimiser l'utilisation des ressources disponibles.`n"
    
    return $markdown
}

# Fonction pour générer le rapport au format JSON
function Generate-JsonReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$PersonnelResults
    )

    return $PersonnelResults | ConvertTo-Json -Depth 10
}

# Déterminer le nombre de personnes nécessaires pour chaque amélioration
$personnelResults = [PSCustomObject]@{
    GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Managers = @()
}

foreach ($manager in $improvementsData.Managers) {
    $managerPersonnel = [PSCustomObject]@{
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
            if ($improvement.Type -eq "Optimisation" -or $improvement.Type -eq "Integration" -or $improvement.Type -eq "Securite") {
                $complexityLevel = "Élevée"
            }
        } elseif ($improvement.Effort -eq "Faible") {
            $complexityLevel = "Faible"
        }
        
        # Déterminer le nombre de compétences requises (à partir de l'identification des compétences)
        $skillsCount = 0
        
        # Dans un cas réel, on récupérerait cette information du fichier des compétences requises
        # Pour simplifier, on utilise une logique basée sur le type et la complexité
        if ($complexityLevel -eq "Élevée") {
            $skillsCount = 8
        } elseif ($complexityLevel -eq "Moyenne") {
            $skillsCount = 5
        } else {
            $skillsCount = 3
        }
        
        if ($improvement.Type -eq "Optimisation" -or $improvement.Type -eq "Integration" -or $improvement.Type -eq "Securite") {
            $skillsCount += 2
        }
        
        # Déterminer le nombre de personnes nécessaires
        $personnelEvaluation = Determine-RequiredPersonnel -Improvement $improvement -ManagerName $manager.Name -ComplexityLevel $complexityLevel -SkillsCount $skillsCount
        
        $improvementPersonnel = [PSCustomObject]@{
            Name = $improvement.Name
            Description = $improvement.Description
            Type = $improvement.Type
            Effort = $improvement.Effort
            ComplexityLevel = $complexityLevel
            SkillsCount = $skillsCount
            PersonnelEvaluation = $personnelEvaluation
        }
        
        $managerPersonnel.Improvements += $improvementPersonnel
    }
    
    $personnelResults.Managers += $managerPersonnel
}

# Générer le rapport dans le format spécifié
switch ($Format) {
    "Markdown" {
        $reportContent = Generate-MarkdownReport -PersonnelResults $personnelResults
    }
    "JSON" {
        $reportContent = Generate-JsonReport -PersonnelResults $personnelResults
    }
}

# Enregistrer le rapport
try {
    $reportContent | Out-File -FilePath $OutputFile -Encoding UTF8
    Write-Host "Rapport du personnel requis généré avec succès : $OutputFile"
} catch {
    Write-Error "Erreur lors de l'enregistrement du rapport : $_"
    exit 1
}

# Afficher un résumé
Write-Host "`nRésumé de la détermination du nombre de personnes nécessaires :"
Write-Host "--------------------------------------------------------"

$totalImprovements = 0
$totalPersonnel = 0
$personnelByRole = @{}

foreach ($manager in $personnelResults.Managers) {
    $managerImprovements = $manager.Improvements.Count
    $managerPersonnel = 0
    
    foreach ($improvement in $manager.Improvements) {
        $managerPersonnel += $improvement.PersonnelEvaluation.TotalPersonnel
        
        foreach ($role in $improvement.PersonnelEvaluation.Roles) {
            if (-not $personnelByRole.ContainsKey($role.Role)) {
                $personnelByRole[$role.Role] = 0
            }
            
            $personnelByRole[$role.Role] += $role.Count
        }
    }
    
    $totalImprovements += $managerImprovements
    $totalPersonnel += $managerPersonnel
    
    Write-Host "  $($manager.Name) : $managerPersonnel personnes pour $managerImprovements améliorations"
}

Write-Host "  Total : $totalPersonnel personnes pour $totalImprovements améliorations"
Write-Host "`nRépartition par rôle :"
foreach ($role in $personnelByRole.Keys | Sort-Object) {
    $percentage = if ($totalPersonnel -gt 0) { [Math]::Round(($personnelByRole[$role] / $totalPersonnel) * 100, 1) } else { 0 }
    Write-Host "  $role : $($personnelByRole[$role]) ($percentage%)"
}
