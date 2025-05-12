# Simple-ApproximateExpressions-v3.ps1
# Script simplifie pour analyser les expressions numeriques approximatives
# Version: 3.0
# Date: 2025-05-15

# Fonction pour analyser les expressions numeriques approximatives
function Get-ApproximateExpressions {
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
        if ($Text -match "environ|approximativement|presque|autour de") {
            $Language = "French"
        } else {
            $Language = "English"
        }
    }

    # Resultats
    $results = @()

    # Expressions régulières pour le français
    if ($Language -eq "French") {
        # Marqueur suivi d'un nombre
        $pattern1 = "(environ|approximativement|presque|autour de)\s+(\d+)"

        # Utiliser l'opérateur -match pour trouver la correspondance
        if ($Text -match $pattern1) {
            $marker = $Matches[1].ToLower()
            $number = $Matches[2]
            $value = [double]$number

            # Déterminer la précision en fonction du marqueur
            $precision = switch -Regex ($marker) {
                "environ" { 0.1 } # 10%
                "approximativement" { 0.05 } # 5%
                "presque" { 0.02 } # 2%
                "autour de" { 0.1 } # 10%
                default { 0.1 } # 10% par défaut
            }

            $approximationInfo = [PSCustomObject]@{
                Type          = "MarkerNumber"
                Value         = $value
                Marker        = $marker
                Precision     = $precision
                LowerBound    = $value * (1 - $precision)
                UpperBound    = $value * (1 + $precision)
                PrecisionType = "Percentage"
            }

            $results += [PSCustomObject]@{
                Expression = $Matches[0]
                StartIndex = $Text.ToLower().IndexOf($Matches[0])
                Length     = $Matches[0].Length
                Info       = $approximationInfo
            }
        }

        # Nombre suivi d'un marqueur
        $pattern2 = "(\d+)\s+jours\s+(environ|approximativement|presque|à peu près)"

        # Utiliser l'opérateur -match pour trouver la correspondance
        if ($Text -match $pattern2) {
            $number = $Matches[1]
            $marker = $Matches[2].ToLower()
            $value = [double]$number

            # Déterminer la précision en fonction du marqueur
            $precision = switch -Regex ($marker) {
                "environ" { 0.1 } # 10%
                "approximativement" { 0.05 } # 5%
                "presque" { 0.02 } # 2%
                "à peu près" { 0.15 } # 15%
                default { 0.1 } # 10% par défaut
            }

            $approximationInfo = [PSCustomObject]@{
                Type          = "NumberMarker"
                Value         = $value
                Marker        = $marker
                Precision     = $precision
                LowerBound    = $value * (1 - $precision)
                UpperBound    = $value * (1 + $precision)
                PrecisionType = "Percentage"
            }

            $results += [PSCustomObject]@{
                Expression = $Matches[0]
                StartIndex = $Text.ToLower().IndexOf($Matches[0])
                Length     = $Matches[0].Length
                Info       = $approximationInfo
            }
        }
    }
    # Expressions régulières pour l'anglais
    else {
        # Marqueur suivi d'un nombre
        $pattern1 = "(about|approximately|around|nearly|almost)\s+(\d+)"

        # Utiliser l'opérateur -match pour trouver la correspondance
        if ($Text -match $pattern1) {
            $marker = $Matches[1].ToLower()
            $number = $Matches[2]
            $value = [double]$number

            # Déterminer la précision en fonction du marqueur
            $precision = switch -Regex ($marker) {
                "about|around" { 0.1 } # 10%
                "approximately" { 0.05 } # 5%
                "nearly|almost" { 0.02 } # 2%
                default { 0.1 } # 10% par défaut
            }

            $approximationInfo = [PSCustomObject]@{
                Type          = "MarkerNumber"
                Value         = $value
                Marker        = $marker
                Precision     = $precision
                LowerBound    = $value * (1 - $precision)
                UpperBound    = $value * (1 + $precision)
                PrecisionType = "Percentage"
            }

            $results += [PSCustomObject]@{
                Expression = $Matches[0]
                StartIndex = $Text.ToLower().IndexOf($Matches[0])
                Length     = $Matches[0].Length
                Info       = $approximationInfo
            }
        }

        # Nombre suivi d'un marqueur
        $pattern2 = "(\d+)\s+days\s+(approximately|or so|roughly|about)"

        # Utiliser l'opérateur -match pour trouver la correspondance
        if ($Text -match $pattern2) {
            $number = $Matches[1]
            $marker = $Matches[2].ToLower()
            $value = [double]$number

            # Déterminer la précision en fonction du marqueur
            $precision = switch -Regex ($marker) {
                "about" { 0.1 } # 10%
                "approximately" { 0.05 } # 5%
                "roughly" { 0.1 } # 10%
                "or so" { 0.15 } # 15%
                default { 0.1 } # 10% par défaut
            }

            $approximationInfo = [PSCustomObject]@{
                Type          = "NumberMarker"
                Value         = $value
                Marker        = $marker
                Precision     = $precision
                LowerBound    = $value * (1 - $precision)
                UpperBound    = $value * (1 + $precision)
                PrecisionType = "Percentage"
            }

            $results += [PSCustomObject]@{
                Expression = $Matches[0]
                StartIndex = $Text.ToLower().IndexOf($Matches[0])
                Length     = $Matches[0].Length
                Info       = $approximationInfo
            }
        }
    }

    return $results
}

# Fonction pour normaliser les expressions numeriques approximatives
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
