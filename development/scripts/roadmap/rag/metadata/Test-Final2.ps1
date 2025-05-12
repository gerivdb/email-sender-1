# Test-Final2.ps1
# Script pour tester les fonctions de détection des nombres et des expressions approximatives
# Version: Final
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
} else {
    Write-Host "Aucune correspondance trouvée" -ForegroundColor Red
}

Write-Host "`nTexte 2: $text2" -ForegroundColor Yellow
if ($text2 -match "about\s+(\d+)") {
    Write-Host "Correspondance trouvée:" -ForegroundColor Green
    Write-Host "  - Expression: $($Matches[0])" -ForegroundColor Green
    Write-Host "  - Nombre: $($Matches[1])" -ForegroundColor Green
} else {
    Write-Host "Aucune correspondance trouvée" -ForegroundColor Red
}
