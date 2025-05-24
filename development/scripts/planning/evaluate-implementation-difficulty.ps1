<#
.SYNOPSIS
    Ã‰value la difficultÃ© d'implÃ©mentation des amÃ©liorations.

.DESCRIPTION
    Ce script Ã©value la difficultÃ© d'implÃ©mentation des amÃ©liorations en analysant
    la complexitÃ© technique, l'expertise requise, les contraintes de temps et les
    dÃ©pendances.

.PARAMETER InputFile
    Chemin vers le fichier JSON contenant les amÃ©liorations Ã  Ã©valuer.

.PARAMETER TechnicalAnalysisFile
    Chemin vers le fichier d'analyse technique gÃ©nÃ©rÃ© prÃ©cÃ©demment.

.PARAMETER OutputFile
    Chemin vers le fichier de sortie pour le rapport d'Ã©valuation de la difficultÃ©.

.PARAMETER Format
    Format du rapport de sortie. Les valeurs possibles sont : JSON, Markdown.
    Par dÃ©faut : Markdown

.EXAMPLE
    .\evaluate-implementation-difficulty.ps1 -InputFile "data\improvements.json" -TechnicalAnalysisFile "data\planning\technical-analysis.md" -OutputFile "data\planning\implementation-difficulty.md"
    GÃ©nÃ¨re un rapport d'Ã©valuation de la difficultÃ© d'implÃ©mentation au format Markdown.

.NOTES
    Auteur: Planning Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-08
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$InputFile,

    [Parameter(Mandatory = $true)]
    [string]$TechnicalAnalysisFile,

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

# Fonction pour Ã©valuer la difficultÃ© d'implÃ©mentation
function Test-ImplementationDifficulty {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Improvement,
        
        [Parameter(Mandatory = $true)]
        [string]$ManagerName
    )

    # Facteurs de difficultÃ©
    $difficultyFactors = @{
        # ComplexitÃ© technique (basÃ©e sur les scores existants)
        TechnicalComplexity = @{
            Weight = 0.35
            Score = 0
        }
        
        # Expertise requise
        ExpertiseRequired = @{
            Weight = 0.25
            Score = 0
        }
        
        # Contraintes de temps
        TimeConstraints = @{
            Weight = 0.20
            Score = 0
        }
        
        # DÃ©pendances
        Dependencies = @{
            Weight = 0.20
            Score = 0
        }
    }
    
    # Ã‰valuer la complexitÃ© technique
    $technicalComplexityScore = 0
    
    # Utiliser les scores existants si disponibles
    if ($Improvement.Scores -and $Improvement.Scores.PSObject.Properties.Name -contains "Impact") {
        $technicalComplexityScore = $Improvement.Scores.Impact
    } else {
        # Estimer la complexitÃ© technique en fonction du type d'amÃ©lioration
        switch ($Improvement.Type) {
            "FonctionnalitÃ©" { $technicalComplexityScore = 7 }
            "AmÃ©lioration" { $technicalComplexityScore = 5 }
            "Optimisation" { $technicalComplexityScore = 8 }
            "IntÃ©gration" { $technicalComplexityScore = 8 }
            "SÃ©curitÃ©" { $technicalComplexityScore = 9 }
            default { $technicalComplexityScore = 6 }
        }
        
        # Ajuster en fonction de l'effort
        if ($Improvement.Effort -eq "Ã‰levÃ©") {
            $technicalComplexityScore += 2
        } elseif ($Improvement.Effort -eq "Faible") {
            $technicalComplexityScore -= 2
        }
        
        # Limiter le score entre 1 et 10
        $technicalComplexityScore = [Math]::Max(1, [Math]::Min(10, $technicalComplexityScore))
    }
    
    $difficultyFactors.TechnicalComplexity.Score = $technicalComplexityScore
    
    # Ã‰valuer l'expertise requise
    $expertiseRequiredScore = 0
    
    # Estimer l'expertise requise en fonction du type d'amÃ©lioration et du gestionnaire
    switch ($Improvement.Type) {
        "FonctionnalitÃ©" { $expertiseRequiredScore = 6 }
        "AmÃ©lioration" { $expertiseRequiredScore = 5 }
        "Optimisation" { $expertiseRequiredScore = 8 }
        "IntÃ©gration" { $expertiseRequiredScore = 7 }
        "SÃ©curitÃ©" { $expertiseRequiredScore = 9 }
        default { $expertiseRequiredScore = 6 }
    }
    
    # Ajuster en fonction du gestionnaire
    switch ($ManagerName) {
        "Process Manager" { $expertiseRequiredScore += 1 }
        "Integrated Manager" { $expertiseRequiredScore += 1 }
        "Error Manager" { $expertiseRequiredScore += 1 }
        "Configuration Manager" { $expertiseRequiredScore -= 1 }
        "Logging Manager" { $expertiseRequiredScore -= 1 }
    }
    
    # Limiter le score entre 1 et 10
    $expertiseRequiredScore = [Math]::Max(1, [Math]::Min(10, $expertiseRequiredScore))
    
    $difficultyFactors.ExpertiseRequired.Score = $expertiseRequiredScore
    
    # Ã‰valuer les contraintes de temps
    $timeConstraintsScore = 0
    
    # Estimer les contraintes de temps en fonction de l'effort
    switch ($Improvement.Effort) {
        "Ã‰levÃ©" { $timeConstraintsScore = 8 }
        "Moyen" { $timeConstraintsScore = 5 }
        "Faible" { $timeConstraintsScore = 3 }
        default { $timeConstraintsScore = 5 }
    }
    
    # Ajuster en fonction du type d'amÃ©lioration
    switch ($Improvement.Type) {
        "Optimisation" { $timeConstraintsScore += 1 }
        "IntÃ©gration" { $timeConstraintsScore += 1 }
        "SÃ©curitÃ©" { $timeConstraintsScore += 2 }
    }
    
    # Limiter le score entre 1 et 10
    $timeConstraintsScore = [Math]::Max(1, [Math]::Min(10, $timeConstraintsScore))
    
    $difficultyFactors.TimeConstraints.Score = $timeConstraintsScore
    
    # Ã‰valuer les dÃ©pendances
    $dependenciesScore = 0
    
    # Estimer les dÃ©pendances en fonction du nombre de dÃ©pendances
    if ($Improvement.Dependencies) {
        $dependenciesScore = [Math]::Min(10, $Improvement.Dependencies.Count * 2 + 3)
    } else {
        $dependenciesScore = 3
    }
    
    # Ajuster en fonction du type d'amÃ©lioration
    switch ($Improvement.Type) {
        "IntÃ©gration" { $dependenciesScore += 2 }
        "Optimisation" { $dependenciesScore += 1 }
    }
    
    # Limiter le score entre 1 et 10
    $dependenciesScore = [Math]::Max(1, [Math]::Min(10, $dependenciesScore))
    
    $difficultyFactors.Dependencies.Score = $dependenciesScore
    
    # Calculer le score de difficultÃ© global
    $difficultyScore = 0
    foreach ($factor in $difficultyFactors.Keys) {
        $difficultyScore += $difficultyFactors[$factor].Score * $difficultyFactors[$factor].Weight
    }
    
    # Arrondir Ã  deux dÃ©cimales
    $difficultyScore = [Math]::Round($difficultyScore, 2)
    
    # DÃ©terminer le niveau de difficultÃ©
    $difficultyLevel = ""
    switch ($difficultyScore) {
        {$_ -lt 3} { $difficultyLevel = "TrÃ¨s facile" }
        {$_ -ge 3 -and $_ -lt 5} { $difficultyLevel = "Facile" }
        {$_ -ge 5 -and $_ -lt 7} { $difficultyLevel = "ModÃ©rÃ©" }
        {$_ -ge 7 -and $_ -lt 8.5} { $difficultyLevel = "Difficile" }
        {$_ -ge 8.5} { $difficultyLevel = "TrÃ¨s difficile" }
    }
    
    # CrÃ©er l'objet d'Ã©valuation de la difficultÃ©
    $difficultyEvaluation = [PSCustomObject]@{
        Score = $difficultyScore
        Level = $difficultyLevel
        Factors = $difficultyFactors
    }
    
    return $difficultyEvaluation
}

# Fonction pour gÃ©nÃ©rer le rapport au format Markdown
function New-MarkdownReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$EvaluationResults
    )

    $markdown = "# Ã‰valuation de la DifficultÃ© d'ImplÃ©mentation des AmÃ©liorations`n`n"
    $markdown += "Ce document prÃ©sente l'Ã©valuation de la difficultÃ© d'implÃ©mentation des amÃ©liorations identifiÃ©es pour les diffÃ©rents gestionnaires.`n`n"
    
    $markdown += "## Table des MatiÃ¨res`n`n"
    
    foreach ($manager in $EvaluationResults.Managers) {
        $markdown += "- [$($manager.Name)](#$($manager.Name.ToLower().Replace(' ', '-')))`n"
    }
    
    $markdown += "`n## MÃ©thodologie`n`n"
    $markdown += "L'Ã©valuation de la difficultÃ© d'implÃ©mentation a Ã©tÃ© rÃ©alisÃ©e en analysant les facteurs suivants :`n`n"
    $markdown += "1. **ComplexitÃ© technique** (Poids : 35%) : Niveau de complexitÃ© technique de l'amÃ©lioration`n"
    $markdown += "2. **Expertise requise** (Poids : 25%) : Niveau d'expertise nÃ©cessaire pour l'implÃ©mentation`n"
    $markdown += "3. **Contraintes de temps** (Poids : 20%) : Contraintes temporelles liÃ©es Ã  l'implÃ©mentation`n"
    $markdown += "4. **DÃ©pendances** (Poids : 20%) : DÃ©pendances vis-Ã -vis d'autres composants ou systÃ¨mes`n`n"
    
    $markdown += "Chaque facteur est Ã©valuÃ© sur une Ã©chelle de 1 Ã  10, puis pondÃ©rÃ© pour obtenir un score global de difficultÃ©.`n`n"
    
    $markdown += "### Niveaux de DifficultÃ©`n`n"
    $markdown += "| Niveau | Score | Description |`n"
    $markdown += "|--------|-------|-------------|`n"
    $markdown += "| TrÃ¨s facile | < 3 | ImplÃ©mentation simple, peu de risques |`n"
    $markdown += "| Facile | 3 - 4.99 | ImplÃ©mentation relativement simple, risques limitÃ©s |`n"
    $markdown += "| ModÃ©rÃ© | 5 - 6.99 | ImplÃ©mentation de complexitÃ© moyenne, risques modÃ©rÃ©s |`n"
    $markdown += "| Difficile | 7 - 8.49 | ImplÃ©mentation complexe, risques significatifs |`n"
    $markdown += "| TrÃ¨s difficile | >= 8.5 | ImplÃ©mentation trÃ¨s complexe, risques Ã©levÃ©s |`n`n"
    
    foreach ($manager in $EvaluationResults.Managers) {
        $markdown += "## <a name='$($manager.Name.ToLower().Replace(' ', '-'))'></a>$($manager.Name)`n`n"
        
        foreach ($improvement in $manager.Improvements) {
            $markdown += "### $($improvement.Name)`n`n"
            $markdown += "**Description :** $($improvement.Description)`n`n"
            $markdown += "**Type :** $($improvement.Type)`n`n"
            $markdown += "**Effort :** $($improvement.Effort)`n`n"
            
            $markdown += "#### Ã‰valuation de la DifficultÃ©`n`n"
            $markdown += "**Score global : $($improvement.DifficultyEvaluation.Score)** (Niveau : $($improvement.DifficultyEvaluation.Level))`n`n"
            
            $markdown += "**Facteurs de difficultÃ© :**`n`n"
            $markdown += "| Facteur | Poids | Score | Score pondÃ©rÃ© |`n"
            $markdown += "|---------|-------|-------|---------------|`n"
            
            foreach ($factor in $improvement.DifficultyEvaluation.Factors.Keys) {
                $factorObj = $improvement.DifficultyEvaluation.Factors[$factor]
                $weightedScore = [Math]::Round($factorObj.Score * $factorObj.Weight, 2)
                $markdown += "| $factor | $($factorObj.Weight) | $($factorObj.Score) | $weightedScore |`n"
            }
            
            $markdown += "`n#### Justification`n`n"
            
            # Justification pour la complexitÃ© technique
            $technicalComplexityScore = $improvement.DifficultyEvaluation.Factors.TechnicalComplexity.Score
            $markdown += "**ComplexitÃ© technique (Score : $technicalComplexityScore) :**`n"
            if ($technicalComplexityScore -ge 8) {
                $markdown += "- AmÃ©lioration techniquement complexe nÃ©cessitant une expertise approfondie`n"
                $markdown += "- Implique des algorithmes ou des structures de donnÃ©es avancÃ©s`n"
                $markdown += "- NÃ©cessite une comprÃ©hension approfondie du systÃ¨me existant`n"
            } elseif ($technicalComplexityScore -ge 5) {
                $markdown += "- AmÃ©lioration de complexitÃ© technique moyenne`n"
                $markdown += "- Implique des modifications significatives mais bien dÃ©finies`n"
                $markdown += "- NÃ©cessite une bonne comprÃ©hension du systÃ¨me existant`n"
            } else {
                $markdown += "- AmÃ©lioration techniquement simple`n"
                $markdown += "- Implique des modifications mineures et bien dÃ©finies`n"
                $markdown += "- NÃ©cessite une comprÃ©hension de base du systÃ¨me existant`n"
            }
            
            # Justification pour l'expertise requise
            $expertiseRequiredScore = $improvement.DifficultyEvaluation.Factors.ExpertiseRequired.Score
            $markdown += "`n**Expertise requise (Score : $expertiseRequiredScore) :**`n"
            if ($expertiseRequiredScore -ge 8) {
                $markdown += "- NÃ©cessite une expertise spÃ©cialisÃ©e dans le domaine`n"
                $markdown += "- Requiert une expÃ©rience significative avec les technologies impliquÃ©es`n"
                $markdown += "- Peu de ressources disponibles avec l'expertise nÃ©cessaire`n"
            } elseif ($expertiseRequiredScore -ge 5) {
                $markdown += "- NÃ©cessite une bonne expertise dans le domaine`n"
                $markdown += "- Requiert une expÃ©rience modÃ©rÃ©e avec les technologies impliquÃ©es`n"
                $markdown += "- Ressources avec l'expertise nÃ©cessaire disponibles mais limitÃ©es`n"
            } else {
                $markdown += "- NÃ©cessite une expertise de base dans le domaine`n"
                $markdown += "- Requiert une expÃ©rience limitÃ©e avec les technologies impliquÃ©es`n"
                $markdown += "- Ressources avec l'expertise nÃ©cessaire facilement disponibles`n"
            }
            
            # Justification pour les contraintes de temps
            $timeConstraintsScore = $improvement.DifficultyEvaluation.Factors.TimeConstraints.Score
            $markdown += "`n**Contraintes de temps (Score : $timeConstraintsScore) :**`n"
            if ($timeConstraintsScore -ge 8) {
                $markdown += "- ImplÃ©mentation nÃ©cessitant un temps significatif`n"
                $markdown += "- Contraintes de temps strictes ou dÃ©lais serrÃ©s`n"
                $markdown += "- Risque Ã©levÃ© de dÃ©passement des dÃ©lais`n"
            } elseif ($timeConstraintsScore -ge 5) {
                $markdown += "- ImplÃ©mentation nÃ©cessitant un temps modÃ©rÃ©`n"
                $markdown += "- Contraintes de temps modÃ©rÃ©es`n"
                $markdown += "- Risque modÃ©rÃ© de dÃ©passement des dÃ©lais`n"
            } else {
                $markdown += "- ImplÃ©mentation rapide`n"
                $markdown += "- Contraintes de temps flexibles`n"
                $markdown += "- Faible risque de dÃ©passement des dÃ©lais`n"
            }
            
            # Justification pour les dÃ©pendances
            $dependenciesScore = $improvement.DifficultyEvaluation.Factors.Dependencies.Score
            $markdown += "`n**DÃ©pendances (Score : $dependenciesScore) :**`n"
            if ($dependenciesScore -ge 8) {
                $markdown += "- Nombreuses dÃ©pendances externes ou internes`n"
                $markdown += "- DÃ©pendances complexes ou mal dÃ©finies`n"
                $markdown += "- Risque Ã©levÃ© liÃ© aux dÃ©pendances`n"
            } elseif ($dependenciesScore -ge 5) {
                $markdown += "- Plusieurs dÃ©pendances externes ou internes`n"
                $markdown += "- DÃ©pendances modÃ©rÃ©ment complexes mais bien dÃ©finies`n"
                $markdown += "- Risque modÃ©rÃ© liÃ© aux dÃ©pendances`n"
            } else {
                $markdown += "- Peu ou pas de dÃ©pendances externes ou internes`n"
                $markdown += "- DÃ©pendances simples et bien dÃ©finies`n"
                $markdown += "- Faible risque liÃ© aux dÃ©pendances`n"
            }
            
            $markdown += "`n"
        }
    }
    
    $markdown += "## RÃ©sumÃ©`n`n"
    
    $totalImprovements = 0
    $difficultyLevels = @{
        "TrÃ¨s facile" = 0
        "Facile" = 0
        "ModÃ©rÃ©" = 0
        "Difficile" = 0
        "TrÃ¨s difficile" = 0
    }
    
    foreach ($manager in $EvaluationResults.Managers) {
        foreach ($improvement in $manager.Improvements) {
            $totalImprovements++
            $difficultyLevels[$improvement.DifficultyEvaluation.Level]++
        }
    }
    
    $markdown += "Cette Ã©valuation a couvert $totalImprovements amÃ©liorations rÃ©parties sur $($EvaluationResults.Managers.Count) gestionnaires.`n`n"
    
    $markdown += "### RÃ©partition par Niveau de DifficultÃ©`n`n"
    $markdown += "| Niveau | Nombre | Pourcentage |`n"
    $markdown += "|--------|--------|------------|`n"
    
    foreach ($level in @("TrÃ¨s facile", "Facile", "ModÃ©rÃ©", "Difficile", "TrÃ¨s difficile")) {
        $percentage = if ($totalImprovements -gt 0) { [Math]::Round(($difficultyLevels[$level] / $totalImprovements) * 100, 1) } else { 0 }
        $markdown += "| $level | $($difficultyLevels[$level]) | $percentage% |`n"
    }
    
    return $markdown
}

# Fonction pour gÃ©nÃ©rer le rapport au format JSON
function New-JsonReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$EvaluationResults
    )

    return $EvaluationResults | ConvertTo-Json -Depth 10
}

# Ã‰valuer la difficultÃ© d'implÃ©mentation des amÃ©liorations
$evaluationResults = [PSCustomObject]@{
    GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Managers = @()
}

foreach ($manager in $improvementsData.Managers) {
    $managerEvaluation = [PSCustomObject]@{
        Name = $manager.Name
        Category = $manager.Category
        Improvements = @()
    }
    
    foreach ($improvement in $manager.Improvements) {
        $difficultyEvaluation = Test-ImplementationDifficulty -Improvement $improvement -ManagerName $manager.Name
        
        $improvementEvaluation = [PSCustomObject]@{
            Name = $improvement.Name
            Description = $improvement.Description
            Type = $improvement.Type
            Effort = $improvement.Effort
            DifficultyEvaluation = $difficultyEvaluation
        }
        
        $managerEvaluation.Improvements += $improvementEvaluation
    }
    
    $evaluationResults.Managers += $managerEvaluation
}

# GÃ©nÃ©rer le rapport dans le format spÃ©cifiÃ©
switch ($Format) {
    "Markdown" {
        $reportContent = New-MarkdownReport -EvaluationResults $evaluationResults
    }
    "JSON" {
        $reportContent = New-JsonReport -EvaluationResults $evaluationResults
    }
}

# Enregistrer le rapport
try {
    $reportContent | Out-File -FilePath $OutputFile -Encoding UTF8
    Write-Host "Rapport d'Ã©valuation de la difficultÃ© d'implÃ©mentation gÃ©nÃ©rÃ© avec succÃ¨s : $OutputFile"
} catch {
    Write-Error "Erreur lors de l'enregistrement du rapport : $_"
    exit 1
}

# Afficher un rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ© de l'Ã©valuation de la difficultÃ© d'implÃ©mentation :"
Write-Host "--------------------------------------------------------"

$totalImprovements = 0
$difficultyLevels = @{
    "TrÃ¨s facile" = 0
    "Facile" = 0
    "ModÃ©rÃ©" = 0
    "Difficile" = 0
    "TrÃ¨s difficile" = 0
}

foreach ($manager in $evaluationResults.Managers) {
    $managerImprovements = $manager.Improvements.Count
    $totalImprovements += $managerImprovements
    
    foreach ($improvement in $manager.Improvements) {
        $difficultyLevels[$improvement.DifficultyEvaluation.Level]++
    }
    
    Write-Host "  $($manager.Name) : $managerImprovements amÃ©liorations"
}

Write-Host "  Total : $totalImprovements amÃ©liorations"
Write-Host "`nRÃ©partition par niveau de difficultÃ© :"
foreach ($level in @("TrÃ¨s facile", "Facile", "ModÃ©rÃ©", "Difficile", "TrÃ¨s difficile")) {
    $percentage = if ($totalImprovements -gt 0) { [Math]::Round(($difficultyLevels[$level] / $totalImprovements) * 100, 1) } else { 0 }
    Write-Host "  $level : $($difficultyLevels[$level]) ($percentage%)"
}


