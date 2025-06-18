#!/usr/bin/env powershell
# Debug simple pour extraire interfaces
Write-Host "🔍 EXTRACTION SIMPLE INTERFACES" -ForegroundColor Cyan

# Scanner patterns simples
$interfaces = Get-ChildItem -Recurse -Include '*.go' | Select-String -Pattern 'type.*interface' | Select-Object Filename, LineNumber, Line

Write-Host "Total trouvées: $($interfaces.Count)" -ForegroundColor Green

foreach ($i in $interfaces) {
   Write-Host "$($i.Filename):$($i.LineNumber) -> $($i.Line.Trim())" -ForegroundColor Yellow
}

Write-Host "✅ TERMINÉ" -ForegroundColor Green
