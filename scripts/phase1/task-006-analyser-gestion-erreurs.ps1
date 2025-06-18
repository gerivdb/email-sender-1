#!/usr/bin/env powershell
# Implémentation Tâche Atomique 006: Analyser Gestion Erreurs
# Durée: 15 minutes max - Phase 1.1.2

Write-Host "🔍 TÂCHE ATOMIQUE 006: Analyser Gestion Erreurs" -ForegroundColor Cyan
Write-Host "Durée: 15 minutes max" -ForegroundColor Yellow

# Vérification branche
$currentBranch = git branch --show-current
Write-Host "📋 Branche active: $currentBranch" -ForegroundColor Green

# Scanner gestion des erreurs
Write-Host "`n📋 Scanning patterns de gestion d'erreurs..." -ForegroundColor Yellow

# Rechercher fichiers managers Go
$managerFiles = Get-ChildItem -Recurse -Include '*manager*.go', '*Manager*.go' | 
Where-Object { $_.FullName -notmatch "vendor|node_modules|\.git|_test\.go" }

Write-Host "📄 Fichiers managers trouvés: $($managerFiles.Count)" -ForegroundColor Green

# Patterns d'erreur à rechercher
$errorPatterns = @{
   "error_returns"  = @(
      'return.*error',
      'return.*fmt\.Errorf',
      'return.*errors\.New',
      'error.*nil'
   )
   "error_handling" = @(
      'if.*err\s*!=\s*nil',
      'if.*error\s*!=\s*nil',
      'err\s*:=',
      'error\s*:='
   )
   "error_wrapping" = @(
      'fmt\.Errorf',
      'errors\.Wrap',
      'errors\.WithMessage',
      'pkg/errors'
   )
   "error_types"    = @(
      'type.*Error\s+struct',
      'type.*error\s+interface',
      'Error\(\)\s+string'
   )
   "logging_errors" = @(
      'log\.Error',
      'logger\.Error',
      'zap\.Error',
      'logrus\.Error'
   )
   "panic_recovery" = @(
      'panic\(',
      'recover\(\)',
      'defer.*recover'
   )
}

$errorHandlingData = @()
$errorReport = @{
   scan_timestamp       = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
   branch               = $currentBranch
   total_manager_files  = $managerFiles.Count
   error_patterns_found = 0
   patterns_searched    = $errorPatterns.Keys.Count
   categories           = @{}
   error_patterns       = @()
}

Write-Host "🔍 Analyzing error handling patterns..." -ForegroundColor Yellow

foreach ($category in $errorPatterns.Keys) {
   Write-Host "  ⚠️  Scanning $category..." -ForegroundColor White
   $categoryMatches = @()
    
   foreach ($pattern in $errorPatterns[$category]) {
      $patternMatches = $managerFiles | Select-String -Pattern $pattern -Context 2
        
      foreach ($match in $patternMatches) {
         $relativePath = $match.Filename.Replace((Get-Location).Path + "\", "")
            
         # Lire contenu pour package et contexte étendu
         $content = Get-Content $match.Filename -Raw -ErrorAction SilentlyContinue
            
         # Déterminer le package
         $packageName = "unknown"
         if ($content -match "package\s+(\w+)") {
            $packageName = $Matches[1]
         }
            
         # Analyser le contexte avant et après
         $contextBefore = $match.Context.PreContext -join "`n"
         $contextAfter = $match.Context.PostContext -join "`n"
         $fullContext = "$contextBefore`n$($match.Line)`n$contextAfter"
            
         # Classifier le pattern d'erreur
         $errorStrategy = "unknown"
         if ($match.Line -match "return.*error") {
            $errorStrategy = "propagation"
         }
         elseif ($match.Line -match "if.*err.*!=.*nil") {
            $errorStrategy = "check_and_handle"
         }
         elseif ($match.Line -match "log.*Error|Error.*log") {
            $errorStrategy = "log_and_continue"
         }
         elseif ($match.Line -match "panic") {
            $errorStrategy = "panic_exit"
         }
         elseif ($match.Line -match "fmt\.Errorf|errors\.Wrap") {
            $errorStrategy = "wrap_and_propagate"
         }
            
         # Détecter la fonction contenant l'erreur
         $functionName = "unknown"
         $lines = $content -split "`n"
         for ($i = $match.LineNumber - 1; $i -ge 0; $i--) {
            if ($lines[$i] -match "func\s+(\w+)") {
               $functionName = $Matches[1]
               break
            }
         }
            
         $errorPattern = @{
            file            = $relativePath
            package         = $packageName
            function        = $functionName
            line_number     = $match.LineNumber
            category        = $category
            pattern_matched = $pattern
            error_strategy  = $errorStrategy
            line_content    = $match.Line.Trim()
            context_before  = $contextBefore.Trim()
            context_after   = $contextAfter.Trim()
            full_context    = $fullContext.Trim()
            severity        = if ($match.Line -match "panic") { "HIGH" } elseif ($match.Line -match "return.*error") { "MEDIUM" } else { "LOW" }
         }
            
         $categoryMatches += $errorPattern
         $errorHandlingData += $errorPattern
         $errorReport.error_patterns += $errorPattern
      }
   }
    
   $errorReport.categories[$category] = @{
      count           = $categoryMatches.Count
      files           = ($categoryMatches | Select-Object -Property file -Unique).Count
      patterns        = $errorPatterns[$category].Count
      high_severity   = ($categoryMatches | Where-Object { $_.severity -eq "HIGH" }).Count
      medium_severity = ($categoryMatches | Where-Object { $_.severity -eq "MEDIUM" }).Count
      low_severity    = ($categoryMatches | Where-Object { $_.severity -eq "LOW" }).Count
   }
}

$errorReport.error_patterns_found = $errorHandlingData.Count

# Générer le rapport Markdown
$markdownContent = @"
# Gestion des Erreurs - Analyse des Patterns

**Date de scan**: $($errorReport.scan_timestamp)  
**Branche**: $($errorReport.branch)  
**Fichiers managers scannés**: $($errorReport.total_manager_files)  
**Patterns d'erreur trouvés**: $($errorReport.error_patterns_found)  
**Catégories analysées**: $($errorReport.patterns_searched)

## 📊 Vue d'Ensemble par Catégorie

"@

foreach ($category in ($errorReport.categories.Keys | Sort-Object)) {
   $catData = $errorReport.categories[$category]
   $percentage = if ($errorReport.error_patterns_found -gt 0) {
      [math]::Round(($catData.count / $errorReport.error_patterns_found) * 100, 1)
   }
   else { 0 }
    
   $markdownContent += @"
### ⚠️ $($category.ToUpper())

- **Occurrences**: $($catData.count) ($percentage%)
- **Fichiers concernés**: $($catData.files)
- **Sévérité HIGH**: $($catData.high_severity)
- **Sévérité MEDIUM**: $($catData.medium_severity)
- **Sévérité LOW**: $($catData.low_severity)

"@
}

$markdownContent += @"

## 🔍 Stratégies d'Erreur Identifiées

"@

# Grouper par stratégie d'erreur
$strategiesByType = $errorHandlingData | Group-Object -Property error_strategy | Sort-Object Count -Descending

foreach ($strategyGroup in $strategiesByType) {
   $markdownContent += @"

### 🎯 Stratégie: $($strategyGroup.Name.ToUpper()) ($($strategyGroup.Count) occurrences)

"@
    
   # Prendre les 3 premiers exemples
   $examples = $strategyGroup.Group | Select-Object -First 3
   foreach ($example in $examples) {
      $markdownContent += @"

#### 📄 ``$($example.file)`` - Fonction: ``$($example.function)`` (Ligne $($example.line_number))

``````go
// Contexte avant
$($example.context_before)

// Pattern détecté
$($example.line_content)

// Contexte après  
$($example.context_after)
``````

"@
   }
}

$markdownContent += @"

## 📈 Analyse par Fichier Manager

"@

# Grouper par fichier
$errorsByFile = $errorHandlingData | Group-Object -Property file | Sort-Object Count -Descending

foreach ($fileGroup in ($errorsByFile | Select-Object -First 10)) {
   $strategiesInFile = $fileGroup.Group | Group-Object -Property error_strategy
   $strategySummary = $strategiesInFile | ForEach-Object { "$($_.Name)($($_.Count))" }
    
   $markdownContent += @"

### 📄 ``$($fileGroup.Name)`` ($($fileGroup.Count) patterns)

- **Package**: $($fileGroup.Group[0].package)
- **Stratégies utilisées**: $($strategySummary -join ', ')
- **Sévérité**: HIGH: $(($fileGroup.Group | Where-Object severity -EQ 'HIGH').Count), MEDIUM: $(($fileGroup.Group | Where-Object severity -EQ 'MEDIUM').Count), LOW: $(($fileGroup.Group | Where-Object severity -EQ 'LOW').Count)

"@
}

# Analyse des problèmes potentiels
$highSeverityErrors = $errorHandlingData | Where-Object { $_.severity -eq "HIGH" }
$inconsistentStrategies = $errorsByFile | Where-Object { ($_.Group | Group-Object -Property error_strategy).Count -gt 2 }

$markdownContent += @"

## 🚨 Problèmes Potentiels Détectés

### Erreurs de Haute Sévérité ($($highSeverityErrors.Count))
"@

if ($highSeverityErrors.Count -gt 0) {
   foreach ($highError in ($highSeverityErrors | Select-Object -First 5)) {
      $markdownContent += "`n- **$($highError.file):$($highError.line_number)** - $($highError.line_content)"
   }
}
else {
   $markdownContent += "`n- Aucune erreur de haute sévérité détectée ✅"
}

$markdownContent += @"

### Stratégies Incohérentes par Fichier ($($inconsistentStrategies.Count))
"@

if ($inconsistentStrategies.Count -gt 0) {
   foreach ($inconsistent in ($inconsistentStrategies | Select-Object -First 5)) {
      $strategies = ($inconsistent.Group | Group-Object -Property error_strategy).Name -join ', '
      $markdownContent += "`n- **$($inconsistent.Name)**: $strategies"
   }
}
else {
   $markdownContent += "`n- Stratégies cohérentes dans tous les fichiers ✅"
}

$markdownContent += @"

## 🔄 Recommandations

### Standards à Implémenter
1. **Standardiser le wrapping d'erreurs** avec `fmt.Errorf` ou `pkg/errors`
2. **Centraliser le logging des erreurs** avec un logger unifié
3. **Éviter les panics** en faveur de la propagation d'erreurs
4. **Implémenter des types d'erreur custom** pour les erreurs métier
5. **Ajouter des tests d'erreur** pour chaque fonction critique

### Patterns Recommandés
- Utiliser `if err != nil { return fmt.Errorf("context: %w", err) }`
- Logger les erreurs au niveau approprié (Error, Warn, Info)
- Implémenter des circuit breakers pour les appels externes
- Utiliser des timeout contexts pour éviter les blocages

---
*Généré par Tâche Atomique 006 - $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")*
"@

# Créer répertoire de sortie
$outputDir = "output/phase1"
if (-not (Test-Path $outputDir)) {
   New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

$markdownPath = "$outputDir/error-handling-patterns.md"
$jsonPath = "$outputDir/error-handling-patterns.json"

# Sauvegarder Markdown
$markdownContent | Out-File -FilePath $markdownPath -Encoding UTF8

# Sauvegarder JSON
$errorReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonPath -Encoding UTF8

# Affichage résultat
Write-Host "`n✅ RÉSULTATS:" -ForegroundColor Green
Write-Host "📊 Patterns d'erreur trouvés: $($errorHandlingData.Count)" -ForegroundColor White
Write-Host "📋 Fichiers managers scannés: $($managerFiles.Count)" -ForegroundColor White
Write-Host "📦 Catégories analysées: $($errorPatterns.Keys.Count)" -ForegroundColor White
Write-Host "🚨 Erreurs haute sévérité: $($highSeverityErrors.Count)" -ForegroundColor White
Write-Host "📄 Rapport Markdown: $markdownPath" -ForegroundColor Cyan
Write-Host "📄 Rapport JSON: $jsonPath" -ForegroundColor Cyan

# TOP stratégies
Write-Host "`n🏆 TOP 3 Stratégies d'erreur:" -ForegroundColor Magenta
foreach ($strategy in ($strategiesByType | Select-Object -First 3)) {
   Write-Host "  - $($strategy.Name): $($strategy.Count) occurrences" -ForegroundColor White
}

# Validation finale
if ($errorHandlingData.Count -gt 0) {
   Write-Host "`n✅ Tâche Atomique 006 COMPLÉTÉE avec succès!" -ForegroundColor Green
   Write-Host "📋 Stratégies d'erreur documentées" -ForegroundColor Green
}
else {
   Write-Host "`n⚠️  Aucun pattern d'erreur trouvé - Vérifiez les patterns de recherche" -ForegroundColor Yellow
}

Write-Host "`n🎯 Phase 1.1.2 COMPLÈTE - Prêt pour Phase 1.1.3!" -ForegroundColor Magenta
