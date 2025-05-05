<#
.SYNOPSIS
    Script pour vÃƒÂ©rifier si les tÃƒÂ¢ches sÃƒÂ©lectionnÃƒÂ©es ont ÃƒÂ©tÃƒÂ© implÃƒÂ©mentÃƒÂ©es ÃƒÂ  100% et testÃƒÂ©es avec succÃƒÂ¨s ÃƒÂ  100% (Mode CHECK).

.DESCRIPTION
    Ce script permet de vÃƒÂ©rifier si les tÃƒÂ¢ches sÃƒÂ©lectionnÃƒÂ©es ont ÃƒÂ©tÃƒÂ© implÃƒÂ©mentÃƒÂ©es ÃƒÂ  100% et testÃƒÂ©es
    avec succÃƒÂ¨s ÃƒÂ  100%. Si c'est le cas, il peut mettre ÃƒÂ  jour automatiquement le statut des tÃƒÂ¢ches
    dans la roadmap en cochant les cases correspondantes. Il implÃƒÂ©mente le mode CHECK dÃƒÂ©crit dans
    la documentation des modes de fonctionnement.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap ÃƒÂ  vÃƒÂ©rifier et mettre ÃƒÂ  jour.

.PARAMETER TaskIdentifier
    Identifiant de la tÃƒÂ¢che ÃƒÂ  vÃƒÂ©rifier (par exemple, "1.2.1.3.2.3").
    Si non spÃƒÂ©cifiÃƒÂ©, l'utilisateur sera invitÃƒÂ© ÃƒÂ  le saisir.

.PARAMETER ImplementationPath
    Chemin vers le rÃƒÂ©pertoire contenant l'implÃƒÂ©mentation.
    Si non spÃƒÂ©cifiÃƒÂ©, le script tentera de le dÃƒÂ©duire automatiquement.

.PARAMETER TestsPath
    Chemin vers le rÃƒÂ©pertoire contenant les tests.
    Si non spÃƒÂ©cifiÃƒÂ©, le script tentera de le dÃƒÂ©duire automatiquement.

.PARAMETER UpdateRoadmap
    Indique si la roadmap doit ÃƒÂªtre mise ÃƒÂ  jour automatiquement.
    Par dÃƒÂ©faut : $true.

.PARAMETER GenerateReport
    Indique si un rapport doit ÃƒÂªtre gÃƒÂ©nÃƒÂ©rÃƒÂ©.
    Par dÃƒÂ©faut : $true.

.EXAMPLE
    .\development\scripts\check-mode.ps1 -FilePath "Roadmap/roadmap_complete_converted.md" -TaskIdentifier "1.2.1.3.2.3"

.EXAMPLE
    .\development\scripts\check-mode.ps1 -FilePath "Roadmap/roadmap_complete_converted.md" -TaskIdentifier "1.2.1.3.2.3" -ImplementationPath "development/roadmap/scripts-parser/module/Functions/Public" -TestsPath "development/roadmap/scripts-parser/module/Tests"

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃƒÂ©ation: 2023-08-15
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

    [Parameter(Mandatory = $false, HelpMessage = "Chemin vers le document actif ÃƒÂ  vÃƒÂ©rifier et mettre ÃƒÂ  jour.")]
    [string]$ActiveDocumentPath,

    [Parameter(Mandatory = $false, HelpMessage = "Indique si les cases ÃƒÂ  cocher dans le document actif doivent ÃƒÂªtre mises ÃƒÂ  jour.")]
    [switch]$CheckActiveDocument = $true
)

# Importer les fonctions nÃƒÂ©cessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path -Path $scriptPath -ChildPath "roadmap-parser\module\Functions\Public"
$invokeCheckPath = Join-Path -Path $modulePath -ChildPath "Invoke-RoadmapCheck.ps1"
$updateTaskPath = Join-Path -Path $modulePath -ChildPath "Update-RoadmapTaskStatus.ps1"

if (Test-Path -Path $invokeCheckPath) {
    . $invokeCheckPath
    Write-Host "Fonction Invoke-RoadmapCheck importÃƒÂ©e." -ForegroundColor Green
} else {
    throw "La fonction Invoke-RoadmapCheck est introuvable ÃƒÂ  l'emplacement : $invokeCheckPath"
}

if (Test-Path -Path $updateTaskPath) {
    . $updateTaskPath
    Write-Host "Fonction Update-RoadmapTaskStatus importÃƒÂ©e." -ForegroundColor Green
} else {
    throw "La fonction Update-RoadmapTaskStatus est introuvable ÃƒÂ  l'emplacement : $updateTaskPath"
}

# VÃƒÂ©rifier que le fichier de roadmap existe
if (-not (Test-Path -Path $FilePath)) {
    throw "Le fichier de roadmap spÃƒÂ©cifiÃƒÂ© n'existe pas : $FilePath"
}

# VÃƒÂ©rifier si le document actif existe
if ($CheckActiveDocument -and $ActiveDocumentPath) {
    if (-not (Test-Path -Path $ActiveDocumentPath)) {
        Write-Warning "Le document actif spÃƒÂ©cifiÃƒÂ© n'existe pas : $ActiveDocumentPath. La vÃƒÂ©rification du document actif sera dÃƒÂ©sactivÃƒÂ©e."
        $CheckActiveDocument = $false
    }
}

# Appeler la fonction Invoke-RoadmapCheck
$result = Invoke-RoadmapCheck -FilePath $FilePath -TaskIdentifier $TaskIdentifier -ImplementationPath $ImplementationPath -TestsPath $TestsPath -UpdateRoadmap $UpdateRoadmap -GenerateReport $GenerateReport

# VÃƒÂ©rifier et mettre ÃƒÂ  jour les cases ÃƒÂ  cocher dans le document actif si demandÃƒÂ©
if ($CheckActiveDocument -and $ActiveDocumentPath) {
    Write-Host "`nVÃƒÂ©rification et mise ÃƒÂ  jour des cases ÃƒÂ  cocher dans le document actif : $ActiveDocumentPath" -ForegroundColor Cyan

    # Lire le contenu du document actif
    $activeDocumentContent = Get-Content -Path $ActiveDocumentPath -Encoding UTF8
    $tasksUpdated = 0

    # Pour chaque tÃƒÂ¢che vÃƒÂ©rifiÃƒÂ©e
    foreach ($task in $result.Tasks) {
        # Si la tÃƒÂ¢che est implÃƒÂ©mentÃƒÂ©e ÃƒÂ  100% et testÃƒÂ©e avec succÃƒÂ¨s ÃƒÂ  100%
        if ($task.Implementation.ImplementationComplete -and $task.Tests.TestsComplete -and $task.Tests.TestsSuccessful) {
            # Rechercher la tÃƒÂ¢che dans le document actif
            $taskPattern = "- \[ \] \*\*$($task.Id)\*\*"
            $taskReplacement = "- [x] **$($task.Id)**"

            # Mettre ÃƒÂ  jour la case ÃƒÂ  cocher
            $newContent = $activeDocumentContent -replace $taskPattern, $taskReplacement

            # Si le contenu a changÃƒÂ©, c'est que la tÃƒÂ¢che a ÃƒÂ©tÃƒÂ© trouvÃƒÂ©e et mise ÃƒÂ  jour
            if ($newContent -ne $activeDocumentContent) {
                $activeDocumentContent = $newContent
                $tasksUpdated++
                Write-Host "  TÃƒÂ¢che $($task.Id) - $($task.Title) : Case ÃƒÂ  cocher mise ÃƒÂ  jour" -ForegroundColor Green
            }
        }
    }

    # Si des tÃƒÂ¢ches ont ÃƒÂ©tÃƒÂ© mises ÃƒÂ  jour, enregistrer le document
    if ($tasksUpdated -gt 0) {
        if ($PSCmdlet.ShouldProcess($ActiveDocumentPath, "Mettre ÃƒÂ  jour les cases ÃƒÂ  cocher dans le document actif")) {
            $activeDocumentContent | Set-Content -Path $ActiveDocumentPath -Encoding UTF8
            Write-Host "  $tasksUpdated tÃƒÂ¢ches ont ÃƒÂ©tÃƒÂ© mises ÃƒÂ  jour dans le document actif." -ForegroundColor Green
        }
    } else {
        Write-Host "  Aucune tÃƒÂ¢che ÃƒÂ  mettre ÃƒÂ  jour dans le document actif." -ForegroundColor Yellow
    }
}

# Afficher un rÃƒÂ©sumÃƒÂ© des rÃƒÂ©sultats
Write-Host "`nRÃƒÂ©sumÃƒÂ© des rÃƒÂ©sultats :" -ForegroundColor Cyan
Write-Host "  TÃƒÂ¢che principale : $($result.TaskIdentifier)" -ForegroundColor Cyan
Write-Host "  Nombre total de tÃƒÂ¢ches : $($result.TotalTasks)" -ForegroundColor Cyan
Write-Host "  TÃƒÂ¢ches implÃƒÂ©mentÃƒÂ©es ÃƒÂ  100% : $($result.ImplementedTasks)" -ForegroundColor $(if ($result.ImplementedTasks -eq $result.TotalTasks) { "Green" } else { "Yellow" })
Write-Host "  TÃƒÂ¢ches testÃƒÂ©es ÃƒÂ  100% : $($result.TestedTasks)" -ForegroundColor $(if ($result.TestedTasks -eq $result.TotalTasks) { "Green" } else { "Yellow" })
Write-Host "  TÃƒÂ¢ches mises ÃƒÂ  jour dans la roadmap : $($result.UpdatedTasks)" -ForegroundColor $(if ($result.UpdatedTasks -gt 0) { "Green" } else { "Gray" })
if ($CheckActiveDocument -and $ActiveDocumentPath) {
    Write-Host "  TÃƒÂ¢ches mises ÃƒÂ  jour dans le document actif : $tasksUpdated" -ForegroundColor $(if ($tasksUpdated -gt 0) { "Green" } else { "Gray" })
}

# Afficher les dÃƒÂ©tails des tÃƒÂ¢ches
Write-Host "`nDÃƒÂ©tails des tÃƒÂ¢ches :" -ForegroundColor Cyan
foreach ($task in $result.Tasks) {
    $statusColor = if ($task.IsChecked -or $task.NeedsUpdate) { "Green" } else { "Yellow" }
    $statusText = if ($task.IsChecked) { "TerminÃƒÂ©e" } elseif ($task.NeedsUpdate) { "Mise ÃƒÂ  jour" } else { "En cours" }

    Write-Host "  TÃƒÂ¢che $($task.Id) - $($task.Title)" -ForegroundColor $statusColor
    Write-Host "    Ãƒâ€°tat : $statusText" -ForegroundColor $statusColor
    Write-Host "    ImplÃƒÂ©mentation : $(if ($task.Implementation.ImplementationComplete) { "ComplÃƒÂ¨te" } else { "IncomplÃƒÂ¨te ($($task.Implementation.ImplementationPercentage)%)" })" -ForegroundColor $(if ($task.Implementation.ImplementationComplete) { "Green" } else { "Yellow" })
    Write-Host "    Tests : $(if ($task.Tests.TestsComplete) { "Complets" } else { "Incomplets" })" -ForegroundColor $(if ($task.Tests.TestsComplete) { "Green" } else { "Yellow" })
    Write-Host "    RÃƒÂ©sultats des tests : $(if ($task.Tests.TestsSuccessful) { "RÃƒÂ©ussis" } else { "Ãƒâ€°chouÃƒÂ©s" })" -ForegroundColor $(if ($task.Tests.TestsSuccessful) { "Green" } else { "Red" })
}

# Afficher le chemin du rapport si gÃƒÂ©nÃƒÂ©rÃƒÂ©
if ($GenerateReport) {
    $reportPath = Join-Path -Path (Split-Path -Parent $FilePath) -ChildPath "check_report_$TaskIdentifier.md"
    if (Test-Path -Path $reportPath) {
        Write-Host "`nRapport gÃƒÂ©nÃƒÂ©rÃƒÂ© : $reportPath" -ForegroundColor Green
    }
}

# Afficher un message de confirmation pour le document actif
if ($CheckActiveDocument -and $ActiveDocumentPath -and $tasksUpdated -gt 0) {
    Write-Host "`nLes cases ÃƒÂ  cocher dans le document actif ont ÃƒÂ©tÃƒÂ© mises ÃƒÂ  jour : $ActiveDocumentPath" -ForegroundColor Green
}

