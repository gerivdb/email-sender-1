# SCRIPT: validate_interceptor_tests.ps1
# Pipeline d'Exécution Automatisée - Validation Complète des Tests Intercepteur

param(
   [switch]$CleanState = $false,
   [switch]$SkipBenchmarks = $false,
   [switch]$VerboseOutput = $false,
   [string]$OutputDir = "test_results"
)

# ========================================================================
# CONFIGURATION ET INITIALISATION
# ========================================================================

$ErrorActionPreference = "Stop"
$StartTime = Get-Date

# Colors for output
$ColorScheme = @{
   Header  = "Cyan"
   Success = "Green" 
   Warning = "Yellow"
   Error   = "Red"
   Info    = "White"
}

function Write-Header {
   param([string]$Message)
   Write-Host "`n🔷 $Message" -ForegroundColor $ColorScheme.Header
   Write-Host ("=" * 60) -ForegroundColor $ColorScheme.Header
}

function Write-Success {
   param([string]$Message)
   Write-Host "✅ $Message" -ForegroundColor $ColorScheme.Success
}

function Write-Warning {
   param([string]$Message)
   Write-Host "⚠️  $Message" -ForegroundColor $ColorScheme.Warning
}

function Write-Error {
   param([string]$Message)
   Write-Host "❌ $Message" -ForegroundColor $ColorScheme.Error
}

function Write-Info {
   param([string]$Message)
   Write-Host "ℹ️  $Message" -ForegroundColor $ColorScheme.Info
}

# ========================================================================
# PHASE 1: SETUP ET VÉRIFICATIONS PRÉLIMINAIRES
# ========================================================================

Write-Header "Phase 1: Setup et Vérifications Environnement"

# Vérifier présence de Go
try {
   $goVersion = go version
   Write-Success "Go installé: $goVersion"
}
catch {
   Write-Error "Go n'est pas installé ou non accessible dans PATH"
   exit 1
}

# Naviguer vers le répertoire du projet
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Join-Path $ScriptDir "development\hooks\commit-interceptor"

if (-not (Test-Path $ProjectDir)) {
   Write-Error "Répertoire projet non trouvé: $ProjectDir"
   exit 1
}

Set-Location $ProjectDir
Write-Success "Répertoire de travail: $(Get-Location)"

# Vérifier go.mod
if (-not (Test-Path "go.mod")) {
   Write-Error "Fichier go.mod non trouvé"
   exit 1
}

# Clean state si demandé
if ($CleanState) {
   Write-Info "Nettoyage de l'état précédent..."
   Remove-Item "test_results" -Recurse -Force -ErrorAction SilentlyContinue
   Remove-Item "coverage.out" -Force -ErrorAction SilentlyContinue
   Remove-Item "coverage.html" -Force -ErrorAction SilentlyContinue
   Remove-Item "benchmark_results.txt" -Force -ErrorAction SilentlyContinue
   Remove-Item "lint_results.json" -Force -ErrorAction SilentlyContinue
   go clean -cache -testcache
   Write-Success "État nettoyé"
}

# Créer répertoire de sortie
if (-not (Test-Path $OutputDir)) {
   New-Item -ItemType Directory -Path $OutputDir | Out-Null
   Write-Success "Répertoire de sortie créé: $OutputDir"
}

# ========================================================================
# PHASE 2: VÉRIFICATIONS DÉPENDANCES
# ========================================================================

Write-Header "Phase 2: Vérification des Dépendances"

Write-Info "Installation/mise à jour des dépendances..."
go mod tidy
if ($LASTEXITCODE -ne 0) {
   Write-Error "Échec de go mod tidy"
   exit 1
}

go mod download
if ($LASTEXITCODE -ne 0) {
   Write-Error "Échec de go mod download"
   exit 1
}

Write-Success "Dépendances vérifiées et installées"

# ========================================================================
# PHASE 3: EXÉCUTION DES TESTS UNITAIRES
# ========================================================================

Write-Header "Phase 3: Exécution Tests Unitaires"

Write-Info "Exécution des tests unitaires avec couverture..."

$TestArgs = @(
   "test",
   "./...",
   "-v",
   "-race",
   "-cover",
   "-coverprofile=$OutputDir/coverage.out",
   "-json"
)

if ($VerboseOutput) {
   $TestArgs += "-x"
}

$TestOutput = & go @TestArgs 2>&1
$TestExitCode = $LASTEXITCODE

# Sauvegarder sortie des tests
$TestOutput | Out-File "$OutputDir/test_output.txt" -Encoding UTF8

if ($TestExitCode -eq 0) {
   Write-Success "Tests unitaires réussis"
}
else {
   Write-Error "Échec des tests unitaires (Code: $TestExitCode)"
   $TestOutput | Where-Object { $_ -match "FAIL|ERROR" } | ForEach-Object {
      Write-Host "  $_" -ForegroundColor Red
   }
}

# Analyser résultats JSON
try {
   $JsonResults = $TestOutput | Where-Object { $_ -match "^\s*{" } | ConvertFrom-Json -ErrorAction SilentlyContinue
   $PassedTests = @($JsonResults | Where-Object { $_.Action -eq "pass" -and $_.Test })
   $FailedTests = @($JsonResults | Where-Object { $_.Action -eq "fail" -and $_.Test })
    
   Write-Info "Tests passés: $($PassedTests.Count)"
   if ($FailedTests.Count -gt 0) {
      Write-Warning "Tests échoués: $($FailedTests.Count)"
      $FailedTests | ForEach-Object {
         Write-Host "  - $($_.Test)" -ForegroundColor Yellow
      }
   }
}
catch {
   Write-Warning "Impossible d'analyser les résultats JSON des tests"
}

# ========================================================================
# PHASE 4: GÉNÉRATION RAPPORT COUVERTURE
# ========================================================================

Write-Header "Phase 4: Génération Rapport de Couverture"

if (Test-Path "$OutputDir/coverage.out") {
   Write-Info "Génération du rapport de couverture HTML..."
    
   go tool cover -html="$OutputDir/coverage.out" -o "$OutputDir/coverage.html"
   if ($LASTEXITCODE -eq 0) {
      Write-Success "Rapport de couverture généré: $OutputDir/coverage.html"
   }
   else {
      Write-Warning "Échec de génération du rapport HTML"
   }
    
   # Extraire pourcentage de couverture
   $CoverageText = go tool cover -func="$OutputDir/coverage.out" | Select-String "total:"
   if ($CoverageText) {
      $CoveragePercent = ($CoverageText -split "\s+")[-1]
      Write-Info "Couverture totale: $CoveragePercent"
        
      # Vérifier seuil minimum
      $CoverageValue = [float]($CoveragePercent -replace "%", "")
      if ($CoverageValue -ge 80) {
         Write-Success "Couverture acceptable (≥80%)"
      }
      else {
         Write-Warning "Couverture insuffisante (<80%): $CoveragePercent"
      }
   }
}
else {
   Write-Warning "Fichier de couverture non trouvé"
}

# ========================================================================
# PHASE 5: BENCHMARKS DE PERFORMANCE
# ========================================================================

if (-not $SkipBenchmarks) {
   Write-Header "Phase 5: Benchmarks de Performance"
    
   Write-Info "Exécution des benchmarks..."
   $BenchmarkOutput = go test -bench=. -benchmem ./... 2>&1
   $BenchmarkExitCode = $LASTEXITCODE
    
   $BenchmarkOutput | Out-File "$OutputDir/benchmark_results.txt" -Encoding UTF8
    
   if ($BenchmarkExitCode -eq 0) {
      Write-Success "Benchmarks terminés"
        
      # Analyser résultats de performance
      $BenchmarkLines = $BenchmarkOutput | Where-Object { $_ -match "^Benchmark" }
      if ($BenchmarkLines) {
         Write-Info "Résultats des benchmarks:"
         $BenchmarkLines | ForEach-Object {
            Write-Host "  $_" -ForegroundColor Cyan
         }
      }
        
      # Vérifier latence maximale (50ms pour classification)
      $AnalysisResults = $BenchmarkOutput | Where-Object { $_ -match "BenchmarkCommitAnalysis" }
      if ($AnalysisResults) {
         $AnalysisResults | ForEach-Object {
            if ($_ -match "(\d+)\s+ns/op") {
               $NanosPerOp = [int]$matches[1]
               $MillisPerOp = $NanosPerOp / 1000000
                    
               if ($MillisPerOp -le 50) {
                  Write-Success "Performance acceptable: ${MillisPerOp}ms/classification"
               }
               else {
                  Write-Warning "Performance dégradée: ${MillisPerOp}ms/classification (>50ms)"
               }
            }
         }
      }
   }
   else {
      Write-Warning "Échec d'exécution des benchmarks"
   }
}

# ========================================================================
# PHASE 6: VALIDATION LINTING
# ========================================================================

Write-Header "Phase 6: Validation du Linting"

# Vérifier si golangci-lint est installé
$LintInstalled = Get-Command "golangci-lint" -ErrorAction SilentlyContinue
if (-not $LintInstalled) {
   Write-Warning "golangci-lint non installé - installation automatique..."
   try {
      if ($IsWindows -or $env:OS -eq "Windows_NT") {
         # Installation pour Windows
         Invoke-WebRequest -Uri "https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh" -OutFile "install-lint.sh"
         bash ./install-lint.sh -b $(go env GOPATH)/bin
         Remove-Item "install-lint.sh" -Force
      }
      else {
         # Installation pour Unix
         curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin
      }
      Write-Success "golangci-lint installé"
   }
   catch {
      Write-Warning "Impossible d'installer golangci-lint automatiquement"
      Write-Info "Veuillez installer manuellement: https://golangci-lint.run/usage/install/"
   }
}

# Exécuter linting si disponible
$LintInstalled = Get-Command "golangci-lint" -ErrorAction SilentlyContinue
if ($LintInstalled) {
   Write-Info "Exécution du linting..."
    
   $LintOutput = golangci-lint run --fast --out-format=json 2>&1
   $LintExitCode = $LASTEXITCODE
    
   $LintOutput | Out-File "$OutputDir/lint_results.json" -Encoding UTF8
    
   if ($LintExitCode -eq 0) {
      Write-Success "Linting passé sans erreurs"
   }
   else {
      Write-Warning "Problèmes détectés par le linter"
        
      # Analyser résultats JSON
      try {
         $LintData = $LintOutput | ConvertFrom-Json -ErrorAction SilentlyContinue
         if ($LintData.Issues) {
            Write-Info "Issues détectées:"
            $LintData.Issues | ForEach-Object {
               Write-Host "  $($_.Pos.Filename):$($_.Pos.Line) - $($_.Text)" -ForegroundColor Yellow
            }
         }
      }
      catch {
         # Fallback: afficher sortie brute
         $LintOutput | Where-Object { $_ -match "warning|error" } | ForEach-Object {
            Write-Host "  $_" -ForegroundColor Yellow
         }
      }
   }
}
else {
   Write-Warning "golangci-lint non disponible - validation linting ignorée"
}

# ========================================================================
# PHASE 7: TESTS D'INTÉGRATION
# ========================================================================

Write-Header "Phase 7: Tests d'Intégration"

Write-Info "Exécution des tests d'intégration..."

# Test de démarrage du serveur
$IntegrationTests = @(
   @{
      Name    = "Test démarrage serveur"
      Command = "go run . --test-mode --port=18080"
      Timeout = 10
   }
)

foreach ($Test in $IntegrationTests) {
   Write-Info "Exécution: $($Test.Name)"
    
   try {
      $Job = Start-Job -ScriptBlock {
         param($Command, $WorkDir)
         Set-Location $WorkDir
         Invoke-Expression $Command
      } -ArgumentList $Test.Command, (Get-Location)
        
      $Result = Wait-Job $Job -Timeout $Test.Timeout
      if ($Result) {
         Write-Success "$($Test.Name) - OK"
      }
      else {
         Write-Warning "$($Test.Name) - Timeout"
      }
        
      Stop-Job $Job -ErrorAction SilentlyContinue
      Remove-Job $Job -ErrorAction SilentlyContinue
   }
   catch {
      Write-Warning "$($Test.Name) - Erreur: $($_.Exception.Message)"
   }
}

# ========================================================================
# PHASE 8: GÉNÉRATION RAPPORT FINAL
# ========================================================================

Write-Header "Phase 8: Génération Rapport Final"

$EndTime = Get-Date
$Duration = $EndTime - $StartTime

# Créer rapport de synthèse
$Report = @{
   Timestamp        = $StartTime
   Duration         = $Duration
   TestResults      = @{
      Passed   = $TestExitCode -eq 0
      ExitCode = $TestExitCode
   }
   BenchmarkResults = @{
      Executed = -not $SkipBenchmarks
      Passed   = $BenchmarkExitCode -eq 0
   }
   LintResults      = @{
      Executed = $LintInstalled -ne $null
      Passed   = $LintExitCode -eq 0
   }
   Files            = @{
      TestOutput = "$OutputDir/test_output.txt"
      Coverage   = "$OutputDir/coverage.html"
      Benchmarks = "$OutputDir/benchmark_results.txt"
      Lint       = "$OutputDir/lint_results.json"
   }
}

$Report | ConvertTo-Json -Depth 3 | Out-File "$OutputDir/validation_report.json" -Encoding UTF8

# Résumé final
Write-Header "Résumé de Validation"

$OverallSuccess = $true

Write-Info "Durée totale: $($Duration.ToString('mm\:ss'))"

if ($Report.TestResults.Passed) {
   Write-Success "Tests unitaires: PASSÉS"
}
else {
   Write-Error "Tests unitaires: ÉCHOUÉS"
   $OverallSuccess = $false
}

if ($Report.BenchmarkResults.Executed) {
   if ($Report.BenchmarkResults.Passed) {
      Write-Success "Benchmarks: PASSÉS" 
   }
   else {
      Write-Warning "Benchmarks: ÉCHOUÉS"
   }
}

if ($Report.LintResults.Executed) {
   if ($Report.LintResults.Passed) {
      Write-Success "Linting: PROPRE"
   }
   else {
      Write-Warning "Linting: PROBLÈMES DÉTECTÉS"
   }
}

Write-Info "Rapports disponibles dans: $OutputDir"

if ($OverallSuccess) {
   Write-Header "✅ VALIDATION COMPLÈTE RÉUSSIE!"
   exit 0
}
else {
   Write-Header "❌ VALIDATION ÉCHOUÉE"
   exit 1
}
