# Simple-ApproximateExpressions-v4.ps1
# Script simplifie pour analyser les expressions numeriques approximatives
# Version: 4.0
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
        $matches1 = $null
        
        if ($Text -match $pattern1) {
            $marker = $Matches[1]
            $number = $Matches[2]
            $value = [double]$number
            
            # Déterminer la précision
            $precision = 0.1 # 10% par défaut
            
            $approximationInfo = [PSCustomObject]@{
                Type = "MarkerNumber"
                Value = $value
                Marker = $marker
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
        $pattern1 = "(about|approximately|around|nearly|almost)\s+(\d+)"
        $matches1 = $null
        
        if ($Text -match $pattern1) {
            $marker = $Matches[1]
            $number = $Matches[2]
            $value = [double]$number
            
            # Déterminer la précision
            $precision = 0.1 # 10% par défaut
            
            $approximationInfo = [PSCustomObject]@{
                Type = "MarkerNumber"
                Value = $value
                Marker = $marker
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
