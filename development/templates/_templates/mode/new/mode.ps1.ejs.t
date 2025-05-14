---
to: development/scripts/modes/<%= nameLower %>-mode.ps1
---
<#
.SYNOPSIS
    <%= name %> - <%= description %>

.DESCRIPTION
    Mode opérationnel <%= name %> pour <%= description %>.
    Catégorie: <%= category %>
    Généré automatiquement le <%= date %>

.PARAMETER Command
    Commande à exécuter. Valeurs possibles: <%= commands.map(c => c.name).join(', ') %>

.PARAMETER Target
    Cible sur laquelle exécuter la commande (fichier, répertoire, etc.)

.PARAMETER Options
    Options supplémentaires pour la commande (hashtable)

.EXAMPLE
    .\<%= nameLower %>-mode.ps1 -Command RUN -Target "chemin/vers/cible"

.EXAMPLE
    .\<%= nameLower %>-mode.ps1 -Command <%= commands[0].name %> -Target "chemin/vers/cible" -Options @{Option1="Valeur1"; Option2="Valeur2"}

.NOTES
    Auteur: Généré automatiquement
    Date de création: <%= date %>
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$Command,
    
    [Parameter(Mandatory=$false)]
    [string]$Target = "",
    
    [Parameter(Mandatory=$false)]
    [hashtable]$Options = @{}
)

# Importer le module commun
try {
    Import-Module ModesCommon -ErrorAction Stop
} catch {
    Write-Error "Impossible de charger le module ModesCommon. Erreur: $_"
    exit 1
}

# Initialiser le mode
Initialize-Mode -Name "<%= name %>" -Category "<%= category %>"

# Traiter la commande
try {
    switch ($Command) {
        # Commandes standard
        "RUN"    { 
            if ($PSCmdlet.ShouldProcess("$Target", "Exécuter le mode <%= name %>")) {
                Invoke-<%= name %>Run -Target $Target -Options $Options 
            }
        }
        "CHECK"  { Get-<%= name %>Status -Target $Target -Options $Options }
        "DEBUG"  { Start-<%= name %>Debug -Target $Target -Options $Options }
        "TEST"   { Invoke-<%= name %>Test -Target $Target -Options $Options }
        "HELP"   { Get-<%= name %>Help -Target $Target -Options $Options }
        
        # Commandes spécifiques au mode
<% commands.forEach(function(cmd) { 
    if (!['RUN', 'CHECK', 'DEBUG', 'TEST', 'HELP'].includes(cmd.name)) { %>
        "<%= cmd.name %>" { <%= cmd.function %> -Target $Target -Options $Options }
<% }
}); %>
        
        default  { 
            Write-Error "Commande non reconnue: $Command. Utilisez HELP pour voir les commandes disponibles."
            exit 1
        }
    }
} catch {
    Write-Error "Erreur lors de l'exécution de la commande $Command. Erreur: $_"
    exit 1
}

# Fonctions standard
function Invoke-<%= name %>Run {
    [CmdletBinding()]
    param (
        [string]$Target,
        [hashtable]$Options
    )
    
    Write-Log -Level Info -Message "Exécution du mode <%= name %> sur la cible: $Target"
    
    # TODO: Implémenter la logique d'exécution du mode <%= name %>
    
    Write-Log -Level Success -Message "Mode <%= name %> exécuté avec succès"
}

function Get-<%= name %>Status {
    [CmdletBinding()]
    param (
        [string]$Target,
        [hashtable]$Options
    )
    
    Write-Log -Level Info -Message "Vérification du statut du mode <%= name %> pour la cible: $Target"
    
    # TODO: Implémenter la logique de vérification du statut
    
    Write-Log -Level Info -Message "Statut du mode <%= name %>: OK"
}

function Start-<%= name %>Debug {
    [CmdletBinding()]
    param (
        [string]$Target,
        [hashtable]$Options
    )
    
    Write-Log -Level Info -Message "Démarrage du débogage du mode <%= name %> pour la cible: $Target"
    
    # TODO: Implémenter la logique de débogage
    
    Write-Log -Level Success -Message "Débogage du mode <%= name %> terminé"
}

function Invoke-<%= name %>Test {
    [CmdletBinding()]
    param (
        [string]$Target,
        [hashtable]$Options
    )
    
    Write-Log -Level Info -Message "Exécution des tests du mode <%= name %> pour la cible: $Target"
    
    # TODO: Implémenter la logique de test
    
    Write-Log -Level Success -Message "Tests du mode <%= name %> exécutés avec succès"
}

function Get-<%= name %>Help {
    [CmdletBinding()]
    param (
        [string]$Target,
        [hashtable]$Options
    )
    
    $helpText = @"
Mode <%= name %> - <%= description %>
==================================

COMMANDES DISPONIBLES:
- RUN    : Exécute le mode <%= name %> sur la cible spécifiée
- CHECK  : Vérifie le statut du mode <%= name %> pour la cible spécifiée
- DEBUG  : Démarre le débogage du mode <%= name %> pour la cible spécifiée
- TEST   : Exécute les tests du mode <%= name %> pour la cible spécifiée
- HELP   : Affiche cette aide
<% commands.forEach(function(cmd) { 
    if (!['RUN', 'CHECK', 'DEBUG', 'TEST', 'HELP'].includes(cmd.name)) { %>
- <%= cmd.name.padEnd(6) %>: <%= cmd.description %>
<% }
}); %>

EXEMPLES:
.\<%= nameLower %>-mode.ps1 -Command RUN -Target "chemin/vers/cible"
.\<%= nameLower %>-mode.ps1 -Command <%= commands[0].name %> -Target "chemin/vers/cible" -Options @{Option1="Valeur1"}
"@

    Write-Host $helpText
}

# Fonctions spécifiques au mode
<% commands.forEach(function(cmd) { 
    if (!['RUN', 'CHECK', 'DEBUG', 'TEST', 'HELP'].includes(cmd.name)) { %>
function <%= cmd.function %> {
    [CmdletBinding()]
    param (
        [string]$Target,
        [hashtable]$Options
    )
    
    Write-Log -Level Info -Message "<%= cmd.description %> pour la cible: $Target"
    
    # TODO: Implémenter la logique de la commande <%= cmd.name %>
    
    Write-Log -Level Success -Message "Commande <%= cmd.name %> exécutée avec succès"
}

<% }
}); %>
