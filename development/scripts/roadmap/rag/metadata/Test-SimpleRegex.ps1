# Test-SimpleRegex.ps1
# Script pour tester des expressions régulières simples
# Version: 1.0
# Date: 2025-05-15

# Phrases de test
$testPhrases = @(
    "Cette tache prendra environ vingt-cinq jours a realiser.",
    "Le projet est estime a deux cent cinquante heures de travail.",
    "This task will take about twenty five days to complete.",
    "The project is estimated at two hundred fifty hours of work."
)

# Expressions régulières simples
$patterns = @(
    '\bvingt-cinq\b',
    '\bvingt cinq\b',
    '\bdeux cent cinquante\b',
    '\bdeux cents cinquante\b',
    '\btwenty five\b',
    '\btwenty-five\b',
    '\btwo hundred fifty\b'
)

# Tester les expressions régulières
Write-Host "Test des expressions regulieres simples..." -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

foreach ($phrase in $testPhrases) {
    Write-Host "`nPhrase: '$phrase'" -ForegroundColor Yellow
    
    foreach ($pattern in $patterns) {
        $matches = [regex]::Matches($phrase, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        
        if ($matches.Count -gt 0) {
            Write-Host "  Pattern '$pattern' : $($matches.Count) correspondance(s)" -ForegroundColor Green
            foreach ($match in $matches) {
                Write-Host "    Correspondance: '$($match.Value)'" -ForegroundColor Green
            }
        } else {
            Write-Host "  Pattern '$pattern' : Aucune correspondance" -ForegroundColor Red
        }
    }
}

Write-Host "`nTest termine." -ForegroundColor Cyan
