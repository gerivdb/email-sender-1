# Test-SimpleRelativeDeadlines.ps1
# Script pour tester l'extraction des expressions de delai relatif (version simplifiee)
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param ()

# Importer le script d'extraction des expressions de delai relatif
$scriptPath = $PSScriptRoot
$getRelativeDeadlinesScriptPath = Join-Path -Path $scriptPath -ChildPath "..\metadata\Get-RelativeDeadlines.ps1"

if (-not (Test-Path -Path $getRelativeDeadlinesScriptPath)) {
    Write-Host "Le script d'extraction des expressions de delai relatif n'existe pas: $getRelativeDeadlinesScriptPath" -ForegroundColor Red
    exit 1
}

# Creer un contenu de test simple
$testContent = @"
# Test simple des expressions de delai relatif

- [ ] **1.1** Tache a realiser dans 5 jours
- [ ] **1.2** Tache a completer dans 2 semaines
- [ ] **2.1** Tache a realiser d'ici 8 jours
- [ ] **3.1** Tache a realiser sous 10 jours
"@

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
            Value      = $value
            Unit       = $unit
        }

        $results += $result
    }

    return $results
}

# Tester l'extraction directe des expressions
Write-Host "Test d'extraction directe des expressions 'dans X jours/semaines'..." -ForegroundColor Cyan
$directResults = Test-ExtractInXTimeExpressions -Text $testContent

if ($directResults.Count -gt 0) {
    Write-Host "Expressions trouvees directement:" -ForegroundColor Green
    foreach ($result in $directResults) {
        Write-Host "  - $($result.Expression) (Valeur: $($result.Value) $($result.Unit))" -ForegroundColor White
    }
} else {
    Write-Host "Aucune expression trouvee directement." -ForegroundColor Red
}

# Tester le script complet
Write-Host "`nTest du script complet d'extraction des expressions de delai relatif..." -ForegroundColor Cyan
$scriptResult = & $getRelativeDeadlinesScriptPath -Content $testContent -OutputFormat "JSON"

try {
    $resultObj = $scriptResult | ConvertFrom-Json

    # Afficher les statistiques
    Write-Host "Statistiques:" -ForegroundColor Yellow
    Write-Host "  Nombre total d'expressions: $($resultObj.Stats.TotalExpressions)" -ForegroundColor Cyan
    Write-Host "  Taches avec delais: $($resultObj.Stats.TasksWithDeadlines)" -ForegroundColor Cyan

    # Verifier les expressions extraites
    $inXTimeExpressions = $resultObj.RelativeDeadlines.InXTimeExpressions

    if ($inXTimeExpressions.Count -gt 0) {
        Write-Host "`nExpressions trouvees par le script:" -ForegroundColor Green
        foreach ($expression in $inXTimeExpressions) {
            Write-Host "  - $($expression.Expression) (Type: $($expression.Type), Valeur: $($expression.Value) $($expression.Unit))" -ForegroundColor White
        }

        # Verifier que toutes les expressions attendues ont ete trouvees
        $expectedPatterns = @(
            "dans 5 jour", "dans 2 semaine", "d'ici 8 jour", "sous 10 jour"
        )

        $foundExpressions = $inXTimeExpressions.Expression

        # Verifier si chaque pattern attendu est present dans les expressions trouvees
        $missingExpressions = @()
        foreach ($pattern in $expectedPatterns) {
            $found = $false
            foreach ($expression in $foundExpressions) {
                if ($expression -like "*$pattern*") {
                    $found = $true
                    break
                }
            }
            if (-not $found) {
                $missingExpressions += $pattern
            }
        }

        if ($missingExpressions.Count -gt 0) {
            Write-Host "`nExpressions manquantes:" -ForegroundColor Red
            foreach ($expression in $missingExpressions) {
                Write-Host "  - $expression" -ForegroundColor Red
            }

            Write-Host "`nCertaines expressions attendues n'ont pas ete trouvees." -ForegroundColor Red
            exit 1
        } else {
            Write-Host "`nToutes les expressions attendues ont ete trouvees!" -ForegroundColor Green
            exit 0
        }
    } else {
        Write-Host "Aucune expression trouvee par le script." -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Erreur lors de la conversion des resultats en JSON: $_" -ForegroundColor Red
    Write-Host "Resultats bruts: $scriptResult" -ForegroundColor Yellow
    exit 1
}
