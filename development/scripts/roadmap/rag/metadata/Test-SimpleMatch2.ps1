# Test-SimpleMatch2.ps1
# Script pour tester l'opérateur -match de PowerShell
# Version: 1.0
# Date: 2025-05-15

# Texte à tester
$text1 = "Le projet prendra environ 10 jours."
$text2 = "The project will take about 10 days."

# Expressions régulières
$pattern1 = "(environ|approximativement|presque|autour de)\s+(\d+)"
$pattern2 = "(about|approximately|around|nearly|almost)\s+(\d+)"

# Tester les expressions régulières
Write-Host "Texte 1: $text1" -ForegroundColor Yellow
$matches1 = $null
$result1 = $text1 -match $pattern1
Write-Host "Correspondance trouvée: $result1" -ForegroundColor Yellow
if ($result1) {
    Write-Host "  - Correspondance complète: $($Matches[0])" -ForegroundColor Green
    Write-Host "  - Groupe 1 (marqueur): $($Matches[1])" -ForegroundColor Green
    Write-Host "  - Groupe 2 (nombre): $($Matches[2])" -ForegroundColor Green
}

Write-Host "`nTexte 2: $text2" -ForegroundColor Yellow
$matches2 = $null
$result2 = $text2 -match $pattern2
Write-Host "Correspondance trouvée: $result2" -ForegroundColor Yellow
if ($result2) {
    Write-Host "  - Correspondance complète: $($Matches[0])" -ForegroundColor Green
    Write-Host "  - Groupe 1 (marqueur): $($Matches[1])" -ForegroundColor Green
    Write-Host "  - Groupe 2 (nombre): $($Matches[2])" -ForegroundColor Green
}
