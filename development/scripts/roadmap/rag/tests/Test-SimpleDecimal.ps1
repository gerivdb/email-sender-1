# Test-SimpleDecimal.ps1
# Script de test simple pour l'extraction des valeurs d'estimation avec décimales
# Version: 1.0
# Date: 2025-05-15

# Définir un exemple de texte contenant des expressions d'estimation avec des valeurs décimales
$testText = "Cette tâche prendra environ 3,5 jours."

# Définir les patterns pour trouver les valeurs numériques suivies d'unités de temps
$patterns = @(
    # Nombre avec virgule + unité (ex: 3,5 jours)
    '(\d+[,]\d+)\s+(jours?)'
)

# Parcourir chaque pattern
foreach ($pattern in $patterns) {
    Write-Host "Pattern: $pattern" -ForegroundColor Cyan
    
    $matchResults = [regex]::Matches($testText, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    
    if ($matchResults.Count -gt 0) {
        Write-Host "  Résultat: $($matchResults.Count) correspondances trouvées" -ForegroundColor Green
        
        foreach ($match in $matchResults) {
            Write-Host "    Valeur: $($match.Groups[1].Value)" -ForegroundColor Gray
            Write-Host "    Unité: $($match.Groups[2].Value)" -ForegroundColor Gray
            Write-Host "    Position: $($match.Index)" -ForegroundColor Gray
            Write-Host "    Longueur: $($match.Length)" -ForegroundColor Gray
            Write-Host ""
        }
    } else {
        Write-Host "  Résultat: Aucune correspondance trouvée" -ForegroundColor Red
    }
}
