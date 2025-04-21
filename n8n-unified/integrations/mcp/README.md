# Intégration n8n avec MCP

Cette intégration permet d'utiliser n8n avec les serveurs MCP (Model Context Protocol) pour accéder à différentes sources de données et services.

## Fonctionnalités

- Configuration automatique des identifiants MCP dans n8n
- Démarrage de n8n avec les serveurs MCP
- Synchronisation des workflows entre n8n et les serveurs MCP
- Utilisation des serveurs MCP dans les workflows n8n

## Configuration

### Prérequis

- n8n installé et configuré (voir le dossier parent)
- Serveurs MCP installés et configurés

### Installation

1. Assurez-vous que n8n est en cours d'exécution
2. Exécutez le script de configuration :

```
.\setup-mcp-integration.ps1
```

## Utilisation

### Démarrer n8n avec les serveurs MCP

Pour démarrer n8n avec les serveurs MCP, exécutez le script suivant :

```
.\start-n8n-with-mcp.cmd
```

### Configurer les identifiants MCP dans n8n

Pour configurer les identifiants MCP dans n8n, exécutez le script suivant :

```
.\configure-n8n-mcp.ps1
```

### Synchroniser les workflows avec les serveurs MCP

Pour synchroniser les workflows avec les serveurs MCP, exécutez le script suivant :

```
.\sync-workflows-with-mcp.ps1
```

## Architecture

L'intégration utilise les serveurs MCP pour accéder à différentes sources de données et services. Les serveurs MCP suivants sont pris en charge :

- MCP Filesystem : Accès aux fichiers locaux
- MCP GitHub : Accès aux dépôts GitHub
- MCP GCP : Accès à Google Cloud Platform
- MCP Supergateway : Passerelle vers d'autres serveurs MCP
- MCP Augment : Intégration avec Augment
- MCP GDrive : Accès à Google Drive
- MCP Git Ingest : Ingestion de dépôts Git

## Composants

- `McpN8nIntegration.ps1` : Script PowerShell principal pour l'intégration
- `setup-mcp-integration.ps1` : Script de configuration de l'intégration
- `start-n8n-with-mcp.cmd` : Script pour démarrer n8n avec les serveurs MCP
- `configure-n8n-mcp.ps1` : Script pour configurer les identifiants MCP dans n8n
- `sync-workflows-with-mcp.ps1` : Script pour synchroniser les workflows avec les serveurs MCP

## Dépannage

### Problèmes courants

- **Erreur de connexion aux serveurs MCP** : Vérifiez que les serveurs MCP sont en cours d'exécution
- **Erreur d'authentification** : Vérifiez que les identifiants MCP sont correctement configurés
- **Workflow non trouvé** : Vérifiez que le workflow existe dans n8n

### Journaux

Les journaux de l'intégration sont stockés dans le dossier `logs/` et peuvent être consultés pour diagnostiquer les problèmes.
