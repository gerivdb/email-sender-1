# Documentation

Ce répertoire contient la documentation du projet.

## Nouvelle Structure de Documentation

La documentation a été réorganisée selon une nouvelle structure pour améliorer la lisibilité et la maintenance. Les documents sont maintenant répartis entre deux dossiers principaux :

### Dossier `projet`

Contient la documentation relative au projet lui-même :

- **architecture** : Diagrammes et décisions d'architecture
- **documentation** : Documentation générale du projet
- **guides** : Guides d'utilisation et d'installation
- **roadmaps** : Plans de développement et feuilles de route
- **specifications** : Spécifications fonctionnelles et techniques
- **tutorials** : Tutoriels et exemples d'utilisation

### Dossier `development`

Contient la documentation relative au développement :

- **api** : Documentation de l'API et exemples
- **communications** : Communications internes et externes
- **n8n-internals** : Documentation interne de n8n
- **roadmap** : Analyse, journal et plans de la feuille de route
- **testing** : Tests, performance et rapports
- **workflows** : Documentation des workflows
- **methodologies** : Méthodologies de développement et modes opératoires
- **tools** : Scripts et utilitaires

## Migration

La migration des documents de l'ancienne structure vers la nouvelle a été effectuée à l'aide de scripts PowerShell et de templates Hygen. Les références aux anciens chemins ont été mises à jour dans tous les fichiers.

## Utilisation de Hygen

Pour créer de nouveaux documents dans la structure, utilisez Hygen :

```powershell
# Créer un nouveau document dans la structure
hygen doc-structure new --docType "projet" --category "guides" --subcategory "installation"
```

## Scripts de Maintenance

Les scripts suivants sont disponibles pour maintenir la structure de documentation :

- `scripts/reorganize-with-hygen.ps1` : Crée la structure de base avec Hygen
- `scripts/reorganize-documentation.ps1` : Migre les fichiers de l'ancienne structure vers la nouvelle
- `scripts/update-doc-references.ps1` : Met à jour les références dans les fichiers
- `scripts/execute-doc-reorganization.ps1` : Exécute toutes les étapes de la réorganisation

Pour exécuter la réorganisation complète :

```powershell
# Exécuter avec confirmation
.\scripts\execute-doc-reorganization.ps1

# Exécuter sans confirmation
.\scripts\execute-doc-reorganization.ps1 -Force

# Simuler l'exécution (WhatIf)
.\scripts\execute-doc-reorganization.ps1 -WhatIf
```

## Contribution

Pour contribuer à la documentation, suivez les conventions décrites dans le guide du développeur.
