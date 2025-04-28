# Gestionnaire Intégré

## Description
Le Gestionnaire Intégré est un outil qui unifie les fonctionnalités du Mode Manager et du Roadmap Manager, offrant une interface unique pour gérer à la fois les modes opérationnels et les roadmaps du projet.

## Objectif
L'objectif principal du Gestionnaire Intégré est de simplifier la gestion des modes opérationnels et des roadmaps en offrant une interface unifiée. Il permet d'exécuter des modes, des workflows, d'analyser des roadmaps et de les mettre à jour, le tout à partir d'un seul point d'entrée.

## Fonctionnalités
- Interface unifiée pour tous les modes opérationnels et les roadmaps
- Gestion centralisée de la configuration
- Exécution individuelle des modes
- Exécution de workflows (séquences de modes)
- Analyse des roadmaps
- Mise à jour des roadmaps avec Git
- Affichage de la liste des modes disponibles
- Affichage de la liste des roadmaps disponibles
- Mode interactif avec menu

## Utilisation

### Commande de base
```powershell
.\development\scripts\integrated-manager.ps1 [options]
```

### Paramètres
| Paramètre | Description | Obligatoire | Valeur par défaut |
|-----------|-------------|-------------|-------------------|
| Mode | Le mode à exécuter (ARCHI, CHECK, C-BREAK, DEBUG, DEV-R, GRAN, OPTI, PREDIC, REVIEW, ROADMAP-PLAN, ROADMAP-REPORT, ROADMAP-SYNC, TEST) | Non | - |
| RoadmapPath | Chemin vers le fichier de roadmap | Non | Valeur de configuration |
| TaskIdentifier | Identifiant de la tâche à traiter (ex: "1.2.3") | Non | - |
| ConfigPath | Chemin vers le fichier de configuration | Non | "development\config\unified-config.json" |
| Force | Indique si les modifications doivent être appliquées sans confirmation | Non | $false |
| ListModes | Affiche la liste des modes disponibles et leurs descriptions | Non | $false |
| ListRoadmaps | Affiche la liste des roadmaps disponibles | Non | $false |
| Analyze | Analyse la roadmap et génère des rapports | Non | $false |
| GitUpdate | Met à jour la roadmap en fonction des commits Git | Non | $false |
| Workflow | Nom du workflow à exécuter | Non | - |
| Interactive | Lance le mode interactif avec menu | Non | $false |

### Exemples

#### Exécuter un mode spécifique
```powershell
# Exécuter le mode CHECK
.\development\scripts\integrated-manager.ps1 -Mode CHECK -RoadmapPath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3" -Force

# Exécuter le mode GRAN
.\development\scripts\integrated-manager.ps1 -Mode GRAN -RoadmapPath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3"
```

#### Exécuter un workflow
```powershell
# Exécuter le workflow de développement
.\development\scripts\integrated-manager.ps1 -Workflow "Development" -RoadmapPath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3"

# Exécuter le workflow d'optimisation
.\development\scripts\integrated-manager.ps1 -Workflow "Optimization" -RoadmapPath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3"
```

#### Analyser une roadmap
```powershell
# Analyser la roadmap par défaut
.\development\scripts\integrated-manager.ps1 -Analyze

# Analyser une roadmap spécifique
.\development\scripts\integrated-manager.ps1 -Analyze -RoadmapPath "projet\roadmaps\Roadmap\roadmap_perso.md"
```

#### Mettre à jour une roadmap avec Git
```powershell
# Mettre à jour la roadmap par défaut
.\development\scripts\integrated-manager.ps1 -GitUpdate

# Mettre à jour une roadmap spécifique
.\development\scripts\integrated-manager.ps1 -GitUpdate -RoadmapPath "projet\roadmaps\Roadmap\roadmap_perso.md"
```

#### Afficher la liste des modes disponibles
```powershell
.\development\scripts\integrated-manager.ps1 -ListModes
```

#### Afficher la liste des roadmaps disponibles
```powershell
.\development\scripts\integrated-manager.ps1 -ListRoadmaps
```

#### Lancer le mode interactif
```powershell
.\development\scripts\integrated-manager.ps1 -Interactive
```

## Workflows prédéfinis

Le Gestionnaire Intégré permet d'exécuter des workflows prédéfinis en utilisant le paramètre `-Workflow`. Voici les workflows disponibles par défaut :

### Workflow de développement complet
```powershell
.\development\scripts\integrated-manager.ps1 -Workflow "Development" -RoadmapPath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3"
```
Ce workflow exécute les modes suivants dans l'ordre :
1. GRAN - Décompose la tâche en sous-tâches
2. DEV-R - Implémente la tâche
3. TEST - Teste la tâche
4. CHECK - Vérifie l'état d'avancement de la tâche

### Workflow d'optimisation
```powershell
.\development\scripts\integrated-manager.ps1 -Workflow "Optimization" -RoadmapPath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3"
```
Ce workflow exécute les modes suivants dans l'ordre :
1. REVIEW - Revoit le code
2. OPTI - Optimise le code
3. TEST - Teste le code optimisé
4. CHECK - Vérifie l'état d'avancement de la tâche

### Workflow de débogage
```powershell
.\development\scripts\integrated-manager.ps1 -Workflow "Debugging" -RoadmapPath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3"
```
Ce workflow exécute les modes suivants dans l'ordre :
1. DEBUG - Débogue le code
2. TEST - Teste le code débogué
3. CHECK - Vérifie l'état d'avancement de la tâche

### Workflow d'architecture
```powershell
.\development\scripts\integrated-manager.ps1 -Workflow "Architecture" -RoadmapPath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3"
```
Ce workflow exécute les modes suivants dans l'ordre :
1. ARCHI - Conçoit l'architecture
2. C-BREAK - Détecte et résout les dépendances circulaires
3. REVIEW - Revoit l'architecture

### Workflow d'analyse
```powershell
.\development\scripts\integrated-manager.ps1 -Workflow "Analysis" -RoadmapPath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3"
```
Ce workflow exécute les modes suivants dans l'ordre :
1. CHECK - Vérifie l'état d'avancement de la tâche
2. PREDIC - Prédit les performances et détecte les anomalies
3. REVIEW - Revoit le code

### Workflow de gestion de roadmap
```powershell
.\development\scripts\integrated-manager.ps1 -Workflow "RoadmapManagement" -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md"
```
Ce workflow exécute les modes suivants dans l'ordre :
1. ROADMAP-SYNC - Synchronise la roadmap entre différents formats
2. ROADMAP-REPORT - Génère des rapports sur l'état de la roadmap
3. ROADMAP-PLAN - Planifie les tâches futures

## Configuration

La configuration du Gestionnaire Intégré se trouve dans le fichier `development\config\unified-config.json`. Ce fichier contient la configuration de tous les modes opérationnels, des roadmaps et des workflows.

### Structure de la configuration
```json
{
  "General": {
    "RoadmapPath": "projet\\roadmaps\\Roadmap\\roadmap_complete_converted.md",
    "ActiveDocumentPath": "docs\\plans\\plan-modes-stepup.md",
    "ReportPath": "reports",
    "LogPath": "logs",
    "DefaultLanguage": "fr-FR",
    "DefaultEncoding": "UTF8-BOM",
    "ProjectRoot": "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1"
  },
  "Modes": {
    "Archi": {
      "Enabled": true,
      "ScriptPath": "development\\scripts\\maintenance\\modes\\archi-mode.ps1",
      "DiagramType": "C4",
      "IncludeComponents": true,
      "IncludeInterfaces": true,
      "IncludeDependencies": true,
      "OutputFormats": ["Markdown", "PlantUML", "Mermaid"]
    },
    // Autres modes...
  },
  "Roadmaps": {
    "Main": {
      "Path": "projet\\roadmaps\\Roadmap\\roadmap_complete_converted.md",
      "Description": "Roadmap principale du projet",
      "Format": "Markdown",
      "AutoUpdate": true,
      "GitIntegration": true,
      "ReportPath": "projet\\roadmaps\\Reports"
    },
    // Autres roadmaps...
  },
  "RoadmapManager": {
    "DefaultRoadmapPath": "projet\\roadmaps\\Roadmap\\roadmap_perso.md",
    "ReportsFolder": "projet\\roadmaps\\Reports",
    "GitRepo": ".",
    "DaysToAnalyze": 7,
    "AutoUpdate": true,
    "GenerateReport": true,
    "JournalPath": "projet\\roadmaps\\journal",
    "LogFile": "projet\\roadmaps\\logs\\RoadmapManager.log",
    "BackupFolder": "projet\\roadmaps\\backup",
    "Scripts": {
      "Manager": "projet\\roadmaps\\scripts\\RoadmapManager.ps1",
      "Analyzer": "projet\\roadmaps\\scripts\\RoadmapAnalyzer.ps1",
      "GitUpdater": "projet\\roadmaps\\scripts\\RoadmapGitUpdater.ps1",
      "Cleanup": "projet\\roadmaps\\scripts\\CleanupRoadmapFiles.ps1",
      "Organize": "projet\\roadmaps\\scripts\\OrganizeRoadmapScripts.ps1",
      "Execute": "projet\\roadmaps\\scripts\\StartRoadmapExecution.ps1",
      "Sync": "projet\\roadmaps\\scripts\\Sync-RoadmapWithJournal.ps1"
    }
  },
  "Workflows": {
    "Development": {
      "Description": "Workflow de développement complet",
      "Modes": ["GRAN", "DEV-R", "TEST", "CHECK"],
      "AutoContinue": true,
      "StopOnError": true
    },
    // Autres workflows...
  },
  "Integration": {
    "EnabledByDefault": true,
    "DefaultWorkflow": "Development",
    "DefaultRoadmap": "Main",
    "AutoSaveResults": true,
    "ResultsPath": "reports\\integration",
    "LogLevel": "Info",
    "NotifyOnCompletion": true,
    "MaxConcurrentTasks": 4
  },
  "Paths": {
    "OutputDirectory": "output",
    "TestsDirectory": "tests",
    "ScriptsDirectory": "development\\scripts",
    "ModulePath": "development\\roadmap\\parser\\module",
    "FunctionsPath": "development\\roadmap\\parser\\module\\Functions",
    "TemplatesPath": "development\\roadmap\\parser\\module\\Templates",
    "BackupPath": "backup"
  }
}
```

## Modes adaptés pour la configuration unifiée

Le Gestionnaire Intégré utilise des versions adaptées des modes opérationnels qui sont conçues pour utiliser la configuration unifiée. Ces modes adaptés se trouvent dans le répertoire `development\scripts\maintenance\modes\`.

### Mode CHECK adapté
Le mode CHECK adapté (`development\scripts\maintenance\modes\check.ps1`) vérifie si les tâches sont 100% implémentées et testées, puis met à jour automatiquement les cases à cocher dans le document actif. Cette version adaptée utilise la configuration unifiée pour déterminer les chemins des fichiers, les options de vérification, etc.

```powershell
# Exécuter le mode CHECK adapté directement
.\development\scripts\maintenance\modes\check.ps1 -TaskIdentifier "1.2.3" -Force

# Exécuter le mode CHECK adapté via le gestionnaire intégré
.\development\scripts\integrated-manager.ps1 -Mode CHECK -TaskIdentifier "1.2.3" -Force
```

### Mode GRAN adapté
Le mode GRAN adapté (`development\scripts\maintenance\modes\gran-mode.ps1`) décompose les tâches en sous-tâches plus granulaires directement dans le document. Cette version adaptée utilise la configuration unifiée pour déterminer les chemins des fichiers, les styles d'indentation, etc.

```powershell
# Exécuter le mode GRAN adapté directement
.\development\scripts\maintenance\modes\gran-mode.ps1 -TaskIdentifier "1.2.3" -SubTasksFile "templates\subtasks.txt"

# Exécuter le mode GRAN adapté via le gestionnaire intégré
.\development\scripts\integrated-manager.ps1 -Mode GRAN -TaskIdentifier "1.2.3" -SubTasksFile "templates\subtasks.txt"
```

### Mode ROADMAP-SYNC
Le mode ROADMAP-SYNC (`development\scripts\maintenance\modes\roadmap-sync-mode.ps1`) permet de synchroniser les roadmaps entre différents formats (Markdown, JSON, HTML, CSV). Il est utile pour maintenir la cohérence entre les différentes représentations de la roadmap.

```powershell
# Exécuter le mode ROADMAP-SYNC directement
.\development\scripts\maintenance\modes\roadmap-sync-mode.ps1 -SourcePath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TargetFormat "JSON"

# Exécuter le mode ROADMAP-SYNC via le gestionnaire intégré
.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-SYNC -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TargetFormat "JSON"
```

### Mode ROADMAP-REPORT
Le mode ROADMAP-REPORT (`development\scripts\maintenance\modes\roadmap-report-mode.ps1`) génère des rapports détaillés sur l'état d'avancement des roadmaps. Il fournit des informations sur l'état des tâches, les tendances, les prévisions, etc.

```powershell
# Exécuter le mode ROADMAP-REPORT directement
.\development\scripts\maintenance\modes\roadmap-report-mode.ps1 -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -ReportFormat "HTML"

# Exécuter le mode ROADMAP-REPORT via le gestionnaire intégré
.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-REPORT -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -ReportFormat "HTML"
```

### Mode ROADMAP-PLAN
Le mode ROADMAP-PLAN (`development\scripts\maintenance\modes\roadmap-plan-mode.ps1`) planifie les tâches futures en fonction de l'état actuel de la roadmap. Il analyse l'état d'avancement, identifie les dépendances et propose un plan d'action.

```powershell
# Exécuter le mode ROADMAP-PLAN directement
.\development\scripts\maintenance\modes\roadmap-plan-mode.ps1 -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -DaysToForecast 30

# Exécuter le mode ROADMAP-PLAN via le gestionnaire intégré
.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-PLAN -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -DaysToForecast 30
```

## Intégration avec d'autres composants

Le Gestionnaire Intégré s'intègre avec les composants suivants :

### Mode Manager
Le Gestionnaire Intégré utilise le Mode Manager pour exécuter les modes opérationnels. Il appelle le script `mode-manager.ps1` avec les paramètres appropriés.

### Roadmap Manager
Le Gestionnaire Intégré utilise le Roadmap Manager pour gérer les roadmaps. Il appelle les scripts `RoadmapAnalyzer.ps1`, `RoadmapGitUpdater.ps1`, etc. avec les paramètres appropriés.

### Roadmap Parser
Le Gestionnaire Intégré utilise indirectement le Roadmap Parser via le Mode Manager pour analyser et manipuler les roadmaps.

## Dépannage

### Problèmes courants et solutions

#### Le script ne trouve pas les fichiers de configuration
Vérifiez que le fichier `development\config\unified-config.json` existe et est accessible. Si ce n'est pas le cas, vous pouvez spécifier un chemin de configuration personnalisé avec le paramètre `-ConfigPath`.

#### Le script ne trouve pas les scripts du Mode Manager ou du Roadmap Manager
Vérifiez que les scripts `development\scripts\manager\mode-manager.ps1` et `projet\roadmaps\scripts\RoadmapManager.ps1` existent et sont accessibles. Si ce n'est pas le cas, vous devrez peut-être mettre à jour les chemins dans le fichier de configuration.

#### Un mode ou un workflow échoue
Vérifiez les messages d'erreur pour déterminer la cause de l'échec. Vous pouvez également exécuter le mode ou le workflow avec le paramètre `-Force` pour ignorer certaines vérifications.

#### Le script ne trouve pas les roadmaps
Vérifiez que les chemins des roadmaps dans le fichier de configuration sont corrects. Vous pouvez également utiliser le paramètre `-ListRoadmaps` pour afficher la liste des roadmaps disponibles.

## Bonnes pratiques
- Utilisez le Gestionnaire Intégré comme point d'entrée unique pour tous les modes opérationnels et les roadmaps
- Créez des workflows personnalisés en fonction de vos besoins
- Maintenez à jour la configuration dans le fichier `unified-config.json`
- Utilisez le mode interactif pour explorer les fonctionnalités du Gestionnaire Intégré
- Documentez les workflows que vous créez pour faciliter leur réutilisation
- Utilisez le paramètre `-Force` avec précaution, car il peut entraîner des modifications sans confirmation

## Exemples avancés

### Créer un workflow personnalisé
Pour créer un workflow personnalisé, ajoutez une nouvelle entrée dans la section `Workflows` du fichier de configuration :

```json
"MonWorkflow": {
  "Description": "Mon workflow personnalisé",
  "Modes": ["GRAN", "DEV-R", "OPTI", "TEST", "CHECK"],
  "AutoContinue": true,
  "StopOnError": true
}
```

Vous pouvez ensuite exécuter ce workflow avec la commande suivante :

```powershell
.\development\scripts\integrated-manager.ps1 -Workflow "MonWorkflow" -RoadmapPath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3"
```

### Exécuter un mode avec des paramètres personnalisés
Pour exécuter un mode avec des paramètres personnalisés, vous pouvez modifier la configuration du mode dans le fichier de configuration, puis exécuter le mode avec la commande suivante :

```powershell
.\development\scripts\integrated-manager.ps1 -Mode "GRAN" -RoadmapPath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3" -ConfigPath "mon-config.json"
```

### Analyser plusieurs roadmaps
Pour analyser plusieurs roadmaps, vous pouvez exécuter le script plusieurs fois avec des chemins de roadmap différents :

```powershell
.\development\scripts\integrated-manager.ps1 -Analyze -RoadmapPath "projet\roadmaps\Roadmap\roadmap_perso.md"
.\development\scripts\integrated-manager.ps1 -Analyze -RoadmapPath "projet\roadmaps\plans\plan-modes-stepup.md"
```

## Tests

Le Gestionnaire Intégré est accompagné d'une suite de tests qui vérifient son bon fonctionnement. Ces tests se trouvent dans le répertoire `development\scripts\manager\tests\`.

### Tests du Gestionnaire Intégré
Le script `Test-IntegratedManager.ps1` vérifie que le Gestionnaire Intégré fonctionne correctement en testant ses fonctionnalités de base, comme l'exécution de modes, de workflows, l'analyse de roadmaps, etc.

```powershell
# Exécuter les tests du Gestionnaire Intégré
Invoke-Pester -Script "development\scripts\manager\tests\Test-IntegratedManager.ps1" -Output Detailed
```

### Tests des Modes Adaptés
Le script `Test-IntegratedManagerModes.ps1` vérifie que le Gestionnaire Intégré fonctionne correctement avec les modes adaptés pour utiliser la configuration unifiée.

```powershell
# Exécuter les tests des Modes Adaptés
Invoke-Pester -Script "development\scripts\manager\tests\Test-IntegratedManagerModes.ps1" -Output Detailed
```

### Exécuter tous les tests
Pour exécuter tous les tests du Gestionnaire Intégré, vous pouvez utiliser la commande suivante :

```powershell
# Exécuter tous les tests du Gestionnaire Intégré
Invoke-Pester -Script "development\scripts\manager\tests\Test-*.ps1" -Output Detailed
```

## Conclusion
Le Gestionnaire Intégré est un outil puissant qui unifie les fonctionnalités du Mode Manager et du Roadmap Manager. Il offre une interface unique pour gérer à la fois les modes opérationnels et les roadmaps du projet, simplifiant ainsi la gestion du projet. Grâce à la configuration unifiée et aux modes adaptés, il permet une intégration harmonieuse entre les différents composants du système.
