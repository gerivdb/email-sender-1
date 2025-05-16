# Système de gestion de roadmap

Ce dossier contient les scripts pour le système de gestion de roadmap du projet EMAIL_SENDER_1.

## Structure des dossiers

```
roadmap/
├── core/                   # Fonctionnalités fondamentales
│   ├── parser/             # Scripts de parsing de roadmap
│   ├── model/              # Modèles de données
│   ├── converter/          # Convertisseurs de format
│   └── manager/            # Scripts de gestion principale
├── utils/                  # Utilitaires
│   ├── helpers/            # Fonctions d'aide
│   ├── export/             # Exportation vers différents formats
│   └── import/             # Importation depuis différentes sources
├── rag/                    # Système RAG
│   ├── core/               # Fonctionnalités RAG principales
│   ├── vectorization/      # Scripts de vectorisation
│   ├── search/             # Scripts de recherche
│   ├── metadata/           # Gestion des métadonnées
│   └── config/             # Configuration du système RAG
├── integration/            # Intégrations avec d'autres systèmes
│   ├── n8n/                # Intégration avec n8n
│   └── notion/             # Intégration avec Notion
├── maintenance/            # Scripts de maintenance
│   ├── cleanup/            # Nettoyage et archivage
│   └── validation/         # Validation de structure
├── visualization/          # Visualisation des roadmaps
├── tests/                  # Tests unitaires et d'intégration
└── docs/                   # Documentation
    ├── examples/           # Exemples d'utilisation
    └── guides/             # Guides d'utilisation
```

## Scripts principaux

### Core

- **Manage-Roadmap.ps1** - Script principal pour gérer la roadmap
- **Update-RoadmapStatus.ps1** - Met à jour le statut des tâches dans la roadmap
- **Update-TaskStatus.ps1** - Met à jour le statut d'une tâche spécifique
- **Update-ParentTaskStatus.ps1** - Met à jour le statut des tâches parentes

### RAG (Retrieval-Augmented Generation)

- **Invoke-RoadmapRAG.ps1** - Script principal pour le système RAG
- **Convert-TaskToVector.ps1** - Convertit les tâches en vecteurs
- **Search-TasksSemanticQdrant.ps1** - Recherche sémantique dans Qdrant
- **Search-TasksQdrant.ps1** - Recherche dans Qdrant
- **Search-TasksSemantic.ps1** - Recherche sémantique générique

### Utils

- **Navigate-Roadmap.ps1** - Navigation dans la roadmap
- **Get-RoadmapFiles.ps1** - Récupère les fichiers de roadmap

### Visualization

- **Generate-RoadmapView.ps1** - Génère des vues de la roadmap

## Utilisation

Pour utiliser le système de gestion de roadmap, exécutez le script principal:

```powershell
.\core\manager\Manage-Roadmap.ps1 -Action <Action> [options]
```

Pour utiliser le système RAG, exécutez:

```powershell
.\rag\core\Invoke-RoadmapRAG.ps1 -Action <Action> [options]
```

## Documentation

Pour plus d'informations sur le système RAG, consultez le guide dans `docs/guides/RAG-System.md`.
