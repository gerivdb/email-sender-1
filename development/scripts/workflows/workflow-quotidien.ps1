<#
.SYNOPSIS
    Script d'automatisation pour les tâches quotidiennes de gestion de roadmap.

.DESCRIPTION
    Ce script exécute les tâches quotidiennes de gestion de roadmap :
    1. Synchronisation de la roadmap principale
    2. Vérification de l'état d'avancement
    3. Journalisation des résultats

.PARAMETER RoadmapPath
    Chemin vers le fichier de roadmap principal.
    Par défaut : "projet\roadmaps\Roadmap\roadmap_complete_converted.md"

.PARAMETER LogPath
    Chemin vers le répertoire de journalisation.
    Par défaut : "projet\roadmaps\Logs"

.PARAMETER ConfigPath
    Chemin vers le fichier de configuration unifiée.
    Par défaut : "development\config\unified-config.json"

.EXAMPLE
    .\workflow-quotidien.ps1

.EXAMPLE
    .\workflow-quotidien.ps1 -RoadmapPath "projet\roadmaps\mes-plans\roadmap_perso.md"

.NOTES
    Auteur: Integrated Manager Team
    Version: 1.0
    Date de création: 2023-06-01
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

# Déterminer le chemin du projet
$projectRoot = $PSScriptRoot
while (-not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container) -and 
       -not [string]::IsNullOrEmpty($projectRoot)) {
    $projectRoot = Split-Path -Path $projectRoot -Parent
}

if ([string]::IsNullOrEmpty($projectRoot) -or -not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container)) {
    $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
    if (-not (Test-Path -Path $projectRoot -PathType Container)) {
        Write-Error "Impossible de déterminer le chemin du projet."
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

# Vérifier que le fichier de roadmap existe
if (-not (Test-Path -Path $RoadmapPath)) {
    Write-Error "Le fichier de roadmap spécifié n'existe pas : $RoadmapPath"
    exit 1
}

# Créer le répertoire de journalisation s'il n'existe pas
if (-not (Test-Path -Path $LogPath)) {
    New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
}

# Définir le chemin du fichier de journal
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

# Définir le chemin du gestionnaire intégré
$integratedManagerPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\integrated-manager.ps1"

# Vérifier que le gestionnaire intégré existe
if (-not (Test-Path -Path $integratedManagerPath)) {
    Write-Log "Le gestionnaire intégré est introuvable : $integratedManagerPath" -Level "ERROR"
    exit 1
}

# Journaliser le début du workflow
Write-Log "Début du workflow quotidien" -Level "INFO"
Write-Log "Fichier de roadmap : $RoadmapPath" -Level "INFO"
Write-Log "Fichier de journal : $logFile" -Level "INFO"
Write-Log "Fichier de configuration : $ConfigPath" -Level "INFO"

try {
    # Étape 1: Synchronisation de la roadmap principale
    Write-Log "Étape 1: Synchronisation de la roadmap principale" -Level "INFO"
    
    # Synchroniser la roadmap vers JSON
    Write-Log "Synchronisation de la roadmap vers JSON" -Level "INFO"
    $syncJsonResult = & $integratedManagerPath -Mode "ROADMAP-SYNC" -SourcePath $RoadmapPath -TargetFormat "JSON" -ConfigPath $ConfigPath
    
    if ($syncJsonResult.Success) {
        Write-Log "Synchronisation vers JSON réussie : $($syncJsonResult.TargetPath)" -Level "SUCCESS"
    } else {
        Write-Log "Échec de la synchronisation vers JSON : $($syncJsonResult.TargetPath)" -Level "ERROR"
    }
    
    # Synchroniser la roadmap vers HTML
    Write-Log "Synchronisation de la roadmap vers HTML" -Level "INFO"
    $syncHtmlResult = & $integratedManagerPath -Mode "ROADMAP-SYNC" -SourcePath $RoadmapPath -TargetFormat "HTML" -ConfigPath $ConfigPath
    
    if ($syncHtmlResult.Success) {
        Write-Log "Synchronisation vers HTML réussie : $($syncHtmlResult.TargetPath)" -Level "SUCCESS"
    } else {
        Write-Log "Échec de la synchronisation vers HTML : $($syncHtmlResult.TargetPath)" -Level "ERROR"
    }
    
    # Étape 2: Vérification de l'état d'avancement
    Write-Log "Étape 2: Vérification de l'état d'avancement" -Level "INFO"
    
    $checkResult = & $integratedManagerPath -Mode "CHECK" -RoadmapPath $RoadmapPath -ConfigPath $ConfigPath
    
    if ($checkResult) {
        Write-Log "Vérification de l'état d'avancement réussie" -Level "SUCCESS"
        Write-Log "Tâches mises à jour : $($checkResult.TasksUpdated -join ', ')" -Level "INFO"
        Write-Log "Rapport généré : $($checkResult.ReportPath)" -Level "INFO"
    } else {
        Write-Log "Échec de la vérification de l'état d'avancement" -Level "ERROR"
    }
    
    # Étape 3: Génération d'un rapport quotidien
    Write-Log "Étape 3: Génération d'un rapport quotidien" -Level "INFO"
    
    $reportPath = Join-Path -Path (Split-Path -Parent $LogPath) -ChildPath "Reports\quotidien-$date"
    $reportResult = & $integratedManagerPath -Mode "ROADMAP-REPORT" -RoadmapPath $RoadmapPath -OutputPath $reportPath -ReportFormat "HTML" -ConfigPath $ConfigPath
    
    if ($reportResult) {
        Write-Log "Génération du rapport quotidien réussie" -Level "SUCCESS"
        Write-Log "Rapport généré : $($reportResult.GeneratedReports -join ', ')" -Level "INFO"
    } else {
        Write-Log "Échec de la génération du rapport quotidien" -Level "ERROR"
    }
    
    # Journaliser la fin du workflow
    Write-Log "Fin du workflow quotidien" -Level "SUCCESS"
} catch {
    # Journaliser l'erreur
    Write-Log "Erreur lors de l'exécution du workflow quotidien : $_" -Level "ERROR"
    Write-Log "Trace de la pile : $($_.ScriptStackTrace)" -Level "ERROR"
    exit 1
}

# Retourner un résultat
return @{
    RoadmapPath = $RoadmapPath
    LogFile = $logFile
    SyncJsonResult = $syncJsonResult
    SyncHtmlResult = $syncHtmlResult
    CheckResult = $checkResult
    ReportResult = $reportResult
    Success = $true
}
