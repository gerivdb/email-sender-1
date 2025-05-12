# Test-SimpleMatch4.ps1
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
if ($text1 -match $pattern1) {
    Write-Host "  - Correspondance complète: $($Matches[0])" -ForegroundColor Green
    Write-Host "  - Groupe 1 (nombre): $($Matches[1])" -ForegroundColor Green
} else {
    Write-Host "  - Aucune correspondance trouvée" -ForegroundColor Red
}

Write-Host "`nTexte 2: $text2" -ForegroundColor Yellow
if ($text2 -match $pattern2) {
    Write-Host "  - Correspondance complète: $($Matches[0])" -ForegroundColor Green
    Write-Host "  - Groupe 1 (nombre): $($Matches[1])" -ForegroundColor Green
} else {
    Write-Host "  - Aucune correspondance trouvée" -ForegroundColor Red
}
