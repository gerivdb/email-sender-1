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
    .\development\scripts\check-mode-fixed.ps1 -FilePath "Roadmap/roadmap_complete_converted.md" -TaskIdentifier "1.2.1.3.2.3"

.EXAMPLE
    .\development\scripts\check-mode-fixed.ps1 -FilePath "Roadmap/roadmap_complete_converted.md" -TaskIdentifier "1.2.1.3.2.3" -ImplementationPath "development/roadmap/scripts-parser/module/Functions/Public" -TestsPath "development/roadmap/scripts-parser/module/Tests"

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.1
    Date de crÃ©ation: 2023-08-15
    Date de mise Ã  jour: 2025-05-02 - Correction des problÃ¨mes d'encodage et de chemins
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

    [Parameter(Mandatory = $false, HelpMessage = "Chemin vers le document actif Ã  vÃ©rifier et mettre Ã  jour. Si non spÃ©cifiÃ©, le document actif sera dÃ©tectÃ© automatiquement.")]
    [string]$ActiveDocumentPath,

    [Parameter(Mandatory = $false, HelpMessage = "Indique si les cases Ã  cocher dans le document actif doivent Ãªtre mises Ã  jour.")]
    [switch]$CheckActiveDocument = $true,

    [Parameter(Mandatory = $false, HelpMessage = "Force la mise Ã  jour des cases Ã  cocher dans le document actif sans demander de confirmation.")]
    [switch]$Force = $false
)

# Importer les fonctions nÃ©cessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $scriptPath)) -ChildPath "module\Functions\Public"
$invokeCheckPath = Join-Path -Path $modulePath -ChildPath "Invoke-RoadmapCheck.ps1"
$updateTaskPath = Join-Path -Path $modulePath -ChildPath "Update-RoadmapTaskStatus.ps1"
$updateCheckboxesPath = Join-Path -Path $modulePath -ChildPath "Update-ActiveDocumentCheckboxes-Fixed.ps1"

# Si les chemins n'existent pas, essayer d'autres chemins
if (-not (Test-Path -Path $modulePath)) {
    $modulePath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $scriptPath))) -ChildPath "module\Functions\Public"
    $invokeCheckPath = Join-Path -Path $modulePath -ChildPath "Invoke-RoadmapCheck.ps1"
    $updateTaskPath = Join-Path -Path $modulePath -ChildPath "Update-RoadmapTaskStatus.ps1"
    $updateCheckboxesPath = Join-Path -Path $modulePath -ChildPath "Update-ActiveDocumentCheckboxes-Fixed.ps1"
}

# Si les chemins n'existent toujours pas, essayer d'autres chemins
if (-not (Test-Path -Path $modulePath)) {
    $modulePath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $scriptPath)))) -ChildPath "module\Functions\Public"
    $invokeCheckPath = Join-Path -Path $modulePath -ChildPath "Invoke-RoadmapCheck.ps1"
    $updateTaskPath = Join-Path -Path $modulePath -ChildPath "Update-RoadmapTaskStatus.ps1"
    $updateCheckboxesPath = Join-Path -Path $modulePath -ChildPath "Update-ActiveDocumentCheckboxes-Fixed.ps1"
}

# Afficher les chemins pour le dÃ©bogage
Write-Host "Chemin du script : $scriptPath" -ForegroundColor Yellow
Write-Host "Chemin du module : $modulePath" -ForegroundColor Yellow
Write-Host "Chemin de Invoke-RoadmapCheck : $invokeCheckPath" -ForegroundColor Yellow
Write-Host "Chemin de Update-RoadmapTaskStatus : $updateTaskPath" -ForegroundColor Yellow
Write-Host "Chemin de Update-ActiveDocumentCheckboxes : $updateCheckboxesPath" -ForegroundColor Yellow

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

if (Test-Path -Path $updateCheckboxesPath) {
    . $updateCheckboxesPath
    Write-Host "Fonction Update-ActiveDocumentCheckboxes importÃ©e." -ForegroundColor Green
} else {
    Write-Warning "La fonction Update-ActiveDocumentCheckboxes est introuvable Ã  l'emplacement : $updateCheckboxesPath. La mise Ã  jour automatique des cases Ã  cocher dans le document actif ne sera pas disponible."
    
    # DÃ©finir une fonction de remplacement simple
    function Update-ActiveDocumentCheckboxes {
        [CmdletBinding(SupportsShouldProcess = $true)]
        param (
            [Parameter(Mandatory = $true)]
            [string]$DocumentPath,
    
            [Parameter(Mandatory = $true)]
            [hashtable]$ImplementationResults,
    
            [Parameter(Mandatory = $true)]
            [hashtable]$TestResults
        )
    
        # Lire le contenu du document actif
        $activeDocumentContent = Get-Content -Path $DocumentPath -Encoding UTF8
        $tasksUpdated = 0
    
        # Pour chaque tÃ¢che vÃ©rifiÃ©e
        foreach ($taskId in $ImplementationResults.Keys) {
            # Si la tÃ¢che est implÃ©mentÃ©e Ã  100% et testÃ©e avec succÃ¨s Ã  100%
            if ($ImplementationResults[$taskId].ImplementationComplete -and 
                $TestResults[$taskId].TestsComplete -and 
                $TestResults[$taskId].TestsSuccessful) {
                
                # Rechercher la tÃ¢che dans le document actif (diffÃ©rents formats possibles)
                $taskPatterns = @(
                    "- \[ \] \*\*$taskId\*\*",
                    "- \[ \] $taskId",
                    "- \[ \] .*$taskId.*"
                )
    
                foreach ($taskPattern in $taskPatterns) {
                    $taskReplacement = $taskPattern -replace "\[ \]", "[x]"
    
                    # Mettre Ã  jour la case Ã  cocher
                    $newContent = @()
                    $updated = $false
                    
                    foreach ($line in $activeDocumentContent) {
                        if ($line -match $taskPattern -and -not $updated) {
                            $newLine = $line -replace "\[ \]", "[x]"
                            $newContent += $newLine
                            $tasksUpdated++
                            $updated = $true
                            Write-Host "  TÃ¢che $taskId : Case Ã  cocher mise Ã  jour" -ForegroundColor Green
                        } else {
                            $newContent += $line
                        }
                    }
    
                    # Si le contenu a changÃ©, c'est que la tÃ¢che a Ã©tÃ© trouvÃ©e et mise Ã  jour
                    if ($updated) {
                        $activeDocumentContent = $newContent
                        break  # Sortir de la boucle des patterns une fois la tÃ¢che trouvÃ©e
                    }
                }
            }
        }
    
        # Si des tÃ¢ches ont Ã©tÃ© mises Ã  jour, enregistrer le document
        if ($tasksUpdated -gt 0) {
            if ($PSCmdlet.ShouldProcess($DocumentPath, "Mettre Ã  jour les cases Ã  cocher")) {
                # Mode force, appliquer les modifications sans confirmation
                $activeDocumentContent | Set-Content -Path $DocumentPath -Encoding UTF8
                Write-Host "  $tasksUpdated tÃ¢ches ont Ã©tÃ© mises Ã  jour dans le document actif." -ForegroundColor Green
            } else {
                # Mode simulation, afficher les modifications sans les appliquer
                Write-Host "  $tasksUpdated tÃ¢ches seraient mises Ã  jour dans le document actif (mode simulation)." -ForegroundColor Yellow
                Write-Host "  Utilisez -Force pour appliquer les modifications." -ForegroundColor Yellow
            }
        } else {
            Write-Host "  Aucune tÃ¢che Ã  mettre Ã  jour dans le document actif." -ForegroundColor Yellow
        }
        
        return $tasksUpdated
    }
}

# VÃ©rifier que le fichier de roadmap existe
if (-not (Test-Path -Path $FilePath)) {
    throw "Le fichier de roadmap spÃ©cifiÃ© n'existe pas : $FilePath"
}

# VÃ©rifier si le document actif existe ou le dÃ©tecter automatiquement
if ($CheckActiveDocument) {
    # Si le chemin du document actif n'est pas spÃ©cifiÃ©, essayer de le dÃ©tecter automatiquement
    if (-not $ActiveDocumentPath) {
        # Essayer de dÃ©tecter le document actif via l'environnement
        if ($env:VSCODE_ACTIVE_DOCUMENT) {
            $ActiveDocumentPath = $env:VSCODE_ACTIVE_DOCUMENT
            Write-Host "Document actif dÃ©tectÃ© automatiquement : $ActiveDocumentPath" -ForegroundColor Green
        } else {
            # Essayer de trouver un document rÃ©cemment modifiÃ© dans le rÃ©pertoire courant
            $recentFiles = Get-ChildItem -Path (Get-Location) -File -Recurse -Include "*.md" |
                Sort-Object LastWriteTime -Descending |
                Select-Object -First 5

            if ($recentFiles.Count -gt 0) {
                $ActiveDocumentPath = $recentFiles[0].FullName
                Write-Host "Document actif dÃ©tectÃ© automatiquement (fichier rÃ©cemment modifiÃ©) : $ActiveDocumentPath" -ForegroundColor Green
            } else {
                Write-Warning "Impossible de dÃ©tecter automatiquement le document actif. Veuillez spÃ©cifier le chemin du document actif avec le paramÃ¨tre -ActiveDocumentPath."
                $CheckActiveDocument = $false
            }
        }
    }

    # VÃ©rifier si le document actif existe
    if ($ActiveDocumentPath -and (-not (Test-Path -Path $ActiveDocumentPath))) {
        Write-Warning "Le document actif spÃ©cifiÃ© n'existe pas : $ActiveDocumentPath. La vÃ©rification du document actif sera dÃ©sactivÃ©e."
        $CheckActiveDocument = $false
    }
}

# Appeler la fonction Invoke-RoadmapCheck
$result = Invoke-RoadmapCheck -FilePath $FilePath -TaskIdentifier $TaskIdentifier -ImplementationPath $ImplementationPath -TestsPath $TestsPath -UpdateRoadmap $UpdateRoadmap -GenerateReport $GenerateReport

# VÃ©rifier et mettre Ã  jour les cases Ã  cocher dans le document actif si demandÃ©
if ($CheckActiveDocument -and $ActiveDocumentPath) {
    Write-Host "`nVÃ©rification et mise Ã  jour des cases Ã  cocher dans le document actif : $ActiveDocumentPath" -ForegroundColor Cyan

    # Extraire les rÃ©sultats d'implÃ©mentation et de tests
    $implementationResults = @{}
    $testResults = @{}

    foreach ($task in $result.Tasks) {
        $implementationResults[$task.Id] = $task.Implementation
        $testResults[$task.Id] = $task.Tests
    }

    # Utiliser la fonction Update-ActiveDocumentCheckboxes
    $updateParams = @{
        DocumentPath = $ActiveDocumentPath
        ImplementationResults = $implementationResults
        TestResults = $testResults
    }

    # Ajouter le paramÃ¨tre WhatIf si Force n'est pas spÃ©cifiÃ©
    if (-not $Force) {
        $updateParams.Add('WhatIf', $true)
        Write-Host "  Mode simulation activÃ©. Utilisez -Force pour appliquer les modifications." -ForegroundColor Yellow
    }

    # Appeler la fonction avec les paramÃ¨tres
    $tasksUpdated = Update-ActiveDocumentCheckboxes @updateParams
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
if ($CheckActiveDocument -and $ActiveDocumentPath) {
    if ($tasksUpdated -gt 0) {
        if ($Force) {
            Write-Host "`nLes cases Ã  cocher dans le document actif ont Ã©tÃ© mises Ã  jour : $ActiveDocumentPath" -ForegroundColor Green
        } else {
            Write-Host "`nLes cases Ã  cocher dans le document actif seraient mises Ã  jour (mode simulation) : $ActiveDocumentPath" -ForegroundColor Yellow
            Write-Host "Utilisez -Force pour appliquer les modifications." -ForegroundColor Yellow
        }
    } else {
        Write-Host "`nAucune case Ã  cocher n'a Ã©tÃ© mise Ã  jour dans le document actif : $ActiveDocumentPath" -ForegroundColor Gray
    }
}
