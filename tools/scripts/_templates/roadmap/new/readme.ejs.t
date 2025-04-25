<#
---
to: D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/scripts/roadmap/<%= category %>/<%= subcategory %>/README.md
unless_exists: true
---
# <%= h.changeCase.title(subcategory) %> - <%= h.changeCase.title(category) %>

Cette section contient les scripts liés à <%= h.changeCase.lower(subcategory) %> dans la catégorie <%= h.changeCase.lower(category) %>.

## Scripts disponibles

- `<%= name %>.ps1` - <%= description %>

## Utilisation

```powershell
# Exemple d'utilisation
.\<%= name %>.ps1 -InputPath "Roadmap/roadmap.md" -OutputPath "Roadmap/output.md"
```

## Dépendances

Ces scripts peuvent dépendre des modules suivants :
- `roadmap-parser` - Module principal de parsing de roadmap

## Tests

Les tests unitaires pour ces scripts se trouvent dans le dossier `tests/<%= category %>`.
