# Simple-ApproximateExpressions-v5.ps1
# Script simplifie pour analyser les expressions numeriques approximatives
# Version: 5.0
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
    }
    # Expressions régulières pour l'anglais
    else {
        # Marqueur suivi d'un nombre
        $pattern1 = "about\s+(\d+)"
        
        if ($Text -match $pattern1) {
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
    }
    
    return $results
}
