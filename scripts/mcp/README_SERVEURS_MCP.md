# Serveurs MCP pour EMAIL_SENDER_1

Ce document explique comment installer, configurer et démarrer les serveurs MCP (Model Context Protocol) utilisés par le projet EMAIL_SENDER_1.

## Scripts disponibles

Plusieurs scripts ont été créés pour simplifier la gestion des serveurs MCP :

### Installation

- **`install-mcp-dependencies.cmd`** : Installe toutes les dépendances npm nécessaires pour les serveurs MCP.

### Gestion des serveurs

- **`start-all-mcp-servers.cmd`** : Démarre tous les serveurs MCP configurés en une seule commande.
- **`stop-all-mcp-servers.cmd`** : Arrête tous les serveurs MCP en cours d'exécution.
- **`restart-all-mcp-servers.cmd`** : Redémarre tous les serveurs MCP (arrêt puis démarrage).
- **`check-mcp-servers.cmd`** : Vérifie l'état de tous les serveurs MCP.

### Configuration

- **`configure-vscode-mcp.cmd`** : Configure les serveurs MCP dans VS Code.
- **`configure-claude-desktop-mcp.cmd`** : Crée un fichier de configuration pour Claude Desktop.

## Guide d'utilisation

### Étape 1 : Installation des dépendances

Exécutez le script d'installation des dépendances :

```
scripts\mcp\install-mcp-dependencies.cmd
```

Ce script vérifiera et installera les packages npm suivants :
- @modelcontextprotocol/server-filesystem
- @modelcontextprotocol/server-github
- gcp-mcp
- supergateway

**Note** : Les packages `augment-mcp` et `mcp-gdriv` ne sont pas disponibles dans le registre npm standard et ne seront pas installés automatiquement.

### Étape 2 : Démarrage des serveurs

Exécutez le script de démarrage unifié :

```
scripts\mcp\start-all-mcp-servers.cmd
```

Ce script démarrera les serveurs MCP suivants :
1. MCP Filesystem (accès aux fichiers locaux)
2. MCP GitHub (accès aux dépôts GitHub)
3. MCP GCP (accès à Google Cloud Platform)
4. MCP Supergateway
5. MCP Augment
6. MCP GDrive

## Configuration des serveurs

### MCP Filesystem
- Aucune configuration spéciale n'est nécessaire.

### MCP GitHub
- Créez un fichier `mcp-servers\github\config.json` avec votre token GitHub.

### MCP GCP
- Placez votre fichier d'authentification Google Cloud dans `mcp-servers\gcp\token.json`.

### MCP Supergateway
- Utilisez le fichier de configuration `src\mcp\config\gateway.yaml`.

### MCP Augment
- La configuration est déjà présente dans `.augment\config.json`.

### MCP GDrive
- Utilisez le fichier de configuration `mcp\gdrive\n8n-config.json`.

## Résolution des problèmes

Si vous rencontrez des erreurs lors du démarrage des serveurs MCP :

1. Vérifiez que Node.js est installé et à jour.
2. Exécutez à nouveau `install-mcp-dependencies.cmd`.
3. Vérifiez les fichiers de configuration.
4. Consultez les logs dans le répertoire `logs`.
5. Utilisez `check-mcp-servers.cmd` pour vérifier l'état des serveurs.
6. Essayez de redémarrer les serveurs avec `restart-all-mcp-servers.cmd`.
7. Configurez les serveurs MCP dans VS Code avec `configure-vscode-mcp.cmd`.

Pour plus d'informations, consultez le guide de résolution des problèmes MCP dans `docs\guides\RESOLUTION_PROBLEMES_MCP.md`.

## Logs

Les logs des serveurs MCP sont stockés dans le répertoire `logs` à la racine du projet, avec le format `mcp_servers_YYYY-MM-DD.log`.
