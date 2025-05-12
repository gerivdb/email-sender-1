# Test-SimpleRegex.ps1
# Script de test simple pour les expressions régulières
# Version: 1.0
# Date: 2025-05-15

# Définir un exemple de texte contenant des expressions d'estimation avec des valeurs décimales
$testText = @"
Cette tâche prendra environ 3,5 jours.
Le développement durera à peu près 2.5 semaines.
La mise en place devrait prendre plus ou moins 5,5 heures.
Cette fonctionnalité nécessitera autour de 10.25 jours de travail.
Le temps de développement est estimé à 4,75 jours.
"@

# Définir les patterns pour trouver les valeurs numériques décimales suivies d'unités de temps
$patterns = @(
    # Nombre avec virgule + unité (ex: 3,5 jours)
    '(\d+,\d+)\s+(jours?)'
    # Nombre avec point + unité (ex: 3.5 jours)
    '(\d+\.\d+)\s+(jours?)'
    # Nombre avec virgule + unité (ex: 5,5 heures)
    '(\d+,\d+)\s+(heures?)'
    # Nombre avec point + unité (ex: 5.5 heures)
    '(\d+\.\d+)\s+(heures?)'
    # Nombre avec virgule + unité (ex: 2,5 semaines)
    '(\d+,\d+)\s+(semaines?)'
    # Nombre avec point + unité (ex: 2.5 semaines)
    '(\d+\.\d+)\s+(semaines?)'
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
