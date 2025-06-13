# Documentation du module RoadmapParserCore

## Vue d'ensemble

RoadmapParserCore est un module PowerShell conÃ§u pour analyser, manipuler et gÃ©rer des roadmaps au format markdown. Il fournit un ensemble complet de fonctions pour travailler avec des fichiers de roadmap, extraire des informations sur les tÃ¢ches, construire des arborescences de tÃ¢ches, et gÃ©nÃ©rer des rapports.

## Architecture du module

Le module RoadmapParserCore est organisÃ© selon une architecture modulaire qui facilite la maintenance et l'extension. Voici les principaux composants :

### Structure des fichiers

- **RoadmapParserCore.psd1** : Manifeste du module qui dÃ©finit les mÃ©tadonnÃ©es, les dÃ©pendances et les fonctions exportÃ©es.
- **RoadmapParserCore.psm1** : Fichier principal du module qui implÃ©mente le chargement dynamique des fonctions.
- **Functions/** : RÃ©pertoire contenant toutes les fonctions du module, organisÃ©es en sous-rÃ©pertoires.
  - **Common/** : Fonctions communes utilisÃ©es par plusieurs composants du module.
  - **Private/** : Fonctions internes non exportÃ©es.
  - **Public/** : Fonctions publiques exportÃ©es par le module.
- **Exceptions/** : Classes d'exceptions personnalisÃ©es.
- **projet/config/** : Fichiers de configuration.
- **Resources/** : Ressources utilisÃ©es par le module.
- **docs/** : Documentation du module.

### MÃ©canisme de chargement dynamique

Le module utilise un mÃ©canisme de chargement dynamique qui permet de :

1. Charger automatiquement les fonctions depuis les sous-rÃ©pertoires
2. GÃ©rer les dÃ©pendances entre fonctions
3. Optimiser les performances en ne chargeant que les fonctions nÃ©cessaires
4. Faciliter l'ajout de nouvelles fonctionnalitÃ©s

## FonctionnalitÃ©s principales

### Parsing du markdown

Le module peut analyser des fichiers markdown contenant des roadmaps et les convertir en objets PowerShell manipulables. Les fonctions principales sont :

- `ConvertFrom-MarkdownToRoadmap` : Convertit un fichier markdown en objet roadmap.
- `Parse-MarkdownTask` : Analyse une ligne de tÃ¢che markdown.
- `Extract-MarkdownTaskStatus` : Extrait le statut d'une tÃ¢che.
- `Extract-MarkdownTaskId` : Extrait l'identifiant d'une tÃ¢che.
- `Extract-MarkdownTaskTitle` : Extrait le titre d'une tÃ¢che.

### Manipulation de l'arbre des tÃ¢ches

Le module permet de construire et manipuler des arborescences de tÃ¢ches :

- `New-RoadmapTree` : CrÃ©e un nouvel arbre de roadmap.
- `New-RoadmapTask` : CrÃ©e une nouvelle tÃ¢che.
- `Add-RoadmapTask` : Ajoute une tÃ¢che Ã  l'arbre.
- `Remove-RoadmapTask` : Supprime une tÃ¢che de l'arbre.
- `Get-RoadmapTask` : Obtient une tÃ¢che spÃ©cifique.
- `Set-RoadmapTaskStatus` : Modifie le statut d'une tÃ¢che.

### Gestion des dÃ©pendances

Le module peut dÃ©tecter et gÃ©rer les dÃ©pendances entre tÃ¢ches :

- `Add-RoadmapTaskDependency` : Ajoute une dÃ©pendance entre deux tÃ¢ches.
- `Remove-RoadmapTaskDependency` : Supprime une dÃ©pendance entre deux tÃ¢ches.
- `Get-RoadmapTaskDependencies` : Obtient les dÃ©pendances d'une tÃ¢che.
- `Get-RoadmapTaskDependents` : Obtient les tÃ¢ches qui dÃ©pendent d'une tÃ¢che spÃ©cifique.
- `Find-DependencyCycle` : DÃ©tecte les cycles de dÃ©pendances.

### Export et import

Le module permet d'exporter et d'importer des roadmaps dans diffÃ©rents formats :

- `Export-RoadmapToJson` : Exporte une roadmap au format JSON.
- `Import-RoadmapFromJson` : Importe une roadmap depuis un fichier JSON.
- `Export-RoadmapTreeToMarkdown` : Exporte un arbre de roadmap au format markdown.

### GÃ©nÃ©ration de rapports

Le module peut gÃ©nÃ©rer des rapports et des statistiques sur les roadmaps :

- `Generate-RoadmapReport` : GÃ©nÃ¨re un rapport sur la roadmap.
- `Generate-RoadmapStatistics` : GÃ©nÃ¨re des statistiques sur la roadmap.
- `Generate-RoadmapVisualization` : GÃ©nÃ¨re une visualisation de la roadmap.

### Journalisation

Le module dispose d'un systÃ¨me de journalisation avancÃ© :

- `Set-RoadmapLogLevel` : DÃ©finit le niveau de journalisation.
- `Get-RoadmapLogConfiguration` : Obtient la configuration de journalisation actuelle.
- `Set-RoadmapLogDestination` : DÃ©finit la destination des journaux.
- `Set-RoadmapLogFormat` : DÃ©finit le format des messages de journal.
- `Write-RoadmapDebug` : Ã‰crit un message de dÃ©bogage.
- `Write-RoadmapVerbose` : Ã‰crit un message verbeux.
- `Write-RoadmapInformation` : Ã‰crit un message d'information.
- `Write-RoadmapWarning` : Ã‰crit un message d'avertissement.
- `Write-RoadmapError` : Ã‰crit un message d'erreur.
- `Write-RoadmapCritical` : Ã‰crit un message critique.

### Modes opÃ©rationnels

Le module implÃ©mente plusieurs modes opÃ©rationnels spÃ©cialisÃ©s :

- `Invoke-RoadmapArchitecture` : Mode ARCHI pour la gÃ©nÃ©ration de diagrammes d'architecture.
- `Invoke-RoadmapDebug` : Mode DEBUG pour le dÃ©bogage de scripts.
- `Invoke-RoadmapTest` : Mode TEST pour l'exÃ©cution de tests.
- `Invoke-RoadmapCheck` : Mode CHECK pour la vÃ©rification de l'Ã©tat des tÃ¢ches.
- `Invoke-RoadmapGranularization` : Mode GRAN pour la granularisation des tÃ¢ches.

## Utilisation avancÃ©e

### Configuration personnalisÃ©e

Le module permet de personnaliser son comportement via des fichiers de configuration :

```powershell
# Charger une configuration personnalisÃ©e

$config = Get-Configuration -ConfigFile "chemin/vers/config.json"

# Fusionner avec la configuration par dÃ©faut

$mergedConfig = Merge-Configuration -DefaultConfig (Get-DefaultConfiguration) -CustomConfig $config

# Utiliser la configuration fusionnÃ©e

ConvertFrom-MarkdownToRoadmap -FilePath "roadmap.md" -Configuration $mergedConfig
```plaintext
### Journalisation avancÃ©e

Le systÃ¨me de journalisation peut Ãªtre configurÃ© pour diffÃ©rents besoins :

```powershell
# DÃ©finir le niveau de journalisation

Set-RoadmapLogLevel -Level "DEBUG"

# DÃ©finir la destination des journaux

Set-RoadmapLogDestination -Destination "File" -FilePath "logs/roadmap.log"

# DÃ©finir le format des messages

Set-RoadmapLogFormat -Format "[{0}] {1} - {2}" # Niveau, Timestamp, Message

```plaintext
### Utilisation des modes opÃ©rationnels

Les modes opÃ©rationnels peuvent Ãªtre utilisÃ©s pour des tÃ¢ches spÃ©cifiques :

```powershell
# Mode ARCHI - GÃ©nÃ©rer des diagrammes d'architecture

Invoke-RoadmapArchitecture -FilePath "roadmap.md" -ProjectPath "project" -OutputPath "output" -DiagramType "C4"

# Mode DEBUG - DÃ©boguer un script avec simulation de contexte

Invoke-RoadmapDebug -FilePath "roadmap.md" -ProjectPath "project" -ScriptPath "script.ps1" -OutputPath "output" -SimulateContext $true -ContextFile "context.json"

# Mode TEST - ExÃ©cuter des tests avec couverture de code

Invoke-RoadmapTest -FilePath "roadmap.md" -ModulePath "module" -TestsPath "tests" -OutputPath "output" -CoverageThreshold 80 -IncludeCodeCoverage $true
```plaintext
## Extension du module

### Ajout de nouvelles fonctions

Pour ajouter une nouvelle fonction au module :

1. CrÃ©ez un fichier PS1 dans le rÃ©pertoire appropriÃ© (Public, Private ou Common)
2. ImplÃ©mentez la fonction avec la documentation appropriÃ©e
3. Si nÃ©cessaire, mettez Ã  jour le manifeste du module pour exporter la fonction

Exemple de nouvelle fonction :

```powershell
<#

.SYNOPSIS
    Exemple de nouvelle fonction.

.DESCRIPTION
    Cette fonction est un exemple de nouvelle fonction Ã  ajouter au module.

.PARAMETER InputObject
    Objet d'entrÃ©e Ã  traiter.

.EXAMPLE
    New-ExampleFunction -InputObject "test"
#>

function New-ExampleFunction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$InputObject
    )
    
    # ImplÃ©mentation de la fonction

    return $InputObject
}

# Exporter la fonction

Export-ModuleMember -Function New-ExampleFunction
```plaintext
### CrÃ©ation d'un nouveau mode opÃ©rationnel

Pour crÃ©er un nouveau mode opÃ©rationnel :

1. CrÃ©ez un fichier PS1 dans le rÃ©pertoire Public avec le prÃ©fixe "Invoke-Roadmap"
2. ImplÃ©mentez la fonction principale du mode
3. CrÃ©ez un script de mode dans le rÃ©pertoire racine du projet
4. Mettez Ã  jour le manifeste du module pour exporter la fonction

## DÃ©pannage

### ProblÃ¨mes courants

- **Erreur de chargement du module** : VÃ©rifiez que tous les fichiers sont prÃ©sents et que les chemins sont corrects.
- **Fonction non trouvÃ©e** : VÃ©rifiez que la fonction est exportÃ©e dans le manifeste du module.
- **Erreur de parsing** : VÃ©rifiez que le fichier markdown est correctement formatÃ©.

### Journalisation pour le dÃ©pannage

Activez la journalisation dÃ©taillÃ©e pour diagnostiquer les problÃ¨mes :

```powershell
# Activer la journalisation de dÃ©bogage

Set-RoadmapLogLevel -Level "DEBUG"

# ExÃ©cuter l'opÃ©ration problÃ©matique

ConvertFrom-MarkdownToRoadmap -FilePath "roadmap.md"
```plaintext
## RÃ©fÃ©rences

- [Documentation PowerShell](https://docs.microsoft.com/en-us/powershell/)
- [Markdown Specification](https://spec.commonmark.org/)
- [PowerShell Module Development](https://docs.microsoft.com/en-us/powershell/scripting/developer/module/writing-a-windows-powershell-module)

## Annexes

### Liste complÃ¨te des fonctions exportÃ©es

Consultez le manifeste du module (RoadmapParserCore.psd1) pour la liste complÃ¨te des fonctions exportÃ©es.

### Exemples de fichiers de configuration

Consultez le rÃ©pertoire Config pour des exemples de fichiers de configuration.

### Exemples de roadmaps

Consultez le rÃ©pertoire Resources pour des exemples de fichiers de roadmap.
