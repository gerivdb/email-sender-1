# Simple-TextToNumber.ps1
# Script simplifie pour convertir les nombres ecrits en toutes lettres en valeurs numeriques
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

    # Normaliser le texte
    $normalizedText = $Text.ToLower() -replace '-', ' ' -replace '\s+', ' '

    # Verifier si le texte correspond exactement a une entree du dictionnaire
    if ($Language -eq "French" -and $frenchNumbers.ContainsKey($normalizedText)) {
        return $frenchNumbers[$normalizedText]
    } elseif ($Language -eq "English" -and $englishNumbers.ContainsKey($normalizedText)) {
        return $englishNumbers[$normalizedText]
    }

    # Si le texte ne correspond pas exactement, retourner 0
    return 0
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
        $normalizedText = $Text.ToLower() -replace '-', ' ' -replace '\s+', ' ' -replace '[.,;:!?]', ''
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

    # Normaliser le texte en supprimant la ponctuation
    $normalizedText = $Text.ToLower() -replace '-', ' ' -replace '\s+', ' ' -replace '[.,;:!?]', ''

    # Resultats
    $result = @()

    # Dictionnaire à utiliser
    $numberDict = if ($Language -eq "French") { $frenchNumbers } else { $englishNumbers }

    # Diviser le texte en mots
    $words = $normalizedText -split '\s+'

    # Parcourir tous les mots du texte
    foreach ($word in $words) {
        # Vérifier si le mot est dans le dictionnaire
        if ($numberDict.ContainsKey($word)) {
            $result += [PSCustomObject]@{
                TextualNumber = $word
                NumericValue  = $numberDict[$word]
                StartIndex    = $normalizedText.IndexOf($word)
                Length        = $word.Length
            }
        }
    }

    return $result
}

# Pas besoin d'exporter les fonctions car ce n'est pas un module PowerShell
