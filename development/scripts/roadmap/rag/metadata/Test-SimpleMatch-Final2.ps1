# Test-SimpleMatch-Final2.ps1
# Script pour tester l'opérateur -match de PowerShell
# Version: Final2
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
$matches1 = $text1 -match $pattern1
Write-Host "Correspondance trouvée: $matches1" -ForegroundColor Yellow
if ($matches1) {
    Write-Host "  - Correspondance complète: $($Matches[0])" -ForegroundColor Green
    Write-Host "  - Groupe 1 (nombre): $($Matches[1])" -ForegroundColor Green
}

Write-Host "`nTexte 2: $text2" -ForegroundColor Yellow
$matches2 = $text2 -match $pattern2
Write-Host "Correspondance trouvée: $matches2" -ForegroundColor Yellow
if ($matches2) {
    Write-Host "  - Correspondance complète: $($Matches[0])" -ForegroundColor Green
    Write-Host "  - Groupe 1 (nombre): $($Matches[1])" -ForegroundColor Green
}

Write-Host "`nTexte 3: $text3" -ForegroundColor Yellow
$matches3 = $text3 -match $pattern3
Write-Host "Correspondance trouvée: $matches3" -ForegroundColor Yellow
if ($matches3) {
    Write-Host "  - Correspondance complète: $($Matches[0])" -ForegroundColor Green
    Write-Host "  - Groupe 1 (nombre): $($Matches[1])" -ForegroundColor Green
}

Write-Host "`nTexte 4: $text4" -ForegroundColor Yellow
$matches4 = $text4 -match $pattern4
Write-Host "Correspondance trouvée: $matches4" -ForegroundColor Yellow
if ($matches4) {
    Write-Host "  - Correspondance complète: $($Matches[0])" -ForegroundColor Green
    Write-Host "  - Groupe 1 (nombre): $($Matches[1])" -ForegroundColor Green
}
