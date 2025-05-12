# Debug-Encoding.ps1
# Script pour déboguer les problèmes d'encodage
# Version: 1.0
# Date: 2025-05-15

# Phrases de test
$testPhrases = @(
    "Cette tâche prendra environ vingt-cinq jours à réaliser.",
    "Le projet est estimé à deux cent cinquante heures de travail.",
    "This task will take about twenty five days to complete.",
    "The project is estimated at two hundred fifty hours of work."
)

# Fonction pour afficher les caractères d'une chaîne
function Show-StringCharacters {
    param (
        [string]$Text
    )
    
    Write-Host "Texte: '$Text'" -ForegroundColor Yellow
    Write-Host "Longueur: $($Text.Length) caractères" -ForegroundColor Yellow
    
    Write-Host "Caractères:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $Text.Length; $i++) {
        $char = $Text[$i]
        $code = [int][char]$char
        Write-Host "  Position $i : '$char' (code: $code, hex: 0x$($code.ToString('X4')))" -ForegroundColor Cyan
    }
}

# Fonction pour normaliser une chaîne
function Get-NormalizedString {
    param (
        [string]$Text
    )
    
    # Normaliser le texte (minuscules, sans accents)
    $normalizedText = $Text.ToLower()
    $normalizedText = $normalizedText -replace '[éèêë]', 'e'
    $normalizedText = $normalizedText -replace '[àâä]', 'a'
    $normalizedText = $normalizedText -replace '[ùûü]', 'u'
    $normalizedText = $normalizedText -replace '[ôö]', 'o'
    $normalizedText = $normalizedText -replace '[îï]', 'i'
    $normalizedText = $normalizedText -replace '[ÿ]', 'y'
    $normalizedText = $normalizedText -replace '[ç]', 'c'
    
    return $normalizedText
}

# Fonction pour tester les expressions régulières
function Test-RegexPattern {
    param (
        [string]$Text,
        [string]$Pattern
    )
    
    Write-Host "Texte: '$Text'" -ForegroundColor Yellow
    Write-Host "Pattern: $Pattern" -ForegroundColor Yellow
    
    $matches = [regex]::Matches($Text, $Pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    
    Write-Host "Nombre de correspondances: $($matches.Count)" -ForegroundColor Cyan
    
    if ($matches.Count -eq 0) {
        Write-Host "Aucune correspondance trouvée!" -ForegroundColor Red
        return
    }
    
    foreach ($match in $matches) {
        Write-Host "Correspondance: '$($match.Value)'" -ForegroundColor Green
        Write-Host "  Position: $($match.Index)" -ForegroundColor Green
        Write-Host "  Longueur: $($match.Length)" -ForegroundColor Green
    }
}

# Tester les phrases
Write-Host "Test des problèmes d'encodage..." -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

foreach ($phrase in $testPhrases) {
    Write-Host "`nPhrase originale:" -ForegroundColor Magenta
    Show-StringCharacters -Text $phrase
    
    $normalizedPhrase = Get-NormalizedString -Text $phrase
    Write-Host "`nPhrase normalisée:" -ForegroundColor Magenta
    Show-StringCharacters -Text $normalizedPhrase
    
    Write-Host "`nTest des expressions régulières:" -ForegroundColor Magenta
    
    # Expressions régulières pour détecter les nombres écrits en toutes lettres
    $frenchPattern = '\b(?:(?:vingt-cinq|vingt cinq|deux cent cinquante|deux cents cinquante|zero|zéro|un|une|deux|trois|quatre|cinq|six|sept|huit|neuf|dix|onze|douze|treize|quatorze|quinze|seize|dix-sept|dixsept|dix sept|dix-huit|dixhuit|dix huit|dix-neuf|dixneuf|dix neuf|vingt|trente|quarante|cinquante|soixante|soixante-dix|soixantedix|soixante dix|quatre-vingt|quatrevingt|quatre vingt|quatre-vingts|quatrevingts|quatre vingts|quatre-vingt-dix|quatrevingtdix|quatre vingt dix)(?:\s+et\s+(?:un|une))?(?:\s+(?:cent|cents|mille|million|millions|milliard|milliards))?(?:\s+(?:zero|zéro|un|une|deux|trois|quatre|cinq|six|sept|huit|neuf|dix|onze|douze|treize|quatorze|quinze|seize|dix-sept|dixsept|dix sept|dix-huit|dixhuit|dix huit|dix-neuf|dixneuf|dix neuf|vingt|trente|quarante|cinquante|soixante|soixante-dix|soixantedix|soixante dix|quatre-vingt|quatrevingt|quatre vingt|quatre-vingts|quatrevingts|quatre vingts|quatre-vingt-dix|quatrevingtdix|quatre vingt dix))*)\b'
    
    $englishPattern = '\b(?:(?:twenty five|twenty-five|two hundred fifty|zero|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety)(?:\s+(?:hundred|thousand|million|billion))?(?:\s+(?:zero|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety))*)\b'
    
    # Sélectionner le pattern approprié
    $pattern = if ($phrase -match '[éèêëàâäùûüôöîïÿç]') { $frenchPattern } else { $englishPattern }
    
    Test-RegexPattern -Text $phrase -Pattern $pattern
    Test-RegexPattern -Text $normalizedPhrase -Pattern $pattern
    
    # Tester avec des patterns simplifiés
    if ($phrase -match '[éèêëàâäùûüôöîïÿç]') {
        Write-Host "`nTest avec pattern simplifié (français):" -ForegroundColor Magenta
        Test-RegexPattern -Text $phrase -Pattern '\b(vingt[\s-]cinq|deux cent(?:s)? cinquante)\b'
        Test-RegexPattern -Text $normalizedPhrase -Pattern '\b(vingt[\s-]cinq|deux cent(?:s)? cinquante)\b'
    } else {
        Write-Host "`nTest avec pattern simplifié (anglais):" -ForegroundColor Magenta
        Test-RegexPattern -Text $phrase -Pattern '\b(twenty[\s-]five|two hundred fifty)\b'
        Test-RegexPattern -Text $normalizedPhrase -Pattern '\b(twenty[\s-]five|two hundred fifty)\b'
    }
    
    Write-Host "--------------------------------" -ForegroundColor Magenta
}

Write-Host "`nTest terminé." -ForegroundColor Cyan
