<#
.SYNOPSIS
    Script d'importation automatique des workflows n8n.

.DESCRIPTION
    Ce script importe automatiquement les workflows n8n depuis des fichiers JSON.
    Il peut utiliser l'API REST ou la CLI n8n selon la configuration.

.PARAMETER SourceFolder
    Dossier contenant les workflows à importer (par défaut: n8n/core/workflows/local).

.PARAMETER TargetFolder
    Dossier de destination pour les workflows importés (par défaut: n8n/data/.n8n/workflows).

.PARAMETER Method
    Méthode d'importation à utiliser (API ou CLI, par défaut: CLI).

.PARAMETER ApiKey
    API Key à utiliser pour l'importation via API. Si non spécifiée, elle sera récupérée depuis les fichiers de configuration.

.PARAMETER Hostname
    Hôte n8n pour l'importation via API (par défaut: localhost).

.PARAMETER Port
    Port n8n pour l'importation via API (par défaut: 5678).

.PARAMETER Protocol
    Protocole pour l'importation via API (http ou https) (par défaut: http).

.PARAMETER Tags
    Tags à ajouter aux workflows importés (séparés par des virgules).

.PARAMETER Active
    Indique si les workflows importés doivent être activés (par défaut: $true).

.PARAMETER Force
    Force l'importation même si le workflow existe déjà (par défaut: $false).

.PARAMETER LogFile
    Fichier de log pour l'importation (par défaut: n8n/logs/import-workflows.log).

.PARAMETER Recursive
    Indique si les sous-dossiers doivent être parcourus récursivement (par défaut: $true).

.PARAMETER BackupFolder
    Dossier de sauvegarde pour les workflows existants avant importation (par défaut: n8n/data/.n8n/workflows/backup).

.PARAMETER MaxConcurrent
    Nombre maximum d'importations simultanées (par défaut: 5).

.EXAMPLE
    .\import-workflows-auto-main.ps1 -SourceFolder "path/to/workflows" -Method "API" -Tags "imported,auto" -Active $true

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  22/04/2025
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$SourceFolder = "n8n/core/workflows/local",
    
    [Parameter(Mandatory=$false)]
    [string]$TargetFolder = "n8n/data/.n8n/workflows",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("API", "CLI")]
    [string]$Method = "CLI",
    
    [Parameter(Mandatory=$false)]
    [string]$ApiKey = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Hostname = "localhost",
    
    [Parameter(Mandatory=$false)]
    [int]$Port = 5678,
    
    [Parameter(Mandatory=$false)]
    [string]$Protocol = "http",
    
    [Parameter(Mandatory=$false)]
    [string]$Tags = "",
    
    [Parameter(Mandatory=$false)]
    [bool]$Active = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$LogFile = "n8n/logs/import-workflows.log",
    
    [Parameter(Mandatory=$false)]
    [bool]$Recursive = $true,
    
    [Parameter(Mandatory=$false)]
    [string]$BackupFolder = "n8n/data/.n8n/workflows/backup",
    
    [Parameter(Mandatory=$false)]
    [int]$MaxConcurrent = 5
)

# Importer les fonctions des parties précédentes
. "$PSScriptRoot\import-workflows-auto-part1.ps1"
. "$PSScriptRoot\import-workflows-auto-part2.ps1"
. "$PSScriptRoot\import-workflows-auto-part3.ps1"

# Mettre à jour les paramètres communs
$script:CommonParams.SourceFolder = $SourceFolder
$script:CommonParams.TargetFolder = $TargetFolder
$script:CommonParams.Method = $Method
$script:CommonParams.ApiKey = $ApiKey
$script:CommonParams.Hostname = $Hostname
$script:CommonParams.Port = $Port
$script:CommonParams.Protocol = $Protocol
$script:CommonParams.Tags = $Tags
$script:CommonParams.Active = $Active
$script:CommonParams.Force = $Force
$script:CommonParams.LogFile = $LogFile
$script:CommonParams.Recursive = $Recursive
$script:CommonParams.BackupFolder = $BackupFolder
$script:CommonParams.MaxConcurrent = $MaxConcurrent

# Vérifier si le dossier de log existe
$logFolder = Split-Path -Path $LogFile -Parent
if (-not (Test-Path -Path $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
}

# Afficher les informations de démarrage
Write-Log "=== Importation automatique des workflows n8n ===" -Level "INFO"
Write-Log "Dossier source: $SourceFolder" -Level "INFO"
Write-Log "Dossier cible: $TargetFolder" -Level "INFO"
Write-Log "Méthode d'importation: $Method" -Level "INFO"
Write-Log "Tags: $Tags" -Level "INFO"
Write-Log "Activation: $Active" -Level "INFO"
Write-Log "Force: $Force" -Level "INFO"
Write-Log "Récursif: $Recursive" -Level "INFO"
Write-Log "Dossier de sauvegarde: $BackupFolder" -Level "INFO"
Write-Log "Fichier de log: $LogFile" -Level "INFO"

# Récupérer l'API Key si nécessaire
if ($Method -eq "API" -and [string]::IsNullOrEmpty($ApiKey)) {
    $ApiKey = Get-ApiKeyFromConfig
    if ([string]::IsNullOrEmpty($ApiKey)) {
        Write-Log "Aucune API Key trouvée. L'importation via API échouera." -Level "ERROR"
        exit 1
    } else {
        Write-Log "API Key récupérée depuis la configuration." -Level "INFO"
    }
}

# Construire l'URL de l'API si nécessaire
$ApiUrl = ""
if ($Method -eq "API") {
    $ApiUrl = "$Protocol`://$Hostname`:$Port/api/v1/workflows/import"
    Write-Log "URL de l'API: $ApiUrl" -Level "INFO"
}

# Importer les workflows
$results = Import-Workflows -SourceFolder $SourceFolder -TargetFolder $TargetFolder -Method $Method -ApiKey $ApiKey -ApiUrl $ApiUrl -Tags $Tags -Active $Active -Recursive $Recursive -BackupFolder $BackupFolder -Force $Force -MaxConcurrent $MaxConcurrent

# Afficher le résumé
Write-Log "=== Résumé de l'importation ===" -Level "INFO"
Write-Log "Total des fichiers: $($results.Total)" -Level "INFO"
Write-Log "Succès: $($results.Success)" -Level "SUCCESS"
Write-Log "Échecs: $($results.Failure)" -Level "ERROR"
Write-Log "Taux de réussite: $($results.SuccessRate)%" -Level "INFO"

# Retourner les résultats
return $results
