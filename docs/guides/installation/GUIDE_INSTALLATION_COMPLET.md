# Guide d'installation complet pour les MCP dans n8n

Ce guide vous explique comment résoudre les problèmes de toasts d'erreur au démarrage des MCP dans n8n.

## Étape 1 : Vérifier les prérequis

Assurez-vous que les éléments suivants sont installés et fonctionnels :

- Node.js (version 14 ou supérieure)
- n8n (version 1.0.0 ou supérieure)
- Les packages npm nécessaires (n8n-nodes-mcp, @suekou/mcp-notion-server)

## Étape 2 : Configurer les variables d'environnement

1. Ouvrez une invite de commande PowerShell en tant qu'administrateur
2. Exécutez la commande suivante pour définir la variable d'environnement au niveau utilisateur :
   ```powershell
   [Environment]::SetEnvironmentVariable('N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE', 'true', 'User')
   ```

## Étape 3 : Utiliser les fichiers batch pour les MCP

Les fichiers batch suivants ont été créés pour faciliter l'utilisation des MCP :

- `mcp-standard.cmd` : Pour le MCP standard (n8n-nodes-mcp)
- `mcp-notion.cmd` : Pour le MCP Notion Server (@suekou/mcp-notion-server)
- `gateway.exe.cmd` : Pour le MCP Gateway (centralmind/gateway)

Ces fichiers définissent automatiquement les variables d'environnement nécessaires lors de l'exécution des MCP.

## Étape 4 : Configurer les identifiants MCP dans n8n

1. Démarrez n8n en utilisant le script `start-n8n.cmd` ou en exécutant la commande `npx n8n start`
2. Ouvrez l'interface web de n8n (généralement http://localhost:5678)
3. Cliquez sur l'icône d'engrenage (⚙️) dans le coin supérieur droit
4. Sélectionnez "Credentials" dans le menu déroulant
5. Configurez les identifiants pour chaque MCP selon les instructions ci-dessous

### MCP Standard

1. Cliquez sur "Create New"
2. Recherchez "MCP Client (STDIO) API" et sélectionnez-le
3. Configurez-le comme suit :
   - **Credential Name**: MCP Standard
   - **Command**: Chemin complet vers mcp-standard.cmd (ex: D:\chemin\vers\mcp-standard.cmd)
   - **Arguments**: (laissez vide)
   - **Environments**: N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true,OPENROUTER_API_KEY=sk-or-v1-...

### MCP Notion Server

1. Cliquez sur "Create New"
2. Recherchez "MCP Client (STDIO) API" et sélectionnez-le
3. Configurez-le comme suit :
   - **Credential Name**: MCP Notion
   - **Command**: Chemin complet vers mcp-notion.cmd (ex: D:\chemin\vers\mcp-notion.cmd)
   - **Arguments**: (laissez vide)
   - **Environments**: N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true,NOTION_API_TOKEN=secret_...

### MCP Gateway

1. Cliquez sur "Create New"
2. Recherchez "MCP Client (STDIO) API" et sélectionnez-le
3. Configurez-le comme suit :
   - **Credential Name**: MCP Gateway
   - **Command**: Chemin complet vers gateway.exe.cmd (ex: D:\chemin\vers\gateway.exe.cmd)
   - **Arguments**: start --config "D:\chemin\vers\gateway.yaml" mcp-stdio
   - **Environments**: N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true

## Étape 5 : Redémarrer n8n

1. Fermez n8n (Ctrl+C dans la console où n8n est en cours d'exécution)
2. Redémarrez n8n en utilisant le script `start-n8n.cmd` ou en exécutant la commande `npx n8n start`

## Étape 6 : Vérifier que les MCP fonctionnent correctement

1. Créez un nouveau workflow dans n8n
2. Ajoutez un nœud "MCP Client"
3. Sélectionnez l'un des identifiants MCP que vous avez configurés
4. Sélectionnez l'opération "List Tools"
5. Exécutez le nœud pour vérifier que le MCP fonctionne correctement

## Dépannage

Si vous rencontrez toujours des problèmes :

1. Vérifiez les logs de n8n pour voir les erreurs éventuelles
2. Assurez-vous que les chemins dans la configuration des identifiants MCP sont corrects et utilisent des chemins absolus
3. Vérifiez que les fichiers batch sont exécutables et accessibles
4. Assurez-vous que n8n a les permissions nécessaires pour exécuter les scripts et accéder aux fichiers

## Ressources supplémentaires

- [Documentation officielle de n8n](https://docs.n8n.io/)
- [Documentation du MCP](https://modelcontextprotocol.io/docs/)
- [GitHub de n8n-nodes-mcp](https://github.com/modelcontextprotocol/n8n-nodes-mcp)
- [GitHub de @suekou/mcp-notion-server](https://github.com/suekou/mcp-notion-server)
- [GitHub de centralmind/gateway](https://github.com/centralmind/gateway)

