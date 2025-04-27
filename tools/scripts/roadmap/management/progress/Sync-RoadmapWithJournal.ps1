#Requires -Version 5.1
<#
.SYNOPSIS
    Synchronise la roadmap Markdown avec le systÃ¨me de journalisation JSON.
.DESCRIPTION
    Ce script permet une synchronisation bidirectionnelle entre le fichier Markdown
    de la roadmap et les entrÃ©es JSON du systÃ¨me de journalisation.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-04-16
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapPath = "Roadmap\roadmap_final.md",

    [Parameter(Mandatory = $false)]
    [ValidateSet("ToJournal", "ToRoadmap", "Bidirectional")]
    [string]$Direction = "Bidirectional",

    [Parameter(Mandatory = $false)]
    [switch]$CreateBackup
)

# Importer le module de gestion du journal
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\RoadmapJournalManager.psm1"
Import-Module $modulePath -Force

# Chemins des fichiers et dossiers
$journalRoot = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Roadmap\journal"
$indexPath = Join-Path -Path $journalRoot -ChildPath "index.json"
$metadataPath = Join-Path -Path $journalRoot -ChildPath "metadata.json"
$backupFolder = Join-Path -Path $journalRoot -ChildPath "backups"

# CrÃ©er le dossier de sauvegarde si nÃ©cessaire
if ($CreateBackup -and -not (Test-Path -Path $backupFolder)) {
    New-Item -Path $backupFolder -ItemType Directory -Force | Out-Null
}

# Fonction pour crÃ©er une sauvegarde
function New-Backup {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    if ($CreateBackup) {
        $fileName = [System.IO.Path]::GetFileName($FilePath)
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupPath = Join-Path -Path $backupFolder -ChildPath "${fileName}.${timestamp}.bak"

        Copy-Item -Path $FilePath -Destination $backupPath -Force
        Write-Host "Sauvegarde crÃ©Ã©e: $backupPath"
    }
}

# Fonction pour mettre Ã  jour la roadmap Ã  partir du journal
function Update-RoadmapFromJournal {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath
    )

    # VÃ©rifier si le fichier de roadmap existe
    if (-not (Test-Path -Path $RoadmapPath)) {
        Write-Error "Le fichier de roadmap '$RoadmapPath' n'existe pas."
        return $false
    }

    # CrÃ©er une sauvegarde
    New-Backup -FilePath $RoadmapPath

    # Lire le contenu du fichier de roadmap
    $roadmapContent = Get-Content -Path $RoadmapPath -Raw
    $roadmapLines = $roadmapContent -split "`n"

    # Charger l'index du journal
    $index = Get-Content -Path $indexPath -Raw | ConvertFrom-Json

    # Pour chaque entrÃ©e dans l'index
    foreach ($entryId in $index.entries.PSObject.Properties.Name) {
        $entryPath = $index.entries.$entryId
        $entry = Get-Content -Path $entryPath -Raw | ConvertFrom-Json

        # Rechercher la section correspondante dans la roadmap
        $taskHeaderPattern = "^###\s+$([regex]::Escape($entryId))\s+"
        $taskHeaderIndex = -1

        for ($i = 0; $i -lt $roadmapLines.Count; $i++) {
            if ($roadmapLines[$i] -match $taskHeaderPattern) {
                $taskHeaderIndex = $i
                break
            }
        }

        # Si la tÃ¢che existe dans la roadmap, mettre Ã  jour ses mÃ©tadonnÃ©es
        if ($taskHeaderIndex -ge 0) {
            # Mettre Ã  jour le titre
            $roadmapLines[$taskHeaderIndex] = "### $entryId $($entry.title)"

            # Rechercher et mettre Ã  jour les mÃ©tadonnÃ©es
            for ($i = $taskHeaderIndex + 1; $i -lt $roadmapLines.Count; $i++) {
                # ArrÃªter si on atteint une autre section
                if ($roadmapLines[$i] -match "^#{1,3}\s+") {
                    break
                }

                # Mettre Ã  jour la complexitÃ©
                if ($roadmapLines[$i] -match "^\*\*ComplexitÃ©\*\*:") {
                    $complexity = switch ($entry.metadata.complexity) {
                        1 { "Faible" }
                        3 { "Moyenne" }
                        5 { "Ã‰levÃ©e" }
                        default { "Moyenne" }
                    }
                    $roadmapLines[$i] = "**ComplexitÃ©**: $complexity"
                }

                # Mettre Ã  jour le temps estimÃ©
                elseif ($roadmapLines[$i] -match "^\*\*Temps estimÃ©\*\*:") {
                    $hours = $entry.metadata.estimatedHours
                    $timeEstimate = if ($hours -ge 40) {
                        "$([math]::Round($hours / 40)) semaines"
                    } elseif ($hours -ge 8) {
                        "$([math]::Round($hours / 8)) jours"
                    } else {
                        "$hours heures"
                    }
                    $roadmapLines[$i] = "**Temps estimÃ©**: $timeEstimate"
                }

                # Mettre Ã  jour la progression
                elseif ($roadmapLines[$i] -match "^\*\*Progression\*\*:") {
                    $status = switch ($entry.status) {
                        "NotStarted" { "Ã€ commencer" }
                        "InProgress" { "En cours" }
                        "Completed" { "TerminÃ©" }
                        "Blocked" { "BloquÃ©" }
                        default { "Ã€ commencer" }
                    }
                    $roadmapLines[$i] = "**Progression**: $($entry.metadata.progress)% - *$status*"
                }

                # Mettre Ã  jour la date de dÃ©but
                elseif ($roadmapLines[$i] -match "^\*\*Date de dÃ©but\*\*:") {
                    $startDate = if ($entry.metadata.startDate) {
                        try {
                            [DateTime]::Parse($entry.metadata.startDate).ToString("dd/MM/yyyy")
                        } catch {
                            "-"
                        }
                    } else {
                        "-"
                    }
                    $roadmapLines[$i] = "**Date de dÃ©but**: $startDate"
                }

                # Mettre Ã  jour la date d'achÃ¨vement prÃ©vue
                elseif ($roadmapLines[$i] -match "^\*\*Date d'achÃ¨vement prÃ©vue\*\*:") {
                    $dueDate = if ($entry.metadata.dueDate) {
                        try {
                            [DateTime]::Parse($entry.metadata.dueDate).ToString("dd/MM/yyyy")
                        } catch {
                            "-"
                        }
                    } else {
                        "-"
                    }
                    $roadmapLines[$i] = "**Date d'achÃ¨vement prÃ©vue**: $dueDate"
                }

                # Mettre Ã  jour la date d'achÃ¨vement rÃ©elle
                elseif ($roadmapLines[$i] -match "^\*\*Date d'achÃ¨vement\*\*:") {
                    $completionDate = if ($entry.metadata.completionDate) {
                        try {
                            [DateTime]::Parse($entry.metadata.completionDate).ToString("dd/MM/yyyy")
                        } catch {
                            "-"
                        }
                    } else {
                        "-"
                    }
                    $roadmapLines[$i] = "**Date d'achÃ¨vement**: $completionDate"
                }

                # Mettre Ã  jour l'objectif (description)
                elseif ($roadmapLines[$i] -match "^\*\*Objectif\*\*:") {
                    $roadmapLines[$i] = "**Objectif**: $($entry.description)"
                }
            }
        } else {
            # La tÃ¢che n'existe pas dans la roadmap, on pourrait l'ajouter ici
            # mais cela nÃ©cessiterait une logique plus complexe pour dÃ©terminer oÃ¹ l'insÃ©rer
            Write-Warning "La tÃ¢che $entryId n'a pas Ã©tÃ© trouvÃ©e dans la roadmap. Ajout manuel requis."
        }
    }

    # Ã‰crire le contenu mis Ã  jour dans le fichier de roadmap
    $roadmapLines -join "`n" | Out-File -FilePath $RoadmapPath -Encoding utf8 -Force

    # Mettre Ã  jour les mÃ©tadonnÃ©es du journal
    $metadata = Get-Content -Path $metadataPath -Raw | ConvertFrom-Json
    $metadata.lastSync = (Get-Date).ToUniversalTime().ToString("o")
    $metadata | ConvertTo-Json -Depth 10 | Out-File -FilePath $metadataPath -Encoding utf8 -Force

    Write-Host "Roadmap mise Ã  jour avec succÃ¨s Ã  partir du journal."
    return $true
}

# Fonction pour mettre Ã  jour le journal Ã  partir de la roadmap
function Update-JournalFromRoadmap {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath
    )

    # VÃ©rifier si le fichier de roadmap existe
    if (-not (Test-Path -Path $RoadmapPath)) {
        Write-Error "Le fichier de roadmap '$RoadmapPath' n'existe pas."
        return $false
    }

    # CrÃ©er une sauvegarde de l'index
    New-Backup -FilePath $indexPath

    # Lire le contenu du fichier de roadmap
    # Utiliser directement le script d'importation

    # Utiliser le script d'importation pour extraire les tÃ¢ches
    $importScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Import-ExistingRoadmapToJournal.ps1"
    & $importScriptPath -RoadmapPath $RoadmapPath -Force

    # Mettre Ã  jour les mÃ©tadonnÃ©es du journal
    $metadata = Get-Content -Path $metadataPath -Raw | ConvertFrom-Json
    $metadata.lastSync = (Get-Date).ToUniversalTime().ToString("o")
    $metadata | ConvertTo-Json -Depth 10 | Out-File -FilePath $metadataPath -Encoding utf8 -Force

    Write-Host "Journal mis Ã  jour avec succÃ¨s Ã  partir de la roadmap."
    return $true
}

# ExÃ©cuter la synchronisation selon la direction spÃ©cifiÃ©e
switch ($Direction) {
    "ToJournal" {
        Update-JournalFromRoadmap -RoadmapPath $RoadmapPath
    }
    "ToRoadmap" {
        Update-RoadmapFromJournal -RoadmapPath $RoadmapPath
    }
    "Bidirectional" {
        # Pour une synchronisation bidirectionnelle, nous mettons d'abord Ã  jour le journal,
        # puis la roadmap Ã  partir du journal mis Ã  jour
        Update-JournalFromRoadmap -RoadmapPath $RoadmapPath
        Update-RoadmapFromJournal -RoadmapPath $RoadmapPath
    }
}
