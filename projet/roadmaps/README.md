# Dossier projet/roadmaps

Ce dossier contient toutes les roadmaps et plans du projet.

## Structure

- **active/** : Roadmap active (tâches en cours et à venir)
- **analysis/** : Analyse de la roadmap
- **archive/** : Archives de la roadmap et sections complétées
- **journal/** : Journal de développement
- **logs/** : Logs de la roadmap
- **mes-plans/** : Plans personnels
- **old_versions/** : Anciennes versions de la roadmap
- **plans/** : Plans de développement
- **reports/** : Rapports d'avancement générés
- **Roadmap/** : Roadmap principale
- **scripts/** : Scripts spécifiques à la roadmap du projet
- **tasks/** : Tâches de développement

## Fichiers principaux

- `roadmap_complete_converted.md` : Fichier original de la roadmap (préservé)
- `active/roadmap_active.md` : Tâches actives et à venir
- `archive/roadmap_completed.md` : Tâches complétées
- `archive/sections/` : Sections complétées archivées individuellement

## Système de gestion de la roadmap

Un nouveau système de gestion de la roadmap a été mis en place pour résoudre le problème de taille excessive du fichier principal. Ce système permet de :

1. **Séparer les tâches** : Diviser la roadmap en tâches actives et complétées
2. **Archiver intelligemment** : Archiver les sections complétées dans des fichiers individuels
3. **Naviguer facilement** : Rechercher et afficher des sections spécifiques
4. **Suivre l'avancement** : Générer des rapports d'avancement

### Scripts de gestion

Les scripts suivants sont disponibles dans `development\scripts\maintenance\` :

- `Manage-Roadmap.ps1` : Script principal pour gérer la roadmap
- `Split-Roadmap.ps1` : Sépare la roadmap en fichiers actif et complété
- `Update-RoadmapStatus.ps1` : Met à jour le statut des tâches
- `Navigate-Roadmap.ps1` : Navigue dans la roadmap et ses archives

### Utilisation

Pour initialiser le système à partir de la roadmap originale :

```powershell
.\development\scripts\maintenance\Manage-Roadmap.ps1 -Action Split -ArchiveSections -Force
```

Pour afficher l'aide complète du système :

```powershell
.\development\scripts\maintenance\Manage-Roadmap.ps1 -Action Help
```

## Note importante

Les outils techniques pour gérer les roadmaps se trouvent dans le dossier `development\scripts\maintenance\`.
