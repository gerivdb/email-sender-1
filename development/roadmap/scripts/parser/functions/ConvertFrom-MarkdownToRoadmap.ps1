﻿<#
.SYNOPSIS
    Convertit un fichier markdown en structure d'objet PowerShell reprÃ©sentant une roadmap.

.DESCRIPTION
    La fonction ConvertFrom-MarkdownToRoadmap lit un fichier markdown et le convertit en une structure d'objet PowerShell.
    Elle est spÃ©cialement conÃ§ue pour traiter les roadmaps au format markdown avec des tÃ¢ches, des statuts et des identifiants.

.PARAMETER FilePath
    Chemin du fichier markdown Ã  convertir.

.PARAMETER IncludeMetadata
    Indique si les mÃ©tadonnÃ©es supplÃ©mentaires doivent Ãªtre extraites et incluses dans les objets.

.EXAMPLE
    ConvertFrom-MarkdownToRoadmap -FilePath ".\roadmap.md"
    Convertit le fichier roadmap.md en structure d'objet PowerShell.

.EXAMPLE
    ConvertFrom-MarkdownToRoadmap -FilePath ".\roadmap.md" -IncludeMetadata
    Convertit le fichier roadmap.md en structure d'objet PowerShell avec extraction des mÃ©tadonnÃ©es.

.OUTPUTS
    [PSCustomObject] ReprÃ©sentant la structure de la roadmap.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-10
#>
function ConvertFrom-MarkdownToRoadmap {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetadata
    )

    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        throw "Le fichier '$FilePath' n'existe pas."
    }

    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Encoding UTF8 -Raw
    $lines = $content -split "`r?`n"

    # CrÃ©er l'objet roadmap
    $roadmap = [PSCustomObject]@{
        Title = "Roadmap"
        Description = ""
        Sections = @()
    }

    # Extraire le titre et la description
    $inDescription = $false
    $descriptionLines = @()

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        # Extraire le titre (premiÃ¨re ligne commenÃ§ant par #)
        if ($line -match '^#\s+(.+)$' -and -not $inDescription) {
            $roadmap.Title = $matches[1]
            $inDescription = $true
            continue
        }

        # Collecter les lignes de description
        if ($inDescription) {
            # Si on trouve une section, on arrÃªte la description
            if ($line -match '^##\s+') {
                $inDescription = $false
                $i-- # Reculer d'une ligne pour traiter la section au prochain tour
                continue
            }

            # Ignorer les lignes vides au dÃ©but de la description
            if ($descriptionLines.Count -eq 0 -and [string]::IsNullOrWhiteSpace($line)) {
                continue
            }

            $descriptionLines += $line
        }
    }

    # DÃ©finir la description
    if ($descriptionLines.Count -gt 0) {
        # Supprimer les lignes vides Ã  la fin
        while ($descriptionLines.Count -gt 0 -and [string]::IsNullOrWhiteSpace($descriptionLines[-1])) {
            $descriptionLines = $descriptionLines[0..($descriptionLines.Count - 2)]
        }
        $roadmap.Description = $descriptionLines -join "`n"
    }

    # Extraire les sections et les tÃ¢ches
    $currentSection = $null
    $taskStack = @()
    $currentLevel = 0

    foreach ($line in $lines) {
        # DÃ©tecter les sections (lignes commenÃ§ant par ##)
        if ($line -match '^##\s+(.+)$') {
            $sectionTitle = $matches[1]
            $currentSection = [PSCustomObject]@{
                Title = $sectionTitle
                Tasks = @()
            }
            $roadmap.Sections += $currentSection
            $taskStack = @()
            $currentLevel = 0
            continue
        }

        # DÃ©tecter les tÃ¢ches (lignes commenÃ§ant par -, *, + avec ou sans case Ã  cocher)
        if ($line -match '^(\s*)[-*+]\s*(?:\[([ xX~!])\])?\s*(?:\*\*([^*]+)\*\*)?\s*(.*)$' -and $currentSection -ne $null) {
            $indent = $matches[1].Length
            $statusMarker = $matches[2]
            $id = $matches[3]
            $title = $matches[4]

            # DÃ©terminer le statut
            $status = switch ($statusMarker) {
                'x' { "Complete" }
                'X' { "Complete" }
                '~' { "InProgress" }
                '!' { "Blocked" }
                default { "Incomplete" }
            }

            # Extraire les mÃ©tadonnÃ©es si demandÃ©
            $metadata = @{}
            if ($IncludeMetadata) {
                # Extraire les assignations (@personne)
                if ($title -match '@([a-zA-Z0-9_-]+)') {
                    $metadata["Assignee"] = $matches[1]
                }

                # Extraire les tags (#tag)
                $tags = @()
                $tagMatches = [regex]::Matches($title, '#([a-zA-Z0-9_-]+)')
                foreach ($match in $tagMatches) {
                    $tags += $match.Groups[1].Value
                }
                if ($tags.Count -gt 0) {
                    $metadata["Tags"] = $tags
                }

                # Extraire les prioritÃ©s (P1, P2, etc.)
                if ($title -match '\b(P[0-9])\b') {
                    $metadata["Priority"] = $matches[1]
                }

                # Extraire les dates (format: @date:YYYY-MM-DD)
                if ($title -match '@date:(\d{4}-\d{2}-\d{2})') {
                    $metadata["Date"] = $matches[1]
                }
            }

            # CrÃ©er l'objet tÃ¢che
            $task = [PSCustomObject]@{
                Id = $id
                Title = $title
                Status = $status
                Level = [int]($indent / 2)  # Supposer 2 espaces par niveau
                SubTasks = @()
                Metadata = $metadata
            }

            # DÃ©terminer le parent en fonction de l'indentation
            if ($indent -eq 0) {
                # TÃ¢che de premier niveau
                $currentSection.Tasks += $task
                $taskStack = @($task)
                $currentLevel = 0
            }
            elseif ($indent -gt $currentLevel) {
                # Sous-tÃ¢che
                if ($taskStack.Count -gt 0) {
                    $taskStack[-1].SubTasks += $task
                    $taskStack += $task
                    $currentLevel = $indent
                }
            }
            elseif ($indent -eq $currentLevel) {
                # MÃªme niveau que la tÃ¢che prÃ©cÃ©dente
                if ($taskStack.Count -gt 1) {
                    $taskStack = $taskStack[0..($taskStack.Count - 2)]
                    $taskStack[-1].SubTasks += $task
                    $taskStack += $task
                }
                else {
                    $currentSection.Tasks += $task
                    $taskStack = @($task)
                }
            }
            elseif ($indent -lt $currentLevel) {
                # Remonter dans la hiÃ©rarchie
                $levelDiff = [int](($currentLevel - $indent) / 2)
                if ($levelDiff -ge $taskStack.Count) {
                    $taskStack = @()
                    $currentSection.Tasks += $task
                    $taskStack += $task
                }
                else {
                    $taskStack = $taskStack[0..($taskStack.Count - $levelDiff - 1)]
                    $taskStack[-1].SubTasks += $task
                    $taskStack += $task
                }
                $currentLevel = $indent
            }
        }
    }

    return $roadmap
}
