#Requires -Version 5.1
<#
.SYNOPSIS
    Archive les tâches complétées à 100% avec tests unitaires effectués.
.DESCRIPTION
    Ce script identifie les tâches marquées comme complétées à 100% dans le roadmap,
    vérifie que les tests unitaires ont été effectués et que les corrections nécessaires
    ont été apportées, puis les archive automatiquement.
.PARAMETER RoadmapPath
    Chemin vers le fichier Markdown de la roadmap.
.PARAMETER ArchivePath
    Chemin vers le fichier d'archive. Si non spécifié, le fichier sera créé au même
    emplacement que le fichier de roadmap avec le nom "roadmap_archive.md".
.PARAMETER Force
    Force l'archivage même si les tests unitaires ne sont pas explicitement mentionnés.
.EXAMPLE
    .\Archive-CompletedTasks.ps1 -RoadmapPath "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\roadmap_complete_converted.md"
.NOTES
    Auteur: EMAIL_SENDER_1 Team
    Date: 2023-07-04
    Version: 1.0.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$RoadmapPath,

    [Parameter(Mandatory = $false)]
    [string]$ArchivePath = $null,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

function Archive-CompletedTasksWithTests {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,

        [Parameter(Mandatory = $true)]
        [string]$ArchivePath,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # Vérifier si le fichier de roadmap existe
    if (-not (Test-Path -Path $RoadmapPath)) {
        throw "Le fichier de roadmap '$RoadmapPath' n'existe pas."
    }

    # Lire le contenu du fichier de roadmap
    $content = Get-Content -Path $RoadmapPath -Encoding UTF8

    # Créer ou lire le fichier d'archive
    if (Test-Path -Path $ArchivePath) {
        $archiveContent = Get-Content -Path $ArchivePath -Encoding UTF8
    } else {
        $archiveContent = @(
            "# Archive des tâches terminées",
            "",
            "Ce fichier contient les tâches terminées qui ont été archivées de la roadmap principale.",
            "",
            "Dernière mise à jour: $(Get-Date -Format 'yyyy-MM-dd')",
            ""
        )
    }

    # Structure pour stocker les tâches terminées
    $completedTasks = @()
    $taskContent = @{}
    $taskIndices = @{}

    # Identifier les tâches terminées
    for ($i = 0; $i -lt $content.Count; $i++) {
        $line = $content[$i]
        Write-Host "Ligne $($i): $line"

        # Détecter les tâches
        if ($line -match '^#### (\d+\.\d+\.\d+) (.+)$') {
            $taskId = $matches[1]
            $taskName = $matches[2]
            Write-Host "Tâche détectée: $taskId $taskName"

            # Vérifier si la tâche est terminée à 100%
            $isCompleted = $false
            $hasTests = $false
            $startIndex = $i
            $endIndex = $i

            for ($j = $i + 1; $j -lt $content.Count; $j++) {
                # Arrêter la recherche si on atteint une autre tâche
                if ($content[$j] -match '^#### ') {
                    $endIndex = $j - 1
                    break
                }

                # Si on atteint la fin du fichier
                if ($j -eq $content.Count - 1) {
                    $endIndex = $j
                }

                # Vérifier si la tâche est terminée à 100%
                if ($content[$j] -match '^\*\*Progression\*\*: 100%') {
                    Write-Host "Progression 100% trouvée à la ligne $($j): $($content[$j])"
                    $isCompleted = $true
                }

                # Vérifier si les tests unitaires sont mentionnés
                if ($content[$j] -match 'Tests unitaires|test unitaire|tests unitaires|Tests Unitaires') {
                    $hasTests = $true
                }
            }

            # Si la tâche est terminée à 100% et que les tests unitaires sont mentionnés (ou force est activé)
            Write-Host "Tâche $($taskId): isCompleted=$($isCompleted), hasTests=$($hasTests), Force=$($Force)"
            if ($isCompleted -and ($hasTests -or $Force.IsPresent)) {
                Write-Host "Tâche terminée trouvée: $taskId $taskName"

                $completedTasks += @{
                    id         = $taskId
                    name       = $taskName
                    startIndex = $startIndex
                    endIndex   = $endIndex
                }

                # Extraire le contenu de la tâche
                $taskContent[$taskId] = $content[$startIndex..$endIndex]
                $taskIndices[$taskId] = @{
                    start = $startIndex
                    end   = $endIndex
                }
            }
        }
    }

    # Si aucune tâche terminée n'est trouvée, sortir
    if ($completedTasks.Count -eq 0) {
        Write-Host "Aucune tâche terminée à archiver."
        return
    }

    # Ajouter les tâches terminées au fichier d'archive
    $archiveContent += ""
    $archiveContent += "## Tâches archivées le $(Get-Date -Format 'yyyy-MM-dd')"
    $archiveContent += ""

    foreach ($task in $completedTasks) {
        $archiveContent += $taskContent[$task.id]
        $archiveContent += ""
    }

    # Remplacer les tâches terminées par des références dans le fichier original
    $newContent = @()
    $skipIndices = @()

    foreach ($taskId in $taskIndices.Keys) {
        $indices = $taskIndices[$taskId]
        $skipIndices += $indices.start..$indices.end
    }

    for ($i = 0; $i -lt $content.Count; $i++) {
        if ($skipIndices -contains $i) {
            # Si c'est le début d'une tâche terminée, ajouter une référence
            foreach ($task in $completedTasks) {
                if ($i -eq $taskIndices[$task.id].start) {
                    $newContent += "#### $($task.id) $($task.name)"
                    $newContent += "**Progression**: 100% - *Terminé*"
                    $newContent += "**Note**: Cette tâche a été archivée. Voir [Archive des tâches](archive/roadmap_archive.md) pour les détails."
                    $newContent += ""
                    break
                }
            }
        } else {
            $newContent += $content[$i]
        }
    }

    # Enregistrer les modifications
    $archiveContent | Out-File -FilePath $ArchivePath -Encoding UTF8
    $newContent | Out-File -FilePath $RoadmapPath -Encoding UTF8

    return @{
        archivedTasks = $completedTasks
        archivePath   = $ArchivePath
    }
}

# Fonction principale
try {
    # Déterminer le chemin d'archive
    if (-not $ArchivePath) {
        $archiveDir = Join-Path -Path (Split-Path -Parent $RoadmapPath) -ChildPath "archive"
        if (-not (Test-Path -Path $archiveDir)) {
            New-Item -Path $archiveDir -ItemType Directory -Force | Out-Null
        }
        $ArchivePath = Join-Path -Path $archiveDir -ChildPath "roadmap_archive.md"
    }

    $result = Archive-CompletedTasksWithTests -RoadmapPath $RoadmapPath -ArchivePath $ArchivePath -Force:$Force

    if ($result) {
        Write-Host "Archivage des tâches terminées réussi."
        Write-Host "$($result.archivedTasks.Count) tâches archivées dans '$($result.archivePath)'."

        # Afficher les tâches archivées
        if ($result.archivedTasks.Count -gt 0) {
            Write-Host "`nTâches archivées:"
            foreach ($task in $result.archivedTasks) {
                Write-Host "  $($task.id) $($task.name)"
            }
        }
    }
} catch {
    Write-Error "Erreur lors de l'archivage des tâches terminées: $_"
}
