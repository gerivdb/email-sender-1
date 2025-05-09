﻿# Analyze-RoadmapStructure.ps1
# Script pour analyser la structure des fichiers de roadmap
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string[]]$RoadmapFiles,

    [Parameter(Mandatory = $false)]
    [string]$InputPath,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [ValidateSet("JSON", "CSV", "Object")]
    [string]$OutputFormat = "Object"
)

# Importer le module de journalisation s'il existe
if (Test-Path -Path "$PSScriptRoot\..\utils\Write-Log.ps1") {
    . "$PSScriptRoot\..\utils\Write-Log.ps1"
} else {
    function Write-Log {
        param (
            [string]$Message,
            [ValidateSet("Info", "Warning", "Error", "Success")]
            [string]$Level = "Info"
        )

        $color = switch ($Level) {
            "Info" { "White" }
            "Warning" { "Yellow" }
            "Error" { "Red" }
            "Success" { "Green" }
        }

        Write-Host "[$Level] $Message" -ForegroundColor $color
    }
}

# Fonction pour analyser la structure d'un fichier markdown
function Get-MarkdownStructure {
    param (
        [string]$FilePath
    )

    $structure = @{
        Path     = $FilePath
        Title    = ""
        Format   = @{
            IndentationType = "Unknown" # Spaces, Tabs, Mixed
            IndentationSize = 0
            NumberingStyle  = "Unknown" # Numeric (1.2.3), Bullet (-, *, +), Mixed
            CheckboxStyle   = "Unknown" # Standard ([]), Custom, None
            HeaderStyle     = "Unknown" # ATX (#), Setext (===), Mixed
        }
        Content  = @{
            SectionCount        = 0
            TaskCount           = 0
            CompletedTaskCount  = 0
            MaxIndentationLevel = 0
            MaxTaskDepth        = 0
        }
        Metadata = @{
            HasFrontMatter    = $false
            HasInlineMetadata = $false
            MetadataFields    = @()
        }
    }

    try {
        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Raw
        $lines = $content -split "`n"

        # Extraire le titre (première ligne commençant par #)
        if ($content -match "^#\s+(.+)$") {
            $structure.Title = $Matches[1].Trim()
        }

        # Vérifier la présence de front matter YAML
        if ($content -match "^---\s*\n([\s\S]*?)\n---") {
            $structure.Metadata.HasFrontMatter = $true
            $frontMatter = $Matches[1]
            $frontMatterLines = $frontMatter -split "`n"

            foreach ($line in $frontMatterLines) {
                if ($line -match "^([^:]+):\s*(.*)$") {
                    $structure.Metadata.MetadataFields += $Matches[1].Trim()
                }
            }
        }

        # Analyser le style d'indentation
        $indentSpaces = 0
        $indentTabs = 0
        $indentSizes = @{}

        # Analyser le style de numérotation
        $bulletCount = 0
        $numericCount = 0
        $checkboxCount = 0
        $standardCheckboxCount = 0

        # Compter les sections
        $sectionCount = 0
        $atxHeaderCount = 0
        $setextHeaderCount = 0

        # Analyser les tâches et l'indentation
        $maxIndentLevel = 0
        $maxTaskDepth = 0
        $taskCount = 0
        $completedTaskCount = 0

        # Vérifier les métadonnées inline
        $inlineMetadataCount = 0

        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]

            # Analyser les en-têtes
            if ($line -match "^(#{1,6})\s+") {
                $sectionCount++
                $atxHeaderCount++
            } elseif ($i -lt $lines.Count - 1 -and $line -match "^[^\s]" -and $lines[$i + 1] -match "^[=]+$") {
                $sectionCount++
                $setextHeaderCount++
            }

            # Analyser l'indentation
            if ($line -match "^(\s+)") {
                $indent = $Matches[1]
                $indentLevel = $indent.Length

                if ($indentLevel -gt $maxIndentLevel) {
                    $maxIndentLevel = $indentLevel
                }

                if ($indent -match "^\t+$") {
                    $indentTabs++
                } elseif ($indent -match "^ +$") {
                    $indentSpaces++
                    $indentSize = $indent.Length

                    if (-not $indentSizes.ContainsKey($indentSize)) {
                        $indentSizes[$indentSize] = 0
                    }

                    $indentSizes[$indentSize]++
                }
            }

            # Analyser les listes
            if ($line -match "^\s*[-*+]\s") {
                $bulletCount++
            } elseif ($line -match "^\s*\d+\.\s") {
                $numericCount++
            }

            # Analyser les cases à cocher
            if ($line -match "\s*[-*+]\s*\[([ xX])\]") {
                $checkboxCount++
                $standardCheckboxCount++
                $taskCount++

                # Calculer la profondeur de la tâche
                if ($line -match "^(\s*)") {
                    $taskIndent = $Matches[1].Length
                    $taskDepth = [math]::Ceiling($taskIndent / 2)

                    if ($taskDepth -gt $maxTaskDepth) {
                        $maxTaskDepth = $taskDepth
                    }
                }

                # Compter les tâches terminées
                if ($line -match "\s*[-*+]\s*\[[xX]\]") {
                    $completedTaskCount++
                }
            }

            # Vérifier les métadonnées inline
            if ($line -match "\s*[-*+]\s*\[[ xX]\]\s*.*\(([^)]+)\)") {
                $inlineMetadataCount++
                $structure.Metadata.HasInlineMetadata = $true
            }
        }

        # Déterminer le type d'indentation
        if ($indentSpaces > 0 -and $indentTabs > 0) {
            $structure.Format.IndentationType = "Mixed"
        }
        elseif ($indentSpaces > 0) {
            $structure.Format.IndentationType = "Spaces"
        }
        elseif ($indentTabs > 0) {
            $structure.Format.IndentationType = "Tabs"
        }

        # Déterminer la taille d'indentation la plus courante
        if ($indentSizes.Count -gt 0) {
            $structure.Format.IndentationSize = $indentSizes.GetEnumerator() |
                Sort-Object -Property Value -Descending |
                Select-Object -First 1 -ExpandProperty Key
        }

        # Déterminer le style de numérotation
        if ($bulletCount > 0 -and $numericCount > 0) {
            $structure.Format.NumberingStyle = "Mixed"
        }
        elseif ($bulletCount > 0) {
            $structure.Format.NumberingStyle = "Bullet"
        }
        elseif ($numericCount > 0) {
            $structure.Format.NumberingStyle = "Numeric"
        }

        # Déterminer le style de case à cocher
        if ($checkboxCount > 0) {
            if ($standardCheckboxCount -eq $checkboxCount) {
                $structure.Format.CheckboxStyle = "Standard"
            } else {
                $structure.Format.CheckboxStyle = "Mixed"
            }
        } else {
            $structure.Format.CheckboxStyle = "None"
        }

        # Déterminer le style d'en-tête
        if ($atxHeaderCount > 0 -and $setextHeaderCount > 0) {
            $structure.Format.HeaderStyle = "Mixed"
        }
        elseif ($atxHeaderCount > 0) {
            $structure.Format.HeaderStyle = "ATX"
        }
        elseif ($setextHeaderCount > 0) {
            $structure.Format.HeaderStyle = "Setext"
        }

        # Mettre à jour les statistiques de contenu
        $structure.Content.SectionCount = $sectionCount
        $structure.Content.TaskCount = $taskCount
        $structure.Content.CompletedTaskCount = $completedTaskCount
        $structure.Content.MaxIndentationLevel = $maxIndentLevel
        $structure.Content.MaxTaskDepth = $maxTaskDepth
    } catch {
        Write-Log "Erreur lors de l'analyse de la structure de $FilePath : $_" -Level Error
    }

    return $structure
}

# Fonction pour exporter les résultats
function Export-Results {
    param (
        [array]$Results,
        [string]$OutputPath,
        [string]$Format
    )

    switch ($Format) {
        "JSON" {
            $Results | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
            Write-Log "Résultats exportés au format JSON dans $OutputPath" -Level Success
        }
        "CSV" {
            # Aplatir les objets pour le CSV
            $flatResults = $Results | ForEach-Object {
                $obj = [PSCustomObject]@{
                    Path                = $_.Path
                    Title               = $_.Title
                    IndentationType     = $_.Format.IndentationType
                    IndentationSize     = $_.Format.IndentationSize
                    NumberingStyle      = $_.Format.NumberingStyle
                    CheckboxStyle       = $_.Format.CheckboxStyle
                    HeaderStyle         = $_.Format.HeaderStyle
                    SectionCount        = $_.Content.SectionCount
                    TaskCount           = $_.Content.TaskCount
                    CompletedTaskCount  = $_.Content.CompletedTaskCount
                    MaxIndentationLevel = $_.Content.MaxIndentationLevel
                    MaxTaskDepth        = $_.Content.MaxTaskDepth
                    HasFrontMatter      = $_.Metadata.HasFrontMatter
                    HasInlineMetadata   = $_.Metadata.HasInlineMetadata
                    MetadataFields      = ($_.Metadata.MetadataFields -join "; ")
                }

                return $obj
            }

            $flatResults | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
            Write-Log "Résultats exportés au format CSV dans $OutputPath" -Level Success
        }
    }
}

# Fonction principale
function Analyze-RoadmapStructure {
    [CmdletBinding()]
    param (
        [string[]]$Files,
        [string]$InputPath
    )

    $results = @()

    # Si un fichier d'entrée est spécifié, charger les fichiers à partir de celui-ci
    if ($InputPath -and (Test-Path -Path $InputPath)) {
        $inputData = Get-Content -Path $InputPath -Raw | ConvertFrom-Json
        $Files = $inputData | ForEach-Object { $_.Path }
    }

    foreach ($file in $Files) {
        Write-Log "Analyse de la structure de $file..." -Level Info

        if (-not (Test-Path -Path $file)) {
            Write-Log "Le fichier $file n'existe pas." -Level Warning
            continue
        }

        $structure = Get-MarkdownStructure -FilePath $file
        $results += $structure
    }

    return $results
}

# Exécution principale
try {
    Write-Log "Démarrage de l'analyse de la structure des fichiers de roadmap..." -Level Info

    $analysisResults = Analyze-RoadmapStructure -Files $RoadmapFiles -InputPath $InputPath

    Write-Log "Analyse terminée. $($analysisResults.Count) fichiers analysés." -Level Success

    # Exporter les résultats si demandé
    if ($OutputPath) {
        Export-Results -Results $analysisResults -OutputPath $OutputPath -Format $OutputFormat
    }

    # Retourner les résultats
    if ($OutputFormat -eq "Object" -or -not $OutputPath) {
        return $analysisResults
    }
} catch {
    Write-Log "Erreur lors de l'analyse des fichiers : $_" -Level Error
    throw $_
}
