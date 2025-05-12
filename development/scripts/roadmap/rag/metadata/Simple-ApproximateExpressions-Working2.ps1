# Simple-ApproximateExpressions-Working2.ps1
# Script simplifie pour analyser les expressions numeriques approximatives
# Version: Working2
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
        $pattern1 = "environ\s+(\d+)"
        $matches1 = $null
        
        if ($Text -match $pattern1) {
            $value = [double]$Matches[1]
            $precision = 0.1 # 10% par défaut
            
            $approximationInfo = [PSCustomObject]@{
                Type = "MarkerNumber"
                Value = $value
                Marker = "environ"
                Precision = $precision
                LowerBound = $value * (1 - $precision)
                UpperBound = $value * (1 + $precision)
                PrecisionType = "Percentage"
            }
            
            $results += [PSCustomObject]@{
                Expression = $Matches[0]
                StartIndex = $Text.IndexOf($Matches[0])
                Length = $Matches[0].Length
                Info = $approximationInfo
            }
        }
        
        # Nombre suivi d'un marqueur
        $pattern3 = "(\d+)\s+jours\s+environ"
        $matches3 = $null
        
        if ($Text -match $pattern3) {
            $value = [double]$Matches[1]
            $precision = 0.1 # 10% par défaut
            
            $approximationInfo = [PSCustomObject]@{
                Type = "NumberMarker"
                Value = $value
                Marker = "environ"
                Precision = $precision
                LowerBound = $value * (1 - $precision)
                UpperBound = $value * (1 + $precision)
                PrecisionType = "Percentage"
            }
            
            $results += [PSCustomObject]@{
                Expression = $Matches[0]
                StartIndex = $Text.IndexOf($Matches[0])
                Length = $Matches[0].Length
                Info = $approximationInfo
            }
        }
    }
    # Expressions régulières pour l'anglais
    else {
        # Marqueur suivi d'un nombre
        $pattern2 = "about\s+(\d+)"
        $matches2 = $null
        
        if ($Text -match $pattern2) {
            $value = [double]$Matches[1]
            $precision = 0.1 # 10% par défaut
            
            $approximationInfo = [PSCustomObject]@{
                Type = "MarkerNumber"
                Value = $value
                Marker = "about"
                Precision = $precision
                LowerBound = $value * (1 - $precision)
                UpperBound = $value * (1 + $precision)
                PrecisionType = "Percentage"
            }
            
            $results += [PSCustomObject]@{
                Expression = $Matches[0]
                StartIndex = $Text.IndexOf($Matches[0])
                Length = $Matches[0].Length
                Info = $approximationInfo
            }
        }
        
        # Nombre suivi d'un marqueur
        $pattern4 = "(\d+)\s+days\s+approximately"
        $matches4 = $null
        
        if ($Text -match $pattern4) {
            $value = [double]$Matches[1]
            $precision = 0.05 # 5% par défaut
            
            $approximationInfo = [PSCustomObject]@{
                Type = "NumberMarker"
                Value = $value
                Marker = "approximately"
                Precision = $precision
                LowerBound = $value * (1 - $precision)
                UpperBound = $value * (1 + $precision)
                PrecisionType = "Percentage"
            }
            
            $results += [PSCustomObject]@{
                Expression = $Matches[0]
                StartIndex = $Text.IndexOf($Matches[0])
                Length = $Matches[0].Length
                Info = $approximationInfo
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
