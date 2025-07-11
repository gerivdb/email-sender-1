# GUIDE RAPIDE – Implémentation et Suivi du Plan v104

## 1. Démarrage

- Lire le plan directeur [`plan-dev-v104-instaurant.md`](plan-dev-v104-instaurant.md:1)
- Prendre connaissance de la procédure opérationnelle et des cases à cocher

## 2. Suivi des étapes

- Pour chaque étape, cocher la case correspondante dans le plan ou la table concernée
- Compléter les champs manquants dans `plans_inventory.md` et `plans_harmonized.md`
- Suivre l’avancement des tâches dans `tasks.md`
- Gérer les dépendances dans `task_dependencies.md`
- Affecter les responsables dans `task_assignments.md`
- Suivre les événements dans `task_events.md`
- Valider chaque étape dans `workflow_validation.md`

## 3. Commandes clés

- Générer l’inventaire :  
  `go run ./cmd/plan-inventory`
- Migrer les plans :  
  `go run ./cmd/plan-harmonizer`
- Détecter les conflits :  
  `go run ./cmd/orchestration-convergence`
- Générer les rapports :  
  `go run ./cmd/plan-reporter`

## 4. Migration progressive

- Se référer à `migration_report.md` pour identifier les plans à compléter
- Enrichir progressivement chaque plan/tâche selon le schéma cible

## 5. Bonnes pratiques

- Cocher chaque action réalisée pour assurer la traçabilité
- Documenter toute modification majeure
- Utiliser les artefacts comme source de vérité pour la gouvernance et l’orchestration

## 6. Ressources

- [plan-dev-v104-instaurant.md](plan-dev-v104-instaurant.md:1)
- [plans_inventory.md](plans_inventory.md:1)
- [plans_harmonized.md](plans_harmonized.md:1)
- [tasks.md](tasks.md:1)
- [task_dependencies.md](task_dependencies.md:1)
- [task_assignments.md](task_assignments.md:1)
- [task_events.md](task_events.md:1)
- [workflow_validation.md](workflow_validation.md:1)
- [migration_report.md](migration_report.md:1)
- [README.md](README.md:1)

*Ce guide permet une prise en main rapide et structurée de l’ensemble du dispositif v104.*