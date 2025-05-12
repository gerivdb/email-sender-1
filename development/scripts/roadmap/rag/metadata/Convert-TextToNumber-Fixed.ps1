# Convert-TextToNumber-Fixed.ps1
# Script pour convertir les nombres ecrits en toutes lettres en valeurs numeriques
# Version: 1.0
# Date: 2025-05-15

# Dictionnaire des nombres en francais
$frenchNumbers = @{
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
    "vingt"            = 20
    "vingt et un"      = 21
    "trente"           = 30
    "trente et un"     = 31
    "quarante"         = 40
    "quarante et un"   = 41
    "cinquante"        = 50
    "cinquante et un"  = 51
    "soixante"         = 60
    "soixante et un"   = 61
    "soixante-dix"     = 70
    "soixantedix"      = 70
    "soixante dix"     = 70
    "soixante et onze" = 71
    "quatre-vingt"     = 80
    "quatrevingt"      = 80
    "quatre vingt"     = 80
    "quatre-vingts"    = 80
    "quatrevingts"     = 80
    "quatre vingts"    = 80
    "quatre-vingt-dix" = 90
    "quatrevingtdix"   = 90
    "quatre vingt dix" = 90
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
    "zero"        = 0
    "one"         = 1
    "two"         = 2
    "three"       = 3
    "four"        = 4
    "five"        = 5
    "six"         = 6
    "seven"       = 7
    "eight"       = 8
    "nine"        = 9
    "ten"         = 10
    "eleven"      = 11
    "twelve"      = 12
    "thirteen"    = 13
    "fourteen"    = 14
    "fifteen"     = 15
    "sixteen"     = 16
    "seventeen"   = 17
    "eighteen"    = 18
    "nineteen"    = 19
    "twenty"      = 20
    "twenty one"  = 21
    "twenty-one"  = 21
    "thirty"      = 30
    "thirty one"  = 31
    "thirty-one"  = 31
    "forty"       = 40
    "forty one"   = 41
    "forty-one"   = 41
    "fifty"       = 50
    "fifty one"   = 51
    "fifty-one"   = 51
    "sixty"       = 60
    "sixty one"   = 61
    "sixty-one"   = 61
    "seventy"     = 70
    "seventy one" = 71
    "seventy-one" = 71
    "eighty"      = 80
    "eighty one"  = 81
    "eighty-one"  = 81
    "ninety"      = 90
    "ninety one"  = 91
    "ninety-one"  = 91
    "hundred"     = 100
    "thousand"    = 1000
    "million"     = 1000000
    "billion"     = 1000000000
}

# Fonction pour convertir un nombre ecrit en francais en valeur numerique
function Convert-FrenchTextToNumber {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    # Cas speciaux pour les nombres composes
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

    # Verifier si le texte correspond a un cas special
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
            $currentNumber += $value
        }
    }

    # Ajouter le nombre courant au resultat
    $result += $currentNumber

    return $result
}

# Fonction pour convertir un nombre ecrit en anglais en valeur numerique
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
            $currentNumber += $value
        }
    }

    # Ajouter le nombre courant au resultat
    $result += $currentNumber

    return $result
}

# Fonction pour convertir un nombre ecrit en toutes lettres en valeur numerique
function ConvertFrom-TextToNumber {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Auto", "French", "English")]
        [string]$Language = "Auto"
    )

    # Determiner la langue si Auto est specifie
    if ($Language -eq "Auto") {
        # Compter les mots francais et anglais
        $frenchWords = 0
        $englishWords = 0

        # Normaliser le texte
        $normalizedText = $Text.ToLower() -replace '-', ' ' -replace '\s+', ' '
        $words = $normalizedText -split '\s+'

        foreach ($word in $words) {
            if ($frenchNumbers.ContainsKey($word)) {
                $frenchWords++
            }
            if ($englishNumbers.ContainsKey($word)) {
                $englishWords++
            }
        }

        # Determiner la langue en fonction du nombre de mots reconnus
        if ($frenchWords -gt $englishWords) {
            $Language = "French"
        } else {
            $Language = "English"
        }
    }

    # Convertir le nombre en fonction de la langue
    if ($Language -eq "French") {
        return Convert-FrenchTextToNumber -Text $Text
    } else {
        return Convert-EnglishTextToNumber -Text $Text
    }
}

# Fonction pour detecter les nombres ecrits en toutes lettres dans un texte
function Get-TextualNumbers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Auto", "French", "English")]
        [string]$Language = "Auto"
    )

    # Determiner la langue si Auto est specifie
    if ($Language -eq "Auto") {
        # Compter les mots francais et anglais
        $frenchWords = 0
        $englishWords = 0

        # Normaliser le texte
        $normalizedText = $Text.ToLower() -replace '-', ' ' -replace '\s+', ' '
        $words = $normalizedText -split '\s+'

        foreach ($word in $words) {
            if ($frenchNumbers.ContainsKey($word)) {
                $frenchWords++
            }
            if ($englishNumbers.ContainsKey($word)) {
                $englishWords++
            }
        }

        # Determiner la langue en fonction du nombre de mots reconnus
        if ($frenchWords -gt $englishWords) {
            $Language = "French"
        } else {
            $Language = "English"
        }
    }

    # Expressions regulieres pour detecter les nombres ecrits en toutes lettres
    $frenchPattern = '\b(vingt[-\s]cinq|deux cent(?:s)? cinquante|zero|un|une|deux|trois|quatre|cinq|six|sept|huit|neuf|dix|onze|douze|treize|quatorze|quinze|seize|dix[-\s]sept|dix[-\s]huit|dix[-\s]neuf|vingt(?:\s+et\s+un)?|trente(?:\s+et\s+un)?|quarante(?:\s+et\s+un)?|cinquante(?:\s+et\s+un)?|soixante(?:\s+et\s+un)?|soixante[-\s]dix|quatre[-\s]vingt(?:s)?|quatre[-\s]vingt[-\s]dix)\b'

    $englishPattern = '\b(twenty[-\s]five|two hundred fifty|zero|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty(?:\s+one)?|thirty(?:\s+one)?|forty(?:\s+one)?|fifty(?:\s+one)?|sixty(?:\s+one)?|seventy(?:\s+one)?|eighty(?:\s+one)?|ninety(?:\s+one)?|one hundred(?:\s+one)?|two hundred|one thousand(?:\s+one)?|two thousand|one million|two million|one billion|two billion)\b'

    # Selectionner le pattern approprie
    $pattern = if ($Language -eq "French") { $frenchPattern } else { $englishPattern }

    # Trouver tous les nombres ecrits en toutes lettres
    $regexMatches = [regex]::Matches($Text, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

    # Convertir chaque nombre trouve
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
