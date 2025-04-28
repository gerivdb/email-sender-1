# EMAIL_SENDER_1

## Structure du projet

La structure du projet a Ã©tÃ© rÃ©organisÃ©e pour une meilleure organisation et maintenabilitÃ©, avec une distinction claire entre les Ã©lÃ©ments liÃ©s au dÃ©veloppement et les Ã©lÃ©ments liÃ©s au projet lui-mÃªme :

### Structure principale

- **src/** - Code source principal de l'application
  - **core/** - FonctionnalitÃ©s de base
  - **modules/** - Modules fonctionnels
  - **api/** - API et interfaces

- **development/** - Tout ce qui concerne le dÃ©veloppement
  - **api/** - Documentation API
  - **communications/** - Communications
  - **docs/** - Documentation technique
    - **augment/** - Documentation Augment
  - **methodologies/** - MÃ©thodologies
  - **n8n-internals/** - Internals de n8n
  - **reporting/** - Rapports
  - **roadmap/** - Roadmap de dÃ©veloppement
  - **scripts/** - Scripts
    - **backups/** - Fichiers de sauvegarde (.bak)
    - **batch/** - Scripts batch (.bat)
    - **maintenance/** - Scripts de maintenance
      - **augment/** - Scripts liÃ©s Ã  Augment
      - **references/** - Scripts de mise Ã  jour des rÃ©fÃ©rences
      - **registry/** - Scripts liÃ©s au registre
      - **repo/** - Scripts de maintenance du repository
      - **vscode/** - Scripts liÃ©s Ã  VS Code
    - **modules/** - Modules PowerShell (.psm1, .psd1)
  - **templates/** - Templates
    - **hygen/** - Templates Hygen
  - **testing/** - Tests et rapports de tests
    - **reports/** - Rapports de tests
    - **tests/** - Tests
  - **tools/** - Outils
  - **workflows/** - Workflows

- **projet/** - Tout ce qui concerne le projet lui-mÃªme
  - **architecture/** - Architecture
  - **assets/** - Ressources statiques
  - **config/** - Configuration
  - **documentation/** - Documentation
    - **config/** - Configuration de documentation
  - **guides/** - Guides
  - **roadmaps/** - Roadmaps du projet
    - **plans/** - Plans
  - **specifications/** - SpÃ©cifications
  - **tutorials/** - Tutoriels

- **.build/** - Fichiers de build et CI/CD
- **logs/** - Logs
- **node_modules/** - DÃ©pendances Node.js

## Outils de gestion automatique des scripts

Le projet est configurÃ© avec plusieurs outils pour gÃ©rer automatiquement les scripts et maintenir une structure de dossiers propre :

### 1. Organisation automatique des scripts

Un script PowerShell est configurÃ© pour dÃ©placer automatiquement les fichiers scripts (PS1, PSM1, PSD1, BAK, BAT) de la racine du projet vers les dossiers appropriÃ©s dans la structure `development/scripts`.

**Utilisation manuelle :**
```powershell
.\development\scripts\maintenance\repo\organize-scripts.ps1
```

### 2. CrÃ©ation de nouveaux scripts

Un script PowerShell est disponible pour crÃ©er facilement de nouveaux scripts au bon endroit dans la structure du projet :

**Utilisation :**
```powershell
.\development\scripts\maintenance\repo\new-script.ps1 -Name nom-du-script -Category maintenance/sous-dossier -Description "Description du script" -Author "Votre Nom"
```

### 3. Pre-commit Hook avec Husky

Un hook pre-commit a Ã©tÃ© configurÃ© pour exÃ©cuter automatiquement le script d'organisation avant chaque commit. Cela garantit que les scripts sont toujours placÃ©s au bon endroit.

### 4. VS Code Task

Une tÃ¢che VS Code a Ã©tÃ© configurÃ©e pour exÃ©cuter automatiquement le script d'organisation Ã  l'ouverture du projet. Vous pouvez Ã©galement l'exÃ©cuter manuellement depuis la palette de commandes de VS Code.

### 5. Initialisation du projet

Pour initialiser le projet pour le dÃ©veloppement, exÃ©cutez le script suivant :

```powershell
.\development\scripts\maintenance\repo\initialize-project.ps1
```

Ce script installe les dÃ©pendances, configure les hooks Git et organise les fichiers.

## Installation

Consultez le guide d'installation dans `projet/guides/installation/`.

## Documentation

La documentation complÃ¨te est disponible dans les dossiers `projet/documentation/` et `development/docs/`.

## DÃ©veloppement

Consultez le guide du dÃ©veloppeur dans `projet/guides/developer/`.

## Tests

Les tests sont disponibles dans le dossier `development/testing/`.

## Licence

Ce projet est sous licence MIT.

