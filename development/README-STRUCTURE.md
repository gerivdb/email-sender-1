# Structure du projet

Ce document explique la structure du projet après la réorganisation effectuée pour éliminer les redondances, ambiguïtés et doublons.

## Principes de la réorganisation

1. **Clarté conceptuelle** : Distinction claire entre "ce que nous construisons" (src) et "comment nous le construisons" (development)
2. **Organisation logique** : Regroupement des fichiers par fonction et domaine
3. **Élimination des redondances** : Fusion des dossiers ayant des fonctions similaires
4. **Simplification** : Réduction du nombre de dossiers à la racine
5. **Standardisation** : Utilisation de conventions de nommage cohérentes

## Structure principale

- **src/** - Code source principal de l'application
- **development/** - Tout ce qui concerne le développement
- **projet/** - Tout ce qui concerne le projet lui-même
- **logs/** - Logs
- **node_modules/** - Dépendances Node.js

## Structure détaillée

### development/

Le dossier `development` contient tous les éléments liés au développement du projet :

#### Scripts

Le dossier `development/scripts` contient tous les scripts utilisés pour le développement, la maintenance et l'automatisation du projet. Les scripts sont organisés par catégorie :

- **analysis/** - Scripts d'analyse de code et de performance
- **analytics/** - Scripts d'analyse de données
- **api/** - Scripts d'API
- **automation/** - Scripts d'automatisation
- **batch/** - Scripts batch (.bat)
- **ci/** - Scripts d'intégration continue
- **core/** - Scripts de base
- **debug/** - Scripts de débogage
- **deployment/** - Scripts de déploiement
- **documentation/** - Scripts liés à la documentation
- **email/** - Scripts liés aux emails
- **examples/** - Exemples de scripts
- **gui/** - Scripts d'interface graphique
- **integration/** - Scripts d'intégration
- **journal/** - Scripts de journalisation
- **maintenance/** - Scripts de maintenance
  - **augment/** - Scripts liés à Augment
  - **cleanup/** - Scripts de nettoyage
  - **modes/** - Scripts de modes opérationnels
  - **references/** - Scripts de mise à jour des références
  - **registry/** - Scripts liés au registre
  - **repo/** - Scripts de maintenance du repository
  - **services/** - Scripts liés aux services
  - **vscode/** - Scripts liés à VS Code
- **manager/** - Scripts de gestion
- **mcp/** - Scripts MCP
- **monitoring/** - Scripts de surveillance
- **n8n/** - Scripts n8n
- **network/** - Scripts réseau
- **node/** - Scripts Node.js
- **performance/** - Scripts de performance
- **python/** - Scripts Python
- **reporting/** - Scripts de reporting
# Ces dossiers ont été déplacés vers development/roadmap/scripts et development/roadmap/parser

- **setup/** - Scripts d'installation
- **templates/** - Scripts de templates
- **testing/** - Scripts de test
  - **tests/** - Tests unitaires
  - **integration/** - Tests d'intégration
- **utils/** - Scripts utilitaires
- **visualization/** - Scripts de visualisation
- **workflow/** - Scripts de workflow

#### Templates

Le dossier `development/templates` contient tous les templates utilisés dans le projet :

- **hygen/** - Templates Hygen pour la génération de code
- **reports/** - Templates pour les rapports
- **charts/** - Templates pour les graphiques
- **dashboards/** - Templates pour les tableaux de bord
- **code/** - Templates pour le code

#### Testing

Le dossier `development/testing` contient tous les éléments liés aux tests :

- **tests/** - Tests unitaires, d'intégration, etc.
- **reports/** - Rapports de tests
- **performance/** - Tests de performance
- **analytics/** - Analyse de tests

#### Roadmap

Le dossier `development/roadmap` contient les outils et scripts pour gérer et analyser les roadmaps du projet :

- **declarations/** - Déclarations et exemples pour la roadmap (anciennement Roadmap)
- **parser/** - Outils d'analyse et de parsing de la roadmap (anciennement dans development/scripts/roadmap-parser)
- **scripts/** - Scripts liés à la roadmap (anciennement dans development/scripts/roadmap)
- **tools/** - Outils pour la roadmap (anciennement dans development/tools/roadmap-tools)

Note: Les roadmaps et plans du projet ont été déplacés vers le dossier `projet/roadmaps`.

#### Tools

Le dossier `development/tools` contient tous les outils utilisés pour le développement :

- **analysis/** - Outils d'analyse de code et de performance
- **augment/** - Configuration et outils pour Augment

#### Documentation

Le dossier `development/docs` contient la documentation technique du projet :

- **augment/** - Documentation liée à Augment
- **api/** - Documentation de l'API
- **architecture/** - Documentation de l'architecture
- **guides/** - Guides pour les développeurs

### projet/

Le dossier `projet` contient tous les éléments liés au projet lui-même :

- **architecture/** - Architecture du projet
- **assets/** - Ressources statiques
- **config/** - Configuration du projet
- **documentation/** - Documentation utilisateur
- **guides/** - Guides utilisateur
- **roadmaps/** - Roadmaps du projet, plans et documents de référence (contient les éléments déplacés depuis development/roadmap)
- **specifications/** - Spécifications du projet
- **tutorials/** - Tutoriels

## Bonnes pratiques

1. **Respecter la structure** : Placer les nouveaux fichiers dans les dossiers appropriés
2. **Utiliser les scripts d'organisation** : Utiliser le script `development/scripts/maintenance/repo/organize-scripts.ps1` pour organiser automatiquement les scripts
3. **Créer de nouveaux scripts** : Utiliser le script `development/scripts/maintenance/repo/new-script.ps1` pour créer de nouveaux scripts
4. **Mettre à jour les références** : Après avoir déplacé des fichiers, utiliser les scripts suivants pour mettre à jour les références :
   - `development/scripts/maintenance/references/update-structure-references-2.ps1` pour les changements de structure généraux
   - `development/scripts/maintenance/references/update-roadmap-references.ps1` pour les changements liés à la roadmap
   - `development/scripts/maintenance/references/update-roadmap-structure-references.ps1` pour les changements de structure de la roadmap
   - `development/scripts/maintenance/references/update-roadmap-declarations-references.ps1` pour le renommage du dossier Roadmap en declarations
5. **Documenter les changements** : Mettre à jour ce document lorsque la structure du projet change

