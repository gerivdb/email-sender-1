---
to: _templates/<%= name %>/<%= action || 'new' %>/hello.ejs.t
---
---
to: <%= h.projectPath() %>/<%= path %>/<%= name %>.md
---
# <%= h.changeCase.title(name) %>

Ce fichier a été généré avec Hygen.

## Informations

- **Nom**: <%= name %>
- **Date de création**: <%= h.now() %>
- **Auteur**: <%= author || 'Système' %>

## Description

<%= description || 'Aucune description fournie.' %>
