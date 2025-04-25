# Script d'exemple pour l'utilisation du module PerformancePredictor
# Auteur: EMAIL_SENDER_1 Team
# Version: 1.0.0

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\PerformancePredictor.psm1"
Import-Module $modulePath -Force

# Fonction pour générer des métriques de test
function New-TestMetrics {
    param (
        [int]$Count = 24,
        [datetime]$StartTime = (Get-Date).AddDays(-1)
    )

    $metrics = @()
    
    for ($i = 0; $i -lt $Count; $i++) {
        $timestamp = $StartTime.AddHours($i)
        
        # Simuler des tendances et des motifs
        $hour = $timestamp.Hour
        $cpuUsage = 30 + 20 * [Math]::Sin($hour / 12 * [Math]::PI) + (Get-Random -Minimum -5 -Maximum 5)
        $memoryUsage = 40 + 10 * [Math]::Sin($hour / 8 * [Math]::PI) + (Get-Random -Minimum -3 -Maximum 3)
        $diskUsage = 50 + 0.5 * $i + (Get-Random -Minimum -1 -Maximum 1)
        $networkUsage = 20 + 15 * [Math]::Sin($hour / 6 * [Math]::PI) + (Get-Random -Minimum -4 -Maximum 4)
        $responseTime = 100 + 50 * [Math]::Sin($hour / 12 * [Math]::PI) + (Get-Random -Minimum -10 -Maximum 10)
        $errorRate = 1 + 0.5 * [Math]::Sin($hour / 8 * [Math]::PI) + (Get-Random -Minimum -0.2 -Maximum 0.2)
        $throughputRate = 1000 + 500 * [Math]::Sin($hour / 6 * [Math]::PI) + (Get-Random -Minimum -100 -Maximum 100)
        
        # Ajouter une anomalie à la 15ème heure
        if ($i -eq 15) {
            $cpuUsage += 40
            $memoryUsage += 30
            $responseTime += 200
            $errorRate += 2
        }
        
        $metrics += [PSCustomObject]@{
            Timestamp = $timestamp
            CPU = [PSCustomObject]@{
                Usage = [Math]::Max(0, [Math]::Min(100, $cpuUsage))
            }
            Memory = [PSCustomObject]@{
                Physical = [PSCustomObject]@{
                    UsagePercent = [Math]::Max(0, [Math]::Min(100, $memoryUsage))
                }
            }
            Disk = [PSCustomObject]@{
                Usage = [PSCustomObject]@{
                    Average = [Math]::Max(0, [Math]::Min(100, $diskUsage))
                }
            }
            Network = [PSCustomObject]@{
                BandwidthUsage = [Math]::Max(0, [Math]::Min(100, $networkUsage))
            }
            ResponseTime = [Math]::Max(0, $responseTime)
            ErrorRate = [Math]::Max(0, $errorRate)
            ThroughputRate = [Math]::Max(0, $throughputRate)
        }
    }
    
    return $metrics
}

# Créer un répertoire pour les rapports
$reportsDir = Join-Path -Path $env:TEMP -ChildPath "PerformancePredictorReports"
if (-not (Test-Path -Path $reportsDir)) {
    New-Item -Path $reportsDir -ItemType Directory -Force | Out-Null
}

# Initialiser le module
Write-Host "Initialisation du module PerformancePredictor..." -ForegroundColor Cyan
Initialize-PerformancePredictor -ConfigPath "$reportsDir\config.json" -LogPath "$reportsDir\logs.log" -ModelStoragePath "$reportsDir\models" -PredictionHorizon 12 -AnomalySensitivity "Medium"

# Générer des métriques de test
Write-Host "Génération des métriques de test..." -ForegroundColor Cyan
$metrics = New-TestMetrics -Count 48

# Entraîner les modèles
Write-Host "Entraînement des modèles prédictifs..." -ForegroundColor Cyan
$trainingResult = Start-ModelTraining -Metrics $metrics -Force
Write-Host "Résultat de l'entraînement:" -ForegroundColor Green
$trainingResult | Format-Table -AutoSize

# Faire des prédictions pour l'utilisation CPU
Write-Host "Prédiction de l'utilisation CPU..." -ForegroundColor Cyan
$cpuPrediction = Get-PerformancePrediction -Metrics $metrics -MetricName "CPU.Usage" -Horizon 6
Write-Host "Prédictions CPU:" -ForegroundColor Green
for ($i = 0; $i -lt $cpuPrediction.predictions.Count; $i++) {
    Write-Host "  $($cpuPrediction.timestamps[$i]): $($cpuPrediction.predictions[$i])%"
}

# Détecter les anomalies dans l'utilisation mémoire
Write-Host "Détection des anomalies dans l'utilisation mémoire..." -ForegroundColor Cyan
$memoryAnomalies = Find-PerformanceAnomaly -Metrics $metrics -MetricName "Memory.Usage" -Sensitivity "High"
Write-Host "Anomalies mémoire détectées: $($memoryAnomalies.anomaly_count)" -ForegroundColor Green
if ($memoryAnomalies.anomalies.Count -gt 0) {
    $memoryAnomalies.anomalies | Format-Table timestamp, value, score, severity -AutoSize
}
else {
    Write-Host "  Aucune anomalie détectée."
}

# Analyser les tendances du temps de réponse
Write-Host "Analyse des tendances du temps de réponse..." -ForegroundColor Cyan
$responseTrend = Get-PerformanceTrend -Metrics $metrics -MetricName "ResponseTime"
Write-Host "Tendance du temps de réponse:" -ForegroundColor Green
Write-Host "  Direction: $($responseTrend.trend.direction)"
Write-Host "  Force: $($responseTrend.trend.strength)"
Write-Host "  Pente: $($responseTrend.trend.slope)"
Write-Host "  Statistiques: Moyenne=$($responseTrend.statistics.mean), Min=$($responseTrend.statistics.min), Max=$($responseTrend.statistics.max)"

# Générer un rapport complet
Write-Host "Génération d'un rapport complet..." -ForegroundColor Cyan
$reportPath = Join-Path -Path $reportsDir -ChildPath "rapport_complet.html"
$reportResult = Export-PredictionReport -Metrics $metrics -OutputPath $reportPath -Format "HTML" -Horizon 12 -MetricNames @("CPU.Usage", "Memory.Usage", "ResponseTime", "ErrorRate")
Write-Host "Rapport généré: $reportPath" -ForegroundColor Green

# Ouvrir le rapport dans le navigateur par défaut
Write-Host "Ouverture du rapport dans le navigateur..." -ForegroundColor Cyan
Start-Process $reportPath

Write-Host "Exemple terminé. Les fichiers générés se trouvent dans $reportsDir" -ForegroundColor Yellow
