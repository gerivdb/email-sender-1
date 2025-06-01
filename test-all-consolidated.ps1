# Script de test pour tous les fichiers consolidated
$consolidatedPath = "projet\roadmaps\plans\consolidated"
$successFiles = @()
$failedFiles = @()

Write-Host "🚀 Test d'assimilation de tous les fichiers consolidated..." -ForegroundColor Green

Get-ChildItem -Path $consolidatedPath -Filter "*.md" | ForEach-Object {
   $fileName = $_.Name
   Write-Host "Testing: $fileName" -ForegroundColor Yellow
    
   try {
      $result = & ".\cmd\roadmap-cli\roadmap-cli.exe" ingest-advanced $_.FullName --dry-run 2>&1
        
      if ($LASTEXITCODE -eq 0) {
         $successFiles += $fileName
         Write-Host "✅ SUCCESS: $fileName" -ForegroundColor Green
      }
      else {
         $failedFiles += $fileName
         Write-Host "❌ FAILED: $fileName" -ForegroundColor Red
      }
   }
   catch {
      $failedFiles += $fileName
      Write-Host "❌ ERROR: $fileName - $($_.Exception.Message)" -ForegroundColor Red
   }
}

Write-Host "`n📊 RÉSULTATS FINAUX:" -ForegroundColor Cyan
Write-Host "✅ Fichiers réussis: $($successFiles.Count)" -ForegroundColor Green
Write-Host "❌ Fichiers échoués: $($failedFiles.Count)" -ForegroundColor Red

if ($successFiles.Count -gt 0) {
   Write-Host "`n✅ FICHIERS RÉUSSIS:" -ForegroundColor Green
   $successFiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor Green }
}

if ($failedFiles.Count -gt 0) {
   Write-Host "`n❌ FICHIERS ÉCHOUÉS:" -ForegroundColor Red  
   $failedFiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
}

$totalFiles = $successFiles.Count + $failedFiles.Count
$successRate = [math]::Round(($successFiles.Count / $totalFiles) * 100, 2)
Write-Host "`n🎯 Taux de réussite: $successRate%" -ForegroundColor Cyan
