# Roadmap - Scripts et processus

Ce dossier contient tous les scripts liés à la roadmap et à son exécution automatique.

## Fichiers principaux

- `roadmap_perso.md` - La roadmap elle-même
- `RoadmapAdmin.ps1` - Script principal d'administration de la roadmap
- `AugmentExecutor.ps1` - Script d'exécution des tâches avec Augment
- `RestartAugment.ps1` - Script de redémarrage en cas d'échec
- `StartRoadmapExecution.ps1` - Script de démarrage rapide
- `RoadmapAnalyzer.ps1` - Script d'analyse de la roadmap
- `RoadmapGitUpdater.ps1` - Script de mise à jour de la roadmap en fonction des commits Git
- `RoadmapManager.ps1` - Script de gestion de la roadmap

## Utilisation

Pour accéder à toutes les fonctionnalités, exécutez :

```powershell
.\RoadmapManager.ps1
```

## Fonctionnalités

1. **Exécution automatique de la roadmap**
   - Analyse la roadmap pour identifier les tâches à faire
   - Exécute automatiquement les tâches avec Augment
   - Met à jour la roadmap pour marquer les tâches comme terminées
   - Passe automatiquement à la tâche suivante

2. **Analyse de la roadmap**
   - Calcule la progression globale et détaillée
   - Génère des rapports HTML, JSON et des graphiques
   - Visualise l'avancement des tâches

3. **Mise à jour basée sur Git**
   - Analyse les commits Git pour identifier les tâches terminées
   - Met à jour automatiquement la roadmap en fonction des commits
   - Génère des rapports sur les correspondances trouvées

4. **Gestion des échecs**
   - Détecte les échecs d'Augment
   - Relance automatiquement les tâches en cas d'échec
   - Fournit des mécanismes de récupération robustes
