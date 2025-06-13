# Model - Modèles de données

Ce dossier contient les modèles de données pour représenter les roadmaps.

## Scripts principaux

- **RoadmapModel.psm1** - Module principal pour les modèles de roadmap
- **TaskModel.psm1** - Module pour les modèles de tâches
- **SectionModel.psm1** - Module pour les modèles de sections

## Classes principales

- **Roadmap** - Représente une roadmap complète
- **Task** - Représente une tâche dans la roadmap
- **Section** - Représente une section dans la roadmap

## Utilisation

```powershell
Import-Module .\RoadmapModel.psm1
$roadmap = [Roadmap]::new("projet\roadmaps\active\roadmap_active.md")
$tasks = $roadmap.GetTasks()
```plaintext