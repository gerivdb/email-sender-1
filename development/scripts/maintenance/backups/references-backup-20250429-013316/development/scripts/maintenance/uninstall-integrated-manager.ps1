<#
.SYNOPSIS
    Script de dÃ©sinstallation du gestionnaire intÃ©grÃ©.

.DESCRIPTION
    Ce script permet de dÃ©sinstaller le gestionnaire intÃ©grÃ© et ses composants.
    Il supprime les tÃ¢ches planifiÃ©es et peut optionnellement supprimer les fichiers et rÃ©pertoires crÃ©Ã©s.

.PARAMETER RemoveFiles
    Indique si les fichiers et rÃ©pertoires crÃ©Ã©s doivent Ãªtre supprimÃ©s.
    Par dÃ©faut : $false

.PARAMETER Force
    Indique si les suppressions doivent Ãªtre effectuÃ©es sans confirmation.
    Par dÃ©faut : $false

.PARAMETER Verbose
    Affiche des informations dÃ©taillÃ©es sur l'exÃ©cution.

.EXAMPLE
    .\uninstall-integrated-manager.ps1

.EXAMPLE
    .\uninstall-integrated-manager.ps1 -RemoveFiles -Force

.NOTES
    Auteur: Integrated Manager Team
    Version: 1.0
    Date de crÃ©ation: 2023-06-01
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [switch]$RemoveFiles,

    [Parameter(Mandatory = $false)]
    [switch]$Force
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

# Fonction pour afficher les rÃ©sultats
function Write-Result {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Component,
        
        [Parameter(Mandatory = $true)]
        [bool]$Success,
        
        [Parameter(Mandatory = $false)]
        [string]$Details = ""
    )
    
    $status = if ($Success) { "OK" } else { "Ã‰CHEC" }
    $color = if ($Success) { "Green" } else { "Red" }
    
    Write-Host "[$status] " -ForegroundColor $color -NoNewline
    Write-Host "$Component" -NoNewline
    
    if ($Details) {
        Write-Host " - $Details"
    } else {
        Write-Host ""
    }
}

# Afficher l'en-tÃªte
Write-Host "DÃ©sinstallation du gestionnaire intÃ©grÃ©" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Supprimer les tÃ¢ches planifiÃ©es
$scheduledTasksSuccess = $true
$scheduledTasksDetails = ""

try {
    $tasks = Get-ScheduledTask -TaskName "roadmap-manager-*" -ErrorAction SilentlyContinue
    
    if ($null -ne $tasks -and $tasks.Count -gt 0) {
        if ($PSCmdlet.ShouldProcess("TÃ¢ches planifiÃ©es", "Supprimer")) {
            Write-Host "Suppression des tÃ¢ches planifiÃ©es..." -ForegroundColor Yellow
            
            foreach ($task in $tasks) {
                try {
                    Unregister-ScheduledTask -TaskName $task.TaskName -Confirm:(-not $Force)
                    Write-Host "  TÃ¢che supprimÃ©e : $($task.TaskName)" -ForegroundColor Gray
                } catch {
                    Write-Warning "Erreur lors de la suppression de la tÃ¢che $($task.TaskName) : $_"
                    $scheduledTasksSuccess = $false
                }
            }
            
            $remainingTasks = Get-ScheduledTask -TaskName "roadmap-manager-*" -ErrorAction SilentlyContinue
            $scheduledTasksSuccess = $null -eq $remainingTasks -or $remainingTasks.Count -eq 0
            $scheduledTasksDetails = if ($scheduledTasksSuccess) { "$($tasks.Count) tÃ¢ches planifiÃ©es supprimÃ©es" } else { "Certaines tÃ¢ches n'ont pas Ã©tÃ© supprimÃ©es" }
        } else {
            $scheduledTasksDetails = "Suppression simulÃ©e"
        }
    } else {
        $scheduledTasksDetails = "Aucune tÃ¢che planifiÃ©e trouvÃ©e"
    }
} catch {
    $scheduledTasksSuccess = $false
    $scheduledTasksDetails = "Erreur lors de la suppression : $_"
}

Write-Result -Component "TÃ¢ches planifiÃ©es" -Success $scheduledTasksSuccess -Details $scheduledTasksDetails

# Supprimer les fichiers et rÃ©pertoires si demandÃ©
$filesSuccess = $true
$filesDetails = ""

if ($RemoveFiles) {
    # Liste des fichiers et rÃ©pertoires Ã  supprimer
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
        "development\\scripts\\mode-manager\tests\Test-CompleteIntegration.ps1",
        "development\\scripts\\mode-manager\tests\Test-RoadmapModes.ps1"
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
                    Write-Host "  Fichier supprimÃ© : $file" -ForegroundColor Gray
                }
            } catch {
                Write-Warning "Erreur lors de la suppression du fichier $file : $_"
                $filesSuccess = $false
            }
        }
    }
    
    # Supprimer les rÃ©pertoires
    foreach ($directory in $directoriesToRemove) {
        $directoryPath = Join-Path -Path $projectRoot -ChildPath $directory
        
        if (Test-Path -Path $directoryPath -PathType Container) {
            try {
                if ($PSCmdlet.ShouldProcess($directoryPath, "Supprimer le rÃ©pertoire")) {
                    Remove-Item -Path $directoryPath -Recurse -Force
                    Write-Host "  RÃ©pertoire supprimÃ© : $directory" -ForegroundColor Gray
                }
            } catch {
                Write-Warning "Erreur lors de la suppression du rÃ©pertoire $directory : $_"
                $filesSuccess = $false
            }
        }
    }
    
    $filesDetails = "Fichiers et rÃ©pertoires supprimÃ©s"
} else {
    $filesDetails = "Suppression ignorÃ©e (utilisez -RemoveFiles pour supprimer)"
}

Write-Result -Component "Fichiers et rÃ©pertoires" -Success $filesSuccess -Details $filesDetails

# Afficher un message de fin
Write-Host ""
Write-Host "DÃ©sinstallation terminÃ©e." -ForegroundColor Cyan

if (-not $RemoveFiles) {
    Write-Host "Les fichiers et rÃ©pertoires n'ont pas Ã©tÃ© supprimÃ©s. Utilisez -RemoveFiles pour les supprimer." -ForegroundColor Yellow
}

# Retourner un rÃ©sultat
return @{
    Success = $scheduledTasksSuccess -and $filesSuccess
    ScheduledTasks = @{ Success = $scheduledTasksSuccess; Details = $scheduledTasksDetails }
    Files = @{ Success = $filesSuccess; Details = $filesDetails }
}


