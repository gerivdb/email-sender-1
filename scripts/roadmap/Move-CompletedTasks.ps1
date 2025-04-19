<#
.SYNOPSIS
    Déplace les tâches terminées d'une roadmap vers un fichier d'archive.

.DESCRIPTION
    Ce script analyse un fichier de roadmap au format Markdown, identifie les tâches
    terminées (100% de progression), les déplace vers un fichier d'archive et les
    remplace par des références dans le fichier original.

.PARAMETER MarkdownPath
    Chemin vers le fichier Markdown de la roadmap.

.PARAMETER ArchivePath
    Chemin vers le fichier d'archive. Si non spécifié, le fichier sera créé au même
    emplacement que le fichier de roadmap avec le nom "completed_tasks.md".

.EXAMPLE
    .\Move-CompletedTasks.ps1 -MarkdownPath "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\roadmap_complete.md"

.NOTES
    Auteur: Équipe DevOps
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

    # Vérifier si le fichier de roadmap existe
    if (-not (Test-Path -Path $MarkdownPath)) {
        throw "Le fichier de roadmap '$MarkdownPath' n'existe pas."
    }

    # Lire le contenu du fichier de roadmap
    $content = Get-Content -Path $MarkdownPath -Encoding UTF8

    # Créer ou lire le fichier d'archive
    if (Test-Path -Path $ArchivePath) {
        $archiveContent = Get-Content -Path $ArchivePath -Encoding UTF8
    }
    else {
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
        
        # Détecter les tâches
        if ($line -match '^#### (\d+\.\d+\.\d+) (.+)$') {
            $taskId = $matches[1]
            $taskName = $matches[2]
            
            # Vérifier si la tâche est terminée
            $isCompleted = $false
            for ($j = $i + 1; $j -lt $content.Count; $j++) {
                if ($content[$j] -match '^\*\*Progression\*\*: 100% - \*Terminé\*$') {
                    $isCompleted = $true
                    break
                }
                
                # Arrêter la recherche si on atteint une autre tâche
                if ($content[$j] -match '^#### ') {
                    break
                }
            }
            
            if ($isCompleted) {
                $completedTasks += @{
                    id = $taskId
                    name = $taskName
                    startIndex = $i
                    endIndex = $i
                }
                
                # Trouver la fin de la tâche
                for ($j = $i + 1; $j -lt $content.Count; $j++) {
                    if ($j -eq $content.Count - 1 || $content[$j + 1] -match '^#### ') {
                        $completedTasks[-1].endIndex = $j
                        break
                    }
                }
                
                # Extraire le contenu de la tâche
                $taskContent[$taskId] = $content[$i..$completedTasks[-1].endIndex]
                $taskIndices[$taskId] = @{
                    start = $i
                    end = $completedTasks[-1].endIndex
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
                    $newContent += "**Note**: Cette tâche a été archivée. Voir `$ArchivePath` pour les détails."
                    $newContent += ""
                    break
                }
            }
        }
        else {
            $newContent += $content[$i]
        }
    }

    # Enregistrer les modifications
    $archiveContent | Out-File -FilePath $ArchivePath -Encoding UTF8
    $newContent | Out-File -FilePath $MarkdownPath -Encoding UTF8
    
    return @{
        archivedTasks = $completedTasks
        archivePath = $ArchivePath
    }
}

# Fonction principale
try {
    # Déterminer le chemin d'archive
    if (-not $ArchivePath) {
        $ArchivePath = Join-Path -Path (Split-Path -Parent $MarkdownPath) -ChildPath "completed_tasks.md"
    }
    
    $result = Move-CompletedTasksToArchive -MarkdownPath $MarkdownPath -ArchivePath $ArchivePath
    
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
catch {
    Write-Error "Erreur lors de l'archivage des tâches terminées: $_"
}
