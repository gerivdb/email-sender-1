# Test-RelativeDeadlines.ps1
# Script pour tester l'extraction des expressions de delai relatif
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\test-results-relative-deadlines.json"
)

# Importer le script d'extraction des expressions de delai relatif
$scriptPath = $PSScriptRoot
$extractRelativeDeadlinesScriptPath = Join-Path -Path $scriptPath -ChildPath "..\metadata\Extract-RelativeDeadlines.ps1"

if (-not (Test-Path -Path $extractRelativeDeadlinesScriptPath)) {
    Write-Host "Le script d'extraction des expressions de delai relatif n'existe pas: $extractRelativeDeadlinesScriptPath" -ForegroundColor Red
    exit 1
}

# Creer un contenu de test avec differentes expressions de delai relatif
$testContent = @"
# Test des expressions de delai relatif

## Expressions "dans X jours/semaines"
- [ ] **1.1** Tache a realiser dans 5 jours
- [ ] **1.2** Tache a completer dans 2 semaines
- [ ] **1.3** Tache a terminer dans 3 mois
- [ ] **1.4** Tache a finaliser dans 1 an

## Expressions "d'ici X jours/semaines"
- [ ] **2.1** Tache a realiser d'ici 8 jours
- [ ] **2.2** Tache a completer d'ici 4 semaines
- [ ] **2.3** Tache a terminer d'ici 2 mois

## Expressions "sous X jours/semaines"
- [ ] **3.1** Tache a realiser sous 10 jours
- [ ] **3.2** Tache a completer sous 3 semaines

## Expressions "en X jours/semaines"
- [ ] **4.1** Tache a realiser en 7 jours
- [ ] **4.2** Tache a completer en 1,5 semaines

## Expressions "X jours/semaines plus tard"
- [ ] **5.1** Tache a realiser 15 jours plus tard
- [ ] **5.2** Tache a completer 2 semaines plus tard

## Expressions "apres X jours/semaines"
- [ ] **6.1** Tache a realiser apres 3 jours
- [ ] **6.2** Tache a completer apres 1 semaine

## Expressions multiples
- [ ] **7.1** Tache a commencer dans 2 jours et a terminer dans 10 jours
- [ ] **7.2** Premiere etape a realiser dans 3 jours, deuxieme etape dans 7 jours

## Expressions avec valeurs decimales
- [ ] **8.1** Tache a realiser dans 2,5 jours
- [ ] **8.2** Tache a completer dans 1.5 semaines
"@

# Executer le script d'extraction des expressions de delai relatif
Write-Host "Test d'extraction des expressions de delai relatif..." -ForegroundColor Cyan
$result = & $extractRelativeDeadlinesScriptPath -Content $testContent -OutputFormat "JSON"

# Verifier si le resultat est valide
if ($null -eq $result) {
    Write-Host "Erreur lors de l'extraction des expressions de delai relatif." -ForegroundColor Red
    exit 1
}

# Afficher les resultats
Write-Host "Resultats de l'extraction des expressions de delai relatif:" -ForegroundColor Green
try {
    $resultObj = $result | ConvertFrom-Json

    # Afficher les statistiques
    Write-Host "Statistiques:" -ForegroundColor Yellow
    Write-Host "  Nombre total d'expressions: $($resultObj.Stats.TotalExpressions)" -ForegroundColor Cyan
    Write-Host "  Taches avec delais: $($resultObj.Stats.TasksWithDeadlines)" -ForegroundColor Cyan

    # Verifier les expressions extraites
    Write-Host "Verification des expressions extraites:" -ForegroundColor Yellow

    # Verifier les expressions "dans X jours/semaines"
    $inXTimeExpressions = $resultObj.RelativeDeadlines.InXTimeExpressions

    if ($inXTimeExpressions.Count -gt 0) {
        Write-Host "  Expressions 'dans X jours/semaines' trouvees: $($inXTimeExpressions.Count)" -ForegroundColor Cyan

        foreach ($expression in $inXTimeExpressions | Sort-Object -Property TaskId) {
            Write-Host "    - Tache $($expression.TaskId): $($expression.Expression) (Type: $($expression.Type), Valeur: $($expression.Value) $($expression.Unit))" -ForegroundColor White
        }
    } else {
        Write-Host "  Aucune expression 'dans X jours/semaines' trouvee." -ForegroundColor Red
    }

    # Verifier les expressions par tache
    Write-Host "`nExpressions par tache:" -ForegroundColor Yellow

    foreach ($taskId in $resultObj.TaskRelativeDeadlines.PSObject.Properties.Name | Sort-Object) {
        $expressions = $resultObj.TaskRelativeDeadlines.$taskId
        Write-Host "  Tache ${taskId}:" -ForegroundColor Cyan

        foreach ($expression in $expressions) {
            Write-Host "    - $($expression.Expression) (Type: $($expression.Type), Valeur: $($expression.Value) $($expression.Unit))" -ForegroundColor White
        }
    }

    # Verifier les types d'expressions
    $expressionTypes = $inXTimeExpressions | Group-Object -Property Type | Select-Object Name, Count

    Write-Host "`nTypes d'expressions:" -ForegroundColor Yellow
    foreach ($type in $expressionTypes) {
        Write-Host "  $($type.Name): $($type.Count)" -ForegroundColor Cyan
    }

    # Verifier les unites de temps
    $timeUnits = $inXTimeExpressions | Group-Object -Property Unit | Select-Object Name, Count

    Write-Host "`nUnites de temps:" -ForegroundColor Yellow
    foreach ($unit in $timeUnits) {
        Write-Host "  $($unit.Name): $($unit.Count)" -ForegroundColor Cyan
    }

    # Sauvegarder les resultats si un chemin de sortie est specifie
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        $result | Out-File -FilePath $OutputPath -Encoding utf8
        Write-Host "`nResultats sauvegardes dans: $OutputPath" -ForegroundColor Green
    }

    # Verifier que toutes les expressions attendues ont ete trouvees
    $expectedExpressions = @(
        "dans 5 jours", "dans 2 semaines", "dans 3 mois", "dans 1 an",
        "d'ici 8 jours", "d'ici 4 semaines", "d'ici 2 mois",
        "sous 10 jours", "sous 3 semaines",
        "en 7 jours", "en 1,5 semaines",
        "15 jours plus tard", "2 semaines plus tard",
        "apres 3 jours", "apres 1 semaine",
        "dans 2 jours", "dans 10 jours",
        "dans 3 jours", "dans 7 jours",
        "dans 2,5 jours", "dans 1.5 semaines"
    )

    $foundExpressions = $inXTimeExpressions.Expression
    $missingExpressions = $expectedExpressions | Where-Object { $foundExpressions -notcontains $_ }

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
} catch {
    Write-Host "Erreur lors de la conversion des resultats en JSON: $_" -ForegroundColor Red
    Write-Host "Resultats bruts: $result" -ForegroundColor Yellow
    exit 1
}
