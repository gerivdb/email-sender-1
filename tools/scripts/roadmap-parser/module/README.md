# RoadmapParserCore

## Description

RoadmapParserCore est un module PowerShell conÃ§u pour analyser, manipuler et gÃ©rer des roadmaps au format markdown. Il fournit un ensemble complet de fonctions pour travailler avec des fichiers de roadmap, extraire des informations sur les tÃ¢ches, construire des arborescences de tÃ¢ches, et gÃ©nÃ©rer des rapports.

## FonctionnalitÃ©s principales

- Parsing de fichiers markdown de roadmap
- Construction d'arborescences de tÃ¢ches
- Manipulation de tÃ¢ches (ajout, suppression, modification)
- Gestion des dÃ©pendances entre tÃ¢ches
- Export et import dans diffÃ©rents formats (JSON, Markdown)
- GÃ©nÃ©ration de rapports et statistiques
- Fonctions utilitaires pour la validation et la manipulation de donnÃ©es
- Journalisation avancÃ©e avec diffÃ©rents niveaux
- Modes opÃ©rationnels spÃ©cialisÃ©s (ARCHI, DEBUG, TEST, CHECK, GRAN)

## Structure du module

```
RoadmapParserCore/
â”œâ”€â”€ RoadmapParserCore.psd1       # Manifeste du module
â”œâ”€â”€ RoadmapParserCore.psm1       # Fichier principal du module
â”œâ”€â”€ Functions/                   # RÃ©pertoire des fonctions
â”‚   â”œâ”€â”€ Common/                  # Fonctions communes
â”‚   â”œâ”€â”€ Private/                 # Fonctions privÃ©es
â”‚   â””â”€â”€ Public/                  # Fonctions publiques
â”œâ”€â”€ Exceptions/                  # Classes d'exceptions personnalisÃ©es
â”œâ”€â”€ Config/                      # Fichiers de configuration
â”œâ”€â”€ Resources/                   # Ressources du module
â””â”€â”€ docs/                        # Documentation
```

## Installation

1. TÃ©lÃ©chargez ou clonez le dÃ©pÃ´t
2. Copiez le rÃ©pertoire `RoadmapParserCore` dans un des rÃ©pertoires de modules PowerShell
3. Importez le module avec `Import-Module RoadmapParserCore`

## Utilisation

### Exemple de base

```powershell
# Importer le module
Import-Module RoadmapParserCore

# Analyser un fichier markdown de roadmap
$roadmap = ConvertFrom-MarkdownToRoadmap -FilePath "chemin/vers/roadmap.md"

# Obtenir toutes les tÃ¢ches
$tasks = Get-RoadmapTask -Roadmap $roadmap

# Afficher les tÃ¢ches terminÃ©es
$completedTasks = Get-RoadmapTasksByStatus -Roadmap $roadmap -Status "Complete"
$completedTasks | Format-Table -Property Id, Title, Status

# Exporter la roadmap au format JSON
Export-RoadmapToJson -Roadmap $roadmap -FilePath "chemin/vers/export.json"
```

### Utilisation des modes opÃ©rationnels

```powershell
# Mode ARCHI - GÃ©nÃ©rer des diagrammes d'architecture
Invoke-RoadmapArchitecture -FilePath "roadmap.md" -ProjectPath "project" -OutputPath "output"

# Mode DEBUG - DÃ©boguer un script
Invoke-RoadmapDebug -FilePath "roadmap.md" -ProjectPath "project" -ScriptPath "script.ps1" -OutputPath "output"

# Mode TEST - ExÃ©cuter des tests
Invoke-RoadmapTest -FilePath "roadmap.md" -ModulePath "module" -TestsPath "tests" -OutputPath "output"

# Mode CHECK - VÃ©rifier l'Ã©tat des tÃ¢ches
Invoke-RoadmapCheck -FilePath "roadmap.md" -OutputPath "output"

# Mode GRAN - Granulariser les tÃ¢ches
Invoke-RoadmapGranularization -FilePath "roadmap.md" -OutputPath "output"
```

## Fonctions principales

Le module exporte de nombreuses fonctions, regroupÃ©es par catÃ©gories :

### Parsing du markdown

- `ConvertFrom-MarkdownToRoadmap` - Convertit un fichier markdown en objet roadmap
- `Parse-MarkdownTask` - Analyse une ligne de tÃ¢che markdown
- `Extract-MarkdownTaskStatus` - Extrait le statut d'une tÃ¢che
- `Extract-MarkdownTaskId` - Extrait l'identifiant d'une tÃ¢che
- `Extract-MarkdownTaskTitle` - Extrait le titre d'une tÃ¢che

### Manipulation de l'arbre

- `New-RoadmapTree` - CrÃ©e un nouvel arbre de roadmap
- `New-RoadmapTask` - CrÃ©e une nouvelle tÃ¢che
- `Add-RoadmapTask` - Ajoute une tÃ¢che Ã  l'arbre
- `Remove-RoadmapTask` - Supprime une tÃ¢che de l'arbre
- `Get-RoadmapTask` - Obtient une tÃ¢che spÃ©cifique
- `Set-RoadmapTaskStatus` - Modifie le statut d'une tÃ¢che

### Export et gÃ©nÃ©ration

- `Export-RoadmapToJson` - Exporte une roadmap au format JSON
- `Import-RoadmapFromJson` - Importe une roadmap depuis un fichier JSON
- `Export-RoadmapTreeToMarkdown` - Exporte un arbre de roadmap au format markdown
- `Generate-RoadmapReport` - GÃ©nÃ¨re un rapport sur la roadmap

### Journalisation

- `Set-RoadmapLogLevel` - DÃ©finit le niveau de journalisation
- `Write-RoadmapDebug` - Ã‰crit un message de dÃ©bogage
- `Write-RoadmapVerbose` - Ã‰crit un message verbeux
- `Write-RoadmapInformation` - Ã‰crit un message d'information
- `Write-RoadmapWarning` - Ã‰crit un message d'avertissement
- `Write-RoadmapError` - Ã‰crit un message d'erreur

### Modes opÃ©rationnels

- `Invoke-RoadmapArchitecture` - Mode ARCHI pour la gÃ©nÃ©ration de diagrammes d'architecture
- `Invoke-RoadmapDebug` - Mode DEBUG pour le dÃ©bogage de scripts
- `Invoke-RoadmapTest` - Mode TEST pour l'exÃ©cution de tests
- `Invoke-RoadmapCheck` - Mode CHECK pour la vÃ©rification de l'Ã©tat des tÃ¢ches
- `Invoke-RoadmapGranularization` - Mode GRAN pour la granularisation des tÃ¢ches

## Documentation

Consultez le rÃ©pertoire [docs](docs) pour une documentation dÃ©taillÃ©e.

## Contribution

Les contributions sont les bienvenues ! Veuillez suivre ces Ã©tapes pour contribuer :

1. Forkez le dÃ©pÃ´t
2. CrÃ©ez une branche pour votre fonctionnalitÃ© (`git checkout -b feature/ma-fonctionnalite`)
3. Committez vos changements (`git commit -am 'Ajout de ma fonctionnalitÃ©'`)
4. Poussez vers la branche (`git push origin feature/ma-fonctionnalite`)
5. CrÃ©ez une Pull Request

## Licence

Ce projet est sous licence MIT. Voir le fichier LICENSE pour plus de dÃ©tails.

## Auteurs

- RoadmapParser Team
