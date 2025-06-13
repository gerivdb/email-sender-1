# Scripts d'organisation pour Roadmap

Ce répertoire contient des scripts pour organiser les fichiers et dossiers du répertoire roadmap.

## Script principal

### Organize-RoadmapFiles.ps1

Ce script déplace les fichiers de la racine du répertoire roadmap vers des sous-dossiers thématiques selon leur fonction. Il utilise les sous-dossiers existants lorsque c'est pertinent, ou crée de nouveaux sous-dossiers si nécessaire.

#### Utilisation

```powershell
# Exécuter en mode simulation (dry run)

.\Organize-RoadmapFiles.ps1 -DryRun

# Exécuter avec confirmation pour chaque action

.\Organize-RoadmapFiles.ps1

# Exécuter sans confirmation

.\Organize-RoadmapFiles.ps1 -Force
```plaintext
## Structure organisée

Le script organise les fichiers selon la structure suivante :

```plaintext
development/scripts/roadmap/
├── ai/                  # Fichiers liés à l'intelligence artificielle

├── core/                # Fichiers liés à la gestion des tâches

├── docs/                # Documentation

├── integration/         # Fichiers liés à l'intégration

├── maintenance/         # Fichiers liés à l'archivage et à la maintenance

├── modules/             # Fichiers liés aux managers

├── rag/                 # Fichiers liés à Retrieval Augmented Generation

├── security/            # Fichiers liés à la sécurité

├── visualization/       # Fichiers liés à la visualisation

└── ... (autres dossiers existants)
```plaintext
## Mappages de fichiers

Le script utilise les mappages suivants pour organiser les fichiers :

### Fichiers liés à l'archivage → dossier `maintenance`

- Archive-CompletedTasks.ps1
- ArchiveTask.xml
- Execute-ArchiveIfNeeded.ps1
- last_archive_run.json
- Register-ArchiveTask.ps1
- RegisterTask.bat
- RunArchiveTask.bat
- RunArchiveTaskHidden.vbs
- Setup-ArchiveScheduledTask.ps1
- Start-AutoArchiveBackground.ps1
- Start-AutoArchiveMonitor.ps1
- Stop-AutoArchiveMonitor.ps1
- Unregister-ArchiveTask.ps1
- UnregisterTask.bat
- Cleanup-OldArchiveScripts.ps1

### Fichiers liés à la gestion des tâches → dossier `core`

- Filter-Tasks.ps1
- Fix-ParentTaskStatus.ps1
- Simple-Split-Roadmap.ps1
- Split-Roadmap.ps1
- update-roadmap-checkboxes.ps1

### Fichiers liés à la visualisation → dossier `visualization`

- Generate-ActiveRoadmapView.ps1
- Generate-CompletedTasksView.ps1
- Generate-PriorityTasksView.ps1

### Fichiers liés à l'IA et RAG → dossiers `ai` et `rag`

- Apply-ThematicAttribution.ps1 → ai
- Explore-QdrantWebUI.ps1 → rag
- Index-PlanDevQdrant.ps1 → rag
- Index-TaskVectors.ps1 → rag
- Index-TaskVectorsQdrant.ps1 → rag
- qwen3-dev-r.ps1 → ai
- Simple-ThematicTest.ps1 → ai
- Start-QdrantContainer.ps1 → rag
- Store-VectorsInChroma.ps1 → rag
- Store-VectorsInQdrant.ps1 → rag
- Use-AIFeatures.ps1 → ai

### Fichiers liés à la sécurité → dossier `security`

- Manage-SecurityCompliance.ps1

### Fichiers liés à l'intégration → dossier `integration`

- Sync-RoadmapServices.ps1

### Fichiers liés aux managers → dossier `modules`

- define-manager-structure.ps1
- reorganize-manager-files.ps1
- standardize-manager-names.ps1

### Documentation → dossier `docs`

- README.md
- README_RAG.md

## Bonnes pratiques

1. Toujours exécuter les scripts en mode simulation (`-DryRun`) avant de les exécuter réellement
2. Créer des sauvegardes avant d'effectuer des opérations potentiellement destructives
3. Journaliser toutes les actions effectuées
