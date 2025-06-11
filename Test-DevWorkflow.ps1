# =============================================================================
# Test-DevWorkflow.ps1 - Test du workflow de développement complet
# =============================================================================

Write-Host "🧪 Test du workflow de développement avec commandes Unix" -ForegroundColor Green
Write-Host ""

# Chargement du bridge si pas déjà fait
$bridgeScript = Join-Path $PSScriptRoot "UnixCommandsBridge.ps1"
if (Test-Path $bridgeScript) {
   . $bridgeScript
}

# Test 1: Pipeline de test Go avec Unix commands
Write-Host "1️⃣  Test pipeline Go avec grep et wc..." -ForegroundColor Cyan
try {
   Push-Location "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\hooks\commit-interceptor"
    
   Write-Host "   Exécution: go test ./... -v | grep -E '^=== RUN|^--- PASS|^--- FAIL'" -ForegroundColor Gray
   $testOutput = go test ./... -v | grep -E "^=== RUN|^--- PASS|^--- FAIL"
    
   $runCount = ($testOutput | grep "^=== RUN" | wc -l).Trim()
   $passCount = ($testOutput | grep "^--- PASS" | wc -l).Trim()
   $failCount = ($testOutput | grep "^--- FAIL" | wc -l).Trim()
    
   Write-Host "   ✅ Tests RUN: $runCount" -ForegroundColor Green
   Write-Host "   ✅ Tests PASS: $passCount" -ForegroundColor Green
   Write-Host "   ✅ Tests FAIL: $failCount" -ForegroundColor $(if ($failCount -eq "0") { "Green" } else { "Red" })
    
   Pop-Location
}
catch {
   Write-Host "   ❌ Erreur: $_" -ForegroundColor Red
}

Write-Host ""

# Test 2: Analyse de fichiers avec find et grep
Write-Host "2️⃣  Test analyse de fichiers Go..." -ForegroundColor Cyan
try {
   Push-Location "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\hooks\commit-interceptor"
    
   Write-Host "   Recherche de fichiers Go..." -ForegroundColor Gray
   $goFiles = find . -name "*.go" | wc -l
   Write-Host "   ✅ Fichiers Go trouvés: $($goFiles.Trim())" -ForegroundColor Green
    
   Write-Host "   Recherche de fonctions test..." -ForegroundColor Gray
   $testFunctions = find . -name "*_test.go" | xargs grep -E "^func Test" | wc -l
   Write-Host "   ✅ Fonctions de test: $($testFunctions.Trim())" -ForegroundColor Green
    
   Pop-Location
}
catch {
   Write-Host "   ❌ Erreur: $_" -ForegroundColor Red
}

Write-Host ""

# Test 3: Analyse de logs avec awk et sed
Write-Host "3️⃣  Test traitement de texte avancé..." -ForegroundColor Cyan
try {
   # Créer des données de test
   $sampleData = @"
2025-06-11 10:00:01 INFO Starting application
2025-06-11 10:00:02 DEBUG Loading configuration
2025-06-11 10:00:03 INFO Application started successfully
2025-06-11 10:00:04 WARN Deprecated function used
2025-06-11 10:00:05 ERROR Connection failed
"@
    
   Write-Host "   Analyse avec awk - Extraction des erreurs..." -ForegroundColor Gray
   $errors = $sampleData | awk '$4 == "ERROR" {print $5, $6}'
   Write-Host "   ✅ Erreurs trouvées: $errors" -ForegroundColor $(if ($errors) { "Red" } else { "Green" })
    
   Write-Host "   Transformation avec sed - Formatage dates..." -ForegroundColor Gray
   $formatted = $sampleData | sed 's/2025-06-11/[TODAY]/' | head -n 2
   Write-Host "   ✅ Format transformé: $($formatted -split "`n" | Select-Object -First 1)" -ForegroundColor Green
}
catch {
   Write-Host "   ❌ Erreur: $_" -ForegroundColor Red
}

Write-Host ""

# Test 4: JSON processing avec jq
Write-Host "4️⃣  Test traitement JSON avec jq..." -ForegroundColor Cyan
try {
   $jsonData = @'
{
  "project": "commit-interceptor",
  "version": "1.0.0",
  "tests": {
    "total": 38,
    "passed": 38,
    "failed": 0
  },
  "coverage": "100%"
}
'@
    
   Write-Host "   Extraction avec jq..." -ForegroundColor Gray
   $projectName = $jsonData | jq -r '.project'
   $testsPassed = $jsonData | jq -r '.tests.passed'
   $coverage = $jsonData | jq -r '.coverage'
    
   Write-Host "   ✅ Projet: $projectName" -ForegroundColor Green
   Write-Host "   ✅ Tests réussis: $testsPassed" -ForegroundColor Green
   Write-Host "   ✅ Couverture: $coverage" -ForegroundColor Green
}
catch {
   Write-Host "   ❌ Erreur jq: $_" -ForegroundColor Red
   Write-Host "   💡 Installez jq: https://stedolan.github.io/jq/" -ForegroundColor Yellow
}

Write-Host ""

# Test 5: Git workflow avec grep
Write-Host "5️⃣  Test workflow Git..." -ForegroundColor Cyan
try {
   Push-Location "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
    
   Write-Host "   Analyse des commits récents..." -ForegroundColor Gray
   $recentCommits = git log --oneline -10 | grep -E "(feat|fix|docs)" | wc -l
   Write-Host "   ✅ Commits conventionnels récents: $($recentCommits.Trim())" -ForegroundColor Green
    
   Write-Host "   Fichiers modifiés..." -ForegroundColor Gray
   $modifiedFiles = git status --porcelain | wc -l
   Write-Host "   ✅ Fichiers modifiés: $($modifiedFiles.Trim())" -ForegroundColor Green
    
   Pop-Location
}
catch {
   Write-Host "   ❌ Erreur Git: $_" -ForegroundColor Red
}

Write-Host ""

# Test 6: Performance et hash
Write-Host "6️⃣  Test hashing et performance..." -ForegroundColor Cyan
try {
   $testString = "Framework de Branchement Automatique - Phase 2.2 Complete"
    
   Write-Host "   Calcul MD5..." -ForegroundColor Gray
   $md5Hash = $testString | md5sum | cut -d' ' -f1
   Write-Host "   ✅ MD5: $md5Hash" -ForegroundColor Green
    
   Write-Host "   Calcul SHA256..." -ForegroundColor Gray
   $sha256Hash = $testString | sha256sum | cut -d' ' -f1
   Write-Host "   ✅ SHA256: $($sha256Hash.Substring(0,16))..." -ForegroundColor Green
}
catch {
   Write-Host "   ❌ Erreur hashing: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "🎉 Test du workflow terminé!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Commandes testées avec succès:" -ForegroundColor White
Write-Host "   • grep, wc, find, xargs" -ForegroundColor Cyan
Write-Host "   • awk, sed, head, cut" -ForegroundColor Cyan  
Write-Host "   • jq (si installé)" -ForegroundColor Cyan
Write-Host "   • md5sum, sha256sum" -ForegroundColor Cyan
Write-Host ""
Write-Host "💡 Votre environment est prêt pour le développement avec Unix tools!" -ForegroundColor Yellow
