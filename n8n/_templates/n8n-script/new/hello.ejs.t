---
to: n8n/automation/<%= category %>/<%= name %>.ps1
---
<#
.SYNOPSIS
    <%= description %>

.DESCRIPTION
    <%= description %>

.PARAMETER Param1
    Description du paramètre 1

.EXAMPLE
    ./<%= name %>.ps1 -Param1 "Valeur"

.NOTES
    Auteur: <%= author %>
    Date de création: <%= new Date().toISOString().split('T')[0] %>
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [Parameter(Mandatory=$false)]
    [string]$Param1 = ""
)

#region Initialisation
$ErrorActionPreference = "Stop"
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptName = Split-Path -Leaf $MyInvocation.MyCommand.Path
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Importer les modules communs
$modulePath = Join-Path -Path $scriptPath -ChildPath "..\..\modules"
if (Test-Path -Path $modulePath) {
    $modules = @("Logger", "ConfigManager")
    foreach ($module in $modules) {
        $modulePath = Join-Path -Path $scriptPath -ChildPath "..\..\modules\$module.psm1"
        if (Test-Path -Path $modulePath) {
            Import-Module $modulePath -Force
        }
    }
}
#endregion Initialisation

#region Fonctions
function Start-MainProcess {
    [CmdletBinding()]
    param ()

    try {
        Write-Host "[$timestamp] Démarrage du script $scriptName" -ForegroundColor Cyan

        # Votre code ici

        Write-Host "[$timestamp] Exécution terminée avec succès" -ForegroundColor Green
    }
    catch {
        Write-Host "[$timestamp] Erreur lors de l'exécution: $_" -ForegroundColor Red
        throw $_
    }
}
#endregion Fonctions

#region Exécution principale
Start-MainProcess
#endregion Exécution principale
