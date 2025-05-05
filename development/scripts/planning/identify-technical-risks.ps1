<#
.SYNOPSIS
    Identifie les risques techniques des amÃ©liorations.

.DESCRIPTION
    Ce script identifie les risques techniques associÃ©s aux amÃ©liorations en analysant
    la complexitÃ© technique, les dÃ©pendances, les technologies et les contraintes.

.PARAMETER InputFile
    Chemin vers le fichier JSON contenant les amÃ©liorations Ã  analyser.

.PARAMETER DifficultyFile
    Chemin vers le fichier d'Ã©valuation de la difficultÃ© d'implÃ©mentation gÃ©nÃ©rÃ© prÃ©cÃ©demment.

.PARAMETER OutputFile
    Chemin vers le fichier de sortie pour le rapport des risques techniques.

.PARAMETER Format
    Format du rapport de sortie. Les valeurs possibles sont : JSON, Markdown.
    Par dÃ©faut : Markdown

.EXAMPLE
    .\identify-technical-risks.ps1 -InputFile "data\improvements.json" -DifficultyFile "data\planning\implementation-difficulty.md" -OutputFile "data\planning\technical-risks.md"
    GÃ©nÃ¨re un rapport des risques techniques au format Markdown.

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
    [string]$DifficultyFile,

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

if (-not (Test-Path -Path $DifficultyFile)) {
    Write-Error "Le fichier d'Ã©valuation de la difficultÃ© n'existe pas : $DifficultyFile"
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

# Fonction pour identifier les risques techniques
function Identify-TechnicalRisks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Improvement,
        
        [Parameter(Mandatory = $true)]
        [string]$ManagerName,
        
        [Parameter(Mandatory = $true)]
        [string]$DifficultyLevel
    )

    $risks = @()
    
    # Risques liÃ©s Ã  la complexitÃ© technique
    if ($DifficultyLevel -eq "Difficile" -or $DifficultyLevel -eq "TrÃ¨s difficile") {
        $risks += [PSCustomObject]@{
            Category = "ComplexitÃ©"
            Description = "ComplexitÃ© technique Ã©levÃ©e pouvant entraÃ®ner des difficultÃ©s d'implÃ©mentation"
            Impact = "Ã‰levÃ©"
            Probability = "Ã‰levÃ©e"
            Mitigation = "DÃ©composer l'amÃ©lioration en tÃ¢ches plus petites et plus gÃ©rables"
        }
    }
    
    # Risques liÃ©s aux dÃ©pendances
    if ($Improvement.Dependencies -and $Improvement.Dependencies.Count -gt 0) {
        $risks += [PSCustomObject]@{
            Category = "DÃ©pendances"
            Description = "DÃ©pendances externes pouvant causer des retards ou des problÃ¨mes d'intÃ©gration"
            Impact = "Moyen"
            Probability = "Moyenne"
            Mitigation = "Identifier et gÃ©rer proactivement les dÃ©pendances, Ã©tablir des contrats d'interface clairs"
        }
    }
    
    # Risques liÃ©s aux technologies
    switch ($Improvement.Type) {
        "Optimisation" {
            $risks += [PSCustomObject]@{
                Category = "Performance"
                Description = "Risque de rÃ©gression de performance dans d'autres parties du systÃ¨me"
                Impact = "Ã‰levÃ©"
                Probability = "Moyenne"
                Mitigation = "Mettre en place des tests de performance complets avant et aprÃ¨s l'implÃ©mentation"
            }
        }
        "IntÃ©gration" {
            $risks += [PSCustomObject]@{
                Category = "IntÃ©gration"
                Description = "ProblÃ¨mes d'intÃ©gration avec des systÃ¨mes externes"
                Impact = "Ã‰levÃ©"
                Probability = "Ã‰levÃ©e"
                Mitigation = "Mettre en place des environnements de test d'intÃ©gration, dÃ©finir des contrats d'API clairs"
            }
        }
        "SÃ©curitÃ©" {
            $risks += [PSCustomObject]@{
                Category = "SÃ©curitÃ©"
                Description = "VulnÃ©rabilitÃ©s de sÃ©curitÃ© potentielles"
                Impact = "TrÃ¨s Ã©levÃ©"
                Probability = "Moyenne"
                Mitigation = "Effectuer des revues de code de sÃ©curitÃ©, des tests de pÃ©nÃ©tration et suivre les bonnes pratiques de sÃ©curitÃ©"
            }
        }
    }
    
    # Risques spÃ©cifiques au gestionnaire
    switch ($ManagerName) {
        "Process Manager" {
            $risks += [PSCustomObject]@{
                Category = "Concurrence"
                Description = "ProblÃ¨mes de concurrence et de synchronisation"
                Impact = "Ã‰levÃ©"
                Probability = "Moyenne"
                Mitigation = "Utiliser des mÃ©canismes de synchronisation appropriÃ©s, effectuer des tests de charge"
            }
        }
        "Mode Manager" {
            $risks += [PSCustomObject]@{
                Category = "Ã‰tat"
                Description = "ProblÃ¨mes de gestion d'Ã©tat et de transition"
                Impact = "Moyen"
                Probability = "Moyenne"
                Mitigation = "Mettre en place des tests de transition d'Ã©tat exhaustifs"
            }
        }
        "Roadmap Manager" {
            $risks += [PSCustomObject]@{
                Category = "CohÃ©rence"
                Description = "ProblÃ¨mes de cohÃ©rence des donnÃ©es"
                Impact = "Moyen"
                Probability = "Moyenne"
                Mitigation = "Mettre en place des mÃ©canismes de validation et de vÃ©rification de cohÃ©rence"
            }
        }
        "Integrated Manager" {
            $risks += [PSCustomObject]@{
                Category = "CompatibilitÃ©"
                Description = "ProblÃ¨mes de compatibilitÃ© avec des systÃ¨mes externes"
                Impact = "Ã‰levÃ©"
                Probability = "Ã‰levÃ©e"
                Mitigation = "Mettre en place des tests de compatibilitÃ©, dÃ©finir des contrats d'API clairs"
            }
        }
        "Script Manager" {
            $risks += [PSCustomObject]@{
                Category = "ExÃ©cution"
                Description = "ProblÃ¨mes d'exÃ©cution de scripts dans diffÃ©rents environnements"
                Impact = "Moyen"
                Probability = "Moyenne"
                Mitigation = "Tester l'exÃ©cution dans tous les environnements cibles"
            }
        }
        "Error Manager" {
            $risks += [PSCustomObject]@{
                Category = "Gestion d'erreurs"
                Description = "ProblÃ¨mes de gestion d'erreurs et de rÃ©cupÃ©ration"
                Impact = "Ã‰levÃ©"
                Probability = "Moyenne"
                Mitigation = "Mettre en place des tests d'erreur exhaustifs, simuler des scÃ©narios de dÃ©faillance"
            }
        }
        "Configuration Manager" {
            $risks += [PSCustomObject]@{
                Category = "Configuration"
                Description = "ProblÃ¨mes de configuration dans diffÃ©rents environnements"
                Impact = "Moyen"
                Probability = "Moyenne"
                Mitigation = "Mettre en place des tests de configuration dans tous les environnements cibles"
            }
        }
        "Logging Manager" {
            $risks += [PSCustomObject]@{
                Category = "Performance"
                Description = "Impact sur les performances dÃ» Ã  une journalisation excessive"
                Impact = "Moyen"
                Probability = "Moyenne"
                Mitigation = "Optimiser la journalisation, mettre en place des niveaux de journalisation configurables"
            }
        }
    }
    
    # Risques liÃ©s Ã  l'effort
    if ($Improvement.Effort -eq "Ã‰levÃ©") {
        $risks += [PSCustomObject]@{
            Category = "Planification"
            Description = "Sous-estimation de l'effort requis"
            Impact = "Moyen"
            Probability = "Ã‰levÃ©e"
            Mitigation = "Ajouter une marge de sÃ©curitÃ© aux estimations, suivre rÃ©guliÃ¨rement l'avancement"
        }
    }
    
    # Risques liÃ©s Ã  la description
    if ($Improvement.Description -match "nouveau|nouvelle|innovant|innovante") {
        $risks += [PSCustomObject]@{
            Category = "Innovation"
            Description = "Risques liÃ©s Ã  l'utilisation de technologies ou d'approches nouvelles"
            Impact = "Moyen"
            Probability = "Moyenne"
            Mitigation = "Effectuer des prototypes, des preuves de concept, et des validations techniques"
        }
    }
    
    # Risques liÃ©s Ã  l'impact
    if ($Improvement.Impact -eq "Ã‰levÃ©") {
        $risks += [PSCustomObject]@{
            Category = "Impact"
            Description = "Impact potentiel sur d'autres parties du systÃ¨me"
            Impact = "Ã‰levÃ©"
            Probability = "Moyenne"
            Mitigation = "Effectuer une analyse d'impact complÃ¨te, mettre en place des tests de rÃ©gression"
        }
    }
    
    return $risks
}

# Fonction pour Ã©valuer la criticitÃ© des risques
function Evaluate-RiskCriticality {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Risk
    )

    $impactScore = switch ($Risk.Impact) {
        "TrÃ¨s Ã©levÃ©" { 5 }
        "Ã‰levÃ©" { 4 }
        "Moyen" { 3 }
        "Faible" { 2 }
        "TrÃ¨s faible" { 1 }
        default { 3 }
    }
    
    $probabilityScore = switch ($Risk.Probability) {
        "TrÃ¨s Ã©levÃ©e" { 5 }
        "Ã‰levÃ©e" { 4 }
        "Moyenne" { 3 }
        "Faible" { 2 }
        "TrÃ¨s faible" { 1 }
        default { 3 }
    }
    
    $criticalityScore = $impactScore * $probabilityScore
    
    $criticalityLevel = switch ($criticalityScore) {
        {$_ -ge 20} { "Critique" }
        {$_ -ge 12 -and $_ -lt 20} { "Ã‰levÃ©e" }
        {$_ -ge 6 -and $_ -lt 12} { "Moyenne" }
        {$_ -lt 6} { "Faible" }
    }
    
    return [PSCustomObject]@{
        Score = $criticalityScore
        Level = $criticalityLevel
    }
}

# Fonction pour gÃ©nÃ©rer le rapport au format Markdown
function Generate-MarkdownReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$RiskResults
    )

    $markdown = "# Identification des Risques Techniques des AmÃ©liorations`n`n"
    $markdown += "Ce document prÃ©sente l'identification des risques techniques associÃ©s aux amÃ©liorations identifiÃ©es pour les diffÃ©rents gestionnaires.`n`n"
    
    $markdown += "## Table des MatiÃ¨res`n`n"
    
    foreach ($manager in $RiskResults.Managers) {
        $markdown += "- [$($manager.Name)](#$($manager.Name.ToLower().Replace(' ', '-')))`n"
    }
    
    $markdown += "`n## MÃ©thodologie`n`n"
    $markdown += "L'identification des risques techniques a Ã©tÃ© rÃ©alisÃ©e en analysant :`n`n"
    $markdown += "1. **ComplexitÃ© technique** : Risques liÃ©s Ã  la complexitÃ© technique de l'amÃ©lioration`n"
    $markdown += "2. **DÃ©pendances** : Risques liÃ©s aux dÃ©pendances vis-Ã -vis d'autres composants ou systÃ¨mes`n"
    $markdown += "3. **Technologies** : Risques liÃ©s aux technologies utilisÃ©es`n"
    $markdown += "4. **SpÃ©cificitÃ©s du gestionnaire** : Risques spÃ©cifiques Ã  chaque gestionnaire`n`n"
    
    $markdown += "### Ã‰valuation de la CriticitÃ© des Risques`n`n"
    $markdown += "La criticitÃ© des risques est Ã©valuÃ©e en fonction de leur impact et de leur probabilitÃ© :`n`n"
    $markdown += "| Impact | ProbabilitÃ© | CriticitÃ© |`n"
    $markdown += "|--------|-------------|-----------|`n"
    $markdown += "| TrÃ¨s Ã©levÃ© (5) | TrÃ¨s Ã©levÃ©e (5) | Critique (25) |`n"
    $markdown += "| Ã‰levÃ© (4) | Ã‰levÃ©e (4) | Ã‰levÃ©e (16) |`n"
    $markdown += "| Moyen (3) | Moyenne (3) | Moyenne (9) |`n"
    $markdown += "| Faible (2) | Faible (2) | Faible (4) |`n"
    $markdown += "| TrÃ¨s faible (1) | TrÃ¨s faible (1) | Faible (1) |`n`n"
    
    $markdown += "La criticitÃ© est calculÃ©e en multipliant le score d'impact par le score de probabilitÃ© :`n`n"
    $markdown += "- **Critique** : Score >= 20`n"
    $markdown += "- **Ã‰levÃ©e** : 12 <= Score < 20`n"
    $markdown += "- **Moyenne** : 6 <= Score < 12`n"
    $markdown += "- **Faible** : Score < 6`n`n"
    
    foreach ($manager in $RiskResults.Managers) {
        $markdown += "## <a name='$($manager.Name.ToLower().Replace(' ', '-'))'></a>$($manager.Name)`n`n"
        
        foreach ($improvement in $manager.Improvements) {
            $markdown += "### $($improvement.Name)`n`n"
            $markdown += "**Description :** $($improvement.Description)`n`n"
            $markdown += "**Type :** $($improvement.Type)`n`n"
            $markdown += "**Effort :** $($improvement.Effort)`n`n"
            $markdown += "**DifficultÃ© d'implÃ©mentation :** $($improvement.DifficultyLevel)`n`n"
            
            if ($improvement.Risks.Count -gt 0) {
                $markdown += "#### Risques IdentifiÃ©s`n`n"
                $markdown += "| CatÃ©gorie | Description | Impact | ProbabilitÃ© | CriticitÃ© | Mitigation |`n"
                $markdown += "|-----------|-------------|--------|-------------|-----------|------------|`n"
                
                foreach ($risk in $improvement.Risks) {
                    $markdown += "| $($risk.Category) | $($risk.Description) | $($risk.Impact) | $($risk.Probability) | $($risk.Criticality.Level) | $($risk.Mitigation) |`n"
                }
            } else {
                $markdown += "#### Risques IdentifiÃ©s`n`n"
                $markdown += "Aucun risque technique significatif identifiÃ© pour cette amÃ©lioration.`n"
            }
            
            $markdown += "`n"
        }
    }
    
    $markdown += "## RÃ©sumÃ©`n`n"
    
    $totalImprovements = 0
    $totalRisks = 0
    $criticalityLevels = @{
        "Critique" = 0
        "Ã‰levÃ©e" = 0
        "Moyenne" = 0
        "Faible" = 0
    }
    
    foreach ($manager in $RiskResults.Managers) {
        $totalImprovements += $manager.Improvements.Count
        
        foreach ($improvement in $manager.Improvements) {
            $totalRisks += $improvement.Risks.Count
            
            foreach ($risk in $improvement.Risks) {
                $criticalityLevels[$risk.Criticality.Level]++
            }
        }
    }
    
    $markdown += "Cette analyse a identifiÃ© $totalRisks risques techniques pour $totalImprovements amÃ©liorations rÃ©parties sur $($RiskResults.Managers.Count) gestionnaires.`n`n"
    
    $markdown += "### RÃ©partition par Niveau de CriticitÃ©`n`n"
    $markdown += "| Niveau | Nombre | Pourcentage |`n"
    $markdown += "|--------|--------|------------|`n"
    
    foreach ($level in @("Critique", "Ã‰levÃ©e", "Moyenne", "Faible")) {
        $percentage = if ($totalRisks -gt 0) { [Math]::Round(($criticalityLevels[$level] / $totalRisks) * 100, 1) } else { 0 }
        $markdown += "| $level | $($criticalityLevels[$level]) | $percentage% |`n"
    }
    
    $markdown += "`n### Recommandations GÃ©nÃ©rales`n`n"
    $markdown += "1. **Prioriser les risques critiques** : Mettre en place des plans de mitigation spÃ©cifiques pour tous les risques de criticitÃ© critique.`n"
    $markdown += "2. **Suivi rÃ©gulier** : Mettre en place un suivi rÃ©gulier des risques identifiÃ©s tout au long du processus d'implÃ©mentation.`n"
    $markdown += "3. **Revues techniques** : Organiser des revues techniques rÃ©guliÃ¨res pour Ã©valuer l'Ã©volution des risques.`n"
    $markdown += "4. **Tests approfondis** : Mettre en place des tests approfondis pour dÃ©tecter et corriger les problÃ¨mes liÃ©s aux risques identifiÃ©s.`n"
    $markdown += "5. **Documentation** : Documenter les risques et les stratÃ©gies de mitigation pour rÃ©fÃ©rence future.`n"
    
    return $markdown
}

# Fonction pour gÃ©nÃ©rer le rapport au format JSON
function Generate-JsonReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$RiskResults
    )

    return $RiskResults | ConvertTo-Json -Depth 10
}

# Identifier les risques techniques des amÃ©liorations
$riskResults = [PSCustomObject]@{
    GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Managers = @()
}

foreach ($manager in $improvementsData.Managers) {
    $managerRisks = [PSCustomObject]@{
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
        
        # Identifier les risques
        $risks = Identify-TechnicalRisks -Improvement $improvement -ManagerName $manager.Name -DifficultyLevel $difficultyLevel
        
        # Ã‰valuer la criticitÃ© des risques
        foreach ($risk in $risks) {
            $risk | Add-Member -MemberType NoteProperty -Name "Criticality" -Value (Evaluate-RiskCriticality -Risk $risk)
        }
        
        $improvementRisks = [PSCustomObject]@{
            Name = $improvement.Name
            Description = $improvement.Description
            Type = $improvement.Type
            Effort = $improvement.Effort
            DifficultyLevel = $difficultyLevel
            Risks = $risks
        }
        
        $managerRisks.Improvements += $improvementRisks
    }
    
    $riskResults.Managers += $managerRisks
}

# GÃ©nÃ©rer le rapport dans le format spÃ©cifiÃ©
switch ($Format) {
    "Markdown" {
        $reportContent = Generate-MarkdownReport -RiskResults $riskResults
    }
    "JSON" {
        $reportContent = Generate-JsonReport -RiskResults $riskResults
    }
}

# Enregistrer le rapport
try {
    $reportContent | Out-File -FilePath $OutputFile -Encoding UTF8
    Write-Host "Rapport des risques techniques gÃ©nÃ©rÃ© avec succÃ¨s : $OutputFile"
} catch {
    Write-Error "Erreur lors de l'enregistrement du rapport : $_"
    exit 1
}

# Afficher un rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ© de l'identification des risques techniques :"
Write-Host "------------------------------------------------"

$totalImprovements = 0
$totalRisks = 0
$criticalityLevels = @{
    "Critique" = 0
    "Ã‰levÃ©e" = 0
    "Moyenne" = 0
    "Faible" = 0
}

foreach ($manager in $riskResults.Managers) {
    $managerImprovements = $manager.Improvements.Count
    $managerRisks = 0
    
    foreach ($improvement in $manager.Improvements) {
        $managerRisks += $improvement.Risks.Count
        
        foreach ($risk in $improvement.Risks) {
            $criticalityLevels[$risk.Criticality.Level]++
        }
    }
    
    $totalImprovements += $managerImprovements
    $totalRisks += $managerRisks
    
    Write-Host "  $($manager.Name) : $managerRisks risques pour $managerImprovements amÃ©liorations"
}

Write-Host "  Total : $totalRisks risques pour $totalImprovements amÃ©liorations"
Write-Host "`nRÃ©partition par niveau de criticitÃ© :"
foreach ($level in @("Critique", "Ã‰levÃ©e", "Moyenne", "Faible")) {
    $percentage = if ($totalRisks -gt 0) { [Math]::Round(($criticalityLevels[$level] / $totalRisks) * 100, 1) } else { 0 }
    Write-Host "  $level : $($criticalityLevels[$level]) ($percentage%)"
}
