# Test-SimpleComplexRelativeDeadlines.ps1
# Script pour tester l'extraction des expressions de delai relatif avec des cas complexes (version simplifiee)
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param ()

# Fonction pour extraire les expressions de delai relatif directement
function Test-ExtractInXTimeExpressions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text
    )
    
    $results = @()
    
    # Pattern pour "dans X jours/semaines/mois/annees"
    $pattern = '(?i)dans\s+(\d+(?:[,.]\d+)?)\s+(jour|jours|semaine|semaines|mois|an|ans|annee|annees)'
    
    $regexMatches = [regex]::Matches($Text, $pattern)
    
    foreach ($match in $regexMatches) {
        $value = $match.Groups[1].Value
        $unit = $match.Groups[2].Value
        $fullMatch = $match.Value
        
        # Creer un objet pour stocker les informations
        $result = [PSCustomObject]@{
            Expression = $fullMatch
            Value = $value
            Unit = $unit
        }
        
        $results += $result
    }
    
    return $results
}

# Creer un contenu de test simple avec des cas complexes
$testContent = @"
# Test simple des expressions de delai relatif avec des cas complexes

- [ ] **1.1** Tache a realiser dans 2,5 jours
- [ ] **1.2** Tache a completer dans 1.5 semaines
- [ ] **3.1** Tache a commencer dans 2 jours et a terminer dans 10 jours
"@

# Tester l'extraction directe des expressions
Write-Host "Test d'extraction directe des expressions 'dans X jours/semaines'..." -ForegroundColor Cyan
$directResults = Test-ExtractInXTimeExpressions -Text $testContent

if ($directResults.Count -gt 0) {
    Write-Host "Expressions trouvees directement:" -ForegroundColor Green
    foreach ($result in $directResults) {
        Write-Host "  - $($result.Expression) (Valeur: $($result.Value) $($result.Unit))" -ForegroundColor White
    }
    
    # Verifier les valeurs decimales
    $decimalWithComma = $directResults | Where-Object { $_.Value -like "*,*" }
    $decimalWithDot = $directResults | Where-Object { $_.Value -like "*.*" }
    
    if ($decimalWithComma) {
        Write-Host "`n✓ Valeur decimale avec virgule detectee: $($decimalWithComma.Value) $($decimalWithComma.Unit)" -ForegroundColor Green
    }
    else {
        Write-Host "`n✗ Valeur decimale avec virgule non detectee" -ForegroundColor Red
    }
    
    if ($decimalWithDot) {
        Write-Host "✓ Valeur decimale avec point detectee: $($decimalWithDot.Value) $($decimalWithDot.Unit)" -ForegroundColor Green
    }
    else {
        Write-Host "✗ Valeur decimale avec point non detectee" -ForegroundColor Red
    }
    
    # Verifier les expressions multiples
    if ($directResults.Count -ge 3) {
        Write-Host "✓ Expressions multiples detectees: $($directResults.Count) expressions" -ForegroundColor Green
    }
    else {
        Write-Host "✗ Expressions multiples non detectees" -ForegroundColor Red
    }
    
    # Verifier que toutes les expressions attendues ont ete trouvees
    $expectedExpressions = @(
        "dans 2,5 jour", "dans 1.5 semaine", "dans 2 jour", "dans 10 jour"
    )
    
    $foundExpressions = $directResults.Expression
    
    # Verifier si chaque expression attendue est presente dans les expressions trouvees
    $missingExpressions = @()
    foreach ($expected in $expectedExpressions) {
        $found = $false
        foreach ($expression in $foundExpressions) {
            if ($expression -like "*$expected*") {
                $found = $true
                break
            }
        }
        if (-not $found) {
            $missingExpressions += $expected
        }
    }
    
    if ($missingExpressions.Count -gt 0) {
        Write-Host "`nExpressions manquantes:" -ForegroundColor Red
        foreach ($expression in $missingExpressions) {
            Write-Host "  - $expression" -ForegroundColor Red
        }
        
        Write-Host "`nCertaines expressions attendues n'ont pas ete trouvees." -ForegroundColor Red
        exit 1
    }
    else {
        Write-Host "`nToutes les expressions attendues ont ete trouvees!" -ForegroundColor Green
        exit 0
    }
}
else {
    Write-Host "Aucune expression trouvee directement." -ForegroundColor Red
    exit 1
}
