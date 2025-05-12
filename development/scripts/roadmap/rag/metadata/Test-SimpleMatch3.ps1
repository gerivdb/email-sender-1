# Test-SimpleMatch3.ps1
# Script pour tester l'opérateur -match de PowerShell
# Version: 1.0
# Date: 2025-05-15

# Texte à tester
$text1 = "Le projet prendra environ 10 jours."
$text2 = "The project will take about 10 days."

# Expressions régulières
$pattern1 = "environ\s+(\d+)"
$pattern2 = "about\s+(\d+)"

# Tester les expressions régulières
Write-Host "Texte 1: $text1" -ForegroundColor Yellow
$result1 = $text1 -match $pattern1
Write-Host "Correspondance trouvée: $result1" -ForegroundColor Yellow
if ($result1) {
    Write-Host "  - Correspondance complète: $($Matches[0])" -ForegroundColor Green
    Write-Host "  - Groupe 1 (nombre): $($Matches[1])" -ForegroundColor Green
    
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
}

Write-Host "`nTexte 2: $text2" -ForegroundColor Yellow
$result2 = $text2 -match $pattern2
Write-Host "Correspondance trouvée: $result2" -ForegroundColor Yellow
if ($result2) {
    Write-Host "  - Correspondance complète: $($Matches[0])" -ForegroundColor Green
    Write-Host "  - Groupe 1 (nombre): $($Matches[1])" -ForegroundColor Green
    
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
}
