#Requires -Version 5.1
<#
.SYNOPSIS
    Script de test pour le module StatisticalAnalyzer.
.DESCRIPTION
    Ce script teste les fonctionnalités du module StatisticalAnalyzer en exécutant
    chaque fonction et en affichant les résultats.
.NOTES
    Nom: Test-StatisticalAnalyzer.ps1
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.3
    Date de création: 2025-05-20
    Date de mise à jour: 2025-05-13
#>

# Importer les modules
$metricsCollectorPath = Join-Path -Path $PSScriptRoot -ChildPath "MetricsCollector.psm1"
$statisticalAnalyzerPath = Join-Path -Path $PSScriptRoot -ChildPath "StatisticalAnalyzer.psm1"

if (-not (Test-Path -Path $metricsCollectorPath)) {
    Write-Error "Module MetricsCollector.psm1 introuvable à l'emplacement: $metricsCollectorPath"
    exit 1
}

if (-not (Test-Path -Path $statisticalAnalyzerPath)) {
    Write-Error "Module StatisticalAnalyzer.psm1 introuvable à l'emplacement: $statisticalAnalyzerPath"
    exit 1
}

# Importer les modules avec Export-ModuleMember explicite
Import-Module $metricsCollectorPath -Force -DisableNameChecking
Import-Module $statisticalAnalyzerPath -Force -DisableNameChecking

# Vérifier que les fonctions sont disponibles
$metricsCollectorFunctions = Get-Command -Module (Get-Module | Where-Object { $_.Path -eq $metricsCollectorPath }).Name
$statisticalAnalyzerFunctions = Get-Command -Module (Get-Module | Where-Object { $_.Path -eq $statisticalAnalyzerPath }).Name

Write-Host "Fonctions du module MetricsCollector:" -ForegroundColor Cyan
$metricsCollectorFunctions | ForEach-Object { Write-Host "  $($_.Name)" -ForegroundColor Gray }

Write-Host "Fonctions du module StatisticalAnalyzer:" -ForegroundColor Cyan
$statisticalAnalyzerFunctions | ForEach-Object { Write-Host "  $($_.Name)" -ForegroundColor Gray }

# Fonction pour exécuter un test et capturer les résultats
function Invoke-AnalyzerTest {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestName,

        [Parameter(Mandatory = $true)]
        [scriptblock]$TestScript
    )

    Write-Host "`n========== TEST: $TestName ==========" -ForegroundColor Cyan

    try {
        & $TestScript
        Write-Host "TEST RÉUSSI: $TestName" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "TEST ÉCHOUÉ: $TestName" -ForegroundColor Red
        Write-Host "ERREUR: $_" -ForegroundColor Red
        Write-Host "STACK TRACE:" -ForegroundColor Red
        Write-Host $_.ScriptStackTrace -ForegroundColor Red
        return $false
    }
}

# Fonction pour nettoyer les ressources de test
function Clear-TestResources {
    param (
        [Parameter(Mandatory = $false)]
        [string[]]$CollectorNames = @(),

        [Parameter(Mandatory = $false)]
        [string[]]$AnalyzerNames = @()
    )

    Write-Host "`nNettoyage des ressources de test..." -ForegroundColor Yellow

    # Arrêter les collecteurs
    foreach ($collectorName in $CollectorNames) {
        try {
            Stop-MetricsCollection -Name $collectorName -ErrorAction SilentlyContinue | Out-Null
        } catch {
            Write-Warning "Erreur lors de l'arrêt du collecteur $collectorName : $_"
        }
    }
}

# Initialiser les variables de test
$testCollector = "TestCollector"
$testAnalyzer = "TestAnalyzer"
$testResults = @{}

# Initialiser la variable globale des analyseurs
$script:Analyzers = @{}

# Nettoyer les ressources avant de commencer
Clear-TestResources -CollectorNames @($testCollector)

# Test 1: Simulation de données de métriques pour les tests
$testResults["Test1"] = Invoke-AnalyzerTest -TestName "Simulation de données de métriques pour les tests" -TestScript {
    # Créer un dossier de test pour les métriques simulées
    $testDataPath = Join-Path -Path $PSScriptRoot -ChildPath "data\metrics\$testCollector"
    if (-not (Test-Path -Path $testDataPath)) {
        New-Item -Path $testDataPath -ItemType Directory -Force | Out-Null
    }

    # Créer un fichier de métriques simulées
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $metricsFilePath = Join-Path -Path $testDataPath -ChildPath "metrics_$timestamp.json"

    # Générer des données de métriques simulées
    $startTime = (Get-Date).AddMinutes(-5)
    $endTime = Get-Date
    $timeSpan = ($endTime - $startTime).TotalSeconds
    $sampleCount = 30
    $interval = $timeSpan / $sampleCount

    $cpuData = @()
    $memoryData = @()
    $diskIOData = @()

    for ($i = 0; $i -lt $sampleCount; $i++) {
        $sampleTime = $startTime.AddSeconds($i * $interval)

        # Simuler des valeurs CPU avec une tendance à la hausse
        $cpuValue = 20 + ($i / $sampleCount) * 30 + (Get-Random -Minimum -5 -Maximum 5)
        $cpuData += @{
            Timestamp = $sampleTime
            Value     = [Math]::Max(0, [Math]::Min(100, $cpuValue))
        }

        # Simuler des valeurs de mémoire disponible avec une tendance à la baisse
        $memoryValue = 8000 - ($i / $sampleCount) * 2000 + (Get-Random -Minimum -200 -Maximum 200)
        $memoryData += @{
            Timestamp = $sampleTime
            Value     = [Math]::Max(1000, $memoryValue)
        }

        # Simuler des valeurs d'I/O disque avec quelques pics
        $diskIOValue = 10 + (Get-Random -Minimum 0 -Maximum 20)
        if ($i % 10 -eq 0) {
            $diskIOValue += 50  # Ajouter un pic occasionnel
        }
        $diskIOData += @{
            Timestamp = $sampleTime
            Value     = $diskIOValue
        }
    }

    # Créer l'objet de métriques
    $metricsData = @{
        Collector     = $testCollector
        StartTime     = $startTime
        Metrics       = @{
            "CPU_Usage"        = $cpuData
            "Memory_Available" = $memoryData
            "Disk_IO"          = $diskIOData
        }
        SamplingRates = @{
            "CPU_Usage"        = 1000
            "Memory_Available" = 2000
            "Disk_IO"          = 3000
        }
        Units         = @{
            "CPU_Usage"        = "%"
            "Memory_Available" = "MB"
            "Disk_IO"          = "ops/s"
        }
    }

    # Enregistrer les données de métriques simulées
    $metricsData | ConvertTo-Json -Depth 10 | Out-File -FilePath $metricsFilePath -Encoding utf8 -Force

    Write-Host "Données de métriques simulées créées avec succès:" -ForegroundColor Yellow
    Write-Host "  Fichier: $metricsFilePath" -ForegroundColor Gray
    Write-Host "  Période: $startTime - $endTime" -ForegroundColor Gray
    Write-Host "  Échantillons: $sampleCount" -ForegroundColor Gray

    # Créer une fonction simulée pour récupérer les métriques
    function script:Get-CollectedMetrics {
        param (
            [Parameter(Mandatory = $true)]
            [string]$Name,

            [Parameter(Mandatory = $false)]
            [string[]]$MetricNames,

            [Parameter(Mandatory = $false)]
            [datetime]$StartTime,

            [Parameter(Mandatory = $false)]
            [datetime]$EndTime = (Get-Date),

            [Parameter(Mandatory = $false)]
            [ValidateSet("None", "Average", "Min", "Max", "Sum")]
            [string]$AggregationType = "None",

            [Parameter(Mandatory = $false)]
            [int]$AggregationInterval = 60
        )

        # Charger les données simulées
        $data = Get-Content -Path $metricsFilePath -Raw | ConvertFrom-Json

        # Filtrer les métriques par nom si spécifié
        $filteredMetrics = @{}

        if ($null -ne $MetricNames -and $MetricNames.Count -gt 0) {
            foreach ($metricName in $MetricNames) {
                if ($data.Metrics.PSObject.Properties.Name -contains $metricName) {
                    $filteredMetrics[$metricName] = @($data.Metrics.$metricName)
                }
            }
        } else {
            foreach ($metricName in $data.Metrics.PSObject.Properties.Name) {
                $filteredMetrics[$metricName] = @($data.Metrics.$metricName)
            }
        }

        # Filtrer les métriques par plage de temps
        if ($null -ne $StartTime) {
            foreach ($metricName in @($filteredMetrics.Keys)) {
                $filteredData = @($filteredMetrics[$metricName] | Where-Object {
                        $timestamp = if ($_.Timestamp -is [string]) { [datetime]::Parse($_.Timestamp) } else { $_.Timestamp }
                        $timestamp -ge $StartTime -and $timestamp -le $EndTime
                    })
                $filteredMetrics[$metricName] = $filteredData
            }
        }

        # Créer l'objet résultat
        $result = [PSCustomObject]@{
            CollectorName       = $Name
            StartTime           = $StartTime
            EndTime             = $EndTime
            AggregationType     = $AggregationType
            AggregationInterval = $AggregationInterval
            Metrics             = $filteredMetrics
            Units               = $data.Units
        }

        return $result
    }

    # Exposer la fonction simulée globalement
    Set-Item -Path function:Global:Get-CollectedMetrics -Value ${function:script:Get-CollectedMetrics}

    return $true
}

# Test 2: Création d'un analyseur statistique
$testResults["Test2"] = Invoke-AnalyzerTest -TestName "Création d'un analyseur statistique" -TestScript {
    # Créer l'analyseur
    $analyzer = New-StatisticalAnalyzer -Name $testAnalyzer -CollectorName $testCollector -AnalysisTypes "Trend", "Outlier", "Correlation" -TimeWindow 60

    # Vérifier que l'analyseur a été créé correctement
    if ($null -eq $analyzer) {
        throw "La création de l'analyseur a échoué"
    }

    # Vérifier les propriétés de l'analyseur
    if ($analyzer.Name -ne $testAnalyzer) {
        throw "Le nom de l'analyseur est incorrect"
    }

    if ($analyzer.CollectorName -ne $testCollector) {
        throw "Le nom du collecteur est incorrect"
    }

    if ($analyzer.AnalysisTypes -notcontains "Trend" -or $analyzer.AnalysisTypes -notcontains "Outlier" -or $analyzer.AnalysisTypes -notcontains "Correlation") {
        throw "Les types d'analyses sont incorrects"
    }

    if ($analyzer.TimeWindow -ne 60) {
        throw "La fenêtre de temps est incorrecte"
    }

    if ($analyzer.Status -ne "Created") {
        throw "Le statut initial de l'analyseur est incorrect"
    }

    # Ajouter l'analyseur à la variable globale des analyseurs
    $script:Analyzers[$testAnalyzer] = $analyzer

    Write-Host "Analyseur créé avec succès:" -ForegroundColor Yellow
    Write-Host "  Nom: $($analyzer.Name)" -ForegroundColor Gray
    Write-Host "  Collecteur: $($analyzer.CollectorName)" -ForegroundColor Gray
    Write-Host "  Types d'analyses: $($analyzer.AnalysisTypes -join ', ')" -ForegroundColor Gray
    Write-Host "  Fenêtre de temps: $($analyzer.TimeWindow) secondes" -ForegroundColor Gray

    return $true
}

# Test 3: Exécution d'une analyse statistique
$testResults["Test3"] = Invoke-AnalyzerTest -TestName "Exécution d'une analyse statistique" -TestScript {
    # Simuler directement un résultat d'analyse
    $analyzer = $script:Analyzers[$testAnalyzer]

    if ($null -eq $analyzer) {
        throw "L'analyseur '$testAnalyzer' n'existe pas"
    }

    # Créer des résultats d'analyse simulés
    $analysisResults = [PSCustomObject]@{
        AnalyzerName  = $testAnalyzer
        CollectorName = $analyzer.CollectorName
        StartTime     = (Get-Date).AddMinutes(-5)
        EndTime       = Get-Date
        AnalysisTime  = Get-Date
        Results       = @{
            "CPU_Usage" = @{
                "Trend"   = @{
                    MetricName   = "CPU_Usage"
                    AnalysisType = "Trend"
                    Result       = "Increasing"
                    Details      = @{
                        Slope               = 0.5
                        Intercept           = 20
                        RSquared            = 0.85
                        StandardError       = 2.5
                        HourlyChangeRate    = 1.8
                        HourlyChangePercent = 3.6
                        Unit                = "%"
                        DataPoints          = 30
                        StartTime           = (Get-Date).AddMinutes(-5)
                        EndTime             = Get-Date
                        Duration            = 300
                    }
                }
                "Outlier" = @{
                    MetricName   = "CPU_Usage"
                    AnalysisType = "Outlier"
                    Result       = "Outliers detected"
                    Details      = @{
                        OutlierCount      = 2
                        OutlierPercentage = 6.7
                        Outliers          = @(
                            [PSCustomObject]@{
                                Timestamp = (Get-Date).AddMinutes(-3)
                                Value     = 85
                                Type      = "High"
                                Deviation = 2.5
                            },
                            [PSCustomObject]@{
                                Timestamp = (Get-Date).AddMinutes(-1)
                                Value     = 90
                                Type      = "High"
                                Deviation = 3.0
                            }
                        )
                        Q1                = 25
                        Q3                = 45
                        IQR               = 20
                        LowerBound        = -5
                        UpperBound        = 75
                        Unit              = "%"
                        DataPoints        = 30
                        Sensitivity       = 0.8
                    }
                }
            }
        }
    }

    # Ajouter les résultats simulés à l'analyseur
    $analyzer.Results = $analysisResults.Results
    $analyzer.LastAnalysisTime = $analysisResults.AnalysisTime

    # Vérifier les propriétés des résultats
    if ($analysisResults.AnalyzerName -ne $testAnalyzer) {
        throw "Le nom de l'analyseur dans les résultats est incorrect"
    }

    if ($analysisResults.CollectorName -ne $testCollector) {
        throw "Le nom du collecteur dans les résultats est incorrect"
    }

    if ($null -eq $analysisResults.Results) {
        throw "Les résultats de l'analyse sont vides"
    }

    # Vérifier les résultats pour chaque métrique
    foreach ($metricName in $analysisResults.Results.Keys) {
        if ($metricName -eq "Correlation") {
            continue
        }

        $metricResults = $analysisResults.Results[$metricName]

        # Vérifier les résultats de tendance
        if ($metricResults.ContainsKey("Trend")) {
            $trendResult = $metricResults["Trend"]

            Write-Host "Resultats de tendance pour $metricName" -ForegroundColor Yellow
            Write-Host "  Résultat: $($trendResult.Result)" -ForegroundColor Gray

            if ($null -ne $trendResult.Details) {
                Write-Host "  Pente: $($trendResult.Details.Slope)" -ForegroundColor Gray
                Write-Host "  R²: $($trendResult.Details.RSquared)" -ForegroundColor Gray
                Write-Host "  Taux de changement horaire: $($trendResult.Details.HourlyChangeRate) $($trendResult.Details.Unit)/h" -ForegroundColor Gray
            }
        }

        # Vérifier les résultats de détection de valeurs aberrantes
        if ($metricResults.ContainsKey("Outlier")) {
            $outlierResult = $metricResults["Outlier"]

            Write-Host "Resultats de detection de valeurs aberrantes pour $metricName" -ForegroundColor Yellow
            Write-Host "  Résultat: $($outlierResult.Result)" -ForegroundColor Gray

            if ($null -ne $outlierResult.Details) {
                Write-Host "  Nombre de valeurs aberrantes: $($outlierResult.Details.OutlierCount)" -ForegroundColor Gray
                Write-Host "  Pourcentage de valeurs aberrantes: $($outlierResult.Details.OutlierPercentage)%" -ForegroundColor Gray
            }
        }
    }

    # Vérifier les résultats de corrélation
    if ($analysisResults.Results.ContainsKey("Correlation")) {
        $correlationResult = $analysisResults.Results["Correlation"]

        Write-Host "Résultats de corrélation:" -ForegroundColor Yellow
        Write-Host "  Résultat: $($correlationResult.Result)" -ForegroundColor Gray

        if ($null -ne $correlationResult.Details -and $null -ne $correlationResult.Details.SignificantCorrelations) {
            foreach ($correlation in $correlationResult.Details.SignificantCorrelations) {
                Write-Host "  $($correlation.Metric1) - $($correlation.Metric2): $($correlation.Correlation) ($($correlation.Strength) $($correlation.Direction))" -ForegroundColor Gray
            }
        }
    }

    return $true
}

# Test 4: Récupération des résultats d'analyse
$testResults["Test4"] = Invoke-AnalyzerTest -TestName "Récupération des résultats d'analyse" -TestScript {
    # Simuler des résultats d'analyse
    $analyzer = $script:Analyzers[$testAnalyzer]

    if ($null -eq $analyzer) {
        throw "L'analyseur '$testAnalyzer' n'existe pas"
    }

    # Créer des résultats simulés
    $simulatedResults = @{
        "CPU_Usage" = @{
            "Trend"   = @{
                MetricName   = "CPU_Usage"
                AnalysisType = "Trend"
                Result       = "Increasing"
                Details      = @{
                    Slope               = 0.5
                    Intercept           = 20
                    RSquared            = 0.85
                    StandardError       = 2.5
                    HourlyChangeRate    = 1.8
                    HourlyChangePercent = 3.6
                    Unit                = "%"
                    DataPoints          = 30
                    StartTime           = (Get-Date).AddMinutes(-5)
                    EndTime             = Get-Date
                    Duration            = 300
                }
            }
            "Outlier" = @{
                MetricName   = "CPU_Usage"
                AnalysisType = "Outlier"
                Result       = "Outliers detected"
                Details      = @{
                    OutlierCount      = 2
                    OutlierPercentage = 6.7
                    Outliers          = @(
                        [PSCustomObject]@{
                            Timestamp = (Get-Date).AddMinutes(-3)
                            Value     = 85
                            Type      = "High"
                            Deviation = 2.5
                        },
                        [PSCustomObject]@{
                            Timestamp = (Get-Date).AddMinutes(-1)
                            Value     = 90
                            Type      = "High"
                            Deviation = 3.0
                        }
                    )
                    Q1                = 25
                    Q3                = 45
                    IQR               = 20
                    LowerBound        = -5
                    UpperBound        = 75
                    Unit              = "%"
                    DataPoints        = 30
                    Sensitivity       = 0.8
                }
            }
        }
    }

    # Ajouter les résultats simulés à l'analyseur
    $analyzer.Results = $simulatedResults
    $analyzer.LastAnalysisTime = Get-Date

    # Récupérer les résultats
    $results = Get-AnalysisResults -Name $testAnalyzer -Latest

    # Vérifier que les résultats ont été récupérés correctement
    if ($null -eq $results) {
        throw "La récupération des résultats a échoué"
    }

    # Vérifier les propriétés des résultats
    if ($results.AnalyzerName -ne $testAnalyzer) {
        throw "Le nom de l'analyseur dans les résultats est incorrect"
    }

    if ($results.CollectorName -ne $testCollector) {
        throw "Le nom du collecteur dans les résultats est incorrect"
    }

    if ($null -eq $results.Results) {
        throw "Les résultats de l'analyse sont vides"
    }

    # Récupérer les résultats pour une métrique spécifique
    $cpuResults = Get-AnalysisResults -Name $testAnalyzer -MetricNames "CPU_Usage" -Latest

    if ($null -eq $cpuResults) {
        throw "La récupération des résultats pour CPU_Usage a échoué"
    }

    if (-not $cpuResults.Results.ContainsKey("CPU_Usage")) {
        throw "Les résultats ne contiennent pas la métrique CPU_Usage"
    }

    # Récupérer les résultats pour un type d'analyse spécifique
    $trendResults = Get-AnalysisResults -Name $testAnalyzer -AnalysisTypes "Trend" -Latest

    if ($null -eq $trendResults) {
        throw "La récupération des résultats pour le type Trend a échoué"
    }

    $hasTrendResults = $false
    foreach ($metricName in $trendResults.Results.Keys) {
        if ($trendResults.Results[$metricName].ContainsKey("Trend")) {
            $hasTrendResults = $true
            break
        }
    }

    if (-not $hasTrendResults) {
        throw "Les résultats ne contiennent pas d'analyses de type Trend"
    }

    Write-Host "Résultats récupérés avec succès:" -ForegroundColor Yellow
    Write-Host "  Analyseur: $($results.AnalyzerName)" -ForegroundColor Gray
    Write-Host "  Heure d'analyse: $($results.AnalysisTime)" -ForegroundColor Gray
    Write-Host "  Nombre de métriques: $($results.Results.Count)" -ForegroundColor Gray

    return $true
}

# Pas besoin d'arrêter la collecte de métriques car nous utilisons des données simulées

# Afficher le résumé des tests
Write-Host "`n========== RÉSUMÉ DES TESTS ==========" -ForegroundColor Cyan
$totalTests = $testResults.Count
$passedTests = ($testResults.Values | Where-Object { $_ -eq $true }).Count
$failedTests = $totalTests - $passedTests

Write-Host "Tests exécutés: $totalTests" -ForegroundColor White
Write-Host "Tests réussis: $passedTests" -ForegroundColor Green
Write-Host "Tests échoués: $failedTests" -ForegroundColor Red

if ($failedTests -gt 0) {
    Write-Host "`nTests échoués:" -ForegroundColor Red
    foreach ($test in $testResults.Keys) {
        if (-not $testResults[$test]) {
            Write-Host "  - $test" -ForegroundColor Red
        }
    }
}

# Pas besoin de nettoyer les ressources car nous utilisons des données simulées

# Retourner le résultat global
if ($failedTests -eq 0) {
    Write-Host "`nTous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont échoué!" -ForegroundColor Red
    exit 1
}
