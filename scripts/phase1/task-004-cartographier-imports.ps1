#!/usr/bin/env powershell
# Implémentation Tâche Atomique 004: Cartographier Imports Managers
# Durée: 15 minutes max - Phase 1.1.2

Write-Host "🔍 TÂCHE ATOMIQUE 004: Cartographier Imports Managers" -ForegroundColor Cyan
Write-Host "Durée: 15 minutes max" -ForegroundColor Yellow

# Vérification branche
$currentBranch = git branch --show-current
Write-Host "📋 Branche active: $currentBranch" -ForegroundColor Green

# Scanner imports dans les fichiers managers
Write-Host "`n📋 Scanning imports dans managers..." -ForegroundColor Yellow

# Rechercher fichiers managers Go
$managerFiles = Get-ChildItem -Recurse -Include '*manager*.go', '*Manager*.go' | 
Where-Object { $_.FullName -notmatch "vendor|node_modules|\.git|_test\.go" }

Write-Host "📄 Fichiers managers trouvés: $($managerFiles.Count)" -ForegroundColor Green

$importsData = @()
$dependenciesReport = @{
   scan_timestamp      = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
   branch              = $currentBranch
   total_manager_files = $managerFiles.Count
   total_imports       = 0
   unique_packages     = @()
   dependencies        = @()
}

Write-Host "🔍 Analysing imports..." -ForegroundColor Yellow

foreach ($file in $managerFiles) {
   $relativePath = $file.FullName.Replace((Get-Location).Path + "\", "")
   $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    
   if (-not $content) { continue }
    
   # Extraire package name
   $packageName = "unknown"
   if ($content -match "package\s+(\w+)") {
      $packageName = $matches[1]
   }
    
   # Extraire imports (multiline avec parentheses)
   $importMatches = @()
    
   # Pattern pour import simple: import "package"
   $singleImports = [regex]::Matches($content, 'import\s+"([^"]+)"')
   foreach ($match in $singleImports) {
      $importMatches += $match.Groups[1].Value
   }
    
   # Pattern pour import groupé: import ( ... )
   $groupImportPattern = 'import\s*\(\s*([^)]+)\s*\)'
   $groupMatch = [regex]::Match($content, $groupImportPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    
   if ($groupMatch.Success) {
      $importBlock = $groupMatch.Groups[1].Value
      $importLines = $importBlock -split "`n" | ForEach-Object { $_.Trim() }
        
      foreach ($line in $importLines) {
         if ($line -match '"([^"]+)"') {
            $importMatches += $matches[1]
         }
      }
   }
    
   # Classifier les imports
   $localImports = @()
   $standardImports = @()
   $thirdPartyImports = @()
    
   foreach ($import in $importMatches) {
      if ($import -match "^(fmt|os|io|net|time|context|strings|strconv|sync|log)") {
         $standardImports += $import
      }
      elseif ($import -match "^github\.com|^golang\.org|^gopkg\.in") {
         $thirdPartyImports += $import
      }
      else {
         $localImports += $import
      }
   }
    
   $fileImportData = @{
      file                = $relativePath
      package             = $packageName
      total_imports       = $importMatches.Count
      standard_imports    = @($standardImports)
      third_party_imports = @($thirdPartyImports)
      local_imports       = @($localImports)
      standard_count      = $standardImports.Count
      third_party_count   = $thirdPartyImports.Count
      local_count         = $localImports.Count
   }
    
   $importsData += $fileImportData
   $dependenciesReport.dependencies += $fileImportData
   $dependenciesReport.total_imports += $importMatches.Count
}

# Calculer statistiques globales
$allImports = $importsData | ForEach-Object { $_.standard_imports + $_.third_party_imports + $_.local_imports } | Sort-Object -Unique
$dependenciesReport.unique_packages = @($allImports)

# Identifier imports les plus fréquents
$importFrequency = @{}
foreach ($data in $importsData) {
   foreach ($import in ($data.standard_imports + $data.third_party_imports + $data.local_imports)) {
      if ($importFrequency.ContainsKey($import)) {
         $importFrequency[$import]++
      }
      else {
         $importFrequency[$import] = 1
      }
   }
}

$topImports = $importFrequency.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 10

# Générer le rapport Markdown
$markdownContent = @"
# Dependencies Map - Imports Managers

**Date de scan**: $($dependenciesReport.scan_timestamp)  
**Branche**: $($dependenciesReport.branch)  
**Fichiers managers scannés**: $($dependenciesReport.total_manager_files)  
**Total imports**: $($dependenciesReport.total_imports)  
**Packages uniques**: $($allImports.Count)

## 📋 Vue d'Ensemble des Dépendances

### TOP 10 Imports les Plus Utilisés

"@

foreach ($topImport in $topImports) {
   $markdownContent += "- ``$($topImport.Key)``: $($topImport.Value) fichiers`n"
}

$markdownContent += @"

## 📦 Analyse par Fichier Manager

"@

foreach ($data in ($importsData | Sort-Object file)) {
   $markdownContent += @"

### ``$($data.file)``

- **Package**: $($data.package)
- **Total imports**: $($data.total_imports)
- **Standard**: $($data.standard_count)
- **Third-party**: $($data.third_party_count) 
- **Local**: $($data.local_count)

#### Standard Library
$(if ($data.standard_imports) { ($data.standard_imports | ForEach-Object { "- ``$_``" }) -join "`n" } else { "- Aucun import standard" })

#### Third-Party Dependencies  
$(if ($data.third_party_imports) { ($data.third_party_imports | ForEach-Object { "- ``$_``" }) -join "`n" } else { "- Aucune dépendance externe" })

#### Local Dependencies
$(if ($data.local_imports) { ($data.local_imports | ForEach-Object { "- ``$_``" }) -join "`n" } else { "- Aucune dépendance locale" })

"@
}

# Statistiques par catégorie
$totalStandard = ($importsData | Measure-Object -Property standard_count -Sum).Sum
$totalThirdParty = ($importsData | Measure-Object -Property third_party_count -Sum).Sum  
$totalLocal = ($importsData | Measure-Object -Property local_count -Sum).Sum

$markdownContent += @"

## 📊 Statistiques Globales

### Répartition par Type d'Import

- **Standard Library**: $totalStandard imports ($([math]::Round($totalStandard / $dependenciesReport.total_imports * 100, 1))%)
- **Third-Party**: $totalThirdParty imports ($([math]::Round($totalThirdParty / $dependenciesReport.total_imports * 100, 1))%)
- **Local**: $totalLocal imports ($([math]::Round($totalLocal / $dependenciesReport.total_imports * 100, 1))%)

### Complexité par Fichier

"@

$complexFiles = $importsData | Sort-Object -Property total_imports -Descending | Select-Object -First 5
foreach ($complex in $complexFiles) {
   $markdownContent += "- ``$($complex.file)``: $($complex.total_imports) imports`n"
}

$markdownContent += @"

### Dépendances Communes (utilisées dans >2 fichiers)

"@

$commonDeps = $importFrequency.GetEnumerator() | Where-Object { $_.Value -gt 2 } | Sort-Object -Property Value -Descending
foreach ($common in $commonDeps) {
   $markdownContent += "- ``$($common.Key)``: $($common.Value) fichiers`n"
}

$markdownContent += @"

---
*Généré par Tâche Atomique 004 - $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")*
"@

# Créer répertoire de sortie
$outputDir = "output/phase1"
if (-not (Test-Path $outputDir)) {
   New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

$jsonPath = "$outputDir/dependencies-map.json"
$markdownPath = "$outputDir/dependencies-map.md"
$dotPath = "$outputDir/dependencies-map.dot"

# Sauvegarder JSON
$dependenciesReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonPath -Encoding UTF8

# Sauvegarder Markdown
$markdownContent | Out-File -FilePath $markdownPath -Encoding UTF8

# Générer fichier DOT pour graphe de dépendances
$dotContent = @"
digraph DependencyGraph {
    rankdir=LR;
    node [shape=box, style=rounded];
    
    // Fichiers managers
"@

foreach ($data in $importsData) {
   $fileName = [System.IO.Path]::GetFileNameWithoutExtension($data.file)
   $dotContent += "    `"$fileName`" [color=blue];`n"
    
   # Ajouter les dépendances importantes (non-standard)
   foreach ($dep in $data.third_party_imports) {
      $depName = $dep -replace "[/\.]", "_"
      $dotContent += "    `"$depName`" [color=red, shape=ellipse];`n"
      $dotContent += "    `"$fileName`" -> `"$depName`";`n"
   }
}

$dotContent += "}"
$dotContent | Out-File -FilePath $dotPath -Encoding UTF8

# Affichage résultat
Write-Host "`n✅ RÉSULTATS:" -ForegroundColor Green
Write-Host "📊 Imports totaux: $($dependenciesReport.total_imports)" -ForegroundColor White
Write-Host "📋 Fichiers scannés: $($dependenciesReport.total_manager_files)" -ForegroundColor White
Write-Host "📦 Packages uniques: $($allImports.Count)" -ForegroundColor White
Write-Host "📄 Rapport JSON: $jsonPath" -ForegroundColor Cyan
Write-Host "📄 Rapport Markdown: $markdownPath" -ForegroundColor Cyan
Write-Host "📄 Graphe DOT: $dotPath" -ForegroundColor Cyan

# TOP imports
Write-Host "`n🏆 TOP 5 Imports les plus utilisés:" -ForegroundColor Magenta
foreach ($top in ($topImports | Select-Object -First 5)) {
   Write-Host "  - $($top.Key): $($top.Value) fichiers" -ForegroundColor White
}

# Validation finale
if ($importsData.Count -gt 0) {
   Write-Host "`n✅ Tâche Atomique 004 COMPLÉTÉE avec succès!" -ForegroundColor Green
   Write-Host "📋 Graphe dépendances complet" -ForegroundColor Green
}
else {
   Write-Host "`n⚠️  Aucun import trouvé - Vérifiez les fichiers managers" -ForegroundColor Yellow
}

Write-Host "`n🎯 Prochaine étape: Tâche Atomique 005 - Identifier Points Communication" -ForegroundColor Magenta
