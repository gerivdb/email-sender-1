# MCP (Model Context Protocol) - EMAIL_SENDER_1

Ce répertoire contient tous les serveurs MCP (Model Context Protocol) utilisés dans le projet EMAIL_SENDER_1.

## Qu'est-ce que le MCP ?

Le Model Context Protocol (MCP) est un protocole qui permet aux modèles d'IA d'interagir avec des outils et des services externes. Il permet d'étendre les capacités des modèles d'IA en leur donnant accès à des données et des fonctionnalités qui ne sont pas disponibles dans leur contexte de base.

## Serveurs MCP disponibles

| Nom | Description | Port | Documentation |
|-----|-------------|------|---------------|
| filesystem | Accès aux fichiers locaux | - | [Guide](../guides/mcp/GUIDE_FINAL_MCP.md) |
| github | Accès aux dépôts GitHub | - | [Guide](../guides/mcp/GITHUB_MCP.md) |
| git-ingest | Exploration et lecture des structures de dépôts GitHub | 8001 | [Guide](../guides/mcp/GUIDE_MCP_GIT_INGEST.md) |
| gcp | Accès à Google Cloud Platform | - | [Guide](../guides/mcp/GUIDE_FINAL_MCP.md) |
| notion | Accès à Notion | - | [Guide](../guides/mcp/GUIDE_FINAL_MCP.md) |
| gateway | Passerelle MCP | - | [Guide](../guides/mcp/GUIDE_MCP_GATEWAY.md) |
| n8n | Accès à n8n | 5678 | [Guide](../guides/mcp/GUIDE_FINAL_MCP.md) |
| desktop-commander | Manipulation de fichiers et exécution de commandes terminal | 8080 | [Guide](../guides/mcp/GUIDE_MCP_DESKTOP_COMMANDER.md) |

## Structure des répertoires

```plaintext
/projet/mcp/
├── _templates/           # Templates Hygen pour générer des serveurs MCP

├── config/               # Configuration des serveurs MCP

│   ├── mcp-config.json   # Configuration principale

│   └── servers/          # Configuration spécifique à chaque serveur

├── core/                 # Fonctionnalités de base

├── dependencies/         # Dépendances des serveurs MCP

├── docs/                 # Documentation technique

├── integrations/         # Intégrations avec d'autres systèmes

├── modules/              # Modules PowerShell

├── monitoring/           # Surveillance des serveurs MCP

├── python/               # Scripts Python

├── scripts/              # Scripts de gestion

├── servers/              # Serveurs MCP

│   ├── filesystem/       # Serveur MCP Filesystem

│   ├── gateway/          # Serveur MCP Gateway

│   ├── gcp/              # Serveur MCP GCP

│   ├── github/           # Serveur MCP GitHub

│   ├── git-ingest/       # Serveur MCP Git Ingest

│   ├── notion/           # Serveur MCP Notion

│   └── desktop-commander/ # Serveur MCP Desktop Commander

├── tests/                # Tests des serveurs MCP

└── versioning/           # Gestion des versions

```plaintext
## Scripts disponibles

### Gestion des serveurs MCP

- `scripts/start-all-mcp-servers.cmd` : Démarre tous les serveurs MCP
- `scripts/stop-all-mcp-servers.cmd` : Arrête tous les serveurs MCP
- `scripts/restart-all-mcp-servers.cmd` : Redémarre tous les serveurs MCP
- `scripts/check-mcp-servers.cmd` : Vérifie l'état des serveurs MCP

### Serveurs individuels

- `scripts/start-filesystem-mcp.cmd` : Démarre le serveur MCP Filesystem
- `scripts/start-github-mcp.cmd` : Démarre le serveur MCP GitHub
- `scripts/start-git-ingest-mcp.cmd` : Démarre le serveur MCP Git Ingest
- `scripts/start-gcp-mcp.cmd` : Démarre le serveur MCP GCP
- `scripts/start-notion-mcp.cmd` : Démarre le serveur MCP Notion
- `scripts/start-gateway-mcp.cmd` : Démarre le serveur MCP Gateway
- `scripts/start-desktop-commander-mcp.cmd` : Démarre le serveur MCP Desktop Commander

### Outils

- `scripts/analyze-github-repo.cmd` : Analyse un dépôt GitHub avec MCP Git Ingest
- `scripts/generate-mcp-server.cmd` : Génère un nouveau serveur MCP avec Hygen

## Utilisation

### Démarrer tous les serveurs MCP

```powershell
.\scripts\start-all-mcp-servers.cmd
```plaintext
### Démarrer un serveur MCP spécifique

```powershell
.\scripts\start-git-ingest-mcp.cmd
```plaintext
### Analyser un dépôt GitHub

```powershell
.\scripts\analyze-github-repo.cmd https://github.com/mem0ai/mem0 output/mem0-analysis 200
```plaintext
### Générer un nouveau serveur MCP

```powershell
.\scripts\generate-mcp-server.cmd nom-serveur "description du serveur" commande "arg1,arg2,arg3" "ENV_VAR=valeur" port
```plaintext
## Configuration

La configuration principale des serveurs MCP se trouve dans le fichier `config/mcp-config.json`. Chaque serveur a également sa propre configuration dans le répertoire `config/servers/`.

## Documentation

La documentation des serveurs MCP se trouve dans le répertoire `../guides/mcp/`.

## Intégration avec n8n

Les serveurs MCP peuvent être utilisés dans n8n via le nœud "MCP Client". Consultez le [Guide d'utilisation des MCP dans n8n](../guides/mcp/GUIDE_FINAL_MCP.md) pour plus d'informations.

## Intégration avec Augment

Les serveurs MCP peuvent être utilisés avec Augment en ajoutant la configuration appropriée dans le fichier de configuration d'Augment. Consultez le [Guide d'utilisation des MCP avec Augment](../guides/mcp/GUIDE_FINAL_MCP.md) pour plus d'informations.
