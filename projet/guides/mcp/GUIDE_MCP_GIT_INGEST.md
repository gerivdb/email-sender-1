# Guide d'utilisation du MCP Git Ingest

## Introduction

Le MCP Git Ingest est un serveur MCP (Model Context Protocol) qui permet d'explorer et de lire les structures de dépôts GitHub et les fichiers importants. Ce guide vous explique comment configurer et utiliser le MCP Git Ingest dans vos workflows.

## Prérequis

- Python 3.8 ou ultérieur
- pip (installé avec Python)
- Git installé sur votre système

## Installation

1. Assurez-vous que Python et pip sont installés sur votre système.
2. Exécutez le script `scripts\setup-mcp-git-ingest.cmd` pour installer et configurer le serveur MCP Git Ingest :
   ```powershell
   .\scripts\setup-mcp-git-ingest.cmd
   ```
3. Pour forcer la réinstallation, utilisez l'option `--force` :
   ```powershell
   .\scripts\setup-mcp-git-ingest.cmd --force
   ```

## Configuration

Le serveur MCP Git Ingest est configuré dans le fichier `projet/mcp/config/servers/git-ingest.json`. Voici les principales options de configuration :

- **port** : Port sur lequel le serveur écoute en mode HTTP (par défaut : 8001)
- **outputDir** : Répertoire de sortie pour les résultats d'analyse
- **cloneDir** : Répertoire pour cloner les dépôts GitHub
- **maxFiles** : Nombre maximum de fichiers à analyser
- **excludePatterns** : Motifs de fichiers à exclure de l'analyse
- **includePatterns** : Motifs de fichiers à inclure dans l'analyse
- **cacheEnabled** : Active ou désactive le cache
- **cacheTTL** : Durée de vie du cache en secondes

## Utilisation

Le MCP Git Ingest fournit deux outils principaux :

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
```plaintext
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
```plaintext
### Script d'analyse de dépôt

Un script d'analyse de dépôt GitHub est disponible dans `projet/mcp/scripts/analyze-github-repo.cmd`. Ce script permet d'analyser un dépôt GitHub et de générer un rapport d'analyse.

#### Utilisation :

```powershell
.\analyze-github-repo.cmd <repo-url> [output-dir] [max-files]
```plaintext
#### Exemple :

```powershell
.\analyze-github-repo.cmd https://github.com/mem0ai/mem0 output/mem0-analysis 200
```plaintext
### Analyse du dépôt mem0ai/mem0

Un script spécifique pour analyser le dépôt mem0ai/mem0 est disponible dans `projet/mcp/scripts/analyze-mem0.cmd`. Ce script permet d'analyser le dépôt mem0ai/mem0 et de générer un rapport d'analyse.

#### Utilisation :

```powershell
.\analyze-mem0.cmd
```plaintext
## Démarrage du serveur

### 1. Mode STDIO

Ce mode est utilisé pour l'intégration avec n8n et Augment. Pour démarrer le serveur en mode STDIO :

```powershell
.\start-git-ingest-mcp.cmd
```plaintext
### 2. Mode HTTP

Ce mode expose une API HTTP pour interagir avec le serveur. Pour démarrer le serveur en mode HTTP :

```powershell
.\start-git-ingest-mcp.cmd --http [--port <port>]
```plaintext
Par défaut, le serveur écoute sur le port 8001. Vous pouvez spécifier un port différent avec l'option `--port`.

## Intégration avec n8n

Pour utiliser le MCP Git Ingest dans n8n :

1. Créez un identifiant "MCP Client (STDIO) API" avec les paramètres suivants :
   - **Credential Name**: MCP Git Ingest
   - **Command**: Chemin complet vers start-git-ingest-mcp.cmd
   - **Arguments**: (laissez vide)
   - **Environments**: N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true

2. Utilisez le nœud "MCP Client" dans vos workflows avec cet identifiant.

### Exemple d'utilisation dans n8n

1. Ajoutez un nœud MCP Client à votre workflow
2. Sélectionnez l'identifiant "MCP Git Ingest"
3. Configurez l'opération "Execute Tool"
4. Sélectionnez l'outil "github_directory_structure" ou "github_read_important_files"
5. Définissez les paramètres nécessaires

### Exemple de workflow

Voici un exemple de workflow qui utilise le MCP Git Ingest pour explorer un dépôt GitHub et lire ses fichiers importants :

1. **Déclencheur** : Nœud "Manual Trigger"
2. **Exploration du dépôt** : Nœud MCP Client avec l'outil "github_directory_structure"
3. **Lecture des fichiers** : Nœud MCP Client avec l'outil "github_read_important_files"
4. **Traitement des données** : Nœuds supplémentaires pour traiter les informations obtenues

## Intégration avec Augment

Pour utiliser le MCP Git Ingest avec Augment, ajoutez la configuration suivante à votre fichier de configuration Augment :

```json
{
  "augment.mcpServers": [
    {
      "name": "MCP Git Ingest",
      "type": "command",
      "command": "D:\\chemin\\vers\\votre\\projet\\scripts\\start-git-ingest-mcp.cmd"
    }
  ]
}
```plaintext
## Dépannage

Si vous rencontrez des problèmes avec le MCP Git Ingest :

1. Vérifiez que Python et pip sont correctement installés sur votre système :
   ```powershell
   python --version
   python -m pip --version
   ```

2. Vérifiez que le package mcp-git-ingest est correctement installé :
   ```powershell
   python -m pip list | Select-String -Pattern "mcp-git-ingest"
   ```

3. Vérifiez que le fichier de configuration existe et est correctement configuré :
   ```powershell
   Get-Content "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\projet\mcp\config\servers\git-ingest.json"
   ```

4. Consultez les logs pour voir les erreurs éventuelles.

5. Essayez de réinstaller le package avec l'option `--force` :
   ```powershell
   .\setup-mcp-git-ingest.cmd --force
   ```

6. Vérifiez que Git est correctement installé sur votre système :
   ```powershell
   git --version
   ```

## Ressources supplémentaires

- [GitHub du projet mcp-git-ingest](https://github.com/adhikasp/mcp-git-ingest)
- [Documentation du Model Context Protocol](https://modelcontextprotocol.ai/)
- [Guide d'utilisation des MCP dans n8n](GUIDE_FINAL_MCP.md)
