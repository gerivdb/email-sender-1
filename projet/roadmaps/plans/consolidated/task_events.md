# Table des Événements / Triggers des Tâches

| id_event | id_task | type_event | date | acteur | payload | commentaire | traité |
|----------|--------|------------|------|--------|---------|-------------|--------|
| evt1     | taskA  | création   | 2025-07-11 | Alice  |  | Création de la tâche | [x] |
| evt2     | taskA  | fin        | 2025-07-12 | Alice  |  | Tâche terminée      | [ ] |
| evt3     | taskB  | déclenchement | 2025-07-12 | Bob    | dépend de taskA | Démarrage après taskA | [ ] |

*Cocher chaque événement une fois traité ou validé.*