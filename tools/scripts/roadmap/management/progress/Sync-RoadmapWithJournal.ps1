#Requires -Version 5.1
<#
.SYNOPSIS
    Synchronise la roadmap Markdown avec le système de journalisation JSON.
.DESCRIPTION
    Ce script permet une synchronisation bidirectionnelle entre le fichier Markdown
    de la roadmap et les entrées JSON du système de journalisation.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-16
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

# Créer le dossier de sauvegarde si nécessaire
if ($CreateBackup -and -not (Test-Path -Path $backupFolder)) {
    New-Item -Path $backupFolder -ItemType Directory -Force | Out-Null
}

# Fonction pour créer une sauvegarde
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
        Write-Host "Sauvegarde créée: $backupPath"
    }
}

# Fonction pour mettre à jour la roadmap à partir du journal
function Update-RoadmapFromJournal {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath
    )

    # Vérifier si le fichier de roadmap existe
    if (-not (Test-Path -Path $RoadmapPath)) {
        Write-Error "Le fichier de roadmap '$RoadmapPath' n'existe pas."
        return $false
    }

    # Créer une sauvegarde
    New-Backup -FilePath $RoadmapPath

    # Lire le contenu du fichier de roadmap
    $roadmapContent = Get-Content -Path $RoadmapPath -Raw
    $roadmapLines = $roadmapContent -split "`n"

    # Charger l'index du journal
    $index = Get-Content -Path $indexPath -Raw | ConvertFrom-Json

    # Pour chaque entrée dans l'index
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

        # Si la tâche existe dans la roadmap, mettre à jour ses métadonnées
        if ($taskHeaderIndex -ge 0) {
            # Mettre à jour le titre
            $roadmapLines[$taskHeaderIndex] = "### $entryId $($entry.title)"

            # Rechercher et mettre à jour les métadonnées
            for ($i = $taskHeaderIndex + 1; $i -lt $roadmapLines.Count; $i++) {
                # Arrêter si on atteint une autre section
                if ($roadmapLines[$i] -match "^#{1,3}\s+") {
                    break
                }

                # Mettre à jour la complexité
                if ($roadmapLines[$i] -match "^\*\*Complexité\*\*:") {
                    $complexity = switch ($entry.metadata.complexity) {
                        1 { "Faible" }
                        3 { "Moyenne" }
                        5 { "Élevée" }
                        default { "Moyenne" }
                    }
                    $roadmapLines[$i] = "**Complexité**: $complexity"
                }

                # Mettre à jour le temps estimé
                elseif ($roadmapLines[$i] -match "^\*\*Temps estimé\*\*:") {
                    $hours = $entry.metadata.estimatedHours
                    $timeEstimate = if ($hours -ge 40) {
                        "$([math]::Round($hours / 40)) semaines"
                    } elseif ($hours -ge 8) {
                        "$([math]::Round($hours / 8)) jours"
                    } else {
                        "$hours heures"
                    }
                    $roadmapLines[$i] = "**Temps estimé**: $timeEstimate"
                }

                # Mettre à jour la progression
                elseif ($roadmapLines[$i] -match "^\*\*Progression\*\*:") {
                    $status = switch ($entry.status) {
                        "NotStarted" { "À commencer" }
                        "InProgress" { "En cours" }
                        "Completed" { "Terminé" }
                        "Blocked" { "Bloqué" }
                        default { "À commencer" }
                    }
                    $roadmapLines[$i] = "**Progression**: $($entry.metadata.progress)% - *$status*"
                }

                # Mettre à jour la date de début
                elseif ($roadmapLines[$i] -match "^\*\*Date de début\*\*:") {
                    $startDate = if ($entry.metadata.startDate) {
                        try {
                            [DateTime]::Parse($entry.metadata.startDate).ToString("dd/MM/yyyy")
                        } catch {
                            "-"
                        }
                    } else {
                        "-"
                    }
                    $roadmapLines[$i] = "**Date de début**: $startDate"
                }

                # Mettre à jour la date d'achèvement prévue
                elseif ($roadmapLines[$i] -match "^\*\*Date d'achèvement prévue\*\*:") {
                    $dueDate = if ($entry.metadata.dueDate) {
                        try {
                            [DateTime]::Parse($entry.metadata.dueDate).ToString("dd/MM/yyyy")
                        } catch {
                            "-"
                        }
                    } else {
                        "-"
                    }
                    $roadmapLines[$i] = "**Date d'achèvement prévue**: $dueDate"
                }

                # Mettre à jour la date d'achèvement réelle
                elseif ($roadmapLines[$i] -match "^\*\*Date d'achèvement\*\*:") {
                    $completionDate = if ($entry.metadata.completionDate) {
                        try {
                            [DateTime]::Parse($entry.metadata.completionDate).ToString("dd/MM/yyyy")
                        } catch {
                            "-"
                        }
                    } else {
                        "-"
                    }
                    $roadmapLines[$i] = "**Date d'achèvement**: $completionDate"
                }

                # Mettre à jour l'objectif (description)
                elseif ($roadmapLines[$i] -match "^\*\*Objectif\*\*:") {
                    $roadmapLines[$i] = "**Objectif**: $($entry.description)"
                }
            }
        } else {
            # La tâche n'existe pas dans la roadmap, on pourrait l'ajouter ici
            # mais cela nécessiterait une logique plus complexe pour déterminer où l'insérer
            Write-Warning "La tâche $entryId n'a pas été trouvée dans la roadmap. Ajout manuel requis."
        }
    }

    # Écrire le contenu mis à jour dans le fichier de roadmap
    $roadmapLines -join "`n" | Out-File -FilePath $RoadmapPath -Encoding utf8 -Force

    # Mettre à jour les métadonnées du journal
    $metadata = Get-Content -Path $metadataPath -Raw | ConvertFrom-Json
    $metadata.lastSync = (Get-Date).ToUniversalTime().ToString("o")
    $metadata | ConvertTo-Json -Depth 10 | Out-File -FilePath $metadataPath -Encoding utf8 -Force

    Write-Host "Roadmap mise à jour avec succès à partir du journal."
    return $true
}

# Fonction pour mettre à jour le journal à partir de la roadmap
function Update-JournalFromRoadmap {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath
    )

    # Vérifier si le fichier de roadmap existe
    if (-not (Test-Path -Path $RoadmapPath)) {
        Write-Error "Le fichier de roadmap '$RoadmapPath' n'existe pas."
        return $false
    }

    # Créer une sauvegarde de l'index
    New-Backup -FilePath $indexPath

    # Lire le contenu du fichier de roadmap
    # Utiliser directement le script d'importation

    # Utiliser le script d'importation pour extraire les tâches
    $importScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Import-ExistingRoadmapToJournal.ps1"
    & $importScriptPath -RoadmapPath $RoadmapPath -Force

    # Mettre à jour les métadonnées du journal
    $metadata = Get-Content -Path $metadataPath -Raw | ConvertFrom-Json
    $metadata.lastSync = (Get-Date).ToUniversalTime().ToString("o")
    $metadata | ConvertTo-Json -Depth 10 | Out-File -FilePath $metadataPath -Encoding utf8 -Force

    Write-Host "Journal mis à jour avec succès à partir de la roadmap."
    return $true
}

# Exécuter la synchronisation selon la direction spécifiée
switch ($Direction) {
    "ToJournal" {
        Update-JournalFromRoadmap -RoadmapPath $RoadmapPath
    }
    "ToRoadmap" {
        Update-RoadmapFromJournal -RoadmapPath $RoadmapPath
    }
    "Bidirectional" {
        # Pour une synchronisation bidirectionnelle, nous mettons d'abord à jour le journal,
        # puis la roadmap à partir du journal mis à jour
        Update-JournalFromRoadmap -RoadmapPath $RoadmapPath
        Update-RoadmapFromJournal -RoadmapPath $RoadmapPath
    }
}
