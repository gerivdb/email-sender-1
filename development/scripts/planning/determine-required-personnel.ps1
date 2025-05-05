<#
.SYNOPSIS
    DÃ©termine le nombre de personnes nÃ©cessaires pour chaque amÃ©lioration.

.DESCRIPTION
    Ce script dÃ©termine le nombre de personnes nÃ©cessaires pour chaque amÃ©lioration en analysant
    la complexitÃ© technique, les compÃ©tences requises, l'effort estimÃ© et les contraintes de temps.

.PARAMETER InputFile
    Chemin vers le fichier JSON contenant les amÃ©liorations Ã  analyser.

.PARAMETER SkillsFile
    Chemin vers le fichier des compÃ©tences requises gÃ©nÃ©rÃ© prÃ©cÃ©demment.

.PARAMETER ComplexityScoresFile
    Chemin vers le fichier des scores de complexitÃ© technique gÃ©nÃ©rÃ© prÃ©cÃ©demment.

.PARAMETER OutputFile
    Chemin vers le fichier de sortie pour le rapport du personnel requis.

.PARAMETER Format
    Format du rapport de sortie. Les valeurs possibles sont : JSON, Markdown.
    Par dÃ©faut : Markdown

.EXAMPLE
    .\determine-required-personnel.ps1 -InputFile "data\improvements.json" -SkillsFile "data\planning\required-skills.md" -ComplexityScoresFile "data\planning\complexity-scores.md" -OutputFile "data\planning\required-personnel.md"
    GÃ©nÃ¨re un rapport du personnel requis au format Markdown.

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
    [string]$SkillsFile,

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

if (-not (Test-Path -Path $SkillsFile)) {
    Write-Error "Le fichier des compÃ©tences requises n'existe pas : $SkillsFile"
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

# Fonction pour dÃ©terminer le nombre de personnes nÃ©cessaires
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

    # Facteurs influenÃ§ant le nombre de personnes nÃ©cessaires
    $personnelFactors = @{
        # ComplexitÃ© technique
        Complexity = @{
            Weight = 0.35
            Score  = 0
        }

        # Nombre de compÃ©tences requises
        Skills     = @{
            Weight = 0.25
            Score  = 0
        }

        # Effort requis
        Effort     = @{
            Weight = 0.20
            Score  = 0
        }

        # Type d'amÃ©lioration
        Type       = @{
            Weight = 0.20
            Score  = 0
        }
    }

    # Ã‰valuer la complexitÃ© technique
    $complexityScore = switch ($ComplexityLevel) {
        "TrÃ¨s Ã©levÃ©e" { 10 }
        "Ã‰levÃ©e" { 8 }
        "Moyenne" { 5 }
        "Faible" { 3 }
        "TrÃ¨s faible" { 1 }
        default { 5 }
    }

    $personnelFactors.Complexity.Score = $complexityScore

    # Ã‰valuer le nombre de compÃ©tences requises
    $skillsScore = [Math]::Min(10, $SkillsCount / 2 + 2)

    $personnelFactors.Skills.Score = $skillsScore

    # Ã‰valuer l'effort requis
    $effortScore = switch ($Improvement.Effort) {
        "Ã‰levÃ©" { 8 }
        "Moyen" { 5 }
        "Faible" { 3 }
        default { 5 }
    }

    $personnelFactors.Effort.Score = $effortScore

    # Ã‰valuer le type d'amÃ©lioration
    $typeScore = switch ($Improvement.Type) {
        "FonctionnalitÃ©" { 7 }
        "AmÃ©lioration" { 5 }
        "Optimisation" { 8 }
        "IntÃ©gration" { 8 }
        "SÃ©curitÃ©" { 9 }
        default { 6 }
    }

    $personnelFactors.Type.Score = $typeScore

    # Calculer le score global
    $globalScore = 0
    foreach ($factor in $personnelFactors.Keys) {
        $globalScore += $personnelFactors[$factor].Score * $personnelFactors[$factor].Weight
    }

    # Arrondir Ã  deux dÃ©cimales
    $globalScore = [Math]::Round($globalScore, 2)

    # DÃ©terminer le nombre de personnes nÃ©cessaires
    $basePersonnel = switch ($globalScore) {
        { $_ -lt 3 } { 1 }
        { $_ -ge 3 -and $_ -lt 5 } { 2 }
        { $_ -ge 5 -and $_ -lt 7 } { 3 }
        { $_ -ge 7 -and $_ -lt 8.5 } { 4 }
        { $_ -ge 8.5 } { 5 }
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
            if ($Improvement.Type -eq "IntÃ©gration") {
                $adjustedPersonnel += 1
            }
        }
        "Error Manager" {
            if ($Improvement.Type -eq "SÃ©curitÃ©") {
                $adjustedPersonnel += 1
            }
        }
    }

    # DÃ©terminer les rÃ´les nÃ©cessaires
    $roles = @()

    # RÃ´les de base pour tous les types d'amÃ©lioration
    $roles += [PSCustomObject]@{
        Role          = "DÃ©veloppeur"
        Count         = [Math]::Max(1, [Math]::Floor($adjustedPersonnel * 0.5))
        Justification = "NÃ©cessaire pour l'implÃ©mentation"
    }

    # RÃ´les spÃ©cifiques au type d'amÃ©lioration
    switch ($Improvement.Type) {
        "Fonctionnalite" {
            $roles += [PSCustomObject]@{
                Role          = "Analyste"
                Count         = 1
                Justification = "NÃ©cessaire pour l'analyse des besoins"
            }
            if ($adjustedPersonnel -ge 3) {
                $roles += [PSCustomObject]@{
                    Role          = "Testeur"
                    Count         = 1
                    Justification = "NÃ©cessaire pour les tests"
                }
            }
        }
        "Amelioration" {
            if ($adjustedPersonnel -ge 3) {
                $roles += [PSCustomObject]@{
                    Role          = "Testeur"
                    Count         = 1
                    Justification = "NÃ©cessaire pour les tests de rÃ©gression"
                }
            }
        }
        "Optimisation" {
            $roles += [PSCustomObject]@{
                Role          = "SpÃ©cialiste en performance"
                Count         = 1
                Justification = "NÃ©cessaire pour l'optimisation des performances"
            }
            if ($adjustedPersonnel >= 4) {
                $roles += [PSCustomObject]@{
                    Role          = "Testeur"
                    Count         = 1
                    Justification = "NÃ©cessaire pour les tests de performance"
                }
            }
        }
        "IntÃ©gration" {
            $roles += [PSCustomObject]@{
                Role          = "SpÃ©cialiste en intÃ©gration"
                Count         = 1
                Justification = "NÃ©cessaire pour l'intÃ©gration avec des systÃ¨mes externes"
            }
            if ($adjustedPersonnel >= 4) {
                $roles += [PSCustomObject]@{
                    Role          = "Testeur"
                    Count         = 1
                    Justification = "NÃ©cessaire pour les tests d'intÃ©gration"
                }
            }
        }
        "SÃ©curitÃ©" {
            $roles += [PSCustomObject]@{
                Role          = "SpÃ©cialiste en sÃ©curitÃ©"
                Count         = 1
                Justification = "NÃ©cessaire pour l'implÃ©mentation des mÃ©canismes de sÃ©curitÃ©"
            }
            if ($adjustedPersonnel >= 4) {
                $roles += [PSCustomObject]@{
                    Role          = "Testeur"
                    Count         = 1
                    Justification = "NÃ©cessaire pour les tests de sÃ©curitÃ©"
                }
            }
        }
    }

    # Ajouter un chef de projet pour les amÃ©liorations complexes
    if ($adjustedPersonnel >= 4) {
        $roles += [PSCustomObject]@{
            Role          = "Chef de projet"
            Count         = 1
            Justification = "NÃ©cessaire pour la coordination de l'Ã©quipe"
        }
    }

    # Calculer le total de personnes
    $totalPersonnel = ($roles | Measure-Object -Property Count -Sum).Sum

    # CrÃ©er l'objet d'Ã©valuation du personnel
    $personnelEvaluation = [PSCustomObject]@{
        BasePersonnel     = $basePersonnel
        AdjustedPersonnel = $adjustedPersonnel
        TotalPersonnel    = $totalPersonnel
        Roles             = $roles
        Factors           = $personnelFactors
    }

    return $personnelEvaluation
}

# Fonction pour gÃ©nÃ©rer le rapport au format Markdown
function Generate-MarkdownReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$PersonnelResults
    )

    $markdown = "# DÃ©termination du Nombre de Personnes NÃ©cessaires pour les AmÃ©liorations`n`n"
    $markdown += "Ce document prÃ©sente la dÃ©termination du nombre de personnes nÃ©cessaires pour les amÃ©liorations identifiÃ©es pour les diffÃ©rents gestionnaires.`n`n"

    $markdown += "## Table des MatiÃ¨res`n`n"

    foreach ($manager in $PersonnelResults.Managers) {
        $markdown += "- [$($manager.Name)](#$($manager.Name.ToLower().Replace(' ', '-')))`n"
    }

    $markdown += "`n## MÃ©thodologie`n`n"
    $markdown += "La dÃ©termination du nombre de personnes nÃ©cessaires a Ã©tÃ© rÃ©alisÃ©e en analysant les facteurs suivants :`n`n"
    $markdown += "1. **ComplexitÃ© technique** (Poids : 35%) : Niveau de complexitÃ© technique de l'amÃ©lioration`n"
    $markdown += "2. **Nombre de compÃ©tences requises** (Poids : 25%) : Nombre de compÃ©tences diffÃ©rentes nÃ©cessaires`n"
    $markdown += "3. **Effort requis** (Poids : 20%) : Niveau d'effort requis pour l'implÃ©mentation`n"
    $markdown += "4. **Type d'amÃ©lioration** (Poids : 20%) : Type de l'amÃ©lioration (FonctionnalitÃ©, AmÃ©lioration, Optimisation, etc.)`n`n"

    $markdown += "Chaque facteur est Ã©valuÃ© sur une Ã©chelle de 1 Ã  10, puis pondÃ©rÃ© pour obtenir un score global. Ce score est ensuite utilisÃ© pour dÃ©terminer le nombre de personnes nÃ©cessaires.`n`n"

    $markdown += "### Ã‰chelle de Base du Personnel`n`n"
    $markdown += "| Score | Nombre de Personnes |`n"
    $markdown += "|-------|---------------------|`n"
    $markdown += "| < 3 | 1 personne |`n"
    $markdown += "| 3 - 4.99 | 2 personnes |`n"
    $markdown += "| 5 - 6.99 | 3 personnes |`n"
    $markdown += "| 7 - 8.49 | 4 personnes |`n"
    $markdown += "| >= 8.5 | 5 personnes |`n`n"

    $markdown += "Ce nombre de base est ensuite ajustÃ© en fonction du gestionnaire et du type d'amÃ©lioration.`n`n"

    foreach ($manager in $PersonnelResults.Managers) {
        $markdown += "## <a name='$($manager.Name.ToLower().Replace(' ', '-'))'></a>$($manager.Name)`n`n"

        foreach ($improvement in $manager.Improvements) {
            $markdown += "### $($improvement.Name)`n`n"
            $markdown += "**Description :** $($improvement.Description)`n`n"
            $markdown += "**Type :** $($improvement.Type)`n`n"
            $markdown += "**ComplexitÃ© technique :** $($improvement.ComplexityLevel)`n`n"
            $markdown += "**Nombre de compÃ©tences requises :** $($improvement.SkillsCount)`n`n"

            $markdown += "#### Ã‰valuation du Personnel NÃ©cessaire`n`n"
            $markdown += "**Nombre de personnes de base : $($improvement.PersonnelEvaluation.BasePersonnel)**`n`n"
            $markdown += "**Nombre de personnes ajustÃ© : $($improvement.PersonnelEvaluation.AdjustedPersonnel)**`n`n"
            $markdown += "**Nombre total de personnes : $($improvement.PersonnelEvaluation.TotalPersonnel)**`n`n"

            $markdown += "**Facteurs d'Ã©valuation :**`n`n"
            $markdown += "| Facteur | Poids | Score | Score pondÃ©rÃ© |`n"
            $markdown += "|---------|-------|-------|---------------|`n"

            foreach ($factor in $improvement.PersonnelEvaluation.Factors.Keys) {
                $factorObj = $improvement.PersonnelEvaluation.Factors[$factor]
                $weightedScore = [Math]::Round($factorObj.Score * $factorObj.Weight, 2)
                $markdown += "| $factor | $($factorObj.Weight) | $($factorObj.Score) | $weightedScore |`n"
            }

            $markdown += "`n**RÃ©partition par rÃ´le :**`n`n"
            $markdown += "| RÃ´le | Nombre | Justification |`n"
            $markdown += "|------|--------|---------------|`n"

            foreach ($role in $improvement.PersonnelEvaluation.Roles) {
                $markdown += "| $($role.Role) | $($role.Count) | $($role.Justification) |`n"
            }

            $markdown += "`n#### Justification`n`n"

            # Justification pour la complexitÃ© technique
            $complexityScore = $improvement.PersonnelEvaluation.Factors.Complexity.Score
            $markdown += "**ComplexitÃ© technique (Score : $complexityScore) :**`n"
            $markdown += "- Niveau de complexitÃ© : $($improvement.ComplexityLevel)`n"
            switch ($improvement.ComplexityLevel) {
                "TrÃ¨s Ã©levÃ©e" {
                    $markdown += "- ComplexitÃ© technique extrÃªme nÃ©cessitant une Ã©quipe plus importante`n"
                    $markdown += "- Nombreux dÃ©fis techniques Ã  surmonter`n"
                }
                "Ã‰levÃ©e" {
                    $markdown += "- ComplexitÃ© technique significative nÃ©cessitant une Ã©quipe solide`n"
                    $markdown += "- DÃ©fis techniques importants Ã  surmonter`n"
                }
                "Moyenne" {
                    $markdown += "- ComplexitÃ© technique modÃ©rÃ©e nÃ©cessitant une Ã©quipe de taille moyenne`n"
                    $markdown += "- Quelques dÃ©fis techniques Ã  surmonter`n"
                }
                "Faible" {
                    $markdown += "- ComplexitÃ© technique limitÃ©e nÃ©cessitant une petite Ã©quipe`n"
                    $markdown += "- Peu de dÃ©fis techniques Ã  surmonter`n"
                }
                "TrÃ¨s faible" {
                    $markdown += "- ComplexitÃ© technique minimale pouvant Ãªtre gÃ©rÃ©e par une seule personne`n"
                    $markdown += "- DÃ©fis techniques minimes`n"
                }
            }

            # Justification pour le nombre de compÃ©tences requises
            $skillsScore = $improvement.PersonnelEvaluation.Factors.Skills.Score
            $markdown += "`n**Nombre de compÃ©tences requises (Score : $skillsScore) :**`n"
            $markdown += "- Nombre de compÃ©tences : $($improvement.SkillsCount)`n"
            if ($improvement.SkillsCount -ge 10) {
                $markdown += "- Nombreuses compÃ©tences diffÃ©rentes nÃ©cessitant plusieurs personnes`n"
                $markdown += "- DifficultÃ© Ã  trouver toutes ces compÃ©tences chez une seule personne`n"
            } elseif ($improvement.SkillsCount -ge 5) {
                $markdown += "- Plusieurs compÃ©tences diffÃ©rentes nÃ©cessitant potentiellement plusieurs personnes`n"
                $markdown += "- PossibilitÃ© de rÃ©partir les compÃ©tences entre les membres de l'Ã©quipe`n"
            } else {
                $markdown += "- Peu de compÃ©tences diffÃ©rentes pouvant Ãªtre couvertes par une seule personne`n"
                $markdown += "- FacilitÃ© Ã  trouver ces compÃ©tences chez une seule personne`n"
            }

            # Justification pour l'effort requis
            $effortScore = $improvement.PersonnelEvaluation.Factors.Effort.Score
            $markdown += "`n**Effort requis (Score : $effortScore) :**`n"
            $markdown += "- Niveau d'effort : $($improvement.Effort)`n"
            switch ($improvement.Effort) {
                "Ã‰levÃ©" {
                    $markdown += "- Effort significatif nÃ©cessitant potentiellement plusieurs personnes`n"
                    $markdown += "- Charge de travail importante Ã  rÃ©partir`n"
                }
                "Moyen" {
                    $markdown += "- Effort modÃ©rÃ© pouvant nÃ©cessiter plusieurs personnes`n"
                    $markdown += "- Charge de travail modÃ©rÃ©e Ã  rÃ©partir`n"
                }
                "Faible" {
                    $markdown += "- Effort limitÃ© pouvant Ãªtre gÃ©rÃ© par une seule personne`n"
                    $markdown += "- Charge de travail limitÃ©e`n"
                }
            }

            # Justification pour le type d'amÃ©lioration
            $typeScore = $improvement.PersonnelEvaluation.Factors.Type.Score
            $markdown += "`n**Type d'amÃ©lioration (Score : $typeScore) :**`n"
            $markdown += "- Type : $($improvement.Type)`n"
            switch ($improvement.Type) {
                "FonctionnalitÃ©" {
                    $markdown += "- ImplÃ©mentation d'une nouvelle fonctionnalitÃ© nÃ©cessitant potentiellement plusieurs rÃ´les`n"
                    $markdown += "- Besoin d'analyse, de dÃ©veloppement et de tests`n"
                }
                "AmÃ©lioration" {
                    $markdown += "- AmÃ©lioration d'une fonctionnalitÃ© existante nÃ©cessitant potentiellement plusieurs rÃ´les`n"
                    $markdown += "- Besoin de dÃ©veloppement et de tests de rÃ©gression`n"
                }
                "Optimisation" {
                    $markdown += "- Optimisation des performances nÃ©cessitant des compÃ©tences spÃ©cifiques`n"
                    $markdown += "- Besoin de spÃ©cialistes en performance et de tests de performance`n"
                }
                "IntÃ©gration" {
                    $markdown += "- IntÃ©gration avec des systÃ¨mes externes nÃ©cessitant des compÃ©tences spÃ©cifiques`n"
                    $markdown += "- Besoin de spÃ©cialistes en intÃ©gration et de tests d'intÃ©gration`n"
                }
                "SÃ©curitÃ©" {
                    $markdown += "- ImplÃ©mentation de mÃ©canismes de sÃ©curitÃ© nÃ©cessitant des compÃ©tences spÃ©cifiques`n"
                    $markdown += "- Besoin de spÃ©cialistes en sÃ©curitÃ© et de tests de sÃ©curitÃ©`n"
                }
            }

            $markdown += "`n"
        }
    }

    $markdown += "## RÃ©sumÃ©`n`n"

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

    $markdown += "Cette analyse a dÃ©terminÃ© un besoin total de $totalPersonnel personnes pour $totalImprovements amÃ©liorations rÃ©parties sur $($PersonnelResults.Managers.Count) gestionnaires.`n`n"

    $markdown += "### RÃ©partition par RÃ´le`n`n"
    $markdown += "| RÃ´le | Nombre | Pourcentage |`n"
    $markdown += "|------|--------|------------|`n"

    foreach ($role in $personnelByRole.Keys | Sort-Object) {
        $percentage = if ($totalPersonnel -gt 0) { [Math]::Round(($personnelByRole[$role] / $totalPersonnel) * 100, 1) } else { 0 }
        $markdown += "| $role | $($personnelByRole[$role]) | $percentage% |`n"
    }

    $markdown += "`n### Recommandations`n`n"
    $markdown += "1. **Optimisation des ressources** : Certaines personnes peuvent travailler sur plusieurs amÃ©liorations en parallÃ¨le, ce qui peut rÃ©duire le nombre total de personnes nÃ©cessaires.`n"
    $markdown += "2. **Priorisation** : Prioriser les amÃ©liorations en fonction des ressources disponibles et des besoins mÃ©tier.`n"
    $markdown += "3. **Formation** : Former les membres de l'Ã©quipe aux compÃ©tences requises pour rÃ©duire le besoin de recruter de nouvelles personnes.`n"
    $markdown += "4. **Externalisation** : Envisager l'externalisation de certaines tÃ¢ches spÃ©cifiques nÃ©cessitant des compÃ©tences rares ou trÃ¨s spÃ©cialisÃ©es.`n"
    $markdown += "5. **Planification** : Planifier les amÃ©liorations de maniÃ¨re Ã  optimiser l'utilisation des ressources disponibles.`n"

    return $markdown
}

# Fonction pour gÃ©nÃ©rer le rapport au format JSON
function Generate-JsonReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$PersonnelResults
    )

    return $PersonnelResults | ConvertTo-Json -Depth 10
}

# DÃ©terminer le nombre de personnes nÃ©cessaires pour chaque amÃ©lioration
$personnelResults = [PSCustomObject]@{
    GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Managers    = @()
}

foreach ($manager in $improvementsData.Managers) {
    $managerPersonnel = [PSCustomObject]@{
        Name         = $manager.Name
        Category     = $manager.Category
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

        # DÃ©terminer le nombre de compÃ©tences requises (Ã  partir de l'identification des compÃ©tences)
        $skillsCount = 0

        # Dans un cas rÃ©el, on rÃ©cupÃ©rerait cette information du fichier des compÃ©tences requises
        # Pour simplifier, on utilise une logique basÃ©e sur le type et la complexitÃ©
        if ($complexityLevel -eq "Ã‰levÃ©e") {
            $skillsCount = 8
        } elseif ($complexityLevel -eq "Moyenne") {
            $skillsCount = 5
        } else {
            $skillsCount = 3
        }

        if ($improvement.Type -eq "Optimisation" -or $improvement.Type -eq "IntÃ©gration" -or $improvement.Type -eq "SÃ©curitÃ©") {
            $skillsCount += 2
        }

        # DÃ©terminer le nombre de personnes nÃ©cessaires
        $personnelEvaluation = Determine-RequiredPersonnel -Improvement $improvement -ManagerName $manager.Name -ComplexityLevel $complexityLevel -SkillsCount $skillsCount

        $improvementPersonnel = [PSCustomObject]@{
            Name                = $improvement.Name
            Description         = $improvement.Description
            Type                = $improvement.Type
            Effort              = $improvement.Effort
            ComplexityLevel     = $complexityLevel
            SkillsCount         = $skillsCount
            PersonnelEvaluation = $personnelEvaluation
        }

        $managerPersonnel.Improvements += $improvementPersonnel
    }

    $personnelResults.Managers += $managerPersonnel
}

# GÃ©nÃ©rer le rapport dans le format spÃ©cifiÃ©
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
    Write-Host "Rapport du personnel requis gÃ©nÃ©rÃ© avec succÃ¨s : $OutputFile"
} catch {
    Write-Error "Erreur lors de l'enregistrement du rapport : $_"
    exit 1
}

# Afficher un rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ© de la dÃ©termination du nombre de personnes nÃ©cessaires :"
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

    Write-Host "  $($manager.Name) : $managerPersonnel personnes pour $managerImprovements amÃ©liorations"
}

Write-Host "  Total : $totalPersonnel personnes pour $totalImprovements amÃ©liorations"
Write-Host "`nRÃ©partition par rÃ´le :"
foreach ($role in $personnelByRole.Keys | Sort-Object) {
    $percentage = if ($totalPersonnel -gt 0) { [Math]::Round(($personnelByRole[$role] / $totalPersonnel) * 100, 1) } else { 0 }
    Write-Host "  $role : $($personnelByRole[$role]) ($percentage%)"
}
