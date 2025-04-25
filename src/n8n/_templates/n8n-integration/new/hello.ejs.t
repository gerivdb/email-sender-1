---
to: n8n/integrations/<%= system %>/<%= name %>.ps1
---
<#
.SYNOPSIS
    Script d'intégration <%= system %> - <%= name %>

.DESCRIPTION
    <%= description %>

.PARAMETER ConfigPath
    Chemin vers le fichier de configuration

.EXAMPLE
    ./<%= name %>.ps1 -ConfigPath "config.json"

.NOTES
    Auteur: <%= author %>
    Date de création: <%= new Date().toISOString().split('T')[0] %>
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath = "..\..\config\<%= system %>-config.json"
)

#region Initialisation
$ErrorActionPreference = "Stop"
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptName = Split-Path -Leaf $MyInvocation.MyCommand.Path
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Importer les modules communs
$modulePath = Join-Path -Path $scriptPath -ChildPath "..\..\modules"
if (Test-Path -Path $modulePath) {
    $modules = @("Logger", "ConfigManager", "<%= system %>Helper")
    foreach ($module in $modules) {
        $modulePath = Join-Path -Path $scriptPath -ChildPath "..\..\modules\$module.psm1"
        if (Test-Path -Path $modulePath) {
            Import-Module $modulePath -Force
        }
    }
}
#endregion Initialisation

#region Fonctions
function Get-Configuration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ConfigPath
    )

    try {
        if (Test-Path -Path $ConfigPath) {
            $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
            return $config
        }
        else {
            throw "Le fichier de configuration n'existe pas: $ConfigPath"
        }
    }
    catch {
        Write-Host "[$timestamp] Erreur lors de la lecture de la configuration: $_" -ForegroundColor Red
        throw $_
    }
}

function Start-Integration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Config
    )

    try {
        Write-Host "[$timestamp] Démarrage de l'intégration <%= system %> - <%= name %>" -ForegroundColor Cyan

        # Votre code d'intégration ici

        Write-Host "[$timestamp] Intégration terminée avec succès" -ForegroundColor Green
    }
    catch {
        Write-Host "[$timestamp] Erreur lors de l'intégration: $_" -ForegroundColor Red
        throw $_
    }
}
#endregion Fonctions

#region Exécution principale
try {
    $configFullPath = Join-Path -Path $scriptPath -ChildPath $ConfigPath
    $config = Get-Configuration -ConfigPath $configFullPath
    Start-Integration -Config $config
}
catch {
    Write-Host "[$timestamp] Erreur fatale: $_" -ForegroundColor Red
    exit 1
}
#endregion Exécution principale
