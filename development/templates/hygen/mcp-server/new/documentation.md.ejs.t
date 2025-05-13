---
to: "<%= createDocs ? `projet/guides/mcp/GUIDE_MCP_${name.toUpperCase().replace(/-/g, '_')}.md` : null %>"
---
# Guide d'utilisation du MCP <%= name.charAt(0).toUpperCase() + name.slice(1) %>

## Introduction

Le MCP <%= name.charAt(0).toUpperCase() + name.slice(1) %> est un serveur MCP (Model Context Protocol) qui <%= description.toLowerCase() %>. Ce guide vous explique comment configurer et utiliser le MCP <%= name.charAt(0).toUpperCase() + name.slice(1) %> dans vos workflows.

## Prérequis

<% if (command === 'npx') { %>
- Node.js version 14.0.0 ou ultérieure
- npm version 6.0.0 ou ultérieure
<% } else if (command === 'python') { %>
- Python 3.8 ou ultérieur
- pip (installé avec Python)
<% } %>
<% if (args.includes('git+https://github.com')) { %>
- Git installé sur votre système
<% } %>

## Installation

<% if (command === 'npx') { %>
1. Assurez-vous que Node.js et npm sont installés sur votre système.
2. Le serveur sera automatiquement installé lors de son utilisation avec npx.
<% } else if (command === 'python') { %>
1. Assurez-vous que Python et pip sont installés sur votre système.
2. Installez les dépendances nécessaires :
   ```powershell
   pip install <%= args.split(',').map(a => a.trim()).filter(a => a.startsWith('git+')).join(' ') %>
   ```
<% } %>
3. Exécutez le script `scripts\start-<%= name %>-mcp.cmd` pour démarrer le serveur MCP <%= name.charAt(0).toUpperCase() + name.slice(1) %> :
   ```powershell
   .\scripts\start-<%= name %>-mcp.cmd
   ```

## Configuration

Le serveur MCP <%= name.charAt(0).toUpperCase() + name.slice(1) %> est configuré dans le fichier `projet/mcp/config/servers/<%= name %>.json`. Voici les principales options de configuration :

<% if (port) { %>
- **port** : Port sur lequel le serveur écoute en mode HTTP (par défaut : <%= port %>)
<% } %>
- **enabled** : Active ou désactive le serveur
- **cacheEnabled** : Active ou désactive le cache
- **cacheTTL** : Durée de vie du cache en secondes
<% if (name === 'git-ingest') { %>
- **outputDir** : Répertoire de sortie pour les résultats d'analyse
- **cloneDir** : Répertoire pour cloner les dépôts GitHub
- **maxFiles** : Nombre maximum de fichiers à analyser
- **excludePatterns** : Motifs de fichiers à exclure de l'analyse
- **includePatterns** : Motifs de fichiers à inclure dans l'analyse
<% } %>

## Utilisation

<% if (name === 'git-ingest') { %>
Le MCP <%= name.charAt(0).toUpperCase() + name.slice(1) %> fournit deux outils principaux :

### 1. github_directory_structure

Cet outil permet d'obtenir la structure d'un dépôt GitHub sous forme d'arborescence.

#### Paramètres :
- **repo_url** : URL du dépôt GitHub (ex: https://github.com/mem0ai/mem0)

#### Exemple d'utilisation :
```json
{
  "tool": "github_directory_structure",
  "params": {
    "repo_url": "https://github.com/mem0ai/mem0"
  }
}
```

### 2. github_read_important_files

Cet outil permet de lire le contenu de fichiers spécifiques dans un dépôt GitHub.

#### Paramètres :
- **repo_url** : URL du dépôt GitHub (ex: https://github.com/mem0ai/mem0)
- **file_paths** : Liste des chemins de fichiers à lire (ex: ["README.md", "mem0/main.py"])

#### Exemple d'utilisation :
```json
{
  "tool": "github_read_important_files",
  "params": {
    "repo_url": "https://github.com/mem0ai/mem0",
    "file_paths": ["README.md", "mem0/main.py"]
  }
}
```

### Script d'analyse de dépôt

Un script d'analyse de dépôt GitHub est disponible dans `projet/mcp/scripts/analyze-github-repo.cmd`. Ce script permet d'analyser un dépôt GitHub et de générer un rapport d'analyse.

#### Utilisation :
```powershell
.\analyze-github-repo.cmd <repo-url> [output-dir] [max-files]
```

#### Exemple :
```powershell
.\analyze-github-repo.cmd https://github.com/mem0ai/mem0 output/mem0-analysis 200
```
<% } else { %>
Le MCP <%= name.charAt(0).toUpperCase() + name.slice(1) %> peut être utilisé de deux manières :

### 1. Mode STDIO

Ce mode est utilisé pour l'intégration avec n8n et Augment. Pour démarrer le serveur en mode STDIO :

```powershell
.\start-<%= name %>-mcp.cmd
```

<% if (port) { %>
### 2. Mode HTTP

Ce mode expose une API HTTP pour interagir avec le serveur. Pour démarrer le serveur en mode HTTP :

```powershell
.\start-<%= name %>-mcp.cmd --http [--port <port>]
```

Par défaut, le serveur écoute sur le port <%= port %>. Vous pouvez spécifier un port différent avec l'option `--port`.
<% } %>
<% } %>

## Intégration avec n8n

Pour utiliser le MCP <%= name.charAt(0).toUpperCase() + name.slice(1) %> dans n8n :

1. Créez un identifiant "MCP Client (STDIO) API" avec les paramètres suivants :
   - **Credential Name**: MCP <%= name.charAt(0).toUpperCase() + name.slice(1) %>
   - **Command**: Chemin complet vers start-<%= name %>-mcp.cmd
   - **Arguments**: (laissez vide)
<% if (needsEnv) { %>
   - **Environments**: <%= envVars %>
<% } else { %>
   - **Environments**: (laissez vide)
<% } %>

2. Utilisez le nœud "MCP Client" dans vos workflows avec cet identifiant.

## Intégration avec Augment

Pour utiliser le MCP <%= name.charAt(0).toUpperCase() + name.slice(1) %> avec Augment, ajoutez la configuration suivante à votre fichier de configuration Augment :

```json
{
  "augment.mcpServers": [
    {
      "name": "MCP <%= name.charAt(0).toUpperCase() + name.slice(1) %>",
      "type": "command",
      "command": "D:\\chemin\\vers\\votre\\projet\\scripts\\start-<%= name %>-mcp.cmd"
    }
  ]
}
```

## Dépannage

Si vous rencontrez des problèmes avec le MCP <%= name.charAt(0).toUpperCase() + name.slice(1) %> :

1. Vérifiez que les prérequis sont correctement installés.
2. Vérifiez que le fichier de configuration existe et est correctement configuré.
3. Consultez les logs pour voir les erreurs éventuelles.
4. Essayez de redémarrer le serveur.

## Ressources supplémentaires

<% if (name === 'git-ingest') { %>
- [GitHub du projet mcp-git-ingest](https://github.com/adhikasp/mcp-git-ingest)
<% } %>
- [Documentation du Model Context Protocol](https://modelcontextprotocol.ai/)
- [Guide d'utilisation des MCP dans n8n](GUIDE_FINAL_MCP.md)
