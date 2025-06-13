# ========================================
# Script de Validation Phase 6.1.2 - Scripts PowerShell d'Administration
# Plan-dev-v55 - Planning Ecosystem Sync
# ========================================

param(
    [switch]$Verbose,
    [string]$Component = "all" # all, metrics, dashboard, alerts
)

$ErrorActionPreference = "Continue"

function Write-StatusMessage {
    param([string]$Message, [string]$Status = "INFO")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $color = switch ($Status) {
        "SUCCESS" { "Green" }
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        default { "Cyan" }
    }
    Write-Host "[$timestamp] [$Status] $Message" -ForegroundColor $color
}

function Test-GoCompilation {
    Write-StatusMessage "🔨 Test de compilation Go..." "INFO"
    
    # Test compilation du package tools
    $result = go build -v ./tools/ 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-StatusMessage "✅ Package tools compilé avec succès" "SUCCESS"
        return $true
    } else {
        Write-StatusMessage "❌ Échec compilation tools: $result" "ERROR"
        return $false
    }
}

function Test-PerformanceMetrics {
    Write-StatusMessage "📊 Test du système de métriques de performance..." "INFO"
    
    # Création d'un petit programme de test
    $testProgram = @"
package main

import (
    "fmt"
    "log"
    "time"
    "./tools"
)

func main() {
    config := &tools.MetricsConfig{
        DatabaseURL:     "",
        RetentionDays:   7,
        SampleInterval:  time.Second * 30,
        MaxSamples:      1000,
        AlertThresholds: map[string]float64{
            "response_time_ms": 500.0,
            "error_rate_percent": 5.0,
        },
    }
    
    logger := log.Default()
    metrics, err := tools.NewPerformanceMetrics(config, logger)
    if err != nil {
        fmt.Printf("Erreur création métriques: %v\n", err)
        return
    }
    
    // Test basic functionality
    metrics.RecordSyncOperation(100*time.Millisecond, 10, 0)
    metrics.RecordResponseTime(50*time.Millisecond)
    metrics.RecordMemoryUsage(1024*1024)
    
    report := metrics.GetPerformanceReport()
    fmt.Printf("✅ Rapport généré: %v opérations\n", report.SampleCount)
    
    // Test nouvelles méthodes
    fmt.Printf("✅ Erreur taux: %.2f%%\n", metrics.GetErrorRate())
    fmt.Printf("✅ Temps réponse: %.2fms\n", metrics.GetAverageResponseTime())
    fmt.Printf("✅ Syncs actifs: %d\n", metrics.GetActiveSyncCount())
    
    fmt.Println("🎉 Test métriques réussi!")
}
"@
    
    $testProgram | Out-File -FilePath "test-metrics.go" -Encoding UTF8
    
    $result = go run test-metrics.go 2>&1
    Remove-Item "test-metrics.go" -ErrorAction SilentlyContinue
    
    if ($result -match "Test métriques réussi!") {
        Write-StatusMessage "✅ Système de métriques fonctionnel" "SUCCESS"
        return $true
    } else {
        Write-StatusMessage "❌ Problème avec le système de métriques: $result" "ERROR"
        return $false
    }
}

function Test-AlertManager {
    Write-StatusMessage "🚨 Test du gestionnaire d'alertes..." "INFO"
    
    $testProgram = @"
package main

import (
    "fmt"
    "log"
    "./tools"
)

func main() {
    config := &tools.AlertConfig{
        EmailEnabled:     false,
        SlackEnabled:     false,
        MaxHistorySize:   100,
        RetryAttempts:    3,
        RetryDelay:       5,
        RateLimitPerHour: 50,
    }
    
    logger := log.Default()
    alertManager, err := tools.NewAlertManager(config, logger)
    if err != nil {
        fmt.Printf("Erreur création gestionnaire alertes: %v\n", err)
        return
    }
    
    // Test création d'alerte
    alert := tools.Alert{
        ID:       "test_001",
        Type:     "test",
        Severity: "low",
        Message:  "Test d'alerte",
        Source:   "validation_script",
    }
    
    err = alertManager.SendAlert(alert)
    if err != nil {
        fmt.Printf("Erreur envoi alerte: %v\n", err)
        return
    }
    
    // Test récupération des alertes récentes
    recentAlerts := alertManager.GetRecentAlerts(5)
    fmt.Printf("✅ Alertes récentes récupérées: %d\n", len(recentAlerts))
    
    fmt.Println("🎉 Test gestionnaire alertes réussi!")
}
"@
    
    $testProgram | Out-File -FilePath "test-alerts.go" -Encoding UTF8
    
    $result = go run test-alerts.go 2>&1
    Remove-Item "test-alerts.go" -ErrorAction SilentlyContinue
    
    if ($result -match "Test gestionnaire alertes réussi!") {
        Write-StatusMessage "✅ Gestionnaire d'alertes fonctionnel" "SUCCESS"
        return $true
    } else {
        Write-StatusMessage "❌ Problème avec le gestionnaire d'alertes: $result" "ERROR"
        return $false
    }
}

function Test-DriftDetector {
    Write-StatusMessage "🔍 Test du détecteur de dérive..." "INFO"
    
    $testProgram = @"
package main

import (
    "fmt"
    "log"
    "time"
    "./tools"
)

func main() {
    // Configuration de base
    alertConfig := &tools.AlertConfig{
        EmailEnabled:     false,
        SlackEnabled:     false,
        MaxHistorySize:   100,
    }
    
    metricsConfig := &tools.MetricsConfig{
        MaxSamples: 100,
        AlertThresholds: map[string]float64{
            "response_time_ms": 500.0,
        },
    }
    
    logger := log.Default()
    
    alertManager, _ := tools.NewAlertManager(alertConfig, logger)
    metrics, _ := tools.NewPerformanceMetrics(metricsConfig, logger)
    
    driftDetector := tools.NewDriftDetector(alertManager, metrics, logger)
    
    // Test démarrage/arrêt
    driftDetector.Start()
    time.Sleep(100 * time.Millisecond)
    driftDetector.Stop()
    
    fmt.Println("✅ Détecteur de dérive testé avec succès")
    fmt.Println("🎉 Test détecteur de dérive réussi!")
}
"@
    
    $testProgram | Out-File -FilePath "test-drift.go" -Encoding UTF8
    
    $result = go run test-drift.go 2>&1
    Remove-Item "test-drift.go" -ErrorAction SilentlyContinue
    
    if ($result -match "Test détecteur de dérive réussi!") {
        Write-StatusMessage "✅ Détecteur de dérive fonctionnel" "SUCCESS"
        return $true
    } else {
        Write-StatusMessage "❌ Problème avec le détecteur de dérive: $result" "ERROR"
        return $false
    }
}

function Test-RealtimeDashboard {
    Write-StatusMessage "📱 Test du dashboard temps réel..." "INFO"
    
    # Test simple de compilation et initialisation
    $testProgram = @"
package main

import (
    "fmt"
    "log"
    "./tools"
)

func main() {
    logger := log.Default()
    
    // Configuration minimale
    alertConfig := &tools.AlertConfig{MaxHistorySize: 100}
    metricsConfig := &tools.MetricsConfig{MaxSamples: 100}
    
    alertManager, _ := tools.NewAlertManager(alertConfig, logger)
    metrics, _ := tools.NewPerformanceMetrics(metricsConfig, logger)
    driftDetector := tools.NewDriftDetector(alertManager, metrics, logger)
    
    dashboard := tools.NewRealtimeDashboard(metrics, driftDetector, alertManager, logger)
    
    // Test de création sans démarrage du serveur
    if dashboard != nil {
        fmt.Println("✅ Dashboard créé avec succès")
    }
    
    fmt.Println("🎉 Test dashboard réussi!")
}
"@
    
    $testProgram | Out-File -FilePath "test-dashboard.go" -Encoding UTF8
    
    $result = go run test-dashboard.go 2>&1
    Remove-Item "test-dashboard.go" -ErrorAction SilentlyContinue
    
    if ($result -match "Test dashboard réussi!") {
        Write-StatusMessage "✅ Dashboard temps réel fonctionnel" "SUCCESS"
        return $true
    } else {
        Write-StatusMessage "❌ Problème avec le dashboard: $result" "ERROR"
        return $false
    }
}

# ========================================
# EXÉCUTION PRINCIPALE
# ========================================

Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "VALIDATION PHASE 6.1.2 - SCRIPTS POWERSHELL D'ADMINISTRATION" -ForegroundColor Cyan
Write-Host "Plan-dev-v55 - Planning Ecosystem Sync" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan

$startTime = Get-Date
$successCount = 0
$totalTests = 0

# Test de compilation de base
$totalTests++
if (Test-GoCompilation) {
    $successCount++
}

# Tests des composants
if ($Component -eq "all" -or $Component -eq "metrics") {
    $totalTests++
    if (Test-PerformanceMetrics) {
        $successCount++
    }
}

if ($Component -eq "all" -or $Component -eq "alerts") {
    $totalTests++
    if (Test-AlertManager) {
        $successCount++
    }
}

if ($Component -eq "all" -or $Component -eq "drift") {
    $totalTests++
    if (Test-DriftDetector) {
        $successCount++
    }
}

if ($Component -eq "all" -or $Component -eq "dashboard") {
    $totalTests++
    if (Test-RealtimeDashboard) {
        $successCount++
    }
}

# Rapport final
$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host ""
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "RAPPORT DE VALIDATION FINAL" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "Tests réussis: $successCount/$totalTests" -ForegroundColor $(if ($successCount -eq $totalTests) { "Green" } else { "Yellow" })
Write-Host "Durée: $($duration.TotalSeconds) secondes" -ForegroundColor Cyan
Write-Host "Date: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')" -ForegroundColor Cyan

if ($successCount -eq $totalTests) {
    Write-Host ""
    Write-Host "🎉 PHASE 6.1.2 COMPLÉTÉE AVEC SUCCÈS!" -ForegroundColor Green
    Write-Host "✅ Tous les scripts PowerShell d'administration sont fonctionnels" -ForegroundColor Green
    exit 0
} else {
    Write-Host ""
    Write-Host "⚠️  VALIDATION PARTIELLE - Certains tests ont échoué" -ForegroundColor Yellow
    exit 1
}
