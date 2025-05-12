# Test-DirectRegex.ps1
# Script pour tester directement les expressions régulières
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
$matches1 = [regex]::Matches($text1, $pattern1)
Write-Host "Nombre de correspondances: $($matches1.Count)" -ForegroundColor Yellow

Write-Host "`nTexte 2: $text2" -ForegroundColor Yellow
$matches2 = [regex]::Matches($text2, $pattern2)
Write-Host "Nombre de correspondances: $($matches2.Count)" -ForegroundColor Yellow

# Créer un objet personnalisé pour chaque correspondance
$results = @()

foreach ($match in $matches1) {
    $marker = $match.Groups[1].Value
    $number = $match.Groups[2].Value
    $value = [double]$number
    
    $results += [PSCustomObject]@{
        Expression = $match.Value
        Marker = $marker
        Value = $value
    }
}

foreach ($match in $matches2) {
    $marker = $match.Groups[1].Value
    $number = $match.Groups[2].Value
    $value = [double]$number
    
    $results += [PSCustomObject]@{
        Expression = $match.Value
        Marker = $marker
        Value = $value
    }
}

# Afficher les résultats
Write-Host "`nRésultats:" -ForegroundColor Cyan
foreach ($result in $results) {
    Write-Host "  - Expression: $($result.Expression)" -ForegroundColor Green
    Write-Host "    Marqueur: $($result.Marker)" -ForegroundColor Green
    Write-Host "    Valeur: $($result.Value)" -ForegroundColor Green
}
