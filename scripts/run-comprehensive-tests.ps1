# ========================================
# Script de Tests Complets Phase 7
# Tests et Validation Complète - Plan-dev-v55
# ========================================

param(
    [switch]$All,
    [switch]$Integration,
    [switch]$Performance,
    [switch]$Validation,
    [switch]$Regression,
    [switch]$Coverage,
    [switch]$Verbose,
    [string]$OutputDir = "./test-results",
    [string]$ReportFormat = "html" # html, json, console
)

# Configuration des couleurs
$ErrorColor = "Red"
$WarningColor = "Yellow"
$SuccessColor = "Green"
$InfoColor = "Cyan"

function Write-TestMessage {
    param([string]$Message, [string]$Color = "White")
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $Color
}

function Initialize-TestEnvironment {
    Write-TestMessage "🔧 Initialisation environnement de test..." $InfoColor
    
    # Créer répertoires de sortie
    if (-not (Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
        Write-TestMessage "📁 Créé répertoire de test: $OutputDir" $InfoColor
    }
    
    # Vérifier les prérequis
    $prerequisites = @(
        @{Name = "Go"; Command = "go version"; Description = "Go compiler"}
        @{Name = "Git"; Command = "git --version"; Description = "Git version control"}
    )
    
    foreach ($prereq in $prerequisites) {
        try {
            $null = Invoke-Expression $prereq.Command
            Write-TestMessage "✅ $($prereq.Description) disponible" $SuccessColor
        }
        catch {
            Write-TestMessage "❌ $($prereq.Description) non trouvé" $ErrorColor
            return $false
        }
    }
    
    # Compiler les tests
    Write-TestMessage "🔨 Compilation des tests..." $InfoColor
    try {
        $buildOutput = & go build -v ./tests/... 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-TestMessage "✅ Compilation réussie" $SuccessColor
        } else {
            Write-TestMessage "❌ Échec compilation: $buildOutput" $ErrorColor
            return $false
        }
    }
    catch {
        Write-TestMessage "❌ Erreur compilation: $($_.Exception.Message)" $ErrorColor
        return $false
    }
    
    return $true
}

function Run-IntegrationTests {
    Write-TestMessage "🧪 Exécution des tests d'intégration..." $InfoColor
    
    $testResults = @{
        TotalTests = 0
        PassedTests = 0
        FailedTests = 0
        Duration = [timespan]::Zero
        Results = @()
    }
    
    $startTime = Get-Date
    
    # Tests de synchronisation
    Write-TestMessage "   📄 Tests de synchronisation Markdown ↔ Dynamique..." $InfoColor
    try {
        $syncOutput = & go test -v ./tests -run "TestMarkdownToDynamicSync|TestDynamicToMarkdownSync" 2>&1
        $testResults.Results += @{
            Suite = "Synchronization"
            Output = $syncOutput
            Success = ($LASTEXITCODE -eq 0)
        }
        
        if ($LASTEXITCODE -eq 0) {
            Write-TestMessage "   ✅ Tests de synchronisation passés" $SuccessColor
            $testResults.PassedTests += 2
        } else {
            Write-TestMessage "   ❌ Échec tests de synchronisation" $ErrorColor
            $testResults.FailedTests += 2
        }
        $testResults.TotalTests += 2
    }
    catch {
        Write-TestMessage "   ❌ Erreur tests synchronisation: $($_.Exception.Message)" $ErrorColor
        $testResults.FailedTests += 2
        $testResults.TotalTests += 2
    }
    
    # Tests de gestion des conflits
    Write-TestMessage "   ⚔️ Tests de gestion des conflits..." $InfoColor
    try {
        $conflictOutput = & go test -v ./tests -run "TestConflictHandling" 2>&1
        $testResults.Results += @{
            Suite = "ConflictHandling"
            Output = $conflictOutput
            Success = ($LASTEXITCODE -eq 0)
        }
        
        if ($LASTEXITCODE -eq 0) {
            Write-TestMessage "   ✅ Tests de conflits passés" $SuccessColor
            $testResults.PassedTests += 1
        } else {
            Write-TestMessage "   ❌ Échec tests de conflits" $ErrorColor
            $testResults.FailedTests += 1
        }
        $testResults.TotalTests += 1
    }
    catch {
        Write-TestMessage "   ❌ Erreur tests conflits: $($_.Exception.Message)" $ErrorColor
        $testResults.FailedTests += 1
        $testResults.TotalTests += 1
    }
    
    # Tests de rollback migration
    Write-TestMessage "   🔄 Tests de rollback migration..." $InfoColor
    try {
        $rollbackOutput = & go test -v ./tests -run "TestMigrationRollback" 2>&1
        $testResults.Results += @{
            Suite = "MigrationRollback"
            Output = $rollbackOutput
            Success = ($LASTEXITCODE -eq 0)
        }
        
        if ($LASTEXITCODE -eq 0) {
            Write-TestMessage "   ✅ Tests de rollback passés" $SuccessColor
            $testResults.PassedTests += 1
        } else {
            Write-TestMessage "   ❌ Échec tests de rollback" $ErrorColor
            $testResults.FailedTests += 1
        }
        $testResults.TotalTests += 1
    }
    catch {
        Write-TestMessage "   ❌ Erreur tests rollback: $($_.Exception.Message)" $ErrorColor
        $testResults.FailedTests += 1
        $testResults.TotalTests += 1
    }
    
    $testResults.Duration = (Get-Date) - $startTime
    
    Write-TestMessage "📊 Tests d'intégration terminés: $($testResults.PassedTests)/$($testResults.TotalTests) passés en $($testResults.Duration.TotalSeconds.ToString('F2'))s" $InfoColor
    
    return $testResults
}

function Run-PerformanceTests {
    Write-TestMessage "⚡ Exécution des tests de performance..." $InfoColor
    
    $performanceResults = @{
        TotalTests = 0
        PassedTests = 0
        FailedTests = 0
        Duration = [timespan]::Zero
        Results = @()
        Benchmarks = @()
    }
    
    $startTime = Get-Date
    
    # Test performance synchronisation en lot
    Write-TestMessage "   📦 Test synchronisation 50 plans..." $InfoColor
    try {
        $bulkSyncOutput = & go test -v ./tests -run "TestBulkSynchronizationPerformance" -timeout=60s 2>&1
        $success = ($LASTEXITCODE -eq 0)
        
        $performanceResults.Results += @{
            Test = "BulkSynchronization"
            Output = $bulkSyncOutput
            Success = $success
        }
        
        if ($success) {
            Write-TestMessage "   ✅ Test synchronisation en lot passé" $SuccessColor
            $performanceResults.PassedTests += 1
            
            # Extraire métriques de performance
            if ($bulkSyncOutput -match "(\d+) plans in (\d+\.?\d*)s, ([\d\.]+) ops/s") {
                $performanceResults.Benchmarks += @{
                    Test = "BulkSync"
                    Plans = $matches[1]
                    Duration = [double]$matches[2]
                    Throughput = [double]$matches[3]
                }
            }
        } else {
            Write-TestMessage "   ❌ Échec test synchronisation en lot" $ErrorColor
            $performanceResults.FailedTests += 1
        }
        $performanceResults.TotalTests += 1
    }
    catch {
        Write-TestMessage "   ❌ Erreur test synchronisation: $($_.Exception.Message)" $ErrorColor
        $performanceResults.FailedTests += 1
        $performanceResults.TotalTests += 1
    }
    
    # Test performance validation en lot
    Write-TestMessage "   🔍 Test validation 100 plans..." $InfoColor
    try {
        $bulkValidationOutput = & go test -v ./tests -run "TestBulkValidationPerformance" -timeout=120s 2>&1
        $success = ($LASTEXITCODE -eq 0)
        
        $performanceResults.Results += @{
            Test = "BulkValidation"
            Output = $bulkValidationOutput
            Success = $success
        }
        
        if ($success) {
            Write-TestMessage "   ✅ Test validation en lot passé" $SuccessColor
            $performanceResults.PassedTests += 1
            
            # Extraire métriques de performance
            if ($bulkValidationOutput -match "(\d+) plans in (\d+\.?\d*)s, avg throughput: ([\d\.]+) ops/s") {
                $performanceResults.Benchmarks += @{
                    Test = "BulkValidation"
                    Plans = $matches[1]
                    Duration = [double]$matches[2]
                    Throughput = [double]$matches[3]
                }
            }
        } else {
            Write-TestMessage "   ❌ Échec test validation en lot" $ErrorColor
            $performanceResults.FailedTests += 1
        }
        $performanceResults.TotalTests += 1
    }
    catch {
        Write-TestMessage "   ❌ Erreur test validation: $($_.Exception.Message)" $ErrorColor
        $performanceResults.FailedTests += 1
        $performanceResults.TotalTests += 1
    }
    
    # Test utilisation mémoire
    Write-TestMessage "   💾 Test utilisation mémoire..." $InfoColor
    try {
        $memoryOutput = & go test -v ./tests -run "TestMemoryUsage" 2>&1
        $success = ($LASTEXITCODE -eq 0)
        
        $performanceResults.Results += @{
            Test = "MemoryUsage"
            Output = $memoryOutput
            Success = $success
        }
        
        if ($success) {
            Write-TestMessage "   ✅ Test mémoire passé" $SuccessColor
            $performanceResults.PassedTests += 1
            
            # Extraire utilisation mémoire
            if ($memoryOutput -match "peak usage (\d+) MB") {
                $performanceResults.Benchmarks += @{
                    Test = "MemoryUsage"
                    PeakMemoryMB = [int]$matches[1]
                }
            }
        } else {
            Write-TestMessage "   ❌ Échec test mémoire" $ErrorColor
            $performanceResults.FailedTests += 1
        }
        $performanceResults.TotalTests += 1
    }
    catch {
        Write-TestMessage "   ❌ Erreur test mémoire: $($_.Exception.Message)" $ErrorColor
        $performanceResults.FailedTests += 1
        $performanceResults.TotalTests += 1
    }
    
    $performanceResults.Duration = (Get-Date) - $startTime
    
    Write-TestMessage "📊 Tests de performance terminés: $($performanceResults.PassedTests)/$($performanceResults.TotalTests) passés en $($performanceResults.Duration.TotalSeconds.ToString('F2'))s" $InfoColor
    
    return $performanceResults
}

function Run-ValidationTests {
    Write-TestMessage "🔍 Exécution des tests de validation..." $InfoColor
    
    $validationResults = @{
        TotalTests = 0
        PassedTests = 0
        FailedTests = 0
        Duration = [timespan]::Zero
        Results = @()
    }
    
    $startTime = Get-Date
    
    # Tests détection divergences
    Write-TestMessage "   🎯 Tests détection divergences..." $InfoColor
    try {
        $divergenceOutput = & go test -v ./tests -run "TestDetectionDivergences" 2>&1
        $success = ($LASTEXITCODE -eq 0)
        
        $validationResults.Results += @{
            Test = "DivergenceDetection"
            Output = $divergenceOutput
            Success = $success
        }
        
        if ($success) {
            Write-TestMessage "   ✅ Tests détection divergences passés" $SuccessColor
            $validationResults.PassedTests += 1
        } else {
            Write-TestMessage "   ❌ Échec tests détection divergences" $ErrorColor
            $validationResults.FailedTests += 1
        }
        $validationResults.TotalTests += 1
    }
    catch {
        Write-TestMessage "   ❌ Erreur tests divergences: $($_.Exception.Message)" $ErrorColor
        $validationResults.FailedTests += 1
        $validationResults.TotalTests += 1
    }
    
    # Tests correction automatique
    Write-TestMessage "   🔧 Tests correction automatique..." $InfoColor
    try {
        $autofixOutput = & go test -v ./tests -run "TestCorrectionAutomatique" 2>&1
        $success = ($LASTEXITCODE -eq 0)
        
        $validationResults.Results += @{
            Test = "AutoCorrection"
            Output = $autofixOutput
            Success = $success
        }
        
        if ($success) {
            Write-TestMessage "   ✅ Tests correction automatique passés" $SuccessColor
            $validationResults.PassedTests += 1
        } else {
            Write-TestMessage "   ❌ Échec tests correction automatique" $ErrorColor
            $validationResults.FailedTests += 1
        }
        $validationResults.TotalTests += 1
    }
    catch {
        Write-TestMessage "   ❌ Erreur tests correction: $($_.Exception.Message)" $ErrorColor
        $validationResults.FailedTests += 1
        $validationResults.TotalTests += 1
    }
    
    $validationResults.Duration = (Get-Date) - $startTime
    
    Write-TestMessage "📊 Tests de validation terminés: $($validationResults.PassedTests)/$($validationResults.TotalTests) passés en $($validationResults.Duration.TotalSeconds.ToString('F2'))s" $InfoColor
    
    return $validationResults
}

function Run-RegressionTests {
    Write-TestMessage "🔄 Exécution des tests de régression..." $InfoColor
    
    $regressionResults = @{
        TotalTests = 0
        PassedTests = 0
        FailedTests = 0
        Duration = [timespan]::Zero
        Results = @()
    }
    
    $startTime = Get-Date
    
    # Tests plans existants
    Write-TestMessage "   📋 Tests plans existants..." $InfoColor
    try {
        $existingPlansOutput = & go test -v ./tests -run "TestPlansExistants" 2>&1
        $success = ($LASTEXITCODE -eq 0)
        
        $regressionResults.Results += @{
            Test = "ExistingPlans"
            Output = $existingPlansOutput
            Success = $success
        }
        
        if ($success) {
            Write-TestMessage "   ✅ Tests plans existants passés" $SuccessColor
            $regressionResults.PassedTests += 1
        } else {
            Write-TestMessage "   ❌ Échec tests plans existants" $ErrorColor
            $regressionResults.FailedTests += 1
        }
        $regressionResults.TotalTests += 1
    }
    catch {
        Write-TestMessage "   ❌ Erreur tests plans existants: $($_.Exception.Message)" $ErrorColor
        $regressionResults.FailedTests += 1
        $regressionResults.TotalTests += 1
    }
    
    # Tests robustesse
    Write-TestMessage "   🛡️ Tests robustesse..." $InfoColor
    try {
        $robustnessOutput = & go test -v ./tests -run "TestRobustesse" 2>&1
        $success = ($LASTEXITCODE -eq 0)
        
        $regressionResults.Results += @{
            Test = "Robustness"
            Output = $robustnessOutput
            Success = $success
        }
        
        if ($success) {
            Write-TestMessage "   ✅ Tests robustesse passés" $SuccessColor
            $regressionResults.PassedTests += 1
        } else {
            Write-TestMessage "   ❌ Échec tests robustesse" $ErrorColor
            $regressionResults.FailedTests += 1
        }
        $regressionResults.TotalTests += 1
    }
    catch {
        Write-TestMessage "   ❌ Erreur tests robustesse: $($_.Exception.Message)" $ErrorColor
        $regressionResults.FailedTests += 1
        $regressionResults.TotalTests += 1
    }
    
    $regressionResults.Duration = (Get-Date) - $startTime
    
    Write-TestMessage "📊 Tests de régression terminés: $($regressionResults.PassedTests)/$($regressionResults.TotalTests) passés en $($regressionResults.Duration.TotalSeconds.ToString('F2'))s" $InfoColor
    
    return $regressionResults
}

function Generate-TestReport {
    param(
        [hashtable]$IntegrationResults,
        [hashtable]$PerformanceResults,
        [hashtable]$ValidationResults,
        [hashtable]$RegressionResults
    )
    
    Write-TestMessage "📄 Génération du rapport de tests..." $InfoColor
    
    $report = @{
        Timestamp = Get-Date
        Summary = @{
            TotalTests = 0
            PassedTests = 0
            FailedTests = 0
            SuccessRate = 0.0
            TotalDuration = [timespan]::Zero
        }
        Integration = $IntegrationResults
        Performance = $PerformanceResults
        Validation = $ValidationResults
        Regression = $RegressionResults
    }
    
    # Calculer résumé global
    $allResults = @($IntegrationResults, $PerformanceResults, $ValidationResults, $RegressionResults)
    foreach ($result in $allResults) {
        if ($result) {
            $report.Summary.TotalTests += $result.TotalTests
            $report.Summary.PassedTests += $result.PassedTests
            $report.Summary.FailedTests += $result.FailedTests
            $report.Summary.TotalDuration = $report.Summary.TotalDuration.Add($result.Duration)
        }
    }
    
    if ($report.Summary.TotalTests -gt 0) {
        $report.Summary.SuccessRate = ($report.Summary.PassedTests / $report.Summary.TotalTests) * 100
    }
    
    # Sauvegarder rapport selon format
    switch ($ReportFormat.ToLower()) {
        "json" {
            $jsonReport = $report | ConvertTo-Json -Depth 10
            $reportPath = Join-Path $OutputDir "test-report.json"
            $jsonReport | Out-File -FilePath $reportPath -Encoding UTF8
            Write-TestMessage "📄 Rapport JSON sauvegardé: $reportPath" $InfoColor
        }
        "html" {
            $htmlReport = Generate-HtmlReport $report
            $reportPath = Join-Path $OutputDir "test-report.html"
            $htmlReport | Out-File -FilePath $reportPath -Encoding UTF8
            Write-TestMessage "📄 Rapport HTML sauvegardé: $reportPath" $InfoColor
        }
        default {
            Write-TestMessage "📊 Rapport de tests - Résumé:" $InfoColor
            Write-TestMessage "   Tests totaux: $($report.Summary.TotalTests)" $InfoColor
            Write-TestMessage "   Tests passés: $($report.Summary.PassedTests)" $SuccessColor
            Write-TestMessage "   Tests échoués: $($report.Summary.FailedTests)" $ErrorColor
            Write-TestMessage "   Taux de réussite: $($report.Summary.SuccessRate.ToString('F1'))%" $InfoColor
            Write-TestMessage "   Durée totale: $($report.Summary.TotalDuration.TotalSeconds.ToString('F2'))s" $InfoColor
        }
    }
    
    return $report
}

function Generate-HtmlReport {
    param([hashtable]$Report)
    
    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de Tests - Phase 7</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .header { text-align: center; margin-bottom: 30px; }
        .summary { background: #e3f2fd; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
        .test-section { margin-bottom: 30px; }
        .test-section h3 { color: #1976d2; border-bottom: 2px solid #1976d2; padding-bottom: 5px; }
        .success { color: #4caf50; }
        .error { color: #f44336; }
        .metric { display: inline-block; margin: 10px; padding: 10px; background: #f0f0f0; border-radius: 4px; }
        .progress-bar { width: 100%; height: 20px; background: #e0e0e0; border-radius: 10px; overflow: hidden; }
        .progress-fill { height: 100%; background: linear-gradient(90deg, #4caf50, #8bc34a); }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🧪 Rapport de Tests Phase 7</h1>
            <p>Générée le $($Report.Timestamp.ToString('dd/MM/yyyy à HH:mm:ss'))</p>
        </div>
        
        <div class="summary">
            <h2>📊 Résumé Global</h2>
            <div class="metric">
                <strong>Tests Totaux:</strong> $($Report.Summary.TotalTests)
            </div>
            <div class="metric success">
                <strong>Tests Passés:</strong> $($Report.Summary.PassedTests)
            </div>
            <div class="metric error">
                <strong>Tests Échoués:</strong> $($Report.Summary.FailedTests)
            </div>
            <div class="metric">
                <strong>Taux de Réussite:</strong> $($Report.Summary.SuccessRate.ToString('F1'))%
            </div>
            <div class="metric">
                <strong>Durée Totale:</strong> $($Report.Summary.TotalDuration.TotalSeconds.ToString('F2'))s
            </div>
            
            <div class="progress-bar">
                <div class="progress-fill" style="width: $($Report.Summary.SuccessRate)%"></div>
            </div>
        </div>
        
        <div class="test-section">
            <h3>🧪 Tests d'Intégration</h3>
            <p><strong>Résultat:</strong> $($Report.Integration.PassedTests)/$($Report.Integration.TotalTests) passés</p>
            <p><strong>Durée:</strong> $($Report.Integration.Duration.TotalSeconds.ToString('F2'))s</p>
        </div>
        
        <div class="test-section">
            <h3>⚡ Tests de Performance</h3>
            <p><strong>Résultat:</strong> $($Report.Performance.PassedTests)/$($Report.Performance.TotalTests) passés</p>
            <p><strong>Durée:</strong> $($Report.Performance.Duration.TotalSeconds.ToString('F2'))s</p>
        </div>
        
        <div class="test-section">
            <h3>🔍 Tests de Validation</h3>
            <p><strong>Résultat:</strong> $($Report.Validation.PassedTests)/$($Report.Validation.TotalTests) passés</p>
            <p><strong>Durée:</strong> $($Report.Validation.Duration.TotalSeconds.ToString('F2'))s</p>
        </div>
        
        <div class="test-section">
            <h3>🔄 Tests de Régression</h3>
            <p><strong>Résultat:</strong> $($Report.Regression.PassedTests)/$($Report.Regression.TotalTests) passés</p>
            <p><strong>Durée:</strong> $($Report.Regression.Duration.TotalSeconds.ToString('F2'))s</p>
        </div>
    </div>
</body>
</html>
"@
    
    return $html
}

# Script principal
function Main {
    Write-TestMessage "🚀 Lancement Phase 7 - Tests et Validation Complète" $InfoColor
    Write-TestMessage "📅 $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')" $InfoColor
    
    # Initialisation
    if (-not (Initialize-TestEnvironment)) {
        Write-TestMessage "❌ Échec initialisation environnement" $ErrorColor
        exit 1
    }
    
    # Variables de résultats
    $integrationResults = $null
    $performanceResults = $null
    $validationResults = $null
    $regressionResults = $null
    
    # Exécuter tests selon paramètres
    if ($All -or $Integration) {
        $integrationResults = Run-IntegrationTests
    }
    
    if ($All -or $Performance) {
        $performanceResults = Run-PerformanceTests
    }
    
    if ($All -or $Validation) {
        $validationResults = Run-ValidationTests
    }
    
    if ($All -or $Regression) {
        $regressionResults = Run-RegressionTests
    }
    
    # Si aucun paramètre spécifique, exécuter tous les tests
    if (-not ($Integration -or $Performance -or $Validation -or $Regression)) {
        Write-TestMessage "🎯 Exécution de tous les tests..." $InfoColor
        $integrationResults = Run-IntegrationTests
        $performanceResults = Run-PerformanceTests
        $validationResults = Run-ValidationTests
        $regressionResults = Run-RegressionTests
    }
    
    # Générer rapport
    $report = Generate-TestReport -IntegrationResults $integrationResults -PerformanceResults $performanceResults -ValidationResults $validationResults -RegressionResults $regressionResults
    
    # Résultat final
    if ($report.Summary.SuccessRate -ge 90) {
        Write-TestMessage "🎉 Phase 7 - Tests RÉUSSIS avec succès! ($($report.Summary.SuccessRate.ToString('F1'))% de réussite)" $SuccessColor
        exit 0
    } elseif ($report.Summary.SuccessRate -ge 75) {
        Write-TestMessage "⚠️ Phase 7 - Tests partiellement réussis ($($report.Summary.SuccessRate.ToString('F1'))% de réussite)" $WarningColor
        exit 0
    } else {
        Write-TestMessage "❌ Phase 7 - Échec des tests ($($report.Summary.SuccessRate.ToString('F1'))% de réussite)" $ErrorColor
        exit 1
    }
}

# Exécution
Main
