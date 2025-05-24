# Parse-Markdown.ps1
# Module pour analyser et extraire des informations des fichiers markdown de roadmap
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param()

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$logModulePath = Join-Path -Path $scriptPath -ChildPath "Write-Log.ps1"

if (Test-Path -Path $logModulePath) {
    . $logModulePath
} else {
    function Write-Log {
        param (
            [string]$Message,
            [string]$Level = "Info"
        )

        Write-Host "[$Level] $Message"
    }
}

# Fonction pour extraire les tâches d'un contenu markdown
function ConvertFrom-MarkdownTasks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $tasks = @()
    $lines = $Content -split "`n"
    $headers = @()
    $currentPath = @()

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        # Détecter les en-têtes
        if ($line -match '^(#+)\s+(.+)$') {
            $level = $matches[1].Length
            $title = $matches[2].Trim()

            # Ajuster le chemin actuel
            if ($headers.Count -gt 0 -and $level -le $headers[-1].Level) {
                $currentPath = $currentPath[0..($level - 2)]
            }

            $currentPath += $title

            $headers += [PSCustomObject]@{
                Level      = $level
                Title      = $title
                LineNumber = $i + 1  # Numéro de ligne (1-based)
                Path       = $currentPath -join " > "
            }
        }
        # Détecter les tâches
        elseif ($line -match '^\s*-\s*\[([ xX])\]\s*(?:\*\*([0-9.]+)\*\*)?\s*(.+)$') {
            $status = $matches[1] -ne ' ' ? "Completed" : "Incomplete"
            $taskId = $matches[2]
            $description = $matches[3].Trim()

            # Calculer le niveau d'indentation
            $indentLevel = ($line -match '^\s+') ? $matches[0].Length : 0

            # Trouver le parent (tâche précédente avec un niveau d'indentation inférieur)
            $parentId = $null
            $parentDescription = $null

            for ($j = $i - 1; $j -ge 0; $j--) {
                $prevLine = $lines[$j]
                if ($prevLine -match '^\s*-\s*\[([ xX])\]\s*(?:\*\*([0-9.]+)\*\*)?\s*(.+)$') {
                    $prevIndent = ($prevLine -match '^\s+') ? $matches[0].Length : 0

                    if ($prevIndent -lt $indentLevel) {
                        $parentId = $matches[2]
                        $parentDescription = $matches[3].Trim()
                        break
                    }
                }
            }

            # Trouver le contexte (en-tête le plus proche)
            $context = $null
            if ($headers.Count -gt 0) {
                $context = $headers[-1].Path
            }

            $tasks += [PSCustomObject]@{
                Id                = $taskId
                Description       = $description
                Status            = $status
                IndentLevel       = $indentLevel
                LineNumber        = $i + 1  # Numéro de ligne (1-based)
                ParentId          = $parentId
                ParentDescription = $parentDescription
                Context           = $context
                Path              = $currentPath -join " > "
                Content           = $description
                OriginalLine      = $line
            }
        }
    }

    return $tasks
}

# Fonction pour extraire la structure hiérarchique d'un contenu markdown
function ConvertFrom-MarkdownStructure {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $structure = @()
    $lines = $Content -split "`n"
    $currentPath = @()
    $currentLevel = 0

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        # Détecter les en-têtes
        if ($line -match '^(#+)\s+(.+)$') {
            $level = $matches[1].Length
            $title = $matches[2].Trim()

            # Ajuster le chemin actuel
            if ($level -le $currentLevel) {
                $currentPath = $currentPath[0..($level - 2)]
            }

            $currentLevel = $level
            $currentPath += $title

            $structure += [PSCustomObject]@{
                Type         = "Header"
                Level        = $level
                Title        = $title
                LineNumber   = $i + 1  # Numéro de ligne (1-based)
                Path         = $currentPath -join " > "
                Content      = $title
                OriginalLine = $line
            }
        }
        # Détecter les tâches
        elseif ($line -match '^\s*-\s*\[([ xX])\]\s*(?:\*\*([0-9.]+)\*\*)?\s*(.+)$') {
            $status = $matches[1] -ne ' ' ? "Completed" : "Incomplete"
            $taskId = $matches[2]
            $description = $matches[3].Trim()

            # Calculer le niveau d'indentation
            $indentLevel = ($line -match '^\s+') ? $matches[0].Length : 0

            $structure += [PSCustomObject]@{
                Type         = "Task"
                Id           = $taskId
                Description  = $description
                Status       = $status
                IndentLevel  = $indentLevel
                LineNumber   = $i + 1  # Numéro de ligne (1-based)
                Path         = $currentPath -join " > "
                Content      = $description
                OriginalLine = $line
            }
        }
        # Détecter les listes
        elseif ($line -match '^\s*-\s+(.+)$') {
            $item = $matches[1].Trim()

            # Calculer le niveau d'indentation
            $indentLevel = ($line -match '^\s+') ? $matches[0].Length : 0

            $structure += [PSCustomObject]@{
                Type         = "ListItem"
                Content      = $item
                IndentLevel  = $indentLevel
                LineNumber   = $i + 1  # Numéro de ligne (1-based)
                Path         = $currentPath -join " > "
                OriginalLine = $line
            }
        }
        # Détecter les paragraphes
        elseif ($line.Trim() -ne "") {
            $structure += [PSCustomObject]@{
                Type         = "Paragraph"
                Content      = $line.Trim()
                LineNumber   = $i + 1  # Numéro de ligne (1-based)
                Path         = $currentPath -join " > "
                OriginalLine = $line
            }
        }
    }

    return $structure
}

# Fonction pour extraire les métadonnées d'un contenu markdown
function ConvertFrom-MarkdownMetadata {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $metadata = @{}
    $lines = $Content -split "`n"
    $inFrontMatter = $false
    $frontMatterLines = @()

    # Extraire le front matter YAML si présent
    foreach ($line in $lines) {
        if ($line -match '^---\s*$') {
            if (-not $inFrontMatter) {
                $inFrontMatter = $true
                continue
            } else {
                $inFrontMatter = $false
                break
            }
        }

        if ($inFrontMatter) {
            $frontMatterLines += $line
        }
    }

    # Analyser le front matter
    foreach ($line in $frontMatterLines) {
        if ($line -match '^\s*([^:]+):\s*(.+)\s*$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            $metadata[$key] = $value
        }
    }

    # Extraire d'autres métadonnées du contenu
    $titleMatch = $Content -match '^#\s+(.+)$'
    if ($titleMatch) {
        $metadata["title"] = $matches[1].Trim()
    }

    # Extraire la date si présente
    $dateMatch = $Content -match 'Date:\s*(\d{4}-\d{2}-\d{2})'
    if ($dateMatch) {
        $metadata["date"] = $matches[1]
    }

    # Extraire la version si présente
    $versionMatch = $Content -match 'Version:\s*([0-9.]+)'
    if ($versionMatch) {
        $metadata["version"] = $matches[1]
    }

    return $metadata
}

# Fonction pour calculer des statistiques sur un contenu markdown
function Get-MarkdownStats {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $structure = ConvertFrom-MarkdownStructure -Content $Content
    $tasks = ConvertFrom-MarkdownTasks -Content $Content

    $completedTasks = $tasks | Where-Object { $_.Status -eq "Completed" }
    $incompleteTasks = $tasks | Where-Object { $_.Status -eq "Incomplete" }

    $headers = $structure | Where-Object { $_.Type -eq "Header" }
    $headersByLevel = @{}

    foreach ($header in $headers) {
        if (-not $headersByLevel.ContainsKey($header.Level)) {
            $headersByLevel[$header.Level] = 0
        }

        $headersByLevel[$header.Level]++
    }

    $stats = @{
        TotalLines            = ($Content -split "`n").Count
        TotalTasks            = $tasks.Count
        CompletedTasks        = $completedTasks.Count
        IncompleteTasks       = $incompleteTasks.Count
        CompletionRate        = if ($tasks.Count -gt 0) { [math]::Round(($completedTasks.Count / $tasks.Count) * 100, 2) } else { 0 }
        TotalHeaders          = $headers.Count
        HeadersByLevel        = $headersByLevel
        MaxHeaderLevel        = if ($headers.Count -gt 0) { ($headers | Measure-Object -Property Level -Maximum).Maximum } else { 0 }
        AverageTasksPerHeader = if ($headers.Count -gt 0) { [math]::Round($tasks.Count / $headers.Count, 2) } else { 0 }
    }

    return $stats
}

# Exporter les fonctions
Export-ModuleMember -function ConvertFrom-MarkdownTasks, ConvertFrom-MarkdownStructure, ConvertFrom-MarkdownMetadata, Get-MarkdownStats

