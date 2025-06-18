# Validation Tâche 023: Créer Structure API REST N8N→Go
# Teste la compilation et la fonctionnalité de base

param(
   [switch]$Verbose
)

$ErrorActionPreference = "Continue"
$StartTime = Get-Date

Write-Host "🧪 VALIDATION TÂCHE 023: Structure API REST N8N→Go" -ForegroundColor Cyan
Write-Host "=" * 60

$Results = @{
   task               = "023-validation"
   timestamp          = $StartTime.ToString("yyyy-MM-dd HH:mm:ss")
   tests_run          = @()
   files_validated    = @()
   compilation_status = "UNKNOWN"
   interface_coverage = @{}
   endpoint_coverage  = @{}
   summary            = @{}
   errors             = @()
}

# Test 1: Vérification fichiers créés
Write-Host "📂 Test 1: Vérification des fichiers créés..." -ForegroundColor Yellow

$requiredFiles = @(
   "pkg/bridge/api/workflow_types.go",
   "pkg/bridge/api/n8n_receiver.go", 
   "pkg/bridge/api/http_receiver.go"
)

$filesOk = 0
foreach ($file in $requiredFiles) {
   if (Test-Path $file) {
      $Results.files_validated += $file
      $filesOk++
      Write-Host "   ✅ $file" -ForegroundColor Green
   }
   else {
      $Results.errors += "Fichier manquant: $file"
      Write-Host "   ❌ $file - MANQUANT" -ForegroundColor Red
   }
}

$Results.tests_run += @{
   name    = "Files Creation Check"
   status  = if ($filesOk -eq $requiredFiles.Count) { "PASS" } else { "FAIL" }
   details = "$filesOk/$($requiredFiles.Count) fichiers présents"
}

# Test 2: Vérification module Go
Write-Host "📦 Test 2: Vérification module Go..." -ForegroundColor Yellow

try {
   if (!(Test-Path "go.mod")) {
      # Créer un go.mod minimal pour les tests
      $goModContent = @"
module email_sender

go 1.21

require (
    github.com/stretchr/testify v1.8.4
)
"@
      $goModContent | Set-Content "go.mod" -Encoding UTF8
      Write-Host "   📝 go.mod créé pour les tests" -ForegroundColor Blue
   }
    
   # Test de compilation
   $compileResult = & go build "./pkg/bridge/api" 2>&1
   if ($LASTEXITCODE -eq 0) {
      $Results.compilation_status = "SUCCESS"
      Write-Host "   ✅ Compilation réussie" -ForegroundColor Green
   }
   else {
      $Results.compilation_status = "FAILED"
      $Results.errors += "Erreur compilation: $compileResult"
      Write-Host "   ❌ Erreur de compilation" -ForegroundColor Red
      Write-Host "   $compileResult" -ForegroundColor Red
   }
}
catch {
   $Results.compilation_status = "ERROR"
   $Results.errors += "Exception compilation: $($_.Exception.Message)"
   Write-Host "   ❌ Exception: $($_.Exception.Message)" -ForegroundColor Red
}

$Results.tests_run += @{
   name    = "Go Compilation"
   status  = if ($Results.compilation_status -eq "SUCCESS") { "PASS" } else { "FAIL" }
   details = $Results.compilation_status
}

# Test 3: Analyse des interfaces
Write-Host "🔌 Test 3: Analyse des interfaces..." -ForegroundColor Yellow

$interfacePatterns = @{
   "N8NReceiver"       = "HandleWorkflow.*GetStatus.*CancelWorkflow.*ListActiveWorkflows.*HealthCheck"
   "HTTPHandler"       = "RegisterRoutes.*HandleWorkflowHTTP.*HandleStatusHTTP.*HandleHealthHTTP"
   "ProcessorFactory"  = "CreateProcessor.*ListAvailableProcessors.*ValidateProcessingType"
   "WorkflowProcessor" = "Process.*CanProcess.*EstimateDuration.*GetCapabilities"
}

foreach ($interface in $interfacePatterns.Keys) {
   $pattern = $interfacePatterns[$interface]
    
   $found = $false
   foreach ($file in $Results.files_validated) {
      if (Test-Path $file) {
         $content = Get-Content $file -Raw
         if ($content -match "type\s+$interface\s+interface" -and $content -match $pattern) {
            $found = $true
            break
         }
      }
   }
    
   $Results.interface_coverage[$interface] = if ($found) { "FOUND" } else { "MISSING" }
    
   if ($found) {
      Write-Host "   ✅ Interface $interface" -ForegroundColor Green
   }
   else {
      Write-Host "   ❌ Interface $interface - MANQUANTE" -ForegroundColor Red
      $Results.errors += "Interface manquante: $interface"
   }
}

$interfacesPassed = ($Results.interface_coverage.Values | Where-Object { $_ -eq "FOUND" }).Count
$interfacesTotal = $Results.interface_coverage.Count

$Results.tests_run += @{
   name    = "Interface Coverage"
   status  = if ($interfacesPassed -eq $interfacesTotal) { "PASS" } else { "PARTIAL" }
   details = "$interfacesPassed/$interfacesTotal interfaces trouvées"
}

# Test 4: Vérification des endpoints
Write-Host "🌐 Test 4: Vérification des endpoints..." -ForegroundColor Yellow

$requiredEndpoints = @(
   "/api/v1/workflow/execute",
   "/api/v1/workflow/status",
   "/api/v1/workflow/cancel",
   "/api/v1/workflow/list",
   "/api/v1/health",
   "/api/v1/docs",
   "/api/v1/capabilities"
)

$endpointsFound = 0
if (Test-Path "pkg/bridge/api/http_receiver.go") {
   $receiverContent = Get-Content "pkg/bridge/api/http_receiver.go" -Raw
    
   foreach ($endpoint in $requiredEndpoints) {
      if ($receiverContent -match [regex]::Escape($endpoint)) {
         $Results.endpoint_coverage[$endpoint] = "FOUND"
         $endpointsFound++
         Write-Host "   ✅ $endpoint" -ForegroundColor Green
      }
      else {
         $Results.endpoint_coverage[$endpoint] = "MISSING"
         Write-Host "   ❌ $endpoint - MANQUANT" -ForegroundColor Red
      }
   }
}
else {
   foreach ($endpoint in $requiredEndpoints) {
      $Results.endpoint_coverage[$endpoint] = "FILE_MISSING"
   }
}

$Results.tests_run += @{
   name    = "Endpoint Coverage"
   status  = if ($endpointsFound -eq $requiredEndpoints.Count) { "PASS" } else { "PARTIAL" }
   details = "$endpointsFound/$($requiredEndpoints.Count) endpoints trouvés"
}

# Test 5: Validation des types de données
Write-Host "📊 Test 5: Validation des types de données..." -ForegroundColor Yellow

$requiredTypes = @(
   "WorkflowRequest",
   "WorkflowResponse", 
   "ErrorDetails",
   "WorkflowStatus",
   "HealthStatus",
   "ProcessingType",
   "Priority",
   "ProcessingStatus"
)

$typesFound = 0
if (Test-Path "pkg/bridge/api/workflow_types.go") {
   $typesContent = Get-Content "pkg/bridge/api/workflow_types.go" -Raw
    
   foreach ($type in $requiredTypes) {
      if ($typesContent -match "type\s+$type\s+(struct|string)") {
         $typesFound++
         Write-Host "   ✅ Type $type" -ForegroundColor Green
      }
      else {
         Write-Host "   ❌ Type $type - MANQUANT" -ForegroundColor Red
         $Results.errors += "Type manquant: $type"
      }
   }
}
else {
   $Results.errors += "Fichier workflow_types.go manquant"
}

$Results.tests_run += @{
   name    = "Data Types Validation"
   status  = if ($typesFound -eq $requiredTypes.Count) { "PASS" } else { "PARTIAL" }
   details = "$typesFound/$($requiredTypes.Count) types trouvés"
}

# Test 6: Validation méthode Error pour ErrorDetails
Write-Host "🔧 Test 6: Validation interface error..." -ForegroundColor Yellow

$errorMethodFound = $false
if (Test-Path "pkg/bridge/api/workflow_types.go") {
   $typesContent = Get-Content "pkg/bridge/api/workflow_types.go" -Raw
   if ($typesContent -match "func\s+\(\s*e\s+\*ErrorDetails\s*\)\s+Error\(\)\s+string") {
      $errorMethodFound = $true
      Write-Host "   ✅ Méthode Error() implémentée" -ForegroundColor Green
   }
   else {
      Write-Host "   ❌ Méthode Error() manquante" -ForegroundColor Red
      $Results.errors += "ErrorDetails ne implémente pas l'interface error"
   }
}

$Results.tests_run += @{
   name    = "Error Interface Implementation"
   status  = if ($errorMethodFound) { "PASS" } else { "FAIL" }
   details = if ($errorMethodFound) { "Méthode Error() trouvée" } else { "Méthode Error() manquante" }
}

# Calcul du résumé
$EndTime = Get-Date
$TotalDuration = ($EndTime - $StartTime).TotalSeconds

$testsPassed = ($Results.tests_run | Where-Object { $_.status -eq "PASS" }).Count
$testsTotal = $Results.tests_run.Count

$Results.summary = @{
   total_duration_seconds = $TotalDuration
   tests_passed           = $testsPassed
   tests_total            = $testsTotal
   files_validated_count  = $Results.files_validated.Count
   compilation_status     = $Results.compilation_status
   interfaces_coverage    = "$interfacesPassed/$interfacesTotal"
   endpoints_coverage     = "$endpointsFound/$($requiredEndpoints.Count)"
   errors_count           = $Results.errors.Count
   overall_status         = if ($testsPassed -eq $testsTotal -and $Results.compilation_status -eq "SUCCESS") { "SUCCESS" } elseif ($testsPassed -gt 0) { "PARTIAL" } else { "FAILED" }
}

# Sauvegarde des résultats
$outputDir = "output/phase2"
if (!(Test-Path $outputDir)) {
   New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

$outputFile = Join-Path $outputDir "task-023-validation.json"
$Results | ConvertTo-Json -Depth 10 | Set-Content $outputFile -Encoding UTF8

# Affichage du résumé
Write-Host ""
Write-Host "📋 RÉSUMÉ VALIDATION TÂCHE 023:" -ForegroundColor Cyan
Write-Host "   Durée totale: $([math]::Round($TotalDuration, 2))s" -ForegroundColor White
Write-Host "   Tests réussis: $testsPassed/$testsTotal" -ForegroundColor White
Write-Host "   Fichiers validés: $($Results.files_validated.Count)" -ForegroundColor White
Write-Host "   Compilation: $($Results.compilation_status)" -ForegroundColor $(if ($Results.compilation_status -eq "SUCCESS") { "Green" } else { "Red" })
Write-Host "   Interfaces: $interfacesPassed/$interfacesTotal" -ForegroundColor White
Write-Host "   Endpoints: $endpointsFound/$($requiredEndpoints.Count)" -ForegroundColor White
Write-Host "   Erreurs: $($Results.errors.Count)" -ForegroundColor White
Write-Host "   Status global: $($Results.summary.overall_status)" -ForegroundColor $(
   switch ($Results.summary.overall_status) {
      "SUCCESS" { "Green" }
      "PARTIAL" { "Yellow" }
      "FAILED" { "Red" }
      default { "White" }
   }
)

if ($Results.errors.Count -gt 0) {
   Write-Host ""
   Write-Host "⚠️ ERREURS DÉTECTÉES:" -ForegroundColor Yellow
   foreach ($error in $Results.errors) {
      Write-Host "   $error" -ForegroundColor Red
   }
}

Write-Host ""
Write-Host "💾 Rapport sauvé: $outputFile" -ForegroundColor Green
Write-Host ""
Write-Host "✅ VALIDATION TÂCHE 023 TERMINÉE" -ForegroundColor Green

# Retourner le code de sortie approprié
if ($Results.summary.overall_status -eq "SUCCESS") {
   exit 0
}
elseif ($Results.summary.overall_status -eq "PARTIAL") {
   exit 1
}
else {
   exit 2
}
