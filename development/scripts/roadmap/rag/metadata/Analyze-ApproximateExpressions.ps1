# Analyze-ApproximateExpressions.ps1
# Script pour analyser les expressions numériques approximatives
# Version: 1.0
# Date: 2025-05-15

# Dictionnaire des marqueurs d'approximation en français
$frenchApproximationMarkers = @{
    # Marqueurs d'approximation par défaut
    "environ"           = 0.1 # ±10%
    "approximativement" = 0.1 # ±10%
    "à peu près"        = 0.15 # ±15%
    "autour de"         = 0.1 # ±10%
    "aux alentours de"  = 0.15 # ±15%
    "plus ou moins"     = 0.2 # ±20%
    "grosso modo"       = 0.25 # ±25%
    "dans les"          = 0.1 # ±10%
    "presque"           = 0.05 # ±5%
    "quasi"             = 0.05 # ±5%
    "pratiquement"      = 0.05 # ±5%

    # Marqueurs d'approximation avec précision explicite
    "à"                 = 0.0 # Sera remplacé par la précision explicite
    "plus_ou_moins"     = 0.0 # Sera remplacé par la précision explicite
    "±"                 = 0.0 # Sera remplacé par la précision explicite

    # Marqueurs d'approximation par intervalle
    "entre"             = 0.0 # Sera calculé à partir de l'intervalle
    "de"                = 0.0 # Sera calculé à partir de l'intervalle
}

# Dictionnaire des marqueurs d'approximation en anglais
$englishApproximationMarkers = @{
    # Marqueurs d'approximation par défaut
    "about"            = 0.1 # ±10%
    "approximately"    = 0.1 # ±10%
    "roughly"          = 0.15 # ±15%
    "around"           = 0.1 # ±10%
    "circa"            = 0.1 # ±10%
    "more or less"     = 0.2 # ±20%
    "in the region of" = 0.15 # ±15%
    "nearly"           = 0.05 # ±5%
    "almost"           = 0.05 # ±5%
    "practically"      = 0.05 # ±5%

    # Marqueurs d'approximation avec précision explicite
    "within"           = 0.0 # Sera remplacé par la précision explicite
    "plus or minus"    = 0.0 # Sera remplacé par la précision explicite
    "±"                = 0.0 # Sera remplacé par la précision explicite

    # Marqueurs d'approximation par intervalle
    "between"          = 0.0 # Sera calculé à partir de l'intervalle
    "from"             = 0.0 # Sera calculé à partir de l'intervalle
}

# Fonction pour analyser les expressions numériques approximatives
function Get-ApproximateExpressions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Auto", "French", "English")]
        [string]$Language = "Auto"
    )

    # Déterminer la langue si Auto est spécifié
    if ($Language -eq "Auto") {
        # Compter les marqueurs français et anglais
        $frenchMarkers = 0
        $englishMarkers = 0

        foreach ($marker in $frenchApproximationMarkers.Keys) {
            if ($Text -match [regex]::Escape($marker)) {
                $frenchMarkers++
            }
        }

        foreach ($marker in $englishApproximationMarkers.Keys) {
            if ($Text -match [regex]::Escape($marker)) {
                $englishMarkers++
            }
        }

        # Déterminer la langue en fonction du nombre de marqueurs reconnus
        if ($frenchMarkers -gt $englishMarkers) {
            $Language = "French"
        } else {
            $Language = "English"
        }
    }

    # Sélectionner le dictionnaire approprié
    $approximationMarkers = if ($Language -eq "French") { $frenchApproximationMarkers } else { $englishApproximationMarkers }

    # Expressions régulières pour détecter les expressions numériques approximatives
    $patterns = @{
        # Pattern pour les expressions avec marqueur d'approximation suivi d'un nombre
        # Exemple: "environ 10", "approximately 20"
        "MarkerNumber"      = if ($Language -eq "French") {
            "\b(environ|approximativement|à peu près|autour de|aux alentours de|plus ou moins|grosso modo|dans les|presque|quasi|pratiquement)\s+(\d+(?:[,.]\d+)?)\b"
        } else {
            "\b(about|approximately|roughly|around|circa|more or less|in the region of|nearly|almost|practically)\s+(\d+(?:[,.]\d+)?)\b"
        }

        # Pattern pour les expressions avec nombre suivi d'un marqueur d'approximation
        # Exemple: "10 environ", "20 approximately"
        "NumberMarker"      = if ($Language -eq "French") {
            "\b(\d+(?:[,.]\d+)?)\s+(environ|approximativement|à peu près|autour de|aux alentours de|plus ou moins|grosso modo|dans les|presque|quasi|pratiquement)\b"
        } else {
            "\b(\d+(?:[,.]\d+)?)\s+(about|approximately|roughly|around|circa|more or less|in the region of|nearly|almost|practically)\b"
        }

        # Pattern pour les expressions avec précision explicite
        # Exemple: "10 ± 2", "20 plus ou moins 3"
        "ExplicitPrecision" = if ($Language -eq "French") {
            "\b(\d+(?:[,.]\d+)?)\s*(±|plus\s+ou\s+moins)\s*(\d+(?:[,.]\d+)?)\b"
        } else {
            "\b(\d+(?:[,.]\d+)?)\s*(±|plus\s+or\s+minus)\s*(\d+(?:[,.]\d+)?)\b"
        }

        # Pattern pour les expressions avec intervalle
        # Exemple: "entre 10 et 20", "between 20 and 30"
        "Interval"          = if ($Language -eq "French") {
            "\b(entre|de)\s+(\d+(?:[,.]\d+)?)\s+(et|à)\s+(\d+(?:[,.]\d+)?)\b"
        } else {
            "\b(between|from)\s+(\d+(?:[,.]\d+)?)\s+(and|to)\s+(\d+(?:[,.]\d+)?)\b"
        }
    }

    # Résultats
    $results = @()

    # Analyser chaque pattern
    foreach ($patternName in $patterns.Keys) {
        $pattern = $patterns[$patternName]
        $regexMatches = [regex]::Matches($Text, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

        foreach ($match in $regexMatches) {
            $approximateExpression = $match.Value
            $approximationInfo = $null

            switch ($patternName) {
                "MarkerNumber" {
                    $marker = $match.Groups[1].Value.ToLower()
                    $number = $match.Groups[2].Value -replace ',', '.'
                    $value = [double]$number
                    $precision = $approximationMarkers[$marker]

                    $approximationInfo = [PSCustomObject]@{
                        Type          = "MarkerNumber"
                        Value         = $value
                        Marker        = $marker
                        Precision     = $precision
                        LowerBound    = $value * (1 - $precision)
                        UpperBound    = $value * (1 + $precision)
                        PrecisionType = "Percentage"
                    }
                }
                "NumberMarker" {
                    $number = $match.Groups[1].Value -replace ',', '.'
                    $marker = $match.Groups[2].Value.ToLower()
                    $value = [double]$number
                    $precision = $approximationMarkers[$marker]

                    $approximationInfo = [PSCustomObject]@{
                        Type          = "NumberMarker"
                        Value         = $value
                        Marker        = $marker
                        Precision     = $precision
                        LowerBound    = $value * (1 - $precision)
                        UpperBound    = $value * (1 + $precision)
                        PrecisionType = "Percentage"
                    }
                }
                "ExplicitPrecision" {
                    $number = $match.Groups[1].Value -replace ',', '.'
                    $marker = $match.Groups[2].Value.ToLower()
                    $precisionValue = $match.Groups[3].Value -replace ',', '.'
                    $value = [double]$number
                    $explicitPrecision = [double]$precisionValue

                    $approximationInfo = [PSCustomObject]@{
                        Type          = "ExplicitPrecision"
                        Value         = $value
                        Marker        = $marker
                        Precision     = $explicitPrecision
                        LowerBound    = $value - $explicitPrecision
                        UpperBound    = $value + $explicitPrecision
                        PrecisionType = "Absolute"
                    }
                }
                "Interval" {
                    $marker = $match.Groups[1].Value.ToLower()
                    $lowerValue = $match.Groups[2].Value -replace ',', '.'
                    $connector = $match.Groups[3].Value.ToLower()
                    $upperValue = $match.Groups[4].Value -replace ',', '.'
                    $lowerBound = [double]$lowerValue
                    $upperBound = [double]$upperValue
                    $value = ($lowerBound + $upperBound) / 2
                    $precision = ($upperBound - $lowerBound) / 2

                    $approximationInfo = [PSCustomObject]@{
                        Type          = "Interval"
                        Value         = $value
                        Marker        = $marker
                        Connector     = $connector
                        Precision     = $precision
                        LowerBound    = $lowerBound
                        UpperBound    = $upperBound
                        PrecisionType = "Absolute"
                    }
                }
            }

            if ($null -ne $approximationInfo) {
                $results += [PSCustomObject]@{
                    Expression = $approximateExpression
                    StartIndex = $match.Index
                    Length     = $match.Length
                    Info       = $approximationInfo
                }
            }
        }
    }

    return $results
}

# Fonction pour normaliser les expressions numériques approximatives
function Get-NormalizedApproximateExpression {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$ApproximationInfo,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Standard", "Range", "Percentage", "PlusMinus")]
        [string]$Format = "Standard",

        [Parameter(Mandatory = $false)]
        [int]$Precision = 2
    )

    $value = [math]::Round($ApproximationInfo.Info.Value, $Precision)

    switch ($Format) {
        "Standard" {
            if ($ApproximationInfo.Info.PrecisionType -eq "Percentage") {
                $precisionPercentage = [math]::Round($ApproximationInfo.Info.Precision * 100)
                return "$value (±$precisionPercentage%)"
            } else {
                $precisionValue = [math]::Round($ApproximationInfo.Info.Precision, $Precision)
                return "$value (±$precisionValue)"
            }
        }
        "Range" {
            $lowerBound = [math]::Round($ApproximationInfo.Info.LowerBound, $Precision)
            $upperBound = [math]::Round($ApproximationInfo.Info.UpperBound, $Precision)
            return "[$lowerBound - $upperBound]"
        }
        "Percentage" {
            if ($ApproximationInfo.Info.PrecisionType -eq "Percentage") {
                $precisionPercentage = [math]::Round($ApproximationInfo.Info.Precision * 100)
                return "$value ±$precisionPercentage%"
            } else {
                $precisionPercentage = [math]::Round(($ApproximationInfo.Info.Precision / $ApproximationInfo.Info.Value) * 100)
                return "$value ±$precisionPercentage%"
            }
        }
        "PlusMinus" {
            $precisionValue = if ($ApproximationInfo.Info.PrecisionType -eq "Percentage") {
                [math]::Round($ApproximationInfo.Info.Value * $ApproximationInfo.Info.Precision, $Precision)
            } else {
                [math]::Round($ApproximationInfo.Info.Precision, $Precision)
            }
            return "$value ±$precisionValue"
        }
    }
}

# Pas besoin d'exporter les fonctions car ce n'est pas un module PowerShell
