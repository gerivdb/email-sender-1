<#
.SYNOPSIS
    Script pour vÃ©rifier si les tÃ¢ches sÃ©lectionnÃ©es ont Ã©tÃ© implÃ©mentÃ©es Ã  100% et testÃ©es avec succÃ¨s Ã  100% (Mode CHECK).

.DESCRIPTION
    Ce script permet de vÃ©rifier si les tÃ¢ches sÃ©lectionnÃ©es ont Ã©tÃ© implÃ©mentÃ©es Ã  100% et testÃ©es
    avec succÃ¨s Ã  100%. Si c'est le cas, il peut mettre Ã  jour automatiquement le statut des tÃ¢ches
    dans la roadmap en cochant les cases correspondantes. Il implÃ©mente le mode CHECK dÃ©crit dans
    la documentation des modes de fonctionnement.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap Ã  vÃ©rifier et mettre Ã  jour.

.PARAMETER TaskIdentifier
    Identifiant de la tÃ¢che Ã  vÃ©rifier (par exemple, "1.2.1.3.2.3").
    Si non spÃ©cifiÃ©, l'utilisateur sera invitÃ© Ã  le saisir.

.PARAMETER ImplementationPath
    Chemin vers le rÃ©pertoire contenant l'implÃ©mentation.
    Si non spÃ©cifiÃ©, le script tentera de le dÃ©duire automatiquement.

.PARAMETER TestsPath
    Chemin vers le rÃ©pertoire contenant les tests.
    Si non spÃ©cifiÃ©, le script tentera de le dÃ©duire automatiquement.

.PARAMETER UpdateRoadmap
    Indique si la roadmap doit Ãªtre mise Ã  jour automatiquement.
    Par dÃ©faut : $true.

.PARAMETER GenerateReport
    Indique si un rapport doit Ãªtre gÃ©nÃ©rÃ©.
    Par dÃ©faut : $true.

.EXAMPLE
    .\scripts\check-mode.ps1 -FilePath "Roadmap/roadmap_complete_converted.md" -TaskIdentifier "1.2.1.3.2.3"

.EXAMPLE
    .\scripts\check-mode.ps1 -FilePath "Roadmap/roadmap_complete_converted.md" -TaskIdentifier "1.2.1.3.2.3" -ImplementationPath "scripts/roadmap-parser/module/Functions/Public" -TestsPath "scripts/roadmap-parser/module/Tests"

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
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

    [Parameter(Mandatory = $false, HelpMessage = "Chemin vers le document actif Ã  vÃ©rifier et mettre Ã  jour.")]
    [string]$ActiveDocumentPath,

    [Parameter(Mandatory = $false, HelpMessage = "Indique si les cases Ã  cocher dans le document actif doivent Ãªtre mises Ã  jour.")]
    [switch]$CheckActiveDocument = $true
)

# Importer les fonctions nÃ©cessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path -Path $scriptPath -ChildPath "roadmap-parser\module\Functions\Public"
$invokeCheckPath = Join-Path -Path $modulePath -ChildPath "Invoke-RoadmapCheck.ps1"
$updateTaskPath = Join-Path -Path $modulePath -ChildPath "Update-RoadmapTaskStatus.ps1"

if (Test-Path -Path $invokeCheckPath) {
    . $invokeCheckPath
    Write-Host "Fonction Invoke-RoadmapCheck importÃ©e." -ForegroundColor Green
} else {
    throw "La fonction Invoke-RoadmapCheck est introuvable Ã  l'emplacement : $invokeCheckPath"
}

if (Test-Path -Path $updateTaskPath) {
    . $updateTaskPath
    Write-Host "Fonction Update-RoadmapTaskStatus importÃ©e." -ForegroundColor Green
} else {
    throw "La fonction Update-RoadmapTaskStatus est introuvable Ã  l'emplacement : $updateTaskPath"
}

# VÃ©rifier que le fichier de roadmap existe
if (-not (Test-Path -Path $FilePath)) {
    throw "Le fichier de roadmap spÃ©cifiÃ© n'existe pas : $FilePath"
}

# VÃ©rifier si le document actif existe
if ($CheckActiveDocument -and $ActiveDocumentPath) {
    if (-not (Test-Path -Path $ActiveDocumentPath)) {
        Write-Warning "Le document actif spÃ©cifiÃ© n'existe pas : $ActiveDocumentPath. La vÃ©rification du document actif sera dÃ©sactivÃ©e."
        $CheckActiveDocument = $false
    }
}

# Appeler la fonction Invoke-RoadmapCheck
$result = Invoke-RoadmapCheck -FilePath $FilePath -TaskIdentifier $TaskIdentifier -ImplementationPath $ImplementationPath -TestsPath $TestsPath -UpdateRoadmap $UpdateRoadmap -GenerateReport $GenerateReport

# VÃ©rifier et mettre Ã  jour les cases Ã  cocher dans le document actif si demandÃ©
if ($CheckActiveDocument -and $ActiveDocumentPath) {
    Write-Host "`nVÃ©rification et mise Ã  jour des cases Ã  cocher dans le document actif : $ActiveDocumentPath" -ForegroundColor Cyan

    # Lire le contenu du document actif
    $activeDocumentContent = Get-Content -Path $ActiveDocumentPath -Encoding UTF8
    $tasksUpdated = 0

    # Pour chaque tÃ¢che vÃ©rifiÃ©e
    foreach ($task in $result.Tasks) {
        # Si la tÃ¢che est implÃ©mentÃ©e Ã  100% et testÃ©e avec succÃ¨s Ã  100%
        if ($task.Implementation.ImplementationComplete -and $task.Tests.TestsComplete -and $task.Tests.TestsSuccessful) {
            # Rechercher la tÃ¢che dans le document actif
            $taskPattern = "- \[ \] \*\*$($task.Id)\*\*"
            $taskReplacement = "- [x] **$($task.Id)**"

            # Mettre Ã  jour la case Ã  cocher
            $newContent = $activeDocumentContent -replace $taskPattern, $taskReplacement

            # Si le contenu a changÃ©, c'est que la tÃ¢che a Ã©tÃ© trouvÃ©e et mise Ã  jour
            if ($newContent -ne $activeDocumentContent) {
                $activeDocumentContent = $newContent
                $tasksUpdated++
                Write-Host "  TÃ¢che $($task.Id) - $($task.Title) : Case Ã  cocher mise Ã  jour" -ForegroundColor Green
            }
        }
    }

    # Si des tÃ¢ches ont Ã©tÃ© mises Ã  jour, enregistrer le document
    if ($tasksUpdated -gt 0) {
        if ($PSCmdlet.ShouldProcess($ActiveDocumentPath, "Mettre Ã  jour les cases Ã  cocher dans le document actif")) {
            $activeDocumentContent | Set-Content -Path $ActiveDocumentPath -Encoding UTF8
            Write-Host "  $tasksUpdated tÃ¢ches ont Ã©tÃ© mises Ã  jour dans le document actif." -ForegroundColor Green
        }
    } else {
        Write-Host "  Aucune tÃ¢che Ã  mettre Ã  jour dans le document actif." -ForegroundColor Yellow
    }
}

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Host "`nRÃ©sumÃ© des rÃ©sultats :" -ForegroundColor Cyan
Write-Host "  TÃ¢che principale : $($result.TaskIdentifier)" -ForegroundColor Cyan
Write-Host "  Nombre total de tÃ¢ches : $($result.TotalTasks)" -ForegroundColor Cyan
Write-Host "  TÃ¢ches implÃ©mentÃ©es Ã  100% : $($result.ImplementedTasks)" -ForegroundColor $(if ($result.ImplementedTasks -eq $result.TotalTasks) { "Green" } else { "Yellow" })
Write-Host "  TÃ¢ches testÃ©es Ã  100% : $($result.TestedTasks)" -ForegroundColor $(if ($result.TestedTasks -eq $result.TotalTasks) { "Green" } else { "Yellow" })
Write-Host "  TÃ¢ches mises Ã  jour dans la roadmap : $($result.UpdatedTasks)" -ForegroundColor $(if ($result.UpdatedTasks -gt 0) { "Green" } else { "Gray" })
if ($CheckActiveDocument -and $ActiveDocumentPath) {
    Write-Host "  TÃ¢ches mises Ã  jour dans le document actif : $tasksUpdated" -ForegroundColor $(if ($tasksUpdated -gt 0) { "Green" } else { "Gray" })
}

# Afficher les dÃ©tails des tÃ¢ches
Write-Host "`nDÃ©tails des tÃ¢ches :" -ForegroundColor Cyan
foreach ($task in $result.Tasks) {
    $statusColor = if ($task.IsChecked -or $task.NeedsUpdate) { "Green" } else { "Yellow" }
    $statusText = if ($task.IsChecked) { "TerminÃ©e" } elseif ($task.NeedsUpdate) { "Mise Ã  jour" } else { "En cours" }

    Write-Host "  TÃ¢che $($task.Id) - $($task.Title)" -ForegroundColor $statusColor
    Write-Host "    Ã‰tat : $statusText" -ForegroundColor $statusColor
    Write-Host "    ImplÃ©mentation : $(if ($task.Implementation.ImplementationComplete) { "ComplÃ¨te" } else { "IncomplÃ¨te ($($task.Implementation.ImplementationPercentage)%)" })" -ForegroundColor $(if ($task.Implementation.ImplementationComplete) { "Green" } else { "Yellow" })
    Write-Host "    Tests : $(if ($task.Tests.TestsComplete) { "Complets" } else { "Incomplets" })" -ForegroundColor $(if ($task.Tests.TestsComplete) { "Green" } else { "Yellow" })
    Write-Host "    RÃ©sultats des tests : $(if ($task.Tests.TestsSuccessful) { "RÃ©ussis" } else { "Ã‰chouÃ©s" })" -ForegroundColor $(if ($task.Tests.TestsSuccessful) { "Green" } else { "Red" })
}

# Afficher le chemin du rapport si gÃ©nÃ©rÃ©
if ($GenerateReport) {
    $reportPath = Join-Path -Path (Split-Path -Parent $FilePath) -ChildPath "check_report_$TaskIdentifier.md"
    if (Test-Path -Path $reportPath) {
        Write-Host "`nRapport gÃ©nÃ©rÃ© : $reportPath" -ForegroundColor Green
    }
}

# Afficher un message de confirmation pour le document actif
if ($CheckActiveDocument -and $ActiveDocumentPath -and $tasksUpdated -gt 0) {
    Write-Host "`nLes cases Ã  cocher dans le document actif ont Ã©tÃ© mises Ã  jour : $ActiveDocumentPath" -ForegroundColor Green
}
