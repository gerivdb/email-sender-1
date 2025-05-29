---
to: <%= h.structure.buildDestinationPath(h.path.config, h.structure.fileNamingPattern(version, title)) %>
encoding: utf8
---
<%
const structureHelpers = h.structure.getCommonHelpers();
const metrics = structureHelpers.metrics.getDefaultMetrics();
const warnings = structureHelpers.metrics.getDefaultWarnings();
const formattedDate = structureHelpers.metrics.formatDate(new Date());
%>
<%
const metrics = h.metrics.getDefaultMetrics();
const warnings = h.metrics.getDefaultWarnings();
const formattedDate = h.metrics.formatDate(new Date());
%>

# Plan de développement <%= version %> - <%= title %>
*Version 1.0 - <%= formattedDate %> - Progression globale : <%= metrics.completedTasks %> / <%= metrics.totalTasks %>*

<%= description %>

## Points de vigilance
<% warnings.forEach(function(w) { %>
- ⚠️ (<%= w.severity %>) <%= w.message %>
<% }) %>

## 📊 Dashboard de Suivi

| Métrique | Valeur | Objectif | Statut |
|----------|--------|----------|--------|
| Scripts Développés | <%= metrics.completedTasks %>/<%= metrics.totalTasks %> | <%= metrics.totalTasks %> | 🟡 Démarrage |
| Efficacité | <%= metrics.efficiency %>% | 80% | 📊 Baseline |
| Tests | <%= metrics.testCoverage %>% | 85% | 📊 À implémenter |

<%
const allPhases = h.tasks.generatePhases(phases);
allPhases.forEach(phase => { %>
<%= h.tasks.formatPhaseMarkdown(phase) %>
<% }); %>

<%= h.commands.generateCommandsSection() %>
hygen plan-dev metrics view
```

---

*Plan généré le <%= timeFormatted %> | Auteur: <%= locals.author || 'gerivdb' %>*