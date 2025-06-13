# Dossier `development`

Ce dossier contient tous les éléments liés au développement du projet, y compris la documentation technique, les scripts, les outils et les tests.

## Structure

### Documentation

- **api/** : Documentation de l'API et exemples
  - **examples/** : Exemples d'utilisation de l'API
  - **documentation/** : Documentation de l'API
- **communications/** : Communications internes et externes
- **docs/** : Documentation technique
  - **augment/** : Documentation liée à Augment
  - **architecture/** : Documentation de l'architecture
  - **guides/** : Guides pour les développeurs
- **n8n-internals/** : Documentation interne de n8n
- **roadmap/** : Analyse, journal et plans de la feuille de route
  - **analysis/** : Analyse de la feuille de route
  - **journal/** : Journal de développement
  - **plans/** : Plans de développement
  - **tasks/** : Tâches de développement
- **methodologies/** : Méthodologies de développement et modes opératoires
  - **modes/** : Modes opératoires
- **workflows/** : Documentation des workflows

### Scripts

Le dossier `scripts` contient tous les scripts utilisés pour le développement, la maintenance et l'automatisation du projet. Les scripts sont organisés par catégorie :

- **backups/** : Fichiers de sauvegarde (.bak)
- **batch/** : Scripts batch (.bat)
- **documentation/** : Scripts liés à la documentation
- **maintenance/** : Scripts de maintenance
  - **augment/** : Scripts liés à Augment
  - **references/** : Scripts de mise à jour des références
  - **registry/** : Scripts liés au registre
  - **repo/** : Scripts de maintenance du repository
  - **vscode/** : Scripts liés à VS Code
- **modules/** : Modules PowerShell (.psm1, .psd1)

### Templates

Le dossier `templates` contient tous les templates utilisés dans le projet :

- **hygen/** : Templates Hygen pour la génération de code
- **reports/** : Templates pour les rapports
- **charts/** : Templates pour les graphiques
- **dashboards/** : Templates pour les tableaux de bord
- **code/** : Templates pour le code

### Testing

Le dossier `testing` contient tous les éléments liés aux tests :

- **tests/** : Tests unitaires, d'intégration, etc.
- **reports/** : Rapports de tests
- **performance/** : Tests de performance

### Tools

Le dossier `tools` contient tous les outils utilisés pour le développement :

- **analysis/** : Outils d'analyse de code et de performance
- **augment/** : Configuration et outils pour Augment

## Bonnes pratiques

1. **Organisation des scripts** : Tous les scripts doivent être placés dans le dossier approprié dans `scripts/`. Utilisez le script `scripts/maintenance/repo/organize-scripts.ps1` pour organiser automatiquement les scripts.

2. **Génération de code** : Utilisez les templates Hygen dans `templates/hygen/` pour générer du code. Utilisez le script `scripts/maintenance/repo/new-script.ps1` pour créer de nouveaux scripts.

3. **Tests** : Tous les tests doivent être placés dans le dossier `testing/tests/`. Les rapports de tests doivent être placés dans `testing/reports/`.

4. **Documentation** : Toute la documentation technique doit être placée dans le dossier `docs/`. La documentation utilisateur doit être placée dans `projet/documentation/`.

## Utilisation

### Création de documents

Pour ajouter de nouveaux documents à cette structure, utilisez Hygen :

```powershell
# Créer un nouveau document dans la structure

hygen doc-structure new --docType "development" --category "api" --subcategory "examples"
```plaintext
### Création de scripts

Pour créer un nouveau script PowerShell, utilisez le script `new-script.ps1` :

```powershell
# Créer un nouveau script PowerShell

.\development\scripts\maintenance\repo\new-script.ps1 -Name "nom-du-script" -Category "maintenance/sous-dossier" -Description "Description du script" -Author "Votre Nom"
```plaintext
### Organisation des scripts

Pour organiser automatiquement les scripts, utilisez le script `organize-scripts.ps1` :

```powershell
# Organiser les scripts

.\development\scripts\maintenance\repo\organize-scripts.ps1
```plaintext