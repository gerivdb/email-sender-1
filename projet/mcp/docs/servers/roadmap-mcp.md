# Serveur MCP Roadmap

## Introduction

Le serveur MCP Roadmap est une implémentation du Model Context Protocol (MCP) spécifiquement conçue pour interagir avec notre système de gestion de roadmaps. Inspiré par le projet claude-task-master, ce serveur permet aux modèles d'IA comme Claude d'interagir directement avec les roadmaps, d'effectuer des recherches, de générer des visualisations et de manipuler les tâches.

## Fonctionnalités

### Gestion des roadmaps
- Lecture et écriture de roadmaps au format Markdown et JSON
- Création, modification et suppression de tâches
- Gestion des dépendances entre tâches
- Suivi de l'avancement des tâches

### Analyse et recherche
- Recherche par mots-clés dans les roadmaps
- Recherche sémantique avec embeddings vectoriels
- Analyse de la structure des roadmaps
- Détection des dépendances implicites

### Visualisation
- Génération de graphes de dépendances
- Création de diagrammes de Gantt
- Visualisation de l'avancement global
- Représentation des chemins critiques

### Intégration
- Synchronisation avec Notion
- Intégration avec GitHub Issues
- Connexion avec n8n pour l'automatisation
- Extension VS Code pour l'édition directe

## Architecture

```
┌─────────────────────┐      ┌─────────────────────┐
│                     │      │                     │
│  Interface MCP      │◄────►│  Gestionnaire de    │
│  (HTTP/WebSocket)   │      │  Roadmaps           │
│                     │      │                     │
└─────────────────────┘      └─────────┬───────────┘
                                       │
                                       │
                                       ▼
┌─────────────────────┐      ┌─────────────────────┐
│                     │      │                     │
│  Stockage           │◄────►│  Analyseur          │
│  (Fichiers/DB)      │      │  (Parser/Validator) │
│                     │      │                     │
└─────────────────────┘      └─────────────────────┘
```

### Composants

1. **Interface MCP** : Implémente le protocole MCP pour communiquer avec les modèles d'IA
2. **Gestionnaire de Roadmaps** : Coordonne les opérations sur les roadmaps
3. **Stockage** : Gère la persistance des roadmaps (fichiers Markdown, base de données)
4. **Analyseur** : Parse, valide et analyse les roadmaps

## Installation

### Prérequis
- Node.js 16 ou supérieur
- npm ou yarn
- Accès au système de fichiers pour le stockage des roadmaps

### Installation automatique

```bash
# Installation via npm
npm install -g @email-sender-1/mcp-roadmap-server

# Installation via le script d'installation
./projet/mcp/scripts/setup/setup-mcp-roadmap.ps1
```

### Installation manuelle

```bash
# Cloner le dépôt
git clone https://github.com/email-sender-1/mcp-roadmap-server.git

# Installer les dépendances
cd mcp-roadmap-server
npm install

# Construire le projet
npm run build

# Lier globalement
npm link
```

## Configuration

Le serveur MCP Roadmap peut être configuré via un fichier de configuration JSON ou des variables d'environnement.

### Fichier de configuration

```json
{
  "server": {
    "port": 3000,
    "host": "localhost"
  },
  "storage": {
    "type": "filesystem",
    "path": "./roadmaps"
  },
  "search": {
    "engine": "vector",
    "model": "openai/text-embedding-ada-002"
  },
  "integrations": {
    "notion": {
      "enabled": true,
      "apiKey": "your-notion-api-key"
    },
    "github": {
      "enabled": true,
      "token": "your-github-token"
    }
  }
}
```

### Variables d'environnement

```
MCP_ROADMAP_PORT=3000
MCP_ROADMAP_HOST=localhost
MCP_ROADMAP_STORAGE_TYPE=filesystem
MCP_ROADMAP_STORAGE_PATH=./roadmaps
MCP_ROADMAP_SEARCH_ENGINE=vector
MCP_ROADMAP_SEARCH_MODEL=openai/text-embedding-ada-002
MCP_ROADMAP_NOTION_ENABLED=true
MCP_ROADMAP_NOTION_API_KEY=your-notion-api-key
MCP_ROADMAP_GITHUB_ENABLED=true
MCP_ROADMAP_GITHUB_TOKEN=your-github-token
```

## Utilisation

### Démarrage du serveur

```bash
# Démarrage avec la configuration par défaut
mcp-roadmap-server

# Démarrage avec un fichier de configuration personnalisé
mcp-roadmap-server --config ./config.json

# Démarrage avec des options en ligne de commande
mcp-roadmap-server --port 3000 --storage-type filesystem --storage-path ./roadmaps
```

### Intégration avec n8n

Pour utiliser le serveur MCP Roadmap dans n8n, configurez un nœud MCP avec les paramètres suivants :

```json
{
  "mcpServers": {
    "roadmap": {
      "command": "mcp-roadmap-server",
      "args": ["--config", "path/to/config.json"],
      "env": {
        "MCP_ROADMAP_NOTION_API_KEY": "your-notion-api-key"
      }
    }
  }
}
```

### Intégration avec Cursor/VS Code

Pour utiliser le serveur MCP Roadmap dans Cursor ou VS Code, ajoutez la configuration suivante :

```json
{
  "mcpServers": {
    "roadmap": {
      "command": "mcp-roadmap-server",
      "args": ["--config", "path/to/config.json"]
    }
  }
}
```

## API MCP

Le serveur MCP Roadmap expose les fonctions suivantes via le protocole MCP :

### Gestion des roadmaps

- `listRoadmaps()` : Liste toutes les roadmaps disponibles
- `getRoadmap(id)` : Récupère une roadmap par son ID
- `createRoadmap(data)` : Crée une nouvelle roadmap
- `updateRoadmap(id, data)` : Met à jour une roadmap existante
- `deleteRoadmap(id)` : Supprime une roadmap

### Gestion des tâches

- `listTasks(roadmapId)` : Liste toutes les tâches d'une roadmap
- `getTask(roadmapId, taskId)` : Récupère une tâche par son ID
- `createTask(roadmapId, data)` : Crée une nouvelle tâche
- `updateTask(roadmapId, taskId, data)` : Met à jour une tâche existante
- `deleteTask(roadmapId, taskId)` : Supprime une tâche
- `completeTask(roadmapId, taskId)` : Marque une tâche comme terminée

### Recherche et analyse

- `searchRoadmaps(query)` : Recherche dans les roadmaps
- `searchTasks(query)` : Recherche dans les tâches
- `analyzeDependencies(roadmapId)` : Analyse les dépendances d'une roadmap
- `findCriticalPath(roadmapId)` : Trouve le chemin critique d'une roadmap
- `suggestNextTasks(roadmapId)` : Suggère les prochaines tâches à accomplir

### Visualisation

- `generateDependencyGraph(roadmapId)` : Génère un graphe de dépendances
- `generateGanttChart(roadmapId)` : Génère un diagramme de Gantt
- `generateProgressReport(roadmapId)` : Génère un rapport d'avancement

## Exemples d'utilisation

### Exemple 1 : Lister les roadmaps

```javascript
const response = await mcp.invoke("roadmap", "listRoadmaps");
console.log(response.data);
```

### Exemple 2 : Créer une tâche

```javascript
const response = await mcp.invoke("roadmap", "createTask", {
  roadmapId: "roadmap-1",
  data: {
    title: "Implémenter la recherche sémantique",
    description: "Ajouter la recherche sémantique avec embeddings vectoriels",
    status: "todo",
    metadata: {
      priority: "high",
      estimated_duration: "3d"
    },
    dependencies: ["task-1", "task-2"]
  }
});
console.log(response.data);
```

### Exemple 3 : Rechercher des tâches

```javascript
const response = await mcp.invoke("roadmap", "searchTasks", {
  query: "recherche sémantique",
  filters: {
    status: "todo",
    priority: "high"
  }
});
console.log(response.data);
```

### Exemple 4 : Générer un graphe de dépendances

```javascript
const response = await mcp.invoke("roadmap", "generateDependencyGraph", {
  roadmapId: "roadmap-1",
  format: "svg"
});
console.log(response.data);
```

## Développement

### Structure du projet

```
mcp-roadmap-server/
├── src/
│   ├── api/           # API MCP
│   ├── core/          # Logique métier
│   ├── storage/       # Gestion du stockage
│   ├── analysis/      # Analyse et recherche
│   ├── visualization/ # Génération de visualisations
│   └── integrations/  # Intégrations externes
├── config/            # Configuration
├── tests/             # Tests
└── docs/              # Documentation
```

### Contribuer

1. Forker le dépôt
2. Créer une branche pour votre fonctionnalité (`git checkout -b feature/ma-fonctionnalite`)
3. Committer vos changements (`git commit -am 'Ajouter ma fonctionnalité'`)
4. Pousser vers la branche (`git push origin feature/ma-fonctionnalite`)
5. Créer une Pull Request

## Conclusion

Le serveur MCP Roadmap offre une interface puissante pour interagir avec notre système de gestion de roadmaps via le protocole MCP. En s'inspirant du projet claude-task-master, il permet aux modèles d'IA comme Claude d'accéder et de manipuler les roadmaps de manière intuitive et efficace.
