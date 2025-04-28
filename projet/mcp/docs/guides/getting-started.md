# Guide de démarrage rapide MCP

Ce guide vous aidera à démarrer rapidement avec le système MCP (Model Context Protocol) dans le projet EMAIL_SENDER_1.

## Prérequis

- Node.js 16 ou ultérieur
- PowerShell 5.1 ou ultérieur
- Python 3.8 ou ultérieur (pour certains serveurs)

## Installation rapide

1. Clonez le dépôt :
   ```
   git clone https://github.com/gerivonderbitsh/EMAIL_SENDER_1.git
   cd EMAIL_SENDER_1
   ```

2. Installez les dépendances :
   ```powershell
   .\projet\mcp\dependencies\scripts\install-dependencies.ps1
   ```

3. Configurez les serveurs MCP :
   ```powershell
   .\projet\mcp\scripts\setup\configure-mcp.ps1
   ```

## Démarrage des serveurs MCP

Pour démarrer tous les serveurs MCP :

```powershell
.\projet\mcp\scripts\utils\start-mcp-server.ps1
```

Pour démarrer un serveur spécifique :

```powershell
.\projet\mcp\scripts\utils\start-mcp-server.ps1 -Server filesystem
```

## Vérification de l'état des serveurs

Pour vérifier l'état des serveurs MCP :

```powershell
.\projet\mcp\scripts\utils\check-mcp-status.ps1
```

## Arrêt des serveurs

Pour arrêter tous les serveurs MCP :

```powershell
.\projet\mcp\scripts\utils\stop-mcp-server.ps1
```

## Intégration avec n8n

Pour configurer n8n avec les serveurs MCP :

```powershell
.\projet\mcp\integrations\n8n\scripts\configure-n8n-mcp.ps1
```

## Étapes suivantes

- [Guide d'installation complet](installation.md)
- [Guide de configuration](configuration.md)
- [Intégration avec n8n](n8n-integration.md)
- [Documentation des serveurs](../servers/)
