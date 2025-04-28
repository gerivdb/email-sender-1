#Requires -Version 5.1
<#
.SYNOPSIS
    Archive les tÃ¢ches complÃ©tÃ©es Ã  100% avec tests unitaires effectuÃ©s.
.DESCRIPTION
    Ce script identifie les tÃ¢ches marquÃ©es comme complÃ©tÃ©es Ã  100% dans le roadmap,
    vÃ©rifie que les tests unitaires ont Ã©tÃ© effectuÃ©s et que les corrections nÃ©cessaires
    ont Ã©tÃ© apportÃ©es, puis les archive automatiquement.
.PARAMETER RoadmapPath
    Chemin vers le fichier Markdown de la roadmap.
.PARAMETER ArchivePath
    Chemin vers le fichier d'archive. Si non spÃ©cifiÃ©, le fichier sera crÃ©Ã© au mÃªme
    emplacement que le fichier de roadmap avec le nom "roadmap_archive.md".
.PARAMETER Force
    Force l'archivage mÃªme si les tests unitaires ne sont pas explicitement mentionnÃ©s.
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

    # VÃ©rifier si le fichier de roadmap existe
    if (-not (Test-Path -Path $RoadmapPath)) {
        throw "Le fichier de roadmap '$RoadmapPath' n'existe pas."
    }

    # Lire le contenu du fichier de roadmap
    $content = Get-Content -Path $RoadmapPath -Encoding UTF8

    # CrÃ©er ou lire le fichier d'archive
    if (Test-Path -Path $ArchivePath) {
        $archiveContent = Get-Content -Path $ArchivePath -Encoding UTF8
    } else {
        $archiveContent = @(
            "# Archive des tÃ¢ches terminÃ©es",
            "",
            "Ce fichier contient les tÃ¢ches terminÃ©es qui ont Ã©tÃ© archivÃ©es de la roadmap principale.",
            "",
            "DerniÃ¨re mise Ã  jour: $(Get-Date -Format 'yyyy-MM-dd')",
            ""
        )
    }

    # Structure pour stocker les tÃ¢ches terminÃ©es
    $completedTasks = @()
    $taskContent = @{}
    $taskIndices = @{}

    # Identifier les tÃ¢ches terminÃ©es
    for ($i = 0; $i -lt $content.Count; $i++) {
        $line = $content[$i]
        Write-Host "Ligne $($i): $line"

        # DÃ©tecter les tÃ¢ches
        if ($line -match '^#### (\d+\.\d+\.\d+) (.+)$') {
            $taskId = $matches[1]
            $taskName = $matches[2]
            Write-Host "TÃ¢che dÃ©tectÃ©e: $taskId $taskName"

            # VÃ©rifier si la tÃ¢che est terminÃ©e Ã  100%
            $isCompleted = $false
            $hasTests = $false
            $startIndex = $i
            $endIndex = $i

            for ($j = $i + 1; $j -lt $content.Count; $j++) {
                # ArrÃªter la recherche si on atteint une autre tÃ¢che
                if ($content[$j] -match '^#### ') {
                    $endIndex = $j - 1
                    break
                }

                # Si on atteint la fin du fichier
                if ($j -eq $content.Count - 1) {
                    $endIndex = $j
                }

                # VÃ©rifier si la tÃ¢che est terminÃ©e Ã  100%
                if ($content[$j] -match '^\*\*Progression\*\*: 100%') {
                    Write-Host "Progression 100% trouvÃ©e Ã  la ligne $($j): $($content[$j])"
                    $isCompleted = $true
                }

                # VÃ©rifier si les tests unitaires sont mentionnÃ©s
                if ($content[$j] -match 'Tests unitaires|test unitaire|tests unitaires|Tests Unitaires') {
                    $hasTests = $true
                }
            }

            # Si la tÃ¢che est terminÃ©e Ã  100% et que les tests unitaires sont mentionnÃ©s (ou force est activÃ©)
            Write-Host "TÃ¢che $($taskId): isCompleted=$($isCompleted), hasTests=$($hasTests), Force=$($Force)"
            if ($isCompleted -and ($hasTests -or $Force.IsPresent)) {
                Write-Host "TÃ¢che terminÃ©e trouvÃ©e: $taskId $taskName"

                $completedTasks += @{
                    id         = $taskId
                    name       = $taskName
                    startIndex = $startIndex
                    endIndex   = $endIndex
                }

                # Extraire le contenu de la tÃ¢che
                $taskContent[$taskId] = $content[$startIndex..$endIndex]
                $taskIndices[$taskId] = @{
                    start = $startIndex
                    end   = $endIndex
                }
            }
        }
    }

    # Si aucune tÃ¢che terminÃ©e n'est trouvÃ©e, sortir
    if ($completedTasks.Count -eq 0) {
        Write-Host "Aucune tÃ¢che terminÃ©e Ã  archiver."
        return
    }

    # Ajouter les tÃ¢ches terminÃ©es au fichier d'archive
    $archiveContent += ""
    $archiveContent += "## TÃ¢ches archivÃ©es le $(Get-Date -Format 'yyyy-MM-dd')"
    $archiveContent += ""

    foreach ($task in $completedTasks) {
        $archiveContent += $taskContent[$task.id]
        $archiveContent += ""
    }

    # Remplacer les tÃ¢ches terminÃ©es par des rÃ©fÃ©rences dans le fichier original
    $newContent = @()
    $skipIndices = @()

    foreach ($taskId in $taskIndices.Keys) {
        $indices = $taskIndices[$taskId]
        $skipIndices += $indices.start..$indices.end
    }

    for ($i = 0; $i -lt $content.Count; $i++) {
        if ($skipIndices -contains $i) {
            # Si c'est le dÃ©but d'une tÃ¢che terminÃ©e, ajouter une rÃ©fÃ©rence
            foreach ($task in $completedTasks) {
                if ($i -eq $taskIndices[$task.id].start) {
                    $newContent += "#### $($task.id) $($task.name)"
                    $newContent += "**Progression**: 100% - *TerminÃ©*"
                    $newContent += "**Note**: Cette tÃ¢che a Ã©tÃ© archivÃ©e. Voir [Archive des tÃ¢ches](archive/roadmap_archive.md) pour les dÃ©tails."
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
    # DÃ©terminer le chemin d'archive
    if (-not $ArchivePath) {
        $archiveDir = Join-Path -Path (Split-Path -Parent $RoadmapPath) -ChildPath "archive"
        if (-not (Test-Path -Path $archiveDir)) {
            New-Item -Path $archiveDir -ItemType Directory -Force | Out-Null
        }
        $ArchivePath = Join-Path -Path $archiveDir -ChildPath "roadmap_archive.md"
    }

    $result = Archive-CompletedTasksWithTests -RoadmapPath $RoadmapPath -ArchivePath $ArchivePath -Force:$Force

    if ($result) {
        Write-Host "Archivage des tÃ¢ches terminÃ©es rÃ©ussi."
        Write-Host "$($result.archivedTasks.Count) tÃ¢ches archivÃ©es dans '$($result.archivePath)'."

        # Afficher les tÃ¢ches archivÃ©es
        if ($result.archivedTasks.Count -gt 0) {
            Write-Host "`nTÃ¢ches archivÃ©es:"
            foreach ($task in $result.archivedTasks) {
                Write-Host "  $($task.id) $($task.name)"
            }
        }
    }
} catch {
    Write-Error "Erreur lors de l'archivage des tÃ¢ches terminÃ©es: $_"
}
