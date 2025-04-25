# Archive - Management

Cette section contient les scripts liés à l'archivage des tâches dans la catégorie management.

## Scripts disponibles

- `Archive-CompletedTasks.ps1` - Archive les tâches complétées dans un fichier séparé
- `Move-CompletedTasks.ps1` - Déplace les tâches complétées vers une section d'archive

## Utilisation

```powershell
# Exemple d'utilisation
.\Archive-CompletedTasks.ps1 -RoadmapPath "Roadmap/roadmap_complete.md" -ArchivePath "Roadmap/archive.md"
```

## Dépendances

Ces scripts peuvent dépendre des modules suivants :
- `roadmap-parser` - Module principal de parsing de roadmap

## Tests

Les tests unitaires pour ces scripts se trouvent dans le dossier `tests/management`.
