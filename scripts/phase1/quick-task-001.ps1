#!/usr/bin/env powershell
# Quick generation Task 001 output file

Write-Host "🔍 Generating audit-managers-scan.json quickly..." -ForegroundColor Cyan

# Scanner managers rapidement
$managers = Get-ChildItem -Recurse -Include '*manager*.go', '*Manager*.go' | 
Where-Object { $_.FullName -notmatch "vendor|node_modules|\.git" }

$report = @{
   scan_timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
   total_managers = $managers.Count
   total_size_kb  = [math]::Round(($managers | Measure-Object -Property Length -Sum).Sum / 1KB, 2)
   branch         = git branch --show-current
   managers       = @()
}

foreach ($mgr in $managers) {
   $relativePath = $mgr.FullName.Replace((Get-Location).Path + "\", "")
   $report.managers += @{
      path          = $relativePath
      size_kb       = [math]::Round($mgr.Length / 1KB, 2)
      last_modified = $mgr.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
   }
}

# Créer output directory si nécessaire
$outputDir = "output/phase1"
if (-not (Test-Path $outputDir)) {
   New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

$outputFile = "$outputDir/audit-managers-scan.json"
$report | ConvertTo-Json -Depth 10 | Out-File -FilePath $outputFile -Encoding UTF8

Write-Host "✅ Generated: $outputFile" -ForegroundColor Green
Write-Host "📊 Managers found: $($managers.Count)" -ForegroundColor White
