# Standard de Structure du Dépôt

## Introduction

Ce document définit la structure standardisée du dépôt pour le projet EMAIL_SENDER_1. Il établit les conventions pour l'organisation des dossiers, le nommage des fichiers et le placement des scripts afin d'améliorer la maintenabilité, la lisibilité et la qualité du code.

## Objectifs

- Établir une structure de dossiers cohérente et intuitive
- Définir des conventions de nommage claires pour les fichiers et dossiers
- Faciliter la navigation et la recherche dans le dépôt
- Réduire la duplication et la prolifération des scripts
- Améliorer la maintenabilité à long terme du projet

## Structure des Dossiers Principaux

| Dossier | Description | Contenu |
|---------|-------------|---------|
| `scripts` | Scripts du projet | Scripts PowerShell, Python, Batch et autres scripts utilitaires |
| `modules` | Modules réutilisables | Modules PowerShell, bibliothèques Python et autres composants réutilisables |
| `projet/documentation` | Documentation | Documentation technique, guides d'utilisation, références API |
| `tests` | Tests | Tests unitaires, tests d'intégration, tests de performance |
| `config` | Configuration | Fichiers de configuration pour différents environnements |
| `assets` | Ressources | Images, fichiers CSS, polices et autres ressources statiques |
| `tools` | Outils | Outils tiers et utilitaires spécifiques au projet |
| `logs` | Journaux | Fichiers de journalisation (générés automatiquement) |
| `reports` | Rapports | Rapports générés par les scripts d'analyse |
| `.github` | GitHub | Workflows GitHub Actions, templates d'issues et de PR |
| `.vscode` | VS Code | Configuration VS Code spécifique au projet |
| `Roadmap` | Roadmap | Fichiers de roadmap et de planification |

## Structure des Sous-Dossiers

### Scripts

Les scripts sont organisés par domaine fonctionnel :

| Sous-dossier | Description |
|--------------|-------------|
| `development/scripts/analysis` | Scripts d'analyse de code et de données |
| `development/scripts/automation` | Scripts d'automatisation de tâches |
| `development/scripts/gui` | Scripts avec interface graphique |
| `development/scripts/integration` | Scripts d'intégration avec d'autres systèmes |
| `development/scripts/maintenance` | Scripts de maintenance du dépôt |
| `development/scripts/setup` | Scripts d'installation et de configuration |
| `development/scripts/utils` | Scripts utilitaires génériques |

Chaque sous-dossier peut contenir des sous-dossiers supplémentaires pour une organisation plus fine.

### Modules

Les modules sont organisés par langage et fonctionnalité :

| Sous-dossier | Description |
|--------------|-------------|
| `modules/PowerShell` | Modules PowerShell |
| `modules/Python` | Modules Python |
| `modules/Common` | Modules communs à plusieurs langages |

### Documentation

La documentation est organisée par type :

| Sous-dossier | Description |
|--------------|-------------|
| `projet/guides` | Guides d'utilisation |
| `development/api` | Documentation API |
| `projet/documentation/development` | Documentation pour les développeurs |
| `projet/architecture` | Documentation d'architecture |

### Tests

Les tests sont organisés par type et par composant testé :

| Sous-dossier | Description |
|--------------|-------------|
| `development/testing/tests/unit` | Tests unitaires |
| `development/testing/tests/integration` | Tests d'intégration |
| `development/testing/tests/performance` | Tests de performance |
| `development/testing/tests/fixtures` | Données de test |

## Conventions de Nommage

### Dossiers

- Utiliser des noms en minuscules avec des tirets pour séparer les mots (kebab-case)
- Exemple : `error-management`, `script-inventory`

### Fichiers

#### Scripts PowerShell

- Utiliser le format Verbe-Nom.ps1 avec PascalCase
- Les verbes doivent être des verbes PowerShell approuvés
- Exemples : `Get-ScriptInventory.ps1`, `Update-Configuration.ps1`

#### Scripts Python

- Utiliser des noms en minuscules avec des underscores pour séparer les mots (snake_case)
- Exemples : `script_inventory.py`, `error_handler.py`

#### Scripts Batch

- Utiliser des noms en minuscules avec des tirets pour séparer les mots (kebab-case)
- Exemples : `start-service.cmd`, `setup-environment.bat`

#### Documentation

- Utiliser des noms descriptifs en PascalCase pour les fichiers Markdown
- Exemples : `UserGuide.md`, `ApiReference.md`

#### Fichiers de Configuration

- Utiliser des noms en minuscules avec des tirets pour séparer les mots (kebab-case)
- Inclure l'environnement dans le nom si applicable
- Exemples : `config-dev.json`, `settings-prod.yaml`

## Règles de Placement des Scripts

### Règles Générales

1. Chaque script doit être placé dans le sous-dossier correspondant à sa fonction principale
2. Les scripts partagés entre plusieurs domaines doivent être placés dans `development/scripts/utils`
3. Les scripts spécifiques à un domaine doivent être placés dans le sous-dossier correspondant
4. Les scripts d'installation doivent être placés dans `development/scripts/setup`
5. Les scripts de maintenance doivent être placés dans `development/scripts/maintenance`

### Règles Spécifiques

1. **Scripts d'analyse** : Tous les scripts d'analyse doivent être placés dans `development/scripts/analysis`
   - Analyse de code : `development/scripts/analysis/code`
   - Analyse de données : `development/scripts/analysis/data`
   - Analyse de performance : `development/scripts/analysis/performance`

2. **Scripts d'automatisation** : Tous les scripts d'automatisation doivent être placés dans `development/scripts/automation`
   - Tâches planifiées : `development/scripts/automation/scheduled`
   - Surveillance : `development/scripts/automation/monitoring`
   - Déploiement : `development/scripts/automation/deployment`

3. **Scripts d'intégration** : Tous les scripts d'intégration doivent être placés dans `development/scripts/integration`
   - Intégration Git : `development/scripts/integration/git`
   - Intégration API : `development/scripts/integration/api`
   - Intégration CI/CD : `development/scripts/integration/cicd`

4. **Scripts GUI** : Tous les scripts avec interface graphique doivent être placés dans `development/scripts/gui`

5. **Scripts de test** : Tous les scripts de test doivent être placés dans `tests` et non dans `development/scripts/tests`

## Métadonnées des Scripts

Chaque script doit inclure des métadonnées standardisées dans son en-tête :

### PowerShell

```powershell
<#
.SYNOPSIS
    Brève description du script
.DESCRIPTION
    Description détaillée du script
.PARAMETER Param1
    Description du paramètre 1
.PARAMETER Param2
    Description du paramètre 2
.EXAMPLE
    Exemple d'utilisation
.NOTES
    Auteur: Nom de l'auteur
    Version: 1.0
    Date de création: YYYY-MM-DD
    Date de modification: YYYY-MM-DD
    Tags: tag1, tag2, tag3
#>
```

### Python

```python
"""
Script Name: script_name.py
Description: Description détaillée du script
Author: Nom de l'auteur
Version: 1.0
Created: YYYY-MM-DD
Modified: YYYY-MM-DD
Tags: tag1, tag2, tag3

Usage:
    python script_name.py [arguments]

Parameters:
    param1 - Description du paramètre 1
    param2 - Description du paramètre 2

Examples:
    python script_name.py param1 param2
"""
```

## Gestion des Versions

- Chaque script doit inclure un numéro de version dans ses métadonnées
- Le format de version doit suivre le versionnage sémantique (MAJOR.MINOR.PATCH)
- Les changements majeurs doivent incrémenter MAJOR
- Les nouvelles fonctionnalités compatibles doivent incrémenter MINOR
- Les corrections de bugs doivent incrémenter PATCH

## Validation de la Structure

La structure du dépôt doit être validée régulièrement à l'aide du script `Test-RepoStructure.ps1` pour s'assurer de sa conformité avec ce standard.

## Migration et Conformité

La migration vers cette structure standardisée doit être effectuée progressivement en utilisant le script `Reorganize-Repository.ps1`. Les nouveaux scripts doivent être créés conformément à ce standard dès le départ.

## Exceptions

Toute exception à ces règles doit être documentée et justifiée dans un fichier `EXCEPTIONS.md` à la racine du dépôt.

## Révisions

Ce standard est sujet à révision. Les modifications doivent être proposées via des pull requests et approuvées par l'équipe de développement.

| Version | Date | Auteur | Description |
|---------|------|--------|-------------|
| 1.0 | 2025-04-26 | Augment Agent | Version initiale |
