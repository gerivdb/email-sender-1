# Test-VeryBasicRegex.ps1
# Script de test très basique pour les expressions régulières
# Version: 1.0
# Date: 2025-05-15

# Définir un exemple de texte
$testText = "Hello, world!"

# Définir un pattern simple
$pattern = 'Hello'

# Tester le pattern
Write-Host "Texte: $testText"
Write-Host "Pattern: $pattern"
Write-Host ""

$matchResults = [regex]::Matches($testText, $pattern)

if ($matchResults.Count -gt 0) {
    Write-Host "Résultat: $($matchResults.Count) correspondances trouvées"
    
    foreach ($match in $matchResults) {
        Write-Host "  Valeur: $($match.Value)"
        Write-Host "  Position: $($match.Index)"
        Write-Host "  Longueur: $($match.Length)"
        Write-Host ""
    }
} else {
    Write-Host "Résultat: Aucune correspondance trouvée"
}
