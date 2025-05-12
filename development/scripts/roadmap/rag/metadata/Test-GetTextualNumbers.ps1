# Test-GetTextualNumbers.ps1
# Script pour tester la fonction Get-TextualNumbers
# Version: 1.0
# Date: 2025-05-15

# Importer le script
. "$PSScriptRoot\Simple-TextToNumber.ps1"

# Test avec une phrase simple
$text = "La premiere tache prendra vingt jours."

# Appeler la fonction
$results = Get-TextualNumbers -Text $text -Language "French"

# Afficher les résultats
Write-Host "Texte: $text"
Write-Host "Résultats: $($results.Count)"
foreach ($result in $results) {
    Write-Host "  - $($result.TextualNumber) => $($result.NumericValue)"
}
