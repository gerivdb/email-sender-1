# Conversion - Core

Cette section contient les scripts liés à la conversion de format dans la catégorie core.

## Scripts disponibles

- `Convert-Roadmap.ps1` - Convertit une roadmap existante vers le nouveau format de template
- `RoadmapConverter.psm1` - Module PowerShell contenant les fonctions de conversion

## Utilisation

```powershell
# Exemple d'utilisation
.\Convert-Roadmap.ps1 -SourcePath "Roadmap/roadmap_complete.md" -TemplatePath "Roadmap/roadmap_template.md" -OutputPath "Roadmap/roadmap_complete_new.md"
```

## Dépendances

Ces scripts peuvent dépendre des modules suivants :
- `roadmap-parser` - Module principal de parsing de roadmap

## Tests

Les tests unitaires pour ces scripts se trouvent dans le dossier `tests/core`.
