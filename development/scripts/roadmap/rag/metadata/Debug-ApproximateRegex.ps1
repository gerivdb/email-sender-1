# Debug-ApproximateRegex.ps1
# Script pour déboguer les expressions régulières pour les expressions numériques approximatives
# Version: 1.0
# Date: 2025-05-15

# Phrases de test
$testPhrases = @(
    "Cette tache prendra environ 10 jours a realiser.",
    "Le projet est estime a approximativement 250 heures de travail.",
    "Le cout sera de 1000 euros environ.",
    "Le delai est de 15 jours plus ou moins 2 jours.",
    "Le budget est entre 5000 et 6000 euros.",
    "La duree varie de 3 a 5 semaines selon la disponibilite.",
    "Le projet necessite environ 10 jours et coutera approximativement 5000 euros.",
    "This task will take about 10 days to complete.",
    "The project is estimated at approximately 250 hours of work.",
    "The cost will be 1000 dollars approximately.",
    "The deadline is 15 days plus or minus 2 days.",
    "The budget is between 5000 and 6000 dollars.",
    "The duration varies from 3 to 5 weeks depending on availability.",
    "The project requires about 10 days and will cost approximately 5000 dollars."
)

# Expressions régulières à tester
$patterns = @{
    # Pattern pour les expressions avec marqueur d'approximation suivi d'un nombre
    "MarkerNumber_FR" = "\b(environ|approximativement|a peu pres|autour de|aux alentours de|plus ou moins|grosso modo|dans les|presque|quasi|pratiquement)\s+(\d+(?:[,.]\d+)?)\b"
    "MarkerNumber_EN" = "\b(about|approximately|roughly|around|circa|more or less|in the region of|nearly|almost|practically)\s+(\d+(?:[,.]\d+)?)\b"
    
    # Pattern pour les expressions avec nombre suivi d'un marqueur d'approximation
    "NumberMarker_FR" = "\b(\d+(?:[,.]\d+)?)\s+(environ|approximativement|a peu pres|autour de|aux alentours de|plus ou moins|grosso modo|dans les|presque|quasi|pratiquement)\b"
    "NumberMarker_EN" = "\b(\d+(?:[,.]\d+)?)\s+(about|approximately|roughly|around|circa|more or less|in the region of|nearly|almost|practically)\b"
    
    # Pattern pour les expressions avec précision explicite
    "ExplicitPrecision_FR" = "\b(\d+(?:[,.]\d+)?)\s*(±|plus\s+ou\s+moins)\s*(\d+(?:[,.]\d+)?)\b"
    "ExplicitPrecision_EN" = "\b(\d+(?:[,.]\d+)?)\s*(±|plus\s+or\s+minus)\s*(\d+(?:[,.]\d+)?)\b"
    
    # Pattern pour les expressions avec intervalle
    "Interval_FR" = "\b(entre|de)\s+(\d+(?:[,.]\d+)?)\s+(et|a)\s+(\d+(?:[,.]\d+)?)\b"
    "Interval_EN" = "\b(between|from)\s+(\d+(?:[,.]\d+)?)\s+(and|to)\s+(\d+(?:[,.]\d+)?)\b"
}

# Tester les expressions régulières
Write-Host "Test des expressions regulieres pour les expressions numeriques approximatives..." -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

foreach ($phrase in $testPhrases) {
    Write-Host "`nPhrase: '$phrase'" -ForegroundColor Yellow
    
    foreach ($patternName in $patterns.Keys) {
        $pattern = $patterns[$patternName]
        $matches = [regex]::Matches($phrase, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        
        if ($matches.Count -gt 0) {
            Write-Host "  Pattern '$patternName' : $($matches.Count) correspondance(s)" -ForegroundColor Green
            foreach ($match in $matches) {
                Write-Host "    Correspondance: '$($match.Value)'" -ForegroundColor Green
                for ($i = 1; $i -lt $match.Groups.Count; $i++) {
                    Write-Host "      Groupe $i: '$($match.Groups[$i].Value)'" -ForegroundColor Green
                }
            }
        } else {
            Write-Host "  Pattern '$patternName' : Aucune correspondance" -ForegroundColor Red
        }
    }
}

Write-Host "`nTest termine." -ForegroundColor Cyan
