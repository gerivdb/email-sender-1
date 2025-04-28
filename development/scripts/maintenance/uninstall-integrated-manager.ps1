<#
.SYNOPSIS
    Script de désinstallation du gestionnaire intégré.

.DESCRIPTION
    Ce script permet de désinstaller le gestionnaire intégré et ses composants.
    Il supprime les tâches planifiées et peut optionnellement supprimer les fichiers et répertoires créés.

.PARAMETER RemoveFiles
    Indique si les fichiers et répertoires créés doivent être supprimés.
    Par défaut : $false

.PARAMETER Force
    Indique si les suppressions doivent être effectuées sans confirmation.
    Par défaut : $false

.PARAMETER Verbose
    Affiche des informations détaillées sur l'exécution.

.EXAMPLE
    .\uninstall-integrated-manager.ps1

.EXAMPLE
    .\uninstall-integrated-manager.ps1 -RemoveFiles -Force

.NOTES
    Auteur: Integrated Manager Team
    Version: 1.0
    Date de création: 2023-06-01
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [switch]$RemoveFiles,

    [Parameter(Mandatory = $false)]
    [switch]$Force
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

# Fonction pour afficher les résultats
function Write-Result {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Component,
        
        [Parameter(Mandatory = $true)]
        [bool]$Success,
        
        [Parameter(Mandatory = $false)]
        [string]$Details = ""
    )
    
    $status = if ($Success) { "OK" } else { "ÉCHEC" }
    $color = if ($Success) { "Green" } else { "Red" }
    
    Write-Host "[$status] " -ForegroundColor $color -NoNewline
    Write-Host "$Component" -NoNewline
    
    if ($Details) {
        Write-Host " - $Details"
    } else {
        Write-Host ""
    }
}

# Afficher l'en-tête
Write-Host "Désinstallation du gestionnaire intégré" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Supprimer les tâches planifiées
$scheduledTasksSuccess = $true
$scheduledTasksDetails = ""

try {
    $tasks = Get-ScheduledTask -TaskName "RoadmapManager-*" -ErrorAction SilentlyContinue
    
    if ($null -ne $tasks -and $tasks.Count -gt 0) {
        if ($PSCmdlet.ShouldProcess("Tâches planifiées", "Supprimer")) {
            Write-Host "Suppression des tâches planifiées..." -ForegroundColor Yellow
            
            foreach ($task in $tasks) {
                try {
                    Unregister-ScheduledTask -TaskName $task.TaskName -Confirm:(-not $Force)
                    Write-Host "  Tâche supprimée : $($task.TaskName)" -ForegroundColor Gray
                } catch {
                    Write-Warning "Erreur lors de la suppression de la tâche $($task.TaskName) : $_"
                    $scheduledTasksSuccess = $false
                }
            }
            
            $remainingTasks = Get-ScheduledTask -TaskName "RoadmapManager-*" -ErrorAction SilentlyContinue
            $scheduledTasksSuccess = $null -eq $remainingTasks -or $remainingTasks.Count -eq 0
            $scheduledTasksDetails = if ($scheduledTasksSuccess) { "$($tasks.Count) tâches planifiées supprimées" } else { "Certaines tâches n'ont pas été supprimées" }
        } else {
            $scheduledTasksDetails = "Suppression simulée"
        }
    } else {
        $scheduledTasksDetails = "Aucune tâche planifiée trouvée"
    }
} catch {
    $scheduledTasksSuccess = $false
    $scheduledTasksDetails = "Erreur lors de la suppression : $_"
}

Write-Result -Component "Tâches planifiées" -Success $scheduledTasksSuccess -Details $scheduledTasksDetails

# Supprimer les fichiers et répertoires si demandé
$filesSuccess = $true
$filesDetails = ""

if ($RemoveFiles) {
    # Liste des fichiers et répertoires à supprimer
    $filesToRemove = @(
        "development\scripts\integrated-manager.ps1",
        "development\scripts\maintenance\modes\roadmap-sync-mode.ps1",
        "development\scripts\maintenance\modes\roadmap-report-mode.ps1",
        "development\scripts\maintenance\modes\roadmap-plan-mode.ps1",
        "development\scripts\workflows\workflow-quotidien.ps1",
        "development\scripts\workflows\workflow-hebdomadaire.ps1",
        "development\scripts\workflows\workflow-mensuel.ps1",
        "development\scripts\workflows\install-scheduled-tasks.ps1",
        "development\docs\guides\user-guides\integrated-manager-guide.md",
        "development\docs\guides\user-guides\integrated-manager-quickstart.md",
        "development\docs\guides\reference\integrated-manager-parameters.md",
        "development\docs\guides\examples\roadmap-modes-examples.md",
        "development\docs\guides\best-practices\roadmap-management.md",
        "development\docs\guides\automation\roadmap-workflows.md",
        "development\scripts\manager\tests\Test-CompleteIntegration.ps1",
        "development\scripts\manager\tests\Test-RoadmapModes.ps1"
    )
    
    $directoriesToRemove = @(
        "projet\roadmaps\Reports",
        "projet\roadmaps\Plans",
        "projet\roadmaps\Logs"
    )
    
    # Supprimer les fichiers
    foreach ($file in $filesToRemove) {
        $filePath = Join-Path -Path $projectRoot -ChildPath $file
        
        if (Test-Path -Path $filePath) {
            try {
                if ($PSCmdlet.ShouldProcess($filePath, "Supprimer le fichier")) {
                    Remove-Item -Path $filePath -Force
                    Write-Host "  Fichier supprimé : $file" -ForegroundColor Gray
                }
            } catch {
                Write-Warning "Erreur lors de la suppression du fichier $file : $_"
                $filesSuccess = $false
            }
        }
    }
    
    # Supprimer les répertoires
    foreach ($directory in $directoriesToRemove) {
        $directoryPath = Join-Path -Path $projectRoot -ChildPath $directory
        
        if (Test-Path -Path $directoryPath -PathType Container) {
            try {
                if ($PSCmdlet.ShouldProcess($directoryPath, "Supprimer le répertoire")) {
                    Remove-Item -Path $directoryPath -Recurse -Force
                    Write-Host "  Répertoire supprimé : $directory" -ForegroundColor Gray
                }
            } catch {
                Write-Warning "Erreur lors de la suppression du répertoire $directory : $_"
                $filesSuccess = $false
            }
        }
    }
    
    $filesDetails = "Fichiers et répertoires supprimés"
} else {
    $filesDetails = "Suppression ignorée (utilisez -RemoveFiles pour supprimer)"
}

Write-Result -Component "Fichiers et répertoires" -Success $filesSuccess -Details $filesDetails

# Afficher un message de fin
Write-Host ""
Write-Host "Désinstallation terminée." -ForegroundColor Cyan

if (-not $RemoveFiles) {
    Write-Host "Les fichiers et répertoires n'ont pas été supprimés. Utilisez -RemoveFiles pour les supprimer." -ForegroundColor Yellow
}

# Retourner un résultat
return @{
    Success = $scheduledTasksSuccess -and $filesSuccess
    ScheduledTasks = @{ Success = $scheduledTasksSuccess; Details = $scheduledTasksDetails }
    Files = @{ Success = $filesSuccess; Details = $filesDetails }
}
