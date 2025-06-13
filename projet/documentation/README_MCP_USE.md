# IntÃ©gration de mcp-use pour la gestion des serveurs MCP

Ce document explique comment utiliser la bibliothÃ¨que `mcp-use` pour amÃ©liorer la gestion des serveurs MCP (Model Context Protocol) dans le projet EMAIL_SENDER_1.

## Introduction

`mcp-use` est une bibliothÃ¨que open source qui permet de connecter facilement n'importe quel modÃ¨le de langage (LLM) Ã  n'importe quel serveur MCP. Cette intÃ©gration offre plusieurs avantages :

- Gestion unifiÃ©e des serveurs MCP
- SÃ©lection dynamique des serveurs
- Support HTTP natif
- IntÃ©gration avec LangChain
- ContrÃ´le d'accÃ¨s aux outils

## PrÃ©requis

- Python 3.11 ou supÃ©rieur
- PowerShell 5.1 ou supÃ©rieur
- Node.js et npm (pour les serveurs MCP basÃ©s sur npm)

## Installation

Les scripts fournis installeront automatiquement les packages Python nÃ©cessaires :
- mcp-use
- langchain-openai
- python-dotenv

## Fichiers inclus

1. `mcp-manager.ps1` : Script PowerShell pour dÃ©marrer le gestionnaire de serveurs MCP ou un agent MCP
2. `mcp_manager.py` : Script Python pour gÃ©rer les serveurs MCP
3. `mcp_agent.py` : Script Python pour utiliser les agents MCP
4. `README_MCP_USE.md` : Ce document

## Configuration

Le script `mcp_manager.py` crÃ©era automatiquement un fichier de configuration `mcp-servers/mcp-config.json` qui dÃ©finit tous les serveurs MCP disponibles. Cette configuration inclut :

- Serveur MCP Filesystem
- Serveur MCP GitHub (si configurÃ©)
- Serveur MCP GCP (si configurÃ©)
- Serveur MCP n8n
- Serveur MCP Augment

## Utilisation

### DÃ©marrer le gestionnaire de serveurs MCP

```powershell
.\mcp-manager.ps1
```plaintext
Ce script dÃ©marrera le gestionnaire de serveurs MCP qui :
1. VÃ©rifie si les packages nÃ©cessaires sont installÃ©s
2. CrÃ©e ou charge la configuration des serveurs MCP
3. Initialise tous les serveurs MCP
4. VÃ©rifie l'Ã©tat des serveurs MCP
5. Garde les serveurs actifs jusqu'Ã  ce que l'utilisateur appuie sur Ctrl+C

### ExÃ©cuter un agent MCP

```powershell
.\mcp-manager.ps1 -Agent
```plaintext
Ce script dÃ©marrera un agent MCP qui :
1. VÃ©rifie si la configuration des serveurs MCP existe
2. Demande Ã  l'utilisateur d'entrer une requÃªte
3. ExÃ©cute la requÃªte en utilisant les serveurs MCP disponibles
4. Affiche le rÃ©sultat

### ExÃ©cuter un agent MCP avec une requÃªte spÃ©cifique

```powershell
.\mcp-manager.ps1 -Agent -Query "Trouve les meilleurs restaurants Ã  Paris"
```plaintext
Ce script dÃ©marrera un agent MCP et exÃ©cutera la requÃªte spÃ©cifiÃ©e.

## RÃ©solution des problÃ¨mes

### Erreur "Failed to initialize server"

Si vous rencontrez une erreur lors de l'initialisation d'un serveur MCP, vÃ©rifiez que :
1. Le serveur MCP est installÃ© et configurÃ© correctement
2. Le serveur MCP est accessible Ã  l'URL ou au port spÃ©cifiÃ©
3. Les informations d'authentification (si nÃ©cessaires) sont correctes

### Erreur "OpenAI API key not found"

Si vous rencontrez une erreur liÃ©e Ã  la clÃ© API OpenAI, vous pouvez :
1. Ajouter votre clÃ© API OpenAI au fichier `.env` Ã  la racine du projet
2. Ou entrer votre clÃ© API lorsque le script vous le demande

## Comparaison avec l'implÃ©mentation prÃ©cÃ©dente

Cette nouvelle implÃ©mentation basÃ©e sur `mcp-use` offre plusieurs avantages par rapport Ã  l'implÃ©mentation prÃ©cÃ©dente :

1. **StabilitÃ© amÃ©liorÃ©e** : La dÃ©tection des serveurs MCP est plus fiable
2. **Configuration centralisÃ©e** : Tous les serveurs MCP sont dÃ©finis dans un seul fichier
3. **SÃ©lection dynamique des serveurs** : Les agents peuvent choisir le serveur le plus appropriÃ©
4. **Support HTTP natif** : Connexion directe aux serveurs MCP via HTTP
5. **IntÃ©gration avec LangChain** : Utilisation facile des modÃ¨les LLM avec les serveurs MCP

## Prochaines Ã©tapes

1. Migrer progressivement les scripts existants vers cette nouvelle implÃ©mentation
2. Ajouter le support pour d'autres serveurs MCP (Notion, GDrive, etc.)
3. IntÃ©grer cette solution Ã  n8n et aux autres outils du projet

## Ressources

- [Documentation mcp-use](https://docs.mcp-use.io)
- [GitHub mcp-use](https://github.com/pietrozullo/mcp-use)
- [Awesome MCP Servers](https://github.com/punkpeye/awesome-mcp-servers)

