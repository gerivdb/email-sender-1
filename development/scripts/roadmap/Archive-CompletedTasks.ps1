# Archive-CompletedTasks.ps1
# Script pour archiver les tâches terminées de la roadmap active
# Version: 1.0
# Date: 2025-05-02

[CmdletBinding()]
param (
    [Parameter()]
    [string]$RoadmapPath = "projet\roadmaps\active\roadmap_active.md",

    [Parameter()]
    [string]$ArchivePath = "projet\roadmaps\archive\roadmap_archive.md",

    [Parameter()]
    [switch]$UpdateVectorDB,

    [Parameter()]
    [string]$QdrantUrl = "http://localhost:6333",

    [Parameter()]
    [string]$CollectionName = "roadmap_tasks",

    [Parameter()]
    [switch]$Force
)

# Importer les modules communs
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$commonPath = Join-Path -Path $scriptPath -ChildPath "..\common"
$modulePath = Join-Path -Path $commonPath -ChildPath "RoadmapModule.psm1"

if (Test-Path $modulePath) {
    Import-Module $modulePath -Force
} else {
    Write-Error "Module commun introuvable: $modulePath"
    exit 1
}

function Test-FileExists {
    param (
        [string]$FilePath
    )

    if (-not (Test-Path -Path $FilePath)) {
        Write-Log "Le fichier $FilePath n'existe pas." -Level Error
        return $false
    }

    return $true
}

function Get-CompletedTasks {
    param (
        [string]$RoadmapContent
    )

    $completedTasks = @()
    $lines = $RoadmapContent -split "`n"
    $currentSection = ""

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        # Détecter les sections
        if ($line -match "^#+\s+(.+)$") {
            $currentSection = $matches[1].Trim()
        }

        # Détecter les tâches terminées
        if ($line -match "^\s*-\s+\[x\]\s+\*\*([^*]+)\*\*\s*(.*)$") {
            $taskId = $matches[1].Trim()
            $taskDescription = $matches[2].Trim()

            # Déterminer le niveau d'indentation
            $indentLevel = 0
            if ($line -match "^(\s*)") {
                $indentLevel = [math]::Floor($matches[1].Length / 2)
            }

            # Ajouter la tâche à la liste des tâches terminées
            $completedTasks += [PSCustomObject]@{
                Id          = $taskId
                Description = $taskDescription
                Section     = $currentSection
                Line        = $i
                IndentLevel = $indentLevel
                FullLine    = $line
            }
        }
    }

    return $completedTasks
}

function Get-TaskWithChildren {
    param (
        [string[]]$Lines,
        [int]$TaskLine,
        [int]$TaskIndentLevel
    )

    $taskLines = @($Lines[$TaskLine])
    $i = $TaskLine + 1

    while ($i -lt $Lines.Count) {
        $line = $Lines[$i]

        # Détecter le niveau d'indentation
        $indentLevel = 0
        if ($line -match "^(\s*)") {
            $indentLevel = [math]::Floor($matches[1].Length / 2)
        }

        # Si le niveau d'indentation est inférieur ou égal à celui de la tâche principale,
        # nous avons atteint la fin des sous-tâches
        if ($line -match "^\s*-\s+\[" -and $indentLevel -le $TaskIndentLevel) {
            break
        }

        # Ajouter la ligne aux lignes de la tâche
        $taskLines += $line
        $i++
    }

    return $taskLines
}

function Update-RoadmapFiles {
    param (
        [string]$RoadmapContent,
        [string]$ArchiveContent,
        [array]$CompletedTasks,
        [string]$RoadmapPath,
        [string]$ArchivePath
    )

    # Créer le répertoire d'archive s'il n'existe pas
    $archiveDir = Split-Path -Parent $ArchivePath
    if (-not (Test-Path -Path $archiveDir)) {
        New-Item -Path $archiveDir -ItemType Directory -Force | Out-Null
    }

    # Créer le fichier d'archive s'il n'existe pas
    if (-not (Test-Path -Path $ArchivePath)) {
        $archiveHeader = "# Roadmap Archive`n`n## Tâches archivées`n`n"
        Set-Content -Path $ArchivePath -Value $archiveHeader -Encoding UTF8
    }

    # Lire le contenu du fichier d'archive
    $archiveContent = Get-Content -Path $ArchivePath -Raw

    # Lire le contenu du fichier de roadmap
    $roadmapLines = $RoadmapContent -split "`n"

    # Trier les tâches par ligne (de la plus grande à la plus petite)
    # pour éviter de décaler les indices lors de la suppression
    $CompletedTasks = $CompletedTasks | Sort-Object -Property Line -Descending

    # Parcourir les tâches terminées
    foreach ($task in $CompletedTasks) {
        # Récupérer la tâche et ses sous-tâches
        $taskLines = Get-TaskWithChildren -Lines $roadmapLines -TaskLine $task.Line -TaskIndentLevel $task.IndentLevel

        # Ajouter la tâche et ses sous-tâches au fichier d'archive
        $archiveContent = $archiveContent.TrimEnd() + "`n`n" + ($taskLines -join "`n")

        # Supprimer la tâche et ses sous-tâches du fichier de roadmap
        $roadmapLines = $roadmapLines[0..($task.Line - 1)] + $roadmapLines[($task.Line + $taskLines.Count)..($roadmapLines.Count - 1)]
    }

    # Mettre à jour le fichier de roadmap
    $roadmapContent = $roadmapLines -join "`n"
    Set-Content -Path $RoadmapPath -Value $roadmapContent -Encoding UTF8

    # Mettre à jour le fichier d'archive
    Set-Content -Path $ArchivePath -Value $archiveContent -Encoding UTF8

    return @{
        RoadmapContent = $roadmapContent
        ArchiveContent = $archiveContent
    }
}

function Update-VectorDatabase {
    param (
        [string]$RoadmapPath,
        [string]$QdrantUrl,
        [string]$CollectionName
    )

    # Appeler le script d'indexation pour mettre à jour la base de données vectorielle
    $indexScriptPath = Join-Path -Path $scriptPath -ChildPath "Index-TaskVectorsQdrant.ps1"

    if (Test-Path $indexScriptPath) {
        Write-Log "Mise à jour de la base de données vectorielle..." -Level Info
        & $indexScriptPath -RoadmapPath $RoadmapPath -QdrantUrl $QdrantUrl -CollectionName $CollectionName -Force:$Force

        if ($LASTEXITCODE -eq 0) {
            Write-Log "Base de données vectorielle mise à jour avec succès." -Level Success
            return $true
        } else {
            Write-Log "Échec de la mise à jour de la base de données vectorielle." -Level Error
            return $false
        }
    } else {
        Write-Log "Script d'indexation introuvable: $indexScriptPath" -Level Error
        return $false
    }
}

function Invoke-TaskArchiving {
    # Vérifier si les fichiers existent
    if (-not (Test-FileExists -FilePath $RoadmapPath)) {
        return
    }

    # Lire le contenu du fichier de roadmap
    $roadmapContent = Get-Content -Path $RoadmapPath -Raw

    # Récupérer les tâches terminées
    $completedTasks = Get-CompletedTasks -RoadmapContent $roadmapContent

    # Vérifier s'il y a des tâches terminées à archiver
    if ($completedTasks.Count -eq 0) {
        Write-Log "Aucune tâche terminée à archiver." -Level Info
        return
    }

    # Afficher les tâches terminées
    Write-Log "Tâches terminées à archiver:" -Level Info
    foreach ($task in $completedTasks) {
        Write-Log "- $($task.Id): $($task.Description)" -Level Info
    }

    # Demander confirmation
    if (-not $Force) {
        $confirmation = Read-Host "Voulez-vous archiver ces $($completedTasks.Count) tâches? (O/N)"
        if ($confirmation -ne "O") {
            Write-Log "Opération annulée." -Level Warning
            return
        }
    }

    # Mettre à jour les fichiers
    $result = Update-RoadmapFiles -RoadmapContent $roadmapContent -ArchiveContent "" -CompletedTasks $completedTasks -RoadmapPath $RoadmapPath -ArchivePath $ArchivePath

    # Afficher le résultat
    Write-Log "Archivage terminé." -Level Success
    Write-Log "$($completedTasks.Count) tâches archivées." -Level Info
    Write-Log "Fichier de roadmap mis à jour: $RoadmapPath" -Level Info
    Write-Log "Fichier d'archive mis à jour: $ArchivePath" -Level Info

    # Mettre à jour la base de données vectorielle si demandé
    if ($UpdateVectorDB) {
        Update-VectorDatabase -RoadmapPath $RoadmapPath -QdrantUrl $QdrantUrl -CollectionName $CollectionName
    }
}

# Exécuter la fonction principale
Invoke-TaskArchiving
