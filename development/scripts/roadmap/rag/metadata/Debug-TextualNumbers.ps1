# Debug-TextualNumbers.ps1
# Script pour déboguer la fonction Get-TextualNumbers
# Version: 1.0
# Date: 2025-05-15

# Importer le script de conversion
. "$PSScriptRoot\Convert-TextToNumber.ps1"

# Phrases de test
$testPhrases = @(
    @{
        Text = "Cette tâche prendra environ vingt-cinq jours à réaliser."
        Language = "French"
        ExpectedNumber = "vingt-cinq"
        ExpectedValue = 25
    },
    @{
        Text = "Le projet est estimé à deux cent cinquante heures de travail."
        Language = "French"
        ExpectedNumber = "deux cent cinquante"
        ExpectedValue = 250
    },
    @{
        Text = "This task will take about twenty five days to complete."
        Language = "English"
        ExpectedNumber = "twenty five"
        ExpectedValue = 25
    },
    @{
        Text = "The project is estimated at two hundred fifty hours of work."
        Language = "English"
        ExpectedNumber = "two hundred fifty"
        ExpectedValue = 250
    }
)

# Fonction pour tester la fonction Get-TextualNumbers
function Test-GetTextualNumbers {
    param (
        [string]$Text,
        [string]$Language,
        [string]$ExpectedNumber,
        [int]$ExpectedValue
    )
    
    Write-Host "Texte: '$Text'" -ForegroundColor Yellow
    Write-Host "Langue: $Language" -ForegroundColor Yellow
    Write-Host "Nombre attendu: '$ExpectedNumber'" -ForegroundColor Yellow
    Write-Host "Valeur attendue: $ExpectedValue" -ForegroundColor Yellow
    
    # Appeler la fonction Get-TextualNumbers
    $results = Get-TextualNumbers -Text $Text -Language $Language
    
    Write-Host "Nombre de résultats: $($results.Count)" -ForegroundColor Cyan
    
    if ($results.Count -eq 0) {
        Write-Host "Aucun résultat trouvé!" -ForegroundColor Red
        return $false
    }
    
    # Afficher les résultats
    foreach ($result in $results) {
        Write-Host "Nombre textuel: '$($result.TextualNumber)'" -ForegroundColor Cyan
        Write-Host "Valeur numérique: $($result.NumericValue)" -ForegroundColor Cyan
        Write-Host "Position: $($result.StartIndex)" -ForegroundColor Cyan
        Write-Host "Longueur: $($result.Length)" -ForegroundColor Cyan
    }
    
    # Vérifier si le nombre attendu est trouvé
    $found = $false
    foreach ($result in $results) {
        if ($result.TextualNumber -like "*$ExpectedNumber*" -and $result.NumericValue -eq $ExpectedValue) {
            Write-Host "Nombre attendu trouvé: '$($result.TextualNumber)' => $($result.NumericValue)" -ForegroundColor Green
            $found = $true
            break
        }
    }
    
    if (-not $found) {
        Write-Host "Nombre attendu non trouvé: '$ExpectedNumber' => $ExpectedValue" -ForegroundColor Red
        return $false
    }
    
    return $true
}

# Tester la fonction Get-TextualNumbers
Write-Host "Test de la fonction Get-TextualNumbers..." -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

$successCount = 0
$failCount = 0

foreach ($phrase in $testPhrases) {
    Write-Host "`nTest de la phrase: '$($phrase.Text)'" -ForegroundColor Magenta
    
    $success = Test-GetTextualNumbers -Text $phrase.Text -Language $phrase.Language -ExpectedNumber $phrase.ExpectedNumber -ExpectedValue $phrase.ExpectedValue
    
    if ($success) {
        Write-Host "Test réussi!" -ForegroundColor Green
        $successCount++
    } else {
        Write-Host "Test échoué!" -ForegroundColor Red
        $failCount++
    }
    
    Write-Host "--------------------------------" -ForegroundColor Magenta
}

# Afficher les résultats
Write-Host "`nRésumé des résultats:" -ForegroundColor Yellow
Write-Host "- Tests réussis: $successCount" -ForegroundColor Yellow
Write-Host "- Tests échoués: $failCount" -ForegroundColor Yellow
Write-Host "- Total: $($successCount + $failCount)" -ForegroundColor Yellow

Write-Host "`nTest terminé." -ForegroundColor Cyan
