# Système RAG (Retrieval-Augmented Generation) pour la gestion de roadmap

Ce système permet de gérer efficacement les tâches de la roadmap en utilisant des techniques de vectorisation et de recherche sémantique.

## Fonctionnalités principales

### 1. Vectorisation des tâches

- Conversion des tâches en vecteurs avec leurs métadonnées
- Stockage dans une base vectorielle (Qdrant ou Chroma)
- Indexation par identifiant, statut, date, etc.

### 2. Interface de recherche et de mise à jour

- Recherche sémantique des tâches par contenu
- Filtrage par statut, date, responsable, etc.
- Mise à jour des statuts avec historique

### 3. Génération de vues dynamiques

- Vue "roadmap active" générée à la demande
- Vue "tâches récemment terminées"
- Vue "prochaines étapes prioritaires"

## Prérequis

- PowerShell 5.1 ou supérieur
- Python 3.7 ou supérieur
- Docker (pour exécuter Qdrant)
- Packages Python :
  - Pour Qdrant : qdrant_client, numpy, requests
  - Pour Chroma : chromadb, numpy, pandas

## Installation

1. Clonez ce dépôt ou copiez les scripts dans votre environnement
2. Installez les packages Python requis :
   ```
   # Pour Qdrant

   pip install qdrant-client numpy requests

   # Pour Chroma

   pip install chromadb numpy pandas
   ```
3. Assurez-vous que Docker est installé et en cours d'exécution pour Qdrant :
   ```
   # Vérifier que Docker est installé

   docker --version

   # Le système démarrera automatiquement le conteneur Docker pour Qdrant

   # lorsque nécessaire, vous n'avez pas besoin de le faire manuellement

   ```
4. Initialisez le système RAG :
   ```powershell
   # Pour utiliser Qdrant (par défaut)

   .\Invoke-RoadmapRAG.ps1 -Action Initialize

   # Pour utiliser Chroma

   .\Invoke-RoadmapRAG.ps1 -Action Initialize -VectorDb Chroma
   ```

## Utilisation

Le script principal `Invoke-RoadmapRAG.ps1` permet d'accéder à toutes les fonctionnalités du système.

### Initialisation du système

```powershell
.\Invoke-RoadmapRAG.ps1 -Action Initialize
```plaintext
### Conversion des tâches en vecteurs

```powershell
.\Invoke-RoadmapRAG.ps1 -Action Convert -Parameters @{
    RoadmapPath = "projet\roadmaps\active\roadmap_active.md"
    OutputPath = "projet\roadmaps\vectors\task_vectors.json"
    Force = $true
}
```plaintext
### Stockage des vecteurs dans la base vectorielle

```powershell
# Pour Qdrant (par défaut)

.\Invoke-RoadmapRAG.ps1 -Action Store -Parameters @{
    VectorsPath = "projet\roadmaps\vectors\task_vectors.json"
    QdrantUrl = "http://localhost:6333"
    CollectionName = "roadmap_tasks"
    Force = $true
}

# Pour Chroma

.\Invoke-RoadmapRAG.ps1 -Action Store -Parameters @{
    VectorsPath = "projet\roadmaps\vectors\task_vectors.json"
    ChromaDbPath = "projet\roadmaps\vectors\chroma_db"
    CollectionName = "roadmap_tasks"
    Force = $true
} -VectorDb Chroma
```plaintext
### Indexation des tâches

```powershell
# Pour Qdrant (par défaut)

.\Invoke-RoadmapRAG.ps1 -Action Index -Parameters @{
    QdrantUrl = "http://localhost:6333"
    CollectionName = "roadmap_tasks"
    IndexOutputPath = "projet\roadmaps\vectors\task_indexes.json"
    Force = $true
}

# Pour Chroma

.\Invoke-RoadmapRAG.ps1 -Action Index -Parameters @{
    ChromaDbPath = "projet\roadmaps\vectors\chroma_db"
    CollectionName = "roadmap_tasks"
    IndexOutputPath = "projet\roadmaps\vectors\task_indexes.json"
    Force = $true
} -VectorDb Chroma
```plaintext
### Recherche sémantique des tâches

```powershell
# Pour Qdrant (par défaut)

.\Invoke-RoadmapRAG.ps1 -Action Search -Parameters @{
    Query = "Implémentation des fonctionnalités de base"
    QdrantUrl = "http://localhost:6333"
    MaxResults = 5
    OutputFormat = "markdown"
    OutputPath = "projet\roadmaps\views\search_results.md"
}

# Pour Chroma

.\Invoke-RoadmapRAG.ps1 -Action Search -Parameters @{
    Query = "Implémentation des fonctionnalités de base"
    MaxResults = 5
    OutputFormat = "markdown"
    OutputPath = "projet\roadmaps\views\search_results.md"
} -VectorDb Chroma
```plaintext
### Filtrage des tâches

```powershell
.\Invoke-RoadmapRAG.ps1 -Action Filter -Parameters @{
    Status = "Incomplete"
    Section = "Phase 1"
    OutputFormat = "markdown"
    OutputPath = "projet\roadmaps\views\filtered_tasks.md"
}
```plaintext
### Mise à jour du statut d'une tâche

```powershell
.\Invoke-RoadmapRAG.ps1 -Action UpdateStatus -Parameters @{
    TaskId = "1.1.2.1"
    Status = "Complete"
    Comment = "Fonctionnalité terminée et testée"
    UpdateRoadmap = $true
}
```plaintext
### Génération de vues

#### Vue de la roadmap active

```powershell
.\Invoke-RoadmapRAG.ps1 -Action ViewActive -Parameters @{
    StatusFilter = "Incomplete"
    OutputFormat = "html"
    OutputPath = "projet\roadmaps\views\active_roadmap.html"
}
```plaintext
#### Vue des tâches récemment terminées

```powershell
.\Invoke-RoadmapRAG.ps1 -Action ViewCompleted -Parameters @{
    DaysBack = 7
    MaxTasks = 20
    OutputFormat = "markdown"
    OutputPath = "projet\roadmaps\views\completed_tasks.md"
}
```plaintext
#### Vue des prochaines étapes prioritaires

```powershell
.\Invoke-RoadmapRAG.ps1 -Action ViewPriority -Parameters @{
    MaxTasks = 10
    PriorityMethod = "Auto"
    OutputFormat = "html"
    OutputPath = "projet\roadmaps\views\priority_tasks.html"
}
```plaintext
## Structure des dossiers

```plaintext
projet/
└── roadmaps/
    ├── active/              # Roadmap active

    ├── completed/           # Tâches complétées

    ├── vectors/             # Vecteurs et bases vectorielles

    │   ├── chroma_db/       # Base de données Chroma

    │   └── qdrant_data/     # Données pour Qdrant

    ├── history/             # Historique des mises à jour

    ├── views/               # Vues générées

    └── config/              # Fichiers de configuration

```plaintext
## Formats de sortie disponibles

- **markdown** : Format Markdown standard
- **html** : Format HTML avec styles CSS
- **json** : Format JSON pour l'intégration avec d'autres systèmes

## Méthodes de priorité

- **Auto** : Calcul automatique basé sur plusieurs facteurs
- **Manual** : Utilisation des priorités définies manuellement dans le fichier de configuration
- **Dependencies** : Priorité basée sur les dépendances entre tâches
- **Chronological** : Priorité basée sur l'ordre chronologique des IDs

## Statuts disponibles

- **Complete** : Tâche terminée
- **Incomplete** : Tâche non commencée
- **InProgress** : Tâche en cours
- **Blocked** : Tâche bloquée
- **Deferred** : Tâche reportée

## Exemples d'utilisation avancée

### Workflow complet

```powershell
# Initialiser le système (utilise Qdrant par défaut)

.\Invoke-RoadmapRAG.ps1 -Action Initialize

# Convertir les tâches en vecteurs

.\Invoke-RoadmapRAG.ps1 -Action Convert -Parameters @{
    RoadmapPath = "projet\roadmaps\active\roadmap_active.md"
    Force = $true
}

# Stocker les vecteurs dans Qdrant

.\Invoke-RoadmapRAG.ps1 -Action Store -Parameters @{
    QdrantUrl = "http://localhost:6333"
    Force = $true
}

# Indexer les tâches

.\Invoke-RoadmapRAG.ps1 -Action Index -Parameters @{
    QdrantUrl = "http://localhost:6333"
    Force = $true
}

# Générer une vue des prochaines étapes prioritaires

.\Invoke-RoadmapRAG.ps1 -Action ViewPriority -Parameters @{
    MaxTasks = 10
    OutputFormat = "html"
    OutputPath = "projet\roadmaps\views\priority_tasks.html"
}

# Ouvrir la vue générée

Invoke-Item "projet\roadmaps\views\priority_tasks.html"
```plaintext
### Workflow avec Chroma

```powershell
# Initialiser le système avec Chroma

.\Invoke-RoadmapRAG.ps1 -Action Initialize -VectorDb Chroma

# Convertir les tâches en vecteurs

.\Invoke-RoadmapRAG.ps1 -Action Convert -Parameters @{
    RoadmapPath = "projet\roadmaps\active\roadmap_active.md"
    Force = $true
}

# Stocker les vecteurs dans Chroma

.\Invoke-RoadmapRAG.ps1 -Action Store -Parameters @{
    Force = $true
} -VectorDb Chroma

# Indexer les tâches

.\Invoke-RoadmapRAG.ps1 -Action Index -Parameters @{
    Force = $true
} -VectorDb Chroma

# Générer une vue des prochaines étapes prioritaires

.\Invoke-RoadmapRAG.ps1 -Action ViewPriority -Parameters @{
    MaxTasks = 10
    OutputFormat = "html"
    OutputPath = "projet\roadmaps\views\priority_tasks.html"
} -VectorDb Chroma

# Ouvrir la vue générée

Invoke-Item "projet\roadmaps\views\priority_tasks.html"
```plaintext
### Recherche et mise à jour

```powershell
# Rechercher des tâches liées à l'implémentation

$results = .\Invoke-RoadmapRAG.ps1 -Action Search -Parameters @{
    Query = "Implémentation"
    MaxResults = 10
    OutputFormat = "json"
}

# Convertir les résultats en objet PowerShell

$tasks = $results | ConvertFrom-Json

# Mettre à jour le statut de la première tâche trouvée

$taskId = $tasks.tasks[0].taskId
.\Invoke-RoadmapRAG.ps1 -Action UpdateStatus -Parameters @{
    TaskId = $taskId
    Status = "InProgress"
    Comment = "Début de l'implémentation"
    UpdateRoadmap = $true
}
```plaintext
## Dépannage

### Problèmes courants

1. **Erreur de connexion à Qdrant**
   - Vérifiez que Docker est installé et en cours d'exécution
   - Le système tentera de démarrer automatiquement le conteneur Docker pour Qdrant
   - Vous pouvez vérifier l'état du conteneur avec la commande : `.\Start-QdrantContainer.ps1 -Action Status`
   - Vous pouvez redémarrer le conteneur avec la commande : `.\Start-QdrantContainer.ps1 -Action Restart`
   - Vérifiez les logs Docker pour plus d'informations : `docker logs roadmap-qdrant`

2. **Erreur de connexion à la base Chroma**
   - Vérifiez que le dossier `projet\roadmaps\vectors\chroma_db` existe
   - Vérifiez que vous avez les permissions nécessaires

3. **Packages Python manquants**
   - Pour Qdrant : `pip install qdrant-client numpy requests`
   - Pour Chroma : `pip install chromadb numpy pandas`

4. **Fichier de roadmap non trouvé**
   - Vérifiez le chemin du fichier de roadmap
   - Assurez-vous que le fichier existe et est accessible

### Journalisation

Tous les scripts incluent une journalisation détaillée. Utilisez les messages de log pour diagnostiquer les problèmes.

## Contribution

Les contributions sont les bienvenues ! N'hésitez pas à améliorer ce système en ajoutant de nouvelles fonctionnalités ou en corrigeant des bugs.

## Licence

Ce projet est sous licence MIT. Voir le fichier LICENSE pour plus de détails.
