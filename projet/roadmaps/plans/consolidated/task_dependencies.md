# Table des Dépendances entre Tâches

| id_task | id_task_dependant | type_dépendance | condition | ordre | commentaire | statut |
|---------|------------------|-----------------|-----------|-------|-------------|--------|
| taskA   | taskB            | séquentielle    | fin de taskA | 1   | TaskB démarre après TaskA | [ ] |
| taskB   | taskC            | conditionnelle  | validation de taskB | 2 | TaskC démarre si TaskB validée | [ ] |
| taskA   | taskC            | événementielle  | événement: fin | 3 | TaskC déclenchée par la fin de TaskA | [ ] |

*À compléter et cocher lors de l’avancement de l’orchestration.*