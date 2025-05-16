# Archive-CompletedTasks.ps1
# Script pour archiver les tÃ¢ches terminÃ©es de la roadmap active
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

        # DÃ©tecter les sections
        if ($line -match "^#+\s+(.+)$") {
            $currentSection = $matches[1].Trim()
        }

        # DÃ©tecter les tÃ¢ches terminÃ©es
        if ($line -match "^\s*-\s+\[x\]\s+\*\*([^*]+)\*\*\s*(.*)$") {
            $taskId = $matches[1].Trim()
            $taskDescription = $matches[2].Trim()

            # DÃ©terminer le niveau d'indentation
            $indentLevel = 0
            if ($line -match "^(\s*)") {
                $indentLevel = [math]::Floor($matches[1].Length / 2)
            }

            # Ajouter la tÃ¢che Ã  la liste des tÃ¢ches terminÃ©es
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

        # DÃ©tecter le niveau d'indentation
        $indentLevel = 0
        if ($line -match "^(\s*)") {
            $indentLevel = [math]::Floor($matches[1].Length / 2)
        }

        # Si le niveau d'indentation est infÃ©rieur ou Ã©gal Ã  celui de la tÃ¢che principale,
        # nous avons atteint la fin des sous-tÃ¢ches
        if ($line -match "^\s*-\s+\[" -and $indentLevel -le $TaskIndentLevel) {
            break
        }

        # Ajouter la ligne aux lignes de la tÃ¢che
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

    # CrÃ©er le rÃ©pertoire d'archive s'il n'existe pas
    $archiveDir = Split-Path -Parent $ArchivePath
    if (-not (Test-Path -Path $archiveDir)) {
        New-Item -Path $archiveDir -ItemType Directory -Force | Out-Null
    }

    # CrÃ©er le fichier d'archive s'il n'existe pas
    if (-not (Test-Path -Path $ArchivePath)) {
        $archiveHeader = "# Roadmap Archive`n`n## TÃ¢ches archivÃ©es`n`n"
        Set-Content -Path $ArchivePath -Value $archiveHeader -Encoding UTF8
    }

    # Lire le contenu du fichier d'archive
    $archiveContent = Get-Content -Path $ArchivePath -Raw

    # Lire le contenu du fichier de roadmap
    $roadmapLines = $RoadmapContent -split "`n"

    # Trier les tÃ¢ches par ligne (de la plus grande Ã  la plus petite)
    # pour Ã©viter de dÃ©caler les indices lors de la suppression
    $CompletedTasks = $CompletedTasks | Sort-Object -Property Line -Descending

    # Parcourir les tÃ¢ches terminÃ©es
    foreach ($task in $CompletedTasks) {
        # RÃ©cupÃ©rer la tÃ¢che et ses sous-tÃ¢ches
        $taskLines = Get-TaskWithChildren -Lines $roadmapLines -TaskLine $task.Line -TaskIndentLevel $task.IndentLevel

        # Ajouter la tÃ¢che et ses sous-tÃ¢ches au fichier d'archive
        $archiveContent = $archiveContent.TrimEnd() + "`n`n" + ($taskLines -join "`n")

        # Supprimer la tÃ¢che et ses sous-tÃ¢ches du fichier de roadmap
        $roadmapLines = $roadmapLines[0..($task.Line - 1)] + $roadmapLines[($task.Line + $taskLines.Count)..($roadmapLines.Count - 1)]
    }

    # Mettre Ã  jour le fichier de roadmap
    $roadmapContent = $roadmapLines -join "`n"
    Set-Content -Path $RoadmapPath -Value $roadmapContent -Encoding UTF8

    # Mettre Ã  jour le fichier d'archive
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

    # Appeler le script d'indexation pour mettre Ã  jour la base de donnÃ©es vectorielle
    $indexScriptPath = Join-Path -Path $scriptPath -ChildPath "Index-TaskVectorsQdrant.ps1"

    if (Test-Path $indexScriptPath) {
        Write-Log "Mise Ã  jour de la base de donnÃ©es vectorielle..." -Level Info
        & $indexScriptPath -RoadmapPath $RoadmapPath -QdrantUrl $QdrantUrl -CollectionName $CollectionName -Force:$Force

        if ($LASTEXITCODE -eq 0) {
            Write-Log "Base de donnÃ©es vectorielle mise Ã  jour avec succÃ¨s." -Level Success
            return $true
        } else {
            Write-Log "Ã‰chec de la mise Ã  jour de la base de donnÃ©es vectorielle." -Level Error
            return $false
        }
    } else {
        Write-Log "Script d'indexation introuvable: $indexScriptPath" -Level Error
        return $false
    }
}

function Invoke-TaskArchiving {
    # VÃ©rifier si les fichiers existent
    if (-not (Test-FileExists -FilePath $RoadmapPath)) {
        return
    }

    # Lire le contenu du fichier de roadmap
    $roadmapContent = Get-Content -Path $RoadmapPath -Raw

    # RÃ©cupÃ©rer les tÃ¢ches terminÃ©es
    $completedTasks = Get-CompletedTasks -RoadmapContent $roadmapContent

    # VÃ©rifier s'il y a des tÃ¢ches terminÃ©es Ã  archiver
    if ($completedTasks.Count -eq 0) {
        Write-Log "Aucune tÃ¢che terminÃ©e Ã  archiver." -Level Info
        return
    }

    # Afficher les tÃ¢ches terminÃ©es
    Write-Log "TÃ¢ches terminÃ©es Ã  archiver:" -Level Info
    foreach ($task in $completedTasks) {
        Write-Log "- $($task.Id): $($task.Description)" -Level Info
    }

    # Demander confirmation
    if (-not $Force) {
        $confirmation = Read-Host "Voulez-vous archiver ces $($completedTasks.Count) tÃ¢ches? (O/N)"
        if ($confirmation -ne "O") {
            Write-Log "OpÃ©ration annulÃ©e." -Level Warning
            return
        }
    }

    # Mettre Ã  jour les fichiers
    $result = Update-RoadmapFiles -RoadmapContent $roadmapContent -ArchiveContent "" -CompletedTasks $completedTasks -RoadmapPath $RoadmapPath -ArchivePath $ArchivePath

    # Afficher le rÃ©sultat
    Write-Log "Archivage terminÃ©." -Level Success
    Write-Log "$($completedTasks.Count) tÃ¢ches archivÃ©es." -Level Info
    Write-Log "Fichier de roadmap mis Ã  jour: $RoadmapPath" -Level Info
    Write-Log "Fichier d'archive mis Ã  jour: $ArchivePath" -Level Info

    # Mettre Ã  jour la base de donnÃ©es vectorielle si demandÃ©
    if ($UpdateVectorDB) {
        Update-VectorDatabase -RoadmapPath $RoadmapPath -QdrantUrl $QdrantUrl -CollectionName $CollectionName
    }
}

# ExÃ©cuter la fonction principale
Invoke-TaskArchiving
