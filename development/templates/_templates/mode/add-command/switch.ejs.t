---
to: development/scripts/modes/<%= modeLower %>-mode.ps1
inject: true
after: "# Commandes spécifiques au mode"
skip_if: "\"<%= name %>\""
---
        "<%= name %>" { <%= function %> -Target $Target -Options $Options }
