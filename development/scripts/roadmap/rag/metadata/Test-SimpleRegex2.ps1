# Test-SimpleRegex2.ps1
# Script pour tester les expressions régulières
# Version: 1.0
# Date: 2025-05-15

# Texte à tester
$text1 = "Le projet prendra environ 10 jours."
$text2 = "The project will take about 10 days."

# Expression régulière pour le français
$pattern1 = "environ\s+(\d+)"

# Expression régulière pour l'anglais
$pattern2 = "about\s+(\d+)"

# Tester l'expression régulière pour le français
$regexMatches1 = [regex]::Matches($text1, $pattern1)

# Afficher les résultats pour le français
Write-Host "Texte 1: $text1" -ForegroundColor Yellow
Write-Host "Pattern 1: $pattern1" -ForegroundColor Yellow
Write-Host "Nombre de correspondances: $($regexMatches1.Count)" -ForegroundColor Yellow

foreach ($match in $regexMatches1) {
    Write-Host "  - Correspondance: $($match.Value)" -ForegroundColor Green
    Write-Host "    Groupe 1: $($match.Groups[1].Value)" -ForegroundColor Green
}

# Tester l'expression régulière pour l'anglais
$regexMatches2 = [regex]::Matches($text2, $pattern2)

# Afficher les résultats pour l'anglais
Write-Host "`nTexte 2: $text2" -ForegroundColor Yellow
Write-Host "Pattern 2: $pattern2" -ForegroundColor Yellow
Write-Host "Nombre de correspondances: $($regexMatches2.Count)" -ForegroundColor Yellow

foreach ($match in $regexMatches2) {
    Write-Host "  - Correspondance: $($match.Value)" -ForegroundColor Green
    Write-Host "    Groupe 1: $($match.Groups[1].Value)" -ForegroundColor Green
}
