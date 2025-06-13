# {{title}}

## Description

{{description}}

## Tâches

{{#each tasks}}

- [ ] **{{id}}** {{title}}
  - Statut: {{status}}
  - Priorité: {{priority}}
  {{#if assignee}}

  - Assigné à: {{assignee}}
  {{/if}}
  {{#if due_date}}

  - Échéance: {{due_date}}
  {{/if}}
{{/each}}

## Résumé

- Total des tâches: {{tasks.length}}
- Tâches à faire: {{tasks_todo}}
- Tâches en cours: {{tasks_in_progress}}
- Tâches terminées: {{tasks_done}}

## Notes

{{notes}}

---
*Généré le {{date}} par {{username}}*
