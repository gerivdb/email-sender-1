# Structure du dossier n8n

Ce document décrit la structure du dossier n8n et son organisation.

## Vue d'ensemble

La structure du dossier n8n est organisée de manière à séparer clairement les différents composants et à faciliter la maintenance et l'intégration avec d'autres systèmes.

```
n8n/
├── config/               # Configuration n8n
├── data/                 # Données n8n (base de données, credentials, etc.)
│   ├── credentials/      # Credentials chiffrées
│   ├── database/         # Base de données SQLite
│   └── storage/          # Stockage binaire
├── workflows/            # Workflows n8n
│   ├── local/            # Workflows utilisés par n8n local
│   ├── ide/              # Workflows utilisés par l'IDE
│   └── archive/          # Workflows archivés
├── scripts/              # Scripts utilitaires
│   ├── sync/             # Scripts de synchronisation
│   ├── setup/            # Scripts d'installation et de configuration
│   └── utils/            # Utilitaires communs
├── integrations/         # Intégrations avec d'autres systèmes
│   ├── ide/              # Intégration avec l'IDE
│   └── mcp/              # Intégration avec MCP
└── docs/                 # Documentation
```

## Détails des dossiers

### config/

Ce dossier contient les fichiers de configuration pour n8n, notamment :

- `n8n-config.json` : Configuration principale de n8n
- `api-key.json` : Clé API pour accéder à l'API n8n

### data/

Ce dossier contient les données persistantes de n8n :

- `credentials/` : Credentials chiffrées pour les connexions aux services externes
- `database/` : Base de données SQLite contenant les workflows, exécutions, etc.
- `storage/` : Stockage binaire pour les fichiers uploadés

### workflows/

Ce dossier contient les workflows n8n organisés par environnement :

- `local/` : Workflows utilisés par n8n local
- `ide/` : Workflows utilisés par l'IDE
- `archive/` : Workflows archivés ou obsolètes

### scripts/

Ce dossier contient les scripts utilitaires pour n8n :

- `sync/` : Scripts de synchronisation entre n8n et les fichiers locaux
- `setup/` : Scripts d'installation et de configuration
- `utils/` : Utilitaires communs utilisés par les autres scripts

### integrations/

Ce dossier contient les intégrations avec d'autres systèmes :

- `ide/` : Intégration avec l'IDE
- `mcp/` : Intégration avec MCP

### docs/

Ce dossier contient la documentation du projet, notamment :

- `structure.md` : Documentation de la structure du dossier
- `sync-procedures.md` : Documentation des procédures de synchronisation
- `installation.md` : Documentation d'installation et de configuration

## Utilisation

### Installation

Pour installer n8n, exécutez le script d'installation :

```powershell
.\scripts\setup\install-n8n.ps1
```

### Démarrage

Pour démarrer n8n, exécutez le script de démarrage :

```powershell
.\scripts\start-n8n.ps1
```

### Synchronisation des workflows

Pour synchroniser les workflows entre n8n et les fichiers locaux, exécutez le script de synchronisation :

```powershell
.\scripts\sync\sync-workflows.ps1
```

Options disponibles :

- `-Direction` : Direction de la synchronisation (`to-n8n`, `from-n8n`, `both`)
- `-Environment` : Environnement cible (`local`, `ide`, `all`)

Exemple :

```powershell
.\scripts\sync\sync-workflows.ps1 -Direction "both" -Environment "all"
```
