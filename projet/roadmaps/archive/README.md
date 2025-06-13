# Archive de la roadmap

Ce dossier contient les tâches archivées et terminées de la roadmap du projet EMAIL_SENDER_1.

## Structure des dossiers

- **logs/** - Journaux d'archivage
- **scripts_archive/** - Scripts d'archivage et utilitaires
- **sections/** - Sections archivées de la roadmap
- **development/testing/tests/** - Tests associés aux tâches archivées

## Fichiers principaux

- **roadmap_archive.md** - Fichier principal d'archive contenant toutes les tâches terminées
- **5.1.2_Implémentation_des_modèles_prédictifs.md** - Archive détaillée de la tâche 5.1.2

## Utilisation

Pour consulter les tâches archivées, ouvrez le fichier `roadmap_archive.md`.

Pour voir les détails d'une tâche spécifique, ouvrez le fichier correspondant (par exemple, `5.1.2_Implémentation_des_modèles_prédictifs.md`).

## Maintenance

Ce dossier est géré par le script `development/scripts/archive_task.ps1`. Pour archiver une nouvelle tâche, utilisez ce script avec les paramètres appropriés.

Exemple :
```powershell
.\development\scripts\archive_task.ps1 -TaskId "5.1.3" -TaskName "Optimisation automatique des performances"
```plaintext