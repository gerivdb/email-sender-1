# Test-SimpleMatch-Working2.ps1
# Script pour tester l'opérateur -match de PowerShell
# Version: Working2
# Date: 2025-05-15

# Textes à tester
$text1 = "Le projet prendra environ 10 jours."
$text2 = "The project will take about 10 days."
$text3 = "Le projet nécessitera 20 jours environ."
$text4 = "The project will require 30 days approximately."

# Expressions régulières
$pattern1 = "environ\s+(\d+)"
$pattern2 = "about\s+(\d+)"
$pattern3 = "(\d+)\s+jours\s+environ"
$pattern4 = "(\d+)\s+days\s+approximately"

# Tester les expressions régulières
Write-Host "Texte 1: $text1" -ForegroundColor Yellow
$matches1 = $null
if ($text1 -match $pattern1) {
    Write-Host "  - Correspondance trouvée: $($Matches[0])" -ForegroundColor Green
    Write-Host "  - Nombre: $($Matches[1])" -ForegroundColor Green
    
    # Créer un objet personnalisé
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
    
    $result = [PSCustomObject]@{
        Expression = $Matches[0]
        StartIndex = $text1.IndexOf($Matches[0])
        Length = $Matches[0].Length
        Info = $approximationInfo
    }
    
    Write-Host "`nObjet personnalisé:" -ForegroundColor Cyan
    Write-Host "  - Expression: $($result.Expression)" -ForegroundColor Cyan
    Write-Host "  - StartIndex: $($result.StartIndex)" -ForegroundColor Cyan
    Write-Host "  - Length: $($result.Length)" -ForegroundColor Cyan
    Write-Host "  - Info.Type: $($result.Info.Type)" -ForegroundColor Cyan
    Write-Host "  - Info.Value: $($result.Info.Value)" -ForegroundColor Cyan
    Write-Host "  - Info.Marker: $($result.Info.Marker)" -ForegroundColor Cyan
    Write-Host "  - Info.Precision: $($result.Info.Precision)" -ForegroundColor Cyan
    Write-Host "  - Info.LowerBound: $($result.Info.LowerBound)" -ForegroundColor Cyan
    Write-Host "  - Info.UpperBound: $($result.Info.UpperBound)" -ForegroundColor Cyan
    Write-Host "  - Info.PrecisionType: $($result.Info.PrecisionType)" -ForegroundColor Cyan
} else {
    Write-Host "  - Aucune correspondance trouvée" -ForegroundColor Red
}

Write-Host "`nTexte 2: $text2" -ForegroundColor Yellow
$matches2 = $null
if ($text2 -match $pattern2) {
    Write-Host "  - Correspondance trouvée: $($Matches[0])" -ForegroundColor Green
    Write-Host "  - Nombre: $($Matches[1])" -ForegroundColor Green
} else {
    Write-Host "  - Aucune correspondance trouvée" -ForegroundColor Red
}

Write-Host "`nTexte 3: $text3" -ForegroundColor Yellow
$matches3 = $null
if ($text3 -match $pattern3) {
    Write-Host "  - Correspondance trouvée: $($Matches[0])" -ForegroundColor Green
    Write-Host "  - Nombre: $($Matches[1])" -ForegroundColor Green
} else {
    Write-Host "  - Aucune correspondance trouvée" -ForegroundColor Red
}

Write-Host "`nTexte 4: $text4" -ForegroundColor Yellow
$matches4 = $null
if ($text4 -match $pattern4) {
    Write-Host "  - Correspondance trouvée: $($Matches[0])" -ForegroundColor Green
    Write-Host "  - Nombre: $($Matches[1])" -ForegroundColor Green
} else {
    Write-Host "  - Aucune correspondance trouvée" -ForegroundColor Red
}
