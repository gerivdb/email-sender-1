---
to: roadmaps/plans/consolidated/plan-dev-<%= version %>-<%= title.toLowerCase().replace(/ /g, '-').replace(/[^a-z0-9\-]/g, '').slice(0,50) %>.md
encoding: utf8
---
<%
const currentDate = new Date();
const timeFormatted = currentDate.toLocaleString('fr-FR');

// Initialisation des métriques
const totalTasks = 9;
const completedTasks = 0;
const efficiency = 0;
const testCoverage = 0;
%>

# Plan de développement <%= version %> - <%= title %>
*Version 1.0 - <%= currentDate.toISOString().split('T')[0] %> - Progression globale : <%= completedTasks %> / <%= totalTasks %>*

<%= description %>

## Points de vigilance
- ⚠️ (HAUTE) Points critiques à surveiller
- ⚠️ (MOYENNE) Points d'attention régulière
- ⚠️ (BASSE) Points à garder en mémoire

## 📊 Dashboard de Suivi

| Métrique | Valeur | Objectif | Statut |
|----------|--------|----------|--------|
| Scripts Développés | <%= completedTasks %>/<%= totalTasks %> | <%= totalTasks %> | 🟡 Démarrage |
| Efficacité | <%= efficiency %>% | 80% | 📊 Baseline |
| Tests | <%= testCoverage %>% | 85% | 📊 À implémenter |

<% for (let i = 1; i <= phases; i++) { %>
## 🎯 Phase <%= i %>
*Progression: <%= completedTasks %>%*

### 📦 Scripts et Tâches
- [ ] Analyse des besoins
- [ ] Conception technique
- [ ] Implémentation
- [ ] Tests et validation
- [ ] Documentation

<% } %>

## 🚀 Commandes de Suivi

```powershell
# Mettre à jour une tâche
hygen plan-dev update task-status --task "1.1.1" --status "done"

# Générer un rapport de progression
hygen plan-dev report progress --phase 1

# Visualiser les métriques de performance
hygen plan-dev metrics view
```

---

*Plan généré le <%= timeFormatted %> | Auteur: <%= locals.author || 'gerivdb' %>*