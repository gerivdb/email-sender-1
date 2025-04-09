# Script pour intégrer Augment avec la mise à jour automatique de la roadmap
# Ce script permet à Augment de déclarer des tâches terminées et de mettre à jour la roadmap

# Importer le module de mise à jour de la roadmap
$updaterPath = Join-Path -Path $PSScriptRoot -ChildPath "RoadmapUpdater.ps1"
if (Test-Path -Path $updaterPath) {
    . $updaterPath
}
else {
    Write-Error "Le module de mise à jour de la roadmap est introuvable: $updaterPath"
    exit 1
}

# Configuration
$AugmentConfig = @{
    # Fichier de log pour les actions d'Augment
    AugmentLogPath = Join-Path -Path $PSScriptRoot -ChildPath "augment_actions.log"

    # Fichier de la roadmap
    RoadmapPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\roadmap_perso.md"
}

# Fonction pour initialiser l'intégration
function Initialize-AugmentRoadmapIntegration {
    # Initialiser le module de mise à jour de la roadmap
    Initialize-RoadmapUpdater -RoadmapPath $AugmentConfig.RoadmapPath

    # Créer le fichier de log s'il n'existe pas
    if (-not (Test-Path -Path $AugmentConfig.AugmentLogPath)) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $initialLog = "[$timestamp] Initialisation de l'intégration Augment-Roadmap`n"
        $initialLog | Set-Content -Path $AugmentConfig.AugmentLogPath -Encoding UTF8
    }

    return $AugmentConfig
}

# Fonction pour qu'Augment déclare une tâche terminée
function Complete-AugmentTask {
    param (
        [Parameter(Mandatory = $true)]
        [string]$PhaseTitle,

        [Parameter(Mandatory = $true)]
        [string]$TaskTitle,

        [Parameter(Mandatory = $false)]
        [string]$Comment = ""
    )

    # Journaliser l'action
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] Augment a déclaré la tâche '$TaskTitle' terminée dans la phase '$PhaseTitle'"

    if (-not [string]::IsNullOrEmpty($Comment)) {
        $logEntry += "`nCommentaire: $Comment"
    }

    $logEntry += "`n"
    Add-Content -Path $AugmentConfig.AugmentLogPath -Value $logEntry

    # Marquer la tâche comme terminée
    $result = Set-TaskCompleted -PhaseTitle $PhaseTitle -TaskTitle $TaskTitle -Force

    # Mettre à jour la roadmap
    $updaterPath = Join-Path -Path $PSScriptRoot -ChildPath "RoadmapUpdater.ps1"
    if (Test-Path -Path $updaterPath) {
        . $updaterPath
        $null = Update-Roadmap
    }

    return $result
}

# Fonction pour qu'Augment déclare une phase terminée
function Complete-AugmentPhase {
    param (
        [Parameter(Mandatory = $true)]
        [string]$PhaseTitle,

        [Parameter(Mandatory = $false)]
        [string]$Comment = ""
    )

    # Journaliser l'action
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] Augment a déclaré la phase '$PhaseTitle' terminée"

    if (-not [string]::IsNullOrEmpty($Comment)) {
        $logEntry += "`nCommentaire: $Comment"
    }

    $logEntry += "`n"
    Add-Content -Path $AugmentConfig.AugmentLogPath -Value $logEntry

    # Marquer la phase comme terminée
    $result = Set-PhaseCompleted -PhaseTitle $PhaseTitle -Force

    # Mettre à jour la roadmap
    $updaterPath = Join-Path -Path $PSScriptRoot -ChildPath "RoadmapUpdater.ps1"
    if (Test-Path -Path $updaterPath) {
        . $updaterPath
        $null = Update-Roadmap
    }

    return $result
}

# Fonction pour qu'Augment déclare une sous-tâche terminée
function Complete-AugmentSubtask {
    param (
        [Parameter(Mandatory = $true)]
        [string]$PhaseTitle,

        [Parameter(Mandatory = $true)]
        [string]$TaskTitle,

        [Parameter(Mandatory = $true)]
        [string]$SubtaskTitle,

        [Parameter(Mandatory = $false)]
        [string]$Comment = ""
    )

    # Journaliser l'action
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] Augment a déclaré la sous-tâche '$SubtaskTitle' terminée dans la tâche '$TaskTitle' de la phase '$PhaseTitle'"

    if (-not [string]::IsNullOrEmpty($Comment)) {
        $logEntry += "`nCommentaire: $Comment"
    }

    $logEntry += "`n"
    Add-Content -Path $AugmentConfig.AugmentLogPath -Value $logEntry

    # Lire le contenu du fichier roadmap
    $content = Get-Content -Path $AugmentConfig.RoadmapPath -Raw

    # Marquer la sous-tâche comme terminée
    $subtaskPattern = "(?m)^    - \[ \] $([regex]::Escape($SubtaskTitle))"
    $subtaskReplacement = "    - [x] $SubtaskTitle"
    $newContent = [regex]::Replace($content, $subtaskPattern, $subtaskReplacement)

    if ($newContent -ne $content) {
        $newContent | Set-Content -Path $AugmentConfig.RoadmapPath -Encoding UTF8

        # Mettre à jour la roadmap pour propager les changements
        $updaterPath = Join-Path -Path $PSScriptRoot -ChildPath "RoadmapUpdater.ps1"
        if (Test-Path -Path $updaterPath) {
            . $updaterPath
            $null = Update-Roadmap
        }

        return $true
    }

    return $false
}

# Fonction pour analyser une déclaration d'Augment
function Invoke-AugmentDeclaration {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Declaration
    )

    # Initialiser l'intégration
    Initialize-AugmentRoadmapIntegration

    # Analyser la déclaration
    if ($Declaration -match "(?i)phase\s+(.+?)\s+terminée") {
        $phaseTitle = $Matches[1].Trim()
        return Complete-AugmentPhase -PhaseTitle $phaseTitle -Comment "Déclaration automatique par Augment"
    }
    elseif ($Declaration -match "(?i)tâche\s+(.+?)\s+dans\s+la\s+phase\s+(.+?)\s+terminée") {
        $taskTitle = $Matches[1].Trim()
        $phaseTitle = $Matches[2].Trim()
        return Complete-AugmentTask -PhaseTitle $phaseTitle -TaskTitle $taskTitle -Comment "Déclaration automatique par Augment"
    }
    elseif ($Declaration -match "(?i)sous-tâche\s+(.+?)\s+dans\s+la\s+tâche\s+(.+?)\s+de\s+la\s+phase\s+(.+?)\s+terminée") {
        $subtaskTitle = $Matches[1].Trim()
        $taskTitle = $Matches[2].Trim()
        $phaseTitle = $Matches[3].Trim()
        return Complete-AugmentSubtask -PhaseTitle $phaseTitle -TaskTitle $taskTitle -SubtaskTitle $subtaskTitle -Comment "Déclaration automatique par Augment"
    }
    else {
        Write-Warning "Déclaration non reconnue: $Declaration"
        return $false
    }
}

# Fonction pour mettre à jour la roadmap à partir d'un fichier de déclarations
function Update-RoadmapFromDeclarations {
    param (
        [Parameter(Mandatory = $true)]
        [string]$DeclarationsFile
    )

    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $DeclarationsFile)) {
        Write-Error "Le fichier de déclarations n'existe pas: $DeclarationsFile"
        return $false
    }

    # Lire les déclarations
    $declarations = Get-Content -Path $DeclarationsFile

    $results = @()

    # Traiter chaque déclaration
    foreach ($declaration in $declarations) {
        if (-not [string]::IsNullOrWhiteSpace($declaration)) {
            $result = Invoke-AugmentDeclaration -Declaration $declaration
            $results += [PSCustomObject]@{
                Declaration = $declaration
                Success = $result
            }
        }
    }

    return $results
}

# Exporter les fonctions
# Note: Export-ModuleMember est commenté car ce script n'est pas un module formel
# Export-ModuleMember -Function Initialize-AugmentRoadmapIntegration, Complete-AugmentTask, Complete-AugmentPhase, Complete-AugmentSubtask, Invoke-AugmentDeclaration, Update-RoadmapFromDeclarations
