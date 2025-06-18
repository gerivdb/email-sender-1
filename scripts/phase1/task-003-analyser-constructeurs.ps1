#!/usr/bin/env powershell
# Implémentation Tâche Atomique 003: Analyser Patterns Constructeurs
# Durée: 15 minutes max - Phase 1.1.1

Write-Host "🔍 TÂCHE ATOMIQUE 003: Analyser Patterns Constructeurs" -ForegroundColor Cyan
Write-Host "Durée: 15 minutes max" -ForegroundColor Yellow

# Vérification branche
$currentBranch = git branch --show-current
Write-Host "📋 Branche active: $currentBranch" -ForegroundColor Green

# Scanner patterns de constructeurs
Write-Host "`n📋 Scanning patterns constructeurs..." -ForegroundColor Yellow

# Rechercher fichiers Go
$goFiles = Get-ChildItem -Recurse -Include '*.go' | 
Where-Object { $_.FullName -notmatch "vendor|node_modules|\.git|_test\.go" }

Write-Host "📄 Fichiers Go trouvés: $($goFiles.Count)" -ForegroundColor Green

# Patterns de constructeurs à rechercher
$constructorPatterns = @(
   'func\s+New\w*Manager\w*\s*\(',
   'func\s+Create\w*Manager\w*\s*\(',
   'func\s+New\w*Client\w*\s*\(',
   'func\s+New\w*Service\w*\s*\(',
   'func\s+New\w*Handler\w*\s*\(',
   'func\s+Init\w*\s*\(',
   'func\s+Setup\w*\s*\('
)

$constructors = @()
$constructorReport = @{
   scan_timestamp      = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
   branch              = $currentBranch
   total_files_scanned = $goFiles.Count
   constructors_found  = 0
   patterns_searched   = $constructorPatterns.Count
   constructors        = @()
}

Write-Host "🔍 Searching constructors avec $($constructorPatterns.Count) patterns..." -ForegroundColor Yellow

foreach ($pattern in $constructorPatterns) {
   $patternMatches = $goFiles | Select-String -Pattern $pattern
    
   foreach ($match in $patternMatches) {
      $relativePath = $match.Filename.Replace((Get-Location).Path + "\", "")
        
      # Extraire le nom de la fonction
      if ($match.Line -match 'func\s+([\w]+)\s*\(') {
         $functionName = $matches[1]
            
         # Lire contenu pour plus de détails
         $content = Get-Content $match.Filename -Raw -ErrorAction SilentlyContinue
         $packageName = "unknown"
            
         if ($content -match "package\s+(\w+)") {
            $packageName = $matches[1]
         }
            
         # Analyser la signature de la fonction
         $signature = $match.Line.Trim()
            
         # Détecter le type retourné
         $returnType = "unknown"
         if ($signature -match '\)\s*(\*?\w+)') {
            $returnType = $matches[1]
         }
         elseif ($signature -match '\)\s*\(([^)]+)\)') {
            $returnType = $matches[1]
         }
            
         # Classifier le pattern
         $patternType = "Unknown"
         if ($functionName -match "^New") { $patternType = "Factory" }
         elseif ($functionName -match "^Create") { $patternType = "Creator" }
         elseif ($functionName -match "^Init") { $patternType = "Initializer" }
         elseif ($functionName -match "^Setup") { $patternType = "Setup" }
            
         # Analyser les paramètres (simple)
         $paramCount = 0
         if ($signature -match '\(([^)]*)\)') {
            $params = $matches[1]
            if ($params.Trim() -ne "") {
               $paramCount = ($params -split ',').Count
            }
         }
            
         $constructorInfo = @{
            name            = $functionName
            file            = $relativePath
            package         = $packageName
            line_number     = $match.LineNumber
            pattern_type    = $patternType
            parameter_count = $paramCount
            return_type     = $returnType
            signature       = $signature
            is_exported     = $functionName[0] -cmatch "[A-Z]"
         }
            
         $constructors += $constructorInfo
         $constructorReport.constructors += $constructorInfo
      }
   }
}

$constructorReport.constructors_found = $constructors.Count

# Générer le rapport JSON et Markdown
$markdownContent = @"
# Patterns Constructeurs - Analyse Complète

**Date de scan**: $($constructorReport.scan_timestamp)  
**Branche**: $($constructorReport.branch)  
**Fichiers scannés**: $($constructorReport.total_files_scanned)  
**Patterns recherchés**: $($constructorReport.patterns_searched)  
**Constructeurs trouvés**: $($constructorReport.constructors_found)

## 📋 Résumé par Type de Pattern

"@

# Grouper par type de pattern
$constructorsByPattern = $constructors | Group-Object -Property pattern_type | Sort-Object Name

foreach ($patternGroup in $constructorsByPattern) {
   $patternType = $patternGroup.Name
   $markdownContent += "`n### Pattern: ``$patternType`` ($($patternGroup.Count) constructeurs)`n`n"
    
   foreach ($constructor in ($patternGroup.Group | Sort-Object name)) {
      $markdownContent += @"
#### ``$($constructor.name)()``

- **Fichier**: ``$($constructor.file)``
- **Package**: $($constructor.package)
- **Ligne**: $($constructor.line_number)
- **Exportée**: $($constructor.is_exported)
- **Paramètres**: $($constructor.parameter_count)
- **Type retourné**: $($constructor.return_type)

``````go
$($constructor.signature)
``````

"@
   }
}

# Grouper par package
$markdownContent += "`n## 📦 Résumé par Package`n"
$constructorsByPackage = $constructors | Group-Object -Property package | Sort-Object Name

foreach ($packageGroup in $constructorsByPackage) {
   $packageName = $packageGroup.Name
   $patternStats = $packageGroup.Group | Group-Object -Property pattern_type
   $patternSummary = $patternStats | ForEach-Object { "$($_.Name)($($_.Count))" }
    
   $markdownContent += "`n- **$packageName**: $($packageGroup.Count) constructeurs [$($patternSummary -join ', ')]"
}

$markdownContent += @"

## 🔄 Analyse et Recommandations

### Répartition par Pattern
"@

foreach ($patternGroup in $constructorsByPattern) {
   $percentage = [math]::Round(($patternGroup.Count / $constructors.Count) * 100, 1)
   $markdownContent += "`n- **$($patternGroup.Name)**: $($patternGroup.Count) constructeurs ($percentage%)"
}

$markdownContent += @"

### Constructeurs avec Beaucoup de Paramètres (>3)
"@

$complexConstructors = $constructors | Where-Object { $_.parameter_count -gt 3 } | Sort-Object -Property parameter_count -Descending
if ($complexConstructors) {
   foreach ($complex in $complexConstructors) {
      $markdownContent += "`n- $($complex.name) ($($complex.parameter_count) paramètres) dans $($complex.file)"
   }
}
else {
   $markdownContent += "`n- Aucun constructeur avec trop de paramètres"
}

$markdownContent += @"

### Constructeurs Non-Exportés
"@

$privateConstructors = $constructors | Where-Object { -not $_.is_exported }
if ($privateConstructors) {
   foreach ($private in $privateConstructors) {
      $markdownContent += "`n- $($private.name) dans $($private.file) ($($private.package))"
   }
}
else {
   $markdownContent += "`n- Tous les constructeurs sont exportés"
}

$markdownContent += @"

---
*Généré par Tâche Atomique 003 - $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")*
"@

# Créer répertoire de sortie
$outputDir = "output/phase1"
if (-not (Test-Path $outputDir)) {
   New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
   Write-Host "📁 Répertoire créé: $outputDir" -ForegroundColor Green
}

$jsonPath = "$outputDir/constructors-analysis.json"
$markdownPath = "$outputDir/constructors-patterns.md"

# Sauvegarder JSON
$constructorReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonPath -Encoding UTF8

# Sauvegarder Markdown
$markdownContent | Out-File -FilePath $markdownPath -Encoding UTF8

# Affichage résultat
Write-Host "`n✅ RÉSULTATS:" -ForegroundColor Green
Write-Host "📊 Constructeurs trouvés: $($constructors.Count)" -ForegroundColor White
Write-Host "📋 Fichiers scannés: $($goFiles.Count)" -ForegroundColor White
Write-Host "📦 Packages: $(($constructorsByPackage | Measure-Object).Count)" -ForegroundColor White
Write-Host "🔓 Constructeurs exportés: $(($constructors | Where-Object is_exported).Count)" -ForegroundColor White
Write-Host "📄 Rapport JSON: $jsonPath" -ForegroundColor Cyan
Write-Host "📄 Rapport Markdown: $markdownPath" -ForegroundColor Cyan

# Statistiques patterns
Write-Host "`n📊 Répartition par pattern:" -ForegroundColor Magenta
foreach ($patternGroup in $constructorsByPattern) {
   $percentage = [math]::Round(($patternGroup.Count / $constructors.Count) * 100, 1)
   Write-Host "  - $($patternGroup.Name): $($patternGroup.Count) ($percentage%)" -ForegroundColor White
}

# Validation finale
if ($constructors.Count -gt 0) {
   Write-Host "`n✅ Tâche Atomique 003 COMPLÉTÉE avec succès!" -ForegroundColor Green
   Write-Host "📋 Patterns de construction identifiés" -ForegroundColor Green
}
else {
   Write-Host "`n⚠️  Aucun constructeur trouvé - Vérifiez les patterns de recherche" -ForegroundColor Yellow
}

Write-Host "`n🎯 Prochaine étape: Tâche Atomique 004 - Cartographier Imports Managers" -ForegroundColor Magenta
