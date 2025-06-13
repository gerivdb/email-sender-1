# Conversion - Core

Cette section contient les scripts liÃ©s Ã  la conversion de format dans la catÃ©gorie core.

## Scripts disponibles

- `Convert-Roadmap.ps1` - Convertit une roadmap existante vers le nouveau format de template
- `RoadmapConverter.psm1` - Module PowerShell contenant les fonctions de conversion

## Utilisation

```powershell
# Exemple d'utilisation

.\Convert-Roadmap.ps1 -SourcePath "Roadmap/roadmap_complete.md" -TemplatePath "Roadmap/roadmap_template.md" -OutputPath "Roadmap/roadmap_complete_new.md"
```plaintext
## DÃ©pendances

Ces scripts peuvent dÃ©pendre des modules suivants :
- `roadmap-parser` - Module principal de parsing de roadmap

## Tests

Les tests unitaires pour ces scripts se trouvent dans le dossier `development/testing/tests/core`.
