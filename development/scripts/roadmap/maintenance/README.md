# Maintenance - Scripts de maintenance

Ce dossier contient les scripts de maintenance pour le système de roadmap.

## Structure

- **cleanup/** - Scripts de nettoyage et d'archivage
- **validation/** - Scripts de validation de structure

## Scripts principaux

### Cleanup

- **Archive-CompletedTasks.ps1** - Archive les tâches terminées
- **Clean-ArchiveSections.ps1** - Nettoie les sections archivées
- **Remove-DuplicateTasks.ps1** - Supprime les tâches en double

### Validation

- **Test-RoadmapStructure.ps1** - Vérifie la structure de la roadmap
- **Validate-TaskIds.ps1** - Valide les identifiants des tâches
- **Check-RoadmapConsistency.ps1** - Vérifie la cohérence de la roadmap

## Utilisation

Pour archiver les tâches terminées:

```powershell
.\cleanup\Archive-CompletedTasks.ps1 -RoadmapPath "projet\roadmaps\active\roadmap_active.md" -ArchivePath "projet\roadmaps\archive\roadmap_completed.md"
```plaintext
Pour valider la structure de la roadmap:

```powershell
.\validation\Test-RoadmapStructure.ps1 -RoadmapPath "projet\roadmaps\active\roadmap_active.md"
```plaintext