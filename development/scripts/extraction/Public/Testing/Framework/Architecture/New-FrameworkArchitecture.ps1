<#
.SYNOPSIS
    Définit l'architecture globale du framework de test de performance.

.DESCRIPTION
    Ce script définit l'architecture globale du framework de test de performance,
    y compris les composants, les interfaces, les flux de données et de contrôle,
    et les principes d'extensibilité.

.NOTES
    Version:        1.0
    Author:         Extraction Module Team
    Creation Date:  2023-05-15
#>

# Définition de l'architecture du framework
$FrameworkArchitecture = @{
    Name = "TestFrameworkArchitecture"
    Description = "Architecture globale du framework de test de performance"
    Version = "1.0"
    
    Overview = @{
        Purpose = "Fournir un framework complet pour tester les performances de chargement des index dans le module d'extraction"
        Goals = @(
            "Mesurer précisément les performances de chargement des index",
            "Comparer différentes configurations d'index",
            "Détecter les régressions de performance",
            "Générer des rapports détaillés des résultats",
            "Fournir une base pour l'optimisation des performances"
        )
        Scope = @{
            Included = @(
                "Génération de données de test",
                "Exécution de tests de performance",
                "Collecte de métriques",
                "Analyse des résultats",
                "Génération de rapports"
            )
            Excluded = @(
                "Tests fonctionnels",
                "Tests de sécurité",
                "Tests d'intégration avec d'autres systèmes",
                "Déploiement automatique"
            )
        }
    }
    
    ArchitecturalStyle = @{
        PrimaryStyle = "Component-Based"
        Description = "Le framework est organisé en composants indépendants avec des interfaces bien définies"
        SecondaryStyles = @(
            @{
                Style = "Plugin-Based"
                Description = "Les fonctionnalités peuvent être étendues via des plugins"
            },
            @{
                Style = "Event-Driven"
                Description = "Les composants communiquent via des événements pour certaines opérations"
            },
            @{
                Style = "Layered"
                Description = "Le framework est organisé en couches logiques"
            }
        )
    }
    
    Components = @{
        Core = @(
            @{
                Name = "TestFrameworkCore"
                Description = "Composant central qui coordonne les autres composants"
                Responsibilities = @(
                    "Initialiser le framework",
                    "Charger la configuration",
                    "Coordonner l'exécution des tests",
                    "Gérer le cycle de vie des composants",
                    "Fournir des services communs"
                )
                Dependencies = @()
            },
            @{
                Name = "PluginManager"
                Description = "Composant responsable de la gestion des plugins"
                Responsibilities = @(
                    "Découvrir les plugins disponibles",
                    "Charger les plugins",
                    "Valider les plugins",
                    "Fournir un accès aux plugins"
                )
                Dependencies = @("TestFrameworkCore")
            },
            @{
                Name = "ConfigurationManager"
                Description = "Composant responsable de la gestion de la configuration"
                Responsibilities = @(
                    "Charger la configuration",
                    "Valider la configuration",
                    "Fournir un accès à la configuration",
                    "Gérer les modifications de configuration"
                )
                Dependencies = @("TestFrameworkCore")
            }
        )
        Functional = @(
            @{
                Name = "TestDataGenerator"
                Description = "Composant responsable de la génération des données de test"
                Responsibilities = @(
                    "Générer des données textuelles aléatoires",
                    "Générer des données structurées aléatoires",
                    "Créer des collections de test",
                    "Exporter les données générées"
                )
                Dependencies = @("TestFrameworkCore", "PluginManager", "ConfigurationManager")
            },
            @{
                Name = "TestExecutor"
                Description = "Composant responsable de l'exécution des tests"
                Responsibilities = @(
                    "Préparer l'environnement de test",
                    "Exécuter les tests",
                    "Collecter les résultats",
                    "Gérer les erreurs d'exécution"
                )
                Dependencies = @("TestFrameworkCore", "TestDataGenerator", "MetricsCollector", "ConfigurationManager")
            },
            @{
                Name = "MetricsCollector"
                Description = "Composant responsable de la collecte des métriques"
                Responsibilities = @(
                    "Collecter les métriques de temps",
                    "Collecter les métriques de mémoire",
                    "Collecter les métriques CPU",
                    "Collecter les métriques d'E/S disque"
                )
                Dependencies = @("TestFrameworkCore", "PluginManager", "ConfigurationManager")
            },
            @{
                Name = "AnalysisReporting"
                Description = "Composant responsable de l'analyse et du reporting"
                Responsibilities = @(
                    "Analyser les résultats de test",
                    "Comparer les résultats",
                    "Détecter les régressions",
                    "Générer des rapports",
                    "Créer des visualisations"
                )
                Dependencies = @("TestFrameworkCore", "PluginManager", "ConfigurationManager")
            }
        )
        Infrastructure = @(
            @{
                Name = "LoggingService"
                Description = "Service de journalisation"
                Responsibilities = @(
                    "Journaliser les événements du framework",
                    "Gérer les niveaux de journalisation",
                    "Fournir différentes cibles de journalisation"
                )
                Dependencies = @("TestFrameworkCore", "ConfigurationManager")
            },
            @{
                Name = "ErrorHandlingService"
                Description = "Service de gestion des erreurs"
                Responsibilities = @(
                    "Capturer les erreurs",
                    "Journaliser les erreurs",
                    "Fournir des informations de diagnostic",
                    "Gérer la récupération après erreur"
                )
                Dependencies = @("TestFrameworkCore", "LoggingService")
            },
            @{
                Name = "StorageService"
                Description = "Service de stockage"
                Responsibilities = @(
                    "Stocker les données de test",
                    "Stocker les résultats de test",
                    "Stocker les rapports",
                    "Gérer la persistance des données"
                )
                Dependencies = @("TestFrameworkCore", "ConfigurationManager")
            }
        )
    }
    
    Layers = @(
        @{
            Name = "Presentation"
            Description = "Couche de présentation"
            Components = @("ReportGenerators", "VisualizationProviders")
            Responsibilities = @(
                "Présenter les résultats aux utilisateurs",
                "Générer des rapports",
                "Créer des visualisations"
            )
        },
        @{
            Name = "Business"
            Description = "Couche métier"
            Components = @("TestExecutor", "AnalysisModules")
            Responsibilities = @(
                "Exécuter la logique métier",
                "Analyser les résultats",
                "Appliquer les règles métier"
            )
        },
        @{
            Name = "Data"
            Description = "Couche de données"
            Components = @("TestDataGenerator", "MetricsCollector", "StorageService")
            Responsibilities = @(
                "Gérer les données",
                "Collecter les métriques",
                "Stocker les résultats"
            )
        },
        @{
            Name = "Infrastructure"
            Description = "Couche d'infrastructure"
            Components = @("TestFrameworkCore", "PluginManager", "ConfigurationManager", "LoggingService", "ErrorHandlingService")
            Responsibilities = @(
                "Fournir des services communs",
                "Gérer les ressources",
                "Coordonner les composants"
            )
        }
    )
    
    CrossCuttingConcerns = @(
        @{
            Name = "Logging"
            Description = "Journalisation des événements et des erreurs"
            Implementation = "LoggingService"
            Scope = "All components"
        },
        @{
            Name = "ErrorHandling"
            Description = "Gestion des erreurs et des exceptions"
            Implementation = "ErrorHandlingService"
            Scope = "All components"
        },
        @{
            Name = "Configuration"
            Description = "Gestion de la configuration"
            Implementation = "ConfigurationManager"
            Scope = "All components"
        },
        @{
            Name = "Extensibility"
            Description = "Mécanismes d'extensibilité"
            Implementation = "PluginManager"
            Scope = "All components"
        },
        @{
            Name = "Performance"
            Description = "Optimisation des performances"
            Implementation = "Various techniques"
            Scope = "All components"
        }
    )
    
    QualityAttributes = @(
        @{
            Name = "Performance"
            Description = "Le framework doit avoir un impact minimal sur les performances mesurées"
            Scenarios = @(
                "Le framework doit ajouter moins de 5% d'overhead aux opérations mesurées",
                "La collecte des métriques doit être optimisée pour minimiser l'impact"
            )
        },
        @{
            Name = "Extensibility"
            Description = "Le framework doit être facilement extensible"
            Scenarios = @(
                "De nouveaux générateurs de données doivent pouvoir être ajoutés sans modifier le code existant",
                "De nouvelles métriques doivent pouvoir être collectées sans modifier le code existant",
                "De nouveaux formats de rapport doivent pouvoir être ajoutés sans modifier le code existant"
            )
        },
        @{
            Name = "Reliability"
            Description = "Le framework doit être fiable et robuste"
            Scenarios = @(
                "Le framework doit récupérer gracieusement des erreurs pendant les tests",
                "Les résultats de test doivent être sauvegardés régulièrement pour éviter les pertes de données",
                "Le framework doit gérer correctement les cas limites et les entrées invalides"
            )
        },
        @{
            Name = "Usability"
            Description = "Le framework doit être facile à utiliser"
            Scenarios = @(
                "La configuration du framework doit être simple et intuitive",
                "Les rapports générés doivent être clairs et informatifs",
                "Le framework doit fournir des messages d'erreur clairs et utiles"
            )
        },
        @{
            Name = "Maintainability"
            Description = "Le framework doit être facile à maintenir"
            Scenarios = @(
                "Le code doit être bien documenté",
                "Les composants doivent être faiblement couplés",
                "Les interfaces doivent être bien définies",
                "Les tests unitaires doivent couvrir les fonctionnalités principales"
            )
        }
    )
    
    TechnicalDecisions = @(
        @{
            Decision = "Utilisation de PowerShell comme langage principal"
            Rationale = "PowerShell est bien adapté pour l'automatisation et l'intégration avec Windows, et est déjà utilisé dans le projet."
            Alternatives = @("Python", "C#")
            Consequences = @{
                Positive = @(
                    "Intégration facile avec l'environnement Windows",
                    "Pas besoin de compilation",
                    "Syntaxe familière pour l'équipe"
                )
                Negative = @(
                    "Performances potentiellement inférieures à C#",
                    "Moins de bibliothèques disponibles qu'en Python"
                )
            }
        },
        @{
            Decision = "Architecture de plugins pour l'extensibilité"
            Rationale = "Permet d'étendre le framework sans modifier le code existant."
            Alternatives = @("Architecture monolithique", "Architecture basée sur l'héritage")
            Consequences = @{
                Positive = @(
                    "Facilité d'extension",
                    "Faible couplage entre les composants",
                    "Possibilité de désactiver des fonctionnalités non utilisées"
                )
                Negative = @(
                    "Complexité accrue",
                    "Overhead potentiel dû à la découverte et au chargement des plugins"
                )
            }
        },
        @{
            Decision = "Stockage des résultats au format JSON"
            Rationale = "Format flexible et facile à utiliser en PowerShell."
            Alternatives = @("XML", "Base de données")
            Consequences = @{
                Positive = @(
                    "Facilité de manipulation en PowerShell",
                    "Format lisible par l'homme",
                    "Pas besoin d'infrastructure de base de données"
                )
                Negative = @(
                    "Performances potentiellement inférieures pour de grands volumes de données",
                    "Moins de fonctionnalités de requête qu'une base de données"
                )
            }
        },
        @{
            Decision = "Utilisation de classes PowerShell pour les composants"
            Rationale = "Les classes PowerShell offrent une meilleure encapsulation et un meilleur support de l'orienté objet."
            Alternatives = @("Modules PowerShell traditionnels", "Scripts PowerShell")
            Consequences = @{
                Positive = @(
                    "Meilleure encapsulation",
                    "Support de l'héritage et des interfaces",
                    "Code plus structuré"
                )
                Negative = @(
                    "Nécessite PowerShell 5.0 ou supérieur",
                    "Moins familier pour certains développeurs PowerShell"
                )
            }
        }
    )
    
    Risks = @(
        @{
            Risk = "Impact sur les performances mesurées"
            Description = "Le framework pourrait affecter les performances qu'il tente de mesurer."
            Mitigation = "Optimiser le code du framework, minimiser l'overhead, isoler les composants de mesure."
            Probability = "Medium"
            Impact = "High"
        },
        @{
            Risk = "Complexité excessive"
            Description = "L'architecture pourrait devenir trop complexe et difficile à maintenir."
            Mitigation = "Suivre les principes SOLID, documenter clairement, créer des tests unitaires."
            Probability = "Medium"
            Impact = "Medium"
        },
        @{
            Risk = "Dépendances externes"
            Description = "Le framework pourrait dépendre de bibliothèques ou d'outils externes qui pourraient changer ou devenir indisponibles."
            Mitigation = "Minimiser les dépendances externes, créer des abstractions pour les dépendances, documenter les versions requises."
            Probability = "Low"
            Impact = "Medium"
        },
        @{
            Risk = "Incompatibilité avec certains environnements"
            Description = "Le framework pourrait ne pas fonctionner correctement dans certains environnements."
            Mitigation = "Tester dans différents environnements, documenter les prérequis, créer des vérifications de compatibilité."
            Probability = "Low"
            Impact = "Medium"
        }
    )
}

# Fonction pour exporter la définition de l'architecture au format JSON
function Export-FrameworkArchitectureDefinition {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = ".\FrameworkArchitecture.json"
    )
    
    try {
        $FrameworkArchitecture | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Output "La définition de l'architecture a été exportée vers $OutputPath"
    }
    catch {
        Write-Error "Erreur lors de l'exportation de la définition de l'architecture: $_"
    }
}

# Fonction pour générer un diagramme de l'architecture au format PlantUML
function New-ArchitectureDiagram {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = ".\ArchitectureDiagram.puml"
    )
    
    $plantUml = @"
@startuml FrameworkArchitecture

package "Test Framework" {
    package "Core" {
        [TestFrameworkCore] as TFC
        [PluginManager] as PM
        [ConfigurationManager] as CM
    }
    
    package "Functional Components" {
        [TestDataGenerator] as TDG
        [TestExecutor] as TE
        [MetricsCollector] as MC
        [AnalysisReporting] as AR
    }
    
    package "Infrastructure" {
        [LoggingService] as LS
        [ErrorHandlingService] as EHS
        [StorageService] as SS
    }
    
    package "Plugins" {
        [DataGeneratorPlugins] as DGP
        [MetricsProviderPlugins] as MPP
        [AnalysisModulePlugins] as AMP
        [ReportGeneratorPlugins] as RGP
        [VisualizationPlugins] as VP
    }
}

' Core dependencies
TFC --> PM : uses
TFC --> CM : uses
TFC --> LS : uses
TFC --> EHS : uses

' Functional component dependencies
TDG --> TFC : uses
TDG --> PM : uses
TDG --> CM : uses

TE --> TFC : uses
TE --> TDG : uses
TE --> MC : uses
TE --> CM : uses

MC --> TFC : uses
MC --> PM : uses
MC --> CM : uses

AR --> TFC : uses
AR --> PM : uses
AR --> CM : uses

' Infrastructure dependencies
LS --> CM : uses
EHS --> LS : uses
SS --> CM : uses

' Plugin dependencies
PM --> DGP : manages
PM --> MPP : manages
PM --> AMP : manages
PM --> RGP : manages
PM --> VP : manages

TDG --> DGP : uses
MC --> MPP : uses
AR --> AMP : uses
AR --> RGP : uses
AR --> VP : uses

@enduml
"@
    
    try {
        $plantUml | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Output "Le diagramme de l'architecture a été généré à $OutputPath"
    }
    catch {
        Write-Error "Erreur lors de la génération du diagramme de l'architecture: $_"
    }
}

# Fonction pour générer un diagramme des couches au format PlantUML
function New-LayersDiagram {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = ".\LayersDiagram.puml"
    )
    
    $plantUml = @"
@startuml FrameworkLayers

skinparam component {
    BackgroundColor<<Presentation>> LightBlue
    BackgroundColor<<Business>> LightGreen
    BackgroundColor<<Data>> LightYellow
    BackgroundColor<<Infrastructure>> LightGray
}

package "Presentation Layer" {
    [ReportGenerators]<<Presentation>>
    [VisualizationProviders]<<Presentation>>
}

package "Business Layer" {
    [TestExecutor]<<Business>>
    [AnalysisModules]<<Business>>
}

package "Data Layer" {
    [TestDataGenerator]<<Data>>
    [MetricsCollector]<<Data>>
    [StorageService]<<Data>>
}

package "Infrastructure Layer" {
    [TestFrameworkCore]<<Infrastructure>>
    [PluginManager]<<Infrastructure>>
    [ConfigurationManager]<<Infrastructure>>
    [LoggingService]<<Infrastructure>>
    [ErrorHandlingService]<<Infrastructure>>
}

[ReportGenerators] --> [AnalysisModules]
[VisualizationProviders] --> [AnalysisModules]

[TestExecutor] --> [TestDataGenerator]
[TestExecutor] --> [MetricsCollector]
[AnalysisModules] --> [MetricsCollector]
[AnalysisModules] --> [StorageService]

[TestDataGenerator] --> [TestFrameworkCore]
[MetricsCollector] --> [TestFrameworkCore]
[StorageService] --> [ConfigurationManager]

[TestFrameworkCore] --> [PluginManager]
[TestFrameworkCore] --> [ConfigurationManager]
[TestFrameworkCore] --> [LoggingService]
[TestFrameworkCore] --> [ErrorHandlingService]

@enduml
"@
    
    try {
        $plantUml | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Output "Le diagramme des couches a été généré à $OutputPath"
    }
    catch {
        Write-Error "Erreur lors de la génération du diagramme des couches: $_"
    }
}

# Fonction pour générer un document d'architecture
function New-ArchitectureDocument {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = ".\FrameworkArchitecture.md"
    )
    
    $document = @"
# Architecture du Framework de Test de Performance

## Vue d'ensemble

**Nom :** $($FrameworkArchitecture.Name)
**Version :** $($FrameworkArchitecture.Version)
**Description :** $($FrameworkArchitecture.Description)

### Objectif

$($FrameworkArchitecture.Overview.Purpose)

### Objectifs

"@
    
    foreach ($goal in $FrameworkArchitecture.Overview.Goals) {
        $document += @"

- $goal
"@
    }
    
    $document += @"

### Portée

**Inclus :**

"@
    
    foreach ($item in $FrameworkArchitecture.Overview.Scope.Included) {
        $document += @"

- $item
"@
    }
    
    $document += @"

**Exclus :**

"@
    
    foreach ($item in $FrameworkArchitecture.Overview.Scope.Excluded) {
        $document += @"

- $item
"@
    }
    
    $document += @"

## Style architectural

**Style principal :** $($FrameworkArchitecture.ArchitecturalStyle.PrimaryStyle)

$($FrameworkArchitecture.ArchitecturalStyle.Description)

**Styles secondaires :**

"@
    
    foreach ($style in $FrameworkArchitecture.ArchitecturalStyle.SecondaryStyles) {
        $document += @"

- **$($style.Style) :** $($style.Description)
"@
    }
    
    $document += @"

## Composants

### Composants principaux

"@
    
    foreach ($component in $FrameworkArchitecture.Components.Core) {
        $document += @"

#### $($component.Name)

$($component.Description)

**Responsabilités :**

"@
        
        foreach ($responsibility in $component.Responsibilities) {
            $document += @"

- $responsibility
"@
        }
        
        if ($component.Dependencies.Count -gt 0) {
            $document += @"

**Dépendances :** $($component.Dependencies -join ", ")
"@
        }
        else {
            $document += @"

**Dépendances :** Aucune
"@
        }
    }
    
    $document += @"

### Composants fonctionnels

"@
    
    foreach ($component in $FrameworkArchitecture.Components.Functional) {
        $document += @"

#### $($component.Name)

$($component.Description)

**Responsabilités :**

"@
        
        foreach ($responsibility in $component.Responsibilities) {
            $document += @"

- $responsibility
"@
        }
        
        $document += @"

**Dépendances :** $($component.Dependencies -join ", ")
"@
    }
    
    $document += @"

### Composants d'infrastructure

"@
    
    foreach ($component in $FrameworkArchitecture.Components.Infrastructure) {
        $document += @"

#### $($component.Name)

$($component.Description)

**Responsabilités :**

"@
        
        foreach ($responsibility in $component.Responsibilities) {
            $document += @"

- $responsibility
"@
        }
        
        $document += @"

**Dépendances :** $($component.Dependencies -join ", ")
"@
    }
    
    $document += @"

## Couches

"@
    
    foreach ($layer in $FrameworkArchitecture.Layers) {
        $document += @"

### $($layer.Name)

$($layer.Description)

**Composants :** $($layer.Components -join ", ")

**Responsabilités :**

"@
        
        foreach ($responsibility in $layer.Responsibilities) {
            $document += @"

- $responsibility
"@
        }
    }
    
    $document += @"

## Préoccupations transversales

"@
    
    foreach ($concern in $FrameworkArchitecture.CrossCuttingConcerns) {
        $document += @"

### $($concern.Name)

$($concern.Description)

**Implémentation :** $($concern.Implementation)
**Portée :** $($concern.Scope)
"@
    }
    
    $document += @"

## Attributs de qualité

"@
    
    foreach ($attribute in $FrameworkArchitecture.QualityAttributes) {
        $document += @"

### $($attribute.Name)

$($attribute.Description)

**Scénarios :**

"@
        
        foreach ($scenario in $attribute.Scenarios) {
            $document += @"

- $scenario
"@
        }
    }
    
    $document += @"

## Décisions techniques

"@
    
    foreach ($decision in $FrameworkArchitecture.TechnicalDecisions) {
        $document += @"

### $($decision.Decision)

**Justification :** $($decision.Rationale)

**Alternatives considérées :** $($decision.Alternatives -join ", ")

**Conséquences positives :**

"@
        
        foreach ($consequence in $decision.Consequences.Positive) {
            $document += @"

- $consequence
"@
        }
        
        $document += @"

**Conséquences négatives :**

"@
        
        foreach ($consequence in $decision.Consequences.Negative) {
            $document += @"

- $consequence
"@
        }
    }
    
    $document += @"

## Risques

"@
    
    foreach ($risk in $FrameworkArchitecture.Risks) {
        $document += @"

### $($risk.Risk)

**Description :** $($risk.Description)

**Mitigation :** $($risk.Mitigation)

**Probabilité :** $($risk.Probability)
**Impact :** $($risk.Impact)
"@
    }
    
    try {
        $document | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Output "Le document d'architecture a été généré à $OutputPath"
    }
    catch {
        Write-Error "Erreur lors de la génération du document d'architecture: $_"
    }
}

# Fonction pour valider la définition de l'architecture
function Test-FrameworkArchitectureDefinition {
    [CmdletBinding()]
    param()
    
    $issues = @()
    
    # Vérifier que les sections requises existent
    $requiredSections = @('Name', 'Description', 'Version', 'Overview', 'ArchitecturalStyle', 'Components', 'Layers', 'CrossCuttingConcerns', 'QualityAttributes')
    foreach ($section in $requiredSections) {
        if (-not $FrameworkArchitecture.ContainsKey($section)) {
            $issues += "Section manquante: $section"
        }
    }
    
    # Vérifier que chaque composant a une description et des responsabilités
    foreach ($category in @('Core', 'Functional', 'Infrastructure')) {
        foreach ($component in $FrameworkArchitecture.Components.$category) {
            if (-not $component.ContainsKey('Description')) {
                $issues += "Description manquante pour le composant: $($component.Name)"
            }
            if (-not $component.ContainsKey('Responsibilities') -or $component.Responsibilities.Count -eq 0) {
                $issues += "Responsabilités manquantes pour le composant: $($component.Name)"
            }
        }
    }
    
    # Vérifier que chaque couche a une description et des composants
    foreach ($layer in $FrameworkArchitecture.Layers) {
        if (-not $layer.ContainsKey('Description')) {
            $issues += "Description manquante pour la couche: $($layer.Name)"
        }
        if (-not $layer.ContainsKey('Components') -or $layer.Components.Count -eq 0) {
            $issues += "Composants manquants pour la couche: $($layer.Name)"
        }
    }
    
    # Afficher les résultats
    if ($issues.Count -eq 0) {
        Write-Output "Validation réussie: La définition de l'architecture est complète et cohérente."
        return $true
    }
    else {
        Write-Warning "Validation échouée: $($issues.Count) problèmes détectés."
        foreach ($issue in $issues) {
            Write-Warning "- $issue"
        }
        return $false
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Export-FrameworkArchitectureDefinition, New-ArchitectureDiagram, New-LayersDiagram, New-ArchitectureDocument, Test-FrameworkArchitectureDefinition
