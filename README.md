# EMAIL_SENDER_1

## Structure du projet

La structure du projet a été réorganisée pour une meilleure organisation et maintenabilité, avec une distinction claire entre les éléments liés au développement et les éléments liés au projet lui-même :

### Structure principale

- **src/** - Code source principal de l'application
  - **core/** - Fonctionnalités de base
  - **modules/** - Modules fonctionnels
  - **api/** - API et interfaces

- **development/** - Tout ce qui concerne le développement
  - **api/** - Documentation API
  - **communications/** - Communications
  - **docs/** - Documentation technique
    - **augment/** - Documentation Augment
  - **methodologies/** - Méthodologies
  - **n8n-internals/** - Internals de n8n
  - **reporting/** - Rapports
  - **roadmap/** - Roadmap de développement
  - **scripts/** - Scripts
    - **backups/** - Fichiers de sauvegarde (.bak)
    - **batch/** - Scripts batch (.bat)
    - **maintenance/** - Scripts de maintenance
      - **augment/** - Scripts liés à Augment
      - **references/** - Scripts de mise à jour des références
      - **registry/** - Scripts liés au registre
      - **repo/** - Scripts de maintenance du repository
      - **vscode/** - Scripts liés à VS Code
    - **modules/** - Modules PowerShell (.psm1, .psd1)
  - **templates/** - Templates
    - **hygen/** - Templates Hygen
  - **testing/** - Tests et rapports de tests
    - **reports/** - Rapports de tests
    - **tests/** - Tests
  - **tools/** - Outils
  - **workflows/** - Workflows

- **projet/** - Tout ce qui concerne le projet lui-même
  - **architecture/** - Architecture
  - **assets/** - Ressources statiques
  - **config/** - Configuration
  - **documentation/** - Documentation
    - **config/** - Configuration de documentation
  - **guides/** - Guides
  - **roadmaps/** - Roadmaps du projet
    - **plans/** - Plans
  - **specifications/** - Spécifications
  - **tutorials/** - Tutoriels

- **.build/** - Fichiers de build et CI/CD
- **logs/** - Logs
- **node_modules/** - Dépendances Node.js

## Outils de gestion automatique des scripts

Le projet est configuré avec plusieurs outils pour gérer automatiquement les scripts et maintenir une structure de dossiers propre :

### 1. Organisation automatique des scripts

Un script PowerShell est configuré pour déplacer automatiquement les fichiers scripts (PS1, PSM1, PSD1, BAK, BAT) de la racine du projet vers les dossiers appropriés dans la structure `development/scripts`.

**Utilisation manuelle :**
```powershell
.\development\scripts\maintenance\repo\organize-scripts.ps1
```

### 2. Création de nouveaux scripts

Un script PowerShell est disponible pour créer facilement de nouveaux scripts au bon endroit dans la structure du projet :

**Utilisation :**
```powershell
.\development\scripts\maintenance\repo\new-script.ps1 -Name nom-du-script -Category maintenance/sous-dossier -Description "Description du script" -Author "Votre Nom"
```

### 3. Pre-commit Hook avec Husky

Un hook pre-commit a été configuré pour exécuter automatiquement le script d'organisation avant chaque commit. Cela garantit que les scripts sont toujours placés au bon endroit.

### 4. VS Code Task

Une tâche VS Code a été configurée pour exécuter automatiquement le script d'organisation à l'ouverture du projet. Vous pouvez également l'exécuter manuellement depuis la palette de commandes de VS Code.

### 5. Initialisation du projet

Pour initialiser le projet pour le développement, exécutez le script suivant :

```powershell
.\development\scripts\maintenance\repo\initialize-project.ps1
```

Ce script installe les dépendances, configure les hooks Git et organise les fichiers.

## Gestionnaire intégré

Le projet utilise un gestionnaire intégré qui unifie les fonctionnalités du Mode Manager et du Roadmap Manager pour offrir une interface unique pour la gestion des modes opérationnels et des roadmaps.

### Fonctionnalités principales

- Exécution des modes opérationnels (CHECK, GRAN, DEV-R, TEST, etc.)
- Gestion des roadmaps (synchronisation, rapports, planification)
- Exécution de workflows prédéfinis
- Automatisation des tâches récurrentes

### Utilisation de base

```powershell
# Exécuter un mode
.\development\scripts\integrated-manager.ps1 -Mode CHECK -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TaskIdentifier "1.2.3"

# Exécuter un workflow
.\development\scripts\integrated-manager.ps1 -Workflow "RoadmapManagement" -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md"

# Afficher la liste des modes disponibles
.\development\scripts\integrated-manager.ps1 -ListModes

# Afficher la liste des workflows disponibles
.\development\scripts\integrated-manager.ps1 -ListWorkflows
```

### Workflows automatisés

Le gestionnaire intégré propose des workflows automatisés pour la gestion des roadmaps :

```powershell
# Exécuter le workflow quotidien
.\development\scripts\workflows\workflow-quotidien.ps1

# Exécuter le workflow hebdomadaire
.\development\scripts\workflows\workflow-hebdomadaire.ps1

# Exécuter le workflow mensuel
.\development\scripts\workflows\workflow-mensuel.ps1

# Installer les tâches planifiées
.\development\scripts\workflows\install-scheduled-tasks.ps1
```

### Documentation

Pour plus d'informations sur le gestionnaire intégré, consultez les guides suivants :

- [Guide d'utilisation complet](development/docs/guides/user-guides/integrated-manager-guide.md)
- [Guide de démarrage rapide](development/docs/guides/user-guides/integrated-manager-quickstart.md)
- [Référence des paramètres](development/docs/guides/reference/integrated-manager-parameters.md)
- [Exemples d'utilisation des modes de roadmap](development/docs/guides/examples/roadmap-modes-examples.md)
- [Bonnes pratiques pour la gestion des roadmaps](development/docs/guides/best-practices/roadmap-management.md)
- [Workflows automatisés](development/docs/guides/automation/roadmap-workflows.md)

## Installation

### Installation rapide du gestionnaire intégré

Pour installer rapidement le gestionnaire intégré, exécutez le script d'installation rapide :

```powershell
# Installation avec les paramètres par défaut
.\development\scripts\maintenance\install-integrated-manager.ps1

# Installation avec des paramètres personnalisés
.\development\scripts\maintenance\install-integrated-manager.ps1 -RoadmapPath "projet\roadmaps\mes-plans\roadmap_perso.md" -InstallScheduledTasks $false

# Installation avec remplacement des fichiers existants
.\development\scripts\maintenance\install-integrated-manager.ps1 -Force
```

Ce script effectue les opérations suivantes :
1. Vérifie que PowerShell 5.1 ou supérieur est installé
2. Installe le module Pester s'il n'est pas déjà installé
3. Crée les répertoires nécessaires
4. Crée un fichier de roadmap de test si nécessaire
5. Crée ou met à jour le fichier de configuration
6. Installe les tâches planifiées si demandé
7. Vérifie l'installation

### Vérification de l'installation

Pour vérifier que le gestionnaire intégré est correctement installé, exécutez le script de vérification :

```powershell
.\development\scripts\maintenance\verify-installation.ps1
```

Ce script vérifie que tous les composants nécessaires sont correctement installés et configurés.

### Désinstallation

Pour désinstaller le gestionnaire intégré, exécutez le script de désinstallation :

```powershell
# Désinstallation des tâches planifiées uniquement
.\development\scripts\maintenance\uninstall-integrated-manager.ps1

# Désinstallation complète (tâches planifiées et fichiers)
.\development\scripts\maintenance\uninstall-integrated-manager.ps1 -RemoveFiles -Force
```

Pour plus d'informations sur l'installation, consultez le guide d'installation dans `projet/guides/installation/`.

## Documentation

La documentation complète est disponible dans les dossiers `projet/documentation/` et `development/docs/`.

## Développement

Consultez le guide du développeur dans `projet/guides/developer/`.

## Tests

Les tests sont disponibles dans le dossier `development/testing/`.

## Licence

Ce projet est sous licence MIT.
