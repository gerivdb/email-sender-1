<#
.SYNOPSIS
    Analyse les aspects techniques des améliorations.

.DESCRIPTION
    Ce script analyse les aspects techniques des améliorations en identifiant
    les composants techniques, les technologies impliquées, les interfaces
    et les dépendances techniques.

.PARAMETER InputFile
    Chemin vers le fichier JSON contenant les améliorations à analyser.

.PARAMETER OutputFile
    Chemin vers le fichier de sortie pour le rapport d'analyse technique.

.PARAMETER Format
    Format du rapport de sortie. Les valeurs possibles sont : JSON, Markdown.
    Par défaut : Markdown

.EXAMPLE
    .\analyze-technical-aspects.ps1 -InputFile "data\improvements.json" -OutputFile "data\planning\technical-analysis.md"
    Génère un rapport d'analyse technique au format Markdown.

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
    [string]$OutputFile,

    [Parameter(Mandatory = $false)]
    [ValidateSet("JSON", "Markdown")]
    [string]$Format = "Markdown"
)

# Vérifier que le fichier d'entrée existe
if (-not (Test-Path -Path $InputFile)) {
    Write-Error "Le fichier d'entrée n'existe pas : $InputFile"
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

# Fonction pour analyser les composants techniques
function Analyze-TechnicalComponents {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Improvement
    )

    $components = @()

    # Analyser la description pour identifier les composants techniques
    $description = $Improvement.Description
    
    # Liste des mots-clés pour les composants techniques
    $componentKeywords = @(
        "API", "Interface", "Base de données", "Serveur", "Client", "Frontend", "Backend",
        "Microservice", "Service", "Module", "Composant", "Bibliothèque", "Framework",
        "Classe", "Objet", "Fonction", "Méthode", "Procédure", "Algorithme", "Structure de données",
        "Cache", "File d'attente", "Message", "Événement", "Notification", "Authentification",
        "Autorisation", "Validation", "Transformation", "Traitement", "Stockage", "Récupération",
        "Indexation", "Recherche", "Tri", "Filtrage", "Pagination", "Agrégation", "Rapport"
    )
    
    # Rechercher les mots-clés dans la description
    foreach ($keyword in $componentKeywords) {
        if ($description -match $keyword) {
            $components += $keyword
        }
    }
    
    # Ajouter des composants spécifiques en fonction du type d'amélioration
    switch ($Improvement.Type) {
        "Fonctionnalité" {
            $components += "Implémentation de fonctionnalité"
        }
        "Amélioration" {
            $components += "Amélioration de composant existant"
        }
        "Optimisation" {
            $components += "Optimisation de performance"
        }
        "Intégration" {
            $components += "Intégration de systèmes"
        }
        "Sécurité" {
            $components += "Mécanisme de sécurité"
        }
    }
    
    # Supprimer les doublons
    $components = $components | Select-Object -Unique
    
    return $components
}

# Fonction pour analyser les technologies impliquées
function Analyze-Technologies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Improvement,
        
        [Parameter(Mandatory = $true)]
        [string]$ManagerName
    )

    $technologies = @()
    
    # Liste des technologies par gestionnaire
    $managerTechnologies = @{
        "Process Manager" = @("PowerShell", "Runspace Pools", "Threads", "Processus", "Synchronisation")
        "Mode Manager" = @("PowerShell", "Configuration", "État", "Transition")
        "Roadmap Manager" = @("Markdown", "Parser", "Graphe", "Dépendances")
        "Integrated Manager" = @("API", "REST", "JSON", "Intégration", "Connecteurs")
        "Script Manager" = @("PowerShell", "Scripts", "Modules", "Exécution")
        "Error Manager" = @("Exceptions", "Journalisation", "Diagnostic", "Récupération")
        "Configuration Manager" = @("JSON", "YAML", "Environnements", "Variables")
        "Logging Manager" = @("Journalisation", "Rotation", "Niveaux de log", "Formatage")
    }
    
    # Ajouter les technologies spécifiques au gestionnaire
    if ($managerTechnologies.ContainsKey($ManagerName)) {
        $technologies += $managerTechnologies[$ManagerName]
    }
    
    # Ajouter des technologies spécifiques en fonction du type d'amélioration
    switch ($Improvement.Type) {
        "Fonctionnalité" {
            $technologies += "Développement"
        }
        "Amélioration" {
            $technologies += "Refactoring"
        }
        "Optimisation" {
            $technologies += "Profilage", "Optimisation"
        }
        "Intégration" {
            $technologies += "API", "Connecteurs"
        }
        "Sécurité" {
            $technologies += "Cryptographie", "Authentification", "Autorisation"
        }
    }
    
    # Supprimer les doublons
    $technologies = $technologies | Select-Object -Unique
    
    return $technologies
}

# Fonction pour analyser les interfaces
function Analyze-Interfaces {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Improvement,
        
        [Parameter(Mandatory = $true)]
        [string]$ManagerName
    )

    $interfaces = @()
    
    # Liste des interfaces par gestionnaire
    $managerInterfaces = @{
        "Process Manager" = @("Interface de gestion des processus", "Interface de surveillance")
        "Mode Manager" = @("Interface de configuration des modes", "Interface de transition")
        "Roadmap Manager" = @("Interface de gestion des tâches", "Interface de visualisation")
        "Integrated Manager" = @("Interface d'intégration", "API externe")
        "Script Manager" = @("Interface d'exécution de scripts", "Interface de gestion des scripts")
        "Error Manager" = @("Interface de gestion des erreurs", "Interface de diagnostic")
        "Configuration Manager" = @("Interface de configuration", "Interface d'environnement")
        "Logging Manager" = @("Interface de journalisation", "Interface de consultation des logs")
    }
    
    # Ajouter les interfaces spécifiques au gestionnaire
    if ($managerInterfaces.ContainsKey($ManagerName)) {
        $interfaces += $managerInterfaces[$ManagerName]
    }
    
    # Ajouter des interfaces spécifiques en fonction du type d'amélioration
    if ($Improvement.Description -match "interface utilisateur|UI|GUI|interface graphique") {
        $interfaces += "Interface utilisateur"
    }
    
    if ($Improvement.Description -match "API|interface de programmation|REST|SOAP|GraphQL") {
        $interfaces += "API"
    }
    
    if ($Improvement.Description -match "base de données|BD|SQL|NoSQL|stockage") {
        $interfaces += "Interface de base de données"
    }
    
    if ($Improvement.Description -match "fichier|système de fichiers|I/O|entrée/sortie") {
        $interfaces += "Interface de fichier"
    }
    
    if ($Improvement.Description -match "réseau|communication|socket|HTTP|TCP|UDP") {
        $interfaces += "Interface réseau"
    }
    
    # Supprimer les doublons
    $interfaces = $interfaces | Select-Object -Unique
    
    return $interfaces
}

# Fonction pour analyser les dépendances techniques
function Analyze-Dependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Improvement
    )

    $dependencies = @()
    
    # Ajouter les dépendances explicites
    if ($Improvement.Dependencies -and $Improvement.Dependencies.Count -gt 0) {
        $dependencies += $Improvement.Dependencies
    }
    
    # Identifier les dépendances implicites
    $description = $Improvement.Description
    
    if ($description -match "dépend|nécessite|requiert|utilise|basé sur") {
        $dependencies += "Dépendances implicites identifiées dans la description"
    }
    
    # Ajouter des dépendances spécifiques en fonction du type d'amélioration
    switch ($Improvement.Type) {
        "Intégration" {
            $dependencies += "Systèmes externes"
        }
        "Amélioration" {
            $dependencies += "Composant existant"
        }
        "Optimisation" {
            $dependencies += "Composant à optimiser"
        }
    }
    
    # Supprimer les doublons
    $dependencies = $dependencies | Select-Object -Unique
    
    return $dependencies
}

# Fonction pour générer le rapport au format Markdown
function Generate-MarkdownReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$AnalysisResults
    )

    $markdown = "# Analyse des Aspects Techniques des Améliorations`n`n"
    $markdown += "Ce document présente l'analyse des aspects techniques des améliorations identifiées pour les différents gestionnaires.`n`n"
    
    $markdown += "## Table des Matières`n`n"
    
    foreach ($manager in $AnalysisResults.Managers) {
        $markdown += "- [$($manager.Name)](#$($manager.Name.ToLower().Replace(' ', '-')))`n"
    }
    
    $markdown += "`n## Méthodologie`n`n"
    $markdown += "L'analyse des aspects techniques a été réalisée en identifiant :`n`n"
    $markdown += "1. **Composants techniques** : Les composants logiciels impliqués dans l'amélioration`n"
    $markdown += "2. **Technologies impliquées** : Les technologies et outils nécessaires pour l'implémentation`n"
    $markdown += "3. **Interfaces** : Les interfaces avec d'autres systèmes ou composants`n"
    $markdown += "4. **Dépendances techniques** : Les dépendances vis-à-vis d'autres composants ou systèmes`n`n"
    
    foreach ($manager in $AnalysisResults.Managers) {
        $markdown += "## <a name='$($manager.Name.ToLower().Replace(' ', '-'))'></a>$($manager.Name)`n`n"
        
        foreach ($improvement in $manager.Improvements) {
            $markdown += "### $($improvement.Name)`n`n"
            $markdown += "**Description :** $($improvement.Description)`n`n"
            $markdown += "**Type :** $($improvement.Type)`n`n"
            
            $markdown += "#### Composants Techniques`n`n"
            if ($improvement.TechnicalComponents.Count -gt 0) {
                foreach ($component in $improvement.TechnicalComponents) {
                    $markdown += "- $component`n"
                }
            } else {
                $markdown += "Aucun composant technique spécifique identifié.`n"
            }
            
            $markdown += "`n#### Technologies Impliquées`n`n"
            if ($improvement.Technologies.Count -gt 0) {
                foreach ($technology in $improvement.Technologies) {
                    $markdown += "- $technology`n"
                }
            } else {
                $markdown += "Aucune technologie spécifique identifiée.`n"
            }
            
            $markdown += "`n#### Interfaces`n`n"
            if ($improvement.Interfaces.Count -gt 0) {
                foreach ($interface in $improvement.Interfaces) {
                    $markdown += "- $interface`n"
                }
            } else {
                $markdown += "Aucune interface spécifique identifiée.`n"
            }
            
            $markdown += "`n#### Dépendances Techniques`n`n"
            if ($improvement.Dependencies.Count -gt 0) {
                foreach ($dependency in $improvement.Dependencies) {
                    $markdown += "- $dependency`n"
                }
            } else {
                $markdown += "Aucune dépendance technique spécifique identifiée.`n"
            }
            
            $markdown += "`n"
        }
    }
    
    $markdown += "## Résumé`n`n"
    
    $totalImprovements = 0
    foreach ($manager in $AnalysisResults.Managers) {
        $totalImprovements += $manager.Improvements.Count
    }
    
    $markdown += "Cette analyse a couvert $totalImprovements améliorations réparties sur $($AnalysisResults.Managers.Count) gestionnaires.`n`n"
    
    $markdown += "### Répartition par Type`n`n"
    $markdown += "| Type | Nombre |`n"
    $markdown += "|------|--------|`n"
    
    $typeCount = @{}
    foreach ($manager in $AnalysisResults.Managers) {
        foreach ($improvement in $manager.Improvements) {
            if (-not $typeCount.ContainsKey($improvement.Type)) {
                $typeCount[$improvement.Type] = 0
            }
            $typeCount[$improvement.Type]++
        }
    }
    
    foreach ($type in $typeCount.Keys | Sort-Object) {
        $markdown += "| $type | $($typeCount[$type]) |`n"
    }
    
    return $markdown
}

# Fonction pour générer le rapport au format JSON
function Generate-JsonReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$AnalysisResults
    )

    return $AnalysisResults | ConvertTo-Json -Depth 10
}

# Analyser les aspects techniques des améliorations
$analysisResults = [PSCustomObject]@{
    GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Managers = @()
}

foreach ($manager in $improvementsData.Managers) {
    $managerAnalysis = [PSCustomObject]@{
        Name = $manager.Name
        Category = $manager.Category
        Improvements = @()
    }
    
    foreach ($improvement in $manager.Improvements) {
        $technicalComponents = Analyze-TechnicalComponents -Improvement $improvement
        $technologies = Analyze-Technologies -Improvement $improvement -ManagerName $manager.Name
        $interfaces = Analyze-Interfaces -Improvement $improvement -ManagerName $manager.Name
        $dependencies = Analyze-Dependencies -Improvement $improvement
        
        $improvementAnalysis = [PSCustomObject]@{
            Name = $improvement.Name
            Description = $improvement.Description
            Type = $improvement.Type
            TechnicalComponents = $technicalComponents
            Technologies = $technologies
            Interfaces = $interfaces
            Dependencies = $dependencies
        }
        
        $managerAnalysis.Improvements += $improvementAnalysis
    }
    
    $analysisResults.Managers += $managerAnalysis
}

# Générer le rapport dans le format spécifié
switch ($Format) {
    "Markdown" {
        $reportContent = Generate-MarkdownReport -AnalysisResults $analysisResults
    }
    "JSON" {
        $reportContent = Generate-JsonReport -AnalysisResults $analysisResults
    }
}

# Enregistrer le rapport
try {
    $reportContent | Out-File -FilePath $OutputFile -Encoding UTF8
    Write-Host "Rapport d'analyse technique généré avec succès : $OutputFile"
} catch {
    Write-Error "Erreur lors de l'enregistrement du rapport : $_"
    exit 1
}

# Afficher un résumé
Write-Host "`nRésumé de l'analyse technique :"
Write-Host "--------------------------------"

$totalImprovements = 0
foreach ($manager in $analysisResults.Managers) {
    $managerImprovements = $manager.Improvements.Count
    $totalImprovements += $managerImprovements
    Write-Host "  $($manager.Name) : $managerImprovements améliorations"
}

Write-Host "  Total : $totalImprovements améliorations"
