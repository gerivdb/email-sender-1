# Intégration de mcp-use pour la gestion des serveurs MCP

Ce document explique comment utiliser la bibliothèque `mcp-use` pour améliorer la gestion des serveurs MCP (Model Context Protocol) dans le projet EMAIL_SENDER_1.

## Introduction

`mcp-use` est une bibliothèque open source qui permet de connecter facilement n'importe quel modèle de langage (LLM) à n'importe quel serveur MCP. Cette intégration offre plusieurs avantages :

- Gestion unifiée des serveurs MCP
- Sélection dynamique des serveurs
- Support HTTP natif
- Intégration avec LangChain
- Contrôle d'accès aux outils

## Prérequis

- Python 3.11 ou supérieur
- PowerShell 5.1 ou supérieur
- Node.js et npm (pour les serveurs MCP basés sur npm)

## Installation

Les scripts fournis installeront automatiquement les packages Python nécessaires :
- mcp-use
- langchain-openai
- python-dotenv

## Fichiers inclus

1. `Start-MCPManager.ps1` : Script PowerShell pour démarrer le gestionnaire de serveurs MCP ou un agent MCP
2. `mcp_manager.py` : Script Python pour gérer les serveurs MCP
3. `mcp_agent.py` : Script Python pour utiliser les agents MCP
4. `README_MCP_USE.md` : Ce document

## Configuration

Le script `mcp_manager.py` créera automatiquement un fichier de configuration `mcp-servers/mcp-config.json` qui définit tous les serveurs MCP disponibles. Cette configuration inclut :

- Serveur MCP Filesystem
- Serveur MCP GitHub (si configuré)
- Serveur MCP GCP (si configuré)
- Serveur MCP n8n
- Serveur MCP Augment

## Utilisation

### Démarrer le gestionnaire de serveurs MCP

```powershell
.\Start-MCPManager.ps1
```

Ce script démarrera le gestionnaire de serveurs MCP qui :
1. Vérifie si les packages nécessaires sont installés
2. Crée ou charge la configuration des serveurs MCP
3. Initialise tous les serveurs MCP
4. Vérifie l'état des serveurs MCP
5. Garde les serveurs actifs jusqu'à ce que l'utilisateur appuie sur Ctrl+C

### Exécuter un agent MCP

```powershell
.\Start-MCPManager.ps1 -Agent
```

Ce script démarrera un agent MCP qui :
1. Vérifie si la configuration des serveurs MCP existe
2. Demande à l'utilisateur d'entrer une requête
3. Exécute la requête en utilisant les serveurs MCP disponibles
4. Affiche le résultat

### Exécuter un agent MCP avec une requête spécifique

```powershell
.\Start-MCPManager.ps1 -Agent -Query "Trouve les meilleurs restaurants à Paris"
```

Ce script démarrera un agent MCP et exécutera la requête spécifiée.

## Résolution des problèmes

### Erreur "Failed to initialize server"

Si vous rencontrez une erreur lors de l'initialisation d'un serveur MCP, vérifiez que :
1. Le serveur MCP est installé et configuré correctement
2. Le serveur MCP est accessible à l'URL ou au port spécifié
3. Les informations d'authentification (si nécessaires) sont correctes

### Erreur "OpenAI API key not found"

Si vous rencontrez une erreur liée à la clé API OpenAI, vous pouvez :
1. Ajouter votre clé API OpenAI au fichier `.env` à la racine du projet
2. Ou entrer votre clé API lorsque le script vous le demande

## Comparaison avec l'implémentation précédente

Cette nouvelle implémentation basée sur `mcp-use` offre plusieurs avantages par rapport à l'implémentation précédente :

1. **Stabilité améliorée** : La détection des serveurs MCP est plus fiable
2. **Configuration centralisée** : Tous les serveurs MCP sont définis dans un seul fichier
3. **Sélection dynamique des serveurs** : Les agents peuvent choisir le serveur le plus approprié
4. **Support HTTP natif** : Connexion directe aux serveurs MCP via HTTP
5. **Intégration avec LangChain** : Utilisation facile des modèles LLM avec les serveurs MCP

## Prochaines étapes

1. Migrer progressivement les scripts existants vers cette nouvelle implémentation
2. Ajouter le support pour d'autres serveurs MCP (Notion, GDrive, etc.)
3. Intégrer cette solution à n8n et aux autres outils du projet

## Ressources

- [Documentation mcp-use](https://docs.mcp-use.io)
- [GitHub mcp-use](https://github.com/pietrozullo/mcp-use)
- [Awesome MCP Servers](https://github.com/punkpeye/awesome-mcp-servers)
