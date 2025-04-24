<#
.SYNOPSIS
    Formate un texte selon différentes options.

.DESCRIPTION
    La fonction Format-RoadmapText formate un texte selon différentes options.
    Elle prend en charge différents types de formatage et peut être utilisée pour
    formater les textes du module RoadmapParser.

.PARAMETER Text
    Le texte à formater.

.PARAMETER FormatType
    Le type de formatage à appliquer. Valeurs possibles :
    - Capitalize : Met en majuscule la première lettre de chaque mot
    - UpperCase : Met tout le texte en majuscules
    - LowerCase : Met tout le texte en minuscules
    - TitleCase : Met en majuscule la première lettre de chaque mot, en respectant certaines règles
    - SentenceCase : Met en majuscule la première lettre de chaque phrase
    - CamelCase : Met en minuscule la première lettre et en majuscule la première lettre des mots suivants
    - PascalCase : Met en majuscule la première lettre de chaque mot, sans espaces
    - SnakeCase : Remplace les espaces par des underscores et met tout en minuscules
    - KebabCase : Remplace les espaces par des tirets et met tout en minuscules
    - Trim : Supprime les espaces au début et à la fin du texte
    - TrimStart : Supprime les espaces au début du texte
    - TrimEnd : Supprime les espaces à la fin du texte
    - Indent : Indente chaque ligne du texte
    - Truncate : Tronque le texte à une longueur spécifiée
    - Pad : Complète le texte avec des caractères pour atteindre une longueur spécifiée
    - Wrap : Enveloppe le texte à une largeur spécifiée
    - Align : Aligne le texte (gauche, droite, centre, justifié)
    - Custom : Utilise un format personnalisé

.PARAMETER CustomFormat
    Le format personnalisé à utiliser pour le formatage.
    Utilisé uniquement lorsque FormatType est "Custom".

.PARAMETER Length
    La longueur à utiliser pour les types de formatage qui en ont besoin (Truncate, Pad, Wrap).

.PARAMETER PadCharacter
    Le caractère à utiliser pour le remplissage avec le type de formatage "Pad".
    Par défaut, c'est un espace.

.PARAMETER IndentLevel
    Le niveau d'indentation à utiliser avec le type de formatage "Indent".
    Par défaut, c'est 1.

.PARAMETER IndentChar
    Le caractère à utiliser pour l'indentation avec le type de formatage "Indent".
    Par défaut, c'est un espace.

.PARAMETER Alignment
    L'alignement à utiliser avec le type de formatage "Align".
    Valeurs possibles : Left, Right, Center, Justify.
    Par défaut, c'est "Left".

.PARAMETER PreserveLineBreaks
    Indique si les sauts de ligne doivent être préservés lors du formatage.
    Par défaut, c'est $true.

.PARAMETER Culture
    La culture à utiliser pour le formatage.
    Par défaut, c'est la culture actuelle.

.PARAMETER ErrorMessage
    Le message d'erreur à afficher en cas d'échec du formatage.
    Si non spécifié, un message par défaut sera utilisé.

.PARAMETER ThrowOnFailure
    Indique si une exception doit être levée en cas d'échec du formatage.

.EXAMPLE
    Format-RoadmapText -Text "hello world" -FormatType Capitalize
    Formate le texte "hello world" en "Hello World".

.EXAMPLE
    Format-RoadmapText -Text "hello world" -FormatType Indent -IndentLevel 2 -IndentChar "`t"
    Indente le texte "hello world" avec 2 tabulations.

.OUTPUTS
    [string] Le texte formaté.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-21
#>
function Format-RoadmapText {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$Text,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet("Capitalize", "UpperCase", "LowerCase", "TitleCase", "SentenceCase", "CamelCase", "PascalCase", "SnakeCase", "KebabCase", "Trim", "TrimStart", "TrimEnd", "Indent", "Truncate", "Pad", "Wrap", "Align", "Custom")]
        [string]$FormatType,

        [Parameter(Mandatory = $false)]
        [string]$CustomFormat,

        [Parameter(Mandatory = $false)]
        [int]$Length,

        [Parameter(Mandatory = $false)]
        [char]$PadCharacter = ' ',

        [Parameter(Mandatory = $false)]
        [int]$IndentLevel = 1,

        [Parameter(Mandatory = $false)]
        [char]$IndentChar = ' ',

        [Parameter(Mandatory = $false)]
        [ValidateSet("Left", "Right", "Center", "Justify")]
        [string]$Alignment = "Left",

        [Parameter(Mandatory = $false)]
        [switch]$PreserveLineBreaks = $true,

        [Parameter(Mandatory = $false)]
        [System.Globalization.CultureInfo]$Culture = [System.Globalization.CultureInfo]::CurrentCulture,

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage,

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )

    # Initialiser le résultat du formatage
    $result = $Text
    $formattingSucceeded = $false

    # Effectuer le formatage selon le type
    try {
        switch ($FormatType) {
            "Capitalize" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = ""
                } else {
                    $textInfo = $Culture.TextInfo
                    $result = $textInfo.ToTitleCase($Text.ToLower())
                }
                $formattingSucceeded = $true
            }
            "UpperCase" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = ""
                } else {
                    $textInfo = $Culture.TextInfo
                    $result = $textInfo.ToUpper($Text)
                }
                $formattingSucceeded = $true
            }
            "LowerCase" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = ""
                } else {
                    $textInfo = $Culture.TextInfo
                    $result = $textInfo.ToLower($Text)
                }
                $formattingSucceeded = $true
            }
            "TitleCase" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = ""
                } else {
                    $textInfo = $Culture.TextInfo
                    $result = $textInfo.ToTitleCase($Text.ToLower())
                    
                    # Appliquer des règles supplémentaires pour le TitleCase
                    $smallWords = @("a", "an", "and", "as", "at", "but", "by", "for", "if", "in", "nor", "of", "on", "or", "the", "to", "up", "yet")
                    $words = $result -split '\s+'
                    
                    for ($i = 1; $i -lt $words.Count; $i++) {
                        if ($smallWords -contains $words[$i].ToLower()) {
                            $words[$i] = $words[$i].ToLower()
                        }
                    }
                    
                    $result = $words -join " "
                }
                $formattingSucceeded = $true
            }
            "SentenceCase" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = ""
                } else {
                    $textInfo = $Culture.TextInfo
                    $result = $textInfo.ToLower($Text)
                    
                    # Mettre en majuscule la première lettre de chaque phrase
                    $sentences = [regex]::Split($result, '(?<=[.!?])\s+')
                    
                    for ($i = 0; $i -lt $sentences.Count; $i++) {
                        if (-not [string]::IsNullOrEmpty($sentences[$i])) {
                            $firstChar = $sentences[$i].Substring(0, 1)
                            $restOfSentence = if ($sentences[$i].Length -gt 1) { $sentences[$i].Substring(1) } else { "" }
                            $sentences[$i] = $textInfo.ToUpper($firstChar) + $restOfSentence
                        }
                    }
                    
                    $result = $sentences -join " "
                }
                $formattingSucceeded = $true
            }
            "CamelCase" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = ""
                } else {
                    $textInfo = $Culture.TextInfo
                    $words = $Text -split '\s+'
                    
                    for ($i = 0; $i -lt $words.Count; $i++) {
                        if (-not [string]::IsNullOrEmpty($words[$i])) {
                            $firstChar = $words[$i].Substring(0, 1)
                            $restOfWord = if ($words[$i].Length -gt 1) { $words[$i].Substring(1) } else { "" }
                            
                            if ($i -eq 0) {
                                $words[$i] = $textInfo.ToLower($firstChar) + $restOfWord
                            } else {
                                $words[$i] = $textInfo.ToUpper($firstChar) + $restOfWord
                            }
                        }
                    }
                    
                    $result = $words -join ""
                }
                $formattingSucceeded = $true
            }
            "PascalCase" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = ""
                } else {
                    $textInfo = $Culture.TextInfo
                    $words = $Text -split '\s+'
                    
                    for ($i = 0; $i -lt $words.Count; $i++) {
                        if (-not [string]::IsNullOrEmpty($words[$i])) {
                            $firstChar = $words[$i].Substring(0, 1)
                            $restOfWord = if ($words[$i].Length -gt 1) { $words[$i].Substring(1) } else { "" }
                            $words[$i] = $textInfo.ToUpper($firstChar) + $restOfWord
                        }
                    }
                    
                    $result = $words -join ""
                }
                $formattingSucceeded = $true
            }
            "SnakeCase" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = ""
                } else {
                    $textInfo = $Culture.TextInfo
                    $words = $Text -split '\s+'
                    $result = ($words | ForEach-Object { $textInfo.ToLower($_) }) -join "_"
                }
                $formattingSucceeded = $true
            }
            "KebabCase" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = ""
                } else {
                    $textInfo = $Culture.TextInfo
                    $words = $Text -split '\s+'
                    $result = ($words | ForEach-Object { $textInfo.ToLower($_) }) -join "-"
                }
                $formattingSucceeded = $true
            }
            "Trim" {
                $result = $Text.Trim()
                $formattingSucceeded = $true
            }
            "TrimStart" {
                $result = $Text.TrimStart()
                $formattingSucceeded = $true
            }
            "TrimEnd" {
                $result = $Text.TrimEnd()
                $formattingSucceeded = $true
            }
            "Indent" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = ""
                } else {
                    $indent = [string]::new($IndentChar, $IndentLevel * 4)
                    
                    if ($PreserveLineBreaks) {
                        $lines = $Text -split "`r`n|`r|`n"
                        $result = ($lines | ForEach-Object { $indent + $_ }) -join [Environment]::NewLine
                    } else {
                        $result = $indent + $Text
                    }
                }
                $formattingSucceeded = $true
            }
            "Truncate" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = ""
                } elseif (-not $PSBoundParameters.ContainsKey('Length')) {
                    throw "Le paramètre Length est requis pour le type de formatage Truncate."
                } else {
                    if ($Text.Length -le $Length) {
                        $result = $Text
                    } else {
                        $result = $Text.Substring(0, $Length)
                    }
                }
                $formattingSucceeded = $true
            }
            "Pad" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = [string]::new($PadCharacter, $Length)
                } elseif (-not $PSBoundParameters.ContainsKey('Length')) {
                    throw "Le paramètre Length est requis pour le type de formatage Pad."
                } else {
                    $result = $Text.PadRight($Length, $PadCharacter)
                }
                $formattingSucceeded = $true
            }
            "Wrap" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = ""
                } elseif (-not $PSBoundParameters.ContainsKey('Length')) {
                    throw "Le paramètre Length est requis pour le type de formatage Wrap."
                } else {
                    $lines = @()
                    $words = $Text -split '\s+'
                    $currentLine = ""
                    
                    foreach ($word in $words) {
                        if ($currentLine.Length -eq 0) {
                            $currentLine = $word
                        } elseif ($currentLine.Length + $word.Length + 1 -le $Length) {
                            $currentLine += " " + $word
                        } else {
                            $lines += $currentLine
                            $currentLine = $word
                        }
                    }
                    
                    if ($currentLine.Length -gt 0) {
                        $lines += $currentLine
                    }
                    
                    $result = $lines -join [Environment]::NewLine
                }
                $formattingSucceeded = $true
            }
            "Align" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = ""
                } elseif (-not $PSBoundParameters.ContainsKey('Length')) {
                    throw "Le paramètre Length est requis pour le type de formatage Align."
                } else {
                    if ($PreserveLineBreaks) {
                        $lines = $Text -split "`r`n|`r|`n"
                        $alignedLines = @()
                        
                        foreach ($line in $lines) {
                            switch ($Alignment) {
                                "Left" {
                                    $alignedLines += $line.PadRight($Length)
                                }
                                "Right" {
                                    $alignedLines += $line.PadLeft($Length)
                                }
                                "Center" {
                                    $padLeft = [math]::Floor(($Length - $line.Length) / 2)
                                    $padRight = $Length - $line.Length - $padLeft
                                    $alignedLines += [string]::new(' ', $padLeft) + $line + [string]::new(' ', $padRight)
                                }
                                "Justify" {
                                    if ($line.Length -ge $Length -or $line.Trim() -eq "") {
                                        $alignedLines += $line.PadRight($Length)
                                    } else {
                                        $words = $line -split '\s+'
                                        $totalSpaces = $Length - ($words -join "").Length
                                        $gaps = $words.Count - 1
                                        
                                        if ($gaps -eq 0) {
                                            $alignedLines += $line.PadRight($Length)
                                        } else {
                                            $spacesPerGap = [math]::Floor($totalSpaces / $gaps)
                                            $extraSpaces = $totalSpaces - ($spacesPerGap * $gaps)
                                            $justifiedLine = ""
                                            
                                            for ($i = 0; $i -lt $words.Count - 1; $i++) {
                                                $justifiedLine += $words[$i]
                                                $spacesToAdd = $spacesPerGap
                                                
                                                if ($i -lt $extraSpaces) {
                                                    $spacesToAdd++
                                                }
                                                
                                                $justifiedLine += [string]::new(' ', $spacesToAdd)
                                            }
                                            
                                            $justifiedLine += $words[-1]
                                            $alignedLines += $justifiedLine
                                        }
                                    }
                                }
                            }
                        }
                        
                        $result = $alignedLines -join [Environment]::NewLine
                    } else {
                        switch ($Alignment) {
                            "Left" {
                                $result = $Text.PadRight($Length)
                            }
                            "Right" {
                                $result = $Text.PadLeft($Length)
                            }
                            "Center" {
                                $padLeft = [math]::Floor(($Length - $Text.Length) / 2)
                                $padRight = $Length - $Text.Length - $padLeft
                                $result = [string]::new(' ', $padLeft) + $Text + [string]::new(' ', $padRight)
                            }
                            "Justify" {
                                if ($Text.Length -ge $Length -or $Text.Trim() -eq "") {
                                    $result = $Text.PadRight($Length)
                                } else {
                                    $words = $Text -split '\s+'
                                    $totalSpaces = $Length - ($words -join "").Length
                                    $gaps = $words.Count - 1
                                    
                                    if ($gaps -eq 0) {
                                        $result = $Text.PadRight($Length)
                                    } else {
                                        $spacesPerGap = [math]::Floor($totalSpaces / $gaps)
                                        $extraSpaces = $totalSpaces - ($spacesPerGap * $gaps)
                                        $justifiedLine = ""
                                        
                                        for ($i = 0; $i -lt $words.Count - 1; $i++) {
                                            $justifiedLine += $words[$i]
                                            $spacesToAdd = $spacesPerGap
                                            
                                            if ($i -lt $extraSpaces) {
                                                $spacesToAdd++
                                            }
                                            
                                            $justifiedLine += [string]::new(' ', $spacesToAdd)
                                        }
                                        
                                        $justifiedLine += $words[-1]
                                        $result = $justifiedLine
                                    }
                                }
                            }
                        }
                    }
                }
                $formattingSucceeded = $true
            }
            "Custom" {
                if ([string]::IsNullOrEmpty($CustomFormat)) {
                    throw "Le paramètre CustomFormat est requis lorsque le type de formatage est Custom."
                } else {
                    # Utiliser le format personnalisé pour formater le texte
                    $result = $Text -f $CustomFormat
                }
                $formattingSucceeded = $true
            }
        }
    } catch {
        $formattingSucceeded = $false
        if ([string]::IsNullOrEmpty($ErrorMessage)) {
            $ErrorMessage = "Impossible de formater le texte avec le type de formatage $FormatType : $_"
        }
    }

    # Gérer l'échec du formatage
    if (-not $formattingSucceeded) {
        if ($ThrowOnFailure) {
            throw $ErrorMessage
        } else {
            Write-Warning $ErrorMessage
            return $Text
        }
    }

    return $result
}
