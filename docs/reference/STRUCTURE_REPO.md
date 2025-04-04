# Structure du Repo

Ce document décrit la structure standardisée du repo pour le projet Email Sender, conforme aux bonnes pratiques GitHub.

## Vue d'ensemble

```
├── src/                  # Code source principal
│   ├── workflows/        # Workflows n8n
│   └── mcp/              # Fichiers MCP (Model Context Protocol)
│       ├── batch/        # Fichiers batch pour MCP
│       └── config/       # Configurations MCP
├── scripts/              # Scripts utilitaires
│   ├── setup/            # Scripts d'installation
│   └── maintenance/      # Scripts de maintenance
├── config/               # Fichiers de configuration
├── logs/                 # Fichiers de logs
├── docs/                 # Documentation
│   ├── guides/           # Guides d'utilisation
│   └── api/              # Documentation API
├── tests/                # Tests
├── tools/                # Outils divers
└── assets/               # Ressources statiques
```

## Description détaillée

### src/

Contient tout le code source principal du projet.

- **workflows/**: Tous les workflows n8n au format JSON.
- **mcp/**: Fichiers liés au Model Context Protocol.
  - **batch/**: Fichiers batch pour exécuter les différents MCP.
  - **config/**: Fichiers de configuration pour les MCP.

### scripts/

Scripts utilitaires pour l'installation, la configuration et la maintenance du projet.

- **setup/**: Scripts d'installation et de configuration initiale.
- **maintenance/**: Scripts pour la maintenance continue du projet.

### config/

Fichiers de configuration pour le projet, y compris les variables d'environnement.

### logs/

Fichiers de logs générés par l'application. Ce dossier est généralement exclu du contrôle de version.

### docs/

Documentation complète du projet.

- **guides/**: Guides d'utilisation pour les différentes fonctionnalités.
- **api/**: Documentation des API utilisées ou exposées.

### tests/

Tests pour vérifier le bon fonctionnement du projet.

### tools/

Outils divers pour le développement et l'exécution du projet.

### assets/

Ressources statiques comme les images, les icônes, etc.

## Conventions de nommage

### Fichiers

- **Workflows n8n**: `nom-du-workflow.json` ou `nom-du-workflow.workflow.json`
- **Scripts PowerShell**: 
  - Installation: `setup-*.ps1`
  - Configuration: `configure-*.ps1`
  - Maintenance: `update-*.ps1`, `cleanup-*.ps1`, `check-*.ps1`
- **Fichiers batch MCP**: `mcp-*.cmd`
- **Documentation**: `NOM_DU_DOCUMENT.md` ou `Nom-du-document.md`
- **Logs**: `*.log`

### Branches Git (si utilisé)

- **main**: Branche principale, stable
- **develop**: Branche de développement
- **feature/nom-de-la-fonctionnalité**: Pour les nouvelles fonctionnalités
- **fix/nom-du-correctif**: Pour les corrections de bugs

## Création de nouveaux fichiers

Pour créer de nouveaux fichiers dans les bons dossiers, utilisez le script `new-file.ps1`:

```powershell
.\scripts\maintenance\new-file.ps1 -Type <type> -Name <nom>
```

Types disponibles:
- **workflow**: Crée un nouveau workflow n8n
- **script**: Crée un nouveau script PowerShell
- **doc**: Crée un nouveau document Markdown
- **config**: Crée un nouveau fichier de configuration
- **mcp**: Crée un nouveau fichier batch MCP
- **test**: Crée un nouveau script de test

## Organisation automatique

Le script `auto-organize.ps1` peut être exécuté périodiquement pour organiser automatiquement les fichiers selon les règles définies:

```powershell
.\scripts\maintenance\auto-organize.ps1
```

Ce script peut également être configuré comme un hook Git pre-commit pour organiser automatiquement les fichiers avant chaque commit.
