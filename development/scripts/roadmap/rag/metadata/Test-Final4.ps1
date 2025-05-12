# Test-Final4.ps1
# Script pour tester les fonctions de détection des nombres et des expressions approximatives
# Version: Final4
# Date: 2025-05-15

# Textes à tester
$text1 = "Le projet prendra environ 10 jours."
$text2 = "The project will take about 10 days."

# Fonction pour analyser les expressions numériques approximatives
function Get-SimpleApproximateExpressions {
    param (
        [string]$Text,
        [string]$Language
    )
    
    $results = @()
    
    if ($Language -eq "French") {
        if ($Text -match "environ\s+(\d+)") {
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
    } else {
        if ($Text -match "about\s+(\d+)") {
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

# Tester la fonction
Write-Host "Test de Get-SimpleApproximateExpressions..." -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

Write-Host "Texte 1: $text1" -ForegroundColor Yellow
$results1 = Get-SimpleApproximateExpressions -Text $text1 -Language "French"
if ($null -ne $results1 -and $results1.Count -gt 0) {
    Write-Host "Résultats trouvés: $($results1.Count)" -ForegroundColor Green
    foreach ($result in $results1) {
        Write-Host "  - Expression: $($result.Expression)" -ForegroundColor Green
        Write-Host "    Type: $($result.Info.Type)" -ForegroundColor Green
        Write-Host "    Valeur: $($result.Info.Value)" -ForegroundColor Green
        Write-Host "    Marqueur: $($result.Info.Marker)" -ForegroundColor Green
        Write-Host "    Précision: $($result.Info.Precision)" -ForegroundColor Green
        Write-Host "    Bornes: [$($result.Info.LowerBound) - $($result.Info.UpperBound)]" -ForegroundColor Green
    }
} else {
    Write-Host "Aucun résultat trouvé" -ForegroundColor Red
}

Write-Host "`nTexte 2: $text2" -ForegroundColor Yellow
$results2 = Get-SimpleApproximateExpressions -Text $text2 -Language "English"
if ($null -ne $results2 -and $results2.Count -gt 0) {
    Write-Host "Résultats trouvés: $($results2.Count)" -ForegroundColor Green
    foreach ($result in $results2) {
        Write-Host "  - Expression: $($result.Expression)" -ForegroundColor Green
        Write-Host "    Type: $($result.Info.Type)" -ForegroundColor Green
        Write-Host "    Valeur: $($result.Info.Value)" -ForegroundColor Green
        Write-Host "    Marqueur: $($result.Info.Marker)" -ForegroundColor Green
        Write-Host "    Précision: $($result.Info.Precision)" -ForegroundColor Green
        Write-Host "    Bornes: [$($result.Info.LowerBound) - $($result.Info.UpperBound)]" -ForegroundColor Green
    }
} else {
    Write-Host "Aucun résultat trouvé" -ForegroundColor Red
}
