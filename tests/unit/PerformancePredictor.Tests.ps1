# Tests unitaires pour le module PerformancePredictor
# Auteur: EMAIL_SENDER_1 Team
# Version: 1.0.0

# Importer le module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\PerformancePredictor.psm1"
if (Test-Path -Path $modulePath) {
    Import-Module $modulePath -Force
    Write-Host "Module importé avec succès: $modulePath" -ForegroundColor Green
} else {
    Write-Error "Module not found: $modulePath"
    exit 1
}

# Vérifier que les fonctions du module sont disponibles
$requiredFunctions = @(
    'Initialize-PerformancePredictor',
    'Start-ModelTraining',
    'Get-PerformancePrediction',
    'Find-PerformanceAnomaly',
    'Get-PerformanceTrend',
    'Export-PredictionReport'
)

$missingFunctions = @()
foreach ($function in $requiredFunctions) {
    if (-not (Get-Command -Name $function -ErrorAction SilentlyContinue)) {
        $missingFunctions += $function
    }
}

if ($missingFunctions.Count -gt 0) {
    Write-Error "Fonctions manquantes dans le module: $($missingFunctions -join ', ')"
    exit 1
}

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
            Timestamp      = $timestamp
            CPU            = [PSCustomObject]@{
                Usage = [Math]::Max(0, [Math]::Min(100, $cpuUsage))
            }
            Memory         = [PSCustomObject]@{
                Physical = [PSCustomObject]@{
                    UsagePercent = [Math]::Max(0, [Math]::Min(100, $memoryUsage))
                }
            }
            Disk           = [PSCustomObject]@{
                Usage = [PSCustomObject]@{
                    Average = [Math]::Max(0, [Math]::Min(100, $diskUsage))
                }
            }
            Network        = [PSCustomObject]@{
                BandwidthUsage = [Math]::Max(0, [Math]::Min(100, $networkUsage))
            }
            ResponseTime   = [Math]::Max(0, $responseTime)
            ErrorRate      = [Math]::Max(0, $errorRate)
            ThroughputRate = [Math]::Max(0, $throughputRate)
        }
    }

    return $metrics
}

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "PerformancePredictorTests"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Configuration pour les tests
$testConfig = @{
    ConfigPath             = Join-Path -Path $testDir -ChildPath "config.json"
    LogPath                = Join-Path -Path $testDir -ChildPath "logs.log"
    ModelStoragePath       = Join-Path -Path $testDir -ChildPath "models"
    PredictionHorizon      = 6
    AnomalySensitivity     = "Medium"
    RetrainingInterval     = 1
    MetricsToPredictString = "CPU.Usage,Memory.Usage,Disk.Usage,Network.BandwidthUsage,ResponseTime,ErrorRate,ThroughputRate"
}

# Générer des métriques de test
$testMetrics = New-TestMetrics -Count 48

Describe "PerformancePredictor Module Tests" {
    BeforeAll {
        # Initialiser le module avec la configuration de test
        Initialize-PerformancePredictor @testConfig
    }

    Context "Module Initialization" {
        It "Should initialize the module with the correct configuration" {
            $script:PerformancePredictorConfig.ConfigPath | Should -Be $testConfig.ConfigPath
            $script:PerformancePredictorConfig.LogPath | Should -Be $testConfig.LogPath
            $script:PerformancePredictorConfig.ModelStoragePath | Should -Be $testConfig.ModelStoragePath
            $script:PerformancePredictorConfig.PredictionHorizon | Should -Be $testConfig.PredictionHorizon
            $script:PerformancePredictorConfig.AnomalySensitivity | Should -Be $testConfig.AnomalySensitivity
            $script:PerformancePredictorConfig.RetrainingInterval | Should -Be $testConfig.RetrainingInterval
            $script:PerformancePredictorConfig.MetricsToPredictString | Should -Be $testConfig.MetricsToPredictString
        }

        It "Should create the necessary directories" {
            Test-Path -Path $testConfig.ModelStoragePath | Should -Be $true
            Test-Path -Path (Split-Path -Path $testConfig.ConfigPath -Parent) | Should -Be $true
            Test-Path -Path (Split-Path -Path $testConfig.LogPath -Parent) | Should -Be $true
        }

        It "Should create the configuration file" {
            Test-Path -Path $testConfig.ConfigPath | Should -Be $true
        }
    }

    Context "Export-MetricsToJson" {
        It "Should export metrics to JSON format" {
            $jsonPath = Join-Path -Path $testDir -ChildPath "metrics.json"
            $result = Export-MetricsToJson -Metrics $testMetrics -OutputPath $jsonPath

            $result | Should -Be $jsonPath
            Test-Path -Path $jsonPath | Should -Be $true

            $jsonContent = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json
            $jsonContent.Count | Should -Be $testMetrics.Count
            $jsonContent[0].PSObject.Properties.Name -contains "CPU.Usage" | Should -Be $true
            $jsonContent[0].PSObject.Properties.Name -contains "Memory.Usage" | Should -Be $true
            $jsonContent[0].PSObject.Properties.Name -contains "Disk.Usage" | Should -Be $true
            $jsonContent[0].PSObject.Properties.Name -contains "Network.BandwidthUsage" | Should -Be $true
            $jsonContent[0].PSObject.Properties.Name -contains "ResponseTime" | Should -Be $true
            $jsonContent[0].PSObject.Properties.Name -contains "ErrorRate" | Should -Be $true
            $jsonContent[0].PSObject.Properties.Name -contains "ThroughputRate" | Should -Be $true
        }
    }

    Context "Model Training and Prediction" {
        It "Should train models successfully" {
            $result = Start-ModelTraining -Metrics $testMetrics -Force

            $result | Should -Not -BeNullOrEmpty
            $result.PSObject.Properties.Name -contains "CPU.Usage" | Should -Be $true
            $result."CPU.Usage".status | Should -Be "success"
        }

        It "Should make predictions successfully" {
            $result = Get-PerformancePrediction -Metrics $testMetrics -MetricName "CPU.Usage" -Horizon 3

            $result | Should -Not -BeNullOrEmpty
            $result.status | Should -Be "success"
            $result.predictions.Count | Should -Be 3
            $result.timestamps.Count | Should -Be 3
        }

        It "Should detect anomalies successfully" {
            $result = Find-PerformanceAnomaly -Metrics $testMetrics -MetricName "CPU.Usage"

            $result | Should -Not -BeNullOrEmpty
            $result.status | Should -Be "success"
            $result.PSObject.Properties.Name -contains "anomalies" | Should -Be $true
            $result.PSObject.Properties.Name -contains "anomaly_count" | Should -Be $true
            $result.PSObject.Properties.Name -contains "total_points" | Should -Be $true
        }

        It "Should analyze trends successfully" {
            $result = Get-PerformanceTrend -Metrics $testMetrics -MetricName "CPU.Usage"

            $result | Should -Not -BeNullOrEmpty
            $result.status | Should -Be "success"
            $result.PSObject.Properties.Name -contains "statistics" | Should -Be $true
            $result.PSObject.Properties.Name -contains "trend" | Should -Be $true
            $result.trend.PSObject.Properties.Name -contains "direction" | Should -Be $true
            $result.trend.PSObject.Properties.Name -contains "strength" | Should -Be $true
            $result.trend.PSObject.Properties.Name -contains "slope" | Should -Be $true
        }
    }

    Context "Report Generation" {
        It "Should generate a JSON report successfully" {
            $reportPath = Join-Path -Path $testDir -ChildPath "report.json"
            $result = Export-PredictionReport -Metrics $testMetrics -OutputPath $reportPath -Format "JSON" -Horizon 3

            $result | Should -Be $reportPath
            Test-Path -Path $reportPath | Should -Be $true

            $reportContent = Get-Content -Path $reportPath -Raw | ConvertFrom-Json
            $reportContent.PSObject.Properties.Name -contains "Predictions" | Should -Be $true
            $reportContent.PSObject.Properties.Name -contains "Anomalies" | Should -Be $true
            $reportContent.PSObject.Properties.Name -contains "Trends" | Should -Be $true
        }

        It "Should generate an HTML report successfully" {
            $reportPath = Join-Path -Path $testDir -ChildPath "report.html"
            $result = Export-PredictionReport -Metrics $testMetrics -OutputPath $reportPath -Format "HTML" -Horizon 3 -MetricNames @("CPU.Usage")

            $result | Should -Be $reportPath
            Test-Path -Path $reportPath | Should -Be $true

            $reportContent = Get-Content -Path $reportPath -Raw
            $reportContent -match "<html>" | Should -Be $true
            $reportContent -match "<title>Rapport de prédiction des performances</title>" | Should -Be $true
            $reportContent -match "<h2>Métrique: CPU.Usage</h2>" | Should -Be $true
        }

        It "Should generate CSV reports successfully" {
            $reportPath = Join-Path -Path $testDir -ChildPath "report.csv"
            $result = Export-PredictionReport -Metrics $testMetrics -OutputPath $reportPath -Format "CSV" -Horizon 3 -MetricNames @("CPU.Usage")

            $result | Should -Be $reportPath
            Test-Path -Path $reportPath | Should -Be $true

            $predictionsPath = Join-Path -Path $testDir -ChildPath "report_predictions.csv"
            Test-Path -Path $predictionsPath | Should -Be $true

            $anomaliesPath = Join-Path -Path $testDir -ChildPath "report_anomalies.csv"
            Test-Path -Path $anomaliesPath | Should -Be $true

            $trendsPath = Join-Path -Path $testDir -ChildPath "report_trends.csv"
            Test-Path -Path $trendsPath | Should -Be $true
        }
    }

    AfterAll {
        # Nettoyer les fichiers de test
        if (Test-Path -Path $testDir) {
            Remove-Item -Path $testDir -Recurse -Force
        }
    }
}
