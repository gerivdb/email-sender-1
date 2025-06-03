# Script de test robuste pour tous les fichiers consolidated
$consolidatedPath = "projet\roadmaps\plans\consolidated"
$successFiles = @()
$failedFiles = @()
$totalItems = 0

Write-Host "Test d'assimilation de tous les fichiers consolidated..." -ForegroundColor Green

Get-ChildItem -Path $consolidatedPath -Filter "*.md" | ForEach-Object {
   $fileName = $_.Name
   Write-Host "Testing: $fileName" -ForegroundColor Yellow
    
   $output = & ".\development\managers\roadmap-manager\roadmap-cli\roadmap-cli.exe" ingest-advanced $_.FullName --dry-run 2>&1
   if ($LASTEXITCODE -eq 0) {
      $successFiles += $fileName
      # Extract item count from output (convert array to string first)
      $outputString = $output -join "`n"
      if ($outputString -match "Total Items: (\d+)") {
         $itemCount = [int]$matches[1]
         $totalItems += $itemCount
         Write-Host "SUCCESS: $fileName ($itemCount items)" -ForegroundColor Green
      }
      else {
         Write-Host "SUCCESS: $fileName" -ForegroundColor Green
      }
   }
   else {
      $failedFiles += $fileName
      Write-Host "FAILED: $fileName" -ForegroundColor Red
      # Show first few lines of error for debugging
      if ($output) {
         $errorLines = ($output | Select-Object -First 3) -join "; "
         Write-Host "  Error: $errorLines" -ForegroundColor DarkRed
      }
   }
}

Write-Host ""
Write-Host "RESULTATS FINAUX:" -ForegroundColor Cyan
Write-Host "Fichiers reussis: $($successFiles.Count)" -ForegroundColor Green
Write-Host "Fichiers echoues: $($failedFiles.Count)" -ForegroundColor Red
Write-Host "Total items extraits: $totalItems" -ForegroundColor Yellow

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
if ($totalFiles -gt 0) {
   $successRate = [math]::Round(($successFiles.Count / $totalFiles) * 100, 2)
   Write-Host ""
   Write-Host "Taux de reussite: $successRate%" -ForegroundColor Cyan
}
