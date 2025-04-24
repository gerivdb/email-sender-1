# Résolution des problèmes de démarrage des serveurs MCP

Ce document explique comment résoudre les problèmes courants rencontrés lors du démarrage des serveurs MCP (Model Context Protocol) pour le projet EMAIL_SENDER_1.

## Problèmes courants

### 1. Erreur "Failed to start the MCP server"

Si vous voyez des erreurs comme celles-ci dans les notifications :
```
Failed to start the MCP server. {"command":"npx -y @m...
Failed to start the MCP server. {"command":"supergateway...
Failed to start the MCP server. {"command":"cmd /c \"ec...
Failed to start the MCP server. {"command":"/mcp-serve...
Failed to start the MCP server. {"command":"/augment-...
Failed to start the MCP server. {"command":"/augment-...
Failed to start the MCP server. {"command":"/mcp-gdriv...
Failed to start the MCP server. {"command":"supergateway...
```

#### Solution

Nous avons créé de nouveaux scripts qui utilisent `npx` pour exécuter les commandes MCP, ce qui résout les problèmes de chemin et d'installation. De plus, nous avons ajouté un mécanisme pour nettoyer les notifications d'erreur et éviter qu'elles ne s'affichent au démarrage.

1. Exécutez le script de démarrage complet qui inclut le nettoyage des notifications :
   ```
   powershell -ExecutionPolicy Bypass -File "scripts\mcp\start-all-mcp-complete-v2.ps1"
   ```

   Ce script effectue les opérations suivantes :
   - Nettoie les notifications existantes
   - Configure VS Code pour ignorer les notifications futures
   - Vérifie si les serveurs sont déjà en cours d'exécution
   - Démarre les serveurs MCP nécessaires
   - Affiche un résumé de l'état des serveurs

2. Alternativement, vous pouvez exécuter les scripts individuels :

   a. Nettoyer les notifications :
   ```
   powershell -ExecutionPolicy Bypass -File "scripts\mcp\clear-mcp-notifications.ps1"
   ```

   b. Configurer VS Code :
   ```
   powershell -ExecutionPolicy Bypass -File "scripts\mcp\configure-vscode-mcp.ps1"
   ```

   c. Configurer Claude Desktop (si nécessaire) :
   ```
   powershell -ExecutionPolicy Bypass -File "scripts\mcp\configure-claude-desktop-mcp.ps1"
   ```

   d. Démarrer les serveurs MCP :
   ```
   powershell -ExecutionPolicy Bypass -File "scripts\mcp\start-all-mcp-servers.ps1"
   ```

### 2. Packages manquants

Certains packages comme `augment-mcp` et `mcp-gdriv` ne sont pas disponibles dans le registre npm standard.

#### Solution

Ces serveurs ne sont pas essentiels pour le fonctionnement de base. Les serveurs principaux (Filesystem, GitHub et Supergateway) devraient fonctionner correctement avec les scripts fournis.

Si vous avez besoin de ces serveurs spécifiques, vous devrez les installer manuellement à partir de leurs sources respectives.

### 3. Fichiers de configuration manquants

Vous pouvez rencontrer des erreurs liées à des fichiers de configuration manquants, comme :
- token.json pour GCP
- config.json pour GitHub
- n8n-config.json pour GDrive

#### Solution

Le script de démarrage créera automatiquement les fichiers de configuration par défaut lorsque c'est possible. Pour les fichiers qui nécessitent des informations d'authentification (comme token.json pour GCP), vous devrez les créer manuellement.

## Configuration des serveurs MCP

### MCP Filesystem
- Aucune configuration spéciale n'est nécessaire.

### MCP GitHub
- Éditez le fichier `mcp-servers\github\config.json` pour ajouter votre token GitHub.

### MCP GCP
- Créez un fichier `mcp-servers\gcp\token.json` avec vos informations d'authentification Google Cloud.

### MCP Supergateway
- Le fichier de configuration est `src\mcp\config\gateway.yaml`.

## Gestion des serveurs MCP

### Vérification des serveurs en cours d'exécution

Pour vérifier quels serveurs MCP sont en cours d'exécution, vous pouvez utiliser le script suivant :

```
powershell -ExecutionPolicy Bypass -File "scripts\mcp\check-mcp-servers-v2-noadmin.ps1"
```

Ce script affichera l'état de tous les serveurs MCP, avec des informations détaillées sur chaque serveur, y compris son PID s'il est en cours d'exécution.

### Arrêt des serveurs MCP

Pour arrêter tous les serveurs MCP en cours d'exécution, utilisez le script suivant :

```
powershell -ExecutionPolicy Bypass -File "scripts\mcp\stop-all-mcp-servers.ps1"
```

Ce script arrêtera tous les processus Node.js liés aux serveurs MCP de manière sécurisée.

### Redémarrage des serveurs MCP

Pour redémarrer tous les serveurs MCP (arrêt puis démarrage), utilisez le script suivant :

```
powershell -ExecutionPolicy Bypass -File "scripts\mcp\restart-all-mcp-servers.ps1"
```

Ce script arrêtera tous les serveurs MCP en cours d'exécution, puis les redémarrera. Il inclut également le nettoyage des notifications pour éviter les erreurs persistantes.

## Configuration des serveurs MCP dans VS Code

Si vous utilisez VS Code avec l'extension Augment, vous pouvez configurer les serveurs MCP directement dans VS Code :

```
powershell -ExecutionPolicy Bypass -File "scripts\mcp\configure-vscode-mcp.ps1"
```

Ce script mettra à jour le fichier `settings.json` de VS Code pour configurer les serveurs MCP et désactiver les notifications d'erreur liées aux serveurs MCP.

## Configuration des serveurs MCP pour Claude Desktop

Si vous utilisez Claude Desktop, vous pouvez configurer les serveurs MCP avec le script suivant :

```
powershell -ExecutionPolicy Bypass -File "scripts\mcp\configure-claude-desktop-mcp.ps1"
```

Ce script créera un fichier de configuration que vous pourrez charger dans Claude Desktop.

## Résolution avancée des problèmes

Si vous rencontrez toujours des problèmes après avoir suivi les étapes ci-dessus :

1. Vérifiez que Node.js est correctement installé et à jour.
2. Vérifiez que npm est correctement installé et à jour.
3. Vérifiez que les packages MCP sont correctement installés avec `npm list -g | findstr modelcontextprotocol`.
4. Consultez les logs dans le répertoire `logs` pour plus d'informations sur les erreurs.
5. Utilisez le script de correction des configurations MCP :
   ```
   powershell -ExecutionPolicy Bypass -File "scripts\mcp\fix-mcp-configurations.ps1" -InstallPackages
   ```
   Ce script corrige automatiquement toutes les configurations des serveurs MCP dans VS Code et crée des scripts individuels pour chaque serveur.
6. Exécutez les tests unitaires pour vérifier que les scripts fonctionnent correctement :
   ```
   powershell -ExecutionPolicy Bypass -File "scripts\mcp\tests\TestOmnibus.ps1" -InstallPester
   ```

## Logs

Les logs des serveurs MCP sont stockés dans le répertoire `logs` à la racine du projet, avec le format `mcp_servers_YYYY-MM-DD.log`.

## Nettoyage des notifications

Si vous continuez à voir des notifications d'erreur liées aux serveurs MCP dans VS Code, vous pouvez les nettoyer manuellement :

```
powershell -ExecutionPolicy Bypass -File "scripts\mcp\clear-mcp-notifications.ps1"
```

Ce script recherche et supprime les notifications d'erreur liées aux serveurs MCP dans les fichiers de configuration de VS Code.

## Documentation supplémentaire

Pour plus d'informations sur les améliorations apportées aux scripts MCP, consultez l'entrée du journal de bord :

- [2025-04-16 - Amélioration des scripts MCP et résolution des notifications d'erreur](../journal_de_bord/entries/2025-04-16-amelioration-scripts-mcp.md)
