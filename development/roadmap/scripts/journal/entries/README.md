# Entries - Journal

Cette section contient les scripts liÃ©s Ã  la gestion des entrÃ©es de journal dans la catÃ©gorie journal.

## Scripts disponibles

- `Add-RoadmapJournalEntry.ps1` - Ajoute une nouvelle entrÃ©e au journal de roadmap
- `Import-ExistingRoadmapToJournal.ps1` - Importe une roadmap existante dans le journal
- `Update-RoadmapJournalStatus.ps1` - Met Ã  jour le statut d'une entrÃ©e de journal

## Utilisation

```powershell
# Exemple d'utilisation

.\Add-RoadmapJournalEntry.ps1 -TaskId "1.2.3" -Status "In Progress" -Comment "Travail en cours sur cette tÃ¢che"
```plaintext
## DÃ©pendances

Ces scripts peuvent dÃ©pendre des modules suivants :
- `roadmap-parser` - Module principal de parsing de roadmap

## Tests

Les tests unitaires pour ces scripts se trouvent dans le dossier `development/testing/tests/journal`.
