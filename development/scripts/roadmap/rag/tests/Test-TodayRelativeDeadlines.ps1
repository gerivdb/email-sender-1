# Test-TodayRelativeDeadlines.ps1
# Script pour tester l'extraction des expressions de delai relatif par rapport a aujourd'hui
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param ()

# Importer le script d'extraction des expressions de delai relatif par rapport a aujourd'hui
$scriptPath = $PSScriptRoot
$extractTodayRelativeDeadlinesScriptPath = Join-Path -Path $scriptPath -ChildPath "..\metadata\Extract-TodayRelativeDeadlines.ps1"

if (-not (Test-Path -Path $extractTodayRelativeDeadlinesScriptPath)) {
    Write-Host "Le script d'extraction des expressions de delai relatif par rapport a aujourd'hui n'existe pas: $extractTodayRelativeDeadlinesScriptPath" -ForegroundColor Red
    exit 1
}

# Creer un contenu de test simple
$testContent = @"
# Test simple des expressions de delai relatif par rapport a aujourd'hui

- [ ] **1.1** Tache a realiser aujourd'hui
- [ ] **1.2** Tache a completer demain
- [ ] **1.3** Tache a terminer apres-demain
- [ ] **2.1** Tache realisee hier
- [ ] **2.2** Tache completee avant-hier
- [ ] **3.1** Tache a realiser cette semaine
- [ ] **3.2** Tache a completer la semaine prochaine
- [ ] **3.3** Tache realisee la semaine derniere
- [ ] **4.1** Tache a realiser ce mois-ci
- [ ] **4.2** Tache a completer le mois prochain
- [ ] **4.3** Tache realisee le mois dernier
- [ ] **5.1** Tache a realiser cette annee
- [ ] **5.2** Tache a completer l'annee prochaine
- [ ] **5.3** Tache realisee l'annee derniere
"@

# Fonction pour tester l'extraction directe des expressions
function Test-ExtractTodayRelativeExpressions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    $results = @()

    # Pattern pour "aujourd'hui"
    $pattern = '(?i)(aujourd''hui|ce jour)'

    $regexMatches = [regex]::Matches($Text, $pattern)

    foreach ($match in $regexMatches) {
        $expression = $match.Value

        # Creer un objet pour stocker les informations
        $result = [PSCustomObject]@{
            Expression = $expression
            Type       = "Aujourd'hui"
        }

        $results += $result
    }

    return $results
}

# Tester l'extraction directe des expressions
Write-Host "Test d'extraction directe des expressions 'aujourd'hui'..." -ForegroundColor Cyan
$directResults = Test-ExtractTodayRelativeExpressions -Text $testContent

if ($directResults.Count -gt 0) {
    Write-Host "Expressions trouvees directement:" -ForegroundColor Green
    foreach ($result in $directResults) {
        Write-Host "  - $($result.Expression) (Type: $($result.Type))" -ForegroundColor White
    }
} else {
    Write-Host "Aucune expression trouvee directement." -ForegroundColor Red
}

# Tester le script complet
Write-Host "`nTest du script complet d'extraction des expressions de delai relatif par rapport a aujourd'hui..." -ForegroundColor Cyan
$scriptResult = & $extractTodayRelativeDeadlinesScriptPath -Content $testContent -OutputFormat "JSON"

try {
    $resultObj = $scriptResult | ConvertFrom-Json

    # Afficher les statistiques
    Write-Host "Statistiques:" -ForegroundColor Yellow
    Write-Host "  Nombre total d'expressions: $($resultObj.Stats.TotalExpressions)" -ForegroundColor Cyan
    Write-Host "  Taches avec delais: $($resultObj.Stats.TasksWithDeadlines)" -ForegroundColor Cyan

    # Verifier les expressions extraites
    $todayRelativeExpressions = $resultObj.TodayRelativeDeadlines.Expressions

    if ($todayRelativeExpressions.Count -gt 0) {
        Write-Host "`nExpressions trouvees par le script:" -ForegroundColor Green

        # Regrouper par type
        $expressionsByType = $todayRelativeExpressions | Group-Object -Property Type

        foreach ($typeGroup in $expressionsByType) {
            Write-Host "`n  Type: $($typeGroup.Name)" -ForegroundColor Cyan

            foreach ($expression in $typeGroup.Group) {
                $taskId = if ($null -eq $expression.TaskId) { "N/A" } else { $expression.TaskId }
                Write-Host "    - Tache ${taskId}: $($expression.Expression) (Valeur: $($expression.RelativeValue) $($expression.Unit), Date: $($expression.AbsoluteDate))" -ForegroundColor White
            }
        }

        # Verifier que toutes les expressions attendues ont ete trouvees
        $expectedExpressions = @(
            "aujourd'hui", "demain", "apres-demain", "hier", "avant-hier",
            "cette semaine", "la semaine prochaine", "la semaine derniere",
            "ce mois-ci", "le mois prochain", "le mois dernier",
            "cette annee", "l'annee prochaine", "l'annee derniere"
        )

        $foundExpressions = $todayRelativeExpressions.Expression

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
        } else {
            Write-Host "`nToutes les expressions attendues ont ete trouvees!" -ForegroundColor Green

            # Verifier les dates absolues
            $today = Get-Date
            $tomorrow = $today.AddDays(1).ToString("yyyy-MM-dd")
            $yesterday = $today.AddDays(-1).ToString("yyyy-MM-dd")

            $demainExpression = $todayRelativeExpressions | Where-Object { $_.Expression -like "*demain*" } | Select-Object -First 1
            $hierExpression = $todayRelativeExpressions | Where-Object { $_.Expression -like "*hier*" } | Select-Object -First 1

            if ($demainExpression.AbsoluteDate -eq $tomorrow -and $hierExpression.AbsoluteDate -eq $yesterday) {
                Write-Host "`nLes dates absolues sont correctes!" -ForegroundColor Green
                exit 0
            } else {
                Write-Host "`nErreur dans les dates absolues:" -ForegroundColor Red
                Write-Host "  - Demain: $($demainExpression.AbsoluteDate) (attendu: $tomorrow)" -ForegroundColor Red
                Write-Host "  - Hier: $($hierExpression.AbsoluteDate) (attendu: $yesterday)" -ForegroundColor Red
                exit 1
            }
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
