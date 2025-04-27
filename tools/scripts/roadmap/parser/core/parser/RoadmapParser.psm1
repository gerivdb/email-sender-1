# RoadmapParser.psm1
# Module pour l'analyse et la manipulation des fichiers markdown de roadmap

# Variables globales
$script:MarkdownPatterns = @{
    ListMarkers       = @('-', '*', '+')
    IndentationSpaces = 2
    TaskStatus        = @{
        Incomplete = '[ ]'
        Complete   = '[x]'
        InProgress = '[~]'
        Blocked    = '[!]'
    }
}

# Fonction pour analyser la structure d'un fichier markdown de roadmap
function Get-RoadmapStructure {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    try {
        # VÃ©rifier si le fichier existe
        if (-not (Test-Path -Path $FilePath)) {
            throw "Le fichier '$FilePath' n'existe pas."
        }

        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Encoding UTF8 -Raw

        # Analyser la structure du fichier
        $structure = @{
            ListMarkers        = Get-MarkdownListMarkers -Content $content
            IndentationPattern = Get-MarkdownIndentationPattern -Content $content
            HeaderFormats      = Get-MarkdownHeaderFormats -Content $content
            EmphasisStyles     = Get-MarkdownEmphasisStyles -Content $content
            TaskHierarchy      = Get-TaskHierarchy -Content $content
            StatusMarkers      = Get-StatusMarkers -Content $content
        }

        return $structure
    } catch {
        Write-Error "Erreur lors de l'analyse de la structure du fichier markdown: $_"
        return $null
    }
}

# Fonction pour analyser les marqueurs de liste utilisÃ©s dans le contenu markdown
function Get-MarkdownListMarkers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $usedMarkers = @{}

    # Rechercher les lignes qui commencent par un marqueur de liste
    foreach ($marker in $script:MarkdownPatterns.ListMarkers) {
        $pattern = "(?m)^\s*\$marker\s+"
        $regexMatches = [regex]::Matches($Content, $pattern)
        if ($regexMatches.Count -gt 0) {
            $usedMarkers[$marker] = $regexMatches.Count
        }
    }

    return $usedMarkers
}

# Fonction pour analyser les conventions d'indentation utilisÃ©es dans le contenu markdown
function Get-MarkdownIndentationPattern {
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

    # DÃ©terminer l'indentation la plus courante
    if ($indentDifferences.Count -gt 0) {
        $mostCommonDiff = $indentDifferences.GetEnumerator() |
            Sort-Object -Property Value -Descending |
            Select-Object -First 1

        $indentationPattern.SpacesPerLevel = $mostCommonDiff.Key

        # VÃ©rifier si l'indentation est cohÃ©rente
        $totalDiffs = $indentDifferences.Values | Measure-Object -Sum | Select-Object -ExpandProperty Sum
        $consistencyRatio = $mostCommonDiff.Value / $totalDiffs

        $indentationPattern.ConsistentIndentation = ($consistencyRatio -ge 0.8)
    }

    return $indentationPattern
}

# Fonction pour analyser les formats de titres et sous-titres
function Get-MarkdownHeaderFormats {
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
        if ($regexMatches.Count -gt 0) {
            $headerFormats.HashHeaders[$i] = $regexMatches.Count
        }
    }

    # Rechercher les titres avec la syntaxe de soulignement
    $underlinePatterns = @{
        1 = "(?m)^.+\n=+$"  # Titre niveau 1 avec =
        2 = "(?m)^.+\n-+$"  # Titre niveau 2 avec -
    }

    foreach ($level in $underlinePatterns.Keys) {
        $pattern = $underlinePatterns[$level]
        $regexMatches = [regex]::Matches($Content, $pattern)
        if ($regexMatches.Count -gt 0) {
            $headerFormats.UnderlineHeaders[$level] = $regexMatches.Count
        }
    }

    return $headerFormats
}

# Fonction pour analyser les styles d'emphase (gras, italique)
function Get-MarkdownEmphasisStyles {
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
    $boldAsterisksPattern = "(?<!\\)\*\*(?!\*).+?(?<!\\)\*\*"
    $boldUnderscoresPattern = "(?<!\\)__(?!_).+?(?<!\\)__"

    $emphasisStyles.Bold.Asterisks = [regex]::Matches($Content, $boldAsterisksPattern).Count
    $emphasisStyles.Bold.Underscores = [regex]::Matches($Content, $boldUnderscoresPattern).Count

    # Rechercher les styles italiques
    $italicAsterisksPattern = "(?<!\*)\*(?!\*).+?(?<!\\)\*(?!\*)"
    $italicUnderscoresPattern = "(?<!_)_(?!_).+?(?<!\\)_(?!_)"

    $emphasisStyles.Italic.Asterisks = [regex]::Matches($Content, $italicAsterisksPattern).Count
    $emphasisStyles.Italic.Underscores = [regex]::Matches($Content, $italicUnderscoresPattern).Count

    # Rechercher les styles gras-italiques
    $boldItalicAsterisksPattern = "(?<!\\)\*\*\*(?!\*).+?(?<!\\)\*\*\*"
    $boldItalicUnderscoresPattern = "(?<!\\)___(?!_).+?(?<!\\)___"
    $boldItalicMixedPattern1 = "(?<!\\)\*\*_(?!_).+?(?<!\\)_\*\*"
    $boldItalicMixedPattern2 = "(?<!\\)__\*(?!\*).+?(?<!\\)\*__"

    $emphasisStyles.BoldItalic.Asterisks = [regex]::Matches($Content, $boldItalicAsterisksPattern).Count
    $emphasisStyles.BoldItalic.Underscores = [regex]::Matches($Content, $boldItalicUnderscoresPattern).Count
    $emphasisStyles.BoldItalic.Mixed = [regex]::Matches($Content, $boldItalicMixedPattern1).Count +
    [regex]::Matches($Content, $boldItalicMixedPattern2).Count

    return $emphasisStyles
}

# Fonction pour analyser la hiÃ©rarchie des tÃ¢ches
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

    # Analyser la hiÃ©rarchie des tÃ¢ches
    $currentDepth = 0
    $maxDepth = 0
    $numberingPatterns = @{}
    $parentChildCount = @{}

    $previousIndent = 0
    $indentToDepth = @{}

    foreach ($line in $lines) {
        if ($line -match '^\s*[-*+]') {
            $indent = ($line -match '^\s*').Matches[0].Value.Length

            # DÃ©terminer la profondeur basÃ©e sur l'indentation
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

            # Analyser les conventions de numÃ©rotation
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

    # Rechercher les marqueurs de statut personnalisÃ©s
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
        "en cours", "en attente", "terminÃ©", "complÃ©tÃ©", "bloquÃ©",
        "reportÃ©", "annulÃ©", "prioritaire", "urgent"
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

# Exporter les fonctions
Export-ModuleMember -Function Get-RoadmapStructure
