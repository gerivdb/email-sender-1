# Test-RegexMatch.ps1
# Script pour tester les expressions régulières
# Version: 1.0
# Date: 2025-05-15

# Textes à tester
$text1 = "Le projet prendra environ 10 jours."
$text2 = "The project will take about 10 days."
$text3 = "Le projet nécessitera 20 jours environ."
$text4 = "The project will require 20 days approximately."

# Expressions régulières à tester
$regex1 = "(environ|approximativement|presque|autour de)\s+(\d+)"
$regex2 = "(about|approximately|around|nearly|almost)\s+(\d+)"
$regex3 = "(\d+)\s+jours\s+(environ|approximativement|presque|à peu près)"
$regex4 = "(\d+)\s+days\s+(approximately|or so|roughly|about)"

# Tester les expressions régulières
Write-Host "Test 1: $text1" -ForegroundColor Yellow
$matches1 = [regex]::Matches($text1, $regex1)
if ($matches1.Count -gt 0) {
    Write-Host "  - Correspondances trouvées: $($matches1.Count)" -ForegroundColor Green
    foreach ($match in $matches1) {
        Write-Host "    - $($match.Value)" -ForegroundColor Green
        Write-Host "      Groupe 1: $($match.Groups[1].Value)" -ForegroundColor Green
        Write-Host "      Groupe 2: $($match.Groups[2].Value)" -ForegroundColor Green
    }
} else {
    Write-Host "  - Aucune correspondance trouvée" -ForegroundColor Red
}

Write-Host "`nTest 2: $text2" -ForegroundColor Yellow
$matches2 = [regex]::Matches($text2, $regex2)
if ($matches2.Count -gt 0) {
    Write-Host "  - Correspondances trouvées: $($matches2.Count)" -ForegroundColor Green
    foreach ($match in $matches2) {
        Write-Host "    - $($match.Value)" -ForegroundColor Green
        Write-Host "      Groupe 1: $($match.Groups[1].Value)" -ForegroundColor Green
        Write-Host "      Groupe 2: $($match.Groups[2].Value)" -ForegroundColor Green
    }
} else {
    Write-Host "  - Aucune correspondance trouvée" -ForegroundColor Red
}

Write-Host "`nTest 3: $text3" -ForegroundColor Yellow
$matches3 = [regex]::Matches($text3, $regex3)
if ($matches3.Count -gt 0) {
    Write-Host "  - Correspondances trouvées: $($matches3.Count)" -ForegroundColor Green
    foreach ($match in $matches3) {
        Write-Host "    - $($match.Value)" -ForegroundColor Green
        Write-Host "      Groupe 1: $($match.Groups[1].Value)" -ForegroundColor Green
        Write-Host "      Groupe 2: $($match.Groups[2].Value)" -ForegroundColor Green
    }
} else {
    Write-Host "  - Aucune correspondance trouvée" -ForegroundColor Red
}

Write-Host "`nTest 4: $text4" -ForegroundColor Yellow
$matches4 = [regex]::Matches($text4, $regex4)
if ($matches4.Count -gt 0) {
    Write-Host "  - Correspondances trouvées: $($matches4.Count)" -ForegroundColor Green
    foreach ($match in $matches4) {
        Write-Host "    - $($match.Value)" -ForegroundColor Green
        Write-Host "      Groupe 1: $($match.Groups[1].Value)" -ForegroundColor Green
        Write-Host "      Groupe 2: $($match.Groups[2].Value)" -ForegroundColor Green
    }
} else {
    Write-Host "  - Aucune correspondance trouvée" -ForegroundColor Red
}
