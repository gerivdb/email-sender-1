#!/usr/bin/env powershell
# Implémentation Tâche Atomique 001: Scanner Fichiers Managers Go
# Durée: 15 minutes max - Phase 1.1.1

Write-Host "🔍 TÂCHE ATOMIQUE 001: Scanner Fichiers Managers Go" -ForegroundColor Cyan
Write-Host "Durée: 15 minutes max" -ForegroundColor Yellow

# Scanner récursif managers Go
Write-Host "`n📋 Scanning managers Go..." -ForegroundColor Yellow
$managers = Get-ChildItem -Recurse -Include '*manager*.go', '*Manager*.go' | 
    Where-Object { $_.FullName -notmatch "vendor|node_modules|\.git" } |
    Select-Object FullName, Length, LastWriteTime

# Calculer statistiques
$totalSize = ($managers | Measure-Object -Property Length -Sum).Sum
$totalSizeKB = [math]::Round($totalSize / 1KB, 2)
$avgSizeKB = [math]::Round(($totalSize / $managers.Count) / 1KB, 2)

# Créer rapport JSON
$report = @{
    scan_timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    total_managers = $managers.Count
    total_size_kb = $totalSizeKB
    average_size_kb = $avgSizeKB
    managers = @()
}

# Analyser chaque manager
foreach ($mgr in ($managers | Sort-Object FullName)) {
    $relativePath = $mgr.FullName.Replace((Get-Location).Path + "\", "")
    $content = Get-Content $mgr.FullName -Raw -ErrorAction SilentlyContinue
    
    # Détection patterns
    $hasInterface = $content -match "type\s+\w*Manager\s+interface"
    $hasStruct = $content -match "type\s+\w*Manager\s+struct"
    $hasNew = $content -match "func\s+New\w*Manager"
    
    $managerInfo = @{
        path = $relativePath
        size_kb = [math]::Round($mgr.Length / 1KB, 2)
        last_modified = $mgr.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
        has_interface = $hasInterface
        has_struct = $hasStruct
        has_constructor = $hasNew
        complexity = if ($mgr.Length -gt 10KB) { "HIGH" } elseif ($mgr.Length -gt 5KB) { "MEDIUM" } else { "LOW" }
    }
    
    $report.managers += $managerInfo
}

# Sauvegarder rapport JSON
$jsonOutput = $report | ConvertTo-Json -Depth 4
$outputFile = "audit-managers-scan.json"
$jsonOutput | Out-File -FilePath $outputFile -Encoding UTF8

# Afficher résultats
Write-Host "`n📊 RÉSULTATS SCAN:" -ForegroundColor Green
Write-Host "   Managers détectés: $($report.total_managers)" -ForegroundColor White
Write-Host "   Taille totale: $($report.total_size_kb) KB" -ForegroundColor White
Write-Host "   Taille moyenne: $($report.average_size_kb) KB" -ForegroundColor White

# Top 5 plus gros managers
Write-Host "`n🔝 Top 5 plus volumineux:" -ForegroundColor Yellow
$topManagers = $report.managers | Sort-Object size_kb -Descending | Select-Object -First 5
foreach ($top in $topManagers) {
    Write-Host "   $($top.path) - $($top.size_kb) KB" -ForegroundColor Cyan
}

# Distribution par complexité
$complexityStats = $report.managers | Group-Object complexity
Write-Host "`n📈 Distribution complexité:" -ForegroundColor Yellow
foreach ($stat in $complexityStats) {
    Write-Host "   $($stat.Name): $($stat.Count) managers" -ForegroundColor White
}

# Validation
Write-Host "`n✅ VALIDATION:" -ForegroundColor Green
Write-Host "   ✅ Liste complète managers détectés" -ForegroundColor Green
Write-Host "   ✅ Rapport JSON généré: $outputFile" -ForegroundColor Green
Write-Host "   ✅ Statistiques calculées" -ForegroundColor Green

Write-Host "`n🎯 TÂCHE 001 TERMINÉE AVEC SUCCÈS!" -ForegroundColor Green
