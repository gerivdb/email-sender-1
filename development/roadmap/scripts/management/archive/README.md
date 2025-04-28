# Archive - Management

Cette section contient les scripts liÃ©s Ã  l'archivage des tÃ¢ches dans la catÃ©gorie management.

## Scripts disponibles

- `Archive-CompletedTasks.ps1` - Archive les tÃ¢ches complÃ©tÃ©es dans un fichier sÃ©parÃ©
- `Move-CompletedTasks.ps1` - DÃ©place les tÃ¢ches complÃ©tÃ©es vers une section d'archive

## Utilisation

```powershell
# Exemple d'utilisation
.\Archive-CompletedTasks.ps1 -RoadmapPath "Roadmap/roadmap_complete.md" -ArchivePath "Roadmap/archive.md"
```

## DÃ©pendances

Ces scripts peuvent dÃ©pendre des modules suivants :
- `roadmap-parser` - Module principal de parsing de roadmap

## Tests

Les tests unitaires pour ces scripts se trouvent dans le dossier `development/testing/tests/management`.
