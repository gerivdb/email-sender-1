#!/usr/bin/env powershell
# Implémentation Tâche Atomique 002: Extraire Interfaces Publiques - Version Optimisée
# Durée: 15 minutes max - Phase 1.1.1

Write-Host "🔍 TÂCHE ATOMIQUE 002: Extraire Interfaces Publiques" -ForegroundColor Cyan
Write-Host "Durée: 15 minutes max" -ForegroundColor Yellow

# Vérification branche
$currentBranch = git branch --show-current
Write-Host "📋 Branche active: $currentBranch" -ForegroundColor Green

# Scanner interfaces publiques
Write-Host "`n📋 Scanning interfaces publiques..." -ForegroundColor Yellow

# Rechercher tous fichiers Go (exclure tests et vendor)
$goFiles = Get-ChildItem -Recurse -Include '*.go' | 
Where-Object { $_.FullName -notmatch "vendor|node_modules|\.git|_test\.go" }

Write-Host "📄 Fichiers Go trouvés: $($goFiles.Count)" -ForegroundColor Green

# Utiliser Select-String pour efficacité
$interfaceMatches = $goFiles | Select-String -Pattern 'type\s+(\w+)\s+interface\s*\{'

$interfaces = @()
$interfaceReport = @{
   scan_timestamp      = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
   branch              = $currentBranch
   total_files_scanned = $goFiles.Count
   interfaces_found    = 0
   interfaces          = @()
}

Write-Host "🔍 Analysing $($interfaceMatches.Count) interfaces..." -ForegroundColor Yellow

foreach ($match in $interfaceMatches) {
   $relativePath = $match.Filename.Replace((Get-Location).Path + "\", "")
    
   # Extraire nom d'interface avec regex simple
   if ($match.Line -match 'type\s+(\w+)\s+interface') {
      $interfaceName = $matches[1]
        
      # Lire contenu pour package
      $content = Get-Content $match.Filename -Raw -ErrorAction SilentlyContinue
      $packageName = "unknown"
        
      if ($content -match "package\s+(\w+)") {
         $packageName = $matches[1]
      }
        
      # Extraire méthodes (pattern simple)
      $methodCount = 0
      $methods = @()
        
      # Trouver le bloc d'interface
      if ($content -match "type\s+$interfaceName\s+interface\s*\{([^}]*)\}") {
         $interfaceBody = $matches[1]
         $methodMatches = [regex]::Matches($interfaceBody, '\s*(\w+)\s*\([^)]*\)')
         $methods = $methodMatches | ForEach-Object { $_.Groups[1].Value } | Where-Object { $_ -ne "" }
         $methodCount = $methods.Count
      }
        
      $interfaceInfo = @{
         name         = $interfaceName.Trim()
         file         = $relativePath
         package      = $packageName
         line_number  = $match.LineNumber
         methods      = @($methods)
         method_count = $methodCount
         is_exported  = $interfaceName[0] -cmatch "[A-Z]"
         line_content = $match.Line.Trim()
      }
        
      $interfaces += $interfaceInfo
      $interfaceReport.interfaces += $interfaceInfo
   }
}

$interfaceReport.interfaces_found = $interfaces.Count

# Générer le rapport Markdown
$markdownContent = @"
# Interfaces Publiques - Rapport d'Extraction

**Date de scan**: $($interfaceReport.scan_timestamp)  
**Branche**: $($interfaceReport.branch)  
**Fichiers scannés**: $($interfaceReport.total_files_scanned)  
**Interfaces trouvées**: $($interfaceReport.interfaces_found)

## 📋 Résumé des Interfaces

"@

# Grouper par package
$interfacesByPackage = $interfaces | Group-Object -Property package | Sort-Object Name

foreach ($packageGroup in $interfacesByPackage) {
   $packageName = $packageGroup.Name
   $markdownContent += "`n### Package: ``$packageName```n`n"
    
   foreach ($interface in ($packageGroup.Group | Sort-Object name)) {
      $markdownContent += @"
#### ``$($interface.name)``

- **Fichier**: ``$($interface.file)``
- **Ligne**: $($interface.line_number)
- **Exportée**: $($interface.is_exported)
- **Nombre de méthodes**: $($interface.method_count)
- **Méthodes**: $($interface.methods -join ', ')

``````go
$($interface.line_content)
``````

"@
   }
}

$markdownContent += @"

## 🔄 Actions Recommandées

### Interfaces Exportées par Package
"@

$exportedByPackage = $interfaces | Where-Object { $_.is_exported } | Group-Object -Property package
foreach ($pkg in $exportedByPackage) {
   $markdownContent += "`n- **$($pkg.Name)**: $($pkg.Count) interfaces ($($pkg.Group.name -join ', '))"
}

$markdownContent += @"

### Interfaces sans Méthodes
"@

$emptyInterfaces = $interfaces | Where-Object { $_.method_count -eq 0 }
if ($emptyInterfaces) {
   foreach ($empty in $emptyInterfaces) {
      $markdownContent += "`n- $($empty.name) dans $($empty.file)"
   }
}
else {
   $markdownContent += "`n- Aucune interface vide détectée"
}

$markdownContent += @"

### Interfaces avec Beaucoup de Méthodes (>5)
"@

$complexInterfaces = $interfaces | Where-Object { $_.method_count -gt 5 } | Sort-Object -Property method_count -Descending
if ($complexInterfaces) {
   foreach ($complex in $complexInterfaces) {
      $markdownContent += "`n- $($complex.name) ($($complex.method_count) méthodes) dans $($complex.file)"
   }
}
else {
   $markdownContent += "`n- Aucune interface complexe détectée"
}

$markdownContent += @"

---
*Généré par Tâche Atomique 002 - $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")*
"@

# Créer répertoire de sortie
$outputDir = "output/phase1"
if (-not (Test-Path $outputDir)) {
   New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
   Write-Host "📁 Répertoire créé: $outputDir" -ForegroundColor Green
}

$jsonPath = "$outputDir/interfaces-publiques-scan.json"
$markdownPath = "$outputDir/interfaces-publiques-managers.md"

# Sauvegarder JSON
$interfaceReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonPath -Encoding UTF8

# Sauvegarder Markdown
$markdownContent | Out-File -FilePath $markdownPath -Encoding UTF8

# Affichage résultat
Write-Host "`n✅ RÉSULTATS:" -ForegroundColor Green
Write-Host "📊 Interfaces trouvées: $($interfaces.Count)" -ForegroundColor White
Write-Host "📋 Fichiers scannés: $($goFiles.Count)" -ForegroundColor White
Write-Host "📦 Packages: $($interfacesByPackage.Count)" -ForegroundColor White
Write-Host "🔓 Interfaces exportées: $(($interfaces | Where-Object is_exported).Count)" -ForegroundColor White
Write-Host "📄 Rapport JSON: $jsonPath" -ForegroundColor Cyan
Write-Host "📄 Rapport Markdown: $markdownPath" -ForegroundColor Cyan

# Top 5 des interfaces par complexité
$top5 = $interfaces | Sort-Object -Property method_count -Descending | Select-Object -First 5
if ($top5) {
   Write-Host "`n🏆 TOP 5 Interfaces les plus complexes:" -ForegroundColor Magenta
   foreach ($top in $top5) {
      Write-Host "  - $($top.name): $($top.method_count) méthodes ($($top.package))" -ForegroundColor White
   }
}

# Validation finale
if ($interfaces.Count -gt 0) {
   Write-Host "`n✅ Tâche Atomique 002 COMPLÉTÉE avec succès!" -ForegroundColor Green
   Write-Host "📋 Toutes interfaces publiques documentées" -ForegroundColor Green
}
else {
   Write-Host "`n⚠️  Aucune interface trouvée - Vérifiez les patterns de recherche" -ForegroundColor Yellow
}

Write-Host "`n🎯 Prochaine étape: Tâche Atomique 003 - Analyser Patterns Constructeurs" -ForegroundColor Magenta
