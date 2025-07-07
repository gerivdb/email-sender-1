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
- **gateway-manager**: Orchestrateur de requêtes Go-natif. Traite les requêtes en coordonnant les services backend tels que CacheManager, LWM, RAG, et MemoryBank. (Voir `development/managers/gateway-manager/README.md` pour détails).
- **mcp-manager**: Gestionnaire MCP. Une version Go était planifiée pour ce répertoire (voir `plan-dev-v33-mcp-manager.md`), mais le répertoire est actuellement vide. Une implémentation PowerShell existe dans `src/mcp/scripts/mcp-manager.ps1` et `src/mcp/modules/MCPManager.psm1` au sein du framework MCP plus large.
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
