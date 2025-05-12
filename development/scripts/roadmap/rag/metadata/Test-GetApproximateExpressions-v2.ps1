# Test-GetApproximateExpressions-v2.ps1
# Script pour tester la fonction Get-ApproximateExpressions
# Version: 2.0
# Date: 2025-05-15

# Importer le script
. "$PSScriptRoot\Simple-ApproximateExpressions-v2.ps1"

# Test avec une phrase simple
$text1 = "Le projet prendra environ 10 jours."
$text2 = "The project will take about 10 days."

# Appeler la fonction pour chaque texte
Write-Host "Test 1: $text1" -ForegroundColor Yellow
$results1 = Get-ApproximateExpressions -Text $text1 -Language "French"
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

Write-Host "`nTest 2: $text2" -ForegroundColor Yellow
$results2 = Get-ApproximateExpressions -Text $text2 -Language "English"
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
