# Guide d'utilisation du MCP Git Ingest dans n8n

## Introduction

Le MCP Git Ingest est un serveur MCP (Model Context Protocol) qui permet d'explorer et de lire les structures de dépôts GitHub et les fichiers importants. Ce guide vous explique comment configurer et utiliser le MCP Git Ingest dans vos workflows n8n.

## Prérequis

- n8n version 1.0.0 ou ultérieure
- Python 3.8 ou ultérieur
- uvx (installé via pip)
- mcp-git-ingest (installé via pip)

## Installation

1. Assurez-vous que Python et pip sont installés sur votre système.
2. Installez uvx et mcp-git-ingest :
   ```powershell
   pip install uvx==1.0.0
   pip install git+https://github.com/adhikasp/mcp-git-ingest
   ```
3. Exécutez le script `scripts\configure-mcp-git-ingest.ps1` pour configurer le MCP Git Ingest dans n8n :
   ```powershell
   .\scripts\configure-mcp-git-ingest.ps1
   ```

## Configuration dans n8n

1. Ouvrez n8n et accédez à "Credentials"
2. Vérifiez que l'identifiant "MCP Git Ingest" a été créé
3. Si ce n'est pas le cas, créez un nouvel identifiant "MCP Client (STDIO) API" avec les paramètres suivants :
   - **Credential Name**: MCP Git Ingest
   - **Command**: Chemin complet vers mcp-git-ingest.cmd
   - **Arguments**: (laissez vide)
   - **Environments**: N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true

## Utilisation dans les workflows

Le MCP Git Ingest fournit deux outils principaux :

### 1. github_directory_structure

Cet outil permet d'obtenir la structure d'un dépôt GitHub sous forme d'arborescence.

#### Paramètres :
- **repo_url** : URL du dépôt GitHub (ex: https://github.com/adhikasp/mcp-git-ingest)

#### Exemple d'utilisation :
1. Ajoutez un nœud MCP Client à votre workflow
2. Sélectionnez l'identifiant "MCP Git Ingest"
3. Configurez l'opération "Execute Tool"
4. Sélectionnez l'outil "github_directory_structure"
5. Définissez le paramètre "repo_url" avec l'URL du dépôt GitHub

### 2. github_read_important_files

Cet outil permet de lire le contenu de fichiers spécifiques dans un dépôt GitHub.

#### Paramètres :
- **repo_url** : URL du dépôt GitHub (ex: https://github.com/adhikasp/mcp-git-ingest)
- **file_paths** : Liste des chemins de fichiers à lire (ex: ["README.md", "src/main.py"])

#### Exemple d'utilisation :
1. Ajoutez un nœud MCP Client à votre workflow
2. Sélectionnez l'identifiant "MCP Git Ingest"
3. Configurez l'opération "Execute Tool"
4. Sélectionnez l'outil "github_read_important_files"
5. Définissez les paramètres "repo_url" et "file_paths"

## Exemple de workflow

Voici un exemple de workflow qui utilise le MCP Git Ingest pour explorer un dépôt GitHub et lire ses fichiers importants :

1. **Déclencheur** : Nœud "Manual Trigger"
2. **Exploration du dépôt** : Nœud MCP Client avec l'outil "github_directory_structure"
3. **Lecture des fichiers** : Nœud MCP Client avec l'outil "github_read_important_files"
4. **Traitement des données** : Nœuds supplémentaires pour traiter les informations obtenues

## Dépannage

Si vous rencontrez des problèmes avec le MCP Git Ingest :

1. Vérifiez que Python et uvx sont correctement installés :
   ```powershell
   python --version
   uvx --version
   ```

2. Vérifiez que la variable d'environnement N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE est définie à true :
   ```powershell
   [Environment]::GetEnvironmentVariable('N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE', 'User')
   ```

3. Vérifiez que le fichier mcp-git-ingest.cmd est exécutable :
   ```powershell
   .\mcp-git-ingest.cmd
   ```

4. Consultez les logs de n8n pour voir les erreurs éventuelles.

## Ressources supplémentaires

- [GitHub du projet mcp-git-ingest](https://github.com/adhikasp/mcp-git-ingest)
- [Documentation du Model Context Protocol](https://modelcontextprotocol.ai/)
- [Guide d'utilisation des MCP dans n8n](../guides/GUIDE_FINAL_MCP.md)

