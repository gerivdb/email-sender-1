# Test-BasicRegex.ps1
# Script de test basique pour les expressions régulières
# Version: 1.0
# Date: 2025-05-15

# Définir un exemple de texte contenant des expressions d'estimation avec des valeurs décimales
$testText = "Cette tâche prendra environ 3,5 jours."

# Définir un pattern simple
$pattern = '(\d+,\d+)\s+(jours?)'

# Tester le pattern
Write-Host "Texte: $testText" -ForegroundColor Cyan
Write-Host "Pattern: $pattern" -ForegroundColor Cyan
Write-Host ""

$matchResults = [regex]::Matches($testText, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

if ($matchResults.Count -gt 0) {
    Write-Host "Résultat: $($matchResults.Count) correspondances trouvées" -ForegroundColor Green
    
    foreach ($match in $matchResults) {
        Write-Host "  Valeur: $($match.Groups[1].Value)" -ForegroundColor Gray
        Write-Host "  Unité: $($match.Groups[2].Value)" -ForegroundColor Gray
        Write-Host "  Position: $($match.Index)" -ForegroundColor Gray
        Write-Host "  Longueur: $($match.Length)" -ForegroundColor Gray
        Write-Host ""
    }
} else {
    Write-Host "Résultat: Aucune correspondance trouvée" -ForegroundColor Red
}
