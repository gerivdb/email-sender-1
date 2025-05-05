<#
.SYNOPSIS
    Met Ã  jour les cases Ã  cocher dans la roadmap pour les tÃ¢ches implÃ©mentÃ©es et testÃ©es Ã  100%.

.DESCRIPTION
    Ce script met Ã  jour les cases Ã  cocher dans la roadmap pour les tÃ¢ches qui ont Ã©tÃ© implÃ©mentÃ©es
    et testÃ©es avec succÃ¨s Ã  100%. Il utilise une approche simplifiÃ©e pour identifier les tÃ¢ches
    complÃ©tÃ©es et mettre Ã  jour les cases Ã  cocher correspondantes.

.PARAMETER RoadmapPath
    Chemin vers le fichier de roadmap Ã  mettre Ã  jour.

.PARAMETER Force
    Indique si les modifications doivent Ãªtre appliquÃ©es sans confirmation.

.EXAMPLE
    .\update-roadmap-checkboxes.ps1 -RoadmapPath "projet\roadmaps\roadmap_complete_converted.md"

.EXAMPLE
    .\update-roadmap-checkboxes.ps1 -RoadmapPath "projet\roadmaps\roadmap_complete_converted.md" -Force

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-02
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true)]
    [string]$RoadmapPath,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# VÃ©rifier que le fichier de roadmap existe
if (-not (Test-Path -Path $RoadmapPath)) {
    Write-Error "Le fichier de roadmap spÃ©cifiÃ© n'existe pas : $RoadmapPath"
    exit 1
}

# Liste des tÃ¢ches complÃ©tÃ©es (Ã  titre d'exemple, cette liste devrait Ãªtre gÃ©nÃ©rÃ©e dynamiquement)
$completedTasks = @(
    "1.1.1",
    "1.1.2",
    "1.1.3",
    "1.2.1",
    "1.2.2",
    "1.2.3",
    "1.3.1",
    "1.3.2",
    "1.3.3",
    "1.4.1",
    "1.4.2",
    "1.4.3",
    "1.5.1",
    "1.5.2",
    "1.5.3",
    "1.6.1",
    "1.6.2",
    "1.6.3",
    "1.7.1",
    "1.7.2",
    "1.7.3",
    "1.8.1",
    "1.8.2",
    "1.8.3",
    "1.9.1",
    "1.9.2",
    "1.9.3",
    "1.10.1",
    "1.10.2",
    "1.10.3",
    "1.11.1",
    "1.11.2",
    "1.11.3",
    "1.12.1",
    "1.12.2",
    "1.12.3",
    "1.13.1",
    "1.13.2",
    "1.13.3",
    "1.14.1",
    "1.14.2",
    "1.14.3",
    "1.15.1",
    "1.15.2",
    "1.15.3",
    "1.16.1",
    "1.16.2",
    "1.16.3"
)

# Lire le contenu du fichier de roadmap
$content = Get-Content -Path $RoadmapPath -Encoding UTF8
$updatedContent = @()
$tasksUpdated = 0

# Parcourir chaque ligne du fichier
foreach ($line in $content) {
    $updated = $false
    
    # VÃ©rifier si la ligne contient une case Ã  cocher non cochÃ©e
    if ($line -match '^\s*-\s+\[\s*\]') {
        # Pour chaque tÃ¢che complÃ©tÃ©e
        foreach ($taskId in $completedTasks) {
            # Ã‰chapper les caractÃ¨res spÃ©ciaux dans l'ID de la tÃ¢che pour la regex
            $escapedTaskId = [regex]::Escape($taskId)
            
            # VÃ©rifier si la ligne contient l'ID de la tÃ¢che
            if ($line -match "\*\*$escapedTaskId\*\*" -or
                $line -match "\b$escapedTaskId\b" -or
                $line -match "\[$escapedTaskId\]" -or
                $line -match "\($escapedTaskId\)") {
                
                # Mettre Ã  jour la case Ã  cocher
                $updatedLine = $line -replace '\[\s*\]', '[x]'
                $updatedContent += $updatedLine
                $tasksUpdated++
                $updated = $true
                
                Write-Host "TÃ¢che $taskId : Case Ã  cocher mise Ã  jour" -ForegroundColor Green
                break
            }
        }
    }
    
    # Si la ligne n'a pas Ã©tÃ© mise Ã  jour, l'ajouter telle quelle
    if (-not $updated) {
        $updatedContent += $line
    }
}

# Si des tÃ¢ches ont Ã©tÃ© mises Ã  jour, enregistrer le fichier
if ($tasksUpdated -gt 0) {
    if ($Force -or $PSCmdlet.ShouldProcess($RoadmapPath, "Mettre Ã  jour $tasksUpdated cases Ã  cocher")) {
        $updatedContent | Set-Content -Path $RoadmapPath -Encoding UTF8
        Write-Host "$tasksUpdated cases Ã  cocher ont Ã©tÃ© mises Ã  jour dans la roadmap." -ForegroundColor Green
    } else {
        Write-Host "$tasksUpdated cases Ã  cocher seraient mises Ã  jour dans la roadmap (mode simulation)." -ForegroundColor Yellow
        Write-Host "Utilisez -Force pour appliquer les modifications." -ForegroundColor Yellow
    }
} else {
    Write-Host "Aucune case Ã  cocher n'a Ã©tÃ© mise Ã  jour dans la roadmap." -ForegroundColor Yellow
}
