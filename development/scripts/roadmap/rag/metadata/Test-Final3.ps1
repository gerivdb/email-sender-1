# Test-Final3.ps1
# Script pour tester les fonctions de détection des nombres et des expressions approximatives
# Version: Final3
# Date: 2025-05-15

# Textes à tester
$text1 = "Le projet prendra environ 10 jours."
$text2 = "The project will take about 10 days."

# Tester l'opérateur -match
Write-Host "Test de l'opérateur -match..." -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

Write-Host "Texte 1: $text1" -ForegroundColor Yellow
if ($text1 -match "environ\s+(\d+)") {
    Write-Host "Correspondance trouvée:" -ForegroundColor Green
    Write-Host "  - Expression: $($Matches[0])" -ForegroundColor Green
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
    Write-Host "Aucune correspondance trouvée" -ForegroundColor Red
}

Write-Host "`nTexte 2: $text2" -ForegroundColor Yellow
if ($text2 -match "about\s+(\d+)") {
    Write-Host "Correspondance trouvée:" -ForegroundColor Green
    Write-Host "  - Expression: $($Matches[0])" -ForegroundColor Green
    Write-Host "  - Nombre: $($Matches[1])" -ForegroundColor Green
    
    # Créer un objet personnalisé
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
    
    $result = [PSCustomObject]@{
        Expression = $Matches[0]
        StartIndex = $text2.IndexOf($Matches[0])
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
    Write-Host "Aucune correspondance trouvée" -ForegroundColor Red
}
