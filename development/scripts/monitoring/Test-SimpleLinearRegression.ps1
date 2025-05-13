#Requires -Version 5.1
<#
.SYNOPSIS
    Script de test pour le module SimpleLinearRegression.
.DESCRIPTION
    Ce script teste les fonctionnalités du module SimpleLinearRegression
    en exécutant chaque fonction et en affichant les résultats.
.NOTES
    Nom: Test-SimpleLinearRegression.ps1
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de création: 2025-05-13
#>

# Importer le module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "SimpleLinearRegression.psm1"
Import-Module $modulePath -Force

# Fonction pour exécuter un test
function Invoke-Test {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestName,

        [Parameter(Mandatory = $true)]
        [scriptblock]$TestScript
    )

    Write-Host "`n========== TEST: $TestName ==========" -ForegroundColor Cyan

    try {
        $result = & $TestScript

        if ($result) {
            Write-Host "TEST RÉUSSI: $TestName" -ForegroundColor Green
            return $true
        } else {
            Write-Host "TEST ÉCHOUÉ: $TestName" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "TEST ÉCHOUÉ: $TestName - $_" -ForegroundColor Red
        return $false
    }
}

# Test 1: Création d'un modèle de régression linéaire simple
$test1 = Invoke-Test -TestName "Création d'un modèle de régression linéaire simple" -TestScript {
    # Créer des données de test avec une tendance linéaire parfaite
    $x = @(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
    $y = @(2, 4, 6, 8, 10, 12, 14, 16, 18, 20)

    $modelName = New-SimpleLinearModel -XValues $x -YValues $y -ModelName "TestModel1"

    if ($null -eq $modelName) {
        Write-Host "Échec: Aucun modèle de régression linéaire créé." -ForegroundColor Red
        return $false
    }

    $model = Get-SimpleLinearModel -ModelName $modelName

    Write-Host "Modèle de régression linéaire créé avec succès:"
    Write-Host "  Nom du modèle: $($model.Name)"
    Write-Host "  Pente (m): $([Math]::Round($model.Slope, 4))"
    Write-Host "  Ordonnée à l'origine (b): $([Math]::Round($model.Intercept, 4))"
    Write-Host "  R²: $([Math]::Round($model.R2, 4))"
    Write-Host "  RMSE: $([Math]::Round($model.RMSE, 4))"
    Write-Host "  MAE: $([Math]::Round($model.MAE, 4))"

    # Vérifier que le modèle a les bons paramètres
    $expectedSlope = 2
    $expectedIntercept = 0

    $slopeError = [Math]::Abs($model.Slope - $expectedSlope)
    $interceptError = [Math]::Abs($model.Intercept - $expectedIntercept)

    if ($slopeError -lt 0.01 -and $interceptError -lt 0.01 -and $model.R2 -gt 0.99) {
        Write-Host "  Les paramètres du modèle sont corrects." -ForegroundColor Green
        return $true
    } else {
        Write-Host "  Erreur de pente: $slopeError (attendu: $expectedSlope)" -ForegroundColor Red
        Write-Host "  Erreur d'ordonnée: $interceptError (attendu: $expectedIntercept)" -ForegroundColor Red
        return $false
    }
}

# Test 2: Prédiction de valeurs futures
$test2 = Invoke-Test -TestName "Prédiction de valeurs futures" -TestScript {
    # Utiliser le modèle créé dans le test précédent
    $modelName = "TestModel1"

    # Prédire les valeurs pour x = 11, 12, 13
    $xValues = @(11, 12, 13)
    $predictions = Invoke-SimpleLinearPrediction -ModelName $modelName -XValues $xValues

    if ($null -eq $predictions) {
        Write-Host "Échec: Aucune prédiction générée." -ForegroundColor Red
        return $false
    }

    Write-Host "Prédictions générées avec succès:"
    Write-Host "  Modèle: $($predictions.ModelName)"
    Write-Host "  Type de modèle: $($predictions.ModelType)"
    Write-Host "  Niveau de confiance: $($predictions.ConfidenceLevel * 100)%"
    Write-Host "  Nombre de prédictions: $($predictions.Predictions.Count)"

    Write-Host "`nValeurs prédites:"
    for ($i = 0; $i -lt $predictions.Predictions.Count; $i++) {
        $pred = $predictions.Predictions[$i]
        Write-Host "  x = $($pred.X): $([Math]::Round($pred.PredictedValue, 2)) [IC: $([Math]::Round($pred.LowerBound, 2)) - $([Math]::Round($pred.UpperBound, 2))]"
    }

    # Vérifier que les prédictions sont correctes (y = 2x)
    $expectedValues = $xValues | ForEach-Object { 2 * $_ }
    $errors = @()

    for ($i = 0; $i -lt $predictions.Predictions.Count; $i++) {
        $predicted = $predictions.Predictions[$i].PredictedValue
        $expected = $expectedValues[$i]
        $errorValue = [Math]::Abs($predicted - $expected)
        $errors += $errorValue
    }

    $maxError = ($errors | Measure-Object -Maximum).Maximum

    Write-Host "`nComparaison avec les valeurs attendues:"
    for ($i = 0; $i -lt $xValues.Count; $i++) {
        Write-Host "  x = $($xValues[$i]): Prédit = $([Math]::Round($predictions.Predictions[$i].PredictedValue, 2)), Attendu = $($expectedValues[$i]), Erreur = $([Math]::Round($errors[$i], 4))"
    }

    if ($maxError -lt 0.01) {
        Write-Host "`n  Les prédictions sont correctes (erreur max: $maxError)." -ForegroundColor Green
        return $true
    } else {
        Write-Host "`n  Les prédictions sont incorrectes (erreur max: $maxError)." -ForegroundColor Red
        return $false
    }
}

# Test 3: Création d'un modèle avec des données bruitées
$test3 = Invoke-Test -TestName "Création d'un modèle avec des données bruitées" -TestScript {
    # Créer des données de test avec une tendance linéaire et du bruit
    $x = @(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
    $y = @()

    # y = 0.5x + 10 + bruit
    $slope = 0.5
    $intercept = 10

    foreach ($xi in $x) {
        $noise = (Get-Random -Minimum -1.0 -Maximum 1.0)
        $yi = $intercept + $slope * $xi + $noise
        $y += $yi
    }

    $modelName = New-SimpleLinearModel -XValues $x -YValues $y -ModelName "TestModel2"

    if ($null -eq $modelName) {
        Write-Host "Échec: Aucun modèle de régression linéaire créé." -ForegroundColor Red
        return $false
    }

    $model = Get-SimpleLinearModel -ModelName $modelName

    Write-Host "Modèle de régression linéaire créé avec succès:"
    Write-Host "  Nom du modèle: $($model.Name)"
    Write-Host "  Pente (m): $([Math]::Round($model.Slope, 4))"
    Write-Host "  Ordonnée à l'origine (b): $([Math]::Round($model.Intercept, 4))"
    Write-Host "  R²: $([Math]::Round($model.R2, 4))"
    Write-Host "  RMSE: $([Math]::Round($model.RMSE, 4))"

    # Vérifier que le modèle a des paramètres proches des valeurs attendues
    $slopeError = [Math]::Abs($model.Slope - $slope)
    $interceptError = [Math]::Abs($model.Intercept - $intercept)

    Write-Host "  Erreur de pente: $([Math]::Round($slopeError, 4)) (attendu: $slope)"
    Write-Host "  Erreur d'ordonnée: $([Math]::Round($interceptError, 4)) (attendu: $intercept)"

    if ($slopeError -lt 0.1 -and $interceptError -lt 1.0 -and $model.R2 -gt 0.8) {
        Write-Host "  Les paramètres du modèle sont acceptables." -ForegroundColor Green
        return $true
    } else {
        Write-Host "  Les paramètres du modèle sont trop éloignés des valeurs attendues." -ForegroundColor Red
        return $false
    }
}

# Résumé des tests
$totalTests = 3
$passedTests = @($test1, $test2, $test3).Where({ $_ -eq $true }).Count
$failedTests = $totalTests - $passedTests

Write-Host "`n========== RÉSUMÉ DES TESTS ==========" -ForegroundColor Cyan
Write-Host "Tests exécutés: $totalTests" -ForegroundColor White
Write-Host "Tests réussis: $passedTests" -ForegroundColor Green
Write-Host "Tests échoués: $failedTests" -ForegroundColor Red

if ($failedTests -eq 0) {
    Write-Host "`nTous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont échoué. Vérifiez les messages d'erreur ci-dessus." -ForegroundColor Red
    exit 1
}
