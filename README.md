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

## Installation

Consultez le guide d'installation dans `projet/guides/installation/`.

## Documentation

La documentation complète est disponible dans les dossiers `projet/documentation/` et `development/docs/`.

## Développement

Consultez le guide du développeur dans `projet/guides/developer/`.

## Tests

Les tests sont disponibles dans le dossier `development/testing/`.

## Licence

Ce projet est sous licence MIT.
