<#
.SYNOPSIS
    Analyse les aspects techniques des amÃ©liorations.

.DESCRIPTION
    Ce script analyse les aspects techniques des amÃ©liorations en identifiant
    les composants techniques, les technologies impliquÃ©es, les interfaces
    et les dÃ©pendances techniques.

.PARAMETER InputFile
    Chemin vers le fichier JSON contenant les amÃ©liorations Ã  analyser.

.PARAMETER OutputFile
    Chemin vers le fichier de sortie pour le rapport d'analyse technique.

.PARAMETER Format
    Format du rapport de sortie. Les valeurs possibles sont : JSON, Markdown.
    Par dÃ©faut : Markdown

.EXAMPLE
    .\analyze-technical-aspects.ps1 -InputFile "data\improvements.json" -OutputFile "data\planning\technical-analysis.md"
    GÃ©nÃ¨re un rapport d'analyse technique au format Markdown.

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
    [string]$OutputFile,

    [Parameter(Mandatory = $false)]
    [ValidateSet("JSON", "Markdown")]
    [string]$Format = "Markdown"
)

# VÃ©rifier que le fichier d'entrÃ©e existe
if (-not (Test-Path -Path $InputFile)) {
    Write-Error "Le fichier d'entrÃ©e n'existe pas : $InputFile"
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
    
    # Liste des mots-clÃ©s pour les composants techniques
    $componentKeywords = @(
        "API", "Interface", "Base de donnÃ©es", "Serveur", "Client", "Frontend", "Backend",
        "Microservice", "Service", "Module", "Composant", "BibliothÃ¨que", "Framework",
        "Classe", "Objet", "Fonction", "MÃ©thode", "ProcÃ©dure", "Algorithme", "Structure de donnÃ©es",
        "Cache", "File d'attente", "Message", "Ã‰vÃ©nement", "Notification", "Authentification",
        "Autorisation", "Validation", "Transformation", "Traitement", "Stockage", "RÃ©cupÃ©ration",
        "Indexation", "Recherche", "Tri", "Filtrage", "Pagination", "AgrÃ©gation", "Rapport"
    )
    
    # Rechercher les mots-clÃ©s dans la description
    foreach ($keyword in $componentKeywords) {
        if ($description -match $keyword) {
            $components += $keyword
        }
    }
    
    # Ajouter des composants spÃ©cifiques en fonction du type d'amÃ©lioration
    switch ($Improvement.Type) {
        "FonctionnalitÃ©" {
            $components += "ImplÃ©mentation de fonctionnalitÃ©"
        }
        "AmÃ©lioration" {
            $components += "AmÃ©lioration de composant existant"
        }
        "Optimisation" {
            $components += "Optimisation de performance"
        }
        "IntÃ©gration" {
            $components += "IntÃ©gration de systÃ¨mes"
        }
        "SÃ©curitÃ©" {
            $components += "MÃ©canisme de sÃ©curitÃ©"
        }
    }
    
    # Supprimer les doublons
    $components = $components | Select-Object -Unique
    
    return $components
}

# Fonction pour analyser les technologies impliquÃ©es
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
        "Mode Manager" = @("PowerShell", "Configuration", "Ã‰tat", "Transition")
        "Roadmap Manager" = @("Markdown", "Parser", "Graphe", "DÃ©pendances")
        "Integrated Manager" = @("API", "REST", "JSON", "IntÃ©gration", "Connecteurs")
        "Script Manager" = @("PowerShell", "Scripts", "Modules", "ExÃ©cution")
        "Error Manager" = @("Exceptions", "Journalisation", "Diagnostic", "RÃ©cupÃ©ration")
        "Configuration Manager" = @("JSON", "YAML", "Environnements", "Variables")
        "Logging Manager" = @("Journalisation", "Rotation", "Niveaux de log", "Formatage")
    }
    
    # Ajouter les technologies spÃ©cifiques au gestionnaire
    if ($managerTechnologies.ContainsKey($ManagerName)) {
        $technologies += $managerTechnologies[$ManagerName]
    }
    
    # Ajouter des technologies spÃ©cifiques en fonction du type d'amÃ©lioration
    switch ($Improvement.Type) {
        "FonctionnalitÃ©" {
            $technologies += "DÃ©veloppement"
        }
        "AmÃ©lioration" {
            $technologies += "Refactoring"
        }
        "Optimisation" {
            $technologies += "Profilage", "Optimisation"
        }
        "IntÃ©gration" {
            $technologies += "API", "Connecteurs"
        }
        "SÃ©curitÃ©" {
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
        "Roadmap Manager" = @("Interface de gestion des tÃ¢ches", "Interface de visualisation")
        "Integrated Manager" = @("Interface d'intÃ©gration", "API externe")
        "Script Manager" = @("Interface d'exÃ©cution de scripts", "Interface de gestion des scripts")
        "Error Manager" = @("Interface de gestion des erreurs", "Interface de diagnostic")
        "Configuration Manager" = @("Interface de configuration", "Interface d'environnement")
        "Logging Manager" = @("Interface de journalisation", "Interface de consultation des logs")
    }
    
    # Ajouter les interfaces spÃ©cifiques au gestionnaire
    if ($managerInterfaces.ContainsKey($ManagerName)) {
        $interfaces += $managerInterfaces[$ManagerName]
    }
    
    # Ajouter des interfaces spÃ©cifiques en fonction du type d'amÃ©lioration
    if ($Improvement.Description -match "interface utilisateur|UI|GUI|interface graphique") {
        $interfaces += "Interface utilisateur"
    }
    
    if ($Improvement.Description -match "API|interface de programmation|REST|SOAP|GraphQL") {
        $interfaces += "API"
    }
    
    if ($Improvement.Description -match "base de donnÃ©es|BD|SQL|NoSQL|stockage") {
        $interfaces += "Interface de base de donnÃ©es"
    }
    
    if ($Improvement.Description -match "fichier|systÃ¨me de fichiers|I/O|entrÃ©e/sortie") {
        $interfaces += "Interface de fichier"
    }
    
    if ($Improvement.Description -match "rÃ©seau|communication|socket|HTTP|TCP|UDP") {
        $interfaces += "Interface rÃ©seau"
    }
    
    # Supprimer les doublons
    $interfaces = $interfaces | Select-Object -Unique
    
    return $interfaces
}

# Fonction pour analyser les dÃ©pendances techniques
function Analyze-Dependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Improvement
    )

    $dependencies = @()
    
    # Ajouter les dÃ©pendances explicites
    if ($Improvement.Dependencies -and $Improvement.Dependencies.Count -gt 0) {
        $dependencies += $Improvement.Dependencies
    }
    
    # Identifier les dÃ©pendances implicites
    $description = $Improvement.Description
    
    if ($description -match "dÃ©pend|nÃ©cessite|requiert|utilise|basÃ© sur") {
        $dependencies += "DÃ©pendances implicites identifiÃ©es dans la description"
    }
    
    # Ajouter des dÃ©pendances spÃ©cifiques en fonction du type d'amÃ©lioration
    switch ($Improvement.Type) {
        "IntÃ©gration" {
            $dependencies += "SystÃ¨mes externes"
        }
        "AmÃ©lioration" {
            $dependencies += "Composant existant"
        }
        "Optimisation" {
            $dependencies += "Composant Ã  optimiser"
        }
    }
    
    # Supprimer les doublons
    $dependencies = $dependencies | Select-Object -Unique
    
    return $dependencies
}

# Fonction pour gÃ©nÃ©rer le rapport au format Markdown
function Generate-MarkdownReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$AnalysisResults
    )

    $markdown = "# Analyse des Aspects Techniques des AmÃ©liorations`n`n"
    $markdown += "Ce document prÃ©sente l'analyse des aspects techniques des amÃ©liorations identifiÃ©es pour les diffÃ©rents gestionnaires.`n`n"
    
    $markdown += "## Table des MatiÃ¨res`n`n"
    
    foreach ($manager in $AnalysisResults.Managers) {
        $markdown += "- [$($manager.Name)](#$($manager.Name.ToLower().Replace(' ', '-')))`n"
    }
    
    $markdown += "`n## MÃ©thodologie`n`n"
    $markdown += "L'analyse des aspects techniques a Ã©tÃ© rÃ©alisÃ©e en identifiant :`n`n"
    $markdown += "1. **Composants techniques** : Les composants logiciels impliquÃ©s dans l'amÃ©lioration`n"
    $markdown += "2. **Technologies impliquÃ©es** : Les technologies et outils nÃ©cessaires pour l'implÃ©mentation`n"
    $markdown += "3. **Interfaces** : Les interfaces avec d'autres systÃ¨mes ou composants`n"
    $markdown += "4. **DÃ©pendances techniques** : Les dÃ©pendances vis-Ã -vis d'autres composants ou systÃ¨mes`n`n"
    
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
                $markdown += "Aucun composant technique spÃ©cifique identifiÃ©.`n"
            }
            
            $markdown += "`n#### Technologies ImpliquÃ©es`n`n"
            if ($improvement.Technologies.Count -gt 0) {
                foreach ($technology in $improvement.Technologies) {
                    $markdown += "- $technology`n"
                }
            } else {
                $markdown += "Aucune technologie spÃ©cifique identifiÃ©e.`n"
            }
            
            $markdown += "`n#### Interfaces`n`n"
            if ($improvement.Interfaces.Count -gt 0) {
                foreach ($interface in $improvement.Interfaces) {
                    $markdown += "- $interface`n"
                }
            } else {
                $markdown += "Aucune interface spÃ©cifique identifiÃ©e.`n"
            }
            
            $markdown += "`n#### DÃ©pendances Techniques`n`n"
            if ($improvement.Dependencies.Count -gt 0) {
                foreach ($dependency in $improvement.Dependencies) {
                    $markdown += "- $dependency`n"
                }
            } else {
                $markdown += "Aucune dÃ©pendance technique spÃ©cifique identifiÃ©e.`n"
            }
            
            $markdown += "`n"
        }
    }
    
    $markdown += "## RÃ©sumÃ©`n`n"
    
    $totalImprovements = 0
    foreach ($manager in $AnalysisResults.Managers) {
        $totalImprovements += $manager.Improvements.Count
    }
    
    $markdown += "Cette analyse a couvert $totalImprovements amÃ©liorations rÃ©parties sur $($AnalysisResults.Managers.Count) gestionnaires.`n`n"
    
    $markdown += "### RÃ©partition par Type`n`n"
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

# Fonction pour gÃ©nÃ©rer le rapport au format JSON
function Generate-JsonReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$AnalysisResults
    )

    return $AnalysisResults | ConvertTo-Json -Depth 10
}

# Analyser les aspects techniques des amÃ©liorations
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

# GÃ©nÃ©rer le rapport dans le format spÃ©cifiÃ©
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
    Write-Host "Rapport d'analyse technique gÃ©nÃ©rÃ© avec succÃ¨s : $OutputFile"
} catch {
    Write-Error "Erreur lors de l'enregistrement du rapport : $_"
    exit 1
}

# Afficher un rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ© de l'analyse technique :"
Write-Host "--------------------------------"

$totalImprovements = 0
foreach ($manager in $analysisResults.Managers) {
    $managerImprovements = $manager.Improvements.Count
    $totalImprovements += $managerImprovements
    Write-Host "  $($manager.Name) : $managerImprovements amÃ©liorations"
}

Write-Host "  Total : $totalImprovements amÃ©liorations"
