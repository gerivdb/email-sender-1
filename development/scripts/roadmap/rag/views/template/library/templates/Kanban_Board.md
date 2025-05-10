# {{title}} - Tableau Kanban

## Description
{{description}}

## À FAIRE
{{#each tasks_by_status.todo}}
### **{{id}}** {{title}}
- Priorité: {{priority}}
{{#if assignee}}
- Assigné à: {{assignee}}
{{/if}}
{{#if due_date}}
- Échéance: {{due_date}}
{{/if}}
{{#if description}}
> {{description}}
{{/if}}

---
{{/each}}

## EN COURS
{{#each tasks_by_status.in_progress}}
### **{{id}}** {{title}}
- Priorité: {{priority}}
{{#if assignee}}
- Assigné à: {{assignee}}
{{/if}}
{{#if due_date}}
- Échéance: {{due_date}}
{{/if}}
{{#if description}}
> {{description}}
{{/if}}

---
{{/each}}

## TERMINÉ
{{#each tasks_by_status.done}}
### **{{id}}** {{title}}
- Priorité: {{priority}}
{{#if assignee}}
- Assigné à: {{assignee}}
{{/if}}
{{#if due_date}}
- Échéance: {{due_date}}
{{/if}}
{{#if description}}
> {{description}}
{{/if}}

---
{{/each}}

## BLOQUÉ
{{#each tasks_by_status.blocked}}
### **{{id}}** {{title}}
- Priorité: {{priority}}
{{#if assignee}}
- Assigné à: {{assignee}}
{{/if}}
{{#if due_date}}
- Échéance: {{due_date}}
{{/if}}
{{#if description}}
> {{description}}
{{/if}}
{{#if blockers}}
**Bloqueurs:** {{blockers}}
{{/if}}

---
{{/each}}

## Résumé
- Total des tâches: {{tasks.length}}
- À faire: {{tasks_todo}}
- En cours: {{tasks_in_progress}}
- Terminées: {{tasks_done}}
- Bloquées: {{tasks_blocked}}

## Notes
{{notes}}

---
*Tableau Kanban généré le {{date}} par {{username}}*
