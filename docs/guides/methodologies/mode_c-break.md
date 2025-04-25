# Mode C-BREAK

## Description

Le mode C-BREAK (Cycle Breaker) est un mode opérationnel conçu pour détecter et corriger les dépendances circulaires dans un projet. Les dépendances circulaires sont des situations où un module A dépend d'un module B, qui dépend d'un module C, qui dépend à son tour du module A, créant ainsi un cycle. Ces cycles peuvent causer des problèmes de maintenance, de performance et de testabilité.

## Objectifs

- Détecter les dépendances circulaires dans un projet
- Analyser la sévérité et l'impact des cycles détectés
- Proposer des stratégies de refactoring pour briser les cycles
- Appliquer automatiquement les corrections si demandé
- Générer des rapports et des visualisations des dépendances

## Fonctionnalités

### Détection de cycles

Le mode C-BREAK utilise trois algorithmes différents pour détecter les cycles de dépendances :

1. **DFS (Depth-First Search)** : Algorithme de parcours en profondeur qui détecte les cycles en marquant les nœuds visités.
2. **Tarjan** : Algorithme pour trouver les composantes fortement connexes dans un graphe, qui correspondent aux cycles.
3. **Johnson** : Algorithme pour énumérer tous les cycles élémentaires dans un graphe dirigé.

### Analyse de dépendances

Le mode analyse les dépendances entre fichiers en fonction du langage de programmation :

- **PowerShell** : Détecte les instructions `Import-Module`, `. (dot sourcing)`, `#Requires`, etc.
- **Python** : Détecte les instructions `import` et `from ... import`.
- **JavaScript/TypeScript** : Détecte les instructions `import` et `require()`.
- **C#** : Détecte les instructions `using` et les références de namespace.
- **Java** : Détecte les instructions `import`.

### Stratégies de résolution

Le mode propose plusieurs stratégies pour résoudre les dépendances circulaires :

1. **Extraction d'interface** : Extraire une interface à partir d'une classe et faire dépendre les clients de l'interface plutôt que de l'implémentation.
2. **Inversion de dépendance** : Inverser la direction des dépendances en introduisant des abstractions.
3. **Pattern médiateur** : Introduire un médiateur pour gérer les interactions entre les modules.
4. **Couche d'abstraction** : Introduire une couche d'abstraction entre les modules.

### Visualisation

Le mode peut générer des graphes de dépendances dans différents formats :

- **DOT** : Format Graphviz pour la visualisation de graphes.
- **Mermaid** : Format Markdown pour la visualisation de graphes.
- **PlantUML** : Format UML pour la visualisation de graphes.
- **JSON** : Format JSON pour l'intégration avec d'autres outils.

## Utilisation

### Syntaxe

```powershell
.\c-break-mode.ps1 -FilePath <string> [-TaskIdentifier <string>] -ProjectPath <string> [-OutputPath <string>] [-StartPath <string>] [-IncludePatterns <string[]>] [-ExcludePatterns <string[]>] [-DetectionAlgorithm <string>] [-MaxDepth <int>] [-MinimumCycleSeverity <int>] [-AutoFix <bool>] [-FixStrategy <string>] [-GenerateGraph <bool>] [-GraphFormat <string>]
```

### Paramètres

| Paramètre | Description | Obligatoire | Valeur par défaut |
|-----------|-------------|-------------|-------------------|
| FilePath | Chemin vers le fichier de roadmap à traiter. | Oui | - |
| TaskIdentifier | Identifiant de la tâche à traiter. | Non | - |
| ProjectPath | Chemin vers le répertoire du projet à analyser. | Oui | - |
| OutputPath | Chemin où seront générés les fichiers de sortie. | Non | Répertoire courant |
| StartPath | Chemin spécifique dans le projet où commencer l'analyse. | Non | "" |
| IncludePatterns | Motifs d'inclusion pour les fichiers à analyser. | Non | "*.ps1", "*.py", "*.js", "*.ts", "*.cs", "*.java" |
| ExcludePatterns | Motifs d'exclusion pour les fichiers à ignorer. | Non | "*node_modules*", "*venv*", "*__pycache__*", "*.test.*", "*.spec.*" |
| DetectionAlgorithm | Algorithme à utiliser pour la détection des cycles. | Non | "TARJAN" |
| MaxDepth | Profondeur maximale d'analyse des dépendances. | Non | 10 |
| MinimumCycleSeverity | Niveau de détail minimum pour considérer un cycle comme significatif (1-5). | Non | 1 |
| AutoFix | Indique si les dépendances circulaires détectées doivent être corrigées automatiquement. | Non | $false |
| FixStrategy | Stratégie de correction à utiliser lorsque AutoFix est activé. | Non | "AUTO" |
| GenerateGraph | Indique si un graphe des dépendances doit être généré. | Non | $false |
| GraphFormat | Format du graphe à générer. | Non | "DOT" |

### Exemples

#### Détecter les cycles dans un projet PowerShell

```powershell
.\c-break-mode.ps1 -FilePath "roadmap.md" -ProjectPath "C:\Projects\MyProject" -IncludePatterns "*.ps1" -DetectionAlgorithm "TARJAN"
```

#### Générer un graphe de dépendances

```powershell
.\c-break-mode.ps1 -FilePath "roadmap.md" -ProjectPath "C:\Projects\MyProject" -GenerateGraph $true -GraphFormat "MERMAID"
```

#### Corriger automatiquement les cycles

```powershell
.\c-break-mode.ps1 -FilePath "roadmap.md" -ProjectPath "C:\Projects\MyProject" -AutoFix $true -FixStrategy "INTERFACE_EXTRACTION"
```

#### Analyser un sous-répertoire spécifique

```powershell
.\c-break-mode.ps1 -FilePath "roadmap.md" -ProjectPath "C:\Projects\MyProject" -StartPath "src\core"
```

## Sorties

Le mode C-BREAK génère plusieurs fichiers de sortie :

1. **cycle_detection_report.json** : Rapport détaillé des cycles détectés.
2. **dependency_graph.<format>** : Graphe des dépendances dans le format spécifié.
3. **cycle_fix_report.json** : Rapport des corrections appliquées.

## Intégration avec d'autres modes

Le mode C-BREAK peut être utilisé en combinaison avec d'autres modes :

- **Mode ARCHI** : Pour analyser l'architecture du projet et détecter les problèmes structurels.
- **Mode REVIEW** : Pour vérifier la qualité du code et détecter les problèmes potentiels.
- **Mode OPTI** : Pour optimiser les performances du projet en éliminant les dépendances inutiles.

## Bonnes pratiques

1. **Commencer par une analyse** : Utilisez d'abord le mode sans correction automatique pour comprendre les cycles détectés.
2. **Visualiser les dépendances** : Générez un graphe pour mieux comprendre la structure des dépendances.
3. **Corriger progressivement** : Corrigez les cycles un par un, en commençant par les plus critiques.
4. **Tester après chaque correction** : Assurez-vous que le projet fonctionne toujours après chaque correction.
5. **Automatiser la détection** : Intégrez la détection de cycles dans votre pipeline CI/CD pour éviter l'introduction de nouveaux cycles.

## Limitations

- La détection de dépendances est basée sur l'analyse statique du code et peut ne pas détecter toutes les dépendances dynamiques.
- La correction automatique peut ne pas être adaptée à tous les cas et peut nécessiter une intervention manuelle.
- L'analyse de grands projets peut prendre du temps et consommer beaucoup de ressources.

## Conclusion

Le mode C-BREAK est un outil puissant pour maintenir la qualité et la maintenabilité d'un projet en détectant et en corrigeant les dépendances circulaires. En utilisant ce mode régulièrement, vous pouvez éviter les problèmes liés aux cycles de dépendances et améliorer la structure de votre code.
