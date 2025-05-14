---
to: development/scripts/modes/<%= modeLower %>-mode.ps1
inject: true
after: "# Fonctions spécifiques au mode"
skip_if: "function <%= function %>"
---

function <%= function %> {
    [CmdletBinding()]
    param (
        [string]$Target,
        [hashtable]$Options<% params.forEach(function(param) { %>,
        
        [<%= param.type %>]$<%= param.name %> = $Options.<%= param.name %><% }); %>
    )
    
    Write-Log -Level Info -Message "<%= description %> pour la cible: $Target"
    
    # TODO: Implémenter la logique de la commande <%= name %>
    
    Write-Log -Level Success -Message "Commande <%= name %> exécutée avec succès"
}
