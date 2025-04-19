# Guide d'utilisation du MCP Notion Server dans n8n

## Introduction

Le MCP Notion Server (@suekou/mcp-notion-server) est un serveur MCP (Model Context Protocol) qui permet d'interagir avec l'API Notion. Ce guide vous explique comment configurer et utiliser le MCP Notion Server dans vos workflows n8n.

## Prérequis

- n8n version 1.0.0 ou ultérieure
- Node.js 16 ou ultérieur
- Un compte Notion avec une intégration configurée

## Configuration de l'intégration Notion

1. **Créer une intégration Notion** :
   - Visitez la [page des intégrations Notion](https://www.notion.so/my-integrations)
   - Cliquez sur "New integration"
   - Nommez votre intégration et sélectionnez les permissions appropriées (ex: "Read content", "Update content")
   - Cliquez sur "Submit" pour créer l'intégration

2. **Récupérer le token d'intégration** :
   - Copiez le "Internal Integration Token" de votre intégration
   - Ce token sera utilisé pour l'authentification

3. **Ajouter l'intégration à votre espace de travail** :
   - Ouvrez la page ou la base de données à laquelle vous souhaitez que l'intégration accède
   - Cliquez sur le bouton "..." dans le coin supérieur droit
   - Cliquez sur "Add connections" et sélectionnez l'intégration que vous avez créée

## Installation

1. Installez le package @suekou/mcp-notion-server :
   ```bash
   npm install @suekou/mcp-notion-server
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
   NOTION_API_TOKEN=secret_...
   ```
   Remplacez `secret_...` par votre token d'intégration Notion.

## Configuration des identifiants MCP dans n8n

1. Ouvrez n8n et accédez à "Credentials"
2. Cliquez sur "Create New"
3. Recherchez "MCP Client (STDIO) API" et sélectionnez-le
4. Configurez les identifiants comme suit :
   - **Nom** : MCP Notion
   - **Command** : npx
   - **Arguments** : -y @suekou/mcp-notion-server
   - **Environments** : NOTION_API_TOKEN=secret_...,N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true

## Utilisation du MCP Notion Server dans un workflow

1. Ajoutez un nœud "MCP Client" à votre workflow
2. Configurez le nœud comme suit :
   - **Connection Type** : Command Line (STDIO)
   - **Credentials** : Sélectionnez les identifiants MCP Notion que vous avez créés
   - **Operation** : Choisissez l'opération souhaitée (List Tools, Execute Tool, etc.)

3. Pour l'opération "Execute Tool" :
   - **Tool Name** : Nom de l'outil Notion à exécuter (ex: notion_search, notion_retrieve_page, etc.)
   - **Parameters** : Paramètres de l'outil au format JSON

## Outils disponibles

Le MCP Notion Server propose de nombreux outils pour interagir avec Notion :

1. **notion_search** : Rechercher des pages ou des bases de données par titre
2. **notion_retrieve_page** : Récupérer les informations d'une page spécifique
3. **notion_retrieve_database** : Récupérer les informations d'une base de données spécifique
4. **notion_query_database** : Interroger une base de données
5. **notion_create_database_item** : Créer un nouvel élément dans une base de données
6. **notion_update_page_properties** : Mettre à jour les propriétés d'une page
7. **notion_retrieve_block** : Récupérer les informations d'un bloc spécifique
8. **notion_retrieve_block_children** : Récupérer les enfants d'un bloc spécifique
9. **notion_append_block_children** : Ajouter des blocs enfants à un bloc parent
10. **notion_delete_block** : Supprimer un bloc spécifique
11. **notion_create_database** : Créer une nouvelle base de données
12. **notion_update_database** : Mettre à jour une base de données
13. **notion_list_all_users** : Lister tous les utilisateurs de l'espace de travail
14. **notion_retrieve_user** : Récupérer les informations d'un utilisateur spécifique
15. **notion_retrieve_bot_user** : Récupérer les informations du bot associé au token
16. **notion_create_comment** : Créer un commentaire
17. **notion_retrieve_comments** : Récupérer les commentaires d'un bloc ou d'une page

## Exemple d'utilisation

### Recherche dans Notion

```json
{
  "tool_name": "notion_search",
  "parameters": {
    "query": "Projet",
    "filter": {
      "value": "page",
      "property": "object"
    },
    "format": "markdown"
  }
}
```

### Récupération d'une page

```json
{
  "tool_name": "notion_retrieve_page",
  "parameters": {
    "page_id": "1c481449-f795-8095-a5cf-cc4418e7ddb7",
    "format": "markdown"
  }
}
```

### Interrogation d'une base de données

```json
{
  "tool_name": "notion_query_database",
  "parameters": {
    "database_id": "1c481449-f795-8095-a5cf-cc4418e7ddb7",
    "filter": {
      "property": "Status",
      "status": {
        "equals": "En cours"
      }
    },
    "sorts": [
      {
        "property": "Date",
        "direction": "descending"
      }
    ],
    "format": "markdown"
  }
}
```

## Dépannage

Si vous rencontrez des problèmes :

1. Vérifiez que la variable d'environnement `N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE` est définie sur "true"
2. Assurez-vous que le package @suekou/mcp-notion-server est correctement installé
3. Vérifiez que votre token d'intégration Notion est valide
4. Assurez-vous que l'intégration a les permissions nécessaires et est ajoutée aux pages/bases de données concernées
5. Redémarrez n8n après avoir effectué ces modifications

## Conversion Markdown

Par défaut, toutes les réponses sont retournées au format JSON. Vous pouvez activer la conversion Markdown expérimentale pour réduire la consommation de tokens :

```
NOTION_MARKDOWN_CONVERSION=true
```

Ajoutez cette variable d'environnement à votre configuration MCP et utilisez le paramètre `format: "markdown"` dans vos appels d'outils pour obtenir des réponses plus lisibles.

## Ressources supplémentaires

- [Documentation officielle du MCP](https://modelcontextprotocol.io/docs/)
- [Documentation de l'API Notion](https://developers.notion.com/reference/intro)
- [GitHub du MCP Notion Server](https://github.com/suekou/mcp-notion-server)

