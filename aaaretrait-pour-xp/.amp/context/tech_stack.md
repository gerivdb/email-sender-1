# Stack technique et utilisation API

Ce document détaille la stack technique du projet, les APIs utilisées et les configurations spécifiques.

## Stack technique principale

### Automatisation et workflows

- **n8n** : Plateforme d'automatisation pour les workflows
  - Version : dernière stable
  - Mode d'hébergement : local (développement), cloud (production)
  - API locale : http://localhost:5678/api/
  - Endpoints principaux : workflows, executions, tags, users

### Intelligence artificielle

- **crewAI** : Framework pour la création d'agents IA collaboratifs
  - Utilisé pour l'orchestration des tâches complexes
  - Intégration avec les LLMs pour l'analyse et la génération de contenu

### Gestion des connaissances

- **Notion** : Plateforme de gestion des connaissances et de collaboration
  - Utilisé pour la documentation et le suivi de projet
  - Intégration via API pour la synchronisation des données

### Futur

- **ERPNext** : Système ERP open-source
  - Planifié pour la gestion des clients et la facturation
  - Intégration prévue via API REST

## Serveurs MCP (Model Context Protocol)

### Serveurs configurés

- **@modelcontextprotocol/server-filesystem**
  - Accès au système de fichiers local
  - Configuration : chemin racine = répertoire du projet

- **@modelcontextprotocol/server-github**
  - Accès aux repositories GitHub
  - Configuration : token d'accès personnel pour l'authentification

- **GCP-MCP server**
  - Projet GCP : 'gen-lang-client-0391388747'
  - Utilisé pour les fonctionnalités avancées d'IA

## Langages et frameworks

### Backend

- **PowerShell 5.1** : Scripts d'automatisation et utilitaires
  - Modules principaux : PSCacheManager, ErrorPatternAnalyzer
  - Standards : PSScriptAnalyzer, Pester pour les tests

- **Python 3.9+** : Traitement de données et analyses
  - Bibliothèques principales : pandas, numpy, matplotlib, requests
  - Frameworks : FastAPI pour les services web légers

### Frontend (en développement)

- **Node.js** : Runtime JavaScript
  - Version : LTS actuelle
  - Gestionnaire de paquets : npm

- **Vue.js** (planifié) : Framework frontend progressif
  - À utiliser pour les interfaces utilisateur

## APIs et intégrations

### Gmail API

- **Scopes utilisés** :
  - gmail.send
  - gmail.compose
  - gmail.modify
- **Authentification** : OAuth2
- **Quotas** : 1000 emails/jour (limite standard)

### GitHub API

- **Utilisé pour** : Gestion des repositories, pull requests, issues
- **Authentification** : OAuth tokens
- **Webhooks** : Configurés pour les événements de pull request

### n8n API locale

- **URL** : http://localhost:5678/api/
- **Endpoints principaux** :
  - `/workflows` : Gestion des workflows
  - `/executions` : Historique et contrôle des exécutions
  - `/tags` : Organisation des workflows
  - `/users` : Gestion des utilisateurs

## Environnements

### Développement

- **OS** : Windows 10/11
- **IDE** : VS Code avec extensions spécifiques
- **Services locaux** : n8n, bases de données

### Test

- **Environnement isolé** pour les tests d'intégration
- **CI/CD** : GitHub Actions pour l'automatisation des tests

### Production (planifié)

- **Hébergement** : Cloud (GCP ou AWS)
- **Conteneurisation** : Docker pour les services
- **Orchestration** : Kubernetes pour la gestion des conteneurs

## Configuration VS Code

### Extensions recommandées

- PowerShell
- Python
- ESLint
- Prettier
- GitLens
- Augment

### Paramètres spécifiques

```json
{
  "files.maxMemoryForLargeFilesMB": 4096,
  "terminal.integrated.scrollback": 10000,
  "terminal.integrated.env.windows": {
    "LC_ALL": "fr_FR.UTF-8"
  },
  "terminal.integrated.gpuAcceleration": "on",
  "augment.chat.autoConfirmLargeMessages": true,
  "augment.chat.maxMessageSizeKB": 100
}
```plaintext
## Bases de données

### Principales

- **SQLite** : Stockage local pour le développement
  - Utilisé par n8n pour les workflows
  - Utilisé pour le cache et les métriques de performance

### Futures

- **PostgreSQL** : Pour l'environnement de production
- **Redis** : Pour le cache distribué
