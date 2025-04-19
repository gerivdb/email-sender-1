# Guide d'utilisation du MCP (Model Context Protocol) dans n8n

## Introduction

Le MCP (Model Context Protocol) est un protocole qui permet aux modèles d'IA d'interagir avec des outils et des sources de données externes de manière standardisée. Ce guide vous explique comment configurer et utiliser le MCP dans vos workflows n8n.

## Prérequis

- n8n version 1.0.0 ou ultérieure
- Node.js 16 ou ultérieur
- Une clé API OpenRouter

## Installation

1. Installez le package n8n-nodes-mcp :
   ```bash
   npm install n8n-nodes-mcp
   ```

2. Définissez la variable d'environnement pour autoriser l'utilisation des outils :
   ```bash
   # Windows (PowerShell)
   $env:N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE = "true"

   # Linux/macOS
   export N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
   ```

3. Créez un fichier `.env` à la racine de votre projet n8n avec le contenu suivant :
   ```
   N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
   OPENROUTER_API_KEY=sk-or-v1-...
   ```
   Remplacez `sk-or-v1-...` par votre clé API OpenRouter.

## Configuration des identifiants MCP dans n8n

1. Ouvrez n8n et accédez à "Credentials"
2. Cliquez sur "Create New"
3. Recherchez "MCP Client (STDIO) API" et sélectionnez-le
4. Configurez les identifiants comme suit :
   - **Nom** : MCP OpenAI
   - **Command** : node
   - **Arguments** : ./node_modules/n8n-nodes-mcp/dist/nodes/McpClient/McpClient.node.js
   - **Environments** : OPENROUTER_API_KEY=sk-or-v1-...,N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true

## Utilisation du MCP dans un workflow

1. Ajoutez un nœud "MCP Client" à votre workflow
2. Configurez le nœud comme suit :
   - **Connection Type** : Command Line (STDIO)
   - **Credentials** : Sélectionnez les identifiants MCP que vous avez créés
   - **Operation** : Choisissez l'opération souhaitée (List Tools, Execute Tool, etc.)

3. Pour l'opération "Execute Tool" :
   - **Tool Name** : Nom de l'outil à exécuter
   - **Parameters** : Paramètres de l'outil au format JSON

## Dépannage

Si vous rencontrez l'erreur "MCP error -1: Connection closed" :

1. Vérifiez que la variable d'environnement `N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE` est définie sur "true"
2. Assurez-vous que le package n8n-nodes-mcp est correctement installé
3. Vérifiez que votre clé API OpenRouter est valide
4. Redémarrez n8n après avoir effectué ces modifications

## Exemple d'utilisation avec OpenRouter

Pour utiliser le MCP avec OpenRouter :

1. Configurez les identifiants MCP comme indiqué ci-dessus
2. Dans votre workflow, ajoutez un nœud MCP Client
3. Sélectionnez l'opération "Execute Tool"
4. Utilisez l'outil "chat" avec les paramètres suivants :
   ```json
   {
     "messages": [
       {"role": "system", "content": "Tu es un assistant utile."},
       {"role": "user", "content": "Bonjour, comment puis-je utiliser le MCP?"}
     ],
     "model": "deepseek-ai/deepseek-v3"
   }
   ```

## Ressources supplémentaires

- [Documentation officielle du MCP](https://modelcontextprotocol.io/docs/)
- [Documentation n8n-nodes-mcp](https://github.com/modelcontextprotocol/n8n-nodes-mcp)
- [SDK TypeScript MCP](https://github.com/modelcontextprotocol/typescript-sdk)

