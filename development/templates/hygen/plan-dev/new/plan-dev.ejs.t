---
to: d:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/projet/roadmaps/plans/consolidated/plan-dev-v<%= version %>-<%= title.toLowerCase().replace(/ /g, '-').replace(/[^a-z0-9\-]/g, '').slice(0,50) %>.md
encoding: utf8
---
# Plan de développement <%= version %> - <%= title %>
*Version 1.0 - <%= new Date().toISOString().split('T')[0] %> - Progression globale : 0%*

<%= description %>

<% 
// labels: titres pour chaque niveau
defaultLabels = ['Tâche principale', 'Sous-tâche', 'Sous-sous-tâche', 'Action'];
// levels: nombre d'éléments à chaque niveau (modifiable)
defaultLevels = [2, 3, 3, 3];
const labels = typeof taskLabels !== 'undefined' ? taskLabels : defaultLabels;
const levels = typeof taskLevels !== 'undefined' ? taskLevels : defaultLevels;

function renderTasks(prefix, levels, labels, depth = 0) {
  if (levels.length === 0) return '';
  let out = '';
  for (let i = 1; i <= levels[0]; i++) {
    let num = prefix + i;
    let label = labels[0] || 'Tâche';
    let indent = '  '.repeat(depth);
    out += `${indent}- [ ] **${num}** ${label} ${i}\n`;
    if (levels.length > 1) {
      out += renderTasks(num + '.', levels.slice(1), labels.slice(1), depth + 1);
    }
  }
  return out;
}
%>
<% for(let i = 1; i <= phases; i++) { %>
## <%= i %>. Phase <%= i %> (Phase <%= i %>)
<%- renderTasks(i + '.', levels, labels) %>
<% } %>
