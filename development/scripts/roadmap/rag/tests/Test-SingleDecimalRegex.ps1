# Test-SingleDecimalRegex.ps1
# Script de test pour une seule expression régulière avec des valeurs décimales et des unités
# Version: 1.0
# Date: 2025-05-15

# Définir un exemple de texte contenant une valeur décimale et une unité
$testText = "Cette tâche prendra environ 3,5 jours."

# Définir un pattern pour les valeurs décimales et les unités
$pattern = '\d+,\d+\s+jours?'

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
