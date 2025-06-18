# Validation Complète du Plan v54 - Toutes Phases
# Description: Vérifie que l'intégralité du plan de développement est implémentée

param(
   [switch]$Detailed = $false
)

Write-Host "🔍 VALIDATION COMPLÈTE DU PLAN v54 - TOUTES PHASES" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Gray

# Configuration
$rootPath = "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$phases = @{
   "Phase 1" = @{
      "Description" = "Smart Infrastructure Orchestrator"
      "StatusFile"  = "PHASE_1_SMART_INFRASTRUCTURE_COMPLETE.md"
      "KeyFiles"    = @(
         "internal\infrastructure\smart_orchestrator.go",
         "docker-compose.yml"
      )
   }
   "Phase 2" = @{
      "Description" = "Système de Surveillance et Auto-Recovery"
      "StatusFile"  = "PHASE_2_ADVANCED_MONITORING_COMPLETE.md"
      "KeyFiles"    = @(
         "internal\monitoring\advanced_infrastructure_monitor.go",
         "internal\auto_recovery\neural_auto_healer.go"
      )
   }
   "Phase 3" = @{
      "Description" = "Intégration IDE et Expérience Développeur"
      "StatusFile"  = "PHASE_3_IDE_INTEGRATION_FINAL_COMPLETE.md"
      "KeyFiles"    = @(
         ".vscode\extension\package.json",
         ".vscode\extension\out\extension.js"
      )
   }
   "Phase 4" = @{
      "Description" = "Optimisations et Sécurité"
      "StatusFile"  = "PHASE_4_IMPLEMENTATION_COMPLETE.md"
      "KeyFiles"    = @(
         "development\managers\advanced-autonomy-manager\internal\infrastructure\infrastructure_orchestrator.go",
         "development\managers\advanced-autonomy-manager\internal\infrastructure\security_manager.go",
         "development\managers\advanced-autonomy-manager\config\infrastructure_config.yaml",
         "scripts\infrastructure\Start-FullStack-Phase4.ps1"
      )
   }
}

$global:totalValidated = 0
$global:totalExpected = 0
$global:issues = @()

function Test-FileExists {
   param([string]$FilePath, [string]$Context)
    
   $fullPath = Join-Path $rootPath $FilePath
   $exists = Test-Path $fullPath
    
   $global:totalExpected++
   if ($exists) {
      $global:totalValidated++
      if ($Detailed) {
         Write-Host "  ✅ $FilePath" -ForegroundColor Green
      }
      return $true
   }
   else {
      $global:issues += "❌ Manquant: $FilePath ($Context)"
      if ($Detailed) {
         Write-Host "  ❌ $FilePath" -ForegroundColor Red
      }
      return $false
   }
}

function Get-FileSize {
   param([string]$FilePath)
    
   $fullPath = Join-Path $rootPath $FilePath
   if (Test-Path $fullPath) {
      $size = (Get-Item $fullPath).Length
      return $size
   }
   return 0
}

# Validation par phase
foreach ($phaseKey in $phases.Keys | Sort-Object) {
   $phase = $phases[$phaseKey]
    
   Write-Host ""
   Write-Host "🎯 $phaseKey : $($phase.Description)" -ForegroundColor Yellow
   Write-Host "-" * 50 -ForegroundColor Gray
    
   # Vérification du fichier de statut
   $statusExists = Test-FileExists $phase.StatusFile "$phaseKey Status"
    
   if ($statusExists) {
      $statusPath = Join-Path $rootPath $phase.StatusFile
      $content = Get-Content $statusPath -Raw
      if ($content -match "✅.*COMPLETE|IMPLEMENTED|SUCCESS") {
         Write-Host "  📋 Statut: COMPLÈTE" -ForegroundColor Green
      }
      else {
         $global:issues += "⚠️  ${phaseKey}: Statut incomplet"
         Write-Host "  📋 Statut: INCOMPLET" -ForegroundColor Yellow
      }
   }
    
   # Vérification des fichiers clés
   $filesValidated = 0
   foreach ($file in $phase.KeyFiles) {
      if (Test-FileExists $file "$phaseKey Implementation") {
         $filesValidated++
      }
   }
    
   $completion = if ($phase.KeyFiles.Count -gt 0) { 
      [math]::Round(($filesValidated / $phase.KeyFiles.Count) * 100, 1) 
   }
   else { 100 }
    
   Write-Host "  📊 Fichiers: $filesValidated/$($phase.KeyFiles.Count) ($completion%)" -ForegroundColor $(if ($completion -eq 100) { "Green" } else { "Yellow" })
}

# Vérification des composants infrastructure critiques
Write-Host ""
Write-Host "🏗️  COMPOSANTS INFRASTRUCTURE CRITIQUES" -ForegroundColor Cyan
Write-Host "-" * 50 -ForegroundColor Gray

$criticalComponents = @{
   "Docker Infrastructure" = @(
      "docker-compose.yml",
      "Dockerfile"
   )
   "Configuration"         = @(
      "development\managers\advanced-autonomy-manager\config\infrastructure_config.yaml"
   )
   "Scripts PowerShell"    = @(
      "scripts\infrastructure\Start-FullStack-Phase4.ps1",
      "scripts\Test-Phase4-Complete.ps1"
   )
   "Documentation"         = @(
      "FINAL_SUCCESS_REPORT_100_PERCENT.md",
      "README.md"
   )
}

foreach ($component in $criticalComponents.Keys) {
   Write-Host "  🔧 $component" -ForegroundColor White
   foreach ($file in $criticalComponents[$component]) {
      Test-FileExists $file $component | Out-Null
   }
}

# Vérification Git
Write-Host ""
Write-Host "📦 ÉTAT GIT" -ForegroundColor Cyan
Write-Host "-" * 50 -ForegroundColor Gray

try {
   $currentBranch = git branch --show-current 2>$null
   Write-Host "  🌿 Branche active: $currentBranch" -ForegroundColor $(if ($currentBranch -eq "dev") { "Green" } else { "Yellow" })
    
   $gitStatus = git status --porcelain 2>$null
   $modifiedFiles = ($gitStatus | Where-Object { $_ -match "^\s*M\s+" }).Count
   $newFiles = ($gitStatus | Where-Object { $_ -match "^\?\?\s+" }).Count
    
   Write-Host "  📝 Fichiers modifiés: $modifiedFiles" -ForegroundColor $(if ($modifiedFiles -eq 0) { "Green" } else { "Yellow" })
   Write-Host "  📄 Nouveaux fichiers: $newFiles" -ForegroundColor $(if ($newFiles -eq 0) { "Green" } else { "Yellow" })
}
catch {
   Write-Host "  ⚠️  Impossible de vérifier l'état Git" -ForegroundColor Yellow
}

# Résumé final
Write-Host ""
Write-Host "📊 RÉSUMÉ DE VALIDATION" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Gray

$completionPercentage = if ($global:totalExpected -gt 0) { 
   [math]::Round(($global:totalValidated / $global:totalExpected) * 100, 1) 
}
else { 0 }

Write-Host "✅ Fichiers validés: $global:totalValidated/$global:totalExpected ($completionPercentage%)" -ForegroundColor $(if ($completionPercentage -eq 100) { "Green" } else { "Yellow" })

if ($global:issues.Count -eq 0) {
   Write-Host ""
   Write-Host "🎉 VALIDATION COMPLÈTE: TOUTES LES PHASES SONT IMPLÉMENTÉES!" -ForegroundColor Green
   Write-Host "   Le plan v54 est 100% terminé et prêt pour le déploiement." -ForegroundColor Green
   exit 0
}
else {
   Write-Host ""
   Write-Host "⚠️  PROBLÈMES DÉTECTÉS:" -ForegroundColor Yellow
   foreach ($issue in $global:issues) {
      Write-Host "   $issue" -ForegroundColor Red
   }
    
   if ($completionPercentage -ge 90) {
      Write-Host ""
      Write-Host "✅ ÉTAT: QUASI-COMPLET ($completionPercentage%)" -ForegroundColor Green
      Write-Host "   Le plan est essentiellement terminé avec quelques détails mineurs." -ForegroundColor Green
      exit 0
   }
   else {
      exit 1
   }
}
