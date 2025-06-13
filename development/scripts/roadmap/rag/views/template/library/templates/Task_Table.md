# {{title}}

## Description

{{description}}

## Tableau des tâches

| ID | Titre | Statut | Priorité | Assigné à | Échéance |
|---|---|---|---|---|---|
{{#each tasks}}

| **{{id}}** | {{title}} | {{status}} | {{priority}} | {{assignee}} | {{due_date}} |
{{/each}}

## Statistiques

### Par statut

- À faire: {{tasks_todo}} ({{percentage_todo}}%)
- En cours: {{tasks_in_progress}} ({{percentage_in_progress}}%)
- Terminées: {{tasks_done}} ({{percentage_done}}%)
- Bloquées: {{tasks_blocked}} ({{percentage_blocked}}%)

### Par priorité

- Haute: {{tasks_high}} ({{percentage_high}}%)
- Moyenne: {{tasks_medium}} ({{percentage_medium}}%)
- Basse: {{tasks_low}} ({{percentage_low}}%)

## Notes

{{notes}}

---
*Rapport généré le {{date}} à {{time}} par {{username}}*
*ID du rapport: {{random_id}}*
