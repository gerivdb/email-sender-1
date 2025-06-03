# Script de test pour tous les fichiers consolidated
$consolidatedPath = "projet\roadmaps\plans\consolidated"
$successFiles = @()
$failedFiles = @()

Write-Host "Test d'assimilation de tous les fichiers consolidated..." -ForegroundColor Green

Get-ChildItem -Path $consolidatedPath -Filter "*.md" | ForEach-Object {
   $fileName = $_.Name
   Write-Host "Testing: $fileName" -ForegroundColor Yellow
    
   & ".\development\managers\roadmap-manager\roadmap-cli\roadmap-cli.exe" ingest-advanced $_.FullName --dry-run 2>$null
    
   if ($LASTEXITCODE -eq 0) {
      $successFiles += $fileName
      Write-Host "SUCCESS: $fileName" -ForegroundColor Green
   }
   else {
      $failedFiles += $fileName
      Write-Host "FAILED: $fileName" -ForegroundColor Red
   }
}

Write-Host ""
Write-Host "RESULTATS FINAUX:" -ForegroundColor Cyan
Write-Host "Fichiers reussis: $($successFiles.Count)" -ForegroundColor Green
Write-Host "Fichiers echoues: $($failedFiles.Count)" -ForegroundColor Red

if ($successFiles.Count -gt 0) {
   Write-Host ""
   Write-Host "FICHIERS REUSSIS:" -ForegroundColor Green
   $successFiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor Green }
}

if ($failedFiles.Count -gt 0) {
   Write-Host ""
   Write-Host "FICHIERS ECHOUES:" -ForegroundColor Red  
   $failedFiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
}

$totalFiles = $successFiles.Count + $failedFiles.Count
$successRate = [math]::Round(($successFiles.Count / $totalFiles) * 100, 2)
Write-Host ""
Write-Host "Taux de reussite: $successRate%" -ForegroundColor Cyan
