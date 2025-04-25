<#
.SYNOPSIS
    Script pour vérifier si les tâches sélectionnées ont été implémentées à 100% et testées avec succès à 100% (Mode CHECK).

.DESCRIPTION
    Ce script permet de vérifier si les tâches sélectionnées ont été implémentées à 100% et testées
    avec succès à 100%. Si c'est le cas, il peut mettre à jour automatiquement le statut des tâches
    dans la roadmap en cochant les cases correspondantes. Il implémente le mode CHECK décrit dans
    la documentation des modes de fonctionnement.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap à vérifier et mettre à jour.

.PARAMETER TaskIdentifier
    Identifiant de la tâche à vérifier (par exemple, "1.2.1.3.2.3").
    Si non spécifié, l'utilisateur sera invité à le saisir.

.PARAMETER ImplementationPath
    Chemin vers le répertoire contenant l'implémentation.
    Si non spécifié, le script tentera de le déduire automatiquement.

.PARAMETER TestsPath
    Chemin vers le répertoire contenant les tests.
    Si non spécifié, le script tentera de le déduire automatiquement.

.PARAMETER UpdateRoadmap
    Indique si la roadmap doit être mise à jour automatiquement.
    Par défaut : $true.

.PARAMETER GenerateReport
    Indique si un rapport doit être généré.
    Par défaut : $true.

.EXAMPLE
    .\scripts\check-mode.ps1 -FilePath "Roadmap/roadmap_complete_converted.md" -TaskIdentifier "1.2.1.3.2.3"

.EXAMPLE
    .\scripts\check-mode.ps1 -FilePath "Roadmap/roadmap_complete_converted.md" -TaskIdentifier "1.2.1.3.2.3" -ImplementationPath "scripts/roadmap-parser/module/Functions/Public" -TestsPath "scripts/roadmap-parser/module/Tests"

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true)]
    [string]$FilePath,

    [Parameter(Mandatory = $false)]
    [string]$TaskIdentifier,

    [Parameter(Mandatory = $false)]
    [string]$ImplementationPath,

    [Parameter(Mandatory = $false)]
    [string]$TestsPath,

    [Parameter(Mandatory = $false)]
    [switch]$UpdateRoadmap = $true,

    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport = $true,

    [Parameter(Mandatory = $false, HelpMessage = "Chemin vers le document actif à vérifier et mettre à jour.")]
    [string]$ActiveDocumentPath,

    [Parameter(Mandatory = $false, HelpMessage = "Indique si les cases à cocher dans le document actif doivent être mises à jour.")]
    [switch]$CheckActiveDocument = $true
)

# Importer les fonctions nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path -Path $scriptPath -ChildPath "roadmap-parser\module\Functions\Public"
$invokeCheckPath = Join-Path -Path $modulePath -ChildPath "Invoke-RoadmapCheck.ps1"
$updateTaskPath = Join-Path -Path $modulePath -ChildPath "Update-RoadmapTaskStatus.ps1"

if (Test-Path -Path $invokeCheckPath) {
    . $invokeCheckPath
    Write-Host "Fonction Invoke-RoadmapCheck importée." -ForegroundColor Green
} else {
    throw "La fonction Invoke-RoadmapCheck est introuvable à l'emplacement : $invokeCheckPath"
}

if (Test-Path -Path $updateTaskPath) {
    . $updateTaskPath
    Write-Host "Fonction Update-RoadmapTaskStatus importée." -ForegroundColor Green
} else {
    throw "La fonction Update-RoadmapTaskStatus est introuvable à l'emplacement : $updateTaskPath"
}

# Vérifier que le fichier de roadmap existe
if (-not (Test-Path -Path $FilePath)) {
    throw "Le fichier de roadmap spécifié n'existe pas : $FilePath"
}

# Vérifier si le document actif existe
if ($CheckActiveDocument -and $ActiveDocumentPath) {
    if (-not (Test-Path -Path $ActiveDocumentPath)) {
        Write-Warning "Le document actif spécifié n'existe pas : $ActiveDocumentPath. La vérification du document actif sera désactivée."
        $CheckActiveDocument = $false
    }
}

# Appeler la fonction Invoke-RoadmapCheck
$result = Invoke-RoadmapCheck -FilePath $FilePath -TaskIdentifier $TaskIdentifier -ImplementationPath $ImplementationPath -TestsPath $TestsPath -UpdateRoadmap $UpdateRoadmap -GenerateReport $GenerateReport

# Vérifier et mettre à jour les cases à cocher dans le document actif si demandé
if ($CheckActiveDocument -and $ActiveDocumentPath) {
    Write-Host "`nVérification et mise à jour des cases à cocher dans le document actif : $ActiveDocumentPath" -ForegroundColor Cyan

    # Lire le contenu du document actif
    $activeDocumentContent = Get-Content -Path $ActiveDocumentPath -Encoding UTF8
    $tasksUpdated = 0

    # Pour chaque tâche vérifiée
    foreach ($task in $result.Tasks) {
        # Si la tâche est implémentée à 100% et testée avec succès à 100%
        if ($task.Implementation.ImplementationComplete -and $task.Tests.TestsComplete -and $task.Tests.TestsSuccessful) {
            # Rechercher la tâche dans le document actif
            $taskPattern = "- \[ \] \*\*$($task.Id)\*\*"
            $taskReplacement = "- [x] **$($task.Id)**"

            # Mettre à jour la case à cocher
            $newContent = $activeDocumentContent -replace $taskPattern, $taskReplacement

            # Si le contenu a changé, c'est que la tâche a été trouvée et mise à jour
            if ($newContent -ne $activeDocumentContent) {
                $activeDocumentContent = $newContent
                $tasksUpdated++
                Write-Host "  Tâche $($task.Id) - $($task.Title) : Case à cocher mise à jour" -ForegroundColor Green
            }
        }
    }

    # Si des tâches ont été mises à jour, enregistrer le document
    if ($tasksUpdated -gt 0) {
        if ($PSCmdlet.ShouldProcess($ActiveDocumentPath, "Mettre à jour les cases à cocher dans le document actif")) {
            $activeDocumentContent | Set-Content -Path $ActiveDocumentPath -Encoding UTF8
            Write-Host "  $tasksUpdated tâches ont été mises à jour dans le document actif." -ForegroundColor Green
        }
    } else {
        Write-Host "  Aucune tâche à mettre à jour dans le document actif." -ForegroundColor Yellow
    }
}

# Afficher un résumé des résultats
Write-Host "`nRésumé des résultats :" -ForegroundColor Cyan
Write-Host "  Tâche principale : $($result.TaskIdentifier)" -ForegroundColor Cyan
Write-Host "  Nombre total de tâches : $($result.TotalTasks)" -ForegroundColor Cyan
Write-Host "  Tâches implémentées à 100% : $($result.ImplementedTasks)" -ForegroundColor $(if ($result.ImplementedTasks -eq $result.TotalTasks) { "Green" } else { "Yellow" })
Write-Host "  Tâches testées à 100% : $($result.TestedTasks)" -ForegroundColor $(if ($result.TestedTasks -eq $result.TotalTasks) { "Green" } else { "Yellow" })
Write-Host "  Tâches mises à jour dans la roadmap : $($result.UpdatedTasks)" -ForegroundColor $(if ($result.UpdatedTasks -gt 0) { "Green" } else { "Gray" })
if ($CheckActiveDocument -and $ActiveDocumentPath) {
    Write-Host "  Tâches mises à jour dans le document actif : $tasksUpdated" -ForegroundColor $(if ($tasksUpdated -gt 0) { "Green" } else { "Gray" })
}

# Afficher les détails des tâches
Write-Host "`nDétails des tâches :" -ForegroundColor Cyan
foreach ($task in $result.Tasks) {
    $statusColor = if ($task.IsChecked -or $task.NeedsUpdate) { "Green" } else { "Yellow" }
    $statusText = if ($task.IsChecked) { "Terminée" } elseif ($task.NeedsUpdate) { "Mise à jour" } else { "En cours" }

    Write-Host "  Tâche $($task.Id) - $($task.Title)" -ForegroundColor $statusColor
    Write-Host "    État : $statusText" -ForegroundColor $statusColor
    Write-Host "    Implémentation : $(if ($task.Implementation.ImplementationComplete) { "Complète" } else { "Incomplète ($($task.Implementation.ImplementationPercentage)%)" })" -ForegroundColor $(if ($task.Implementation.ImplementationComplete) { "Green" } else { "Yellow" })
    Write-Host "    Tests : $(if ($task.Tests.TestsComplete) { "Complets" } else { "Incomplets" })" -ForegroundColor $(if ($task.Tests.TestsComplete) { "Green" } else { "Yellow" })
    Write-Host "    Résultats des tests : $(if ($task.Tests.TestsSuccessful) { "Réussis" } else { "Échoués" })" -ForegroundColor $(if ($task.Tests.TestsSuccessful) { "Green" } else { "Red" })
}

# Afficher le chemin du rapport si généré
if ($GenerateReport) {
    $reportPath = Join-Path -Path (Split-Path -Parent $FilePath) -ChildPath "check_report_$TaskIdentifier.md"
    if (Test-Path -Path $reportPath) {
        Write-Host "`nRapport généré : $reportPath" -ForegroundColor Green
    }
}

# Afficher un message de confirmation pour le document actif
if ($CheckActiveDocument -and $ActiveDocumentPath -and $tasksUpdated -gt 0) {
    Write-Host "`nLes cases à cocher dans le document actif ont été mises à jour : $ActiveDocumentPath" -ForegroundColor Green
}
