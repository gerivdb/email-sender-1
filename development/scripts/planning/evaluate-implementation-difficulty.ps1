<#
.SYNOPSIS
    Évalue la difficulté d'implémentation des améliorations.

.DESCRIPTION
    Ce script évalue la difficulté d'implémentation des améliorations en analysant
    la complexité technique, l'expertise requise, les contraintes de temps et les
    dépendances.

.PARAMETER InputFile
    Chemin vers le fichier JSON contenant les améliorations à évaluer.

.PARAMETER TechnicalAnalysisFile
    Chemin vers le fichier d'analyse technique généré précédemment.

.PARAMETER OutputFile
    Chemin vers le fichier de sortie pour le rapport d'évaluation de la difficulté.

.PARAMETER Format
    Format du rapport de sortie. Les valeurs possibles sont : JSON, Markdown.
    Par défaut : Markdown

.EXAMPLE
    .\evaluate-implementation-difficulty.ps1 -InputFile "data\improvements.json" -TechnicalAnalysisFile "data\planning\technical-analysis.md" -OutputFile "data\planning\implementation-difficulty.md"
    Génère un rapport d'évaluation de la difficulté d'implémentation au format Markdown.

.NOTES
    Auteur: Planning Team
    Version: 1.0
    Date de création: 2025-05-08
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

# Vérifier que les fichiers d'entrée existent
if (-not (Test-Path -Path $InputFile)) {
    Write-Error "Le fichier d'entrée n'existe pas : $InputFile"
    exit 1
}

if (-not (Test-Path -Path $TechnicalAnalysisFile)) {
    Write-Error "Le fichier d'analyse technique n'existe pas : $TechnicalAnalysisFile"
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

# Fonction pour évaluer la difficulté d'implémentation
function Evaluate-ImplementationDifficulty {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Improvement,
        
        [Parameter(Mandatory = $true)]
        [string]$ManagerName
    )

    # Facteurs de difficulté
    $difficultyFactors = @{
        # Complexité technique (basée sur les scores existants)
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
        
        # Dépendances
        Dependencies = @{
            Weight = 0.20
            Score = 0
        }
    }
    
    # Évaluer la complexité technique
    $technicalComplexityScore = 0
    
    # Utiliser les scores existants si disponibles
    if ($Improvement.Scores -and $Improvement.Scores.PSObject.Properties.Name -contains "Impact") {
        $technicalComplexityScore = $Improvement.Scores.Impact
    } else {
        # Estimer la complexité technique en fonction du type d'amélioration
        switch ($Improvement.Type) {
            "Fonctionnalité" { $technicalComplexityScore = 7 }
            "Amélioration" { $technicalComplexityScore = 5 }
            "Optimisation" { $technicalComplexityScore = 8 }
            "Intégration" { $technicalComplexityScore = 8 }
            "Sécurité" { $technicalComplexityScore = 9 }
            default { $technicalComplexityScore = 6 }
        }
        
        # Ajuster en fonction de l'effort
        if ($Improvement.Effort -eq "Élevé") {
            $technicalComplexityScore += 2
        } elseif ($Improvement.Effort -eq "Faible") {
            $technicalComplexityScore -= 2
        }
        
        # Limiter le score entre 1 et 10
        $technicalComplexityScore = [Math]::Max(1, [Math]::Min(10, $technicalComplexityScore))
    }
    
    $difficultyFactors.TechnicalComplexity.Score = $technicalComplexityScore
    
    # Évaluer l'expertise requise
    $expertiseRequiredScore = 0
    
    # Estimer l'expertise requise en fonction du type d'amélioration et du gestionnaire
    switch ($Improvement.Type) {
        "Fonctionnalité" { $expertiseRequiredScore = 6 }
        "Amélioration" { $expertiseRequiredScore = 5 }
        "Optimisation" { $expertiseRequiredScore = 8 }
        "Intégration" { $expertiseRequiredScore = 7 }
        "Sécurité" { $expertiseRequiredScore = 9 }
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
    
    # Évaluer les contraintes de temps
    $timeConstraintsScore = 0
    
    # Estimer les contraintes de temps en fonction de l'effort
    switch ($Improvement.Effort) {
        "Élevé" { $timeConstraintsScore = 8 }
        "Moyen" { $timeConstraintsScore = 5 }
        "Faible" { $timeConstraintsScore = 3 }
        default { $timeConstraintsScore = 5 }
    }
    
    # Ajuster en fonction du type d'amélioration
    switch ($Improvement.Type) {
        "Optimisation" { $timeConstraintsScore += 1 }
        "Intégration" { $timeConstraintsScore += 1 }
        "Sécurité" { $timeConstraintsScore += 2 }
    }
    
    # Limiter le score entre 1 et 10
    $timeConstraintsScore = [Math]::Max(1, [Math]::Min(10, $timeConstraintsScore))
    
    $difficultyFactors.TimeConstraints.Score = $timeConstraintsScore
    
    # Évaluer les dépendances
    $dependenciesScore = 0
    
    # Estimer les dépendances en fonction du nombre de dépendances
    if ($Improvement.Dependencies) {
        $dependenciesScore = [Math]::Min(10, $Improvement.Dependencies.Count * 2 + 3)
    } else {
        $dependenciesScore = 3
    }
    
    # Ajuster en fonction du type d'amélioration
    switch ($Improvement.Type) {
        "Intégration" { $dependenciesScore += 2 }
        "Optimisation" { $dependenciesScore += 1 }
    }
    
    # Limiter le score entre 1 et 10
    $dependenciesScore = [Math]::Max(1, [Math]::Min(10, $dependenciesScore))
    
    $difficultyFactors.Dependencies.Score = $dependenciesScore
    
    # Calculer le score de difficulté global
    $difficultyScore = 0
    foreach ($factor in $difficultyFactors.Keys) {
        $difficultyScore += $difficultyFactors[$factor].Score * $difficultyFactors[$factor].Weight
    }
    
    # Arrondir à deux décimales
    $difficultyScore = [Math]::Round($difficultyScore, 2)
    
    # Déterminer le niveau de difficulté
    $difficultyLevel = ""
    switch ($difficultyScore) {
        {$_ -lt 3} { $difficultyLevel = "Très facile" }
        {$_ -ge 3 -and $_ -lt 5} { $difficultyLevel = "Facile" }
        {$_ -ge 5 -and $_ -lt 7} { $difficultyLevel = "Modéré" }
        {$_ -ge 7 -and $_ -lt 8.5} { $difficultyLevel = "Difficile" }
        {$_ -ge 8.5} { $difficultyLevel = "Très difficile" }
    }
    
    # Créer l'objet d'évaluation de la difficulté
    $difficultyEvaluation = [PSCustomObject]@{
        Score = $difficultyScore
        Level = $difficultyLevel
        Factors = $difficultyFactors
    }
    
    return $difficultyEvaluation
}

# Fonction pour générer le rapport au format Markdown
function Generate-MarkdownReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$EvaluationResults
    )

    $markdown = "# Évaluation de la Difficulté d'Implémentation des Améliorations`n`n"
    $markdown += "Ce document présente l'évaluation de la difficulté d'implémentation des améliorations identifiées pour les différents gestionnaires.`n`n"
    
    $markdown += "## Table des Matières`n`n"
    
    foreach ($manager in $EvaluationResults.Managers) {
        $markdown += "- [$($manager.Name)](#$($manager.Name.ToLower().Replace(' ', '-')))`n"
    }
    
    $markdown += "`n## Méthodologie`n`n"
    $markdown += "L'évaluation de la difficulté d'implémentation a été réalisée en analysant les facteurs suivants :`n`n"
    $markdown += "1. **Complexité technique** (Poids : 35%) : Niveau de complexité technique de l'amélioration`n"
    $markdown += "2. **Expertise requise** (Poids : 25%) : Niveau d'expertise nécessaire pour l'implémentation`n"
    $markdown += "3. **Contraintes de temps** (Poids : 20%) : Contraintes temporelles liées à l'implémentation`n"
    $markdown += "4. **Dépendances** (Poids : 20%) : Dépendances vis-à-vis d'autres composants ou systèmes`n`n"
    
    $markdown += "Chaque facteur est évalué sur une échelle de 1 à 10, puis pondéré pour obtenir un score global de difficulté.`n`n"
    
    $markdown += "### Niveaux de Difficulté`n`n"
    $markdown += "| Niveau | Score | Description |`n"
    $markdown += "|--------|-------|-------------|`n"
    $markdown += "| Très facile | < 3 | Implémentation simple, peu de risques |`n"
    $markdown += "| Facile | 3 - 4.99 | Implémentation relativement simple, risques limités |`n"
    $markdown += "| Modéré | 5 - 6.99 | Implémentation de complexité moyenne, risques modérés |`n"
    $markdown += "| Difficile | 7 - 8.49 | Implémentation complexe, risques significatifs |`n"
    $markdown += "| Très difficile | >= 8.5 | Implémentation très complexe, risques élevés |`n`n"
    
    foreach ($manager in $EvaluationResults.Managers) {
        $markdown += "## <a name='$($manager.Name.ToLower().Replace(' ', '-'))'></a>$($manager.Name)`n`n"
        
        foreach ($improvement in $manager.Improvements) {
            $markdown += "### $($improvement.Name)`n`n"
            $markdown += "**Description :** $($improvement.Description)`n`n"
            $markdown += "**Type :** $($improvement.Type)`n`n"
            $markdown += "**Effort :** $($improvement.Effort)`n`n"
            
            $markdown += "#### Évaluation de la Difficulté`n`n"
            $markdown += "**Score global : $($improvement.DifficultyEvaluation.Score)** (Niveau : $($improvement.DifficultyEvaluation.Level))`n`n"
            
            $markdown += "**Facteurs de difficulté :**`n`n"
            $markdown += "| Facteur | Poids | Score | Score pondéré |`n"
            $markdown += "|---------|-------|-------|---------------|`n"
            
            foreach ($factor in $improvement.DifficultyEvaluation.Factors.Keys) {
                $factorObj = $improvement.DifficultyEvaluation.Factors[$factor]
                $weightedScore = [Math]::Round($factorObj.Score * $factorObj.Weight, 2)
                $markdown += "| $factor | $($factorObj.Weight) | $($factorObj.Score) | $weightedScore |`n"
            }
            
            $markdown += "`n#### Justification`n`n"
            
            # Justification pour la complexité technique
            $technicalComplexityScore = $improvement.DifficultyEvaluation.Factors.TechnicalComplexity.Score
            $markdown += "**Complexité technique (Score : $technicalComplexityScore) :**`n"
            if ($technicalComplexityScore -ge 8) {
                $markdown += "- Amélioration techniquement complexe nécessitant une expertise approfondie`n"
                $markdown += "- Implique des algorithmes ou des structures de données avancés`n"
                $markdown += "- Nécessite une compréhension approfondie du système existant`n"
            } elseif ($technicalComplexityScore -ge 5) {
                $markdown += "- Amélioration de complexité technique moyenne`n"
                $markdown += "- Implique des modifications significatives mais bien définies`n"
                $markdown += "- Nécessite une bonne compréhension du système existant`n"
            } else {
                $markdown += "- Amélioration techniquement simple`n"
                $markdown += "- Implique des modifications mineures et bien définies`n"
                $markdown += "- Nécessite une compréhension de base du système existant`n"
            }
            
            # Justification pour l'expertise requise
            $expertiseRequiredScore = $improvement.DifficultyEvaluation.Factors.ExpertiseRequired.Score
            $markdown += "`n**Expertise requise (Score : $expertiseRequiredScore) :**`n"
            if ($expertiseRequiredScore -ge 8) {
                $markdown += "- Nécessite une expertise spécialisée dans le domaine`n"
                $markdown += "- Requiert une expérience significative avec les technologies impliquées`n"
                $markdown += "- Peu de ressources disponibles avec l'expertise nécessaire`n"
            } elseif ($expertiseRequiredScore -ge 5) {
                $markdown += "- Nécessite une bonne expertise dans le domaine`n"
                $markdown += "- Requiert une expérience modérée avec les technologies impliquées`n"
                $markdown += "- Ressources avec l'expertise nécessaire disponibles mais limitées`n"
            } else {
                $markdown += "- Nécessite une expertise de base dans le domaine`n"
                $markdown += "- Requiert une expérience limitée avec les technologies impliquées`n"
                $markdown += "- Ressources avec l'expertise nécessaire facilement disponibles`n"
            }
            
            # Justification pour les contraintes de temps
            $timeConstraintsScore = $improvement.DifficultyEvaluation.Factors.TimeConstraints.Score
            $markdown += "`n**Contraintes de temps (Score : $timeConstraintsScore) :**`n"
            if ($timeConstraintsScore -ge 8) {
                $markdown += "- Implémentation nécessitant un temps significatif`n"
                $markdown += "- Contraintes de temps strictes ou délais serrés`n"
                $markdown += "- Risque élevé de dépassement des délais`n"
            } elseif ($timeConstraintsScore -ge 5) {
                $markdown += "- Implémentation nécessitant un temps modéré`n"
                $markdown += "- Contraintes de temps modérées`n"
                $markdown += "- Risque modéré de dépassement des délais`n"
            } else {
                $markdown += "- Implémentation rapide`n"
                $markdown += "- Contraintes de temps flexibles`n"
                $markdown += "- Faible risque de dépassement des délais`n"
            }
            
            # Justification pour les dépendances
            $dependenciesScore = $improvement.DifficultyEvaluation.Factors.Dependencies.Score
            $markdown += "`n**Dépendances (Score : $dependenciesScore) :**`n"
            if ($dependenciesScore -ge 8) {
                $markdown += "- Nombreuses dépendances externes ou internes`n"
                $markdown += "- Dépendances complexes ou mal définies`n"
                $markdown += "- Risque élevé lié aux dépendances`n"
            } elseif ($dependenciesScore -ge 5) {
                $markdown += "- Plusieurs dépendances externes ou internes`n"
                $markdown += "- Dépendances modérément complexes mais bien définies`n"
                $markdown += "- Risque modéré lié aux dépendances`n"
            } else {
                $markdown += "- Peu ou pas de dépendances externes ou internes`n"
                $markdown += "- Dépendances simples et bien définies`n"
                $markdown += "- Faible risque lié aux dépendances`n"
            }
            
            $markdown += "`n"
        }
    }
    
    $markdown += "## Résumé`n`n"
    
    $totalImprovements = 0
    $difficultyLevels = @{
        "Très facile" = 0
        "Facile" = 0
        "Modéré" = 0
        "Difficile" = 0
        "Très difficile" = 0
    }
    
    foreach ($manager in $EvaluationResults.Managers) {
        foreach ($improvement in $manager.Improvements) {
            $totalImprovements++
            $difficultyLevels[$improvement.DifficultyEvaluation.Level]++
        }
    }
    
    $markdown += "Cette évaluation a couvert $totalImprovements améliorations réparties sur $($EvaluationResults.Managers.Count) gestionnaires.`n`n"
    
    $markdown += "### Répartition par Niveau de Difficulté`n`n"
    $markdown += "| Niveau | Nombre | Pourcentage |`n"
    $markdown += "|--------|--------|------------|`n"
    
    foreach ($level in @("Très facile", "Facile", "Modéré", "Difficile", "Très difficile")) {
        $percentage = if ($totalImprovements -gt 0) { [Math]::Round(($difficultyLevels[$level] / $totalImprovements) * 100, 1) } else { 0 }
        $markdown += "| $level | $($difficultyLevels[$level]) | $percentage% |`n"
    }
    
    return $markdown
}

# Fonction pour générer le rapport au format JSON
function Generate-JsonReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$EvaluationResults
    )

    return $EvaluationResults | ConvertTo-Json -Depth 10
}

# Évaluer la difficulté d'implémentation des améliorations
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
        $difficultyEvaluation = Evaluate-ImplementationDifficulty -Improvement $improvement -ManagerName $manager.Name
        
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

# Générer le rapport dans le format spécifié
switch ($Format) {
    "Markdown" {
        $reportContent = Generate-MarkdownReport -EvaluationResults $evaluationResults
    }
    "JSON" {
        $reportContent = Generate-JsonReport -EvaluationResults $evaluationResults
    }
}

# Enregistrer le rapport
try {
    $reportContent | Out-File -FilePath $OutputFile -Encoding UTF8
    Write-Host "Rapport d'évaluation de la difficulté d'implémentation généré avec succès : $OutputFile"
} catch {
    Write-Error "Erreur lors de l'enregistrement du rapport : $_"
    exit 1
}

# Afficher un résumé
Write-Host "`nRésumé de l'évaluation de la difficulté d'implémentation :"
Write-Host "--------------------------------------------------------"

$totalImprovements = 0
$difficultyLevels = @{
    "Très facile" = 0
    "Facile" = 0
    "Modéré" = 0
    "Difficile" = 0
    "Très difficile" = 0
}

foreach ($manager in $evaluationResults.Managers) {
    $managerImprovements = $manager.Improvements.Count
    $totalImprovements += $managerImprovements
    
    foreach ($improvement in $manager.Improvements) {
        $difficultyLevels[$improvement.DifficultyEvaluation.Level]++
    }
    
    Write-Host "  $($manager.Name) : $managerImprovements améliorations"
}

Write-Host "  Total : $totalImprovements améliorations"
Write-Host "`nRépartition par niveau de difficulté :"
foreach ($level in @("Très facile", "Facile", "Modéré", "Difficile", "Très difficile")) {
    $percentage = if ($totalImprovements -gt 0) { [Math]::Round(($difficultyLevels[$level] / $totalImprovements) * 100, 1) } else { 0 }
    Write-Host "  $level : $($difficultyLevels[$level]) ($percentage%)"
}
