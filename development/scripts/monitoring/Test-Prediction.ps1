#Requires -Version 5.1
<#
.SYNOPSIS
    Script de test pour la fonction de prédiction du module PredictiveModels.
.DESCRIPTION
    Ce script teste la fonction de prédiction du module PredictiveModels
    en utilisant des données de test simples.
.NOTES
    Nom: Test-Prediction.ps1
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.3
    Date de création: 2025-05-13
#>

# Importer les modules à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "PredictiveModels.psm1"
Import-Module $modulePath -Force

# Créer des données de test avec une tendance linéaire simple
function New-SimpleTestData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$Hours = 24,

        [Parameter(Mandatory = $false)]
        [double]$Slope = 0.5,

        [Parameter(Mandatory = $false)]
        [double]$Intercept = 50
    )

    $startTime = (Get-Date).Date.AddHours(-$Hours)
    $endTime = (Get-Date).Date

    $values = @()
    $timestamps = @()

    # Générer des données avec une tendance linéaire parfaite
    for ($hour = 0; $hour -lt $Hours; $hour++) {
        $timestamp = $startTime.AddHours($hour)
        $timestamps += $timestamp

        # Valeur linéaire: y = mx + b
        $value = $Intercept + $Slope * $hour
        $values += $value
    }

    # Créer la structure de données
    $testData = @{
        CollectorName    = "SimpleLinearTrendCollector"
        StartTime        = $startTime
        EndTime          = $endTime
        SamplingInterval = 3600 # 1 heure
        MetricsData      = @{
            CPU_Usage = @{
                Values     = $values
                Timestamps = $timestamps
                Unit       = "%"
            }
        }
    }

    return $testData
}

Write-Host "Test de prédiction avec régression linéaire" -ForegroundColor Cyan

# Créer des données de test simples
$testData = New-SimpleTestData -Hours 24 -Slope 0.5 -Intercept 50

Write-Host "Données de test créées:" -ForegroundColor Yellow
Write-Host "  Nombre d'échantillons: $($testData.MetricsData.CPU_Usage.Values.Count)"
Write-Host "  Période: $($testData.StartTime.ToString('MM/dd/yyyy HH:mm:ss')) - $($testData.EndTime.ToString('MM/dd/yyyy HH:mm:ss'))"
Write-Host "  Première valeur: $($testData.MetricsData.CPU_Usage.Values[0])"
Write-Host "  Dernière valeur: $($testData.MetricsData.CPU_Usage.Values[-1])"

# Créer un modèle de régression linéaire
Write-Host "`nCréation du modèle de régression linéaire..." -ForegroundColor Yellow
$modelName = New-LinearRegressionModel -MetricsData $testData -MetricName "CPU_Usage" -PolynomialDegree 1

if ($null -eq $modelName) {
    Write-Host "Échec: Aucun modèle de régression linéaire créé." -ForegroundColor Red
    exit 1
}

# Récupérer le modèle
$model = Get-RegressionModel -ModelName $modelName

Write-Host "Modèle créé avec succès:" -ForegroundColor Green
Write-Host "  Nom du modèle: $($model.Name)"
Write-Host "  Coefficients: $([string]::Join(', ', ($model.Coefficients | ForEach-Object { [Math]::Round($_, 4) })))"
Write-Host "  R²: $([Math]::Round($model.R2, 4))"
Write-Host "  RMSE: $([Math]::Round($model.RMSE, 4))"

# Créer des timestamps futurs pour la prédiction
$lastTimestamp = $testData.MetricsData.CPU_Usage.Timestamps[-1]
$futureTimestamps = @(
    $lastTimestamp.AddHours(1),
    $lastTimestamp.AddHours(2),
    $lastTimestamp.AddHours(3),
    $lastTimestamp.AddHours(4),
    $lastTimestamp.AddHours(5)
)

# Faire des prédictions
Write-Host "`nPrédiction des valeurs futures..." -ForegroundColor Yellow
$predictions = Invoke-RegressionPrediction -ModelName $modelName -Timestamps $futureTimestamps

if ($null -eq $predictions) {
    Write-Host "Échec: Aucune prédiction générée." -ForegroundColor Red
    exit 1
}

# Afficher les prédictions
Write-Host "Prédictions générées avec succès:" -ForegroundColor Green
Write-Host "  Modèle: $($predictions.ModelName)"
Write-Host "  Métrique: $($predictions.MetricName)"
Write-Host "  Unité: $($predictions.Unit)"
Write-Host "  Intervalle de confiance: $($predictions.ConfidenceInterval * 100)%"
Write-Host "  Nombre de prédictions: $($predictions.Predictions.Count)"

Write-Host "`nValeurs prédites:" -ForegroundColor Cyan
for ($i = 0; $i -lt $predictions.Predictions.Count; $i++) {
    $pred = $predictions.Predictions[$i]
    Write-Host "  $($pred.Timestamp.ToString('yyyy-MM-dd HH:mm:ss')): $([Math]::Round($pred.PredictedValue, 2)) $($predictions.Unit) [IC: $([Math]::Round($pred.LowerBound, 2)) - $([Math]::Round($pred.UpperBound, 2))]"
}

# Vérifier que les prédictions suivent la tendance attendue
$lastValue = $testData.MetricsData.CPU_Usage.Values[-1]
$expectedValues = @()

for ($i = 1; $i -le 5; $i++) {
    $expectedValues += $lastValue + $i * 0.5
}

Write-Host "`nComparaison avec les valeurs attendues:" -ForegroundColor Cyan
Write-Host "  Dernière valeur observée: $lastValue"

$totalError = 0
$maxError = 0

for ($i = 0; $i -lt $predictions.Predictions.Count; $i++) {
    $predicted = $predictions.Predictions[$i].PredictedValue
    $expected = $expectedValues[$i]
    $errorValue = [Math]::Abs($predicted - $expected)
    $totalError += $errorValue
    if ($errorValue -gt $maxError) {
        $maxError = $errorValue
    }

    Write-Host "  Heure +$($i+1): Prédit = $([Math]::Round($predicted, 2)), Attendu = $([Math]::Round($expected, 2)), Erreur = $([Math]::Round($errorValue, 2))"
}

$meanError = $totalError / $predictions.Predictions.Count
$accuracy = 1 - ($meanError / ($lastValue * 0.1))
$accuracy = [Math]::Max(0, [Math]::Min(1, $accuracy))

Write-Host "`nRésultats:" -ForegroundColor Cyan
Write-Host "  Erreur moyenne: $([Math]::Round($meanError, 2))"
Write-Host "  Erreur maximale: $([Math]::Round($maxError, 2))"
Write-Host "  Précision: $([Math]::Round($accuracy * 100, 1))%" -ForegroundColor $(if ($accuracy -gt 0.8) { "Green" } elseif ($accuracy -gt 0.5) { "Yellow" } else { "Red" })

if ($accuracy -gt 0.5) {
    Write-Host "`nTest réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nTest échoué: La précision des prédictions est insuffisante." -ForegroundColor Red
    exit 1
}
