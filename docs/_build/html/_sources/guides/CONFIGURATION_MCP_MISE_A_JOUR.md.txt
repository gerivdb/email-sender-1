# Configuration mise à jour des MCP dans n8n

## Problème des toasts d'erreur au démarrage

Si vous voyez des toasts d'erreur indiquant que les MCP n'ont pas démarré, suivez ces instructions pour résoudre le problème.

## 1. MCP Standard (n8n-nodes-mcp)

1. Ouvrez n8n et accédez à "Credentials"
2. Créez un nouvel identifiant "MCP Client (STDIO) API"
3. Configurez-le comme suit :
   - **Credential Name**: MCP Standard
   - **Command**: D:\DO\WEB\N8N tests\scripts json � tester\EMAIL SENDER 1\mcp-standard.cmd
   - **Arguments**: (laissez vide)
   - **Environments**: N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true,OPENROUTER_API_KEY=sk-or-v1-...

## 2. MCP Notion Server

1. Ouvrez n8n et accédez à "Credentials"
2. Créez un nouvel identifiant "MCP Client (STDIO) API"
3. Configurez-le comme suit :
   - **Credential Name**: MCP Notion
   - **Command**: D:\DO\WEB\N8N tests\scripts json � tester\EMAIL SENDER 1\mcp-notion.cmd
   - **Arguments**: (laissez vide)
   - **Environments**: N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true,NOTION_API_TOKEN=secret_...

## 3. MCP Gateway

1. Ouvrez n8n et accédez à "Credentials"
2. Créez un nouvel identifiant "MCP Client (STDIO) API"
3. Configurez-le comme suit :
   - **Credential Name**: MCP Gateway
   - **Command**: D:\DO\WEB\N8N tests\scripts json � tester\EMAIL SENDER 1\gateway.exe.cmd
   - **Arguments**: start --config "D:\DO\WEB\N8N tests\scripts json � tester\EMAIL SENDER 1\gateway.yaml" mcp-stdio
   - **Environments**: N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true

## Important

- Utilisez des chemins absolus pour tous les fichiers
- Redémarrez n8n après avoir configuré les identifiants
- Vérifiez les logs de n8n pour voir les erreurs éventuelles

