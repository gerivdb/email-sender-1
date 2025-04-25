# Documentation du module RoadmapParserCore

## Vue d'ensemble

RoadmapParserCore est un module PowerShell conçu pour analyser, manipuler et gérer des roadmaps au format markdown. Il fournit un ensemble complet de fonctions pour travailler avec des fichiers de roadmap, extraire des informations sur les tâches, construire des arborescences de tâches, et générer des rapports.

## Architecture du module

Le module RoadmapParserCore est organisé selon une architecture modulaire qui facilite la maintenance et l'extension. Voici les principaux composants :

### Structure des fichiers

- **RoadmapParserCore.psd1** : Manifeste du module qui définit les métadonnées, les dépendances et les fonctions exportées.
- **RoadmapParserCore.psm1** : Fichier principal du module qui implémente le chargement dynamique des fonctions.
- **Functions/** : Répertoire contenant toutes les fonctions du module, organisées en sous-répertoires.
  - **Common/** : Fonctions communes utilisées par plusieurs composants du module.
  - **Private/** : Fonctions internes non exportées.
  - **Public/** : Fonctions publiques exportées par le module.
- **Exceptions/** : Classes d'exceptions personnalisées.
- **Config/** : Fichiers de configuration.
- **Resources/** : Ressources utilisées par le module.
- **docs/** : Documentation du module.

### Mécanisme de chargement dynamique

Le module utilise un mécanisme de chargement dynamique qui permet de :

1. Charger automatiquement les fonctions depuis les sous-répertoires
2. Gérer les dépendances entre fonctions
3. Optimiser les performances en ne chargeant que les fonctions nécessaires
4. Faciliter l'ajout de nouvelles fonctionnalités

## Fonctionnalités principales

### Parsing du markdown

Le module peut analyser des fichiers markdown contenant des roadmaps et les convertir en objets PowerShell manipulables. Les fonctions principales sont :

- `ConvertFrom-MarkdownToRoadmap` : Convertit un fichier markdown en objet roadmap.
- `Parse-MarkdownTask` : Analyse une ligne de tâche markdown.
- `Extract-MarkdownTaskStatus` : Extrait le statut d'une tâche.
- `Extract-MarkdownTaskId` : Extrait l'identifiant d'une tâche.
- `Extract-MarkdownTaskTitle` : Extrait le titre d'une tâche.

### Manipulation de l'arbre des tâches

Le module permet de construire et manipuler des arborescences de tâches :

- `New-RoadmapTree` : Crée un nouvel arbre de roadmap.
- `New-RoadmapTask` : Crée une nouvelle tâche.
- `Add-RoadmapTask` : Ajoute une tâche à l'arbre.
- `Remove-RoadmapTask` : Supprime une tâche de l'arbre.
- `Get-RoadmapTask` : Obtient une tâche spécifique.
- `Set-RoadmapTaskStatus` : Modifie le statut d'une tâche.

### Gestion des dépendances

Le module peut détecter et gérer les dépendances entre tâches :

- `Add-RoadmapTaskDependency` : Ajoute une dépendance entre deux tâches.
- `Remove-RoadmapTaskDependency` : Supprime une dépendance entre deux tâches.
- `Get-RoadmapTaskDependencies` : Obtient les dépendances d'une tâche.
- `Get-RoadmapTaskDependents` : Obtient les tâches qui dépendent d'une tâche spécifique.
- `Find-DependencyCycle` : Détecte les cycles de dépendances.

### Export et import

Le module permet d'exporter et d'importer des roadmaps dans différents formats :

- `Export-RoadmapToJson` : Exporte une roadmap au format JSON.
- `Import-RoadmapFromJson` : Importe une roadmap depuis un fichier JSON.
- `Export-RoadmapTreeToMarkdown` : Exporte un arbre de roadmap au format markdown.

### Génération de rapports

Le module peut générer des rapports et des statistiques sur les roadmaps :

- `Generate-RoadmapReport` : Génère un rapport sur la roadmap.
- `Generate-RoadmapStatistics` : Génère des statistiques sur la roadmap.
- `Generate-RoadmapVisualization` : Génère une visualisation de la roadmap.

### Journalisation

Le module dispose d'un système de journalisation avancé :

- `Set-RoadmapLogLevel` : Définit le niveau de journalisation.
- `Get-RoadmapLogConfiguration` : Obtient la configuration de journalisation actuelle.
- `Set-RoadmapLogDestination` : Définit la destination des journaux.
- `Set-RoadmapLogFormat` : Définit le format des messages de journal.
- `Write-RoadmapDebug` : Écrit un message de débogage.
- `Write-RoadmapVerbose` : Écrit un message verbeux.
- `Write-RoadmapInformation` : Écrit un message d'information.
- `Write-RoadmapWarning` : Écrit un message d'avertissement.
- `Write-RoadmapError` : Écrit un message d'erreur.
- `Write-RoadmapCritical` : Écrit un message critique.

### Modes opérationnels

Le module implémente plusieurs modes opérationnels spécialisés :

- `Invoke-RoadmapArchitecture` : Mode ARCHI pour la génération de diagrammes d'architecture.
- `Invoke-RoadmapDebug` : Mode DEBUG pour le débogage de scripts.
- `Invoke-RoadmapTest` : Mode TEST pour l'exécution de tests.
- `Invoke-RoadmapCheck` : Mode CHECK pour la vérification de l'état des tâches.
- `Invoke-RoadmapGranularization` : Mode GRAN pour la granularisation des tâches.

## Utilisation avancée

### Configuration personnalisée

Le module permet de personnaliser son comportement via des fichiers de configuration :

```powershell
# Charger une configuration personnalisée
$config = Get-Configuration -ConfigFile "chemin/vers/config.json"

# Fusionner avec la configuration par défaut
$mergedConfig = Merge-Configuration -DefaultConfig (Get-DefaultConfiguration) -CustomConfig $config

# Utiliser la configuration fusionnée
ConvertFrom-MarkdownToRoadmap -FilePath "roadmap.md" -Configuration $mergedConfig
```

### Journalisation avancée

Le système de journalisation peut être configuré pour différents besoins :

```powershell
# Définir le niveau de journalisation
Set-RoadmapLogLevel -Level "DEBUG"

# Définir la destination des journaux
Set-RoadmapLogDestination -Destination "File" -FilePath "logs/roadmap.log"

# Définir le format des messages
Set-RoadmapLogFormat -Format "[{0}] {1} - {2}" # Niveau, Timestamp, Message
```

### Utilisation des modes opérationnels

Les modes opérationnels peuvent être utilisés pour des tâches spécifiques :

```powershell
# Mode ARCHI - Générer des diagrammes d'architecture
Invoke-RoadmapArchitecture -FilePath "roadmap.md" -ProjectPath "project" -OutputPath "output" -DiagramType "C4"

# Mode DEBUG - Déboguer un script avec simulation de contexte
Invoke-RoadmapDebug -FilePath "roadmap.md" -ProjectPath "project" -ScriptPath "script.ps1" -OutputPath "output" -SimulateContext $true -ContextFile "context.json"

# Mode TEST - Exécuter des tests avec couverture de code
Invoke-RoadmapTest -FilePath "roadmap.md" -ModulePath "module" -TestsPath "tests" -OutputPath "output" -CoverageThreshold 80 -IncludeCodeCoverage $true
```

## Extension du module

### Ajout de nouvelles fonctions

Pour ajouter une nouvelle fonction au module :

1. Créez un fichier PS1 dans le répertoire approprié (Public, Private ou Common)
2. Implémentez la fonction avec la documentation appropriée
3. Si nécessaire, mettez à jour le manifeste du module pour exporter la fonction

Exemple de nouvelle fonction :

```powershell
<#
.SYNOPSIS
    Exemple de nouvelle fonction.

.DESCRIPTION
    Cette fonction est un exemple de nouvelle fonction à ajouter au module.

.PARAMETER InputObject
    Objet d'entrée à traiter.

.EXAMPLE
    New-ExampleFunction -InputObject "test"
#>
function New-ExampleFunction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$InputObject
    )
    
    # Implémentation de la fonction
    return $InputObject
}

# Exporter la fonction
Export-ModuleMember -Function New-ExampleFunction
```

### Création d'un nouveau mode opérationnel

Pour créer un nouveau mode opérationnel :

1. Créez un fichier PS1 dans le répertoire Public avec le préfixe "Invoke-Roadmap"
2. Implémentez la fonction principale du mode
3. Créez un script de mode dans le répertoire racine du projet
4. Mettez à jour le manifeste du module pour exporter la fonction

## Dépannage

### Problèmes courants

- **Erreur de chargement du module** : Vérifiez que tous les fichiers sont présents et que les chemins sont corrects.
- **Fonction non trouvée** : Vérifiez que la fonction est exportée dans le manifeste du module.
- **Erreur de parsing** : Vérifiez que le fichier markdown est correctement formaté.

### Journalisation pour le dépannage

Activez la journalisation détaillée pour diagnostiquer les problèmes :

```powershell
# Activer la journalisation de débogage
Set-RoadmapLogLevel -Level "DEBUG"

# Exécuter l'opération problématique
ConvertFrom-MarkdownToRoadmap -FilePath "roadmap.md"
```

## Références

- [Documentation PowerShell](https://docs.microsoft.com/en-us/powershell/)
- [Markdown Specification](https://spec.commonmark.org/)
- [PowerShell Module Development](https://docs.microsoft.com/en-us/powershell/scripting/developer/module/writing-a-windows-powershell-module)

## Annexes

### Liste complète des fonctions exportées

Consultez le manifeste du module (RoadmapParserCore.psd1) pour la liste complète des fonctions exportées.

### Exemples de fichiers de configuration

Consultez le répertoire Config pour des exemples de fichiers de configuration.

### Exemples de roadmaps

Consultez le répertoire Resources pour des exemples de fichiers de roadmap.
