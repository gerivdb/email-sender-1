<#
.SYNOPSIS
    DÃ©place les tÃ¢ches terminÃ©es d'une roadmap vers un fichier d'archive.

.DESCRIPTION
    Ce script analyse un fichier de roadmap au format Markdown, identifie les tÃ¢ches
    terminÃ©es (100% de progression), les dÃ©place vers un fichier d'archive et les
    remplace par des rÃ©fÃ©rences dans le fichier original.

.PARAMETER MarkdownPath
    Chemin vers le fichier Markdown de la roadmap.

.PARAMETER ArchivePath
    Chemin vers le fichier d'archive. Si non spÃ©cifiÃ©, le fichier sera crÃ©Ã© au mÃªme
    emplacement que le fichier de roadmap avec le nom "completed_tasks.md".

.EXAMPLE
    .\Move-CompletedTasks.ps1 -MarkdownPath "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\roadmap_complete.md"

.NOTES
    Auteur: Ã‰quipe DevOps
    Date: 2025-04-20
    Version: 1.0.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$MarkdownPath,

    [Parameter(Mandatory = $false)]
    [string]$ArchivePath = $null
)

function Move-CompletedTasksToArchive {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$MarkdownPath,

        [Parameter(Mandatory = $true)]
        [string]$ArchivePath
    )

    # VÃ©rifier si le fichier de roadmap existe
    if (-not (Test-Path -Path $MarkdownPath)) {
        throw "Le fichier de roadmap '$MarkdownPath' n'existe pas."
    }

    # Lire le contenu du fichier de roadmap
    $content = Get-Content -Path $MarkdownPath -Encoding UTF8

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

        # DÃ©tecter les tÃ¢ches
        Write-Host "Ligne: $line"
        if ($line -match '^#### (\d+\.\d+\.\d+) (.+)$') {
            $taskId = $matches[1]
            $taskName = $matches[2]

            # VÃ©rifier si la tÃ¢che est terminÃ©e
            $isCompleted = $false
            for ($j = $i + 1; $j -lt $content.Count; $j++) {
                Write-Host "VÃ©rification ligne: $($content[$j])"
                if ($content[$j] -match '^\*\*Progression\*\*: 100% - \*TerminÃ©\*$') {
                    $isCompleted = $true
                    Write-Host "TÃ¢che terminÃ©e trouvÃ©e: $taskId $taskName"
                    break
                }

                # ArrÃªter la recherche si on atteint une autre tÃ¢che
                if ($content[$j] -match '^#### ') {
                    break
                }
            }

            if ($isCompleted) {
                $completedTasks += @{
                    id         = $taskId
                    name       = $taskName
                    startIndex = $i
                    endIndex   = $i
                }

                # Trouver la fin de la tÃ¢che
                for ($j = $i + 1; $j -lt $content.Count; $j++) {
                    if (($j -eq $content.Count - 1) -or ($content[$j + 1] -match '^#### ')) {
                        $completedTasks[-1].endIndex = $j
                        break
                    }
                }

                # Extraire le contenu de la tÃ¢che
                $taskContent[$taskId] = $content[$i..$completedTasks[-1].endIndex]
                $taskIndices[$taskId] = @{
                    start = $i
                    end   = $completedTasks[-1].endIndex
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
                    $newContent += "**Note**: Cette tÃ¢che a Ã©tÃ© archivÃ©e. Voir `$ArchivePath` pour les dÃ©tails."
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
    $newContent | Out-File -FilePath $MarkdownPath -Encoding UTF8

    return @{
        archivedTasks = $completedTasks
        archivePath   = $ArchivePath
    }
}

# Fonction principale
try {
    # DÃ©terminer le chemin d'archive
    if (-not $ArchivePath) {
        $ArchivePath = Join-Path -Path (Split-Path -Parent $MarkdownPath) -ChildPath "completed_tasks.md"
    }

    $result = Move-CompletedTasksToArchive -MarkdownPath $MarkdownPath -ArchivePath $ArchivePath

    Write-Host "Archivage des tÃ¢ches terminÃ©es rÃ©ussi."
    Write-Host "$($result.archivedTasks.Count) tÃ¢ches archivÃ©es dans '$($result.archivePath)'."

    # Afficher les tÃ¢ches archivÃ©es
    if ($result.archivedTasks.Count -gt 0) {
        Write-Host "`nTÃ¢ches archivÃ©es:"
        foreach ($task in $result.archivedTasks) {
            Write-Host "  $($task.id) $($task.name)"
        }
    }
} catch {
    Write-Error "Erreur lors de l'archivage des tÃ¢ches terminÃ©es: $_"
}
