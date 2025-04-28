---
to: <%= docType %>/<%= category %><%= subcategory ? '/' + subcategory : '' %>/README.md
---
# <%= category.charAt(0).toUpperCase() + category.slice(1) %><%= subcategory ? ' - ' + subcategory.charAt(0).toUpperCase() + subcategory.slice(1) : '' %>

Cette documentation fait partie de la section <%= docType === 'projet' ? 'Projet' : 'Development' %>.

## Contenu

Cette section contient la documentation relative à <%= category %><%= subcategory ? ' - ' + subcategory : '' %>.

## Structure

```
<%= docType %>/<%= category %><%= subcategory ? '/' + subcategory : '' %>/
├── README.md (ce fichier)
└── ...
```
