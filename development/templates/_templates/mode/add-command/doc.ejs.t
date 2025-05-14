---
to: docs/guides/modes/<%= modeLower %>-mode.md
inject: true
after: "### Commandes spécifiques"
skip_if: "| `<%= name %>`"
---

| `<%= name %>` | <%= description %> | `.\<%= modeLower %>-mode.ps1 -Command <%= name %> -Target "chemin/vers/cible"` |
