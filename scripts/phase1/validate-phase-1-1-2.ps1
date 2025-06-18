#!/usr/bin/env powershell
# Validation Complétude Phase 1.1.2 - Mapper Dépendances et Communications
# Tâches Atomiques 005-006

Write-Host "🔍 VALIDATION PHASE 1.1.2: Mapper Dépendances et Communications" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Yellow

# Vérification branche
$currentBranch = git branch --show-current
Write-Host "📋 Branche active: $currentBranch" -ForegroundColor Green

# Vérifier l'existence des fichiers de sortie Phase 1.1.2
$outputDir = "output/phase1"
$expectedFiles112 = @(
   "communication-points.yaml", # Tâche 005
   "communication-points.md", # Tâche 005
   "communication-points.json", # Tâche 005
   "error-handling-patterns.md", # Tâche 006
   "error-handling-patterns.json"             # Tâche 006
)

Write-Host "`n📋 Vérification des sorties Phase 1.1.2..." -ForegroundColor Yellow

$completedTasks112 = @()
$missingFiles112 = @()

foreach ($file in $expectedFiles112) {
   $filePath = Join-Path $outputDir $file
   if (Test-Path $filePath) {
      $fileInfo = Get-Item $filePath
      $completedTasks112 += @{
         file          = $file
         path          = $filePath
         size_kb       = [math]::Round($fileInfo.Length / 1KB, 2)
         last_modified = $fileInfo.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
      }
      Write-Host "  ✅ $file ($([math]::Round($fileInfo.Length / 1KB, 2)) KB)" -ForegroundColor Green
   }
   else {
      $missingFiles112 += $file
      Write-Host "  ❌ $file" -ForegroundColor Red
   }
}

# Identifier tâches atomiques complétées Phase 1.1.2
$taskStatus112 = @{
   "Task_005_Identifier_Communications" = ($null -ne ($completedTasks112 | Where-Object { $_.file -eq "communication-points.yaml" })) -and ($null -ne ($completedTasks112 | Where-Object { $_.file -eq "communication-points.md" }))
   "Task_006_Analyser_Gestion_Erreurs"  = ($null -ne ($completedTasks112 | Where-Object { $_.file -eq "error-handling-patterns.md" })) -and ($null -ne ($completedTasks112 | Where-Object { $_.file -eq "error-handling-patterns.json" }))
}

# Résumé des tâches Phase 1.1.2
Write-Host "`n📊 STATUT DES TÂCHES ATOMIQUES PHASE 1.1.2:" -ForegroundColor Magenta

foreach ($task in $taskStatus112.GetEnumerator()) {
   $status = if ($task.Value) { "✅ COMPLÉTÉE" } else { "❌ EN COURS/MANQUANTE" }
   $color = if ($task.Value) { "Green" } else { "Red" }
   Write-Host "  $($task.Key): $status" -ForegroundColor $color
}

# Vérification aussi Phase 1.1.1 pour complétude globale
$expectedFiles111 = @(
   "audit-managers-scan.json",
   "interfaces-publiques-managers.md",
   "interfaces-publiques-scan.json", 
   "constructors-analysis.json",
   "constructors-patterns.md",
   "dependencies-map.json",
   "dependencies-map.md",
   "dependencies-map.dot"
)

$phase111Complete = $true
foreach ($file in $expectedFiles111) {
   if (-not (Test-Path (Join-Path $outputDir $file))) {
      $phase111Complete = $false
      break
   }
}

Write-Host "`n📈 STATUT GLOBAL PHASES 1.1.1 + 1.1.2:" -ForegroundColor Magenta
Write-Host "  Phase 1.1.1: $(if ($phase111Complete) { '✅ COMPLÈTE' } else { '❌ INCOMPLÈTE' })" -ForegroundColor $(if ($phase111Complete) { 'Green' } else { 'Red' })

$completedCount112 = ($taskStatus112.Values | Where-Object { $_ }).Count
$totalTasks112 = $taskStatus112.Count

Write-Host "  Phase 1.1.2: $(if ($completedCount112 -eq $totalTasks112) { '✅ COMPLÈTE' } else { "❌ INCOMPLÈTE ($completedCount112/$totalTasks112)" })" -ForegroundColor $(if ($completedCount112 -eq $totalTasks112) { 'Green' } else { 'Red' })

# Calculer statistiques si fichiers JSON disponibles
Write-Host "`n📈 STATISTIQUES PHASE 1.1.2:" -ForegroundColor Magenta

# Stats communication (si disponible)
$communicationFile = Join-Path $outputDir "communication-points.json"
if (Test-Path $communicationFile) {
   try {
      $communicationData = Get-Content $communicationFile -Raw | ConvertFrom-Json
      Write-Host "  📡 Points de communication: $($communicationData.communication_points_found)" -ForegroundColor White
      Write-Host "  📋 Fichiers scannés: $($communicationData.total_files_scanned)" -ForegroundColor White
      Write-Host "  📦 Catégories analysées: $($communicationData.patterns_searched)" -ForegroundColor White
   }
   catch {
      Write-Host "  ⚠️  Erreur lecture communication JSON" -ForegroundColor Yellow
   }
}

# Stats erreurs (si disponible)
$errorFile = Join-Path $outputDir "error-handling-patterns.json"
if (Test-Path $errorFile) {
   try {
      $errorData = Get-Content $errorFile -Raw | ConvertFrom-Json
      Write-Host "  ⚠️  Patterns d'erreur: $($errorData.error_patterns_found)" -ForegroundColor White
      Write-Host "  📁 Fichiers managers: $($errorData.total_manager_files)" -ForegroundColor White
      Write-Host "  🔍 Catégories erreur: $($errorData.patterns_searched)" -ForegroundColor White
   }
   catch {
      Write-Host "  ⚠️  Erreur lecture error patterns JSON" -ForegroundColor Yellow
   }
}

# Recommandations pour la suite
Write-Host "`n🎯 PROCHAINES ÉTAPES:" -ForegroundColor Magenta

$bothPhasesComplete = $phase111Complete -and ($completedCount112 -eq $totalTasks112)

if ($bothPhasesComplete) {
   Write-Host "  ✅ Phases 1.1.1 + 1.1.2 COMPLÈTES - Prêt pour Phase 1.1.3" -ForegroundColor Green
   Write-Host "  🎯 Lancer Tâche Atomique 007: Benchmark Managers Existants" -ForegroundColor White
   Write-Host "  🎯 Lancer Tâche Atomique 008: Analyser Utilisation Ressources" -ForegroundColor White
}
else {
   Write-Host "  ⚠️  Phases incomplètes - Compléter avant de continuer" -ForegroundColor Yellow
   if (-not $phase111Complete) {
      Write-Host "  🔄 Finaliser Phase 1.1.1 d'abord" -ForegroundColor White
   }
   if ($completedCount112 -ne $totalTasks112) {
      Write-Host "  🔄 Compléter Phase 1.1.2 (Tâches 005-006)" -ForegroundColor White
   }
}

# Validation de branche
if ($currentBranch -eq "dev") {
   Write-Host "`n✅ Branche 'dev' appropriée pour Phase 1.1.2" -ForegroundColor Green
}
else {
   Write-Host "`n⚠️  Attention: branche '$currentBranch' - vérifier si appropriée" -ForegroundColor Yellow
}

# Résumé des livrables créés
Write-Host "`n📄 LIVRABLES PHASE 1.1.2 CRÉÉS:" -ForegroundColor Magenta
foreach ($task in $completedTasks112) {
   Write-Host "  📁 $($task.file) ($($task.size_kb) KB)" -ForegroundColor White
}

Write-Host "`n🏁 VALIDATION PHASE 1.1.2 TERMINÉE" -ForegroundColor Cyan
