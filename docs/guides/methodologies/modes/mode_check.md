# Mode CHECK

## Description
Le mode CHECK est un mode opérationnel qui vérifie automatiquement si les tâches sont 100% implémentées et testées, puis les marque comme complètes dans la roadmap.

## Objectif
L'objectif principal du mode CHECK est d'automatiser la vérification de l'état d'avancement des tâches et de maintenir la roadmap à jour.

## Fonctionnalités
- Vérification automatique de l'implémentation des tâches
- Vérification automatique des tests associés aux tâches
- Marquage automatique des tâches complètes dans la roadmap
- Génération de rapports d'avancement

## Utilisation

```powershell
# Vérifier l'état d'avancement d'une tâche spécifique
.\check-mode.ps1 -RoadmapPath "docs/roadmap/roadmap.md" -TaskId "1.2.3"

# Vérifier l'état d'avancement de toutes les tâches
.\check-mode.ps1 -RoadmapPath "docs/roadmap/roadmap.md" -All

# Vérifier l'état d'avancement et mettre à jour la roadmap
.\check-mode.ps1 -RoadmapPath "docs/roadmap/roadmap.md" -All -UpdateRoadmap
```

## Critères de validation
Une tâche est considérée comme complète si :
- [ ] Elle est 100% implémentée
- [ ] Elle a des tests associés
- [ ] Tous les tests passent avec succès
- [ ] La documentation est à jour

## Intégration avec d'autres modes
Le mode CHECK peut être utilisé en combinaison avec d'autres modes :
- **DEV-R** : Pour vérifier l'état d'avancement des tâches en cours de développement
- **TEST** : Pour vérifier que tous les tests passent avant de marquer une tâche comme complète
- **REVIEW** : Pour vérifier que le code a été revu avant de marquer une tâche comme complète

## Implémentation
Le mode CHECK est implémenté dans le script `check-mode.ps1` qui se trouve dans le dossier `tools/scripts/roadmap/modes/check`.

## Exemple de rapport
```
Rapport d'avancement :
- Tâche 1.1 : 100% implémentée, 100% testée ✓
- Tâche 1.2 : 75% implémentée, 50% testée ✗
- Tâche 1.3 : 100% implémentée, 100% testée ✓
- Tâche 2.1 : 0% implémentée, 0% testée ✗
```

## Bonnes pratiques
- Exécuter le mode CHECK régulièrement pour maintenir la roadmap à jour
- Vérifier manuellement les tâches marquées comme complètes
- Utiliser le mode CHECK avant de présenter l'avancement du projet
- Configurer des seuils de validation personnalisés si nécessaire
