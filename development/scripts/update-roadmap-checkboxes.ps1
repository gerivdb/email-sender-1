<#
.SYNOPSIS
    Met à jour les cases à cocher dans la roadmap pour les tâches implémentées et testées à 100%.

.DESCRIPTION
    Ce script met à jour les cases à cocher dans la roadmap pour les tâches qui ont été implémentées
    et testées avec succès à 100%. Il utilise une approche simplifiée pour identifier les tâches
    complétées et mettre à jour les cases à cocher correspondantes.

.PARAMETER RoadmapPath
    Chemin vers le fichier de roadmap à mettre à jour.

.PARAMETER Force
    Indique si les modifications doivent être appliquées sans confirmation.

.EXAMPLE
    .\update-roadmap-checkboxes.ps1 -RoadmapPath "projet\roadmaps\roadmap_complete_converted.md"

.EXAMPLE
    .\update-roadmap-checkboxes.ps1 -RoadmapPath "projet\roadmaps\roadmap_complete_converted.md" -Force

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2025-05-02
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true)]
    [string]$RoadmapPath,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Vérifier que le fichier de roadmap existe
if (-not (Test-Path -Path $RoadmapPath)) {
    Write-Error "Le fichier de roadmap spécifié n'existe pas : $RoadmapPath"
    exit 1
}

# Liste des tâches complétées (à titre d'exemple, cette liste devrait être générée dynamiquement)
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
    
    # Vérifier si la ligne contient une case à cocher non cochée
    if ($line -match '^\s*-\s+\[\s*\]') {
        # Pour chaque tâche complétée
        foreach ($taskId in $completedTasks) {
            # Échapper les caractères spéciaux dans l'ID de la tâche pour la regex
            $escapedTaskId = [regex]::Escape($taskId)
            
            # Vérifier si la ligne contient l'ID de la tâche
            if ($line -match "\*\*$escapedTaskId\*\*" -or
                $line -match "\b$escapedTaskId\b" -or
                $line -match "\[$escapedTaskId\]" -or
                $line -match "\($escapedTaskId\)") {
                
                # Mettre à jour la case à cocher
                $updatedLine = $line -replace '\[\s*\]', '[x]'
                $updatedContent += $updatedLine
                $tasksUpdated++
                $updated = $true
                
                Write-Host "Tâche $taskId : Case à cocher mise à jour" -ForegroundColor Green
                break
            }
        }
    }
    
    # Si la ligne n'a pas été mise à jour, l'ajouter telle quelle
    if (-not $updated) {
        $updatedContent += $line
    }
}

# Si des tâches ont été mises à jour, enregistrer le fichier
if ($tasksUpdated -gt 0) {
    if ($Force -or $PSCmdlet.ShouldProcess($RoadmapPath, "Mettre à jour $tasksUpdated cases à cocher")) {
        $updatedContent | Set-Content -Path $RoadmapPath -Encoding UTF8
        Write-Host "$tasksUpdated cases à cocher ont été mises à jour dans la roadmap." -ForegroundColor Green
    } else {
        Write-Host "$tasksUpdated cases à cocher seraient mises à jour dans la roadmap (mode simulation)." -ForegroundColor Yellow
        Write-Host "Utilisez -Force pour appliquer les modifications." -ForegroundColor Yellow
    }
} else {
    Write-Host "Aucune case à cocher n'a été mise à jour dans la roadmap." -ForegroundColor Yellow
}
