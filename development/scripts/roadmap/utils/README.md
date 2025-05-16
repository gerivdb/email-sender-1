# Utils - Utilitaires

Ce dossier contient les scripts utilitaires pour la gestion des roadmaps.

## Structure

- **helpers/** - Fonctions d'aide générales
- **export/** - Scripts pour exporter les roadmaps vers différents formats
- **import/** - Scripts pour importer les roadmaps depuis différentes sources

## Scripts principaux

- **Navigate-Roadmap.ps1** - Navigation dans la roadmap
- **Get-RoadmapFiles.ps1** - Récupère les fichiers de roadmap

## Utilisation

Ces scripts sont généralement utilisés par les scripts principaux, mais peuvent également être utilisés directement:

```powershell
.\helpers\Navigate-Roadmap.ps1 -Mode Active -DetailLevel 2
```

```powershell
.\import\Get-RoadmapFiles.ps1 -Directories @("projet/roadmaps", "development/roadmap") -FileExtensions @(".md")
```
