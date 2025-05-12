# Debug-RegexPatterns.ps1
# Script pour déboguer les expressions régulières utilisées pour détecter les nombres écrits en toutes lettres
# Version: 1.0
# Date: 2025-05-15

# Phrases de test
$testPhrases = @(
    @{
        Text = "Cette tâche prendra environ vingt-cinq jours à réaliser."
        Language = "French"
        ExpectedNumber = "vingt-cinq"
    },
    @{
        Text = "Le projet est estimé à deux cent cinquante heures de travail."
        Language = "French"
        ExpectedNumber = "deux cent cinquante"
    },
    @{
        Text = "This task will take about twenty five days to complete."
        Language = "English"
        ExpectedNumber = "twenty five"
    },
    @{
        Text = "The project is estimated at two hundred fifty hours of work."
        Language = "English"
        ExpectedNumber = "two hundred fifty"
    }
)

# Expressions régulières à tester
$frenchPatterns = @(
    # Pattern original
    '\b(?:(?:vingt-cinq|vingt cinq|deux cent cinquante|deux cents cinquante|zero|zéro|un|une|deux|trois|quatre|cinq|six|sept|huit|neuf|dix|onze|douze|treize|quatorze|quinze|seize|dix-sept|dixsept|dix sept|dix-huit|dixhuit|dix huit|dix-neuf|dixneuf|dix neuf|vingt|trente|quarante|cinquante|soixante|soixante-dix|soixantedix|soixante dix|quatre-vingt|quatrevingt|quatre vingt|quatre-vingts|quatrevingts|quatre vingts|quatre-vingt-dix|quatrevingtdix|quatre vingt dix)(?:\s+et\s+(?:un|une))?(?:\s+(?:cent|cents|mille|million|millions|milliard|milliards))?(?:\s+(?:zero|zéro|un|une|deux|trois|quatre|cinq|six|sept|huit|neuf|dix|onze|douze|treize|quatorze|quinze|seize|dix-sept|dixsept|dix sept|dix-huit|dixhuit|dix huit|dix-neuf|dixneuf|dix neuf|vingt|trente|quarante|cinquante|soixante|soixante-dix|soixantedix|soixante dix|quatre-vingt|quatrevingt|quatre vingt|quatre-vingts|quatrevingts|quatre vingts|quatre-vingt-dix|quatrevingtdix|quatre vingt dix))*)\b',
    
    # Pattern simplifié 1
    '\b(vingt-cinq|vingt cinq|deux cent cinquante|deux cents cinquante)\b',
    
    # Pattern simplifié 2
    '\b(vingt[\s-]cinq|deux cent(?:s)? cinquante)\b'
)

$englishPatterns = @(
    # Pattern original
    '\b(?:(?:twenty five|twenty-five|two hundred fifty|zero|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety)(?:\s+(?:hundred|thousand|million|billion))?(?:\s+(?:zero|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety))*)\b',
    
    # Pattern simplifié 1
    '\b(twenty five|twenty-five|two hundred fifty)\b',
    
    # Pattern simplifié 2
    '\b(twenty[\s-]five|two hundred fifty)\b'
)

# Fonction pour tester les expressions régulières
function Test-RegexPattern {
    param (
        [string]$Text,
        [string]$Pattern,
        [string]$ExpectedMatch
    )
    
    $matches = [regex]::Matches($Text, $Pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    
    if ($matches.Count -eq 0) {
        Write-Host "Aucune correspondance trouvée pour le pattern: $Pattern" -ForegroundColor Red
        return $false
    }
    
    $found = $false
    foreach ($match in $matches) {
        Write-Host "Correspondance trouvée: '$($match.Value)'" -ForegroundColor Cyan
        if ($match.Value -like "*$ExpectedMatch*") {
            Write-Host "Correspondance attendue trouvée: '$($match.Value)'" -ForegroundColor Green
            $found = $true
        }
    }
    
    if (-not $found) {
        Write-Host "Correspondance attendue non trouvée: '$ExpectedMatch'" -ForegroundColor Red
        return $false
    }
    
    return $true
}

# Tester les expressions régulières
Write-Host "Test des expressions régulières pour détecter les nombres écrits en toutes lettres..." -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

foreach ($phrase in $testPhrases) {
    Write-Host "`nPhrase: '$($phrase.Text)'" -ForegroundColor Yellow
    Write-Host "Nombre attendu: '$($phrase.ExpectedNumber)'" -ForegroundColor Yellow
    
    $patterns = if ($phrase.Language -eq "French") { $frenchPatterns } else { $englishPatterns }
    
    for ($i = 0; $i -lt $patterns.Count; $i++) {
        Write-Host "`nTest du pattern $($i + 1):" -ForegroundColor Magenta
        $success = Test-RegexPattern -Text $phrase.Text -Pattern $patterns[$i] -ExpectedMatch $phrase.ExpectedNumber
        
        if ($success) {
            Write-Host "Pattern $($i + 1) réussi!" -ForegroundColor Green
        } else {
            Write-Host "Pattern $($i + 1) échoué!" -ForegroundColor Red
        }
    }
}

Write-Host "`nTest terminé." -ForegroundColor Cyan
