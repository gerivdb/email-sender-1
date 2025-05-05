<#
.SYNOPSIS
    Script d'automatisation pour les tÃ¢ches quotidiennes de gestion de roadmap.

.DESCRIPTION
    Ce script exÃ©cute les tÃ¢ches quotidiennes de gestion de roadmap :
    1. Synchronisation de la roadmap principale
    2. VÃ©rification de l'Ã©tat d'avancement
    3. Journalisation des rÃ©sultats

.PARAMETER RoadmapPath
    Chemin vers le fichier de roadmap principal.
    Par dÃ©faut : "projet\roadmaps\Roadmap\roadmap_complete_converted.md"

.PARAMETER LogPath
    Chemin vers le rÃ©pertoire de journalisation.
    Par dÃ©faut : "projet\roadmaps\Logs"

.PARAMETER ConfigPath
    Chemin vers le fichier de configuration unifiÃ©e.
    Par dÃ©faut : "development\config\unified-config.json"

.EXAMPLE
    .\workflow-quotidien.ps1

.EXAMPLE
    .\workflow-quotidien.ps1 -RoadmapPath "projet\roadmaps\mes-plans\roadmap_perso.md"

.NOTES
    Auteur: Integrated Manager Team
    Version: 1.0
    Date de crÃ©ation: 2023-06-01
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapPath = "projet\roadmaps\Roadmap\roadmap_complete_converted.md",

    [Parameter(Mandatory = $false)]
    [string]$LogPath = "projet\roadmaps\Logs",

    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = "development\config\unified-config.json"
)

# DÃ©terminer le chemin du projet
$projectRoot = $PSScriptRoot
while (-not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container) -and 
       -not [string]::IsNullOrEmpty($projectRoot)) {
    $projectRoot = Split-Path -Path $projectRoot -Parent
}

if ([string]::IsNullOrEmpty($projectRoot) -or -not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container)) {
    $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
    if (-not (Test-Path -Path $projectRoot -PathType Container)) {
        Write-Error "Impossible de dÃ©terminer le chemin du projet."
        exit 1
    }
}

# Convertir les chemins relatifs en chemins absolus
if (-not [System.IO.Path]::IsPathRooted($RoadmapPath)) {
    $RoadmapPath = Join-Path -Path $projectRoot -ChildPath $RoadmapPath
}

if (-not [System.IO.Path]::IsPathRooted($LogPath)) {
    $LogPath = Join-Path -Path $projectRoot -ChildPath $LogPath
}

if (-not [System.IO.Path]::IsPathRooted($ConfigPath)) {
    $ConfigPath = Join-Path -Path $projectRoot -ChildPath $ConfigPath
}

# VÃ©rifier que le fichier de roadmap existe
if (-not (Test-Path -Path $RoadmapPath)) {
    Write-Error "Le fichier de roadmap spÃ©cifiÃ© n'existe pas : $RoadmapPath"
    exit 1
}

# CrÃ©er le rÃ©pertoire de journalisation s'il n'existe pas
if (-not (Test-Path -Path $LogPath)) {
    New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
}

# DÃ©finir le chemin du fichier de journal
$date = Get-Date -Format "yyyy-MM-dd"
$logFile = Join-Path -Path $LogPath -ChildPath "workflow-quotidien-$date.log"

# Fonction pour journaliser les messages
function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Afficher le message dans la console
    switch ($Level) {
        "INFO" { Write-Host $logMessage -ForegroundColor Gray }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
    }
    
    # Ajouter le message au fichier de journal
    $logMessage | Out-File -FilePath $logFile -Append
}

# DÃ©finir le chemin du gestionnaire intÃ©grÃ©
$integratedManagerPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\integrated-manager.ps1"

# VÃ©rifier que le gestionnaire intÃ©grÃ© existe
if (-not (Test-Path -Path $integratedManagerPath)) {
    Write-Log "Le gestionnaire intÃ©grÃ© est introuvable : $integratedManagerPath" -Level "ERROR"
    exit 1
}

# Journaliser le dÃ©but du workflow
Write-Log "DÃ©but du workflow quotidien" -Level "INFO"
Write-Log "Fichier de roadmap : $RoadmapPath" -Level "INFO"
Write-Log "Fichier de journal : $logFile" -Level "INFO"
Write-Log "Fichier de configuration : $ConfigPath" -Level "INFO"

try {
    # Ã‰tape 1: Synchronisation de la roadmap principale
    Write-Log "Ã‰tape 1: Synchronisation de la roadmap principale" -Level "INFO"
    
    # Synchroniser la roadmap vers JSON
    Write-Log "Synchronisation de la roadmap vers JSON" -Level "INFO"
    $syncJsonResult = & $integratedManagerPath -Mode "ROADMAP-SYNC" -SourcePath $RoadmapPath -TargetFormat "JSON" -ConfigPath $ConfigPath
    
    if ($syncJsonResult.Success) {
        Write-Log "Synchronisation vers JSON rÃ©ussie : $($syncJsonResult.TargetPath)" -Level "SUCCESS"
    } else {
        Write-Log "Ã‰chec de la synchronisation vers JSON : $($syncJsonResult.TargetPath)" -Level "ERROR"
    }
    
    # Synchroniser la roadmap vers HTML
    Write-Log "Synchronisation de la roadmap vers HTML" -Level "INFO"
    $syncHtmlResult = & $integratedManagerPath -Mode "ROADMAP-SYNC" -SourcePath $RoadmapPath -TargetFormat "HTML" -ConfigPath $ConfigPath
    
    if ($syncHtmlResult.Success) {
        Write-Log "Synchronisation vers HTML rÃ©ussie : $($syncHtmlResult.TargetPath)" -Level "SUCCESS"
    } else {
        Write-Log "Ã‰chec de la synchronisation vers HTML : $($syncHtmlResult.TargetPath)" -Level "ERROR"
    }
    
    # Ã‰tape 2: VÃ©rification de l'Ã©tat d'avancement
    Write-Log "Ã‰tape 2: VÃ©rification de l'Ã©tat d'avancement" -Level "INFO"
    
    $checkResult = & $integratedManagerPath -Mode "CHECK" -RoadmapPath $RoadmapPath -ConfigPath $ConfigPath
    
    if ($checkResult) {
        Write-Log "VÃ©rification de l'Ã©tat d'avancement rÃ©ussie" -Level "SUCCESS"
        Write-Log "TÃ¢ches mises Ã  jour : $($checkResult.TasksUpdated -join ', ')" -Level "INFO"
        Write-Log "Rapport gÃ©nÃ©rÃ© : $($checkResult.ReportPath)" -Level "INFO"
    } else {
        Write-Log "Ã‰chec de la vÃ©rification de l'Ã©tat d'avancement" -Level "ERROR"
    }
    
    # Ã‰tape 3: GÃ©nÃ©ration d'un rapport quotidien
    Write-Log "Ã‰tape 3: GÃ©nÃ©ration d'un rapport quotidien" -Level "INFO"
    
    $reportPath = Join-Path -Path (Split-Path -Parent $LogPath) -ChildPath "Reports\quotidien-$date"
    $reportResult = & $integratedManagerPath -Mode "ROADMAP-REPORT" -RoadmapPath $RoadmapPath -OutputPath $reportPath -ReportFormat "HTML" -ConfigPath $ConfigPath
    
    if ($reportResult) {
        Write-Log "GÃ©nÃ©ration du rapport quotidien rÃ©ussie" -Level "SUCCESS"
        Write-Log "Rapport gÃ©nÃ©rÃ© : $($reportResult.GeneratedReports -join ', ')" -Level "INFO"
    } else {
        Write-Log "Ã‰chec de la gÃ©nÃ©ration du rapport quotidien" -Level "ERROR"
    }
    
    # Journaliser la fin du workflow
    Write-Log "Fin du workflow quotidien" -Level "SUCCESS"
} catch {
    # Journaliser l'erreur
    Write-Log "Erreur lors de l'exÃ©cution du workflow quotidien : $_" -Level "ERROR"
    Write-Log "Trace de la pile : $($_.ScriptStackTrace)" -Level "ERROR"
    exit 1
}

# Retourner un rÃ©sultat
return @{
    RoadmapPath = $RoadmapPath
    LogFile = $logFile
    SyncJsonResult = $syncJsonResult
    SyncHtmlResult = $syncHtmlResult
    CheckResult = $checkResult
    ReportResult = $reportResult
    Success = $true
}
