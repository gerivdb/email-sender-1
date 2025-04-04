# Projet Email Sender pour n8n

Ce projet contient des workflows n8n et des outils pour automatiser l'envoi d'emails et la gestion des processus de booking pour le groupe Gribitch.

## Structure du projet

```
├── workflows/            # Workflows n8n finaux
│   ├── core/             # Workflows principaux
│   ├── config/           # Workflows de configuration
│   ├── phases/           # Workflows par phase
│   └── testing/          # Workflows de test
├── credentials/          # Informations d'identification
├── config/               # Fichiers de configuration
├── mcp/                  # Configurations MCP
├── src/                  # Code source principal
│   ├── workflows/        # Workflows n8n (développement)
│   └── mcp/              # Fichiers MCP (Model Context Protocol)
│       ├── batch/        # Fichiers batch pour MCP
│       └── config/       # Configurations MCP
├── scripts/              # Scripts utilitaires
│   ├── maintenance/      # Scripts de maintenance
│   │   ├── repo/         # Organisation et vérification du dépôt
│   │   ├── encoding/     # Correction des problèmes d'encodage
│   │   └── cleanup/      # Nettoyage des fichiers et dossiers
│   ├── setup/            # Scripts d'installation
│   │   ├── mcp/          # Configuration des MCP
│   │   └── env/          # Configuration de l'environnement
│   ├── workflow/         # Scripts liés aux workflows n8n
│   │   ├── validation/   # Validation des workflows
│   │   ├── testing/      # Test des workflows
│   │   └── monitoring/   # Surveillance des workflows
│   └── utils/            # Scripts utilitaires
│       ├── markdown/     # Traitement des fichiers Markdown
│       ├── json/         # Traitement des fichiers JSON
│       └── automation/   # Automatisation des tâches
├── logs/                 # Fichiers de logs
│   ├── daily/            # Logs quotidiens
│   ├── weekly/           # Logs hebdomadaires
│   ├── monthly/          # Logs mensuels
│   ├── scripts/          # Logs des scripts
│   └── workflows/        # Logs des workflows
├── docs/                 # Documentation
│   ├── guides/           # Guides d'utilisation
│   └── api/              # Documentation API
├── tests/                # Tests
├── tools/                # Outils divers
└── assets/               # Ressources statiques
```

## Organisation des fichiers finaux

Les fichiers finaux indispensables au projet sont organisés dans les répertoires suivants :

- **workflows/** - Contient tous les fichiers de workflow n8n finaux
  - **core/** - Workflows principaux
    - EMAIL_SENDER_1 (5).json - Workflow principal
  - **config/** - Workflows de configuration
    - EMAIL_SENDER_CONFIG.json - Configuration du workflow
  - **phases/** - Workflows par phase
    - EMAIL_SENDER_PHASE1.json à EMAIL_SENDER_PHASE6.json - Phases du workflow
  - **testing/** - Workflows de test

- **credentials/** - Contient les informations d'identification nécessaires pour les connexions
  - Fichiers de credentials pour les différentes connexions (OpenRouter, Notion, etc.)

- **config/** - Contient les fichiers de configuration
  - n8n-config.txt - Configuration de base de n8n

- **mcp/** - Contient les configurations pour les Model Context Protocol (MCP)
  - mcp-config.json - Configuration de base MCP
  - mcp-config-fixed.json - Configuration MCP corrigée

## MCP disponibles

- **MCP Standard** : Pour interagir avec OpenRouter et les modèles d'IA
- **MCP Notion** : Pour interagir avec vos bases de données Notion
- **MCP Gateway** : Pour interagir avec vos bases de données SQL
- **MCP Git Ingest** : Pour explorer et lire les dépôts GitHub

## Installation et configuration

1. **Configuration des MCP Standard, Notion et Gateway** :
   ```powershell
   .\scripts\setup\configure-n8n-mcp.ps1
   ```

2. **Configuration du MCP Git Ingest** :
   ```powershell
   .\scripts\setup\configure-mcp-git-ingest.ps1
   ```

3. **Démarrage de n8n avec vérification des MCP** :
   ```
   .\tools\start-n8n-mcp.cmd
   ```

## Mise à jour et maintenance

- **Mise à jour des MCP** :
  ```powershell
  .\scripts\maintenance\update-mcp.ps1
  ```

- **Organisation des fichiers** :
  ```powershell
  .\scripts\maintenance\create-folders.ps1
  .\scripts\maintenance\move-mcp-files.ps1
  ```

- **Nettoyage des fichiers obsolètes** :
  ```powershell
  .\scripts\maintenance\cleanup-mcp-files.ps1
  ```

## Documentation

- [Guide final MCP](docs/guides/GUIDE_FINAL_MCP.md) : Guide complet sur les MCP dans n8n
- [Guide MCP Gateway](docs/guides/GUIDE_MCP_GATEWAY.md) : Guide spécifique pour le MCP Gateway
- [Guide MCP Git Ingest](docs/guides/GUIDE_MCP_GIT_INGEST.md) : Guide spécifique pour le MCP Git Ingest

## Organisation automatique des fichiers

Le projet dispose de scripts d'automatisation pour maintenir une structure de répertoire claire et organisée :

### Scripts d'organisation

- **scripts/organize-scripts.ps1** - Organise les scripts en sous-dossiers sémantiques
  ```powershell
  powershell -File .\scripts\organize-scripts.ps1
  ```

- **scripts/utils/automation/auto-organize-folders.ps1** - Organise les dossiers contenant trop de fichiers
  ```powershell
  powershell -File .\scripts\utils\automation\auto-organize-folders.ps1 -MaxFilesPerFolder 15
  ```

- **scripts/utils/automation/manage-logs.ps1** - Gère les logs par unité de temps
  ```powershell
  powershell -File .\scripts\utils\automation\manage-logs.ps1 <LogName> [Category]
  ```

### Configuration de l'automatisation

Pour configurer l'exécution automatique de ces scripts, utilisez :

```powershell
powershell -File .\scripts\utils\automation\setup-auto-organization.ps1
```

Ce script crée des tâches planifiées pour :
- Organiser les scripts (hebdomadaire)
- Organiser les dossiers (quotidienne)
- Gérer les logs (quotidienne)

### Principes d'organisation

- **Limitation du nombre de fichiers** : Maximum 15 fichiers par dossier
- **Organisation sémantique** : Classement par type d'usage
- **Logs par unité de temps** : Quotidien, hebdomadaire, mensuel
- **Archivage automatique** : Compression des anciens logs

## Utilisation des MCP

Pour utiliser les MCP, vous pouvez exécuter directement les fichiers batch dans le dossier `src/mcp/batch` :

```powershell
.\src\mcp\batch\mcp-standard.cmd
.\src\mcp\batch\mcp-notion.cmd
.\src\mcp\batch\gateway.exe.cmd
.\src\mcp\batch\mcp-git-ingest.cmd
```

## Workflows de test

Des workflows de test sont disponibles dans le dossier `workflows/testing` :
- `test-mcp-workflow-updated.json` : Workflow de test pour les MCP Standard, Notion et Gateway
- `test-mcp-git-ingest-workflow.json` : Workflow de test pour le MCP Git Ingest

## Dépannage

Si vous rencontrez des problèmes avec les MCP, consultez la section "Maintenance et dépannage" du [Guide final MCP](docs/guides/GUIDE_FINAL_MCP.md).
