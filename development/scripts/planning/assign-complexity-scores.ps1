<#
.SYNOPSIS
    Attribue des scores de complexitÃ© technique aux amÃ©liorations.

.DESCRIPTION
    Ce script attribue des scores de complexitÃ© technique aux amÃ©liorations en se basant
    sur l'analyse technique, l'Ã©valuation de la difficultÃ© d'implÃ©mentation et l'identification
    des risques techniques.

.PARAMETER InputFile
    Chemin vers le fichier JSON contenant les amÃ©liorations Ã  Ã©valuer.

.PARAMETER TechnicalAnalysisFile
    Chemin vers le fichier d'analyse technique gÃ©nÃ©rÃ© prÃ©cÃ©demment.

.PARAMETER DifficultyFile
    Chemin vers le fichier d'Ã©valuation de la difficultÃ© d'implÃ©mentation gÃ©nÃ©rÃ© prÃ©cÃ©demment.

.PARAMETER RisksFile
    Chemin vers le fichier d'identification des risques techniques gÃ©nÃ©rÃ© prÃ©cÃ©demment.

.PARAMETER OutputFile
    Chemin vers le fichier de sortie pour le rapport des scores de complexitÃ© technique.

.PARAMETER Format
    Format du rapport de sortie. Les valeurs possibles sont : JSON, Markdown.
    Par dÃ©faut : Markdown

.EXAMPLE
    .\assign-complexity-scores.ps1 -InputFile "data\improvements.json" -TechnicalAnalysisFile "data\planning\technical-analysis.md" -DifficultyFile "data\planning\implementation-difficulty.md" -RisksFile "data\planning\technical-risks.md" -OutputFile "data\planning\complexity-scores.md"
    GÃ©nÃ¨re un rapport des scores de complexitÃ© technique au format Markdown.

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
    [string]$DifficultyFile,

    [Parameter(Mandatory = $true)]
    [string]$RisksFile,

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

if (-not (Test-Path -Path $DifficultyFile)) {
    Write-Error "Le fichier d'Ã©valuation de la difficultÃ© n'existe pas : $DifficultyFile"
    exit 1
}

if (-not (Test-Path -Path $RisksFile)) {
    Write-Error "Le fichier d'identification des risques techniques n'existe pas : $RisksFile"
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

# Fonction pour attribuer un score de complexitÃ© technique
function Set-ComplexityScore {
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

    # Facteurs de complexitÃ© technique
    $complexityFactors = @{
        # Type d'amÃ©lioration
        Type = @{
            Weight = 0.20
            Score = 0
        }
        
        # Effort requis
        Effort = @{
            Weight = 0.15
            Score = 0
        }
        
        # DifficultÃ© d'implÃ©mentation
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
    
    # Ã‰valuer le type d'amÃ©lioration
    $typeScore = switch ($Improvement.Type) {
        "FonctionnalitÃ©" { 7 }
        "AmÃ©lioration" { 5 }
        "Optimisation" { 8 }
        "IntÃ©gration" { 8 }
        "SÃ©curitÃ©" { 9 }
        default { 6 }
    }
    
    $complexityFactors.Type.Score = $typeScore
    
    # Ã‰valuer l'effort requis
    $effortScore = switch ($Improvement.Effort) {
        "Ã‰levÃ©" { 8 }
        "Moyen" { 5 }
        "Faible" { 3 }
        default { 5 }
    }
    
    $complexityFactors.Effort.Score = $effortScore
    
    # Ã‰valuer la difficultÃ© d'implÃ©mentation
    $difficultyScore = switch ($DifficultyLevel) {
        "TrÃ¨s difficile" { 10 }
        "Difficile" { 8 }
        "ModÃ©rÃ©" { 5 }
        "Facile" { 3 }
        "TrÃ¨s facile" { 1 }
        default { 5 }
    }
    
    $complexityFactors.Difficulty.Score = $difficultyScore
    
    # Ã‰valuer les risques techniques
    $risksScore = [Math]::Min(10, $RisksCount * 2 + 2)
    
    $complexityFactors.Risks.Score = $risksScore
    
    # Calculer le score de complexitÃ© technique global
    $complexityScore = 0
    foreach ($factor in $complexityFactors.Keys) {
        $complexityScore += $complexityFactors[$factor].Score * $complexityFactors[$factor].Weight
    }
    
    # Arrondir Ã  deux dÃ©cimales
    $complexityScore = [Math]::Round($complexityScore, 2)
    
    # DÃ©terminer le niveau de complexitÃ© technique
    $complexityLevel = ""
    switch ($complexityScore) {
        {$_ -lt 3} { $complexityLevel = "TrÃ¨s faible" }
        {$_ -ge 3 -and $_ -lt 5} { $complexityLevel = "Faible" }
        {$_ -ge 5 -and $_ -lt 7} { $complexityLevel = "Moyenne" }
        {$_ -ge 7 -and $_ -lt 8.5} { $complexityLevel = "Ã‰levÃ©e" }
        {$_ -ge 8.5} { $complexityLevel = "TrÃ¨s Ã©levÃ©e" }
    }
    
    # CrÃ©er l'objet d'Ã©valuation de la complexitÃ© technique
    $complexityEvaluation = [PSCustomObject]@{
        Score = $complexityScore
        Level = $complexityLevel
        Factors = $complexityFactors
    }
    
    return $complexityEvaluation
}

# Fonction pour gÃ©nÃ©rer le rapport au format Markdown
function New-MarkdownReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$ComplexityResults
    )

    $markdown = "# Attribution des Scores de ComplexitÃ© Technique des AmÃ©liorations`n`n"
    $markdown += "Ce document prÃ©sente l'attribution des scores de complexitÃ© technique aux amÃ©liorations identifiÃ©es pour les diffÃ©rents gestionnaires.`n`n"
    
    $markdown += "## Table des MatiÃ¨res`n`n"
    
    foreach ($manager in $ComplexityResults.Managers) {
        $markdown += "- [$($manager.Name)](#$($manager.Name.ToLower().Replace(' ', '-')))`n"
    }
    
    $markdown += "`n## MÃ©thodologie`n`n"
    $markdown += "L'attribution des scores de complexitÃ© technique a Ã©tÃ© rÃ©alisÃ©e en analysant les facteurs suivants :`n`n"
    $markdown += "1. **Type d'amÃ©lioration** (Poids : 20%) : Type de l'amÃ©lioration (FonctionnalitÃ©, AmÃ©lioration, Optimisation, etc.)`n"
    $markdown += "2. **Effort requis** (Poids : 15%) : Niveau d'effort requis pour l'implÃ©mentation`n"
    $markdown += "3. **DifficultÃ© d'implÃ©mentation** (Poids : 35%) : Niveau de difficultÃ© d'implÃ©mentation`n"
    $markdown += "4. **Risques techniques** (Poids : 30%) : Nombre et criticitÃ© des risques techniques identifiÃ©s`n`n"
    
    $markdown += "Chaque facteur est Ã©valuÃ© sur une Ã©chelle de 1 Ã  10, puis pondÃ©rÃ© pour obtenir un score global de complexitÃ© technique.`n`n"
    
    $markdown += "### Niveaux de ComplexitÃ© Technique`n`n"
    $markdown += "| Niveau | Score | Description |`n"
    $markdown += "|--------|-------|-------------|`n"
    $markdown += "| TrÃ¨s faible | < 3 | ComplexitÃ© technique minimale, implÃ©mentation simple |`n"
    $markdown += "| Faible | 3 - 4.99 | ComplexitÃ© technique limitÃ©e, implÃ©mentation relativement simple |`n"
    $markdown += "| Moyenne | 5 - 6.99 | ComplexitÃ© technique modÃ©rÃ©e, implÃ©mentation de difficultÃ© moyenne |`n"
    $markdown += "| Ã‰levÃ©e | 7 - 8.49 | ComplexitÃ© technique significative, implÃ©mentation difficile |`n"
    $markdown += "| TrÃ¨s Ã©levÃ©e | >= 8.5 | ComplexitÃ© technique extrÃªme, implÃ©mentation trÃ¨s difficile |`n`n"
    
    foreach ($manager in $ComplexityResults.Managers) {
        $markdown += "## <a name='$($manager.Name.ToLower().Replace(' ', '-'))'></a>$($manager.Name)`n`n"
        
        foreach ($improvement in $manager.Improvements) {
            $markdown += "### $($improvement.Name)`n`n"
            $markdown += "**Description :** $($improvement.Description)`n`n"
            $markdown += "**Type :** $($improvement.Type)`n`n"
            $markdown += "**Effort :** $($improvement.Effort)`n`n"
            $markdown += "**DifficultÃ© d'implÃ©mentation :** $($improvement.DifficultyLevel)`n`n"
            $markdown += "**Risques techniques identifiÃ©s :** $($improvement.RisksCount)`n`n"
            
            $markdown += "#### Score de ComplexitÃ© Technique`n`n"
            $markdown += "**Score global : $($improvement.ComplexityEvaluation.Score)** (Niveau : $($improvement.ComplexityEvaluation.Level))`n`n"
            
            $markdown += "**Facteurs de complexitÃ© :**`n`n"
            $markdown += "| Facteur | Poids | Score | Score pondÃ©rÃ© |`n"
            $markdown += "|---------|-------|-------|---------------|`n"
            
            foreach ($factor in $improvement.ComplexityEvaluation.Factors.Keys) {
                $factorObj = $improvement.ComplexityEvaluation.Factors[$factor]
                $weightedScore = [Math]::Round($factorObj.Score * $factorObj.Weight, 2)
                $markdown += "| $factor | $($factorObj.Weight) | $($factorObj.Score) | $weightedScore |`n"
            }
            
            $markdown += "`n#### Justification`n`n"
            
            # Justification pour le type d'amÃ©lioration
            $typeScore = $improvement.ComplexityEvaluation.Factors.Type.Score
            $markdown += "**Type d'amÃ©lioration (Score : $typeScore) :**`n"
            $markdown += "- Type : $($improvement.Type)`n"
            switch ($improvement.Type) {
                "FonctionnalitÃ©" {
                    $markdown += "- ImplÃ©mentation d'une nouvelle fonctionnalitÃ©`n"
                    $markdown += "- ComplexitÃ© technique modÃ©rÃ©e Ã  Ã©levÃ©e`n"
                }
                "AmÃ©lioration" {
                    $markdown += "- AmÃ©lioration d'une fonctionnalitÃ© existante`n"
                    $markdown += "- ComplexitÃ© technique modÃ©rÃ©e`n"
                }
                "Optimisation" {
                    $markdown += "- Optimisation des performances ou de l'efficacitÃ©`n"
                    $markdown += "- ComplexitÃ© technique Ã©levÃ©e`n"
                }
                "IntÃ©gration" {
                    $markdown += "- IntÃ©gration avec des systÃ¨mes externes`n"
                    $markdown += "- ComplexitÃ© technique Ã©levÃ©e`n"
                }
                "SÃ©curitÃ©" {
                    $markdown += "- ImplÃ©mentation de mÃ©canismes de sÃ©curitÃ©`n"
                    $markdown += "- ComplexitÃ© technique trÃ¨s Ã©levÃ©e`n"
                }
            }
            
            # Justification pour l'effort requis
            $effortScore = $improvement.ComplexityEvaluation.Factors.Effort.Score
            $markdown += "`n**Effort requis (Score : $effortScore) :**`n"
            $markdown += "- Niveau d'effort : $($improvement.Effort)`n"
            switch ($improvement.Effort) {
                "Ã‰levÃ©" {
                    $markdown += "- Effort significatif requis pour l'implÃ©mentation`n"
                    $markdown += "- Temps et ressources importants nÃ©cessaires`n"
                }
                "Moyen" {
                    $markdown += "- Effort modÃ©rÃ© requis pour l'implÃ©mentation`n"
                    $markdown += "- Temps et ressources modÃ©rÃ©s nÃ©cessaires`n"
                }
                "Faible" {
                    $markdown += "- Effort limitÃ© requis pour l'implÃ©mentation`n"
                    $markdown += "- Temps et ressources limitÃ©s nÃ©cessaires`n"
                }
            }
            
            # Justification pour la difficultÃ© d'implÃ©mentation
            $difficultyScore = $improvement.ComplexityEvaluation.Factors.Difficulty.Score
            $markdown += "`n**DifficultÃ© d'implÃ©mentation (Score : $difficultyScore) :**`n"
            $markdown += "- Niveau de difficultÃ© : $($improvement.DifficultyLevel)`n"
            switch ($improvement.DifficultyLevel) {
                "TrÃ¨s difficile" {
                    $markdown += "- ImplÃ©mentation extrÃªmement complexe`n"
                    $markdown += "- Expertise technique avancÃ©e requise`n"
                    $markdown += "- Nombreux dÃ©fis techniques Ã  surmonter`n"
                }
                "Difficile" {
                    $markdown += "- ImplÃ©mentation complexe`n"
                    $markdown += "- Expertise technique significative requise`n"
                    $markdown += "- DÃ©fis techniques importants Ã  surmonter`n"
                }
                "ModÃ©rÃ©" {
                    $markdown += "- ImplÃ©mentation de complexitÃ© moyenne`n"
                    $markdown += "- Expertise technique modÃ©rÃ©e requise`n"
                    $markdown += "- Quelques dÃ©fis techniques Ã  surmonter`n"
                }
                "Facile" {
                    $markdown += "- ImplÃ©mentation relativement simple`n"
                    $markdown += "- Expertise technique de base requise`n"
                    $markdown += "- Peu de dÃ©fis techniques Ã  surmonter`n"
                }
                "TrÃ¨s facile" {
                    $markdown += "- ImplÃ©mentation trÃ¨s simple`n"
                    $markdown += "- Peu d'expertise technique requise`n"
                    $markdown += "- DÃ©fis techniques minimes`n"
                }
            }
            
            # Justification pour les risques techniques
            $risksScore = $improvement.ComplexityEvaluation.Factors.Risks.Score
            $markdown += "`n**Risques techniques (Score : $risksScore) :**`n"
            $markdown += "- Nombre de risques identifiÃ©s : $($improvement.RisksCount)`n"
            if ($improvement.RisksCount -ge 5) {
                $markdown += "- Nombreux risques techniques identifiÃ©s`n"
                $markdown += "- Risques potentiellement critiques ou de criticitÃ© Ã©levÃ©e`n"
                $markdown += "- NÃ©cessite une attention particuliÃ¨re et des stratÃ©gies de mitigation`n"
            } elseif ($improvement.RisksCount -ge 2) {
                $markdown += "- Plusieurs risques techniques identifiÃ©s`n"
                $markdown += "- Risques de criticitÃ© modÃ©rÃ©e`n"
                $markdown += "- NÃ©cessite des stratÃ©gies de mitigation appropriÃ©es`n"
            } else {
                $markdown += "- Peu ou pas de risques techniques identifiÃ©s`n"
                $markdown += "- Risques de faible criticitÃ©`n"
                $markdown += "- Peu de stratÃ©gies de mitigation nÃ©cessaires`n"
            }
            
            $markdown += "`n"
        }
    }
    
    $markdown += "## RÃ©sumÃ©`n`n"
    
    $totalImprovements = 0
    $complexityLevels = @{
        "TrÃ¨s Ã©levÃ©e" = 0
        "Ã‰levÃ©e" = 0
        "Moyenne" = 0
        "Faible" = 0
        "TrÃ¨s faible" = 0
    }
    
    foreach ($manager in $ComplexityResults.Managers) {
        $totalImprovements += $manager.Improvements.Count
        
        foreach ($improvement in $manager.Improvements) {
            $complexityLevels[$improvement.ComplexityEvaluation.Level]++
        }
    }
    
    $markdown += "Cette analyse a attribuÃ© des scores de complexitÃ© technique Ã  $totalImprovements amÃ©liorations rÃ©parties sur $($ComplexityResults.Managers.Count) gestionnaires.`n`n"
    
    $markdown += "### RÃ©partition par Niveau de ComplexitÃ© Technique`n`n"
    $markdown += "| Niveau | Nombre | Pourcentage |`n"
    $markdown += "|--------|--------|------------|`n"
    
    foreach ($level in @("TrÃ¨s Ã©levÃ©e", "Ã‰levÃ©e", "Moyenne", "Faible", "TrÃ¨s faible")) {
        $percentage = if ($totalImprovements -gt 0) { [Math]::Round(($complexityLevels[$level] / $totalImprovements) * 100, 1) } else { 0 }
        $markdown += "| $level | $($complexityLevels[$level]) | $percentage% |`n"
    }
    
    $markdown += "`n### Recommandations`n`n"
    $markdown += "1. **Prioriser les amÃ©liorations de complexitÃ© faible Ã  moyenne** : Commencer par implÃ©menter les amÃ©liorations de complexitÃ© faible Ã  moyenne pour obtenir des rÃ©sultats rapides.`n"
    $markdown += "2. **Planifier soigneusement les amÃ©liorations de complexitÃ© Ã©levÃ©e Ã  trÃ¨s Ã©levÃ©e** : Allouer suffisamment de temps et de ressources pour les amÃ©liorations de complexitÃ© Ã©levÃ©e Ã  trÃ¨s Ã©levÃ©e.`n"
    $markdown += "3. **DÃ©composer les amÃ©liorations complexes** : DÃ©composer les amÃ©liorations de complexitÃ© Ã©levÃ©e Ã  trÃ¨s Ã©levÃ©e en tÃ¢ches plus petites et plus gÃ©rables.`n"
    $markdown += "4. **Mettre en place des revues techniques** : Organiser des revues techniques rÃ©guliÃ¨res pour les amÃ©liorations de complexitÃ© Ã©levÃ©e Ã  trÃ¨s Ã©levÃ©e.`n"
    $markdown += "5. **Documenter les dÃ©cisions techniques** : Documenter les dÃ©cisions techniques prises lors de l'implÃ©mentation des amÃ©liorations complexes.`n"
    
    return $markdown
}

# Fonction pour gÃ©nÃ©rer le rapport au format JSON
function New-JsonReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$ComplexityResults
    )

    return $ComplexityResults | ConvertTo-Json -Depth 10
}

# Attribuer des scores de complexitÃ© technique aux amÃ©liorations
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
        # DÃ©terminer le niveau de difficultÃ© (Ã  partir de l'Ã©valuation prÃ©cÃ©dente)
        $difficultyLevel = "ModÃ©rÃ©" # Valeur par dÃ©faut
        
        # Dans un cas rÃ©el, on rÃ©cupÃ©rerait cette information du fichier d'Ã©valuation de la difficultÃ©
        # Pour simplifier, on utilise une logique basÃ©e sur l'effort et le type
        if ($improvement.Effort -eq "Ã‰levÃ©") {
            if ($improvement.Type -eq "Optimisation" -or $improvement.Type -eq "IntÃ©gration" -or $improvement.Type -eq "SÃ©curitÃ©") {
                $difficultyLevel = "Difficile"
            }
        } elseif ($improvement.Effort -eq "Faible") {
            $difficultyLevel = "Facile"
        }
        
        # DÃ©terminer le nombre de risques (Ã  partir de l'identification des risques)
        $risksCount = 0
        
        # Dans un cas rÃ©el, on rÃ©cupÃ©rerait cette information du fichier d'identification des risques
        # Pour simplifier, on utilise une logique basÃ©e sur le type et la difficultÃ©
        if ($difficultyLevel -eq "Difficile") {
            $risksCount = 4
        } elseif ($difficultyLevel -eq "ModÃ©rÃ©") {
            $risksCount = 2
        } else {
            $risksCount = 1
        }
        
        if ($improvement.Type -eq "Optimisation" -or $improvement.Type -eq "IntÃ©gration" -or $improvement.Type -eq "SÃ©curitÃ©") {
            $risksCount += 1
        }
        
        # Attribuer un score de complexitÃ© technique
        $complexityEvaluation = Set-ComplexityScore -Improvement $improvement -ManagerName $manager.Name -DifficultyLevel $difficultyLevel -RisksCount $risksCount
        
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

# GÃ©nÃ©rer le rapport dans le format spÃ©cifiÃ©
switch ($Format) {
    "Markdown" {
        $reportContent = New-MarkdownReport -ComplexityResults $complexityResults
    }
    "JSON" {
        $reportContent = New-JsonReport -ComplexityResults $complexityResults
    }
}

# Enregistrer le rapport
try {
    $reportContent | Out-File -FilePath $OutputFile -Encoding UTF8
    Write-Host "Rapport des scores de complexitÃ© technique gÃ©nÃ©rÃ© avec succÃ¨s : $OutputFile"
} catch {
    Write-Error "Erreur lors de l'enregistrement du rapport : $_"
    exit 1
}

# Afficher un rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ© de l'attribution des scores de complexitÃ© technique :"
Write-Host "--------------------------------------------------------"

$totalImprovements = 0
$complexityLevels = @{
    "TrÃ¨s Ã©levÃ©e" = 0
    "Ã‰levÃ©e" = 0
    "Moyenne" = 0
    "Faible" = 0
    "TrÃ¨s faible" = 0
}

foreach ($manager in $complexityResults.Managers) {
    $managerImprovements = $manager.Improvements.Count
    $totalImprovements += $managerImprovements
    
    foreach ($improvement in $manager.Improvements) {
        $complexityLevels[$improvement.ComplexityEvaluation.Level]++
    }
    
    Write-Host "  $($manager.Name) : $managerImprovements amÃ©liorations"
}

Write-Host "  Total : $totalImprovements amÃ©liorations"
Write-Host "`nRÃ©partition par niveau de complexitÃ© technique :"
foreach ($level in @("TrÃ¨s Ã©levÃ©e", "Ã‰levÃ©e", "Moyenne", "Faible", "TrÃ¨s faible")) {
    $percentage = if ($totalImprovements -gt 0) { [Math]::Round(($complexityLevels[$level] / $totalImprovements) * 100, 1) } else { 0 }
    Write-Host "  $level : $($complexityLevels[$level]) ($percentage%)"
}


