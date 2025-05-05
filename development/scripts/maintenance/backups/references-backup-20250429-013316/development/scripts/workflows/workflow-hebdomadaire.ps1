<#
.SYNOPSIS
    Script d'automatisation pour les tÃ¢ches hebdomadaires de gestion de roadmap.

.DESCRIPTION
    Ce script exÃ©cute les tÃ¢ches hebdomadaires de gestion de roadmap :
    1. Synchronisation de toutes les roadmaps
    2. GÃ©nÃ©ration de rapports hebdomadaires
    3. Planification des tÃ¢ches pour la semaine Ã  venir
    4. Journalisation des rÃ©sultats

.PARAMETER RoadmapPaths
    Tableau des chemins vers les fichiers de roadmap Ã  traiter.
    Par dÃ©faut : @("projet\roadmaps\Roadmap\roadmap_complete_converted.md")

.PARAMETER OutputPath
    Chemin vers le rÃ©pertoire de sortie pour les rapports et les plans.
    Par dÃ©faut : "projet\roadmaps"

.PARAMETER LogPath
    Chemin vers le rÃ©pertoire de journalisation.
    Par dÃ©faut : "projet\roadmaps\Logs"

.PARAMETER ConfigPath
    Chemin vers le fichier de configuration unifiÃ©e.
    Par dÃ©faut : "development\config\unified-config.json"

.EXAMPLE
    .\workflow-hebdomadaire.ps1

.EXAMPLE
    .\workflow-hebdomadaire.ps1 -RoadmapPaths @("projet\roadmaps\Roadmap\roadmap_complete_converted.md", "projet\roadmaps\mes-plans\roadmap_perso.md")

.NOTES
    Auteur: Integrated Manager Team
    Version: 1.0
    Date de crÃ©ation: 2023-06-01
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string[]]$RoadmapPaths = @("projet\roadmaps\Roadmap\roadmap_complete_converted.md"),

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "projet\roadmaps",

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
$absoluteRoadmapPaths = @()
foreach ($path in $RoadmapPaths) {
    if (-not [System.IO.Path]::IsPathRooted($path)) {
        $absoluteRoadmapPaths += Join-Path -Path $projectRoot -ChildPath $path
    } else {
        $absoluteRoadmapPaths += $path
    }
}
$RoadmapPaths = $absoluteRoadmapPaths

if (-not [System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath = Join-Path -Path $projectRoot -ChildPath $OutputPath
}

if (-not [System.IO.Path]::IsPathRooted($LogPath)) {
    $LogPath = Join-Path -Path $projectRoot -ChildPath $LogPath
}

if (-not [System.IO.Path]::IsPathRooted($ConfigPath)) {
    $ConfigPath = Join-Path -Path $projectRoot -ChildPath $ConfigPath
}

# VÃ©rifier que les fichiers de roadmap existent
foreach ($path in $RoadmapPaths) {
    if (-not (Test-Path -Path $path)) {
        Write-Error "Le fichier de roadmap spÃ©cifiÃ© n'existe pas : $path"
        exit 1
    }
}

# CrÃ©er les rÃ©pertoires nÃ©cessaires s'ils n'existent pas
$reportsPath = Join-Path -Path $OutputPath -ChildPath "Reports"
$plansPath = Join-Path -Path $OutputPath -ChildPath "Plans"

foreach ($path in @($LogPath, $reportsPath, $plansPath)) {
    if (-not (Test-Path -Path $path)) {
        New-Item -Path $path -ItemType Directory -Force | Out-Null
    }
}

# DÃ©finir le chemin du fichier de journal
$date = Get-Date -Format "yyyy-MM-dd"
$logFile = Join-Path -Path $LogPath -ChildPath "workflow-hebdomadaire-$date.log"

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
Write-Log "DÃ©but du workflow hebdomadaire" -Level "INFO"
Write-Log "Fichiers de roadmap : $($RoadmapPaths -join ', ')" -Level "INFO"
Write-Log "RÃ©pertoire de sortie : $OutputPath" -Level "INFO"
Write-Log "Fichier de journal : $logFile" -Level "INFO"
Write-Log "Fichier de configuration : $ConfigPath" -Level "INFO"

try {
    # Ã‰tape 1: Synchronisation de toutes les roadmaps
    Write-Log "Ã‰tape 1: Synchronisation de toutes les roadmaps" -Level "INFO"
    
    # Synchroniser toutes les roadmaps vers JSON et HTML
    $syncResults = @()
    
    foreach ($roadmapPath in $RoadmapPaths) {
        Write-Log "Synchronisation de la roadmap : $roadmapPath" -Level "INFO"
        
        # Synchroniser vers JSON
        Write-Log "Synchronisation vers JSON" -Level "INFO"
        $syncJsonResult = & $integratedManagerPath -Mode "ROADMAP-SYNC" -SourcePath $roadmapPath -TargetFormat "JSON" -ConfigPath $ConfigPath
        
        if ($syncJsonResult.Success) {
            Write-Log "Synchronisation vers JSON rÃ©ussie : $($syncJsonResult.TargetPath)" -Level "SUCCESS"
        } else {
            Write-Log "Ã‰chec de la synchronisation vers JSON : $($syncJsonResult.TargetPath)" -Level "ERROR"
        }
        
        # Synchroniser vers HTML
        Write-Log "Synchronisation vers HTML" -Level "INFO"
        $syncHtmlResult = & $integratedManagerPath -Mode "ROADMAP-SYNC" -SourcePath $roadmapPath -TargetFormat "HTML" -ConfigPath $ConfigPath
        
        if ($syncHtmlResult.Success) {
            Write-Log "Synchronisation vers HTML rÃ©ussie : $($syncHtmlResult.TargetPath)" -Level "SUCCESS"
        } else {
            Write-Log "Ã‰chec de la synchronisation vers HTML : $($syncHtmlResult.TargetPath)" -Level "ERROR"
        }
        
        $syncResults += @{
            RoadmapPath = $roadmapPath
            JsonResult = $syncJsonResult
            HtmlResult = $syncHtmlResult
        }
    }
    
    # Ã‰tape 2: GÃ©nÃ©ration de rapports hebdomadaires
    Write-Log "Ã‰tape 2: GÃ©nÃ©ration de rapports hebdomadaires" -Level "INFO"
    
    $reportResults = @()
    
    foreach ($roadmapPath in $RoadmapPaths) {
        $roadmapName = [System.IO.Path]::GetFileNameWithoutExtension($roadmapPath)
        $reportPath = Join-Path -Path $reportsPath -ChildPath "hebdomadaire-$roadmapName-$date"
        
        Write-Log "GÃ©nÃ©ration du rapport hebdomadaire pour : $roadmapPath" -Level "INFO"
        $reportResult = & $integratedManagerPath -Mode "ROADMAP-REPORT" -RoadmapPath $roadmapPath -OutputPath $reportPath -ReportFormat "All" -ConfigPath $ConfigPath
        
        if ($reportResult) {
            Write-Log "GÃ©nÃ©ration du rapport hebdomadaire rÃ©ussie" -Level "SUCCESS"
            Write-Log "Rapports gÃ©nÃ©rÃ©s : $($reportResult.GeneratedReports -join ', ')" -Level "INFO"
        } else {
            Write-Log "Ã‰chec de la gÃ©nÃ©ration du rapport hebdomadaire" -Level "ERROR"
        }
        
        $reportResults += @{
            RoadmapPath = $roadmapPath
            ReportPath = $reportPath
            Result = $reportResult
        }
    }
    
    # Ã‰tape 3: Planification des tÃ¢ches pour la semaine Ã  venir
    Write-Log "Ã‰tape 3: Planification des tÃ¢ches pour la semaine Ã  venir" -Level "INFO"
    
    $planResults = @()
    
    foreach ($roadmapPath in $RoadmapPaths) {
        $roadmapName = [System.IO.Path]::GetFileNameWithoutExtension($roadmapPath)
        $planPath = Join-Path -Path $plansPath -ChildPath "hebdomadaire-$roadmapName-$date.md"
        
        Write-Log "GÃ©nÃ©ration du plan hebdomadaire pour : $roadmapPath" -Level "INFO"
        $planResult = & $integratedManagerPath -Mode "ROADMAP-PLAN" -RoadmapPath $roadmapPath -OutputPath $planPath -DaysToForecast 7 -ConfigPath $ConfigPath
        
        if ($planResult) {
            Write-Log "GÃ©nÃ©ration du plan hebdomadaire rÃ©ussie" -Level "SUCCESS"
            Write-Log "Plan gÃ©nÃ©rÃ© : $planPath" -Level "INFO"
        } else {
            Write-Log "Ã‰chec de la gÃ©nÃ©ration du plan hebdomadaire" -Level "ERROR"
        }
        
        $planResults += @{
            RoadmapPath = $roadmapPath
            PlanPath = $planPath
            Result = $planResult
        }
    }
    
    # Ã‰tape 4: ExÃ©cution du workflow de gestion de roadmap
    Write-Log "Ã‰tape 4: ExÃ©cution du workflow de gestion de roadmap" -Level "INFO"
    
    $workflowResults = @()
    
    foreach ($roadmapPath in $RoadmapPaths) {
        Write-Log "ExÃ©cution du workflow de gestion de roadmap pour : $roadmapPath" -Level "INFO"
        $workflowResult = & $integratedManagerPath -Workflow "RoadmapManagement" -RoadmapPath $roadmapPath -ConfigPath $ConfigPath
        
        if ($workflowResult) {
            Write-Log "ExÃ©cution du workflow de gestion de roadmap rÃ©ussie" -Level "SUCCESS"
        } else {
            Write-Log "Ã‰chec de l'exÃ©cution du workflow de gestion de roadmap" -Level "ERROR"
        }
        
        $workflowResults += @{
            RoadmapPath = $roadmapPath
            Result = $workflowResult
        }
    }
    
    # Journaliser la fin du workflow
    Write-Log "Fin du workflow hebdomadaire" -Level "SUCCESS"
} catch {
    # Journaliser l'erreur
    Write-Log "Erreur lors de l'exÃ©cution du workflow hebdomadaire : $_" -Level "ERROR"
    Write-Log "Trace de la pile : $($_.ScriptStackTrace)" -Level "ERROR"
    exit 1
}

# Retourner un rÃ©sultat
return @{
    RoadmapPaths = $RoadmapPaths
    OutputPath = $OutputPath
    LogFile = $logFile
    SyncResults = $syncResults
    ReportResults = $reportResults
    PlanResults = $planResults
    WorkflowResults = $workflowResults
    Success = $true
}
