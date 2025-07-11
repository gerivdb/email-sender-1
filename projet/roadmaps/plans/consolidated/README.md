# README – Gouvernance et Suivi Opérationnel (Plan v104)

## 1. Présentation

Ce dossier centralise tous les artefacts du plan v104 : inventaire, table harmonisée, tâches, dépendances, affectations, événements, workflow, rapports de migration.

## 2. Procédure de suivi actionnable

- Suivre chaque étape du plan dans la section « Procédure opérationnelle » de [`plan-dev-v104-instaurant.md`](plan-dev-v104-instaurant.md:1) (cases à cocher).
- Compléter les champs manquants dans `plans_inventory.md` et `plans_harmonized.md` au fil de la migration.
- Suivre l’avancement des tâches dans `tasks.md` (cases à cocher).
- Gérer les dépendances dans `task_dependencies.md`, les affectations dans `task_assignments.md`, les événements dans `task_events.md`.
- Valider chaque étape et transition dans `workflow_validation.md`.

## 3. Artefacts principaux

- `plan-dev-v104-instaurant.md` : plan directeur, procédure séquentielle, checklist
- `plans_inventory.md` : inventaire dynamique, champs à compléter
- `plans_harmonized.md` : table harmonisée, migration progressive
- `tasks.md` : suivi granulaire des tâches
- `task_dependencies.md` : dépendances entre tâches
- `task_assignments.md` : affectations dynamiques
- `task_events.md` : suivi des événements/triggers
- `workflow_validation.md` : validation des étapes et conformité
- `migration_report.md` : rapport d’écart et suggestions

## 4. Bonnes pratiques

- Cocher chaque étape/tâche/événement validé pour assurer la traçabilité.
- Documenter toute modification majeure dans les artefacts concernés.
- Utiliser les scripts et commandes Go indiqués dans le plan pour automatiser l’inventaire, la migration, le reporting.

## 5. FAQ

- **Comment suivre l’avancement ?**  
  → Utiliser les cases à cocher dans chaque table et la checklist du plan.

- **Comment compléter la migration ?**  
  → Se référer au rapport de migration et compléter les champs manquants dans les tables.

- **Comment ajouter une nouvelle tâche ou dépendance ?**  
  → Ajouter une ligne dans `tasks.md` ou `task_dependencies.md` et suivre la procédure.

*Ce README synthétise la logique opérationnelle et la gouvernance du plan v104 pour un pilotage efficace et traçable.*