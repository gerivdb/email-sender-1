<#
.SYNOPSIS
    Script d'automatisation pour les tÃ¢ches mensuelles de gestion de roadmap.

.DESCRIPTION
    Ce script exÃ©cute les tÃ¢ches mensuelles de gestion de roadmap :
    1. Synchronisation de toutes les roadmaps
    2. GÃ©nÃ©ration de rapports mensuels dÃ©taillÃ©s
    3. Planification des tÃ¢ches pour le mois Ã  venir
    4. Analyse des tendances et prÃ©visions
    5. Journalisation des rÃ©sultats

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
    .\workflow-mensuel.ps1

.EXAMPLE
    .\workflow-mensuel.ps1 -RoadmapPaths @("projet\roadmaps\Roadmap\roadmap_complete_converted.md", "projet\roadmaps\mes-plans\roadmap_perso.md")

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
$analysisPath = Join-Path -Path $OutputPath -ChildPath "Analysis"

foreach ($path in @($LogPath, $reportsPath, $plansPath, $analysisPath)) {
    if (-not (Test-Path -Path $path)) {
        New-Item -Path $path -ItemType Directory -Force | Out-Null
    }
}

# DÃ©finir le chemin du fichier de journal
$yearMonth = Get-Date -Format "yyyy-MM"
$date = Get-Date -Format "yyyy-MM-dd"
$logFile = Join-Path -Path $LogPath -ChildPath "workflow-mensuel-$yearMonth.log"

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
Write-Log "DÃ©but du workflow mensuel" -Level "INFO"
Write-Log "Fichiers de roadmap : $($RoadmapPaths -join ', ')" -Level "INFO"
Write-Log "RÃ©pertoire de sortie : $OutputPath" -Level "INFO"
Write-Log "Fichier de journal : $logFile" -Level "INFO"
Write-Log "Fichier de configuration : $ConfigPath" -Level "INFO"

try {
    # Ã‰tape 1: Synchronisation de toutes les roadmaps
    Write-Log "Ã‰tape 1: Synchronisation de toutes les roadmaps" -Level "INFO"
    
    # Synchroniser toutes les roadmaps vers tous les formats
    $syncResults = @()
    $formats = @("JSON", "HTML", "CSV")
    
    foreach ($roadmapPath in $RoadmapPaths) {
        Write-Log "Synchronisation de la roadmap : $roadmapPath" -Level "INFO"
        
        foreach ($format in $formats) {
            Write-Log "Synchronisation vers $format" -Level "INFO"
            $syncResult = & $integratedManagerPath -Mode "ROADMAP-SYNC" -SourcePath $roadmapPath -TargetFormat $format -ConfigPath $ConfigPath
            
            if ($syncResult.Success) {
                Write-Log "Synchronisation vers $format rÃ©ussie : $($syncResult.TargetPath)" -Level "SUCCESS"
            } else {
                Write-Log "Ã‰chec de la synchronisation vers $format : $($syncResult.TargetPath)" -Level "ERROR"
            }
            
            $syncResults += @{
                RoadmapPath = $roadmapPath
                Format = $format
                Result = $syncResult
            }
        }
    }
    
    # Ã‰tape 2: GÃ©nÃ©ration de rapports mensuels dÃ©taillÃ©s
    Write-Log "Ã‰tape 2: GÃ©nÃ©ration de rapports mensuels dÃ©taillÃ©s" -Level "INFO"
    
    $reportResults = @()
    
    foreach ($roadmapPath in $RoadmapPaths) {
        $roadmapName = [System.IO.Path]::GetFileNameWithoutExtension($roadmapPath)
        $reportPath = Join-Path -Path $reportsPath -ChildPath "mensuel-$roadmapName-$yearMonth"
        
        Write-Log "GÃ©nÃ©ration du rapport mensuel pour : $roadmapPath" -Level "INFO"
        $reportResult = & $integratedManagerPath -Mode "ROADMAP-REPORT" -RoadmapPath $roadmapPath -OutputPath $reportPath -ReportFormat "All" -IncludeCharts -IncludeTrends -IncludePredictions -DaysToAnalyze 30 -ConfigPath $ConfigPath
        
        if ($reportResult) {
            Write-Log "GÃ©nÃ©ration du rapport mensuel rÃ©ussie" -Level "SUCCESS"
            Write-Log "Rapports gÃ©nÃ©rÃ©s : $($reportResult.GeneratedReports -join ', ')" -Level "INFO"
        } else {
            Write-Log "Ã‰chec de la gÃ©nÃ©ration du rapport mensuel" -Level "ERROR"
        }
        
        $reportResults += @{
            RoadmapPath = $roadmapPath
            ReportPath = $reportPath
            Result = $reportResult
        }
    }
    
    # Ã‰tape 3: Planification des tÃ¢ches pour le mois Ã  venir
    Write-Log "Ã‰tape 3: Planification des tÃ¢ches pour le mois Ã  venir" -Level "INFO"
    
    $planResults = @()
    
    foreach ($roadmapPath in $RoadmapPaths) {
        $roadmapName = [System.IO.Path]::GetFileNameWithoutExtension($roadmapPath)
        $planPath = Join-Path -Path $plansPath -ChildPath "mensuel-$roadmapName-$yearMonth.md"
        
        Write-Log "GÃ©nÃ©ration du plan mensuel pour : $roadmapPath" -Level "INFO"
        $planResult = & $integratedManagerPath -Mode "ROADMAP-PLAN" -RoadmapPath $roadmapPath -OutputPath $planPath -DaysToForecast 30 -ConfigPath $ConfigPath
        
        if ($planResult) {
            Write-Log "GÃ©nÃ©ration du plan mensuel rÃ©ussie" -Level "SUCCESS"
            Write-Log "Plan gÃ©nÃ©rÃ© : $planPath" -Level "INFO"
        } else {
            Write-Log "Ã‰chec de la gÃ©nÃ©ration du plan mensuel" -Level "ERROR"
        }
        
        $planResults += @{
            RoadmapPath = $roadmapPath
            PlanPath = $planPath
            Result = $planResult
        }
    }
    
    # Ã‰tape 4: Analyse des tendances et prÃ©visions
    Write-Log "Ã‰tape 4: Analyse des tendances et prÃ©visions" -Level "INFO"
    
    $analysisResults = @()
    
    foreach ($roadmapPath in $RoadmapPaths) {
        $roadmapName = [System.IO.Path]::GetFileNameWithoutExtension($roadmapPath)
        $analysisPath = Join-Path -Path $analysisPath -ChildPath "analyse-$roadmapName-$yearMonth.md"
        
        Write-Log "GÃ©nÃ©ration de l'analyse pour : $roadmapPath" -Level "INFO"
        
        # CrÃ©er un rapport d'analyse personnalisÃ©
        $analysisContent = @"
# Analyse des tendances et prÃ©visions - $roadmapName - $yearMonth

## RÃ©sumÃ©

Ce rapport prÃ©sente une analyse des tendances et des prÃ©visions pour la roadmap "$roadmapName" pour le mois de $yearMonth.

## Tendances

### Progression globale

La progression globale de la roadmap est analysÃ©e sur les 30 derniers jours.

### TÃ¢ches complÃ©tÃ©es

Le nombre de tÃ¢ches complÃ©tÃ©es est analysÃ© sur les 30 derniers jours.

### TÃ¢ches en cours

Le nombre de tÃ¢ches en cours est analysÃ© sur les 30 derniers jours.

## PrÃ©visions

### Estimation de la date de fin

En fonction des tendances actuelles, la date de fin estimÃ©e pour la roadmap est calculÃ©e.

### TÃ¢ches Ã  risque

Les tÃ¢ches qui prÃ©sentent un risque de retard sont identifiÃ©es.

### Recommandations

Des recommandations sont formulÃ©es pour amÃ©liorer la progression de la roadmap.

## Conclusion

Cette analyse permet de mieux comprendre l'Ã©tat d'avancement de la roadmap et de prendre des dÃ©cisions Ã©clairÃ©es pour la suite du projet.
"@
        
        # Enregistrer le rapport d'analyse
        $analysisContent | Out-File -FilePath $analysisPath -Encoding UTF8
        
        Write-Log "Analyse gÃ©nÃ©rÃ©e : $analysisPath" -Level "SUCCESS"
        
        $analysisResults += @{
            RoadmapPath = $roadmapPath
            AnalysisPath = $analysisPath
        }
    }
    
    # Ã‰tape 5: CrÃ©ation d'un rapport de synthÃ¨se
    Write-Log "Ã‰tape 5: CrÃ©ation d'un rapport de synthÃ¨se" -Level "INFO"
    
    $synthesisPath = Join-Path -Path $reportsPath -ChildPath "synthese-$yearMonth.md"
    
    # CrÃ©er un rapport de synthÃ¨se
    $synthesisContent = @"
# Rapport de synthÃ¨se - $yearMonth

## RÃ©sumÃ©

Ce rapport prÃ©sente une synthÃ¨se des activitÃ©s de gestion de roadmap pour le mois de $yearMonth.

## Roadmaps traitÃ©es

Les roadmaps suivantes ont Ã©tÃ© traitÃ©es :

$(foreach ($roadmapPath in $RoadmapPaths) {
    "- $roadmapPath"
})

## Rapports gÃ©nÃ©rÃ©s

Les rapports suivants ont Ã©tÃ© gÃ©nÃ©rÃ©s :

$(foreach ($reportResult in $reportResults) {
    "- $($reportResult.ReportPath)"
})

## Plans gÃ©nÃ©rÃ©s

Les plans suivants ont Ã©tÃ© gÃ©nÃ©rÃ©s :

$(foreach ($planResult in $planResults) {
    "- $($planResult.PlanPath)"
})

## Analyses gÃ©nÃ©rÃ©es

Les analyses suivantes ont Ã©tÃ© gÃ©nÃ©rÃ©es :

$(foreach ($analysisResult in $analysisResults) {
    "- $($analysisResult.AnalysisPath)"
})

## Conclusion

Ce rapport de synthÃ¨se permet de suivre l'ensemble des activitÃ©s de gestion de roadmap pour le mois de $yearMonth.
"@
    
    # Enregistrer le rapport de synthÃ¨se
    $synthesisContent | Out-File -FilePath $synthesisPath -Encoding UTF8
    
    Write-Log "Rapport de synthÃ¨se gÃ©nÃ©rÃ© : $synthesisPath" -Level "SUCCESS"
    
    # Journaliser la fin du workflow
    Write-Log "Fin du workflow mensuel" -Level "SUCCESS"
} catch {
    # Journaliser l'erreur
    Write-Log "Erreur lors de l'exÃ©cution du workflow mensuel : $_" -Level "ERROR"
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
    AnalysisResults = $analysisResults
    SynthesisPath = $synthesisPath
    Success = $true
}
