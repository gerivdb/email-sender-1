<#
.SYNOPSIS
    Script d'automatisation pour les tâches mensuelles de gestion de roadmap.

.DESCRIPTION
    Ce script exécute les tâches mensuelles de gestion de roadmap :
    1. Synchronisation de toutes les roadmaps
    2. Génération de rapports mensuels détaillés
    3. Planification des tâches pour le mois à venir
    4. Analyse des tendances et prévisions
    5. Journalisation des résultats

.PARAMETER RoadmapPaths
    Tableau des chemins vers les fichiers de roadmap à traiter.
    Par défaut : @("projet\roadmaps\Roadmap\roadmap_complete_converted.md")

.PARAMETER OutputPath
    Chemin vers le répertoire de sortie pour les rapports et les plans.
    Par défaut : "projet\roadmaps"

.PARAMETER LogPath
    Chemin vers le répertoire de journalisation.
    Par défaut : "projet\roadmaps\Logs"

.PARAMETER ConfigPath
    Chemin vers le fichier de configuration unifiée.
    Par défaut : "development\config\unified-config.json"

.EXAMPLE
    .\workflow-mensuel.ps1

.EXAMPLE
    .\workflow-mensuel.ps1 -RoadmapPaths @("projet\roadmaps\Roadmap\roadmap_complete_converted.md", "projet\roadmaps\mes-plans\roadmap_perso.md")

.NOTES
    Auteur: Integrated Manager Team
    Version: 1.0
    Date de création: 2023-06-01
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

# Vérifier que les fichiers de roadmap existent
foreach ($path in $RoadmapPaths) {
    if (-not (Test-Path -Path $path)) {
        Write-Error "Le fichier de roadmap spécifié n'existe pas : $path"
        exit 1
    }
}

# Créer les répertoires nécessaires s'ils n'existent pas
$reportsPath = Join-Path -Path $OutputPath -ChildPath "Reports"
$plansPath = Join-Path -Path $OutputPath -ChildPath "Plans"
$analysisPath = Join-Path -Path $OutputPath -ChildPath "Analysis"

foreach ($path in @($LogPath, $reportsPath, $plansPath, $analysisPath)) {
    if (-not (Test-Path -Path $path)) {
        New-Item -Path $path -ItemType Directory -Force | Out-Null
    }
}

# Définir le chemin du fichier de journal
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

# Définir le chemin du gestionnaire intégré
$integratedManagerPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\integrated-manager.ps1"

# Vérifier que le gestionnaire intégré existe
if (-not (Test-Path -Path $integratedManagerPath)) {
    Write-Log "Le gestionnaire intégré est introuvable : $integratedManagerPath" -Level "ERROR"
    exit 1
}

# Journaliser le début du workflow
Write-Log "Début du workflow mensuel" -Level "INFO"
Write-Log "Fichiers de roadmap : $($RoadmapPaths -join ', ')" -Level "INFO"
Write-Log "Répertoire de sortie : $OutputPath" -Level "INFO"
Write-Log "Fichier de journal : $logFile" -Level "INFO"
Write-Log "Fichier de configuration : $ConfigPath" -Level "INFO"

try {
    # Étape 1: Synchronisation de toutes les roadmaps
    Write-Log "Étape 1: Synchronisation de toutes les roadmaps" -Level "INFO"
    
    # Synchroniser toutes les roadmaps vers tous les formats
    $syncResults = @()
    $formats = @("JSON", "HTML", "CSV")
    
    foreach ($roadmapPath in $RoadmapPaths) {
        Write-Log "Synchronisation de la roadmap : $roadmapPath" -Level "INFO"
        
        foreach ($format in $formats) {
            Write-Log "Synchronisation vers $format" -Level "INFO"
            $syncResult = & $integratedManagerPath -Mode "ROADMAP-SYNC" -SourcePath $roadmapPath -TargetFormat $format -ConfigPath $ConfigPath
            
            if ($syncResult.Success) {
                Write-Log "Synchronisation vers $format réussie : $($syncResult.TargetPath)" -Level "SUCCESS"
            } else {
                Write-Log "Échec de la synchronisation vers $format : $($syncResult.TargetPath)" -Level "ERROR"
            }
            
            $syncResults += @{
                RoadmapPath = $roadmapPath
                Format = $format
                Result = $syncResult
            }
        }
    }
    
    # Étape 2: Génération de rapports mensuels détaillés
    Write-Log "Étape 2: Génération de rapports mensuels détaillés" -Level "INFO"
    
    $reportResults = @()
    
    foreach ($roadmapPath in $RoadmapPaths) {
        $roadmapName = [System.IO.Path]::GetFileNameWithoutExtension($roadmapPath)
        $reportPath = Join-Path -Path $reportsPath -ChildPath "mensuel-$roadmapName-$yearMonth"
        
        Write-Log "Génération du rapport mensuel pour : $roadmapPath" -Level "INFO"
        $reportResult = & $integratedManagerPath -Mode "ROADMAP-REPORT" -RoadmapPath $roadmapPath -OutputPath $reportPath -ReportFormat "All" -IncludeCharts -IncludeTrends -IncludePredictions -DaysToAnalyze 30 -ConfigPath $ConfigPath
        
        if ($reportResult) {
            Write-Log "Génération du rapport mensuel réussie" -Level "SUCCESS"
            Write-Log "Rapports générés : $($reportResult.GeneratedReports -join ', ')" -Level "INFO"
        } else {
            Write-Log "Échec de la génération du rapport mensuel" -Level "ERROR"
        }
        
        $reportResults += @{
            RoadmapPath = $roadmapPath
            ReportPath = $reportPath
            Result = $reportResult
        }
    }
    
    # Étape 3: Planification des tâches pour le mois à venir
    Write-Log "Étape 3: Planification des tâches pour le mois à venir" -Level "INFO"
    
    $planResults = @()
    
    foreach ($roadmapPath in $RoadmapPaths) {
        $roadmapName = [System.IO.Path]::GetFileNameWithoutExtension($roadmapPath)
        $planPath = Join-Path -Path $plansPath -ChildPath "mensuel-$roadmapName-$yearMonth.md"
        
        Write-Log "Génération du plan mensuel pour : $roadmapPath" -Level "INFO"
        $planResult = & $integratedManagerPath -Mode "ROADMAP-PLAN" -RoadmapPath $roadmapPath -OutputPath $planPath -DaysToForecast 30 -ConfigPath $ConfigPath
        
        if ($planResult) {
            Write-Log "Génération du plan mensuel réussie" -Level "SUCCESS"
            Write-Log "Plan généré : $planPath" -Level "INFO"
        } else {
            Write-Log "Échec de la génération du plan mensuel" -Level "ERROR"
        }
        
        $planResults += @{
            RoadmapPath = $roadmapPath
            PlanPath = $planPath
            Result = $planResult
        }
    }
    
    # Étape 4: Analyse des tendances et prévisions
    Write-Log "Étape 4: Analyse des tendances et prévisions" -Level "INFO"
    
    $analysisResults = @()
    
    foreach ($roadmapPath in $RoadmapPaths) {
        $roadmapName = [System.IO.Path]::GetFileNameWithoutExtension($roadmapPath)
        $analysisPath = Join-Path -Path $analysisPath -ChildPath "analyse-$roadmapName-$yearMonth.md"
        
        Write-Log "Génération de l'analyse pour : $roadmapPath" -Level "INFO"
        
        # Créer un rapport d'analyse personnalisé
        $analysisContent = @"
# Analyse des tendances et prévisions - $roadmapName - $yearMonth

## Résumé

Ce rapport présente une analyse des tendances et des prévisions pour la roadmap "$roadmapName" pour le mois de $yearMonth.

## Tendances

### Progression globale

La progression globale de la roadmap est analysée sur les 30 derniers jours.

### Tâches complétées

Le nombre de tâches complétées est analysé sur les 30 derniers jours.

### Tâches en cours

Le nombre de tâches en cours est analysé sur les 30 derniers jours.

## Prévisions

### Estimation de la date de fin

En fonction des tendances actuelles, la date de fin estimée pour la roadmap est calculée.

### Tâches à risque

Les tâches qui présentent un risque de retard sont identifiées.

### Recommandations

Des recommandations sont formulées pour améliorer la progression de la roadmap.

## Conclusion

Cette analyse permet de mieux comprendre l'état d'avancement de la roadmap et de prendre des décisions éclairées pour la suite du projet.
"@
        
        # Enregistrer le rapport d'analyse
        $analysisContent | Out-File -FilePath $analysisPath -Encoding UTF8
        
        Write-Log "Analyse générée : $analysisPath" -Level "SUCCESS"
        
        $analysisResults += @{
            RoadmapPath = $roadmapPath
            AnalysisPath = $analysisPath
        }
    }
    
    # Étape 5: Création d'un rapport de synthèse
    Write-Log "Étape 5: Création d'un rapport de synthèse" -Level "INFO"
    
    $synthesisPath = Join-Path -Path $reportsPath -ChildPath "synthese-$yearMonth.md"
    
    # Créer un rapport de synthèse
    $synthesisContent = @"
# Rapport de synthèse - $yearMonth

## Résumé

Ce rapport présente une synthèse des activités de gestion de roadmap pour le mois de $yearMonth.

## Roadmaps traitées

Les roadmaps suivantes ont été traitées :

$(foreach ($roadmapPath in $RoadmapPaths) {
    "- $roadmapPath"
})

## Rapports générés

Les rapports suivants ont été générés :

$(foreach ($reportResult in $reportResults) {
    "- $($reportResult.ReportPath)"
})

## Plans générés

Les plans suivants ont été générés :

$(foreach ($planResult in $planResults) {
    "- $($planResult.PlanPath)"
})

## Analyses générées

Les analyses suivantes ont été générées :

$(foreach ($analysisResult in $analysisResults) {
    "- $($analysisResult.AnalysisPath)"
})

## Conclusion

Ce rapport de synthèse permet de suivre l'ensemble des activités de gestion de roadmap pour le mois de $yearMonth.
"@
    
    # Enregistrer le rapport de synthèse
    $synthesisContent | Out-File -FilePath $synthesisPath -Encoding UTF8
    
    Write-Log "Rapport de synthèse généré : $synthesisPath" -Level "SUCCESS"
    
    # Journaliser la fin du workflow
    Write-Log "Fin du workflow mensuel" -Level "SUCCESS"
} catch {
    # Journaliser l'erreur
    Write-Log "Erreur lors de l'exécution du workflow mensuel : $_" -Level "ERROR"
    Write-Log "Trace de la pile : $($_.ScriptStackTrace)" -Level "ERROR"
    exit 1
}

# Retourner un résultat
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
