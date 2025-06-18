# Task 007: Benchmark Managers Existants
# Durée: 20 minutes max
# Sortie: performance-baseline.json

param(
   [string]$OutputDir = "output/phase1",
   [switch]$Verbose
)

$ErrorActionPreference = "Continue"
$StartTime = Get-Date

Write-Host "🚀 PHASE 1.1.3 - TÂCHE 007: Benchmark Managers Existants" -ForegroundColor Cyan
Write-Host "=" * 60

# Création du répertoire de sortie
if (!(Test-Path $OutputDir)) {
   New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$Results = @{
   task                = "007-benchmark-managers"
   timestamp           = $StartTime.ToString("yyyy-MM-dd HH:mm:ss")
   go_version          = ""
   benchmarks          = @{}
   performance_metrics = @{}
   errors              = @()
   summary             = @{}
}

try {
   # Vérifier la version Go
   Write-Host "🔍 Vérification version Go..." -ForegroundColor Yellow
   $goVersion = go version 2>&1
   if ($LASTEXITCODE -eq 0) {
      $Results.go_version = $goVersion.ToString()
      Write-Host "✅ Go détecté: $goVersion" -ForegroundColor Green
   }
   else {
      $errorMsg = "Go non disponible: $goVersion"
      $Results.errors += $errorMsg
      Write-Host "❌ $errorMsg" -ForegroundColor Red
      return
   }

   # Rechercher les fichiers managers Go
   Write-Host "🔍 Recherche des managers Go..." -ForegroundColor Yellow
   $managerFiles = Get-ChildItem -Recurse -Include "*manager*.go", "*Manager*.go" | 
   Where-Object { $_.FullName -notmatch "vendor|node_modules|\.git" }

   if ($managerFiles) {
      Write-Host "📁 Managers détectés:" -ForegroundColor Green
      foreach ($file in $managerFiles) {
         $relativePath = $file.FullName.Replace((Get-Location).Path, "").TrimStart('\')
         Write-Host "   $relativePath" -ForegroundColor White
      }
        
      $Results.performance_metrics.managers_found = $managerFiles.Count
      $Results.performance_metrics.manager_files = $managerFiles | ForEach-Object { 
         @{
            path          = $_.FullName.Replace((Get-Location).Path, "").TrimStart('\')
            size_bytes    = $_.Length
            last_modified = $_.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
         }
      }
   }
   else {
      Write-Host "⚠️ Aucun fichier manager Go trouvé" -ForegroundColor Yellow
      $Results.performance_metrics.managers_found = 0
   }

   # Vérifier si go.mod existe
   Write-Host "🔍 Vérification module Go..." -ForegroundColor Yellow
   if (Test-Path "go.mod") {
      Write-Host "✅ go.mod trouvé" -ForegroundColor Green
        
      # Lire le contenu du go.mod
      $goModContent = Get-Content "go.mod" -Raw
      $Results.performance_metrics.go_mod_info = @{
         exists          = $true
         content_preview = $goModContent.Substring(0, [Math]::Min(500, $goModContent.Length))
      }
        
      # Tenter go mod tidy
      Write-Host "🔧 Exécution go mod tidy..." -ForegroundColor Yellow
      $tidyResult = go mod tidy 2>&1
      if ($LASTEXITCODE -eq 0) {
         Write-Host "✅ go mod tidy réussi" -ForegroundColor Green
      }
      else {
         $errorMsg = "go mod tidy échoué: $tidyResult"
         $Results.errors += $errorMsg
         Write-Host "⚠️ $errorMsg" -ForegroundColor Yellow
      }
   }
   else {
      Write-Host "⚠️ go.mod non trouvé" -ForegroundColor Yellow
      $Results.performance_metrics.go_mod_info = @{ exists = $false }
   }

   # Rechercher les répertoires avec des tests
   Write-Host "🔍 Recherche des tests Go..." -ForegroundColor Yellow
   $testFiles = Get-ChildItem -Recurse -Include "*_test.go" | 
   Where-Object { $_.FullName -notmatch "vendor|node_modules|\.git" }

   $testDirs = @()
   if ($testFiles) {
      $testDirs = $testFiles | ForEach-Object { $_.Directory.FullName } | Sort-Object -Unique
      Write-Host "📁 Répertoires avec tests:" -ForegroundColor Green
      foreach ($dir in $testDirs) {
         $relativePath = $dir.Replace((Get-Location).Path, "").TrimStart('\')
         Write-Host "   $relativePath" -ForegroundColor White
      }
        
      $Results.performance_metrics.test_files_found = $testFiles.Count
      $Results.performance_metrics.test_directories = $testDirs.Count
   }
   else {
      Write-Host "⚠️ Aucun fichier de test trouvé" -ForegroundColor Yellow
      $Results.performance_metrics.test_files_found = 0
      $Results.performance_metrics.test_directories = 0
   }

   # Exécuter les benchmarks si possible
   if ($testDirs.Count -gt 0 -and (Test-Path "go.mod")) {
      Write-Host "🏃‍♂️ Exécution des benchmarks..." -ForegroundColor Yellow
        
      # Tenter benchmark global
      Write-Host "📊 Benchmark global (timeout 30s)..." -ForegroundColor Cyan
      $benchmarkStart = Get-Date
        
      try {
         # Utiliser timeout pour éviter les blocages
         $benchResult = timeout 30 go test -bench=. -benchmem ./... 2>&1
         $benchmarkEnd = Get-Date
         $benchmarkDuration = ($benchmarkEnd - $benchmarkStart).TotalSeconds
            
         if ($benchResult -match "PASS|FAIL|ok|SKIP") {
            Write-Host "✅ Benchmark terminé en $([math]::Round($benchmarkDuration, 2))s" -ForegroundColor Green
                
            # Parser les résultats de benchmark
            $benchmarkLines = $benchResult -split "`n" | Where-Object { $_ -match "Benchmark" }
            $Results.benchmarks.global_benchmark = @{
               duration_seconds = $benchmarkDuration
               raw_output       = $benchResult.ToString()
               benchmark_lines  = $benchmarkLines
               status           = "completed"
            }
                
            # Analyser les métriques de performance
            $memoryLines = $benchResult -split "`n" | Where-Object { $_ -match "allocs/op|B/op" }
            if ($memoryLines) {
               $Results.benchmarks.memory_metrics = $memoryLines
            }
                
         }
         else {
            $errorMsg = "Benchmark n'a pas produit de résultats valides"
            $Results.errors += $errorMsg
            Write-Host "⚠️ $errorMsg" -ForegroundColor Yellow
            $Results.benchmarks.global_benchmark = @{
               duration_seconds = $benchmarkDuration
               status           = "no_valid_output"
               raw_output       = $benchResult.ToString()
            }
         }
      }
      catch {
         $errorMsg = "Erreur lors du benchmark: $($_.Exception.Message)"
         $Results.errors += $errorMsg
         Write-Host "❌ $errorMsg" -ForegroundColor Red
         $Results.benchmarks.global_benchmark = @{
            status       = "error"
            errorMessage = $errorMsg
         }
      }
        
      # Benchmark spécifique aux répertoires avec managers
      $managerDirs = @()
      if ($managerFiles) {
         $managerDirs = $managerFiles | ForEach-Object { $_.Directory.FullName } | Sort-Object -Unique
            
         foreach ($dir in $managerDirs) {
            $relativePath = $dir.Replace((Get-Location).Path, "").TrimStart('\').Replace('\', '/')
            if ($relativePath -eq "") { $relativePath = "." }
                
            Write-Host "📊 Benchmark $relativePath..." -ForegroundColor Cyan
            $dirBenchStart = Get-Date
                
            try {
               $dirBenchResult = timeout 15 go test -bench=. -benchmem $relativePath 2>&1
               $dirBenchEnd = Get-Date
               $dirBenchDuration = ($dirBenchEnd - $dirBenchStart).TotalSeconds
                    
               if (!$Results.benchmarks.directory_benchmarks) {
                  $Results.benchmarks.directory_benchmarks = @{}
               }
               
               $statusValue = "no_output"
               if ($dirBenchResult -match "PASS|FAIL|ok|SKIP") {
                  $statusValue = "completed"
               }
               
               $Results.benchmarks.directory_benchmarks[$relativePath] = @{
                  duration_seconds = $dirBenchDuration
                  raw_output       = $dirBenchResult.ToString()
                  status           = $statusValue
               }
                    
               Write-Host "   ✅ Terminé en $([math]::Round($dirBenchDuration, 2))s" -ForegroundColor Green
            }
            catch {
               $errorMsg = "Erreur benchmark $relativePath : $($_.Exception.Message)"
               $Results.errors += $errorMsg
               Write-Host "   ❌ $errorMsg" -ForegroundColor Red
            }
         }
      }
   }
   else {
      Write-Host "⚠️ Pas de tests trouvés ou go.mod manquant - benchmark impossible" -ForegroundColor Yellow
      $Results.benchmarks.status = "skipped"
      $Results.benchmarks.reason = "no_tests_or_gomod"
   }

   # Tests de build pour vérifier la compilabilité
   Write-Host "🔨 Test de build..." -ForegroundColor Yellow
   $buildStart = Get-Date
    
   try {
      $buildResult = go build ./... 2>&1
      $buildEnd = Get-Date
      $buildDuration = ($buildEnd - $buildStart).TotalSeconds
        
      if ($LASTEXITCODE -eq 0) {
         Write-Host "✅ Build réussi en $([math]::Round($buildDuration, 2))s" -ForegroundColor Green
         $Results.performance_metrics.build_status = @{
            success          = $true
            duration_seconds = $buildDuration
            output           = $buildResult.ToString()
         }
      }
      else {
         Write-Host "❌ Build échoué" -ForegroundColor Red
         $Results.performance_metrics.build_status = @{
            success          = $false
            duration_seconds = $buildDuration
            errorMessage     = $buildResult.ToString()
         }
      }
   }
   catch {
      $errorMsg = "Erreur lors du build: $($_.Exception.Message)"
      $Results.errors += $errorMsg
      Write-Host "❌ $errorMsg" -ForegroundColor Red
      $Results.performance_metrics.build_status = @{
         success      = $false
         errorMessage = $errorMsg
      }
   }

}
catch {
   $errorMsg = "Erreur générale: $($_.Exception.Message)"
   $Results.errors += $errorMsg
   Write-Host "❌ $errorMsg" -ForegroundColor Red
}

# Calcul du résumé
$EndTime = Get-Date
$TotalDuration = ($EndTime - $StartTime).TotalSeconds

$Results.summary = @{
   total_duration_seconds = $TotalDuration
   managers_analyzed      = $Results.performance_metrics.managers_found
   tests_found            = $Results.performance_metrics.test_files_found
   benchmarks_executed    = $(if ($Results.benchmarks.global_benchmark) { 1 } else { 0 })
   build_successful       = $($Results.performance_metrics.build_status.success -eq $true)
   errors_count           = $Results.errors.Count
   status                 = $(if ($Results.errors.Count -eq 0) { "SUCCESS" } else { "PARTIAL_SUCCESS" })
}

# Sauvegarde des résultats
$outputFile = Join-Path $OutputDir "performance-baseline.json"
$Results | ConvertTo-Json -Depth 10 | Set-Content $outputFile -Encoding UTF8

Write-Host ""
Write-Host "📋 RÉSUMÉ TÂCHE 007:" -ForegroundColor Cyan
Write-Host "   Durée totale: $([math]::Round($TotalDuration, 2))s" -ForegroundColor White
Write-Host "   Managers trouvés: $($Results.summary.managers_analyzed)" -ForegroundColor White
Write-Host "   Tests trouvés: $($Results.summary.tests_found)" -ForegroundColor White
Write-Host "   Build réussi: $($Results.summary.build_successful)" -ForegroundColor White
Write-Host "   Erreurs: $($Results.summary.errors_count)" -ForegroundColor White
Write-Host "   Status: $($Results.summary.status)" -ForegroundColor $(if ($Results.summary.status -eq "SUCCESS") { "Green" } else { "Yellow" })
Write-Host ""
Write-Host "💾 Résultats sauvés: $outputFile" -ForegroundColor Green

if ($Verbose -and $Results.errors.Count -gt 0) {
   Write-Host ""
   Write-Host "⚠️ ERREURS DÉTECTÉES:" -ForegroundColor Yellow
   foreach ($errorItem in $Results.errors) {
      Write-Host "   $errorItem" -ForegroundColor Red
   }
}

Write-Host ""
Write-Host "✅ TÂCHE 007 TERMINÉE" -ForegroundColor Green
