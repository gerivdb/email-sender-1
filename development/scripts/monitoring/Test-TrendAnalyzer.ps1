#Requires -Version 5.1
<#
.SYNOPSIS
    Script de test pour le module TrendAnalyzer.
.DESCRIPTION
    Ce script teste les fonctionnalités du module TrendAnalyzer en exécutant
    chaque fonction et en affichant les résultats.
.NOTES
    Nom: Test-TrendAnalyzer.ps1
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.3
    Date de création: 2025-05-13
#>

# Importer le module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "TrendAnalyzer.psm1"
Import-Module $modulePath -Force

# Créer le dossier de données de test si nécessaire
$testDataPath = Join-Path -Path $PSScriptRoot -ChildPath "data\metrics\TestCollector"
if (-not (Test-Path -Path $testDataPath)) {
    New-Item -Path $testDataPath -ItemType Directory -Force | Out-Null
}

# Variables globales pour les tests
$script:TestCollectorName = "TestCollector"
$script:TestStartTime = (Get-Date).AddHours(-1)
$script:TestEndTime = Get-Date
$script:TestMetricNames = @("CPU_Usage", "Memory_Usage")

# Fonction pour créer des données de métriques simulées
function New-SimulatedMetricsData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$CollectorName,

        [Parameter(Mandatory = $true)]
        [DateTime]$StartTime,

        [Parameter(Mandatory = $true)]
        [DateTime]$EndTime,

        [Parameter(Mandatory = $false)]
        [int]$SampleCount = 30
    )

    # Calculer l'intervalle entre les échantillons
    $interval = ($EndTime - $StartTime).TotalSeconds / $SampleCount

    # Créer les fichiers de métriques
    for ($i = 0; $i -lt $SampleCount; $i++) {
        $timestamp = $StartTime.AddSeconds($i * $interval)
        $formattedTimestamp = $timestamp.ToString("yyyyMMdd_HHmmss")
        $filePath = Join-Path -Path $testDataPath -ChildPath "metrics_$formattedTimestamp.json"

        # Créer les données de métriques
        $cpuValue = [Math]::Min(100, [Math]::Max(0, 50 + $i * 0.5 + (Get-Random -Minimum -5 -Maximum 5)))
        $memoryValue = [Math]::Min(100, [Math]::Max(0, 60 + $i * 0.3 + (Get-Random -Minimum -3 -Maximum 3)))

        $metricsData = @{
            Timestamp     = $timestamp.ToString("o")
            CollectorName = $CollectorName
            Metrics       = @(
                @{
                    Name  = "CPU_Usage"
                    Value = $cpuValue
                    Unit  = "%"
                },
                @{
                    Name  = "Memory_Usage"
                    Value = $memoryValue
                    Unit  = "%"
                }
            )
        }

        # Enregistrer le fichier
        $metricsData | ConvertTo-Json -Depth 10 | Out-File -FilePath $filePath -Encoding utf8
    }

    Write-Host "Données de métriques simulées créées avec succès:"
    Write-Host "  Fichier: $filePath"
    Write-Host "  Période: $($StartTime.ToString('MM/dd/yyyy HH:mm:ss')) - $($EndTime.ToString('MM/dd/yyyy HH:mm:ss'))"
    Write-Host "  Échantillons: $SampleCount"

    return $true
}

# Fonction pour nettoyer les ressources de test
function Remove-TestResources {
    [CmdletBinding()]
    param()

    # Supprimer les fichiers de métriques de test
    if (Test-Path -Path $testDataPath) {
        Get-ChildItem -Path $testDataPath -Filter "metrics_*.json" | Remove-Item -Force
    }
}

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

# Initialisation
Write-Host "Nettoyage des ressources de test..." -ForegroundColor Yellow
Remove-TestResources

# Test 1: Création de données de métriques simulées
$test1 = Invoke-Test -TestName "Simulation de données de métriques pour les tests" -TestScript {
    New-SimulatedMetricsData -CollectorName $script:TestCollectorName -StartTime $script:TestStartTime -EndTime $script:TestEndTime
}

# Test 2: Extraction des données historiques
$test2 = Invoke-Test -TestName "Extraction des données historiques" -TestScript {
    $historicalData = Get-HistoricalMetricsData -CollectorName $script:TestCollectorName -StartTime $script:TestStartTime -EndTime $script:TestEndTime

    if ($null -eq $historicalData) {
        Write-Host "Échec: Aucune donnée historique retournée." -ForegroundColor Red
        return $false
    }

    Write-Host "Données historiques extraites avec succès:"
    Write-Host "  Collecteur: $($historicalData.CollectorName)"
    Write-Host "  Période: $($historicalData.StartTime.ToString('MM/dd/yyyy HH:mm:ss')) - $($historicalData.EndTime.ToString('MM/dd/yyyy HH:mm:ss'))"
    Write-Host "  Métriques: $($historicalData.MetricsData.Keys -join ', ')"
    Write-Host "  Échantillons CPU: $($historicalData.MetricsData.CPU_Usage.Values.Count)"

    # Vérifier que les données sont correctes
    $cpuData = $historicalData.MetricsData.CPU_Usage
    $memoryData = $historicalData.MetricsData.Memory_Usage

    if ($cpuData.Values.Count -gt 0 -and $memoryData.Values.Count -gt 0) {
        return $true
    } else {
        Write-Host "Échec: Données incomplètes." -ForegroundColor Red
        return $false
    }
}

# Test 3: Échantillonnage des données
$test3 = Invoke-Test -TestName "Échantillonnage des données historiques" -TestScript {
    $historicalData = Get-HistoricalMetricsData -CollectorName $script:TestCollectorName -StartTime $script:TestStartTime -EndTime $script:TestEndTime -SamplingInterval 300

    if ($null -eq $historicalData) {
        Write-Host "Échec: Aucune donnée historique retournée." -ForegroundColor Red
        return $false
    }

    Write-Host "Données échantillonnées avec succès:"
    Write-Host "  Intervalle d'échantillonnage: $($historicalData.SamplingInterval) secondes"
    Write-Host "  Échantillons CPU après échantillonnage: $($historicalData.MetricsData.CPU_Usage.Values.Count)"

    # Vérifier que l'échantillonnage a réduit le nombre de points
    if ($historicalData.MetricsData.CPU_Usage.Values.Count -lt 30) {
        return $true
    } else {
        Write-Host "Échec: L'échantillonnage n'a pas réduit le nombre de points." -ForegroundColor Red
        return $false
    }
}

# Test 4: Détection de patterns cycliques journaliers
$test4 = Invoke-Test -TestName "Détection de patterns cycliques journaliers" -TestScript {
    # Créer des données avec un pattern journalier clair
    $testDataPath = Join-Path -Path $PSScriptRoot -ChildPath "data\metrics\TestCyclicCollector"
    if (-not (Test-Path -Path $testDataPath)) {
        New-Item -Path $testDataPath -ItemType Directory -Force | Out-Null
    }

    # Nettoyer les fichiers existants
    Get-ChildItem -Path $testDataPath -Filter "metrics_*.json" | Remove-Item -Force

    # Créer 72 heures de données (3 jours) avec un pattern clair
    $startTime = (Get-Date).Date.AddDays(-3)
    $endTime = (Get-Date).Date

    # Générer des données avec un pattern journalier (pic à 14h, creux à 2h)
    for ($day = 0; $day -lt 3; $day++) {
        for ($hour = 0; $hour -lt 24; $hour++) {
            $timestamp = $startTime.AddDays($day).AddHours($hour)
            $formattedTimestamp = $timestamp.ToString("yyyyMMdd_HHmmss")
            $filePath = Join-Path -Path $testDataPath -ChildPath "metrics_$formattedTimestamp.json"

            # Créer un pattern avec un pic à 14h (50 + 40 = 90%) et un creux à 2h (50 - 40 = 10%)
            $baseValue = 50
            $amplitude = 40

            # Calculer la valeur en fonction de l'heure (pic à 14h, creux à 2h)
            # Utiliser une fonction linéaire par morceaux pour créer le pattern
            if ($hour -ge 2 -and $hour -lt 14) {
                # De 2h à 14h: montée progressive
                $factor = ($hour - 2) / 12.0
                $cpuValue = $baseValue + $amplitude * $factor
            } elseif ($hour -ge 14) {
                # De 14h à 2h (le lendemain): descente progressive
                $factor = 1 - (($hour - 14) / 12.0)
                $cpuValue = $baseValue + $amplitude * $factor
            } else {
                # De 0h à 2h: fin de la descente
                $factor = 1 - ((24 + $hour - 14) / 12.0)
                $cpuValue = $baseValue + $amplitude * $factor
            }

            # S'assurer que la valeur est entre 0 et 100
            $cpuValue = [Math]::Min(100, [Math]::Max(0, $cpuValue))

            # Ajouter un peu de bruit aléatoire
            $cpuValue = [Math]::Min(100, [Math]::Max(0, $cpuValue + (Get-Random -Minimum -5 -Maximum 5)))

            $metricsData = @{
                Timestamp     = $timestamp.ToString("o")
                CollectorName = "TestCyclicCollector"
                Metrics       = @(
                    @{
                        Name  = "CPU_Usage"
                        Value = $cpuValue
                        Unit  = "%"
                    }
                )
            }

            # Enregistrer le fichier
            $metricsData | ConvertTo-Json -Depth 10 | Out-File -FilePath $filePath -Encoding utf8
        }
    }

    # Extraire les données historiques
    $historicalData = Get-HistoricalMetricsData -CollectorName "TestCyclicCollector" -StartTime $startTime -EndTime $endTime

    # Détecter les patterns cycliques
    $cyclicPatterns = Find-CyclicPatterns -MetricsData $historicalData -MetricName "CPU_Usage" -CycleTypes @("Daily")

    if ($null -eq $cyclicPatterns) {
        Write-Host "Échec: Aucun résultat de détection de patterns cycliques retourné." -ForegroundColor Red
        return $false
    }

    Write-Host "Détection de patterns cycliques journaliers:"
    Write-Host "  Pattern cyclique détecté: $($cyclicPatterns.HasCyclicPatterns)"

    if ($cyclicPatterns.HasCyclicPatterns) {
        $dailyPattern = $cyclicPatterns.CyclicPatterns.Daily
        Write-Host "  Coefficient de variation: $([Math]::Round($dailyPattern.CoefficientOfVariation, 3))"
        Write-Host "  Heure de pic: $($dailyPattern.PeakHour)h ($([Math]::Round($dailyPattern.PeakValue, 1))%)"
        Write-Host "  Heure de creux: $($dailyPattern.TroughHour)h ($([Math]::Round($dailyPattern.TroughValue, 1))%)"
        Write-Host "  Confiance: $([Math]::Round($dailyPattern.Confidence * 100, 1))%"

        # Vérifier que le pic est autour de 14h (±2h) et le creux autour de 2h (±2h)
        $peakHourOK = [Math]::Abs($dailyPattern.PeakHour - 14) -le 2
        $troughHourOK = [Math]::Abs($dailyPattern.TroughHour - 2) -le 2

        if ($peakHourOK -and $troughHourOK) {
            return $true
        } else {
            Write-Host "Échec: Les heures de pic et de creux ne correspondent pas au pattern attendu." -ForegroundColor Red
            return $false
        }
    } else {
        Write-Host "Échec: Aucun pattern cyclique journalier détecté." -ForegroundColor Red
        return $false
    }
}

# Test 5: Normalisation des données
$test5 = Invoke-Test -TestName "Normalisation des données de métriques" -TestScript {
    # Créer des données avec des échelles différentes
    $testDataPath = Join-Path -Path $PSScriptRoot -ChildPath "data\metrics\TestNormCollector"
    if (-not (Test-Path -Path $testDataPath)) {
        New-Item -Path $testDataPath -ItemType Directory -Force | Out-Null
    }

    # Nettoyer les fichiers existants
    Get-ChildItem -Path $testDataPath -Filter "metrics_*.json" | Remove-Item -Force

    # Créer 24 heures de données avec des échelles différentes
    $startTime = (Get-Date).Date.AddDays(-1)
    $endTime = (Get-Date).Date

    # Générer des données avec des échelles différentes
    for ($hour = 0; $hour -lt 24; $hour++) {
        $timestamp = $startTime.AddHours($hour)
        $formattedTimestamp = $timestamp.ToString("yyyyMMdd_HHmmss")
        $filePath = Join-Path -Path $testDataPath -ChildPath "metrics_$formattedTimestamp.json"

        # CPU: 0-100%, Memory: 0-16GB, Disk: 0-500MB/s
        $cpuValue = 50 + 30 * [Math]::Sin($hour * [Math]::PI / 12)
        $memoryValue = 8 + 6 * [Math]::Cos($hour * [Math]::PI / 12)
        $diskValue = 250 + 200 * [Math]::Sin($hour * [Math]::PI / 8)

        # Ajouter un peu de bruit aléatoire
        $cpuValue = [Math]::Min(100, [Math]::Max(0, $cpuValue + (Get-Random -Minimum -5 -Maximum 5)))
        $memoryValue = [Math]::Min(16, [Math]::Max(0, $memoryValue + (Get-Random -Minimum -0.5 -Maximum 0.5)))
        $diskValue = [Math]::Min(500, [Math]::Max(0, $diskValue + (Get-Random -Minimum -20 -Maximum 20)))

        $metricsData = @{
            Timestamp     = $timestamp.ToString("o")
            CollectorName = "TestNormCollector"
            Metrics       = @(
                @{
                    Name  = "CPU_Usage"
                    Value = $cpuValue
                    Unit  = "%"
                },
                @{
                    Name  = "Memory_Usage"
                    Value = $memoryValue
                    Unit  = "GB"
                },
                @{
                    Name  = "Disk_IO"
                    Value = $diskValue
                    Unit  = "MB/s"
                }
            )
        }

        # Enregistrer le fichier
        $metricsData | ConvertTo-Json -Depth 10 | Out-File -FilePath $filePath -Encoding utf8
    }

    # Extraire les données historiques
    $historicalData = Get-HistoricalMetricsData -CollectorName "TestNormCollector" -StartTime $startTime -EndTime $endTime

    # Tester la normalisation MinMax
    $normalizedMinMax = ConvertTo-NormalizedMetrics -MetricsData $historicalData -Method "MinMax"

    if ($null -eq $normalizedMinMax) {
        Write-Host "Échec: Aucun résultat de normalisation MinMax retourné." -ForegroundColor Red
        return $false
    }

    # Tester la normalisation ZScore
    $normalizedZScore = ConvertTo-NormalizedMetrics -MetricsData $historicalData -Method "ZScore"

    if ($null -eq $normalizedZScore) {
        Write-Host "Échec: Aucun résultat de normalisation ZScore retourné." -ForegroundColor Red
        return $false
    }

    # Tester la normalisation Robust
    $normalizedRobust = ConvertTo-NormalizedMetrics -MetricsData $historicalData -Method "Robust"

    if ($null -eq $normalizedRobust) {
        Write-Host "Échec: Aucun résultat de normalisation Robust retourné." -ForegroundColor Red
        return $false
    }

    # Vérifier que les valeurs normalisées sont dans les plages attendues
    $minMaxValues = $normalizedMinMax.MetricsData.CPU_Usage.Values
    $zScoreValues = $normalizedZScore.MetricsData.CPU_Usage.Values
    $robustValues = $normalizedRobust.MetricsData.CPU_Usage.Values

    $minMaxInRange = ($minMaxValues | Where-Object { $_ -ge 0 -and $_ -le 1 }).Count -eq $minMaxValues.Count

    Write-Host "Résultats de normalisation:"
    Write-Host "  Méthode MinMax: Plage [$([Math]::Round(($minMaxValues | Measure-Object -Minimum).Minimum, 3)) - $([Math]::Round(($minMaxValues | Measure-Object -Maximum).Maximum, 3))]"
    Write-Host "  Méthode ZScore: Plage [$([Math]::Round(($zScoreValues | Measure-Object -Minimum).Minimum, 3)) - $([Math]::Round(($zScoreValues | Measure-Object -Maximum).Maximum, 3))]"
    Write-Host "  Méthode Robust: Plage [$([Math]::Round(($robustValues | Measure-Object -Minimum).Minimum, 3)) - $([Math]::Round(($robustValues | Measure-Object -Maximum).Maximum, 3))]"

    # Vérifier que les statistiques originales sont correctement stockées
    $cpuStats = $normalizedMinMax.OriginalStats.CPU_Usage

    Write-Host "  Statistiques originales CPU:"
    Write-Host "    Min: $([Math]::Round($cpuStats.Min, 1))%"
    Write-Host "    Max: $([Math]::Round($cpuStats.Max, 1))%"
    Write-Host "    Moyenne: $([Math]::Round($cpuStats.Mean, 1))%"

    if ($minMaxInRange) {
        return $true
    } else {
        Write-Host "Échec: Les valeurs normalisées MinMax ne sont pas dans la plage [0,1]." -ForegroundColor Red
        return $false
    }
}

# Résumé des tests
$totalTests = 5
$passedTests = @($test1, $test2, $test3, $test4, $test5).Where({ $_ -eq $true }).Count
$failedTests = $totalTests - $passedTests

Write-Host "`n========== RÉSUMÉ DES TESTS ==========" -ForegroundColor Cyan
Write-Host "Tests exécutés: $totalTests" -ForegroundColor White
Write-Host "Tests réussis: $passedTests" -ForegroundColor Green
Write-Host "Tests échoués: $failedTests" -ForegroundColor Red

if ($failedTests -eq 0) {
    Write-Host "`nTous les tests ont réussi!" -ForegroundColor Green
} else {
    Write-Host "`nCertains tests ont échoué. Vérifiez les messages d'erreur ci-dessus." -ForegroundColor Red
}

# Nettoyage final
Write-Host "`nNettoyage des ressources de test..." -ForegroundColor Yellow
Remove-TestResources
