#!/usr/bin/env powershell
# Implémentation Tâche Atomique 005: Identifier Points Communication
# Durée: 15 minutes max - Phase 1.1.2

Write-Host "🔍 TÂCHE ATOMIQUE 005: Identifier Points Communication" -ForegroundColor Cyan
Write-Host "Durée: 15 minutes max" -ForegroundColor Yellow

# Vérification branche
$currentBranch = git branch --show-current
Write-Host "📋 Branche active: $currentBranch" -ForegroundColor Green

# Scanner points de communication
Write-Host "`n📋 Scanning points de communication..." -ForegroundColor Yellow

# Rechercher fichiers Go (managers et autres)
$goFiles = Get-ChildItem -Recurse -Include '*.go' | 
Where-Object { $_.FullName -notmatch "vendor|node_modules|\.git|_test\.go" }

Write-Host "📄 Fichiers Go trouvés: $($goFiles.Count)" -ForegroundColor Green

# Patterns de communication à rechercher
$communicationPatterns = @{
   "channels"       = @(
      'make\s*\(\s*chan\s+',
      'chan\s+\w+',
      '<-\s*\w+',
      '\w+\s*<-'
   )
   "http_endpoints" = @(
      'http\.Handle',
      'http\.HandleFunc',
      'gin\.\w+\(',
      'router\.\w+\(',
      'mux\.\w+\(',
      '\.POST\(',
      '\.GET\(',
      '\.PUT\(',
      '\.DELETE\('
   )
   "redis_pubsub"   = @(
      'redis\.Publish',
      'redis\.Subscribe',
      'redis\.PSubscribe',
      'pubsub\.',
      'PUBLISH',
      'SUBSCRIBE'
   )
   "grpc_calls"     = @(
      'grpc\.',
      '\.pb\.go',
      'protobuf',
      'rpc\s+\w+\('
   )
   "websockets"     = @(
      'websocket\.',
      'gorilla/websocket',
      'ws\.',
      'WebSocket'
   )
   "message_queues" = @(
      'rabbitmq',
      'amqp\.',
      'kafka',
      'nats\.',
      'queue\.'
   )
}

$communicationPoints = @()
$communicationReport = @{
   scan_timestamp             = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
   branch                     = $currentBranch
   total_files_scanned        = $goFiles.Count
   communication_points_found = 0
   patterns_searched          = $communicationPatterns.Keys.Count
   categories                 = @{}
   communication_points       = @()
}

Write-Host "🔍 Searching communication patterns..." -ForegroundColor Yellow

foreach ($category in $communicationPatterns.Keys) {
   Write-Host "  📡 Scanning $category..." -ForegroundColor White
   $categoryMatches = @()
   foreach ($pattern in $communicationPatterns[$category]) {
      $patternMatches = $goFiles | Select-String -Pattern $pattern
        
      foreach ($match in $patternMatches) {
         $relativePath = $match.Filename.Replace((Get-Location).Path + "\", "")
            
         # Extraire contexte autour de la ligne
         $content = Get-Content $match.Filename -Raw -ErrorAction SilentlyContinue
         $lines = $content -split "`n"
         $contextStart = [Math]::Max(0, $match.LineNumber - 3)
         $contextEnd = [Math]::Min($lines.Count - 1, $match.LineNumber + 2)
         $context = $lines[$contextStart..$contextEnd] -join "`n"            # Déterminer le package
         $packageName = "unknown"
         if ($content -match "package\s+(\w+)") {
            $packageName = $Matches[1]
         }
            
         # Analyser le type de communication plus précisément
         $commType = $category
         $direction = "bidirectional"
            
         if ($match.Line -match "\.GET\(|\.POST\(|\.PUT\(|\.DELETE\(") {
            $direction = "inbound"
         }
         elseif ($match.Line -match "http\.Client|http\.Get|http\.Post") {
            $direction = "outbound"
         }
         elseif ($match.Line -match "<-") {
            $direction = "receive"
         }
         elseif ($match.Line -match "->") {
            $direction = "send"
         }
            
         $commPoint = @{
            file               = $relativePath
            package            = $packageName
            line_number        = $match.LineNumber
            category           = $category
            pattern_matched    = $pattern
            communication_type = $commType
            direction          = $direction
            line_content       = $match.Line.Trim()
            context            = $context.Trim()
            is_manager_file    = $relativePath -match "manager"
         }
            
         $categoryMatches += $commPoint
         $communicationPoints += $commPoint
         $communicationReport.communication_points += $commPoint
      }
   }
    
   $communicationReport.categories[$category] = @{
      count    = $categoryMatches.Count
      files    = ($categoryMatches | Select-Object -Property file -Unique).Count
      patterns = $communicationPatterns[$category].Count
   }
}

$communicationReport.communication_points_found = $communicationPoints.Count

# Générer le rapport YAML et Markdown
$yamlContent = @"
# Points de Communication - Analyse Système
scan_info:
  timestamp: $($communicationReport.scan_timestamp)
  branch: $($communicationReport.branch)
  files_scanned: $($communicationReport.total_files_scanned)
  total_points: $($communicationReport.communication_points_found)

categories:
"@

foreach ($category in $communicationReport.categories.Keys) {
   $catData = $communicationReport.categories[$category]
   $yamlContent += @"

  ${category}:
    count: $($catData.count)
    unique_files: $($catData.files)
    patterns_used: $($catData.patterns)
"@
}

$yamlContent += @"

communication_points:
"@

# Grouper par catégorie pour le YAML
$pointsByCategory = $communicationPoints | Group-Object -Property category

foreach ($categoryGroup in $pointsByCategory) {
   $yamlContent += "`n  $($categoryGroup.Name):"
   foreach ($point in $categoryGroup.Group) {
      $yamlContent += @"

    - file: "$($point.file)"
      package: "$($point.package)"
      line: $($point.line_number)
      type: "$($point.communication_type)"
      direction: "$($point.direction)"
      pattern: "$($point.pattern_matched)"
      content: "$($point.line_content -replace '"', '\"')"
      is_manager: $($point.is_manager_file.ToString().ToLower())
"@
   }
}

# Générer rapport Markdown
$markdownContent = @"
# Points de Communication - Analyse Système

**Date de scan**: $($communicationReport.scan_timestamp)  
**Branche**: $($communicationReport.branch)  
**Fichiers scannés**: $($communicationReport.total_files_scanned)  
**Points trouvés**: $($communicationReport.communication_points_found)

## 📊 Vue d'Ensemble par Catégorie

"@

foreach ($category in ($communicationReport.categories.Keys | Sort-Object)) {
   $catData = $communicationReport.categories[$category]
   $percentage = if ($communicationReport.communication_points_found -gt 0) {
      [math]::Round(($catData.count / $communicationReport.communication_points_found) * 100, 1)
   }
   else { 0 }
    
   $markdownContent += @"
### 📡 $($category.ToUpper())

- **Points trouvés**: $($catData.count) ($percentage%)
- **Fichiers concernés**: $($catData.files)
- **Patterns recherchés**: $($catData.patterns)

"@
}

$markdownContent += @"

## 🔍 Détail par Catégorie

"@

foreach ($categoryGroup in ($pointsByCategory | Sort-Object Name)) {
   $markdownContent += "`n### 📡 $($categoryGroup.Name.ToUpper())`n"
    
   # Grouper par fichier dans cette catégorie
   $fileGroups = $categoryGroup.Group | Group-Object -Property file | Sort-Object Name
    
   foreach ($fileGroup in $fileGroups) {
      $markdownContent += "`n#### 📄 ``$($fileGroup.Name)```n"
        
      foreach ($point in ($fileGroup.Group | Sort-Object line_number)) {
         $markdownContent += @"

**Ligne $($point.line_number)** - $($point.direction) - Package: $($point.package)

``````go
$($point.line_content)
``````

"@
      }
   }
}

# Statistiques par manager vs non-manager
$managerPoints = $communicationPoints | Where-Object { $_.is_manager_file }
$nonManagerPoints = $communicationPoints | Where-Object { -not $_.is_manager_file }

$markdownContent += @"

## 🏗️ Répartition Manager vs Non-Manager

### Fichiers Managers
- **Points de communication**: $($managerPoints.Count)
- **Fichiers concernés**: $(($managerPoints | Select-Object file -Unique).Count)

### Fichiers Non-Managers  
- **Points de communication**: $($nonManagerPoints.Count)
- **Fichiers concernés**: $(($nonManagerPoints | Select-Object file -Unique).Count)

## 📈 TOP 5 Fichiers avec le Plus de Points

"@

$topFiles = $communicationPoints | Group-Object -Property file | 
Sort-Object Count -Descending | Select-Object -First 5

foreach ($topFile in $topFiles) {
   $markdownContent += "- ``$($topFile.Name)``: $($topFile.Count) points`n"
}

$markdownContent += @"

## 🔄 Recommandations

### Patterns de Communication Détectés
"@

foreach ($categoryGroup in ($pointsByCategory | Sort-Object Count -Descending)) {
   $markdownContent += "`n- **$($categoryGroup.Name)**: $($categoryGroup.Count) occurrences"
}

$markdownContent += @"

### Actions Recommandées
- Centraliser la gestion des channels dans un manager dédié
- Standardiser les patterns HTTP avec middleware unifié
- Implémenter circuit breakers pour les appels externes
- Ajouter monitoring sur tous les points de communication

---
*Généré par Tâche Atomique 005 - $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")*
"@

# Créer répertoire de sortie
$outputDir = "output/phase1"
if (-not (Test-Path $outputDir)) {
   New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

$yamlPath = "$outputDir/communication-points.yaml"
$markdownPath = "$outputDir/communication-points.md"
$jsonPath = "$outputDir/communication-points.json"

# Sauvegarder YAML
$yamlContent | Out-File -FilePath $yamlPath -Encoding UTF8

# Sauvegarder Markdown
$markdownContent | Out-File -FilePath $markdownPath -Encoding UTF8

# Sauvegarder JSON
$communicationReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonPath -Encoding UTF8

# Affichage résultat
Write-Host "`n✅ RÉSULTATS:" -ForegroundColor Green
Write-Host "📊 Points communication trouvés: $($communicationPoints.Count)" -ForegroundColor White
Write-Host "📋 Fichiers scannés: $($goFiles.Count)" -ForegroundColor White
Write-Host "📦 Catégories analysées: $($communicationPatterns.Keys.Count)" -ForegroundColor White
Write-Host "🏗️  Points dans managers: $($managerPoints.Count)" -ForegroundColor White
Write-Host "📄 Rapport YAML: $yamlPath" -ForegroundColor Cyan
Write-Host "📄 Rapport Markdown: $markdownPath" -ForegroundColor Cyan  
Write-Host "📄 Rapport JSON: $jsonPath" -ForegroundColor Cyan

# TOP catégories
Write-Host "`n🏆 TOP 3 Catégories de communication:" -ForegroundColor Magenta
$topCategories = $communicationReport.categories.GetEnumerator() | 
Sort-Object -Property { $_.Value.count } -Descending | Select-Object -First 3
    
foreach ($topCat in $topCategories) {
   Write-Host "  - $($topCat.Key): $($topCat.Value.count) points" -ForegroundColor White
}

# Validation finale
if ($communicationPoints.Count -gt 0) {
   Write-Host "`n✅ Tâche Atomique 005 COMPLÉTÉE avec succès!" -ForegroundColor Green
   Write-Host "📋 Tous points d'échange répertoriés" -ForegroundColor Green
}
else {
   Write-Host "`n⚠️  Aucun point de communication trouvé - Vérifiez les patterns" -ForegroundColor Yellow
}

Write-Host "`n🎯 Prochaine étape: Tâche Atomique 006 - Analyser Gestion Erreurs" -ForegroundColor Magenta
