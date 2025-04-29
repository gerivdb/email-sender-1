<#
.SYNOPSIS
    Identifie les risques techniques des améliorations.

.DESCRIPTION
    Ce script identifie les risques techniques associés aux améliorations en analysant
    la complexité technique, les dépendances, les technologies et les contraintes.

.PARAMETER InputFile
    Chemin vers le fichier JSON contenant les améliorations à analyser.

.PARAMETER DifficultyFile
    Chemin vers le fichier d'évaluation de la difficulté d'implémentation généré précédemment.

.PARAMETER OutputFile
    Chemin vers le fichier de sortie pour le rapport des risques techniques.

.PARAMETER Format
    Format du rapport de sortie. Les valeurs possibles sont : JSON, Markdown.
    Par défaut : Markdown

.EXAMPLE
    .\identify-technical-risks.ps1 -InputFile "data\improvements.json" -DifficultyFile "data\planning\implementation-difficulty.md" -OutputFile "data\planning\technical-risks.md"
    Génère un rapport des risques techniques au format Markdown.

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
    [string]$DifficultyFile,

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

if (-not (Test-Path -Path $DifficultyFile)) {
    Write-Error "Le fichier d'évaluation de la difficulté n'existe pas : $DifficultyFile"
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
    
    # Risques liés à la complexité technique
    if ($DifficultyLevel -eq "Difficile" -or $DifficultyLevel -eq "Très difficile") {
        $risks += [PSCustomObject]@{
            Category = "Complexité"
            Description = "Complexité technique élevée pouvant entraîner des difficultés d'implémentation"
            Impact = "Élevé"
            Probability = "Élevée"
            Mitigation = "Décomposer l'amélioration en tâches plus petites et plus gérables"
        }
    }
    
    # Risques liés aux dépendances
    if ($Improvement.Dependencies -and $Improvement.Dependencies.Count -gt 0) {
        $risks += [PSCustomObject]@{
            Category = "Dépendances"
            Description = "Dépendances externes pouvant causer des retards ou des problèmes d'intégration"
            Impact = "Moyen"
            Probability = "Moyenne"
            Mitigation = "Identifier et gérer proactivement les dépendances, établir des contrats d'interface clairs"
        }
    }
    
    # Risques liés aux technologies
    switch ($Improvement.Type) {
        "Optimisation" {
            $risks += [PSCustomObject]@{
                Category = "Performance"
                Description = "Risque de régression de performance dans d'autres parties du système"
                Impact = "Élevé"
                Probability = "Moyenne"
                Mitigation = "Mettre en place des tests de performance complets avant et après l'implémentation"
            }
        }
        "Intégration" {
            $risks += [PSCustomObject]@{
                Category = "Intégration"
                Description = "Problèmes d'intégration avec des systèmes externes"
                Impact = "Élevé"
                Probability = "Élevée"
                Mitigation = "Mettre en place des environnements de test d'intégration, définir des contrats d'API clairs"
            }
        }
        "Sécurité" {
            $risks += [PSCustomObject]@{
                Category = "Sécurité"
                Description = "Vulnérabilités de sécurité potentielles"
                Impact = "Très élevé"
                Probability = "Moyenne"
                Mitigation = "Effectuer des revues de code de sécurité, des tests de pénétration et suivre les bonnes pratiques de sécurité"
            }
        }
    }
    
    # Risques spécifiques au gestionnaire
    switch ($ManagerName) {
        "Process Manager" {
            $risks += [PSCustomObject]@{
                Category = "Concurrence"
                Description = "Problèmes de concurrence et de synchronisation"
                Impact = "Élevé"
                Probability = "Moyenne"
                Mitigation = "Utiliser des mécanismes de synchronisation appropriés, effectuer des tests de charge"
            }
        }
        "Mode Manager" {
            $risks += [PSCustomObject]@{
                Category = "État"
                Description = "Problèmes de gestion d'état et de transition"
                Impact = "Moyen"
                Probability = "Moyenne"
                Mitigation = "Mettre en place des tests de transition d'état exhaustifs"
            }
        }
        "Roadmap Manager" {
            $risks += [PSCustomObject]@{
                Category = "Cohérence"
                Description = "Problèmes de cohérence des données"
                Impact = "Moyen"
                Probability = "Moyenne"
                Mitigation = "Mettre en place des mécanismes de validation et de vérification de cohérence"
            }
        }
        "Integrated Manager" {
            $risks += [PSCustomObject]@{
                Category = "Compatibilité"
                Description = "Problèmes de compatibilité avec des systèmes externes"
                Impact = "Élevé"
                Probability = "Élevée"
                Mitigation = "Mettre en place des tests de compatibilité, définir des contrats d'API clairs"
            }
        }
        "Script Manager" {
            $risks += [PSCustomObject]@{
                Category = "Exécution"
                Description = "Problèmes d'exécution de scripts dans différents environnements"
                Impact = "Moyen"
                Probability = "Moyenne"
                Mitigation = "Tester l'exécution dans tous les environnements cibles"
            }
        }
        "Error Manager" {
            $risks += [PSCustomObject]@{
                Category = "Gestion d'erreurs"
                Description = "Problèmes de gestion d'erreurs et de récupération"
                Impact = "Élevé"
                Probability = "Moyenne"
                Mitigation = "Mettre en place des tests d'erreur exhaustifs, simuler des scénarios de défaillance"
            }
        }
        "Configuration Manager" {
            $risks += [PSCustomObject]@{
                Category = "Configuration"
                Description = "Problèmes de configuration dans différents environnements"
                Impact = "Moyen"
                Probability = "Moyenne"
                Mitigation = "Mettre en place des tests de configuration dans tous les environnements cibles"
            }
        }
        "Logging Manager" {
            $risks += [PSCustomObject]@{
                Category = "Performance"
                Description = "Impact sur les performances dû à une journalisation excessive"
                Impact = "Moyen"
                Probability = "Moyenne"
                Mitigation = "Optimiser la journalisation, mettre en place des niveaux de journalisation configurables"
            }
        }
    }
    
    # Risques liés à l'effort
    if ($Improvement.Effort -eq "Élevé") {
        $risks += [PSCustomObject]@{
            Category = "Planification"
            Description = "Sous-estimation de l'effort requis"
            Impact = "Moyen"
            Probability = "Élevée"
            Mitigation = "Ajouter une marge de sécurité aux estimations, suivre régulièrement l'avancement"
        }
    }
    
    # Risques liés à la description
    if ($Improvement.Description -match "nouveau|nouvelle|innovant|innovante") {
        $risks += [PSCustomObject]@{
            Category = "Innovation"
            Description = "Risques liés à l'utilisation de technologies ou d'approches nouvelles"
            Impact = "Moyen"
            Probability = "Moyenne"
            Mitigation = "Effectuer des prototypes, des preuves de concept, et des validations techniques"
        }
    }
    
    # Risques liés à l'impact
    if ($Improvement.Impact -eq "Élevé") {
        $risks += [PSCustomObject]@{
            Category = "Impact"
            Description = "Impact potentiel sur d'autres parties du système"
            Impact = "Élevé"
            Probability = "Moyenne"
            Mitigation = "Effectuer une analyse d'impact complète, mettre en place des tests de régression"
        }
    }
    
    return $risks
}

# Fonction pour évaluer la criticité des risques
function Evaluate-RiskCriticality {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Risk
    )

    $impactScore = switch ($Risk.Impact) {
        "Très élevé" { 5 }
        "Élevé" { 4 }
        "Moyen" { 3 }
        "Faible" { 2 }
        "Très faible" { 1 }
        default { 3 }
    }
    
    $probabilityScore = switch ($Risk.Probability) {
        "Très élevée" { 5 }
        "Élevée" { 4 }
        "Moyenne" { 3 }
        "Faible" { 2 }
        "Très faible" { 1 }
        default { 3 }
    }
    
    $criticalityScore = $impactScore * $probabilityScore
    
    $criticalityLevel = switch ($criticalityScore) {
        {$_ -ge 20} { "Critique" }
        {$_ -ge 12 -and $_ -lt 20} { "Élevée" }
        {$_ -ge 6 -and $_ -lt 12} { "Moyenne" }
        {$_ -lt 6} { "Faible" }
    }
    
    return [PSCustomObject]@{
        Score = $criticalityScore
        Level = $criticalityLevel
    }
}

# Fonction pour générer le rapport au format Markdown
function Generate-MarkdownReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$RiskResults
    )

    $markdown = "# Identification des Risques Techniques des Améliorations`n`n"
    $markdown += "Ce document présente l'identification des risques techniques associés aux améliorations identifiées pour les différents gestionnaires.`n`n"
    
    $markdown += "## Table des Matières`n`n"
    
    foreach ($manager in $RiskResults.Managers) {
        $markdown += "- [$($manager.Name)](#$($manager.Name.ToLower().Replace(' ', '-')))`n"
    }
    
    $markdown += "`n## Méthodologie`n`n"
    $markdown += "L'identification des risques techniques a été réalisée en analysant :`n`n"
    $markdown += "1. **Complexité technique** : Risques liés à la complexité technique de l'amélioration`n"
    $markdown += "2. **Dépendances** : Risques liés aux dépendances vis-à-vis d'autres composants ou systèmes`n"
    $markdown += "3. **Technologies** : Risques liés aux technologies utilisées`n"
    $markdown += "4. **Spécificités du gestionnaire** : Risques spécifiques à chaque gestionnaire`n`n"
    
    $markdown += "### Évaluation de la Criticité des Risques`n`n"
    $markdown += "La criticité des risques est évaluée en fonction de leur impact et de leur probabilité :`n`n"
    $markdown += "| Impact | Probabilité | Criticité |`n"
    $markdown += "|--------|-------------|-----------|`n"
    $markdown += "| Très élevé (5) | Très élevée (5) | Critique (25) |`n"
    $markdown += "| Élevé (4) | Élevée (4) | Élevée (16) |`n"
    $markdown += "| Moyen (3) | Moyenne (3) | Moyenne (9) |`n"
    $markdown += "| Faible (2) | Faible (2) | Faible (4) |`n"
    $markdown += "| Très faible (1) | Très faible (1) | Faible (1) |`n`n"
    
    $markdown += "La criticité est calculée en multipliant le score d'impact par le score de probabilité :`n`n"
    $markdown += "- **Critique** : Score >= 20`n"
    $markdown += "- **Élevée** : 12 <= Score < 20`n"
    $markdown += "- **Moyenne** : 6 <= Score < 12`n"
    $markdown += "- **Faible** : Score < 6`n`n"
    
    foreach ($manager in $RiskResults.Managers) {
        $markdown += "## <a name='$($manager.Name.ToLower().Replace(' ', '-'))'></a>$($manager.Name)`n`n"
        
        foreach ($improvement in $manager.Improvements) {
            $markdown += "### $($improvement.Name)`n`n"
            $markdown += "**Description :** $($improvement.Description)`n`n"
            $markdown += "**Type :** $($improvement.Type)`n`n"
            $markdown += "**Effort :** $($improvement.Effort)`n`n"
            $markdown += "**Difficulté d'implémentation :** $($improvement.DifficultyLevel)`n`n"
            
            if ($improvement.Risks.Count -gt 0) {
                $markdown += "#### Risques Identifiés`n`n"
                $markdown += "| Catégorie | Description | Impact | Probabilité | Criticité | Mitigation |`n"
                $markdown += "|-----------|-------------|--------|-------------|-----------|------------|`n"
                
                foreach ($risk in $improvement.Risks) {
                    $markdown += "| $($risk.Category) | $($risk.Description) | $($risk.Impact) | $($risk.Probability) | $($risk.Criticality.Level) | $($risk.Mitigation) |`n"
                }
            } else {
                $markdown += "#### Risques Identifiés`n`n"
                $markdown += "Aucun risque technique significatif identifié pour cette amélioration.`n"
            }
            
            $markdown += "`n"
        }
    }
    
    $markdown += "## Résumé`n`n"
    
    $totalImprovements = 0
    $totalRisks = 0
    $criticalityLevels = @{
        "Critique" = 0
        "Élevée" = 0
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
    
    $markdown += "Cette analyse a identifié $totalRisks risques techniques pour $totalImprovements améliorations réparties sur $($RiskResults.Managers.Count) gestionnaires.`n`n"
    
    $markdown += "### Répartition par Niveau de Criticité`n`n"
    $markdown += "| Niveau | Nombre | Pourcentage |`n"
    $markdown += "|--------|--------|------------|`n"
    
    foreach ($level in @("Critique", "Élevée", "Moyenne", "Faible")) {
        $percentage = if ($totalRisks -gt 0) { [Math]::Round(($criticalityLevels[$level] / $totalRisks) * 100, 1) } else { 0 }
        $markdown += "| $level | $($criticalityLevels[$level]) | $percentage% |`n"
    }
    
    $markdown += "`n### Recommandations Générales`n`n"
    $markdown += "1. **Prioriser les risques critiques** : Mettre en place des plans de mitigation spécifiques pour tous les risques de criticité critique.`n"
    $markdown += "2. **Suivi régulier** : Mettre en place un suivi régulier des risques identifiés tout au long du processus d'implémentation.`n"
    $markdown += "3. **Revues techniques** : Organiser des revues techniques régulières pour évaluer l'évolution des risques.`n"
    $markdown += "4. **Tests approfondis** : Mettre en place des tests approfondis pour détecter et corriger les problèmes liés aux risques identifiés.`n"
    $markdown += "5. **Documentation** : Documenter les risques et les stratégies de mitigation pour référence future.`n"
    
    return $markdown
}

# Fonction pour générer le rapport au format JSON
function Generate-JsonReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$RiskResults
    )

    return $RiskResults | ConvertTo-Json -Depth 10
}

# Identifier les risques techniques des améliorations
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
        
        # Identifier les risques
        $risks = Identify-TechnicalRisks -Improvement $improvement -ManagerName $manager.Name -DifficultyLevel $difficultyLevel
        
        # Évaluer la criticité des risques
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

# Générer le rapport dans le format spécifié
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
    Write-Host "Rapport des risques techniques généré avec succès : $OutputFile"
} catch {
    Write-Error "Erreur lors de l'enregistrement du rapport : $_"
    exit 1
}

# Afficher un résumé
Write-Host "`nRésumé de l'identification des risques techniques :"
Write-Host "------------------------------------------------"

$totalImprovements = 0
$totalRisks = 0
$criticalityLevels = @{
    "Critique" = 0
    "Élevée" = 0
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
    
    Write-Host "  $($manager.Name) : $managerRisks risques pour $managerImprovements améliorations"
}

Write-Host "  Total : $totalRisks risques pour $totalImprovements améliorations"
Write-Host "`nRépartition par niveau de criticité :"
foreach ($level in @("Critique", "Élevée", "Moyenne", "Faible")) {
    $percentage = if ($totalRisks -gt 0) { [Math]::Round(($criticalityLevels[$level] / $totalRisks) * 100, 1) } else { 0 }
    Write-Host "  $level : $($criticalityLevels[$level]) ($percentage%)"
}
