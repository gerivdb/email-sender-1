#!/usr/bin/env powershell
# Validation Complétude Phase 1.1.1 - Audit Infrastructure Manager Go
# Tâches Atomiques 001-006

Write-Host "🔍 VALIDATION PHASE 1.1.1: Audit Infrastructure Manager Go" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Yellow

# Vérification branche
$currentBranch = git branch --show-current
Write-Host "📋 Branche active: $currentBranch" -ForegroundColor Green

# Vérifier l'existence des fichiers de sortie
$outputDir = "output/phase1"
$expectedFiles = @(
   "audit-managers-scan.json", # Tâche 001
   "interfaces-publiques-managers.md", # Tâche 002
   "interfaces-publiques-scan.json", # Tâche 002
   "constructors-analysis.json", # Tâche 003
   "constructors-patterns.md", # Tâche 003
   "dependencies-map.json", # Tâche 004
   "dependencies-map.md", # Tâche 004
   "dependencies-map.dot"                         # Tâche 004
)

Write-Host "`n📋 Vérification des sorties attendues..." -ForegroundColor Yellow

$completedTasks = @()
$missingFiles = @()

foreach ($file in $expectedFiles) {
   $filePath = Join-Path $outputDir $file
   if (Test-Path $filePath) {
      $fileInfo = Get-Item $filePath
      $completedTasks += @{
         file          = $file
         path          = $filePath
         size_kb       = [math]::Round($fileInfo.Length / 1KB, 2)
         last_modified = $fileInfo.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
      }
      Write-Host "  ✅ $file ($([math]::Round($fileInfo.Length / 1KB, 2)) KB)" -ForegroundColor Green
   }
   else {
      $missingFiles += $file
      Write-Host "  ❌ $file" -ForegroundColor Red
   }
}

# Identifier tâches atomiques complétées
$taskStatus = @{
   "Task_001_Scanner_Managers"       = $null -ne ($completedTasks | Where-Object { $_.file -eq "audit-managers-scan.json" })
   "Task_002_Extraire_Interfaces"    = ($null -ne ($completedTasks | Where-Object { $_.file -eq "interfaces-publiques-managers.md" })) -and ($null -ne ($completedTasks | Where-Object { $_.file -eq "interfaces-publiques-scan.json" }))
   "Task_003_Analyser_Constructeurs" = ($null -ne ($completedTasks | Where-Object { $_.file -eq "constructors-analysis.json" })) -and ($null -ne ($completedTasks | Where-Object { $_.file -eq "constructors-patterns.md" }))
   "Task_004_Cartographier_Imports"  = ($null -ne ($completedTasks | Where-Object { $_.file -eq "dependencies-map.json" })) -and ($null -ne ($completedTasks | Where-Object { $_.file -eq "dependencies-map.md" }))
}

# Résumé des tâches
Write-Host "`n📊 STATUT DES TÂCHES ATOMIQUES:" -ForegroundColor Magenta

foreach ($task in $taskStatus.GetEnumerator()) {
   $status = if ($task.Value) { "✅ COMPLÉTÉE" } else { "❌ EN COURS/MANQUANTE" }
   $color = if ($task.Value) { "Green" } else { "Red" }
   Write-Host "  $($task.Key): $status" -ForegroundColor $color
}

# Calculer statistiques si fichiers JSON disponibles
Write-Host "`n📈 STATISTIQUES EXTRAITES:" -ForegroundColor Magenta

# Stats interfaces (si disponible)
$interfacesFile = Join-Path $outputDir "interfaces-publiques-scan.json"
if (Test-Path $interfacesFile) {
   try {
      $interfacesData = Get-Content $interfacesFile -Raw | ConvertFrom-Json
      Write-Host "  🔗 Interfaces trouvées: $($interfacesData.interfaces_found)" -ForegroundColor White
      Write-Host "  📄 Fichiers scannés: $($interfacesData.total_files_scanned)" -ForegroundColor White
   }
   catch {
      Write-Host "  ⚠️  Erreur lecture interfaces JSON" -ForegroundColor Yellow
   }
}

# Stats constructeurs (si disponible)
$constructorsFile = Join-Path $outputDir "constructors-analysis.json"
if (Test-Path $constructorsFile) {
   try {
      $constructorsData = Get-Content $constructorsFile -Raw | ConvertFrom-Json
      Write-Host "  🏗️  Constructeurs trouvés: $($constructorsData.constructors_found)" -ForegroundColor White
      Write-Host "  📋 Patterns recherchés: $($constructorsData.patterns_searched)" -ForegroundColor White
   }
   catch {
      Write-Host "  ⚠️  Erreur lecture constructeurs JSON" -ForegroundColor Yellow
   }
}

# Stats dependencies (si disponible)
$dependenciesFile = Join-Path $outputDir "dependencies-map.json"
if (Test-Path $dependenciesFile) {
   try {
      $dependenciesData = Get-Content $dependenciesFile -Raw | ConvertFrom-Json
      Write-Host "  📦 Total imports: $($dependenciesData.total_imports)" -ForegroundColor White
      Write-Host "  📁 Packages uniques: $($dependenciesData.unique_packages.Count)" -ForegroundColor White
   }
   catch {
      Write-Host "  ⚠️  Erreur lecture dependencies JSON" -ForegroundColor Yellow
   }
}

# Recommandations pour la suite
Write-Host "`n🎯 PROCHAINES ÉTAPES:" -ForegroundColor Magenta

$completedCount = ($taskStatus.Values | Where-Object { $_ }).Count
$totalTasks = $taskStatus.Count

if ($completedCount -eq $totalTasks) {
   Write-Host "  ✅ Phase 1.1.1 COMPLÈTE - Prêt pour Phase 1.1.2" -ForegroundColor Green
   Write-Host "  🎯 Lancer Tâche Atomique 005: Identifier Points Communication" -ForegroundColor White
}
else {
   Write-Host "  ⚠️  Phase 1.1.1 INCOMPLÈTE ($completedCount/$totalTasks tâches)" -ForegroundColor Yellow
   Write-Host "  🔄 Compléter les tâches manquantes avant de continuer" -ForegroundColor White
}

# Validation de branche
if ($currentBranch -eq "dev") {
   Write-Host "`n✅ Branche 'dev' appropriée pour ces tâches" -ForegroundColor Green
}
else {
   Write-Host "`n⚠️  Attention: branche '$currentBranch' - vérifier si appropriée" -ForegroundColor Yellow
}

Write-Host "`n🏁 AUDIT PHASE 1.1.1 TERMINÉ" -ForegroundColor Cyan
