# Test-CompleteDecimalRegex.ps1
# Script de test pour les expressions régulières avec des valeurs décimales et des unités
# Version: 1.0
# Date: 2025-05-15

# Définir un exemple de texte contenant des valeurs décimales et des unités
$testText = @"
Cette tâche prendra environ 3,5 jours.
Le développement durera à peu près 2.5 semaines.
La mise en place devrait prendre plus ou moins 5,5 heures.
Cette fonctionnalité nécessitera autour de 10.25 jours de travail.
Le temps de développement est estimé à 4,75 jours.
"@

# Définir des patterns pour les valeurs décimales et les unités
$patterns = @(
    # Nombre avec virgule + jours
    '\d+,\d+\s+jours?'
    # Nombre avec point + jours
    '\d+\.\d+\s+jours?'
    # Nombre avec virgule + semaines
    '\d+,\d+\s+semaines?'
    # Nombre avec point + semaines
    '\d+\.\d+\s+semaines?'
    # Nombre avec virgule + heures
    '\d+,\d+\s+heures?'
    # Nombre avec point + heures
    '\d+\.\d+\s+heures?'
)

# Tester chaque pattern
foreach ($pattern in $patterns) {
    Write-Host "Pattern: $pattern" -ForegroundColor Cyan
    
    $matchResults = [regex]::Matches($testText, $pattern)
    
    if ($matchResults.Count -gt 0) {
        Write-Host "  Résultat: $($matchResults.Count) correspondances trouvées" -ForegroundColor Green
        
        foreach ($match in $matchResults) {
            Write-Host "    Valeur: $($match.Value)" -ForegroundColor Gray
            Write-Host "    Position: $($match.Index)" -ForegroundColor Gray
            Write-Host "    Longueur: $($match.Length)" -ForegroundColor Gray
            Write-Host ""
        }
    } else {
        Write-Host "  Résultat: Aucune correspondance trouvée" -ForegroundColor Red
    }
}
