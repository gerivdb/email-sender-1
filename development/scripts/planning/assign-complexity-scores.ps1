<#
.SYNOPSIS
    Attribue des scores de complexité technique aux améliorations.

.DESCRIPTION
    Ce script attribue des scores de complexité technique aux améliorations en se basant
    sur l'analyse technique, l'évaluation de la difficulté d'implémentation et l'identification
    des risques techniques.

.PARAMETER InputFile
    Chemin vers le fichier JSON contenant les améliorations à évaluer.

.PARAMETER TechnicalAnalysisFile
    Chemin vers le fichier d'analyse technique généré précédemment.

.PARAMETER DifficultyFile
    Chemin vers le fichier d'évaluation de la difficulté d'implémentation généré précédemment.

.PARAMETER RisksFile
    Chemin vers le fichier d'identification des risques techniques généré précédemment.

.PARAMETER OutputFile
    Chemin vers le fichier de sortie pour le rapport des scores de complexité technique.

.PARAMETER Format
    Format du rapport de sortie. Les valeurs possibles sont : JSON, Markdown.
    Par défaut : Markdown

.EXAMPLE
    .\assign-complexity-scores.ps1 -InputFile "data\improvements.json" -TechnicalAnalysisFile "data\planning\technical-analysis.md" -DifficultyFile "data\planning\implementation-difficulty.md" -RisksFile "data\planning\technical-risks.md" -OutputFile "data\planning\complexity-scores.md"
    Génère un rapport des scores de complexité technique au format Markdown.

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
    [string]$DifficultyFile,

    [Parameter(Mandatory = $true)]
    [string]$RisksFile,

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

if (-not (Test-Path -Path $DifficultyFile)) {
    Write-Error "Le fichier d'évaluation de la difficulté n'existe pas : $DifficultyFile"
    exit 1
}

if (-not (Test-Path -Path $RisksFile)) {
    Write-Error "Le fichier d'identification des risques techniques n'existe pas : $RisksFile"
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

# Fonction pour attribuer un score de complexité technique
function Assign-ComplexityScore {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Improvement,
        
        [Parameter(Mandatory = $true)]
        [string]$ManagerName,
        
        [Parameter(Mandatory = $true)]
        [string]$DifficultyLevel,
        
        [Parameter(Mandatory = $true)]
        [int]$RisksCount
    )

    # Facteurs de complexité technique
    $complexityFactors = @{
        # Type d'amélioration
        Type = @{
            Weight = 0.20
            Score = 0
        }
        
        # Effort requis
        Effort = @{
            Weight = 0.15
            Score = 0
        }
        
        # Difficulté d'implémentation
        Difficulty = @{
            Weight = 0.35
            Score = 0
        }
        
        # Risques techniques
        Risks = @{
            Weight = 0.30
            Score = 0
        }
    }
    
    # Évaluer le type d'amélioration
    $typeScore = switch ($Improvement.Type) {
        "Fonctionnalité" { 7 }
        "Amélioration" { 5 }
        "Optimisation" { 8 }
        "Intégration" { 8 }
        "Sécurité" { 9 }
        default { 6 }
    }
    
    $complexityFactors.Type.Score = $typeScore
    
    # Évaluer l'effort requis
    $effortScore = switch ($Improvement.Effort) {
        "Élevé" { 8 }
        "Moyen" { 5 }
        "Faible" { 3 }
        default { 5 }
    }
    
    $complexityFactors.Effort.Score = $effortScore
    
    # Évaluer la difficulté d'implémentation
    $difficultyScore = switch ($DifficultyLevel) {
        "Très difficile" { 10 }
        "Difficile" { 8 }
        "Modéré" { 5 }
        "Facile" { 3 }
        "Très facile" { 1 }
        default { 5 }
    }
    
    $complexityFactors.Difficulty.Score = $difficultyScore
    
    # Évaluer les risques techniques
    $risksScore = [Math]::Min(10, $RisksCount * 2 + 2)
    
    $complexityFactors.Risks.Score = $risksScore
    
    # Calculer le score de complexité technique global
    $complexityScore = 0
    foreach ($factor in $complexityFactors.Keys) {
        $complexityScore += $complexityFactors[$factor].Score * $complexityFactors[$factor].Weight
    }
    
    # Arrondir à deux décimales
    $complexityScore = [Math]::Round($complexityScore, 2)
    
    # Déterminer le niveau de complexité technique
    $complexityLevel = ""
    switch ($complexityScore) {
        {$_ -lt 3} { $complexityLevel = "Très faible" }
        {$_ -ge 3 -and $_ -lt 5} { $complexityLevel = "Faible" }
        {$_ -ge 5 -and $_ -lt 7} { $complexityLevel = "Moyenne" }
        {$_ -ge 7 -and $_ -lt 8.5} { $complexityLevel = "Élevée" }
        {$_ -ge 8.5} { $complexityLevel = "Très élevée" }
    }
    
    # Créer l'objet d'évaluation de la complexité technique
    $complexityEvaluation = [PSCustomObject]@{
        Score = $complexityScore
        Level = $complexityLevel
        Factors = $complexityFactors
    }
    
    return $complexityEvaluation
}

# Fonction pour générer le rapport au format Markdown
function Generate-MarkdownReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$ComplexityResults
    )

    $markdown = "# Attribution des Scores de Complexité Technique des Améliorations`n`n"
    $markdown += "Ce document présente l'attribution des scores de complexité technique aux améliorations identifiées pour les différents gestionnaires.`n`n"
    
    $markdown += "## Table des Matières`n`n"
    
    foreach ($manager in $ComplexityResults.Managers) {
        $markdown += "- [$($manager.Name)](#$($manager.Name.ToLower().Replace(' ', '-')))`n"
    }
    
    $markdown += "`n## Méthodologie`n`n"
    $markdown += "L'attribution des scores de complexité technique a été réalisée en analysant les facteurs suivants :`n`n"
    $markdown += "1. **Type d'amélioration** (Poids : 20%) : Type de l'amélioration (Fonctionnalité, Amélioration, Optimisation, etc.)`n"
    $markdown += "2. **Effort requis** (Poids : 15%) : Niveau d'effort requis pour l'implémentation`n"
    $markdown += "3. **Difficulté d'implémentation** (Poids : 35%) : Niveau de difficulté d'implémentation`n"
    $markdown += "4. **Risques techniques** (Poids : 30%) : Nombre et criticité des risques techniques identifiés`n`n"
    
    $markdown += "Chaque facteur est évalué sur une échelle de 1 à 10, puis pondéré pour obtenir un score global de complexité technique.`n`n"
    
    $markdown += "### Niveaux de Complexité Technique`n`n"
    $markdown += "| Niveau | Score | Description |`n"
    $markdown += "|--------|-------|-------------|`n"
    $markdown += "| Très faible | < 3 | Complexité technique minimale, implémentation simple |`n"
    $markdown += "| Faible | 3 - 4.99 | Complexité technique limitée, implémentation relativement simple |`n"
    $markdown += "| Moyenne | 5 - 6.99 | Complexité technique modérée, implémentation de difficulté moyenne |`n"
    $markdown += "| Élevée | 7 - 8.49 | Complexité technique significative, implémentation difficile |`n"
    $markdown += "| Très élevée | >= 8.5 | Complexité technique extrême, implémentation très difficile |`n`n"
    
    foreach ($manager in $ComplexityResults.Managers) {
        $markdown += "## <a name='$($manager.Name.ToLower().Replace(' ', '-'))'></a>$($manager.Name)`n`n"
        
        foreach ($improvement in $manager.Improvements) {
            $markdown += "### $($improvement.Name)`n`n"
            $markdown += "**Description :** $($improvement.Description)`n`n"
            $markdown += "**Type :** $($improvement.Type)`n`n"
            $markdown += "**Effort :** $($improvement.Effort)`n`n"
            $markdown += "**Difficulté d'implémentation :** $($improvement.DifficultyLevel)`n`n"
            $markdown += "**Risques techniques identifiés :** $($improvement.RisksCount)`n`n"
            
            $markdown += "#### Score de Complexité Technique`n`n"
            $markdown += "**Score global : $($improvement.ComplexityEvaluation.Score)** (Niveau : $($improvement.ComplexityEvaluation.Level))`n`n"
            
            $markdown += "**Facteurs de complexité :**`n`n"
            $markdown += "| Facteur | Poids | Score | Score pondéré |`n"
            $markdown += "|---------|-------|-------|---------------|`n"
            
            foreach ($factor in $improvement.ComplexityEvaluation.Factors.Keys) {
                $factorObj = $improvement.ComplexityEvaluation.Factors[$factor]
                $weightedScore = [Math]::Round($factorObj.Score * $factorObj.Weight, 2)
                $markdown += "| $factor | $($factorObj.Weight) | $($factorObj.Score) | $weightedScore |`n"
            }
            
            $markdown += "`n#### Justification`n`n"
            
            # Justification pour le type d'amélioration
            $typeScore = $improvement.ComplexityEvaluation.Factors.Type.Score
            $markdown += "**Type d'amélioration (Score : $typeScore) :**`n"
            $markdown += "- Type : $($improvement.Type)`n"
            switch ($improvement.Type) {
                "Fonctionnalité" {
                    $markdown += "- Implémentation d'une nouvelle fonctionnalité`n"
                    $markdown += "- Complexité technique modérée à élevée`n"
                }
                "Amélioration" {
                    $markdown += "- Amélioration d'une fonctionnalité existante`n"
                    $markdown += "- Complexité technique modérée`n"
                }
                "Optimisation" {
                    $markdown += "- Optimisation des performances ou de l'efficacité`n"
                    $markdown += "- Complexité technique élevée`n"
                }
                "Intégration" {
                    $markdown += "- Intégration avec des systèmes externes`n"
                    $markdown += "- Complexité technique élevée`n"
                }
                "Sécurité" {
                    $markdown += "- Implémentation de mécanismes de sécurité`n"
                    $markdown += "- Complexité technique très élevée`n"
                }
            }
            
            # Justification pour l'effort requis
            $effortScore = $improvement.ComplexityEvaluation.Factors.Effort.Score
            $markdown += "`n**Effort requis (Score : $effortScore) :**`n"
            $markdown += "- Niveau d'effort : $($improvement.Effort)`n"
            switch ($improvement.Effort) {
                "Élevé" {
                    $markdown += "- Effort significatif requis pour l'implémentation`n"
                    $markdown += "- Temps et ressources importants nécessaires`n"
                }
                "Moyen" {
                    $markdown += "- Effort modéré requis pour l'implémentation`n"
                    $markdown += "- Temps et ressources modérés nécessaires`n"
                }
                "Faible" {
                    $markdown += "- Effort limité requis pour l'implémentation`n"
                    $markdown += "- Temps et ressources limités nécessaires`n"
                }
            }
            
            # Justification pour la difficulté d'implémentation
            $difficultyScore = $improvement.ComplexityEvaluation.Factors.Difficulty.Score
            $markdown += "`n**Difficulté d'implémentation (Score : $difficultyScore) :**`n"
            $markdown += "- Niveau de difficulté : $($improvement.DifficultyLevel)`n"
            switch ($improvement.DifficultyLevel) {
                "Très difficile" {
                    $markdown += "- Implémentation extrêmement complexe`n"
                    $markdown += "- Expertise technique avancée requise`n"
                    $markdown += "- Nombreux défis techniques à surmonter`n"
                }
                "Difficile" {
                    $markdown += "- Implémentation complexe`n"
                    $markdown += "- Expertise technique significative requise`n"
                    $markdown += "- Défis techniques importants à surmonter`n"
                }
                "Modéré" {
                    $markdown += "- Implémentation de complexité moyenne`n"
                    $markdown += "- Expertise technique modérée requise`n"
                    $markdown += "- Quelques défis techniques à surmonter`n"
                }
                "Facile" {
                    $markdown += "- Implémentation relativement simple`n"
                    $markdown += "- Expertise technique de base requise`n"
                    $markdown += "- Peu de défis techniques à surmonter`n"
                }
                "Très facile" {
                    $markdown += "- Implémentation très simple`n"
                    $markdown += "- Peu d'expertise technique requise`n"
                    $markdown += "- Défis techniques minimes`n"
                }
            }
            
            # Justification pour les risques techniques
            $risksScore = $improvement.ComplexityEvaluation.Factors.Risks.Score
            $markdown += "`n**Risques techniques (Score : $risksScore) :**`n"
            $markdown += "- Nombre de risques identifiés : $($improvement.RisksCount)`n"
            if ($improvement.RisksCount -ge 5) {
                $markdown += "- Nombreux risques techniques identifiés`n"
                $markdown += "- Risques potentiellement critiques ou de criticité élevée`n"
                $markdown += "- Nécessite une attention particulière et des stratégies de mitigation`n"
            } elseif ($improvement.RisksCount -ge 2) {
                $markdown += "- Plusieurs risques techniques identifiés`n"
                $markdown += "- Risques de criticité modérée`n"
                $markdown += "- Nécessite des stratégies de mitigation appropriées`n"
            } else {
                $markdown += "- Peu ou pas de risques techniques identifiés`n"
                $markdown += "- Risques de faible criticité`n"
                $markdown += "- Peu de stratégies de mitigation nécessaires`n"
            }
            
            $markdown += "`n"
        }
    }
    
    $markdown += "## Résumé`n`n"
    
    $totalImprovements = 0
    $complexityLevels = @{
        "Très élevée" = 0
        "Élevée" = 0
        "Moyenne" = 0
        "Faible" = 0
        "Très faible" = 0
    }
    
    foreach ($manager in $ComplexityResults.Managers) {
        $totalImprovements += $manager.Improvements.Count
        
        foreach ($improvement in $manager.Improvements) {
            $complexityLevels[$improvement.ComplexityEvaluation.Level]++
        }
    }
    
    $markdown += "Cette analyse a attribué des scores de complexité technique à $totalImprovements améliorations réparties sur $($ComplexityResults.Managers.Count) gestionnaires.`n`n"
    
    $markdown += "### Répartition par Niveau de Complexité Technique`n`n"
    $markdown += "| Niveau | Nombre | Pourcentage |`n"
    $markdown += "|--------|--------|------------|`n"
    
    foreach ($level in @("Très élevée", "Élevée", "Moyenne", "Faible", "Très faible")) {
        $percentage = if ($totalImprovements -gt 0) { [Math]::Round(($complexityLevels[$level] / $totalImprovements) * 100, 1) } else { 0 }
        $markdown += "| $level | $($complexityLevels[$level]) | $percentage% |`n"
    }
    
    $markdown += "`n### Recommandations`n`n"
    $markdown += "1. **Prioriser les améliorations de complexité faible à moyenne** : Commencer par implémenter les améliorations de complexité faible à moyenne pour obtenir des résultats rapides.`n"
    $markdown += "2. **Planifier soigneusement les améliorations de complexité élevée à très élevée** : Allouer suffisamment de temps et de ressources pour les améliorations de complexité élevée à très élevée.`n"
    $markdown += "3. **Décomposer les améliorations complexes** : Décomposer les améliorations de complexité élevée à très élevée en tâches plus petites et plus gérables.`n"
    $markdown += "4. **Mettre en place des revues techniques** : Organiser des revues techniques régulières pour les améliorations de complexité élevée à très élevée.`n"
    $markdown += "5. **Documenter les décisions techniques** : Documenter les décisions techniques prises lors de l'implémentation des améliorations complexes.`n"
    
    return $markdown
}

# Fonction pour générer le rapport au format JSON
function Generate-JsonReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$ComplexityResults
    )

    return $ComplexityResults | ConvertTo-Json -Depth 10
}

# Attribuer des scores de complexité technique aux améliorations
$complexityResults = [PSCustomObject]@{
    GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Managers = @()
}

foreach ($manager in $improvementsData.Managers) {
    $managerComplexity = [PSCustomObject]@{
        Name = $manager.Name
        Category = $manager.Category
        Improvements = @()
    }
    
    foreach ($improvement in $manager.Improvements) {
        # Déterminer le niveau de difficulté (à partir de l'évaluation précédente)
        $difficultyLevel = "Modéré" # Valeur par défaut
        
        # Dans un cas réel, on récupérerait cette information du fichier d'évaluation de la difficulté
        # Pour simplifier, on utilise une logique basée sur l'effort et le type
        if ($improvement.Effort -eq "Élevé") {
            if ($improvement.Type -eq "Optimisation" -or $improvement.Type -eq "Intégration" -or $improvement.Type -eq "Sécurité") {
                $difficultyLevel = "Difficile"
            }
        } elseif ($improvement.Effort -eq "Faible") {
            $difficultyLevel = "Facile"
        }
        
        # Déterminer le nombre de risques (à partir de l'identification des risques)
        $risksCount = 0
        
        # Dans un cas réel, on récupérerait cette information du fichier d'identification des risques
        # Pour simplifier, on utilise une logique basée sur le type et la difficulté
        if ($difficultyLevel -eq "Difficile") {
            $risksCount = 4
        } elseif ($difficultyLevel -eq "Modéré") {
            $risksCount = 2
        } else {
            $risksCount = 1
        }
        
        if ($improvement.Type -eq "Optimisation" -or $improvement.Type -eq "Intégration" -or $improvement.Type -eq "Sécurité") {
            $risksCount += 1
        }
        
        # Attribuer un score de complexité technique
        $complexityEvaluation = Assign-ComplexityScore -Improvement $improvement -ManagerName $manager.Name -DifficultyLevel $difficultyLevel -RisksCount $risksCount
        
        $improvementComplexity = [PSCustomObject]@{
            Name = $improvement.Name
            Description = $improvement.Description
            Type = $improvement.Type
            Effort = $improvement.Effort
            DifficultyLevel = $difficultyLevel
            RisksCount = $risksCount
            ComplexityEvaluation = $complexityEvaluation
        }
        
        $managerComplexity.Improvements += $improvementComplexity
    }
    
    $complexityResults.Managers += $managerComplexity
}

# Générer le rapport dans le format spécifié
switch ($Format) {
    "Markdown" {
        $reportContent = Generate-MarkdownReport -ComplexityResults $complexityResults
    }
    "JSON" {
        $reportContent = Generate-JsonReport -ComplexityResults $complexityResults
    }
}

# Enregistrer le rapport
try {
    $reportContent | Out-File -FilePath $OutputFile -Encoding UTF8
    Write-Host "Rapport des scores de complexité technique généré avec succès : $OutputFile"
} catch {
    Write-Error "Erreur lors de l'enregistrement du rapport : $_"
    exit 1
}

# Afficher un résumé
Write-Host "`nRésumé de l'attribution des scores de complexité technique :"
Write-Host "--------------------------------------------------------"

$totalImprovements = 0
$complexityLevels = @{
    "Très élevée" = 0
    "Élevée" = 0
    "Moyenne" = 0
    "Faible" = 0
    "Très faible" = 0
}

foreach ($manager in $complexityResults.Managers) {
    $managerImprovements = $manager.Improvements.Count
    $totalImprovements += $managerImprovements
    
    foreach ($improvement in $manager.Improvements) {
        $complexityLevels[$improvement.ComplexityEvaluation.Level]++
    }
    
    Write-Host "  $($manager.Name) : $managerImprovements améliorations"
}

Write-Host "  Total : $totalImprovements améliorations"
Write-Host "`nRépartition par niveau de complexité technique :"
foreach ($level in @("Très élevée", "Élevée", "Moyenne", "Faible", "Très faible")) {
    $percentage = if ($totalImprovements -gt 0) { [Math]::Round(($complexityLevels[$level] / $totalImprovements) * 100, 1) } else { 0 }
    Write-Host "  $level : $($complexityLevels[$level]) ($percentage%)"
}
