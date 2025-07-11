# FAQ – Plan v104 Gouvernance Dynamique

## Comment suivre l’avancement des tâches et plans ?
- Utilisez les cases à cocher dans `plan-dev-v104-instaurant.md`, `tasks.md`, `task_dependencies.md`, `task_assignments.md`, `task_events.md` et `workflow_validation.md` pour tracer chaque étape.

## Que faire si un plan ou une tâche n’a pas tous les champs du schéma ?
- Complétez progressivement les champs manquants selon le rapport `migration_report.md`.
- Utilisez les statuts « à compléter » pour signaler les entrées incomplètes.

## Comment ajouter une nouvelle tâche ou dépendance ?
- Ajoutez une ligne dans `tasks.md` ou `task_dependencies.md` en respectant le schéma.
- Affectez un responsable dans `task_assignments.md` et suivez les événements dans `task_events.md`.

## Comment automatiser l’inventaire, la migration ou le reporting ?
- Utilisez les commandes Go indiquées dans le plan :
  - `go run ./cmd/plan-inventory`
  - `go run ./cmd/plan-harmonizer`
  - `go run ./cmd/orchestration-convergence`
  - `go run ./cmd/plan-reporter`

## Comment assurer la conformité et la validation ?
- Suivez les étapes et règles de validation dans `workflow_validation.md`.
- Cochez chaque étape validée et documentez toute modification majeure.

## Où trouver la procédure complète et les artefacts ?
- Consultez le plan directeur [`plan-dev-v104-instaurant.md`](plan-dev-v104-instaurant.md:1) et le guide rapide `GUIDE.md`.

## Que faire en cas de conflit ou de besoin d’évolution du schéma ?
- Documentez le cas dans `migration_report.md` ou ouvrez une issue/proposition d’évolution.
- Mettez à jour le schéma dans `plan_schema.md` si nécessaire.

*Cette FAQ accompagne la gouvernance, la migration et l’actionnement du plan v104 pour garantir autonomie et traçabilité.*