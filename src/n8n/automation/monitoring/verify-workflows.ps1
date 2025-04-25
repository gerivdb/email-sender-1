<#
.SYNOPSIS
    Script de vérification de la présence des workflows n8n.

.DESCRIPTION
    Ce script vérifie la présence des workflows n8n en comparant les workflows de référence
    avec les workflows cibles. Il peut utiliser l'API REST ou le système de fichiers pour
    récupérer les workflows cibles.

.PARAMETER WorkflowFolder
    Dossier contenant les workflows cibles (par défaut: n8n/data/.n8n/workflows).

.PARAMETER ReferenceFolder
    Dossier contenant les workflows de référence (par défaut: n8n/core/workflows/local).

.PARAMETER ApiMethod
    Indique si la méthode API doit être utilisée pour récupérer les workflows cibles (par défaut: $false).

.PARAMETER Hostname
    Hôte n8n pour la méthode API (par défaut: localhost).

.PARAMETER Port
    Port n8n pour la méthode API (par défaut: 5678).

.PARAMETER Protocol
    Protocole pour la méthode API (http ou https) (par défaut: http).

.PARAMETER ApiKey
    API Key à utiliser pour la méthode API. Si non spécifiée, elle sera récupérée depuis les fichiers de configuration.

.PARAMETER LogFile
    Fichier de log pour la vérification (par défaut: n8n/logs/verify-workflows.log).

.PARAMETER Recursive
    Indique si les sous-dossiers doivent être parcourus récursivement (par défaut: $true).

.PARAMETER NotificationEnabled
    Indique si les notifications doivent être envoyées (par défaut: $true).

.PARAMETER NotificationScript
    Script à utiliser pour envoyer les notifications (par défaut: n8n/automation/notification/send-notification.ps1).

.PARAMETER NotificationLevel
    Niveau minimum pour envoyer une notification (INFO, WARNING, ERROR) (par défaut: WARNING).

.PARAMETER OutputFile
    Fichier de sortie pour les résultats de la vérification (par défaut: n8n/logs/missing-workflows.json).

.PARAMETER DetailLevel
    Niveau de détail des résultats (1: Basic, 2: Standard, 3: Detailed) (par défaut: 2).

.EXAMPLE
    .\verify-workflows.ps1 -ReferenceFolder "path/to/reference" -WorkflowFolder "path/to/workflows"

.EXAMPLE
    .\verify-workflows.ps1 -ApiMethod $true -Hostname "localhost" -Port 5678

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  22/04/2025
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$WorkflowFolder = "n8n/data/.n8n/workflows",
    
    [Parameter(Mandatory=$false)]
    [string]$ReferenceFolder = "n8n/core/workflows/local",
    
    [Parameter(Mandatory=$false)]
    [bool]$ApiMethod = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$Hostname = "localhost",
    
    [Parameter(Mandatory=$false)]
    [int]$Port = 5678,
    
    [Parameter(Mandatory=$false)]
    [string]$Protocol = "http",
    
    [Parameter(Mandatory=$false)]
    [string]$ApiKey = "",
    
    [Parameter(Mandatory=$false)]
    [string]$LogFile = "n8n/logs/verify-workflows.log",
    
    [Parameter(Mandatory=$false)]
    [bool]$Recursive = $true,
    
    [Parameter(Mandatory=$false)]
    [bool]$NotificationEnabled = $true,
    
    [Parameter(Mandatory=$false)]
    [string]$NotificationScript = "n8n/automation/notification/send-notification.ps1",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("INFO", "WARNING", "ERROR")]
    [string]$NotificationLevel = "WARNING",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFile = "n8n/logs/missing-workflows.json",
    
    [Parameter(Mandatory=$false)]
    [ValidateRange(1, 3)]
    [int]$DetailLevel = 2
)

# Importer les fonctions des parties précédentes
. "$PSScriptRoot\verify-workflows-part1.ps1"
. "$PSScriptRoot\verify-workflows-part2.ps1"
. "$PSScriptRoot\verify-workflows-part3.ps1"

# Mettre à jour les paramètres communs
$script:CommonParams.WorkflowFolder = $WorkflowFolder
$script:CommonParams.ReferenceFolder = $ReferenceFolder
$script:CommonParams.ApiMethod = $ApiMethod
$script:CommonParams.Hostname = $Hostname
$script:CommonParams.Port = $Port
$script:CommonParams.Protocol = $Protocol
$script:CommonParams.ApiKey = $ApiKey
$script:CommonParams.LogFile = $LogFile
$script:CommonParams.Recursive = $Recursive
$script:CommonParams.NotificationEnabled = $NotificationEnabled
$script:CommonParams.NotificationScript = $NotificationScript
$script:CommonParams.NotificationLevel = $NotificationLevel
$script:CommonParams.OutputFile = $OutputFile
$script:CommonParams.DetailLevel = $DetailLevel

# Vérifier si le dossier de log existe
$logFolder = Split-Path -Path $LogFile -Parent
if (-not (Test-Path -Path $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
}

# Vérifier la présence des workflows
$results = Verify-Workflows -WorkflowFolder $WorkflowFolder -ReferenceFolder $ReferenceFolder -ApiMethod $ApiMethod -Hostname $Hostname -Port $Port -Protocol $Protocol -ApiKey $ApiKey -Recursive $Recursive -OutputFile $OutputFile -DetailLevel $DetailLevel

# Afficher le résumé
Write-Log "`n=== Résumé de la vérification ===" -Level "INFO"
Write-Log "Nombre de workflows de référence: $($results.ReferenceCount)" -Level "INFO"
Write-Log "Nombre de workflows cibles: $($results.TargetCount)" -Level "INFO"
Write-Log "Nombre de workflows manquants: $($results.MissingCount)" -Level $(if ($results.MissingCount -gt 0) { "WARNING" } else { "SUCCESS" })
Write-Log "Nombre de workflows présents: $($results.PresentCount)" -Level "INFO"

# Retourner les résultats
return $results
