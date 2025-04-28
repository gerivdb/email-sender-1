#Requires -Version 5.1
<#
.SYNOPSIS
    <%= h.inflection.humanize(name) %>.
.DESCRIPTION
    <%= description %>
.PARAMETER OutputPath
    Chemin du dossier pour les rapports de sortie.
.EXAMPLE
    .\<%= name %>.ps1 -OutputPath ".\reports\output"
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: <%= h.now() %>
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\reports\output"
)

# Fonction pour écrire dans le journal
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
    }
    
    Write-Host $logMessage -ForegroundColor $color
}

# Code principal
Write-Log "Démarrage de <%= h.inflection.humanize(name) %>..." -Level "INFO"

# Votre code ici

Write-Log "Opération terminée avec succès." -Level "SUCCESS"
