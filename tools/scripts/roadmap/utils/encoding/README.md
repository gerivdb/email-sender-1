# Encoding - Utils

Cette section contient les scripts liés à la gestion d'encodage dans la catégorie utils.

## Scripts disponibles

- `Fix-RoadmapEncoding.ps1` - Corrige l'encodage des fichiers de roadmap
- `fix_encoding.py` - Script Python pour corriger l'encodage
- `fix_encoding_simple.py` - Version simplifiée du script de correction d'encodage

## Utilisation

```powershell
# Exemple d'utilisation PowerShell
.\Fix-RoadmapEncoding.ps1 -FilePath "Roadmap/roadmap_complete.md" -Encoding "UTF8"

# Exemple d'utilisation Python
python fix_encoding.py "Roadmap/roadmap_complete.md"
```

## Dépendances

Ces scripts peuvent dépendre des modules suivants :
- PowerShell : Aucune dépendance externe
- Python : `chardet` pour la détection d'encodage

## Tests

Les tests unitaires pour ces scripts se trouvent dans le dossier `tests/utils`.
