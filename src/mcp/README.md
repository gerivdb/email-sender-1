# Configuration MCP pour n8n

Ce dossier contient tous les fichiers nécessaires pour configurer et utiliser les MCP (Model Context Protocol) dans n8n.

## Structure des dossiers

- **batch** : Fichiers batch pour exécuter les différents MCP
- **config** : Fichiers de configuration pour les MCP
- **workflows** : Workflows de test pour les MCP

## MCP disponibles

- **MCP Standard** : Pour interagir avec OpenRouter et les modèles d'IA
- **MCP Notion** : Pour interagir avec vos bases de données Notion
- **MCP Gateway** : Pour interagir avec vos bases de données SQL
- **MCP Git Ingest** : Pour explorer et lire les dépôts GitHub

## Utilisation

1. Exécutez le script scripts\configure-n8n-mcp.ps1 pour configurer les MCP Standard, Notion et Gateway
2. Exécutez le script scripts\configure-mcp-git-ingest.ps1 pour configurer le MCP Git Ingest
3. Utilisez le script start-n8n-complete.cmd pour démarrer n8n avec vérification des MCP

## Documentation

Pour plus d'informations, consultez les guides suivants :

- [Guide final MCP](../GUIDE_FINAL_MCP.md)
- [Guide MCP Gateway](../GUIDE_MCP_GATEWAY.md)
- [Guide MCP Git Ingest](../GUIDE_MCP_GIT_INGEST.md)
