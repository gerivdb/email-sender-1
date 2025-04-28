# Architecture du système MCP

Ce document décrit l'architecture du système MCP (Model Context Protocol) utilisé dans le projet EMAIL_SENDER_1.

## Vue d'ensemble

Le système MCP est composé de plusieurs composants qui interagissent entre eux pour fournir un accès aux données et aux fonctionnalités via le protocole MCP.

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│                 │     │                 │     │                 │
│  Applications   │     │      n8n        │     │   Agents IA     │
│                 │     │                 │     │                 │
└────────┬────────┘     └────────┬────────┘     └────────┬────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                       Protocole MCP                             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌────────┴────────┐     ┌────────┴────────┐     ┌────────┴────────┐
│                 │     │                 │     │                 │
│ Serveur         │     │ Serveur         │     │ Serveur         │
│ Filesystem      │     │ GitHub          │     │ Gateway         │
│                 │     │                 │     │                 │
└────────┬────────┘     └────────┬────────┘     └────────┬────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌────────┴────────┐     ┌────────┴────────┐     ┌────────┴────────┐
│                 │     │                 │     │                 │
│ Système de      │     │ Dépôts          │     │ Bases de        │
│ fichiers        │     │ GitHub          │     │ données         │
│                 │     │                 │     │                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

## Composants principaux

### Client MCP

Le client MCP est responsable de la communication avec les serveurs MCP. Il permet de :

- Se connecter à un serveur MCP
- Récupérer la liste des outils disponibles
- Exécuter des outils
- Recevoir les résultats

### Serveur MCP

Le serveur MCP implémente le protocole MCP et expose des outils via une API REST ou WebSocket. Il permet de :

- Exposer des outils
- Recevoir des requêtes
- Exécuter des outils
- Renvoyer les résultats

### Gestionnaire MCP

Le gestionnaire MCP est responsable de la gestion des serveurs MCP. Il permet de :

- Détecter les serveurs MCP disponibles
- Configurer les serveurs MCP
- Démarrer et arrêter les serveurs MCP
- Surveiller l'état des serveurs MCP

### Agent MCP

L'agent MCP utilise un modèle de langage pour exécuter des requêtes en langage naturel via le protocole MCP. Il permet de :

- Comprendre les requêtes en langage naturel
- Identifier les outils à utiliser
- Exécuter les outils
- Interpréter les résultats

## Types de serveurs

### Serveur Filesystem

Le serveur Filesystem permet d'accéder aux fichiers locaux. Il expose des outils pour :

- Lister les fichiers et dossiers
- Lire le contenu des fichiers
- Écrire dans les fichiers
- Créer et supprimer des fichiers et dossiers

### Serveur GitHub

Le serveur GitHub permet d'accéder aux dépôts GitHub. Il expose des outils pour :

- Lister les dépôts
- Lister les fichiers et dossiers
- Lire le contenu des fichiers
- Créer des issues
- Créer des pull requests

### Serveur Gateway

Le serveur Gateway permet d'accéder aux bases de données SQL. Il expose des outils pour :

- Lister les bases de données
- Lister les tables
- Exécuter des requêtes SQL
- Récupérer les résultats

### Serveur Notion

Le serveur Notion permet d'accéder aux bases de données Notion. Il expose des outils pour :

- Lister les bases de données
- Lister les pages
- Lire le contenu des pages
- Créer et modifier des pages

### Serveur GCP

Le serveur GCP permet d'accéder aux services Google Cloud Platform. Il expose des outils pour :

- Lister les projets
- Lister les buckets
- Lire et écrire des fichiers
- Exécuter des requêtes BigQuery

## Flux de données

1. L'utilisateur envoie une requête à une application (n8n, agent IA, etc.)
2. L'application utilise le client MCP pour communiquer avec le serveur MCP
3. Le serveur MCP reçoit la requête et l'exécute
4. Le serveur MCP renvoie le résultat au client MCP
5. L'application traite le résultat et le présente à l'utilisateur

## Structure du code

La structure du code est organisée comme suit :

```
projet/mcp/
├── core/                  # Composants principaux
│   ├── client/            # Client MCP
│   ├── server/            # Serveur MCP
│   └── common/            # Composants communs
├── servers/               # Serveurs spécifiques
│   ├── filesystem/        # Serveur Filesystem
│   ├── github/            # Serveur GitHub
│   ├── gateway/           # Serveur Gateway
│   ├── notion/            # Serveur Notion
│   └── gcp/               # Serveur GCP
├── scripts/               # Scripts d'utilisation
│   ├── setup/             # Scripts d'installation
│   ├── maintenance/       # Scripts de maintenance
│   └── utils/             # Scripts utilitaires
├── modules/               # Modules PowerShell
├── python/                # Implémentations Python
├── tests/                 # Tests
│   ├── unit/              # Tests unitaires
│   ├── integration/       # Tests d'intégration
│   └── performance/       # Tests de performance
├── config/                # Configuration
│   ├── templates/         # Modèles de configuration
│   ├── environments/      # Configurations par environnement
│   └── servers/           # Configurations des serveurs
├── docs/                  # Documentation
│   ├── guides/            # Guides d'utilisation
│   ├── api/               # Documentation API
│   ├── servers/           # Documentation des serveurs
│   └── development/       # Documentation pour les développeurs
├── integrations/          # Intégrations
│   └── n8n/               # Intégration avec n8n
├── monitoring/            # Monitoring
│   ├── scripts/           # Scripts de monitoring
│   ├── dashboards/        # Dashboards
│   └── alerts/            # Alertes
└── dependencies/          # Dépendances
    ├── npm/               # Dépendances npm
    ├── pip/               # Dépendances pip
    └── binary/            # Dépendances binaires
```

## Diagramme de classes

```
┌───────────────────┐     ┌───────────────────┐     ┌───────────────────┐
│   MCPClient       │     │   MCPServer       │     │   MCPManager      │
├───────────────────┤     ├───────────────────┤     ├───────────────────┤
│ - serverUrl       │     │ - port            │     │ - servers         │
│ - timeout         │     │ - tools           │     │ - config          │
├───────────────────┤     ├───────────────────┤     ├───────────────────┤
│ + connect()       │     │ + start()         │     │ + detectServers() │
│ + listTools()     │     │ + stop()          │     │ + startServer()   │
│ + executeTool()   │     │ + registerTool()  │     │ + stopServer()    │
└───────────────────┘     └───────────────────┘     └───────────────────┘
         │                         │                         │
         │                         │                         │
         ▼                         ▼                         ▼
┌───────────────────┐     ┌───────────────────┐     ┌───────────────────┐
│   MCPTool         │     │   MCPContext      │     │   MCPConfig       │
├───────────────────┤     ├───────────────────┤     ├───────────────────┤
│ - name            │     │ - request         │     │ - mcpServers      │
│ - description     │     │ - response        │     │ - global          │
│ - parameters      │     │ - user            │     ├───────────────────┤
├───────────────────┤     ├───────────────────┤     │ + load()          │
│ + execute()       │     │ + getData()       │     │ + save()          │
│ + validate()      │     │ + setData()       │     │ + validate()      │
└───────────────────┘     └───────────────────┘     └───────────────────┘
```

## Protocole MCP

Le protocole MCP est basé sur JSON-RPC et permet la communication entre les clients et les serveurs MCP. Il définit les méthodes suivantes :

- `listTools` : Liste les outils disponibles
- `executeTool` : Exécute un outil
- `getSchema` : Récupère le schéma d'un outil
- `getStatus` : Récupère l'état du serveur

## Sécurité

Le système MCP implémente plusieurs mesures de sécurité :

- Authentification par clé API
- Limitation de débit
- Validation des entrées
- Journalisation des accès
- Contrôle d'accès basé sur les rôles

## Performance

Le système MCP est conçu pour être performant et évolutif :

- Mise en cache des résultats
- Exécution parallèle des outils
- Limitation des ressources
- Surveillance des performances

## Évolutivité

Le système MCP est conçu pour être facilement extensible :

- Architecture modulaire
- Interfaces bien définies
- Configuration centralisée
- Tests automatisés
