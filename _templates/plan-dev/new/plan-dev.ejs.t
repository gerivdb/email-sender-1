---
to: projet/roadmaps/plans/plan-dev-<%= version %>-<%= title.toLowerCase().replace(/ /g, '-') %>.md
---
# Plan de développement <%= version %> - <%= title %>
*Version 1.0 - <%= new Date().toISOString().split('T')[0] %> - Progression globale : 0%*

<%= description %>

<% for(let i = 1; i <= phases; i++) { %>
## <%= i %>. Phase <%= i %> (Phase <%= i %>)

- [ ] **<%= i %>.1** Tâche principale 1
  - [ ] **<%= i %>.1.1** Sous-tâche 1.1
    - [ ] **<%= i %>.1.1.1** Sous-sous-tâche 1.1.1
      - [ ] **<%= i %>.1.1.1.1** Action 1.1.1.1
      - [ ] **<%= i %>.1.1.1.2** Action 1.1.1.2
      - [ ] **<%= i %>.1.1.1.3** Action 1.1.1.3
    - [ ] **<%= i %>.1.1.2** Sous-sous-tâche 1.1.2
      - [ ] **<%= i %>.1.1.2.1** Action 1.1.2.1
      - [ ] **<%= i %>.1.1.2.2** Action 1.1.2.2
      - [ ] **<%= i %>.1.1.2.3** Action 1.1.2.3
    - [ ] **<%= i %>.1.1.3** Sous-sous-tâche 1.1.3
      - [ ] **<%= i %>.1.1.3.1** Action 1.1.3.1
      - [ ] **<%= i %>.1.1.3.2** Action 1.1.3.2
      - [ ] **<%= i %>.1.1.3.3** Action 1.1.3.3
  - [ ] **<%= i %>.1.2** Sous-tâche 1.2
    - [ ] **<%= i %>.1.2.1** Sous-sous-tâche 1.2.1
      - [ ] **<%= i %>.1.2.1.1** Action 1.2.1.1
      - [ ] **<%= i %>.1.2.1.2** Action 1.2.1.2
      - [ ] **<%= i %>.1.2.1.3** Action 1.2.1.3
    - [ ] **<%= i %>.1.2.2** Sous-sous-tâche 1.2.2
      - [ ] **<%= i %>.1.2.2.1** Action 1.2.2.1
      - [ ] **<%= i %>.1.2.2.2** Action 1.2.2.2
      - [ ] **<%= i %>.1.2.2.3** Action 1.2.2.3
    - [ ] **<%= i %>.1.2.3** Sous-sous-tâche 1.2.3
      - [ ] **<%= i %>.1.2.3.1** Action 1.2.3.1
      - [ ] **<%= i %>.1.2.3.2** Action 1.2.3.2
      - [ ] **<%= i %>.1.2.3.3** Action 1.2.3.3
  - [ ] **<%= i %>.1.3** Sous-tâche 1.3
    - [ ] **<%= i %>.1.3.1** Sous-sous-tâche 1.3.1
      - [ ] **<%= i %>.1.3.1.1** Action 1.3.1.1
      - [ ] **<%= i %>.1.3.1.2** Action 1.3.1.2
      - [ ] **<%= i %>.1.3.1.3** Action 1.3.1.3
    - [ ] **<%= i %>.1.3.2** Sous-sous-tâche 1.3.2
      - [ ] **<%= i %>.1.3.2.1** Action 1.3.2.1
      - [ ] **<%= i %>.1.3.2.2** Action 1.3.2.2
      - [ ] **<%= i %>.1.3.2.3** Action 1.3.2.3
    - [ ] **<%= i %>.1.3.3** Sous-sous-tâche 1.3.3
      - [ ] **<%= i %>.1.3.3.1** Action 1.3.3.1
      - [ ] **<%= i %>.1.3.3.2** Action 1.3.3.2
      - [ ] **<%= i %>.1.3.3.3** Action 1.3.3.3

- [ ] **<%= i %>.2** Tâche principale 2
  - [ ] **<%= i %>.2.1** Sous-tâche 2.1
    - [ ] **<%= i %>.2.1.1** Sous-sous-tâche 2.1.1
    - [ ] **<%= i %>.2.1.2** Sous-sous-tâche 2.1.2
    - [ ] **<%= i %>.2.1.3** Sous-sous-tâche 2.1.3
  - [ ] **<%= i %>.2.2** Sous-tâche 2.2
    - [ ] **<%= i %>.2.2.1** Sous-sous-tâche 2.2.1
    - [ ] **<%= i %>.2.2.2** Sous-sous-tâche 2.2.2
    - [ ] **<%= i %>.2.2.3** Sous-sous-tâche 2.2.3
  - [ ] **<%= i %>.2.3** Sous-tâche 2.3
    - [ ] **<%= i %>.2.3.1** Sous-sous-tâche 2.3.1
    - [ ] **<%= i %>.2.3.2** Sous-sous-tâche 2.3.2
    - [ ] **<%= i %>.2.3.3** Sous-sous-tâche 2.3.3
<% } %>
