# Système RAG de gestion des roadmaps

Ce dossier contient les scripts pour le système RAG (Retrieval-Augmented Generation) de gestion des roadmaps. Ce système permet d'analyser, vectoriser, rechercher et visualiser les roadmaps du projet.

## 🆕 Exécution des tests (Nouveau)

Pour exécuter les tests du système RAG de roadmaps, utilisez l'un des scripts batch suivants :

- **RunTests.bat** : Exécute tous les tests
- **RunChangeDetectionTests.bat** : Exécute uniquement les tests de détection des changements
- **RunVectorUpdateTests.bat** : Exécute uniquement les tests de mise à jour des vecteurs
- **RunVersioningTests.bat** : Exécute uniquement les tests de versionnage des embeddings

Ces scripts automatisent complètement le processus de test, y compris :
- La vérification et le démarrage de Qdrant
- La configuration d'un environnement virtuel Python avec les dépendances exactes
- L'exécution des tests
- La génération d'un rapport HTML des résultats

Pour une utilisation avancée, vous pouvez exécuter directement le script PowerShell :

```powershell
.\Run-CompleteTestSuite.ps1 -TestType All -Force
```

## Fonctionnalités

- **Analyse des roadmaps** : Inventaire, analyse de structure, détection de doublons
- **Vectorisation** : Conversion des roadmaps en vecteurs pour la recherche sémantique
- **Recherche** : Recherche sémantique dans les roadmaps
- **Visualisation** : Génération de graphiques et visualisations interactives
- **Synchronisation** : Mise à jour automatique des roadmaps dans Qdrant

## Prérequis

- PowerShell 5.1 ou supérieur
- Python 3.8 ou supérieur
- Docker (pour Qdrant)

## Installation

Pour installer toutes les dépendances nécessaires, exécutez le script `Install-Dependencies.ps1` :

```powershell
.\Install-Dependencies.ps1
```

Ce script installera :
- Python (si nécessaire)
- Les packages Python requis (sentence-transformers, qdrant-client, matplotlib, networkx, pyvis)
- Docker (si nécessaire)
- Qdrant (via Docker)

## Utilisation

### Analyse des roadmaps

Pour analyser les roadmaps, utilisez le script `Simple-RoadmapAnalysis.ps1` :

```powershell
.\Simple-RoadmapAnalysis.ps1 -Action All -OutputDirectory "projet/roadmaps/analysis" -Force
```

Options disponibles :
- `-Action` : Action à exécuter (Inventory, Analyze, FindDuplicates, All)
- `-OutputDirectory` : Dossier de sortie pour les résultats
- `-Force` : Force l'écrasement des fichiers existants

### Vectorisation des roadmaps

Pour vectoriser les roadmaps et les stocker dans Qdrant, utilisez le script `Invoke-RoadmapRAG.ps1` :

```powershell
.\Invoke-RoadmapRAG.ps1 -Action Vectorize -InventoryPath "projet/roadmaps/analysis/inventory.json"
```

Options disponibles :
- `-InventoryPath` : Chemin vers le fichier d'inventaire JSON
- `-Model` : Nom du modèle SentenceTransformer à utiliser (défaut: all-MiniLM-L6-v2)
- `-Collection` : Nom de la collection Qdrant (défaut: roadmaps)
- `-Host` : Hôte du serveur Qdrant (défaut: localhost)
- `-Port` : Port du serveur Qdrant (défaut: 6333)
- `-ChunkSize` : Taille maximale des chunks (défaut: 512)
- `-ChunkOverlap` : Chevauchement entre les chunks (défaut: 128)
- `-Force` : Force la réindexation même si la collection existe déjà

### Recherche dans les roadmaps

Pour rechercher dans les roadmaps vectorisées, utilisez le script `Invoke-RoadmapRAG.ps1` :

```powershell
.\Invoke-RoadmapRAG.ps1 -Action Search -Query "implémentation du backend" -Limit 5 -OutputFormat markdown
```

Options disponibles :
- `-Query` : Requête de recherche
- `-Limit` : Nombre maximum de résultats (défaut: 10)
- `-OutputFormat` : Format de sortie (text, json, markdown) (défaut: text)
- `-OutputPath` : Fichier de sortie (si non spécifié, affiche sur la sortie standard)
- `-FilterPath` : Fichier JSON contenant les filtres à appliquer

### Visualisation des roadmaps

Pour générer des visualisations graphiques des roadmaps, utilisez le script `Invoke-RoadmapVisualization.ps1` :

```powershell
.\Invoke-RoadmapVisualization.ps1 -RoadmapPath "projet/roadmaps/active/roadmap_active.md" -OpenInBrowser
```

Options disponibles :
- `-RoadmapPath` : Chemin vers le fichier markdown de roadmap
- `-OutputDirectory` : Dossier de sortie pour les visualisations
- `-OpenInBrowser` : Ouvre les visualisations dans le navigateur
- `-Force` : Force la régénération des visualisations

### Synchronisation automatique

Pour démarrer la synchronisation automatique des roadmaps avec Qdrant, utilisez le script `Start-RoadmapSync.ps1` :

```powershell
.\Start-RoadmapSync.ps1 -RoadmapPath "projet/roadmaps/active/roadmap_active.md" -IntervalMinutes 20 -NoPrompt
```

Options disponibles :
- `-RoadmapPath` : Chemin vers le fichier markdown de roadmap
- `-OutputDirectory` : Dossier de sortie pour les résultats
- `-IntervalMinutes` : Intervalle de synchronisation en minutes (défaut: 20)
- `-Force` : Force l'écrasement des fichiers existants
- `-NoPrompt` : Ne demande pas de confirmation

## Structure des fichiers

### Scripts principaux
- `Simple-RoadmapAnalysis.ps1` : Script principal pour l'analyse des roadmaps
- `Invoke-RoadmapRAG.ps1` : Interface pour le système RAG
- `Invoke-RoadmapVisualization.ps1` : Script pour générer des visualisations
- `Start-RoadmapSync.ps1` : Script pour la synchronisation automatique
- `Install-Dependencies.ps1` : Script pour installer les dépendances

### Scripts Python
- `vectorize_roadmaps.py` : Script Python pour vectoriser les roadmaps
- `search_roadmaps.py` : Script Python pour rechercher dans les roadmaps
- `Generate-RoadmapVisualization.py` : Script Python pour générer des visualisations

### Scripts de test
- `Run-CompleteTestSuite.ps1` : Script principal pour exécuter tous les tests
- `RunTests.bat` : Script batch pour exécuter tous les tests
- `RunChangeDetectionTests.bat` : Script batch pour les tests de détection des changements
- `RunVectorUpdateTests.bat` : Script batch pour les tests de mise à jour des vecteurs
- `RunVersioningTests.bat` : Script batch pour les tests de versionnage des embeddings

## Exemples d'utilisation

### Workflow complet

```powershell
# Installer les dépendances
.\Install-Dependencies.ps1

# Analyser les roadmaps
.\Simple-RoadmapAnalysis.ps1 -Action All -Force

# Vectoriser les roadmaps
.\Invoke-RoadmapRAG.ps1 -Action Vectorize -InventoryPath "projet/roadmaps/analysis/inventory.json"

# Rechercher dans les roadmaps
.\Invoke-RoadmapRAG.ps1 -Action Search -Query "implémentation du backend" -OutputPath "projet/roadmaps/analysis/search_results.md" -OutputFormat markdown

# Générer des visualisations
.\Invoke-RoadmapVisualization.ps1 -RoadmapPath "projet/roadmaps/active/roadmap_active.md" -OpenInBrowser

# Démarrer la synchronisation automatique
.\Start-RoadmapSync.ps1 -IntervalMinutes 20 -NoPrompt
```

### Filtres de recherche

Vous pouvez créer un fichier JSON contenant des filtres pour la recherche :

```json
{
  "must": [
    {
      "key": "metadata.file_name",
      "match": {
        "value": "roadmap_active.md"
      }
    }
  ],
  "should": [
    {
      "key": "task_id",
      "match": {
        "value": "1.2"
      }
    }
  ]
}
```

Puis utiliser ce fichier pour filtrer les résultats de recherche :

```powershell
.\Invoke-RoadmapRAG.ps1 -Action Search -Query "implémentation" -FilterPath "projet/roadmaps/analysis/filters.json"
```

## Tests et validation

### Exécution des tests automatisés

Le système RAG de roadmaps comprend une suite complète de tests automatisés pour valider son fonctionnement. Ces tests sont organisés en trois catégories :

1. **ChangeDetection** : Tests pour la détection des changements dans les roadmaps
   - Détection des ajouts, suppressions, modifications
   - Détection des changements de statut
   - Détection des déplacements et changements structurels

2. **VectorUpdate** : Tests pour la mise à jour sélective des vecteurs
   - Mise à jour avec ajouts, modifications, changements de statut

3. **Versioning** : Tests pour le système de versionnage des embeddings
   - Enregistrement de versions, création de snapshots
   - Migration vers un nouveau modèle, rollback

Pour exécuter tous les tests avec une configuration automatique :

```powershell
.\Run-CompleteTestSuite.ps1 -Force
```

Pour exécuter un type de test spécifique :

```powershell
.\Run-CompleteTestSuite.ps1 -TestType ChangeDetection -Force
```

Options disponibles :
- `-TestType` : Type de tests à exécuter (`All`, `ChangeDetection`, `VectorUpdate`, `Versioning`)
- `-VenvPath` : Chemin de l'environnement virtuel (par défaut : `venv`)
- `-QdrantUrl` : URL de Qdrant (par défaut : `http://localhost:6333`)
- `-Force` : Forcer la recréation de l'environnement virtuel s'il existe déjà
- `-SkipQdrantCheck` : Ignorer la vérification et le démarrage de Qdrant
- `-SkipVenvSetup` : Ignorer la configuration de l'environnement virtuel
- `-NoReport` : Ne pas générer de rapport HTML

Le rapport de test sera généré dans le répertoire `projet\roadmaps\analysis\test\output`.

## Dépannage

### Qdrant n'est pas accessible

Si Qdrant n'est pas accessible, vérifiez que Docker est en cours d'exécution et que le conteneur Qdrant est démarré :

```powershell
docker ps
```

Si le conteneur n'est pas en cours d'exécution, démarrez-le :

```powershell
docker start qdrant
```

### Erreurs Python

Si vous rencontrez des erreurs Python, utilisez le script de résolution automatique :

```powershell
.\Run-CompleteTestSuite.ps1 -Force
```

Ce script installera automatiquement toutes les dépendances nécessaires avec les versions exactes requises.

Pour une installation manuelle, vérifiez que toutes les dépendances sont installées :

```powershell
python -c "import sentence_transformers, qdrant_client, matplotlib, networkx, pyvis"
```

Si des dépendances sont manquantes, installez les versions compatibles :

```powershell
pip install huggingface-hub==0.19.4 transformers==4.36.2 torch==2.1.2 sentence-transformers==2.2.2 qdrant-client==1.7.0 matplotlib networkx pyvis
```

### Problèmes de compatibilité des dépendances

Si vous rencontrez des problèmes de compatibilité entre les bibliothèques Python, consultez le guide de dépannage :

```powershell
notepad docs\guides\roadmap\TROUBLESHOOTING_DEPENDENCIES.md
```

Ce guide explique les problèmes courants et leurs solutions, notamment les incompatibilités entre `sentence-transformers`, `huggingface-hub` et `transformers`.

## Licence

Ce projet est sous licence MIT. Voir le fichier LICENSE pour plus de détails.
