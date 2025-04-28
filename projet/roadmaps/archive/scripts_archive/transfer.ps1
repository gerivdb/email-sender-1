<#
.SYNOPSIS
Transfert les sections terminées de la roadmap vers le fichier d'archive
#>

param (
    [switch]$DryRun,
    [string]$RoadmapFile = "..\roadmap_complete_converted.md",
    [string]$ArchiveFile = "roadmap_archive.md"
)

$logFile = "logs\transfer_$(Get-Date -Format 'yyyyMMdd').log"

function Log-Message {
    param ($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$timestamp] $Message" | Out-File -FilePath $logFile -Append
    Write-Host "[$timestamp] $Message"
}

try {
    # Initialisation
    Log-Message "Début du processus d'archivage"

    if (-not (Test-Path $RoadmapFile)) {
        throw [System.IO.FileNotFoundException]::new("Fichier source introuvable", $RoadmapFile)
    }

    # Lecture et traitement
    $content = Get-Content -Path $RoadmapFile -Raw
    $sections = $content -split "(?m)^##\s"
    $completed = @()
    $remaining = @("## $($sections[0])")

    foreach ($section in $sections[1..($sections.Length-1)]) {
        if ($section -match "\[x\]" -or $section -match "Status\s*:\s*100%\s*Complete") {
            $title = ($section -split '\n')[0]
            $completed += "## $section`n**Archived**: $(Get-Date -Format 'yyyy-MM-dd')`n"
            Log-Message "Section complète détectée: $title"
        } else {
            $remaining += "## $section"
        }
    }

    if ($DryRun) {
        Log-Message "DRY RUN: $($completed.Count) sections à archiver"
        return $completed.Count
    }

    # Archivage
    if ($completed.Count -gt 0) {
        if (-not (Test-Path $ArchiveFile)) {
            New-Item -Path $ArchiveFile -ItemType File -Force | Out-Null
            "# Roadmap Archive`n`n## Introduction`n" | Out-File $ArchiveFile
        }
        $completed | Out-File $ArchiveFile -Append
        $remaining -join "`n" | Out-File $RoadmapFile
        Add-Content $RoadmapFile "`n## Archive`nVoir: [Tâches archivées](archive/roadmap_archive.md)"
        Log-Message "Archivage réussi: $($completed.Count) sections"
    } else {
        Log-Message "Aucune section à archiver"
    }

    return $completed.Count

} catch {
    Log-Message "ERREUR: $($_.Exception.GetType().Name) - $($_.Exception.Message)"
    throw
}
