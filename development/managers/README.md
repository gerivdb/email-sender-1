# Gestionnaires

Ce répertoire contient tous les gestionnaires du projet dans une architecture unifiée.

## Structure

Chaque gestionnaire est organisé selon la structure suivante :

- `<gestionnaire>/config` : Fichiers de configuration spécifiques au gestionnaire
- `<gestionnaire>/scripts` : Scripts PowerShell du gestionnaire  
- `<gestionnaire>/modules` : Modules PowerShell/Go du gestionnaire
- `<gestionnaire>/tests` : Tests unitaires et d'intégration du gestionnaire
- `<gestionnaire>/README.md` : Documentation spécifique du gestionnaire

## Gestionnaires disponibles

- **integrated-manager** : Gestionnaire intégré qui coordonne tous les autres gestionnaires
- **mode-manager** : Gestionnaire des modes opérationnels
- **roadmap-manager** : Gestionnaire de la roadmap (anciennement `cmd/roadmap-cli`)
- **mcp-manager** : Gestionnaire MCP
- **script-manager** : Gestionnaire de scripts
- **dependency-manager** : Gestionnaire de dépendances Go
- **n8n-manager** : Gestionnaire n8n
- **process-manager** : Gestionnaire de processus avec adaptateurs

## Scripts utilitaires

Des scripts utilitaires sont disponibles dans le dossier `scripts/` à la racine :

- `.\scripts\dep.ps1` : Interface simplifiée pour le gestionnaire de dépendances
- `.\scripts\roadmap.ps1` : Interface simplifiée pour le gestionnaire de roadmap

## Configuration

Les fichiers de configuration des gestionnaires sont centralisés dans le répertoire `projet/config/managers/`.
