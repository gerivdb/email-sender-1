# Encoding - Utils

Cette section contient les scripts liÃ©s Ã  la gestion d'encodage dans la catÃ©gorie utils.

## Scripts disponibles

- `Fix-RoadmapEncoding.ps1` - Corrige l'encodage des fichiers de roadmap
- `fix_encoding.py` - Script Python pour corriger l'encodage
- `fix_encoding_simple.py` - Version simplifiÃ©e du script de correction d'encodage

## Utilisation

```powershell
# Exemple d'utilisation PowerShell
.\Fix-RoadmapEncoding.ps1 -FilePath "Roadmap/roadmap_complete.md" -Encoding "UTF8"

# Exemple d'utilisation Python
python fix_encoding.py "Roadmap/roadmap_complete.md"
```

## DÃ©pendances

Ces scripts peuvent dÃ©pendre des modules suivants :
- PowerShell : Aucune dÃ©pendance externe
- Python : `chardet` pour la dÃ©tection d'encodage

## Tests

Les tests unitaires pour ces scripts se trouvent dans le dossier `development/testing/tests/utils`.
