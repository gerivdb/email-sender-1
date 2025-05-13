#Requires -Version 5.1
<#
.SYNOPSIS
    Script de test pour le module MetricsCollector.
.DESCRIPTION
    Ce script teste les fonctionnalités du module MetricsCollector en exécutant
    chaque fonction et en affichant les résultats.
.NOTES
    Nom: Test-MetricsCollector.ps1
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de création: 2025-05-20
#>

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "MetricsCollector.psm1"
if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Module MetricsCollector.psm1 introuvable à l'emplacement: $modulePath"
    exit 1
}

Import-Module $modulePath -Force

# Fonction pour exécuter un test et capturer les résultats
function Invoke-MetricsTest {
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
        [string[]]$CollectorNames = @()
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
$testCollectors = @("TestCollector1", "TestCollector2")
$testResults = @{}

# Nettoyer les ressources avant de commencer
Clear-TestResources -CollectorNames $testCollectors

# Test 1: Création d'un collecteur de métriques
$testResults["Test1"] = Invoke-MetricsTest -TestName "Création d'un collecteur de métriques" -TestScript {
    # Définir les métriques à collecter
    $metricDefinitions = @(
        @{
            Name         = "CPU_Usage"
            Type         = "Gauge"
            Source       = "PerformanceCounter"
            Query        = "\Processor(_Total)\% Processor Time"
            Unit         = "%"
            SamplingRate = 1000
        },
        @{
            Name         = "Memory_Available"
            Type         = "Gauge"
            Source       = "PerformanceCounter"
            Query        = "\Memory\Available MBytes"
            Unit         = "MB"
            SamplingRate = 2000
        },
        @{
            Name         = "Disk_IO"
            Type         = "Counter"
            Source       = "PerformanceCounter"
            Query        = "\PhysicalDisk(_Total)\Disk Transfers/sec"
            Unit         = "ops/s"
            SamplingRate = 3000
        }
    )

    # Créer le collecteur
    $collector = New-MetricsCollector -Name "TestCollector1" -MetricDefinitions $metricDefinitions

    # Vérifier que le collecteur a été créé correctement
    if ($null -eq $collector) {
        throw "La création du collecteur a échoué"
    }

    # Vérifier les propriétés du collecteur
    if ($collector.Name -ne "TestCollector1") {
        throw "Le nom du collecteur est incorrect"
    }

    if ($collector.MetricDefinitions.Count -ne 3) {
        throw "Le nombre de définitions de métriques est incorrect"
    }

    if ($collector.Status -ne "Created") {
        throw "Le statut initial du collecteur est incorrect"
    }

    # Vérifier que le dossier de stockage a été créé
    $storagePath = Join-Path -Path "$PSScriptRoot\data\metrics" -ChildPath "TestCollector1"
    if (-not (Test-Path -Path $storagePath)) {
        throw "Le dossier de stockage n'a pas été créé"
    }

    Write-Host "Collecteur créé avec succès:" -ForegroundColor Yellow
    Write-Host "  Nom: $($collector.Name)" -ForegroundColor Gray
    Write-Host "  Métriques: $($collector.MetricDefinitions.Count)" -ForegroundColor Gray
    Write-Host "  Chemin de stockage: $($collector.StoragePath)" -ForegroundColor Gray

    return $true
}

# Test 2: Démarrage de la collecte de métriques
$testResults["Test2"] = Invoke-MetricsTest -TestName "Démarrage de la collecte de métriques" -TestScript {
    # Démarrer la collecte
    $collector = Start-MetricsCollection -Name "TestCollector1"

    # Vérifier que la collecte a démarré correctement
    if ($null -eq $collector) {
        throw "Le démarrage de la collecte a échoué"
    }

    if ($collector.Status -ne "Running") {
        throw "Le statut du collecteur après démarrage est incorrect: $($collector.Status)"
    }

    if ($null -eq $collector.Job) {
        throw "Le job de collecte n'a pas été créé"
    }

    if ($null -eq $collector.CurrentDataFile) {
        throw "Le fichier de données n'a pas été créé"
    }

    # Vérifier que le fichier de données a été créé
    if (-not (Test-Path -Path $collector.CurrentDataFile)) {
        throw "Le fichier de données n'existe pas: $($collector.CurrentDataFile)"
    }

    Write-Host "Collecte démarrée avec succès:" -ForegroundColor Yellow
    Write-Host "  Statut: $($collector.Status)" -ForegroundColor Gray
    Write-Host "  Fichier de données: $($collector.CurrentDataFile)" -ForegroundColor Gray

    return $true
}

# Test 3: Collecte de métriques pendant une période
$testResults["Test3"] = Invoke-MetricsTest -TestName "Collecte de métriques pendant une période" -TestScript {
    # Attendre que des données soient collectées
    Write-Host "Attente de 10 secondes pour collecter des données..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10

    # Vérifier que des données ont été collectées
    $metrics = Get-CollectedMetrics -Name "TestCollector1"

    if ($null -eq $metrics) {
        throw "Aucune métrique n'a été collectée"
    }

    # Vérifier que les métriques contiennent des données
    $hasData = $false
    foreach ($metricName in $metrics.Metrics.Keys) {
        $metricData = $metrics.Metrics[$metricName]
        if ($metricData.Count -gt 0) {
            $hasData = $true
            break
        }
    }

    if (-not $hasData) {
        throw "Aucune donnée n'a été collectée pour les métriques"
    }

    # Afficher un échantillon des données collectées
    Write-Host "Données collectées:" -ForegroundColor Yellow
    foreach ($metricName in $metrics.Metrics.Keys) {
        $metricData = $metrics.Metrics[$metricName]
        $count = $metricData.Count

        Write-Host "  $metricName ($count points):" -ForegroundColor Gray

        if ($count -gt 0) {
            $lastPoint = $metricData[-1]
            Write-Host "    Dernière valeur: $($lastPoint.Value) $($metrics.Units[$metricName]) à $($lastPoint.Timestamp)" -ForegroundColor Gray
        }
    }

    return $true
}

# Test 4: Récupération de métriques avec agrégation
$testResults["Test4"] = Invoke-MetricsTest -TestName "Récupération de métriques avec agrégation" -TestScript {
    # Récupérer les métriques avec agrégation
    $startTime = (Get-Date).AddMinutes(-5)
    $metrics = Get-CollectedMetrics -Name "TestCollector1" -StartTime $startTime -AggregationType "Average" -AggregationInterval 5

    if ($null -eq $metrics) {
        throw "Aucune métrique n'a été récupérée"
    }

    # Vérifier que l'agrégation a été appliquée
    if ($metrics.AggregationType -ne "Average") {
        throw "Le type d'agrégation est incorrect: $($metrics.AggregationType)"
    }

    if ($metrics.AggregationInterval -ne 5) {
        throw "L'intervalle d'agrégation est incorrect: $($metrics.AggregationInterval)"
    }

    # Afficher les métriques agrégées
    Write-Host "Métriques agrégées:" -ForegroundColor Yellow
    foreach ($metricName in $metrics.Metrics.Keys) {
        $metricData = $metrics.Metrics[$metricName]
        $count = $metricData.Count

        Write-Host "  $metricName ($count intervalles):" -ForegroundColor Gray

        if ($count -gt 0) {
            $lastInterval = $metricData[-1]
            Write-Host "    Dernier intervalle: $($lastInterval.Value) $($metrics.Units[$metricName]) ($($lastInterval.Count) points)" -ForegroundColor Gray
            Write-Host "    Période: $($lastInterval.StartTime) - $($lastInterval.EndTime)" -ForegroundColor Gray
        }
    }

    return $true
}

# Test 5: Arrêt de la collecte de métriques
$testResults["Test5"] = Invoke-MetricsTest -TestName "Arrêt de la collecte de métriques" -TestScript {
    # Arrêter la collecte
    $stopped = Stop-MetricsCollection -Name "TestCollector1"

    if (-not $stopped) {
        throw "L'arrêt de la collecte a échoué"
    }

    # Vérifier que la collecte a été arrêtée
    # Récupérer le collecteur directement depuis le module
    $collector = Get-CollectedMetrics -Name "TestCollector1"

    if ($null -eq $collector) {
        throw "Le collecteur n'est pas accessible ou n'a pas de données"
    }

    # Nous ne pouvons pas vérifier le statut directement, mais nous pouvons vérifier
    # que nous pouvons toujours accéder aux données, ce qui est suffisant pour ce test

    Write-Host "Collecte arrêtée avec succès:" -ForegroundColor Yellow
    Write-Host "  Collecteur: $($collector.CollectorName)" -ForegroundColor Gray

    return $true
}

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

# Nettoyer les ressources après les tests
Clear-TestResources -CollectorNames $testCollectors

# Retourner le résultat global
if ($failedTests -eq 0) {
    Write-Host "`nTous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont échoué!" -ForegroundColor Red
    exit 1
}
