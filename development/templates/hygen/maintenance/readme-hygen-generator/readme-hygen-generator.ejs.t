<% /*
  Générateur universel de README dynamique pour dossiers de templates Hygen
  Utilise des sous-modules EJS pour chaque section majeure.
*/ %>
---
to: <%= typeof outputPath !== 'undefined' ? outputPath : 'README.md' %>
---
# 📄 Template Hygen — <%= typeof templateName !== 'undefined' ? templateName : 'Nom du template' %> (README dynamique)

<%- include('intro.ejs', { templateName }) %>

<%- include('structure.ejs', { files }) %>

<%- include('roles.ejs', { files }) %>

<%- include('usage.ejs', { usage, templateName }) %>

<%- include('customization.ejs') %>

<%- include('practices.ejs') %>

---

> Ce README est généré dynamiquement pour toujours refléter la structure réelle du template et de ses générateurs.
