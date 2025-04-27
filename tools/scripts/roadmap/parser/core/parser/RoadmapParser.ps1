# RoadmapParser.ps1
# Script pour parser un fichier markdown de roadmap

# Fonction pour parser un fichier markdown en structure de tÃ¢ches
function ConvertFrom-MarkdownToTaskStructure {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    if (-not (Test-Path -Path $FilePath)) {
        throw "Le fichier '$FilePath' n'existe pas."
    }

    $content = Get-Content -Path $FilePath -Encoding UTF8 -Raw
    $lines = $content -split "`n"

    # Extraire le titre et la description
    $title = "Roadmap"
    $description = ""

    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^#\s+(.+)$') {
            $title = $matches[1]

            # Extraire la description (lignes non vides aprÃ¨s le titre jusqu'Ã  la premiÃ¨re section)
            $descLines = @()
            $j = $i + 1
            while ($j -lt $lines.Count -and -not ($lines[$j] -match '^#{2,}\s+')) {
                if (-not [string]::IsNullOrWhiteSpace($lines[$j])) {
                    $descLines += $lines[$j]
                }
                $j++
            }

            if ($descLines.Count -gt 0) {
                $description = $descLines -join "`n"
            }

            break
        }
    }

    # CrÃ©er la structure de tÃ¢ches
    $taskStructure = @{
        Title        = $title
        Description  = $description
        Tasks        = @()
        FilePath     = $FilePath
        CreatedDate  = Get-Date
        ModifiedDate = Get-Date
    }

    # Parser les tÃ¢ches
    $taskStack = @{}

    foreach ($line in $lines) {
        if ($line -match '^(\s*)[-*+]\s*(?:\[([ xX~!])\])?\s*(?:\*\*([^*]+)\*\*)?\s*(.*)$') {
            $indent = $matches[1].Length
            $statusMark = $matches[2]
            $id = $matches[3]
            $title = $matches[4]

            # DÃ©terminer le statut
            $status = switch ($statusMark) {
                'x' { "Complete" }
                'X' { "Complete" }
                '~' { "InProgress" }
                '!' { "Blocked" }
                default { "Incomplete" }
            }

            # CrÃ©er la tÃ¢che
            $task = @{
                Id               = $id
                Title            = $title
                Status           = $status
                Level            = [Math]::Floor($indent / 2)
                Children         = @()
                OriginalMarkdown = $line
            }

            # DÃ©terminer le parent en fonction de l'indentation
            if ($task.Level -eq 0) {
                # TÃ¢che de premier niveau
                $taskStructure.Tasks += $task
                $taskStack[0] = $task
            } else {
                # Trouver le parent appropriÃ©
                $parentLevel = $task.Level - 1
                while ($parentLevel -ge 0) {
                    if ($taskStack.ContainsKey($parentLevel)) {
                        $parent = $taskStack[$parentLevel]
                        $parent.Children += $task
                        $taskStack[$task.Level] = $task
                        break
                    }
                    $parentLevel--
                }
            }
        }
    }

    return $taskStructure
}

# Fonction pour convertir une structure de tÃ¢ches en markdown
function ConvertTo-MarkdownFromTaskStructure {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$TaskStructure,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = $null
    )

    $markdown = "# $($TaskStructure.Title)`n`n"

    if (-not [string]::IsNullOrEmpty($TaskStructure.Description)) {
        $markdown += "$($TaskStructure.Description)`n`n"
    }

    # Fonction rÃ©cursive pour gÃ©nÃ©rer le markdown des tÃ¢ches
    function ConvertTaskToMarkdown {
        param (
            [Parameter(Mandatory = $true)]
            [hashtable]$Task,

            [Parameter(Mandatory = $false)]
            [int]$Level = 0
        )

        $indent = "  " * $Level
        $statusMark = switch ($Task.Status) {
            "Complete" { "[x]" }
            "InProgress" { "[~]" }
            "Blocked" { "[!]" }
            default { "[ ]" }
        }

        $idPart = if (-not [string]::IsNullOrEmpty($Task.Id)) { "**$($Task.Id)** " } else { "" }
        $markdown = "$indent- $statusMark $idPart$($Task.Title)`n"

        foreach ($child in $Task.Children) {
            $markdown += ConvertTaskToMarkdown -Task $child -Level ($Level + 1)
        }

        return $markdown
    }

    # GÃ©nÃ©rer le markdown pour chaque tÃ¢che de premier niveau
    foreach ($task in $TaskStructure.Tasks) {
        $markdown += ConvertTaskToMarkdown -Task $task
    }

    # Enregistrer le markdown dans un fichier si un chemin de sortie est spÃ©cifiÃ©
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        $markdown | Out-File -FilePath $OutputPath -Encoding UTF8
    }

    return $markdown
}

# Fonction pour analyser la structure d'un fichier markdown de roadmap
function Get-RoadmapStructureInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    if (-not (Test-Path -Path $FilePath)) {
        throw "Le fichier '$FilePath' n'existe pas."
    }

    $content = Get-Content -Path $FilePath -Encoding UTF8 -Raw
    $lines = $content -split "`n"

    # Analyser les marqueurs de liste
    $listMarkers = @{}
    foreach ($marker in @('-', '*', '+')) {
        $pattern = "(?m)^\s*\$marker\s+"
        $regexMatches = [regex]::Matches($content, $pattern)
        if ($null -ne $regexMatches -and $regexMatches.Count -gt 0) {
            $listMarkers[$marker] = $regexMatches.Count
        }
    }

    # Analyser les conventions d'indentation
    $indentCounts = @{}
    $indentDifferences = @{}
    $previousIndent = 0

    foreach ($line in $lines) {
        if ($line -match '^\s*[-*+]') {
            if ($line -match '^(\s*)') {
                $indent = $matches[1].Length

                if (-not $indentCounts.ContainsKey($indent)) {
                    $indentCounts[$indent] = 1
                } else {
                    $indentCounts[$indent] += 1
                }
            }

            if ($previousIndent -ne 0 -and $indent -gt $previousIndent) {
                $diff = $indent - $previousIndent
                if (-not $indentDifferences.ContainsKey($diff)) {
                    $indentDifferences[$diff] = 1
                } else {
                    $indentDifferences[$diff] += 1
                }
            }

            $previousIndent = $indent
        }
    }

    # DÃ©terminer l'indentation la plus courante
    $spacesPerLevel = 2
    if ($indentDifferences.Count -gt 0) {
        $mostCommonDiff = $indentDifferences.GetEnumerator() |
            Sort-Object -Property Value -Descending |
            Select-Object -First 1

        $spacesPerLevel = $mostCommonDiff.Key
    }

    # Analyser les formats de titres
    $headerFormats = @{
        HashHeaders      = @{}
        UnderlineHeaders = @{}
    }

    # Rechercher les titres avec la syntaxe #
    for ($i = 1; $i -le 6; $i++) {
        $hashPattern = "(?m)^#{$i}\s+.+$"
        $regexMatches = [regex]::Matches($content, $hashPattern)
        if ($null -ne $regexMatches -and $regexMatches.Count -gt 0) {
            $headerFormats.HashHeaders[$i] = $regexMatches.Count
        }
    }

    # Rechercher les titres avec la syntaxe de soulignement
    $underlinePatterns = @{
        1 = "(?m)^[^\n]+\n=+$"  # Titre niveau 1 avec =
        2 = "(?m)^[^\n]+\n-+$"  # Titre niveau 2 avec -
    }

    foreach ($level in $underlinePatterns.Keys) {
        $pattern = $underlinePatterns[$level]
        $regexMatches = [regex]::Matches($content, $pattern)
        if ($null -ne $regexMatches -and $regexMatches.Count -gt 0) {
            $headerFormats.UnderlineHeaders[$level] = $regexMatches.Count
        }
    }

    # Analyser les marqueurs de statut
    $statusMarkers = @{
        Incomplete        = 0
        Complete          = 0
        Custom            = @{}
        TextualIndicators = @{}
    }

    # Rechercher les marqueurs de statut standard
    $incompletePattern = "(?m)^\s*[-*+]\s*\[ \]"
    $completePattern = "(?m)^\s*[-*+]\s*\[x\]"

    $incompleteMatches = [regex]::Matches($content, $incompletePattern)
    $completeMatches = [regex]::Matches($content, $completePattern)

    $statusMarkers.Incomplete = if ($null -ne $incompleteMatches) { $incompleteMatches.Count } else { 0 }
    $statusMarkers.Complete = if ($null -ne $completeMatches) { $completeMatches.Count } else { 0 }

    # Rechercher les marqueurs de statut personnalisÃ©s
    $customPattern = "(?m)^\s*[-*+]\s*\[([^x ])\]"
    $customMatches = [regex]::Matches($content, $customPattern)

    if ($null -ne $customMatches) {
        foreach ($match in $customMatches) {
            $customMarker = $match.Groups[1].Value
            if (-not $statusMarkers.Custom.ContainsKey($customMarker)) {
                $statusMarkers.Custom[$customMarker] = 1
            } else {
                $statusMarkers.Custom[$customMarker] += 1
            }
        }
    }

    # Rechercher les indicateurs textuels de progression
    $textualIndicators = @(
        "en cours", "en attente", "terminÃ©", "complÃ©tÃ©", "bloquÃ©",
        "reportÃ©", "annulÃ©", "prioritaire", "urgent"
    )

    foreach ($indicator in $textualIndicators) {
        $pattern = "(?i)$indicator"
        $indicatorMatches = [regex]::Matches($content, $pattern)
        $count = if ($null -ne $indicatorMatches) { $indicatorMatches.Count } else { 0 }
        if ($count -gt 0) {
            $statusMarkers.TextualIndicators[$indicator] = $count
        }
    }

    # Analyser les conventions de numÃ©rotation
    $numberingPatterns = @{}
    foreach ($line in $lines) {
        if ($line -match '^\s*[-*+]\s*(?:\*\*)?(\d+(\.\d+)*|\w+\.)') {
            $numberingPattern = $matches[1]
            if (-not $numberingPatterns.ContainsKey($numberingPattern)) {
                $numberingPatterns[$numberingPattern] = 1
            } else {
                $numberingPatterns[$numberingPattern] += 1
            }
        }
    }

    # Calculer les statistiques de progression
    $totalTasks = $statusMarkers.Incomplete + $statusMarkers.Complete
    foreach ($customCount in $statusMarkers.Custom.Values) {
        $totalTasks += $customCount
    }

    $completionPercentage = if ($totalTasks -gt 0) {
        [Math]::Round(($statusMarkers.Complete / $totalTasks) * 100, 2)
    } else {
        0
    }

    # CrÃ©er la structure d'information
    $structureInfo = @{
        FilePath          = $FilePath
        ListMarkers       = $listMarkers
        Indentation       = @{
            SpacesPerLevel        = $spacesPerLevel
            ConsistentIndentation = ($indentDifferences.Count -eq 1)
        }
        HeaderFormats     = $headerFormats
        StatusMarkers     = $statusMarkers
        NumberingPatterns = $numberingPatterns
        Progress          = @{
            TotalTasks           = $totalTasks
            CompleteTasks        = $statusMarkers.Complete
            IncompleteTasks      = $statusMarkers.Incomplete
            CompletionPercentage = $completionPercentage
        }
    }

    return $structureInfo
}

# Fonction pour gÃ©nÃ©rer un rapport de structure de roadmap
function New-RoadmapStructureReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$StructureInfo,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = $null
    )

    $report = "# Rapport d'Analyse de Structure de Roadmap`n`n"
    $report += "**Fichier analysÃ©:** $($StructureInfo.FilePath)`n"
    $report += "**Date d'analyse:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`n"

    # Marqueurs de liste
    $report += "## 1. Marqueurs de Liste`n`n"
    if ($StructureInfo.ListMarkers.Count -eq 0) {
        $report += "Aucun marqueur de liste dÃ©tectÃ©.`n`n"
    } else {
        $report += "| Marqueur | Occurrences |`n|----------|-------------|`n"
        foreach ($marker in $StructureInfo.ListMarkers.GetEnumerator()) {
            $report += "| `$($marker.Key)` | $($marker.Value) |`n"
        }
        $report += "`n"
    }

    # Conventions d'indentation
    $report += "## 2. Conventions d'Indentation`n`n"
    $report += "- **Espaces par niveau:** $($StructureInfo.Indentation.SpacesPerLevel)`n"
    $report += "- **Indentation cohÃ©rente:** $($StructureInfo.Indentation.ConsistentIndentation)`n`n"

    # Formats de titres
    $report += "## 3. Formats de Titres et Sous-titres`n`n"
    $report += "### 3.1 Titres avec #`n`n"
    if ($StructureInfo.HeaderFormats.HashHeaders.Count -eq 0) {
        $report += "Aucun titre avec # dÃ©tectÃ©.`n`n"
    } else {
        $report += "| Niveau | Occurrences |`n|--------|-------------|`n"
        foreach ($level in $StructureInfo.HeaderFormats.HashHeaders.GetEnumerator() | Sort-Object -Property Key) {
            $report += "| $($level.Key) | $($level.Value) |`n"
        }
        $report += "`n"
    }

    $report += "### 3.2 Titres avec soulignement`n`n"
    if ($StructureInfo.HeaderFormats.UnderlineHeaders.Count -eq 0) {
        $report += "Aucun titre avec soulignement dÃ©tectÃ©.`n`n"
    } else {
        $report += "| Type | Niveau | Occurrences |`n|------|--------|-------------|`n"
        foreach ($level in $StructureInfo.HeaderFormats.UnderlineHeaders.GetEnumerator() | Sort-Object -Property Key) {
            $levelChar = if ($level.Key -eq 1) { "=" } else { "-" }
            $report += "| $levelChar | $($level.Key) | $($level.Value) |`n"
        }
        $report += "`n"
    }

    # Marqueurs de statut
    $report += "## 4. Marqueurs de Statut`n`n"
    $report += "- **Incomplet (`[ ]`):** $($StructureInfo.StatusMarkers.Incomplete) occurrences`n"
    $report += "- **Complet (`[x]`):** $($StructureInfo.StatusMarkers.Complete) occurrences`n`n"

    $report += "### 4.1 Marqueurs PersonnalisÃ©s`n`n"
    if ($StructureInfo.StatusMarkers.Custom.Count -eq 0) {
        $report += "Aucun marqueur personnalisÃ© dÃ©tectÃ©.`n`n"
    } else {
        $report += "| Marqueur | Occurrences |`n|----------|-------------|`n"
        foreach ($marker in $StructureInfo.StatusMarkers.Custom.GetEnumerator()) {
            $report += "| [$($marker.Key)] | $($marker.Value) |`n"
        }
        $report += "`n"
    }

    $report += "### 4.2 Indicateurs Textuels de Progression`n`n"
    if ($StructureInfo.StatusMarkers.TextualIndicators.Count -eq 0) {
        $report += "Aucun indicateur textuel dÃ©tectÃ©.`n`n"
    } else {
        $report += "| Indicateur | Occurrences |`n|-----------|-------------|`n"
        foreach ($indicator in $StructureInfo.StatusMarkers.TextualIndicators.GetEnumerator()) {
            $report += "| $($indicator.Key) | $($indicator.Value) |`n"
        }
        $report += "`n"
    }

    # Conventions de numÃ©rotation
    $report += "## 5. Conventions de NumÃ©rotation`n`n"
    if ($StructureInfo.NumberingPatterns.Count -eq 0) {
        $report += "Aucune convention de numÃ©rotation dÃ©tectÃ©e.`n`n"
    } else {
        $report += "| Format | Occurrences |`n|--------|-------------|`n"
        foreach ($pattern in $StructureInfo.NumberingPatterns.GetEnumerator() | Sort-Object -Property Value -Descending) {
            $report += "| `$($pattern.Key)` | $($pattern.Value) |`n"
        }
        $report += "`n"
    }

    # Progression
    $report += "## 6. Progression`n`n"
    $report += "- **TÃ¢ches totales:** $($StructureInfo.Progress.TotalTasks)`n"
    $report += "- **TÃ¢ches terminÃ©es:** $($StructureInfo.Progress.CompleteTasks)`n"
    $report += "- **TÃ¢ches en cours:** $($StructureInfo.Progress.IncompleteTasks)`n"
    $report += "- **Pourcentage de complÃ©tion:** $($StructureInfo.Progress.CompletionPercentage)%`n`n"

    # CrÃ©er un graphique de progression en ASCII art
    $progressBarWidth = 50
    $completedChars = [Math]::Round(($StructureInfo.Progress.CompletionPercentage / 100) * $progressBarWidth)
    $remainingChars = $progressBarWidth - $completedChars

    $progressBar = "["
    for ($i = 0; $i -lt $completedChars; $i++) {
        $progressBar += "="
    }
    for ($i = 0; $i -lt $remainingChars; $i++) {
        $progressBar += " "
    }
    $progressBar += "]"

    $report += "```\n"
    $report += $progressBar + " " + $StructureInfo.Progress.CompletionPercentage + "%\n"
    $report += "```\n"

    # Enregistrer le rapport dans un fichier si un chemin de sortie est spÃ©cifiÃ©
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        $report | Out-File -FilePath $OutputPath -Encoding UTF8
    }

    return $report
}

# Fonction pour mettre Ã  jour le statut d'une tÃ¢che dans un fichier markdown
function Update-TaskStatus {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string]$TaskId,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Incomplete", "Complete", "InProgress", "Blocked")]
        [string]$Status,

        [Parameter(Mandatory = $false)]
        [switch]$SaveChanges
    )

    if (-not (Test-Path -Path $FilePath)) {
        throw "Le fichier '$FilePath' n'existe pas."
    }

    $content = Get-Content -Path $FilePath -Encoding UTF8
    $modified = $false

    for ($i = 0; $i -lt $content.Count; $i++) {
        if ($content[$i] -match "^\s*[-*+]\s*\[[^\]]*\]\s*\*\*$TaskId\*\*") {
            $statusMark = switch ($Status) {
                "Complete" { "x" }
                "InProgress" { "~" }
                "Blocked" { "!" }
                default { " " }
            }

            $newLine = $content[$i] -replace "\[[^\]]*\]", "[$statusMark]"
            if ($newLine -ne $content[$i]) {
                $content[$i] = $newLine
                $modified = $true
            }
        }
    }

    if ($modified -and $SaveChanges) {
        $content | Out-File -FilePath $FilePath -Encoding UTF8
    }

    return $modified
}

# Fonction pour ajouter une nouvelle tÃ¢che Ã  un fichier markdown
function Add-Task {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string]$TaskId,

        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $false)]
        [string]$ParentTaskId = $null,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Incomplete", "Complete", "InProgress", "Blocked")]
        [string]$Status = "Incomplete",

        [Parameter(Mandatory = $false)]
        [switch]$SaveChanges
    )

    if (-not (Test-Path -Path $FilePath)) {
        throw "Le fichier '$FilePath' n'existe pas."
    }

    $content = Get-Content -Path $FilePath -Encoding UTF8
    $modified = $false

    # DÃ©terminer le statut
    $statusMark = switch ($Status) {
        "Complete" { "x" }
        "InProgress" { "~" }
        "Blocked" { "!" }
        default { " " }
    }

    # CrÃ©er la nouvelle ligne de tÃ¢che
    $newTaskLine = "- [$statusMark] **$TaskId** $Title"

    if ([string]::IsNullOrEmpty($ParentTaskId)) {
        # Ajouter la tÃ¢che Ã  la fin du fichier
        $content += $newTaskLine
        $modified = $true
    } else {
        # Trouver la tÃ¢che parente
        $parentIndex = -1
        $parentIndent = 0

        for ($i = 0; $i -lt $content.Count; $i++) {
            if ($content[$i] -match "^\s*[-*+]\s*\[[^\]]*\]\s*\*\*$ParentTaskId\*\*") {
                $parentIndex = $i
                $parentIndent = ($content[$i] -match '^\s*').Matches[0].Value.Length
                break
            }
        }

        if ($parentIndex -ge 0) {
            # Trouver l'endroit oÃ¹ insÃ©rer la nouvelle tÃ¢che (aprÃ¨s la derniÃ¨re sous-tÃ¢che de la tÃ¢che parente)
            $insertIndex = $parentIndex + 1
            $childIndent = $parentIndent + 2

            while ($insertIndex -lt $content.Count) {
                $lineIndent = 0
                if ($content[$insertIndex] -match '^\s*') {
                    $lineIndent = $matches[0].Length
                }

                if ($lineIndent -le $parentIndent) {
                    break
                }

                $insertIndex++
            }

            # InsÃ©rer la nouvelle tÃ¢che avec l'indentation appropriÃ©e
            $indentedTaskLine = (" " * $childIndent) + $newTaskLine
            $content = $content[0..($insertIndex - 1)] + $indentedTaskLine + $content[$insertIndex..($content.Count - 1)]
            $modified = $true
        }
    }

    if ($modified -and $SaveChanges) {
        $content | Out-File -FilePath $FilePath -Encoding UTF8
    }

    return $modified
}

# Fonction pour supprimer une tÃ¢che d'un fichier markdown
function Remove-Task {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string]$TaskId,

        [Parameter(Mandatory = $false)]
        [switch]$RemoveChildren,

        [Parameter(Mandatory = $false)]
        [switch]$SaveChanges
    )

    if (-not (Test-Path -Path $FilePath)) {
        throw "Le fichier '$FilePath' n'existe pas."
    }

    $content = Get-Content -Path $FilePath -Encoding UTF8
    $modified = $false

    # Trouver la tÃ¢che Ã  supprimer
    $taskIndex = -1
    $taskIndent = 0

    for ($i = 0; $i -lt $content.Count; $i++) {
        if ($content[$i] -match "^\s*[-*+]\s*\[[^\]]*\]\s*\*\*$TaskId\*\*") {
            $taskIndex = $i
            $taskIndent = ($content[$i] -match '^\s*').Matches[0].Value.Length
            break
        }
    }

    if ($taskIndex -ge 0) {
        if ($RemoveChildren) {
            # Supprimer la tÃ¢che et toutes ses sous-tÃ¢ches
            $endIndex = $taskIndex + 1

            while ($endIndex -lt $content.Count) {
                $lineIndent = 0
                if ($content[$endIndex] -match '^\s*') {
                    $lineIndent = $matches[0].Length
                }

                if ($lineIndent -le $taskIndent) {
                    break
                }

                $endIndex++
            }

            $content = $content[0..($taskIndex - 1)] + $content[$endIndex..($content.Count - 1)]
        } else {
            # Supprimer uniquement la tÃ¢che
            $content = $content[0..($taskIndex - 1)] + $content[($taskIndex + 1)..($content.Count - 1)]
        }

        $modified = $true
    }

    if ($modified -and $SaveChanges) {
        $content | Out-File -FilePath $FilePath -Encoding UTF8
    }

    return $modified
}

# Fonction pour gÃ©nÃ©rer un rapport de progression
function New-ProgressReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = $null
    )

    if (-not (Test-Path -Path $FilePath)) {
        throw "Le fichier '$FilePath' n'existe pas."
    }

    # Analyser la structure du fichier
    $structureInfo = Get-RoadmapStructureInfo -FilePath $FilePath

    # GÃ©nÃ©rer le rapport de progression
    $report = "# Rapport de Progression de la Roadmap`n`n"
    $report += "**Fichier analysÃ©:** $FilePath`n"
    $report += "**Date d'analyse:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`n"

    $report += "## Progression Globale`n`n"
    $report += "- **TÃ¢ches totales:** $($structureInfo.Progress.TotalTasks)`n"
    $report += "- **TÃ¢ches terminÃ©es:** $($structureInfo.Progress.CompleteTasks)`n"
    $report += "- **TÃ¢ches en cours:** $($structureInfo.Progress.IncompleteTasks)`n"
    $report += "- **Pourcentage de complÃ©tion:** $($structureInfo.Progress.CompletionPercentage)%`n`n"

    # CrÃ©er un graphique de progression en ASCII art
    $progressBarWidth = 50
    $completedChars = [Math]::Round(($structureInfo.Progress.CompletionPercentage / 100) * $progressBarWidth)
    $remainingChars = $progressBarWidth - $completedChars

    $progressBar = "["
    for ($i = 0; $i -lt $completedChars; $i++) {
        $progressBar += "="
    }
    for ($i = 0; $i -lt $remainingChars; $i++) {
        $progressBar += " "
    }
    $progressBar += "]"

    $report += "```\n"
    $report += $progressBar + " " + $structureInfo.Progress.CompletionPercentage + "%\n"
    $report += "```\n"

    # Enregistrer le rapport dans un fichier si un chemin de sortie est spÃ©cifiÃ©
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        $report | Out-File -FilePath $OutputPath -Encoding UTF8
    }

    return $report
}

# Exporter les fonctions
Export-ModuleMember -Function ConvertFrom-MarkdownToTaskStructure, ConvertTo-MarkdownFromTaskStructure, Get-RoadmapStructureInfo, New-RoadmapStructureReport, Update-TaskStatus, Add-Task, Remove-Task, New-ProgressReport
