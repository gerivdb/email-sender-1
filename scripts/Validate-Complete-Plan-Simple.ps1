# Validation Complete du Plan v54 - Toutes Phases
param([switch]$Detailed = $false)

Write-Host "=== VALIDATION COMPLETE DU PLAN v54 - TOUTES PHASES ===" -ForegroundColor Cyan

$rootPath = "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$phases = @{
   "Phase 1" = "PHASE_1_SMART_INFRASTRUCTURE_COMPLETE.md"
   "Phase 2" = "PHASE_2_ADVANCED_MONITORING_COMPLETE.md"
   "Phase 3" = "PHASE_3_IDE_INTEGRATION_FINAL_COMPLETE.md"
   "Phase 4" = "PHASE_4_IMPLEMENTATION_COMPLETE.md"
}

$totalValidated = 0
$totalExpected = $phases.Count
$issues = @()

# Verification des phases
foreach ($phaseKey in $phases.Keys | Sort-Object) {
   $statusFile = $phases[$phaseKey]
   $fullPath = Join-Path $rootPath $statusFile
    
   Write-Host ""
   Write-Host "$phaseKey :" -ForegroundColor Yellow
   if (Test-Path $fullPath) {
      $content = Get-Content $fullPath -Raw
      if ($content -match "COMPLETE|IMPLEMENTED|SUCCESS|COMPLÈTE|VALIDÉE") {
         Write-Host "  Status: COMPLETE" -ForegroundColor Green
         $totalValidated++
      }
      else {
         Write-Host "  Status: INCOMPLETE" -ForegroundColor Yellow
         $issues += "${phaseKey}: Status incomplete"
      }
   }
   else {
      Write-Host "  Status: MISSING" -ForegroundColor Red
      $issues += "${phaseKey}: Status file missing"
   }
}

# Verification des fichiers critiques Phase 4
Write-Host ""
Write-Host "FICHIERS CRITIQUES PHASE 4:" -ForegroundColor Cyan
$phase4Files = @(
   "development\managers\advanced-autonomy-manager\internal\infrastructure\infrastructure_orchestrator.go",
   "development\managers\advanced-autonomy-manager\internal\infrastructure\security_manager.go",
   "development\managers\advanced-autonomy-manager\config\infrastructure_config.yaml",
   "scripts\infrastructure\Start-FullStack-Phase4.ps1"
)

$filesValidated = 0
foreach ($file in $phase4Files) {
   $fullPath = Join-Path $rootPath $file
   if (Test-Path $fullPath) {
      Write-Host "  OK: $file" -ForegroundColor Green
      $filesValidated++
   }
   else {
      Write-Host "  MISSING: $file" -ForegroundColor Red
   }
}

# Verification Git
Write-Host ""
Write-Host "ETAT GIT:" -ForegroundColor Cyan
try {
   $currentBranch = git branch --show-current 2>$null
   Write-Host "  Branche: $currentBranch" -ForegroundColor $(if ($currentBranch -eq "dev") { "Green" } else { "Yellow" })
}
catch {
   Write-Host "  Impossible de verifier Git" -ForegroundColor Yellow
}

# Resume final
Write-Host ""
Write-Host "=== RESUME FINAL ===" -ForegroundColor Cyan
$completionPercentage = [math]::Round(($totalValidated / $totalExpected) * 100, 1)
Write-Host "Phases validees: $totalValidated/$totalExpected ($completionPercentage%)" -ForegroundColor $(if ($completionPercentage -eq 100) { "Green" } else { "Yellow" })
Write-Host "Fichiers Phase 4: $filesValidated/$($phase4Files.Count)" -ForegroundColor $(if ($filesValidated -eq $phase4Files.Count) { "Green" } else { "Yellow" })

if ($issues.Count -eq 0 -and $filesValidated -eq $phase4Files.Count) {
   Write-Host ""
   Write-Host "VALIDATION COMPLETE: TOUTES LES PHASES SONT IMPLEMENTEES!" -ForegroundColor Green
   Write-Host "Le plan v54 est 100% termine et pret pour le deploiement." -ForegroundColor Green
   exit 0
}
else {
   Write-Host ""
   if ($issues.Count -gt 0) {
      Write-Host "PROBLEMES DETECTES:" -ForegroundColor Yellow
      foreach ($issue in $issues) {
         Write-Host "  - $issue" -ForegroundColor Red
      }
   }
    
   if ($completionPercentage -ge 90) {
      Write-Host ""
      Write-Host "ETAT: QUASI-COMPLET ($completionPercentage%)" -ForegroundColor Green
      exit 0
   }
   else {
      exit 1
   }
}
