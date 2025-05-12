# Test-Final.ps1
# Script pour tester les fonctions de détection des nombres et des expressions approximatives
# Version: Final
# Date: 2025-05-15

# Importer les scripts
. "$PSScriptRoot\Simple-TextToNumber.ps1"
. "$PSScriptRoot\Simple-ApproximateExpressions-Final.ps1"

# Textes à tester
$text1 = "Le projet prendra environ 10 jours."
$text2 = "The project will take about 10 days."
$text3 = "La première tâche prendra vingt jours."
$text4 = "The first task will take twenty days."

# Tester la fonction Get-TextualNumbers
Write-Host "Test de Get-TextualNumbers..." -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

Write-Host "Texte 3: $text3" -ForegroundColor Yellow
$results3 = Get-TextualNumbers -Text $text3 -Language "French"
if ($null -ne $results3 -and $results3.Count -gt 0) {
    Write-Host "Résultats trouvés: $($results3.Count)" -ForegroundColor Green
    foreach ($result in $results3) {
        Write-Host "  - $($result.TextualNumber) => $($result.NumericValue)" -ForegroundColor Green
    }
} else {
    Write-Host "Aucun résultat trouvé" -ForegroundColor Red
}

Write-Host "`nTexte 4: $text4" -ForegroundColor Yellow
$results4 = Get-TextualNumbers -Text $text4 -Language "English"
if ($null -ne $results4 -and $results4.Count -gt 0) {
    Write-Host "Résultats trouvés: $($results4.Count)" -ForegroundColor Green
    foreach ($result in $results4) {
        Write-Host "  - $($result.TextualNumber) => $($result.NumericValue)" -ForegroundColor Green
    }
} else {
    Write-Host "Aucun résultat trouvé" -ForegroundColor Red
}

# Tester la fonction Get-ApproximateExpressions
Write-Host "`nTest de Get-ApproximateExpressions..." -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

Write-Host "Texte 1: $text1" -ForegroundColor Yellow
if ($text1 -match "environ\s+(\d+)") {
    Write-Host "Correspondance trouvée avec l'opérateur -match:" -ForegroundColor Green
    Write-Host "  - Expression: $($Matches[0])" -ForegroundColor Green
    Write-Host "  - Nombre: $($Matches[1])" -ForegroundColor Green
    
    $results1 = Get-ApproximateExpressions -Text $text1 -Language "French"
    if ($null -ne $results1 -and $results1.Count -gt 0) {
        Write-Host "`nRésultats de Get-ApproximateExpressions:" -ForegroundColor Green
        foreach ($result in $results1) {
            Write-Host "  - Expression: $($result.Expression)" -ForegroundColor Green
            Write-Host "    Type: $($result.Info.Type)" -ForegroundColor Green
            Write-Host "    Valeur: $($result.Info.Value)" -ForegroundColor Green
            Write-Host "    Marqueur: $($result.Info.Marker)" -ForegroundColor Green
            Write-Host "    Précision: $($result.Info.Precision)" -ForegroundColor Green
            Write-Host "    Bornes: [$($result.Info.LowerBound) - $($result.Info.UpperBound)]" -ForegroundColor Green
        }
    } else {
        Write-Host "`nAucun résultat trouvé avec Get-ApproximateExpressions" -ForegroundColor Red
    }
} else {
    Write-Host "Aucune correspondance trouvée avec l'opérateur -match" -ForegroundColor Red
}

Write-Host "`nTexte 2: $text2" -ForegroundColor Yellow
if ($text2 -match "about\s+(\d+)") {
    Write-Host "Correspondance trouvée avec l'opérateur -match:" -ForegroundColor Green
    Write-Host "  - Expression: $($Matches[0])" -ForegroundColor Green
    Write-Host "  - Nombre: $($Matches[1])" -ForegroundColor Green
    
    $results2 = Get-ApproximateExpressions -Text $text2 -Language "English"
    if ($null -ne $results2 -and $results2.Count -gt 0) {
        Write-Host "`nRésultats de Get-ApproximateExpressions:" -ForegroundColor Green
        foreach ($result in $results2) {
            Write-Host "  - Expression: $($result.Expression)" -ForegroundColor Green
            Write-Host "    Type: $($result.Info.Type)" -ForegroundColor Green
            Write-Host "    Valeur: $($result.Info.Value)" -ForegroundColor Green
            Write-Host "    Marqueur: $($result.Info.Marker)" -ForegroundColor Green
            Write-Host "    Précision: $($result.Info.Precision)" -ForegroundColor Green
            Write-Host "    Bornes: [$($result.Info.LowerBound) - $($result.Info.UpperBound)]" -ForegroundColor Green
        }
    } else {
        Write-Host "`nAucun résultat trouvé avec Get-ApproximateExpressions" -ForegroundColor Red
    }
} else {
    Write-Host "Aucune correspondance trouvée avec l'opérateur -match" -ForegroundColor Red
}
