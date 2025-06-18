#!/usr/bin/env powershell
# Implémentation Tâche Atomique 002: Extraire Interfaces Publiques
# Durée: 15 minutes max - Phase 1.1.1

Write-Host "🔍 TÂCHE ATOMIQUE 002: Extraire Interfaces Publiques" -ForegroundColor Cyan
Write-Host "Durée: 15 minutes max" -ForegroundColor Yellow

# Vérification branche
$currentBranch = git branch --show-current
Write-Host "📋 Branche active: $currentBranch" -ForegroundColor Green

# Scanner interfaces publiques dans les managers
Write-Host "`n📋 Scanning interfaces publiques dans managers Go..." -ForegroundColor Yellow

# Patterns de recherche pour interfaces
$interfacePatterns = @(
   "type\s+(\w*Manager\w*)\s+interface",
   "type\s+(\w*Client\w*)\s+interface", 
   "type\s+(\w*Service\w*)\s+interface",
   "type\s+(\w*Handler\w*)\s+interface"
)

# Rechercher tous fichiers Go (pas seulement managers)
$goFiles = Get-ChildItem -Recurse -Include '*.go' | 
Where-Object { $_.FullName -notmatch "vendor|node_modules|\.git|_test\.go" }

$interfaces = @()
$interfaceReport = @{
   scan_timestamp      = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
   branch              = $currentBranch
   total_files_scanned = $goFiles.Count
   interfaces_found    = 0
   interfaces          = @()
}

foreach ($file in $goFiles) {
   $relativePath = $file.FullName.Replace((Get-Location).Path + "\", "")
   $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    
   if (-not $content) { continue }
    
   # Chercher chaque pattern d'interface
   foreach ($pattern in $interfacePatterns) {
      $matches = [regex]::Matches($content, $pattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)
        
      foreach ($match in $matches) {
         if ($match.Groups.Count -gt 1) {
            $interfaceName = $match.Groups[1].Value
                
            # Extraire la définition complète de l'interface
            $interfaceStart = $match.Index
            $interfaceDefPattern = "type\s+$interfaceName\s+interface\s*\{[^}]*\}"
            $fullMatch = [regex]::Match($content, $interfaceDefPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
                
            if ($fullMatch.Success) {
               # Extraire les méthodes de l'interface
               $methodPattern = "\s+(\w+)\s*\([^)]*\)\s*(?:\([^)]*\))?"
               $methods = [regex]::Matches($fullMatch.Value, $methodPattern) | 
               ForEach-Object { $_.Groups[1].Value } |
               Where-Object { $_ -notmatch "type|interface" }
                    
               $interfaceInfo = @{
                  name         = $interfaceName
                  file         = $relativePath
                  package      = ""
                  methods      = @($methods)
                  method_count = $methods.Count
                  definition   = $fullMatch.Value.Trim()
                  is_exported  = $interfaceName[0] -cmatch "[A-Z]"
               }
                    
               # Extraire le package
               $packageMatch = [regex]::Match($content, "package\s+(\w+)")
               if ($packageMatch.Success) {
                  $interfaceInfo.package = $packageMatch.Groups[1].Value
               }
                    
               $interfaces += $interfaceInfo
               $interfaceReport.interfaces += $interfaceInfo
            }
         }
      }
   }
}

$interfaceReport.interfaces_found = $interfaces.Count

# Générer le rapport Markdown
$markdownContent = @"
# Interfaces Publiques Managers - Rapport d'Extraction

**Date de scan**: $($interfaceReport.scan_timestamp)  
**Branche**: $($interfaceReport.branch)  
**Fichiers scannés**: $($interfaceReport.total_files_scanned)  
**Interfaces trouvées**: $($interfaceReport.interfaces_found)

## 📋 Résumé des Interfaces

"@

# Grouper par package
$interfacesByPackage = $interfaces | Group-Object -Property package

foreach ($packageGroup in $interfacesByPackage) {
   $packageName = if ($packageGroup.Name) { $packageGroup.Name } else { "main" }
   $markdownContent += "`n### Package: ``$packageName```n`n"
    
   foreach ($interface in $packageGroup.Group) {
      $markdownContent += @"
#### ``$($interface.name)``

- **Fichier**: ``$($interface.file)``
- **Exportée**: $($interface.is_exported)
- **Nombre de méthodes**: $($interface.method_count)
- **Méthodes**: $($interface.methods -join ', ')

``````go
$($interface.definition)
``````

"@
   }
}

$markdownContent += @"

## 🔄 Actions Recommandées

### Interfaces à Standardiser
$(if ($interfaces | Where-Object { $_.name -notmatch "Manager$" -and $_.is_exported }) {
    ($interfaces | Where-Object { $_.name -notmatch "Manager$" -and $_.is_exported } | ForEach-Object { "- $($_.name) dans $($_.file)" }) -join "`n"
} else {
    "- Aucune interface non-standard détectée"
})

### Interfaces sans Méthodes
$(if ($interfaces | Where-Object { $_.method_count -eq 0 }) {
    ($interfaces | Where-Object { $_.method_count -eq 0 } | ForEach-Object { "- $($_.name) dans $($_.file)" }) -join "`n"
} else {
    "- Toutes les interfaces ont des méthodes définies"
})

### Interfaces avec Beaucoup de Méthodes (>10)
$(if ($interfaces | Where-Object { $_.method_count -gt 10 }) {
    ($interfaces | Where-Object { $_.method_count -gt 10 } | ForEach-Object { "- $($_.name) ($($_.method_count) méthodes) dans $($_.file)" }) -join "`n"
} else {
    "- Aucune interface avec trop de méthodes"
})

---
*Généré par Tâche Atomique 002 - $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")*
"@

# Écrire les rapports
$outputDir = "output/phase1"
if (-not (Test-Path $outputDir)) {
   New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
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
Write-Host "📄 Rapport JSON: $jsonPath" -ForegroundColor Cyan
Write-Host "📄 Rapport Markdown: $markdownPath" -ForegroundColor Cyan

# Validation finale
if ($interfaces.Count -gt 0) {
   Write-Host "`n✅ Tâche Atomique 002 COMPLÉTÉE avec succès!" -ForegroundColor Green
   Write-Host "📋 Toutes interfaces publiques documentées" -ForegroundColor Green
}
else {
   Write-Host "`n⚠️  Aucune interface trouvée - Vérifiez les patterns de recherche" -ForegroundColor Yellow
}

Write-Host "`n🎯 Prochaine étape: Tâche Atomique 003 - Analyser Patterns Constructeurs" -ForegroundColor Magenta
