# RoadmapParserCore

## Description

RoadmapParserCore est un module PowerShell conçu pour analyser, manipuler et gérer des roadmaps au format markdown. Il fournit un ensemble complet de fonctions pour travailler avec des fichiers de roadmap, extraire des informations sur les tâches, construire des arborescences de tâches, et générer des rapports.

## Fonctionnalités principales

- Parsing de fichiers markdown de roadmap
- Construction d'arborescences de tâches
- Manipulation de tâches (ajout, suppression, modification)
- Gestion des dépendances entre tâches
- Export et import dans différents formats (JSON, Markdown)
- Génération de rapports et statistiques
- Fonctions utilitaires pour la validation et la manipulation de données
- Journalisation avancée avec différents niveaux
- Modes opérationnels spécialisés (ARCHI, DEBUG, TEST, CHECK, GRAN)

## Structure du module

```
RoadmapParserCore/
├── RoadmapParserCore.psd1       # Manifeste du module
├── RoadmapParserCore.psm1       # Fichier principal du module
├── Functions/                   # Répertoire des fonctions
│   ├── Common/                  # Fonctions communes
│   ├── Private/                 # Fonctions privées
│   └── Public/                  # Fonctions publiques
├── Exceptions/                  # Classes d'exceptions personnalisées
├── Config/                      # Fichiers de configuration
├── Resources/                   # Ressources du module
└── docs/                        # Documentation
```

## Installation

1. Téléchargez ou clonez le dépôt
2. Copiez le répertoire `RoadmapParserCore` dans un des répertoires de modules PowerShell
3. Importez le module avec `Import-Module RoadmapParserCore`

## Utilisation

### Exemple de base

```powershell
# Importer le module
Import-Module RoadmapParserCore

# Analyser un fichier markdown de roadmap
$roadmap = ConvertFrom-MarkdownToRoadmap -FilePath "chemin/vers/roadmap.md"

# Obtenir toutes les tâches
$tasks = Get-RoadmapTask -Roadmap $roadmap

# Afficher les tâches terminées
$completedTasks = Get-RoadmapTasksByStatus -Roadmap $roadmap -Status "Complete"
$completedTasks | Format-Table -Property Id, Title, Status

# Exporter la roadmap au format JSON
Export-RoadmapToJson -Roadmap $roadmap -FilePath "chemin/vers/export.json"
```

### Utilisation des modes opérationnels

```powershell
# Mode ARCHI - Générer des diagrammes d'architecture
Invoke-RoadmapArchitecture -FilePath "roadmap.md" -ProjectPath "project" -OutputPath "output"

# Mode DEBUG - Déboguer un script
Invoke-RoadmapDebug -FilePath "roadmap.md" -ProjectPath "project" -ScriptPath "script.ps1" -OutputPath "output"

# Mode TEST - Exécuter des tests
Invoke-RoadmapTest -FilePath "roadmap.md" -ModulePath "module" -TestsPath "tests" -OutputPath "output"

# Mode CHECK - Vérifier l'état des tâches
Invoke-RoadmapCheck -FilePath "roadmap.md" -OutputPath "output"

# Mode GRAN - Granulariser les tâches
Invoke-RoadmapGranularization -FilePath "roadmap.md" -OutputPath "output"
```

## Fonctions principales

Le module exporte de nombreuses fonctions, regroupées par catégories :

### Parsing du markdown

- `ConvertFrom-MarkdownToRoadmap` - Convertit un fichier markdown en objet roadmap
- `Parse-MarkdownTask` - Analyse une ligne de tâche markdown
- `Extract-MarkdownTaskStatus` - Extrait le statut d'une tâche
- `Extract-MarkdownTaskId` - Extrait l'identifiant d'une tâche
- `Extract-MarkdownTaskTitle` - Extrait le titre d'une tâche

### Manipulation de l'arbre

- `New-RoadmapTree` - Crée un nouvel arbre de roadmap
- `New-RoadmapTask` - Crée une nouvelle tâche
- `Add-RoadmapTask` - Ajoute une tâche à l'arbre
- `Remove-RoadmapTask` - Supprime une tâche de l'arbre
- `Get-RoadmapTask` - Obtient une tâche spécifique
- `Set-RoadmapTaskStatus` - Modifie le statut d'une tâche

### Export et génération

- `Export-RoadmapToJson` - Exporte une roadmap au format JSON
- `Import-RoadmapFromJson` - Importe une roadmap depuis un fichier JSON
- `Export-RoadmapTreeToMarkdown` - Exporte un arbre de roadmap au format markdown
- `Generate-RoadmapReport` - Génère un rapport sur la roadmap

### Journalisation

- `Set-RoadmapLogLevel` - Définit le niveau de journalisation
- `Write-RoadmapDebug` - Écrit un message de débogage
- `Write-RoadmapVerbose` - Écrit un message verbeux
- `Write-RoadmapInformation` - Écrit un message d'information
- `Write-RoadmapWarning` - Écrit un message d'avertissement
- `Write-RoadmapError` - Écrit un message d'erreur

### Modes opérationnels

- `Invoke-RoadmapArchitecture` - Mode ARCHI pour la génération de diagrammes d'architecture
- `Invoke-RoadmapDebug` - Mode DEBUG pour le débogage de scripts
- `Invoke-RoadmapTest` - Mode TEST pour l'exécution de tests
- `Invoke-RoadmapCheck` - Mode CHECK pour la vérification de l'état des tâches
- `Invoke-RoadmapGranularization` - Mode GRAN pour la granularisation des tâches

## Documentation

Consultez le répertoire [docs](docs) pour une documentation détaillée.

## Contribution

Les contributions sont les bienvenues ! Veuillez suivre ces étapes pour contribuer :

1. Forkez le dépôt
2. Créez une branche pour votre fonctionnalité (`git checkout -b feature/ma-fonctionnalite`)
3. Committez vos changements (`git commit -am 'Ajout de ma fonctionnalité'`)
4. Poussez vers la branche (`git push origin feature/ma-fonctionnalite`)
5. Créez une Pull Request

## Licence

Ce projet est sous licence MIT. Voir le fichier LICENSE pour plus de détails.

## Auteurs

- RoadmapParser Team
