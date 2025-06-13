# Règles du Projet (Workspace-Specific)

## Outils et Infrastructure

- **n8n** : Moteur principal d'automatisation
- **MCP personnalisés** :
  - OpenRouter/IA
  - Notion DB
  - SQL Gateway
  - Git Ingest (Python)
  - GitHub
- **Scripts** :
  - PowerShell
  - CMD
  - Python

## Configurations Spécifiques

- **Fichiers de configuration** :
  - `.augmentignore`
  - `unified-config.json`
- **Scripts de maintenance** :
  - `optimize-mcp-structure.ps1`
  - `Run-MaintenanceTests.ps1`
- **Documentation** :
  - `development/docs/`
  - `projet/documentation/`

## Pratiques du Projet

- **Templates** : Utilisation de **hygen.js**
- **CI/CD** : Gestion des workflows avec **Azure Pipelines**
- **Structure modulaire** : Séparation claire des responsabilités dans les dossiers :
  - `development/`
  - `src/`
  - `workflows/`
