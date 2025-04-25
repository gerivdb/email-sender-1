# RoadmapAnalyzer.psm1
# Module pour l'analyse de la structure des fichiers markdown de roadmap

# Fonction pour analyser la structure d'un fichier markdown de roadmap
function Get-MarkdownStructure {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    try {
        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $FilePath)) {
            throw "Le fichier '$FilePath' n'existe pas."
        }

        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Encoding UTF8 -Raw

        # Analyser la structure du fichier
        $structure = @{
            ListMarkers   = Get-ListMarkers -Content $content
            Indentation   = Get-IndentationPattern -Content $content
            Headers       = Get-HeaderFormats -Content $content
            Emphasis      = Get-EmphasisStyles -Content $content
            TaskHierarchy = Get-TaskHierarchy -Content $content
            StatusMarkers = Get-StatusMarkers -Content $content
        }

        return $structure
    } catch {
        Write-Error "Erreur lors de l'analyse de la structure du fichier markdown: $_"
        return $null
    }
}

# Fonction pour analyser les marqueurs de liste utilisés dans le contenu markdown
function Get-ListMarkers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $usedMarkers = @{}
    $standardMarkers = @('-', '*', '+')

    # Rechercher les lignes qui commencent par un marqueur de liste
    foreach ($marker in $standardMarkers) {
        $pattern = "(?m)^\s*\$marker\s+"
        $regexMatches = [regex]::Matches($Content, $pattern)
        if ($regexMatches -ne $null -and $regexMatches.Count -gt 0) {
            $usedMarkers[$marker] = $regexMatches.Count
        }
    }

    return $usedMarkers
}

# Fonction pour analyser les conventions d'indentation utilisées dans le contenu markdown
function Get-IndentationPattern {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $indentationPattern = @{
        SpacesPerLevel        = 0
        ConsistentIndentation = $false
    }

    # Diviser le contenu en lignes
    $lines = $Content -split "`n"

    # Analyser les espaces d'indentation
    $indentCounts = @{}
    $previousIndent = 0
    $indentDifferences = @{}

    foreach ($line in $lines) {
        if ($line -match '^\s*[-*+]') {
            $indent = ($line -match '^\s*').Matches[0].Value.Length

            if (-not $indentCounts.ContainsKey($indent)) {
                $indentCounts[$indent] = 1
            } else {
                $indentCounts[$indent] += 1
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

    # Déterminer l'indentation la plus courante
    if ($indentDifferences.Count -gt 0) {
        $mostCommonDiff = $indentDifferences.GetEnumerator() |
            Sort-Object -Property Value -Descending |
            Select-Object -First 1

        $indentationPattern.SpacesPerLevel = $mostCommonDiff.Key

        # Vérifier si l'indentation est cohérente
        $totalDiffs = ($indentDifferences.Values | Measure-Object -Sum).Sum
        $consistencyRatio = $mostCommonDiff.Value / $totalDiffs

        $indentationPattern.ConsistentIndentation = ($consistencyRatio -ge 0.8)
    }

    return $indentationPattern
}

# Fonction pour analyser les formats de titres et sous-titres
function Get-HeaderFormats {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $headerFormats = @{
        HashHeaders      = @{}  # Headers with # syntax
        UnderlineHeaders = @{} # Headers with underline syntax
    }

    # Rechercher les titres avec la syntaxe #
    for ($i = 1; $i -le 6; $i++) {
        $hashPattern = "(?m)^#{$i}\s+.+$"
        $regexMatches = [regex]::Matches($Content, $hashPattern)
        if ($regexMatches -ne $null -and $regexMatches.Count -gt 0) {
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
        $regexMatches = [regex]::Matches($Content, $pattern)
        if ($regexMatches -ne $null -and $regexMatches.Count -gt 0) {
            $headerFormats.UnderlineHeaders[$level] = $regexMatches.Count
        }
    }

    return $headerFormats
}

# Fonction pour analyser les styles d'emphase (gras, italique)
function Get-EmphasisStyles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $emphasisStyles = @{
        Bold       = @{
            Asterisks   = 0  # **bold**
            Underscores = 0  # __bold__
        }
        Italic     = @{
            Asterisks   = 0  # *italic*
            Underscores = 0  # _italic_
        }
        BoldItalic = @{
            Asterisks   = 0  # ***bold-italic***
            Mixed       = 0  # **_bold-italic_** or _**bold-italic**_
            Underscores = 0  # ___bold-italic___
        }
    }

    # Rechercher les styles gras
    $boldAsterisksPattern = "\*\*[^\*]+\*\*"
    $boldUnderscoresPattern = "__[^_]+__"

    $emphasisStyles.Bold.Asterisks = [regex]::Matches($Content, $boldAsterisksPattern).Count
    $emphasisStyles.Bold.Underscores = [regex]::Matches($Content, $boldUnderscoresPattern).Count

    # Rechercher les styles italiques
    $italicAsterisksPattern = "(?<!\*)\*(?!\*)[^\*]+\*(?!\*)"
    $italicUnderscoresPattern = "(?<!_)_(?!_)[^_]+_(?!_)"

    $emphasisStyles.Italic.Asterisks = [regex]::Matches($Content, $italicAsterisksPattern).Count
    $emphasisStyles.Italic.Underscores = [regex]::Matches($Content, $italicUnderscoresPattern).Count

    # Rechercher les styles gras-italiques
    $boldItalicAsterisksPattern = "\*\*\*[^\*]+\*\*\*"
    $boldItalicUnderscoresPattern = "___[^_]+___"
    $boldItalicMixedPattern1 = "\*\*_[^_]+_\*\*"
    $boldItalicMixedPattern2 = "__\*[^\*]+\*__"

    $emphasisStyles.BoldItalic.Asterisks = [regex]::Matches($Content, $boldItalicAsterisksPattern).Count
    $emphasisStyles.BoldItalic.Underscores = [regex]::Matches($Content, $boldItalicUnderscoresPattern).Count
    $emphasisStyles.BoldItalic.Mixed = [regex]::Matches($Content, $boldItalicMixedPattern1).Count +
    [regex]::Matches($Content, $boldItalicMixedPattern2).Count

    return $emphasisStyles
}

# Fonction pour analyser la hiérarchie des tâches
function Get-TaskHierarchy {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $hierarchy = @{
        MaxDepth             = 0
        NumberingConventions = @{}
        ParentChildRelations = @{}
    }

    # Diviser le contenu en lignes
    $lines = $Content -split "`n"

    # Analyser la hiérarchie des tâches
    $currentDepth = 0
    $maxDepth = 0
    $numberingPatterns = @{}
    $parentChildCount = @{}

    $previousIndent = 0
    $indentToDepth = @{}

    foreach ($line in $lines) {
        if ($line -match '^\s*[-*+]') {
            $indent = ($line -match '^\s*').Matches[0].Value.Length

            # Déterminer la profondeur basée sur l'indentation
            if (-not $indentToDepth.ContainsKey($indent)) {
                if ($indent -gt $previousIndent) {
                    $currentDepth++
                } elseif ($indent -lt $previousIndent) {
                    $depthDiff = 0
                    foreach ($knownIndent in $indentToDepth.Keys | Sort-Object -Descending) {
                        if ($knownIndent -gt $indent) {
                            $depthDiff++
                        }
                    }
                    $currentDepth -= $depthDiff
                }
                $indentToDepth[$indent] = $currentDepth
            } else {
                $currentDepth = $indentToDepth[$indent]
            }

            $maxDepth = [Math]::Max($maxDepth, $currentDepth)

            # Analyser les conventions de numérotation
            if ($line -match '^\s*[-*+]\s*(?:\*\*)?(\d+(\.\d+)*|\w+\.)') {
                $numberingPattern = $matches[1]
                if (-not $numberingPatterns.ContainsKey($numberingPattern)) {
                    $numberingPatterns[$numberingPattern] = 1
                } else {
                    $numberingPatterns[$numberingPattern] += 1
                }
            }

            # Analyser les relations parent-enfant
            if ($previousIndent -lt $indent) {
                if (-not $parentChildCount.ContainsKey($currentDepth)) {
                    $parentChildCount[$currentDepth] = 1
                } else {
                    $parentChildCount[$currentDepth] += 1
                }
            }

            $previousIndent = $indent
        }
    }

    $hierarchy.MaxDepth = $maxDepth
    $hierarchy.NumberingConventions = $numberingPatterns
    $hierarchy.ParentChildRelations = $parentChildCount

    return $hierarchy
}

# Fonction pour analyser les marqueurs de statut
function Get-StatusMarkers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $statusMarkers = @{
        Incomplete        = 0
        Complete          = 0
        Custom            = @{}
        TextualIndicators = @{}
    }

    # Rechercher les marqueurs de statut standard
    $incompletePattern = "(?m)^\s*[-*+]\s*\[ \]"
    $completePattern = "(?m)^\s*[-*+]\s*\[x\]"

    $statusMarkers.Incomplete = [regex]::Matches($Content, $incompletePattern).Count
    $statusMarkers.Complete = [regex]::Matches($Content, $completePattern).Count

    # Rechercher les marqueurs de statut personnalisés
    $customPattern = "(?m)^\s*[-*+]\s*\[([^x ])\]"
    $customMatches = [regex]::Matches($Content, $customPattern)

    foreach ($match in $customMatches) {
        $customMarker = $match.Groups[1].Value
        if (-not $statusMarkers.Custom.ContainsKey($customMarker)) {
            $statusMarkers.Custom[$customMarker] = 1
        } else {
            $statusMarkers.Custom[$customMarker] += 1
        }
    }

    # Rechercher les indicateurs textuels de progression
    $textualIndicators = @(
        "en cours", "en attente", "terminé", "complété", "bloqué",
        "reporté", "annulé", "prioritaire", "urgent"
    )

    foreach ($indicator in $textualIndicators) {
        $pattern = "(?i)$indicator"
        $count = [regex]::Matches($Content, $pattern).Count
        if ($count -gt 0) {
            $statusMarkers.TextualIndicators[$indicator] = $count
        }
    }

    return $statusMarkers
}

# Fonction pour analyser les conventions spécifiques au projet
function Get-ProjectConventions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $conventions = @{
        TaskIdentifiers    = @{
            Pattern  = $null
            Examples = @()
        }
        PriorityIndicators = @{
            Pattern  = $null
            Examples = @()
        }
        StatusIndicators   = @{
            Pattern  = $null
            Examples = @()
        }
        SpecialSections    = @()
        MetadataFormat     = $null
    }

    # Détecter les identifiants de tâches
    $taskIdPatterns = @(
        # Format numérique (1.2.3)
        '(?m)^\s*[-*+]\s*(?:\*\*)?(\d+(\.\d+)+)(?:\*\*)?\s',
        # Format alphanumérique (A.1.2)
        '(?m)^\s*[-*+]\s*(?:\*\*)?([A-Za-z]+(\.\d+)+)(?:\*\*)?\s',
        # Format avec préfixe (TASK-123)
        '(?m)^\s*[-*+]\s*(?:\*\*)?([A-Z]+-\d+)(?:\*\*)?\s'
    )

    foreach ($pattern in $taskIdPatterns) {
        $regexMatches = [regex]::Matches($Content, $pattern)
        if ($regexMatches.Count -gt 0) {
            $conventions.TaskIdentifiers.Pattern = $pattern
            $conventions.TaskIdentifiers.Examples = $regexMatches |
                Select-Object -First 5 |
                ForEach-Object { $_.Groups[1].Value }
            break
        }
    }

    # Détecter les indicateurs de priorité
    $priorityPatterns = @(
        # Format [PRIORITY: HIGH]
        '(?m)\[PRIORITY:\s*([A-Z]+)\]',
        # Format (P1), (P2), etc.
        '(?m)\(P(\d+)\)',
        # Format !!! (haute priorité), !! (moyenne), ! (basse)
        '(?m)(!{1,3})'
    )

    foreach ($pattern in $priorityPatterns) {
        $regexMatches = [regex]::Matches($Content, $pattern)
        if ($regexMatches.Count -gt 0) {
            $conventions.PriorityIndicators.Pattern = $pattern
            $conventions.PriorityIndicators.Examples = $regexMatches |
                Select-Object -First 5 |
                ForEach-Object { $_.Groups[1].Value }
            break
        }
    }

    # Détecter les indicateurs de statut spécifiques au projet
    $statusPatterns = @(
        # Format [STATUS: IN_PROGRESS]
        '(?m)\[STATUS:\s*([A-Z_]+)\]',
        # Format @in-progress, @completed, etc.
        '(?m)@([a-z-]+)',
        # Format #status:in-progress
        '(?m)#status:([a-z-]+)'
    )

    foreach ($pattern in $statusPatterns) {
        $regexMatches = [regex]::Matches($Content, $pattern)
        if ($regexMatches.Count -gt 0) {
            $conventions.StatusIndicators.Pattern = $pattern
            $conventions.StatusIndicators.Examples = $regexMatches |
                Select-Object -First 5 |
                ForEach-Object { $_.Groups[1].Value }
            break
        }
    }

    # Détecter les sections spéciales
    $specialSectionPatterns = @(
        # Sections avec des titres spécifiques
        '(?m)^#+\s*(TODO|DONE|IN PROGRESS|BACKLOG|ICEBOX|NOTES|REFERENCES)',
        # Sections délimitées par des séparateurs
        '(?m)^-{3,}\s*([A-Z ]+)\s*-{3,}$'
    )

    foreach ($pattern in $specialSectionPatterns) {
        $regexMatches = [regex]::Matches($Content, $pattern)
        if ($regexMatches.Count -gt 0) {
            $conventions.SpecialSections += $regexMatches |
                Select-Object -First 5 |
                ForEach-Object { $_.Groups[1].Value }
        }
    }

    # Détecter le format des métadonnées
    $metadataPatterns = @(
        # Format YAML front matter
        '(?ms)^---\s*\n(.*?)\n---\s*\n',
        # Format clé-valeur
        '(?m)^([A-Za-z]+):\s*(.+)$'
    )

    foreach ($pattern in $metadataPatterns) {
        $regexMatches = [regex]::Matches($Content, $pattern)
        if ($regexMatches.Count -gt 0) {
            $conventions.MetadataFormat = $pattern
            break
        }
    }

    return $conventions
}

# Exporter les fonctions
Export-ModuleMember -Function Get-MarkdownStructure, Get-ProjectConventions
