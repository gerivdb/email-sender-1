<#
.SYNOPSIS
    Recherche un motif dans un texte.

.DESCRIPTION
    La fonction Search-RoadmapText recherche un motif dans un texte.
    Elle prend en charge différents types de recherche et peut être utilisée pour
    rechercher des motifs dans les textes du module RoadmapParser.

.PARAMETER Text
    Le texte dans lequel effectuer la recherche.

.PARAMETER Pattern
    Le motif à rechercher.

.PARAMETER SearchType
    Le type de recherche à effectuer. Valeurs possibles :
    - Simple : Recherche simple (sensible à la casse)
    - CaseInsensitive : Recherche insensible à la casse
    - Regex : Recherche par expression régulière
    - Wildcard : Recherche avec caractères génériques
    - WholeWord : Recherche de mots entiers
    - StartsWith : Recherche au début du texte
    - EndsWith : Recherche à la fin du texte
    - Contains : Recherche dans tout le texte
    - Exact : Recherche exacte (égalité)
    - Custom : Recherche personnalisée

.PARAMETER CustomSearch
    La fonction de recherche personnalisée à utiliser.
    Utilisé uniquement lorsque SearchType est "Custom".

.PARAMETER IncludeLineNumbers
    Indique si les numéros de ligne doivent être inclus dans les résultats.
    Par défaut, c'est $false.

.PARAMETER IncludeContext
    Indique si le contexte (lignes avant et après) doit être inclus dans les résultats.
    Par défaut, c'est $false.

.PARAMETER ContextLines
    Le nombre de lignes de contexte à inclure avant et après chaque correspondance.
    Par défaut, c'est 2.

.PARAMETER MaxResults
    Le nombre maximum de résultats à retourner.
    Par défaut, c'est 0 (tous les résultats).

.PARAMETER Culture
    La culture à utiliser pour la recherche.
    Par défaut, c'est la culture actuelle.

.PARAMETER ErrorMessage
    Le message d'erreur à afficher en cas d'échec de la recherche.
    Si non spécifié, un message par défaut sera utilisé.

.PARAMETER ThrowOnFailure
    Indique si une exception doit être levée en cas d'échec de la recherche.

.EXAMPLE
    Search-RoadmapText -Text "Hello World" -Pattern "world" -SearchType CaseInsensitive
    Recherche "world" dans "Hello World" de manière insensible à la casse.

.EXAMPLE
    Search-RoadmapText -Text "Hello World" -Pattern "^Hello" -SearchType Regex
    Recherche le motif regex "^Hello" dans "Hello World".

.OUTPUTS
    [PSCustomObject[]] Les résultats de la recherche, avec les propriétés suivantes :
    - Match : Le texte correspondant
    - Index : L'index de début de la correspondance
    - Length : La longueur de la correspondance
    - LineNumber : Le numéro de ligne (si IncludeLineNumbers est $true)
    - Context : Le contexte (si IncludeContext est $true)

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-21
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

    # Initialiser les résultats de la recherche
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
                    # Créer un motif regex pour les mots entiers
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
                    throw "Le paramètre CustomSearch est requis lorsque le type de recherche est Custom."
                } else {
                    $results = & $CustomSearch $Text $Pattern
                }
                $searchSucceeded = $true
            }
        }

        # Ajouter les numéros de ligne si demandé
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

        # Ajouter le contexte si demandé
        if ($IncludeContext -and $results.Count -gt 0) {
            $lines = $Text -split "`r`n|`r|`n"

            # S'assurer que les numéros de ligne sont inclus
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

        # Limiter le nombre de résultats si demandé
        if ($MaxResults -gt 0 -and $results.Count -gt $MaxResults) {
            $results = $results | Select-Object -First $MaxResults
        }
    } catch {
        $searchSucceeded = $false
        if ([string]::IsNullOrEmpty($ErrorMessage)) {
            $ErrorMessage = "Impossible de rechercher le motif '$Pattern' dans le texte avec le type de recherche $SearchType : $_"
        }
    }

    # Gérer l'échec de la recherche
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
