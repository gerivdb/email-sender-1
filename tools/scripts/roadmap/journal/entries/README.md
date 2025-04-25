# Entries - Journal

Cette section contient les scripts liés à la gestion des entrées de journal dans la catégorie journal.

## Scripts disponibles

- `Add-RoadmapJournalEntry.ps1` - Ajoute une nouvelle entrée au journal de roadmap
- `Import-ExistingRoadmapToJournal.ps1` - Importe une roadmap existante dans le journal
- `Update-RoadmapJournalStatus.ps1` - Met à jour le statut d'une entrée de journal

## Utilisation

```powershell
# Exemple d'utilisation
.\Add-RoadmapJournalEntry.ps1 -TaskId "1.2.3" -Status "In Progress" -Comment "Travail en cours sur cette tâche"
```

## Dépendances

Ces scripts peuvent dépendre des modules suivants :
- `roadmap-parser` - Module principal de parsing de roadmap

## Tests

Les tests unitaires pour ces scripts se trouvent dans le dossier `tests/journal`.
