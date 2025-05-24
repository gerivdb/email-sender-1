# Update-RoadmapStatus.ps1
# Script pour mettre Ã  jour les statuts des tÃ¢ches dans la roadmap active
# et archiver automatiquement les tÃ¢ches terminÃ©es

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ActiveRoadmapPath = "projet\roadmaps\active\roadmap_active.md",

    [Parameter(Mandatory = $false)]
    [string]$CompletedRoadmapPath = "projet\roadmaps\archive\roadmap_completed.md",

    [Parameter(Mandatory = $false)]
    [string]$TaskId,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Complete", "Incomplete")]
    [string]$Status,

    [Parameter(Mandatory = $false)]
    [switch]$AutoArchive,

    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport
)

function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Info', 'Warning', 'Error')]
        [string]$Level = 'Info'
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    switch ($Level) {
        'Info' { Write-Host $logMessage -ForegroundColor Cyan }
        'Warning' { Write-Host $logMessage -ForegroundColor Yellow }
        'Error' { Write-Host $logMessage -ForegroundColor Red }
    }
}

function Test-FileExists {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path)) {
        Write-Log "Le fichier $Path n'existe pas." -Level Warning
        return $false
    }

    return $true
}

function Update-TaskStatus {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,

        [Parameter(Mandatory = $true)]
        [string]$TaskId,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Complete", "Incomplete")]
        [string]$NewStatus
    )

    if (-not (Test-FileExists -Path $RoadmapPath)) {
        return $false
    }

    try {
        $content = Get-Content -Path $RoadmapPath -Encoding UTF8
        $updated = $false
        $taskPattern = "- \[(x| )\] \*\*$TaskId\*\*"

        for ($i = 0; $i -lt $content.Count; $i++) {
            if ($content[$i] -match $taskPattern) {
                if ($NewStatus -eq "Complete") {
                    $content[$i] = $content[$i] -replace "- \[ \] \*\*$TaskId\*\*", "- [x] **$TaskId**"
                } else {
                    $content[$i] = $content[$i] -replace "- \[x\] \*\*$TaskId\*\*", "- [ ] **$TaskId**"
                }
                $updated = $true
                break
            }
        }

        if ($updated) {
            Set-Content -Path $RoadmapPath -Value $content -Encoding UTF8
            Write-Log "Statut de la tÃ¢che $TaskId mis Ã  jour: $NewStatus" -Level Info
            return $true
        } else {
            Write-Log "TÃ¢che $TaskId non trouvÃ©e dans $RoadmapPath" -Level Warning
            return $false
        }
    } catch {
        Write-Log "Erreur lors de la mise Ã  jour du statut: $_" -Level Error
        return $false
    }
}

function Get-TasksStatus {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath
    )

    if (-not (Test-FileExists -Path $RoadmapPath)) {
        return @()
    }

    try {
        $content = Get-Content -Path $RoadmapPath -Encoding UTF8
        $tasks = @()
        $taskPattern = "- \[(x| )\] \*\*([0-9.]+)\*\*\s+(.*)"
        $currentSection = ""

        foreach ($line in $content) {
            # DÃ©tecter les en-tÃªtes de section
            if ($line -match "^#{1,6}\s+(.+)$") {
                $currentSection = $Matches[1]
            }

            # DÃ©tecter les tÃ¢ches
            if ($line -match $taskPattern) {
                $status = if ($Matches[1] -eq "x") { "Complete" } else { "Incomplete" }
                $taskId = $Matches[2]
                $taskDescription = $Matches[3]

                $tasks += [PSCustomObject]@{
                    TaskId      = $taskId
                    Description = $taskDescription
                    Status      = $status
                    Section     = $currentSection
                }
            }
        }

        return $tasks
    } catch {
        Write-Log "Erreur lors de la rÃ©cupÃ©ration des statuts: $_" -Level Error
        return @()
    }
}

function Move-CompletedTasks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ActivePath,

        [Parameter(Mandatory = $true)]
        [string]$CompletedPath
    )

    if (-not (Test-FileExists -Path $ActivePath) -or -not (Test-FileExists -Path $CompletedPath)) {
        return $false
    }

    try {
        # Lire les fichiers
        $activeContent = Get-Content -Path $ActivePath -Encoding UTF8
        $completedContent = Get-Content -Path $CompletedPath -Encoding UTF8

        # Identifier les sections et tÃ¢ches complÃ©tÃ©es
        $newActiveContent = @()
        $sectionsToMove = @()
        $inSection = $false
        $currentSection = @()
        $currentSectionCompleted = $true
        $sectionHasTasks = $false

        foreach ($line in $activeContent) {
            # DÃ©tecter les en-tÃªtes de section
            if ($line -match "^#{1,6}\s+") {
                # Finaliser la section prÃ©cÃ©dente
                if ($inSection) {
                    if ($currentSectionCompleted -and $sectionHasTasks) {
                        $sectionsToMove += $currentSection
                    } else {
                        $newActiveContent += $currentSection
                    }
                }

                # Commencer une nouvelle section
                $inSection = $true
                $currentSection = @($line)
                $currentSectionCompleted = $true
                $sectionHasTasks = $false
            } elseif ($inSection) {
                # Ajouter la ligne Ã  la section courante
                $currentSection += $line

                # VÃ©rifier si c'est une tÃ¢che
                if ($line -match "- \[(x| )\]") {
                    $sectionHasTasks = $true
                    if ($line -match "- \[ \]") {
                        $currentSectionCompleted = $false
                    }
                }
            } else {
                # Ligne hors section (en-tÃªte du document)
                $newActiveContent += $line
            }
        }

        # Traiter la derniÃ¨re section
        if ($inSection) {
            if ($currentSectionCompleted -and $sectionHasTasks) {
                $sectionsToMove += $currentSection
            } else {
                $newActiveContent += $currentSection
            }
        }

        # Ajouter les sections complÃ©tÃ©es au fichier d'archive
        $newCompletedContent = $completedContent
        foreach ($section in $sectionsToMove) {
            $newCompletedContent += ""
            $newCompletedContent += $section
        }

        # Sauvegarder les fichiers
        Set-Content -Path $ActivePath -Value $newActiveContent -Encoding UTF8
        Set-Content -Path $CompletedPath -Value $newCompletedContent -Encoding UTF8

        Write-Log "DÃ©placement des tÃ¢ches terminÃ©es: $(($sectionsToMove | Measure-Object).Count) sections dÃ©placÃ©es" -Level Info
        return $true
    } catch {
        Write-Log "Erreur lors du dÃ©placement des tÃ¢ches terminÃ©es: $_" -Level Error
        return $false
    }
}

function New-StatusReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ActivePath,

        [Parameter(Mandatory = $true)]
        [string]$CompletedPath
    )

    if (-not (Test-FileExists -Path $ActivePath) -or -not (Test-FileExists -Path $CompletedPath)) {
        return $false
    }

    try {
        $activeTasks = Get-TasksStatus -RoadmapPath $ActivePath
        $completedTasks = Get-TasksStatus -RoadmapPath $CompletedPath

        $totalTasks = $activeTasks.Count + $completedTasks.Count
        $completedCount = ($activeTasks | Where-Object { $_.Status -eq "Complete" }).Count + $completedTasks.Count
        $incompleteCount = ($activeTasks | Where-Object { $_.Status -eq "Incomplete" }).Count

        $completionPercentage = if ($totalTasks -gt 0) { [math]::Round(($completedCount / $totalTasks) * 100, 2) } else { 0 }

        $report = @"
# Rapport d'avancement de la Roadmap - EMAIL_SENDER_1

GÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## RÃ©sumÃ©

- **Total des tÃ¢ches**: $totalTasks
- **TÃ¢ches terminÃ©es**: $completedCount
- **TÃ¢ches en cours**: $incompleteCount
- **Pourcentage d'achÃ¨vement**: $completionPercentage%

## TÃ¢ches actives par section

"@

        $activeSections = $activeTasks | Group-Object -Property Section

        foreach ($section in $activeSections) {
            $sectionTasks = $section.Group
            $sectionCompleted = ($sectionTasks | Where-Object { $_.Status -eq "Complete" }).Count
            $sectionTotal = $sectionTasks.Count
            $sectionPercentage = if ($sectionTotal -gt 0) { [math]::Round(($sectionCompleted / $sectionTotal) * 100, 2) } else { 0 }

            $report += @"

### $($section.Name)

- Progression: $sectionCompleted / $sectionTotal ($sectionPercentage%)

| ID | Description | Statut |
|---|---|---|

"@

            foreach ($task in $sectionTasks | Sort-Object -Property TaskId) {
                $statusIcon = if ($task.Status -eq "Complete") { "âœ…" } else { "â³" }
                $report += "| $($task.TaskId) | $($task.Description) | $statusIcon |\n"
            }
        }

        $reportPath = "projet\roadmaps\reports\status_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"
        $reportFolder = Split-Path -Path $reportPath -Parent

        if (-not (Test-Path -Path $reportFolder)) {
            New-Item -Path $reportFolder -ItemType Directory -Force | Out-Null
        }

        Set-Content -Path $reportPath -Value $report -Encoding UTF8
        Write-Log "Rapport d'avancement gÃ©nÃ©rÃ©: $reportPath" -Level Info

        return $reportPath
    } catch {
        Write-Log "Erreur lors de la gÃ©nÃ©ration du rapport: $_" -Level Error
        return $false
    }
}

# ExÃ©cution principale
if (-not [string]::IsNullOrEmpty($TaskId) -and -not [string]::IsNullOrEmpty($Status)) {
    Write-Log "Mise Ã  jour du statut de la tÃ¢che ${TaskId}: ${Status}" -Level Info
    $success = Update-TaskStatus -RoadmapPath $ActiveRoadmapPath -TaskId $TaskId -NewStatus $Status

    if ($success -and $AutoArchive -and $Status -eq "Complete") {
        Write-Log "Archivage automatique des tÃ¢ches terminÃ©es..." -Level Info
        Move-CompletedTasks -ActivePath $ActiveRoadmapPath -CompletedPath $CompletedRoadmapPath
    }
} elseif ($AutoArchive) {
    Write-Log "Archivage des tÃ¢ches terminÃ©es..." -Level Info
    Move-CompletedTasks -ActivePath $ActiveRoadmapPath -CompletedPath $CompletedRoadmapPath
}

if ($GenerateReport) {
    Write-Log "GÃ©nÃ©ration du rapport d'avancement..." -Level Info
    $reportPath = New-StatusReport -ActivePath $ActiveRoadmapPath -CompletedPath $CompletedRoadmapPath

    if ($reportPath) {
        Write-Log "Rapport gÃ©nÃ©rÃ© avec succÃ¨s: $reportPath" -Level Info
    }
}

