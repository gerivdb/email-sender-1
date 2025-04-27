<#
.SYNOPSIS
    Recherche un motif dans un texte.

.DESCRIPTION
    La fonction Search-RoadmapText recherche un motif dans un texte.
    Elle prend en charge diffÃ©rents types de recherche et peut Ãªtre utilisÃ©e pour
    rechercher des motifs dans les textes du module RoadmapParser.

.PARAMETER Text
    Le texte dans lequel effectuer la recherche.

.PARAMETER Pattern
    Le motif Ã  rechercher.

.PARAMETER SearchType
    Le type de recherche Ã  effectuer. Valeurs possibles :
    - Simple : Recherche simple (sensible Ã  la casse)
    - CaseInsensitive : Recherche insensible Ã  la casse
    - Regex : Recherche par expression rÃ©guliÃ¨re
    - Wildcard : Recherche avec caractÃ¨res gÃ©nÃ©riques
    - WholeWord : Recherche de mots entiers
    - StartsWith : Recherche au dÃ©but du texte
    - EndsWith : Recherche Ã  la fin du texte
    - Contains : Recherche dans tout le texte
    - Exact : Recherche exacte (Ã©galitÃ©)
    - Custom : Recherche personnalisÃ©e

.PARAMETER CustomSearch
    La fonction de recherche personnalisÃ©e Ã  utiliser.
    UtilisÃ© uniquement lorsque SearchType est "Custom".

.PARAMETER IncludeLineNumbers
    Indique si les numÃ©ros de ligne doivent Ãªtre inclus dans les rÃ©sultats.
    Par dÃ©faut, c'est $false.

.PARAMETER IncludeContext
    Indique si le contexte (lignes avant et aprÃ¨s) doit Ãªtre inclus dans les rÃ©sultats.
    Par dÃ©faut, c'est $false.

.PARAMETER ContextLines
    Le nombre de lignes de contexte Ã  inclure avant et aprÃ¨s chaque correspondance.
    Par dÃ©faut, c'est 2.

.PARAMETER MaxResults
    Le nombre maximum de rÃ©sultats Ã  retourner.
    Par dÃ©faut, c'est 0 (tous les rÃ©sultats).

.PARAMETER Culture
    La culture Ã  utiliser pour la recherche.
    Par dÃ©faut, c'est la culture actuelle.

.PARAMETER ErrorMessage
    Le message d'erreur Ã  afficher en cas d'Ã©chec de la recherche.
    Si non spÃ©cifiÃ©, un message par dÃ©faut sera utilisÃ©.

.PARAMETER ThrowOnFailure
    Indique si une exception doit Ãªtre levÃ©e en cas d'Ã©chec de la recherche.

.EXAMPLE
    Search-RoadmapText -Text "Hello World" -Pattern "world" -SearchType CaseInsensitive
    Recherche "world" dans "Hello World" de maniÃ¨re insensible Ã  la casse.

.EXAMPLE
    Search-RoadmapText -Text "Hello World" -Pattern "^Hello" -SearchType Regex
    Recherche le motif regex "^Hello" dans "Hello World".

.OUTPUTS
    [PSCustomObject[]] Les rÃ©sultats de la recherche, avec les propriÃ©tÃ©s suivantes :
    - Match : Le texte correspondant
    - Index : L'index de dÃ©but de la correspondance
    - Length : La longueur de la correspondance
    - LineNumber : Le numÃ©ro de ligne (si IncludeLineNumbers est $true)
    - Context : Le contexte (si IncludeContext est $true)

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-21
#>
function Search-RoadmapText {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$Text,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Pattern,

        [Parameter(Mandatory = $true, Position = 2)]
        [ValidateSet("Simple", "CaseInsensitive", "Regex", "Wildcard", "WholeWord", "StartsWith", "EndsWith", "Contains", "Exact", "Custom")]
        [string]$SearchType,

        [Parameter(Mandatory = $false)]
        [scriptblock]$CustomSearch,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeLineNumbers,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeContext,

        [Parameter(Mandatory = $false)]
        [int]$ContextLines = 2,

        [Parameter(Mandatory = $false)]
        [int]$MaxResults = 0,

        [Parameter(Mandatory = $false)]
        [System.Globalization.CultureInfo]$Culture = [System.Globalization.CultureInfo]::CurrentCulture,

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage,

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )

    # Initialiser les rÃ©sultats de la recherche
    $results = @()
    $searchSucceeded = $false

    # Effectuer la recherche selon le type
    try {
        switch ($SearchType) {
            "Simple" {
                if ([string]::IsNullOrEmpty($Text) -or [string]::IsNullOrEmpty($Pattern)) {
                    $results = @()
                } else {
                    $index = 0
                    $matches = @()

                    while (($index = $Text.IndexOf($Pattern, $index)) -ge 0) {
                        $matches += [PSCustomObject]@{
                            Match  = $Pattern
                            Index  = $index
                            Length = $Pattern.Length
                        }
                        $index += $Pattern.Length
                    }

                    $results = $matches
                }
                $searchSucceeded = $true
            }
            "CaseInsensitive" {
                if ([string]::IsNullOrEmpty($Text) -or [string]::IsNullOrEmpty($Pattern)) {
                    $results = @()
                } else {
                    $index = 0
                    $matches = @()
                    $textLower = $Text.ToLower()
                    $patternLower = $Pattern.ToLower()

                    while (($index = $textLower.IndexOf($patternLower, $index)) -ge 0) {
                        $matches += [PSCustomObject]@{
                            Match  = $Text.Substring($index, $Pattern.Length)
                            Index  = $index
                            Length = $Pattern.Length
                        }
                        $index += $Pattern.Length
                    }

                    $results = $matches
                }
                $searchSucceeded = $true
            }
            "Regex" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $results = @()
                } else {
                    $regex = [regex]$Pattern
                    $matches = $regex.Matches($Text)

                    $results = $matches | ForEach-Object {
                        [PSCustomObject]@{
                            Match  = $_.Value
                            Index  = $_.Index
                            Length = $_.Length
                        }
                    }
                }
                $searchSucceeded = $true
            }
            "Wildcard" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $results = @()
                } else {
                    # Convertir le motif wildcard en regex
                    $regexPattern = "^" + [regex]::Escape($Pattern).Replace("\*", ".*").Replace("\?", ".") + "$"
                    $regex = [regex]$regexPattern

                    # Diviser le texte en lignes et rechercher dans chaque ligne
                    $lines = $Text -split "`r`n|`r|`n"
                    $index = 0
                    $matches = @()

                    foreach ($line in $lines) {
                        if ($regex.IsMatch($line)) {
                            $matches += [PSCustomObject]@{
                                Match  = $line
                                Index  = $index
                                Length = $line.Length
                            }
                        }
                        $index += $line.Length + 2  # +2 pour le saut de ligne
                    }

                    $results = $matches
                }
                $searchSucceeded = $true
            }
            "WholeWord" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $results = @()
                } else {
                    # CrÃ©er un motif regex pour les mots entiers
                    $regexPattern = "\b" + [regex]::Escape($Pattern) + "\b"
                    $regex = [regex]$regexPattern
                    $matches = $regex.Matches($Text)

                    $results = $matches | ForEach-Object {
                        [PSCustomObject]@{
                            Match  = $_.Value
                            Index  = $_.Index
                            Length = $_.Length
                        }
                    }
                }
                $searchSucceeded = $true
            }
            "StartsWith" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $results = @()
                } else {
                    if ($Text.StartsWith($Pattern)) {
                        $results = @(
                            [PSCustomObject]@{
                                Match  = $Pattern
                                Index  = 0
                                Length = $Pattern.Length
                            }
                        )
                    } else {
                        $results = @()
                    }
                }
                $searchSucceeded = $true
            }
            "EndsWith" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $results = @()
                } else {
                    if ($Text.EndsWith($Pattern)) {
                        $index = $Text.Length - $Pattern.Length
                        $results = @(
                            [PSCustomObject]@{
                                Match  = $Pattern
                                Index  = $index
                                Length = $Pattern.Length
                            }
                        )
                    } else {
                        $results = @()
                    }
                }
                $searchSucceeded = $true
            }
            "Contains" {
                if ([string]::IsNullOrEmpty($Text) -or [string]::IsNullOrEmpty($Pattern)) {
                    $results = @()
                } else {
                    $index = 0
                    $matches = @()

                    while (($index = $Text.IndexOf($Pattern, $index)) -ge 0) {
                        $matches += [PSCustomObject]@{
                            Match  = $Pattern
                            Index  = $index
                            Length = $Pattern.Length
                        }
                        $index += $Pattern.Length
                    }

                    $results = $matches
                }
                $searchSucceeded = $true
            }
            "Exact" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $results = @()
                } else {
                    if ($Text -eq $Pattern) {
                        $results = @(
                            [PSCustomObject]@{
                                Match  = $Text
                                Index  = 0
                                Length = $Text.Length
                            }
                        )
                    } else {
                        $results = @()
                    }
                }
                $searchSucceeded = $true
            }
            "Custom" {
                if ($null -eq $CustomSearch) {
                    throw "Le paramÃ¨tre CustomSearch est requis lorsque le type de recherche est Custom."
                } else {
                    $results = & $CustomSearch $Text $Pattern
                }
                $searchSucceeded = $true
            }
        }

        # Ajouter les numÃ©ros de ligne si demandÃ©
        if ($IncludeLineNumbers -and $results.Count -gt 0) {
            $lines = $Text -split "`r`n|`r|`n"
            $lineStartIndices = @(0)
            $currentIndex = 0

            foreach ($line in $lines) {
                $currentIndex += $line.Length + 2  # +2 pour le saut de ligne
                $lineStartIndices += $currentIndex
            }

            foreach ($result in $results) {
                $lineNumber = 1
                for ($i = 1; $i -lt $lineStartIndices.Count; $i++) {
                    if ($result.Index -lt $lineStartIndices[$i]) {
                        $lineNumber = $i
                        break
                    }
                }

                $result | Add-Member -MemberType NoteProperty -Name "LineNumber" -Value $lineNumber
            }
        }

        # Ajouter le contexte si demandÃ©
        if ($IncludeContext -and $results.Count -gt 0) {
            $lines = $Text -split "`r`n|`r|`n"

            # S'assurer que les numÃ©ros de ligne sont inclus
            $hasLineNumbers = $true
            foreach ($result in $results) {
                if (-not ($result.PSObject.Properties.Name -contains "LineNumber")) {
                    $hasLineNumbers = $false
                    break
                }
            }
            if (-not $hasLineNumbers) {
                $lineStartIndices = @(0)
                $currentIndex = 0

                foreach ($line in $lines) {
                    $currentIndex += $line.Length + 2  # +2 pour le saut de ligne
                    $lineStartIndices += $currentIndex
                }

                foreach ($result in $results) {
                    $lineNumber = 1
                    for ($i = 1; $i -lt $lineStartIndices.Count; $i++) {
                        if ($result.Index -lt $lineStartIndices[$i]) {
                            $lineNumber = $i
                            break
                        }
                    }

                    $result | Add-Member -MemberType NoteProperty -Name "LineNumber" -Value $lineNumber
                }
            }

            foreach ($result in $results) {
                $lineNumber = $result.LineNumber
                $startLine = [Math]::Max(1, $lineNumber - $ContextLines)
                $endLine = [Math]::Min($lines.Count, $lineNumber + $ContextLines)

                $contextLines = @()
                for ($i = $startLine; $i -le $endLine; $i++) {
                    $contextLines += [PSCustomObject]@{
                        LineNumber = $i
                        Text       = $lines[$i - 1]
                        IsMatch    = $i -eq $lineNumber
                    }
                }

                $result | Add-Member -MemberType NoteProperty -Name "Context" -Value $contextLines
            }
        }

        # Limiter le nombre de rÃ©sultats si demandÃ©
        if ($MaxResults -gt 0 -and $results.Count -gt $MaxResults) {
            $results = $results | Select-Object -First $MaxResults
        }
    } catch {
        $searchSucceeded = $false
        if ([string]::IsNullOrEmpty($ErrorMessage)) {
            $ErrorMessage = "Impossible de rechercher le motif '$Pattern' dans le texte avec le type de recherche $SearchType : $_"
        }
    }

    # GÃ©rer l'Ã©chec de la recherche
    if (-not $searchSucceeded) {
        if ($ThrowOnFailure) {
            throw $ErrorMessage
        } else {
            Write-Warning $ErrorMessage
            return @()
        }
    }

    return $results
}
