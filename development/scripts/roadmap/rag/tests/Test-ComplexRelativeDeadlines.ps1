# Test-ComplexRelativeDeadlines.ps1
# Script pour tester l'extraction des expressions de delai relatif avec des cas complexes
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param ()

# Importer le script d'extraction des expressions de delai relatif
$scriptPath = $PSScriptRoot
$extractRelativeDeadlinesScriptPath = Join-Path -Path $scriptPath -ChildPath "..\metadata\Extract-RelativeDeadlines.ps1"

if (-not (Test-Path -Path $extractRelativeDeadlinesScriptPath)) {
    Write-Host "Le script d'extraction des expressions de delai relatif n'existe pas: $extractRelativeDeadlinesScriptPath" -ForegroundColor Red
    exit 1
}

# Creer un contenu de test avec des cas complexes
$testContent = @"
# Test des expressions de delai relatif avec des cas complexes

## Expressions avec des valeurs decimales
- [ ] **1.1** Tache a realiser dans 2,5 jours
- [ ] **1.2** Tache a completer dans 1.5 semaines

## Expressions avec des contextes ambigus
- [ ] **2.1** Tache a realiser dans 5 jours, mais seulement si la tache **2.2** est terminee
- [ ] **2.2** Tache a completer dans 3 jours, puis commencer la tache **2.3**
- [ ] **2.3** Tache a realiser dans 10 jours apres la fin de la tache **2.2**

## Expressions multiples dans la meme tache
- [ ] **3.1** Tache a commencer dans 2 jours et a terminer dans 10 jours
- [ ] **3.2** Premiere etape a realiser dans 3 jours, deuxieme etape dans 7 jours, et derniere etape dans 12 jours

## Expressions avec des negations
- [ ] **4.1** Tache a ne pas realiser dans les 5 prochains jours
- [ ] **4.2** Tache a ne pas commencer avant 3 jours

## Expressions avec des conditions
- [ ] **5.1** Tache a realiser dans 4 jours si possible, sinon dans 7 jours
- [ ] **5.2** Tache a completer de preference dans 2 semaines, au plus tard dans 3 semaines
"@

# Executer le script d'extraction des expressions de delai relatif
Write-Host "Test d'extraction des expressions de delai relatif avec des cas complexes..." -ForegroundColor Cyan
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
    
    # Verifier les expressions par tache
    Write-Host "`nExpressions par tache:" -ForegroundColor Yellow
    
    foreach ($taskId in $resultObj.TaskRelativeDeadlines.PSObject.Properties.Name | Sort-Object) {
        $expressions = $resultObj.TaskRelativeDeadlines.$taskId
        Write-Host "  Tache ${taskId}:" -ForegroundColor Cyan
        
        foreach ($expression in $expressions) {
            Write-Host "    - $($expression.Expression) (Type: $($expression.Type), Valeur: $($expression.Value) $($expression.Unit))" -ForegroundColor White
        }
    }
    
    # Verifier les cas specifiques
    Write-Host "`nVerification des cas specifiques:" -ForegroundColor Yellow
    
    # Cas 1: Valeurs decimales
    $task1_1 = $resultObj.TaskRelativeDeadlines.'1.1' | Where-Object { $_.Expression -like "*2,5 jour*" }
    $task1_2 = $resultObj.TaskRelativeDeadlines.'1.2' | Where-Object { $_.Expression -like "*1.5 semaine*" }
    
    if ($task1_1) {
        Write-Host "  ✓ Valeur decimale avec virgule detectee: $($task1_1.Value) $($task1_1.Unit)" -ForegroundColor Green
    }
    else {
        Write-Host "  ✗ Valeur decimale avec virgule non detectee" -ForegroundColor Red
    }
    
    if ($task1_2) {
        Write-Host "  ✓ Valeur decimale avec point detectee: $($task1_2.Value) $($task1_2.Unit)" -ForegroundColor Green
    }
    else {
        Write-Host "  ✗ Valeur decimale avec point non detectee" -ForegroundColor Red
    }
    
    # Cas 2: Expressions multiples dans la meme tache
    $task3_1_expressions = $resultObj.TaskRelativeDeadlines.'3.1'
    $task3_2_expressions = $resultObj.TaskRelativeDeadlines.'3.2'
    
    if ($task3_1_expressions -and $task3_1_expressions.Count -ge 2) {
        Write-Host "  ✓ Expressions multiples detectees dans la tache 3.1: $($task3_1_expressions.Count) expressions" -ForegroundColor Green
    }
    else {
        Write-Host "  ✗ Expressions multiples non detectees dans la tache 3.1" -ForegroundColor Red
    }
    
    if ($task3_2_expressions -and $task3_2_expressions.Count -ge 3) {
        Write-Host "  ✓ Expressions multiples detectees dans la tache 3.2: $($task3_2_expressions.Count) expressions" -ForegroundColor Green
    }
    else {
        Write-Host "  ✗ Expressions multiples non detectees dans la tache 3.2" -ForegroundColor Red
    }
    
    # Verifier que toutes les expressions attendues ont ete trouvees
    $expectedExpressions = @(
        "dans 2,5 jour", "dans 1.5 semaine",
        "dans 5 jour", "dans 3 jour", "dans 10 jour",
        "dans 2 jour", "dans 10 jour", "dans 3 jour", "dans 7 jour", "dans 12 jour",
        "dans les 5 prochain jour", "avant 3 jour",
        "dans 4 jour", "dans 7 jour", "dans 2 semaine", "dans 3 semaine"
    )
    
    $foundExpressions = $resultObj.RelativeDeadlines.InXTimeExpressions.Expression
    
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
catch {
    Write-Host "Erreur lors de la conversion des resultats en JSON: $_" -ForegroundColor Red
    Write-Host "Resultats bruts: $result" -ForegroundColor Yellow
    exit 1
}
