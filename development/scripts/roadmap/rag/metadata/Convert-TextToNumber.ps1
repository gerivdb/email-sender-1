# Convert-TextToNumber.ps1
# Script pour convertir les nombres écrits en toutes lettres en valeurs numériques
# Version: 1.0
# Date: 2025-05-15

# Dictionnaire des nombres en français
$frenchNumbers = @{
    # Unités
    "zéro"             = 0
    "zero"             = 0
    "un"               = 1
    "une"              = 1
    "deux"             = 2
    "trois"            = 3
    "quatre"           = 4
    "cinq"             = 5
    "six"              = 6
    "sept"             = 7
    "huit"             = 8
    "neuf"             = 9

    # Nombres de 10 à 19
    "dix"              = 10
    "onze"             = 11
    "douze"            = 12
    "treize"           = 13
    "quatorze"         = 14
    "quinze"           = 15
    "seize"            = 16
    "dix-sept"         = 17
    "dixsept"          = 17
    "dix sept"         = 17
    "dix-huit"         = 18
    "dixhuit"          = 18
    "dix huit"         = 18
    "dix-neuf"         = 19
    "dixneuf"          = 19
    "dix neuf"         = 19

    # Dizaines
    "vingt"            = 20
    "trente"           = 30
    "quarante"         = 40
    "cinquante"        = 50
    "soixante"         = 60
    "soixante-dix"     = 70
    "soixantedix"      = 70
    "soixante dix"     = 70
    "quatre-vingt"     = 80
    "quatrevingt"      = 80
    "quatre vingt"     = 80
    "quatre-vingts"    = 80
    "quatrevingts"     = 80
    "quatre vingts"    = 80
    "quatre-vingt-dix" = 90
    "quatrevingtdix"   = 90
    "quatre vingt dix" = 90

    # Multiplicateurs
    "cent"             = 100
    "cents"            = 100
    "mille"            = 1000
    "million"          = 1000000
    "millions"         = 1000000
    "milliard"         = 1000000000
    "milliards"        = 1000000000
}

# Dictionnaire des nombres en anglais
$englishNumbers = @{
    # Unités
    "zero"      = 0
    "one"       = 1
    "two"       = 2
    "three"     = 3
    "four"      = 4
    "five"      = 5
    "six"       = 6
    "seven"     = 7
    "eight"     = 8
    "nine"      = 9

    # Nombres de 10 à 19
    "ten"       = 10
    "eleven"    = 11
    "twelve"    = 12
    "thirteen"  = 13
    "fourteen"  = 14
    "fifteen"   = 15
    "sixteen"   = 16
    "seventeen" = 17
    "eighteen"  = 18
    "nineteen"  = 19

    # Dizaines
    "twenty"    = 20
    "thirty"    = 30
    "forty"     = 40
    "fifty"     = 50
    "sixty"     = 60
    "seventy"   = 70
    "eighty"    = 80
    "ninety"    = 90

    # Multiplicateurs
    "hundred"   = 100
    "thousand"  = 1000
    "million"   = 1000000
    "billion"   = 1000000000
}

# Fonction pour convertir un nombre écrit en toutes lettres en valeur numérique
function ConvertFrom-TextToNumber {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Auto", "French", "English")]
        [string]$Language = "Auto"
    )

    # Normaliser le texte (minuscules, sans accents)
    $normalizedText = $Text.ToLower()
    $normalizedText = $normalizedText -replace '[éèêë]', 'e'
    $normalizedText = $normalizedText -replace '[àâä]', 'a'
    $normalizedText = $normalizedText -replace '[ùûü]', 'u'
    $normalizedText = $normalizedText -replace '[ôö]', 'o'
    $normalizedText = $normalizedText -replace '[îï]', 'i'
    $normalizedText = $normalizedText -replace '[ÿ]', 'y'
    $normalizedText = $normalizedText -replace '[ç]', 'c'

    # Déterminer la langue si Auto est spécifié
    if ($Language -eq "Auto") {
        # Compter les mots français et anglais
        $frenchWords = 0
        $englishWords = 0

        $words = $normalizedText -split '\s+|-'
        foreach ($word in $words) {
            if ($frenchNumbers.ContainsKey($word)) {
                $frenchWords++
            }
            if ($englishNumbers.ContainsKey($word)) {
                $englishWords++
            }
        }

        # Déterminer la langue en fonction du nombre de mots reconnus
        if ($frenchWords -gt $englishWords) {
            $Language = "French"
        } else {
            $Language = "English"
        }
    }

    # Sélectionner le dictionnaire approprié
    $numberDictionary = if ($Language -eq "French") { $frenchNumbers } else { $englishNumbers }

    # Traiter le texte en fonction de la langue
    if ($Language -eq "French") {
        return Convert-FrenchTextToNumber -Text $normalizedText
    } else {
        return Convert-EnglishTextToNumber -Text $normalizedText
    }
}

# Fonction pour convertir un nombre écrit en français en valeur numérique
function Convert-FrenchTextToNumber {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    # Cas spéciaux pour les nombres composés
    $specialCases = @{
        "quatre vingt"      = 80
        "quatre vingts"     = 80
        "quatre vingt dix"  = 90
        "quatre vingts dix" = 90
        "soixante dix"      = 70
        "vingt et un"       = 21
        "trente et un"      = 31
        "quarante et un"    = 41
        "cinquante et un"   = 51
        "soixante et un"    = 61
        "soixante et onze"  = 71
        "quatre vingt un"   = 81
        "quatre vingt onze" = 91
    }

    # Vérifier si le texte correspond à un cas spécial
    $normalizedText = $Text.ToLower() -replace '-', ' ' -replace '\s+', ' '
    if ($specialCases.ContainsKey($normalizedText)) {
        return $specialCases[$normalizedText]
    }

    # Remplacer les tirets et les espaces multiples par des espaces simples
    $Text = $Text -replace '-', ' '
    $Text = $Text -replace '\s+', ' '

    # Diviser le texte en mots
    $words = $Text -split '\s+'

    # Initialiser les variables
    $result = 0
    $currentNumber = 0

    # Parcourir les mots
    foreach ($word in $words) {
        # Ignorer les mots vides ou non reconnus
        if ([string]::IsNullOrEmpty($word) -or -not $frenchNumbers.ContainsKey($word)) {
            continue
        }

        $value = $frenchNumbers[$word]

        # Traiter les multiplicateurs
        if ($value -eq 100) {
            # Cent
            if ($currentNumber -eq 0) {
                $currentNumber = 1
            }
            $currentNumber *= 100
        } elseif ($value -eq 1000) {
            # Mille
            if ($currentNumber -eq 0) {
                $currentNumber = 1
            }
            $currentNumber *= 1000
            $result += $currentNumber
            $currentNumber = 0
        } elseif ($value -eq 1000000 -or $value -eq 1000000000) {
            # Million ou Milliard
            if ($currentNumber -eq 0) {
                $currentNumber = 1
            }
            $currentNumber *= $value
            $result += $currentNumber
            $currentNumber = 0
        } else {
            # Nombres simples
            if ($value -lt 100) {
                # Cas spécial pour "quatre-vingt-un", "soixante-et-onze", etc.
                if ($currentNumber % 100 -eq 80 -or $currentNumber % 100 -eq 60) {
                    if ($value -le 19) {
                        $currentNumber += $value
                    } else {
                        $currentNumber += $value
                    }
                } else {
                    $currentNumber += $value
                }
            } else {
                $currentNumber = $value
            }
        }
    }

    # Ajouter le dernier nombre calculé
    $result += $currentNumber

    return $result
}

# Fonction pour convertir un nombre écrit en anglais en valeur numérique
function Convert-EnglishTextToNumber {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    # Remplacer les tirets et les espaces multiples par des espaces simples
    $Text = $Text -replace '-', ' '
    $Text = $Text -replace '\s+', ' '

    # Diviser le texte en mots
    $words = $Text -split '\s+'

    # Initialiser les variables
    $result = 0
    $currentNumber = 0

    # Parcourir les mots
    foreach ($word in $words) {
        # Ignorer les mots vides ou non reconnus
        if ([string]::IsNullOrEmpty($word) -or -not $englishNumbers.ContainsKey($word)) {
            continue
        }

        $value = $englishNumbers[$word]

        # Traiter les multiplicateurs
        if ($value -eq 100) {
            # Hundred
            if ($currentNumber -eq 0) {
                $currentNumber = 1
            }
            $currentNumber *= 100
        } elseif ($value -eq 1000) {
            # Thousand
            if ($currentNumber -eq 0) {
                $currentNumber = 1
            }
            $currentNumber *= 1000
            $result += $currentNumber
            $currentNumber = 0
        } elseif ($value -eq 1000000 -or $value -eq 1000000000) {
            # Million ou Billion
            if ($currentNumber -eq 0) {
                $currentNumber = 1
            }
            $currentNumber *= $value
            $result += $currentNumber
            $currentNumber = 0
        } else {
            # Nombres simples
            if ($value -lt 100) {
                $currentNumber += $value
            } else {
                $currentNumber = $value
            }
        }
    }

    # Ajouter le dernier nombre calculé
    $result += $currentNumber

    return $result
}

# Fonction principale pour détecter et convertir les nombres écrits en toutes lettres dans un texte
function Get-TextualNumbers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Auto", "French", "English")]
        [string]$Language = "Auto"
    )

    # Expressions régulières pour détecter les nombres écrits en toutes lettres
    $frenchPattern = '\b(?:(?:vingt-cinq|vingt cinq|deux cent cinquante|deux cents cinquante|zero|zéro|un|une|deux|trois|quatre|cinq|six|sept|huit|neuf|dix|onze|douze|treize|quatorze|quinze|seize|dix-sept|dixsept|dix sept|dix-huit|dixhuit|dix huit|dix-neuf|dixneuf|dix neuf|vingt|trente|quarante|cinquante|soixante|soixante-dix|soixantedix|soixante dix|quatre-vingt|quatrevingt|quatre vingt|quatre-vingts|quatrevingts|quatre vingts|quatre-vingt-dix|quatrevingtdix|quatre vingt dix)(?:\s+et\s+(?:un|une))?(?:\s+(?:cent|cents|mille|million|millions|milliard|milliards))?(?:\s+(?:zero|zéro|un|une|deux|trois|quatre|cinq|six|sept|huit|neuf|dix|onze|douze|treize|quatorze|quinze|seize|dix-sept|dixsept|dix sept|dix-huit|dixhuit|dix huit|dix-neuf|dixneuf|dix neuf|vingt|trente|quarante|cinquante|soixante|soixante-dix|soixantedix|soixante dix|quatre-vingt|quatrevingt|quatre vingt|quatre-vingts|quatrevingts|quatre vingts|quatre-vingt-dix|quatrevingtdix|quatre vingt dix))*)\b'

    $englishPattern = '\b(?:(?:twenty five|twenty-five|two hundred fifty|zero|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety)(?:\s+(?:hundred|thousand|million|billion))?(?:\s+(?:zero|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety))*)\b'

    # Sélectionner le pattern approprié
    $pattern = if ($Language -eq "French") { $frenchPattern } elseif ($Language -eq "English") { $englishPattern } else { "($frenchPattern)|($englishPattern)" }

    # Trouver tous les nombres écrits en toutes lettres
    $regexMatches = [regex]::Matches($Text, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

    # Convertir chaque nombre trouvé
    $result = @()
    foreach ($match in $regexMatches) {
        $textualNumber = $match.Value
        $numericValue = ConvertFrom-TextToNumber -Text $textualNumber -Language $Language

        $result += [PSCustomObject]@{
            TextualNumber = $textualNumber
            NumericValue  = $numericValue
            StartIndex    = $match.Index
            Length        = $match.Length
        }
    }

    return $result
}

# Pas besoin d'exporter les fonctions car ce n'est pas un module PowerShell
