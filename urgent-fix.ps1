# ================================================================================================
# 🚨 QUICK START - RÉSOLUTION URGENT fix/go-workflow-yaml-syntax
# ================================================================================================
# Script de démarrage rapide pour traiter immédiatement l'erreur URGENTE
# Conflits de merge dans .github/workflows/go-quality.yml

param(
   [switch]$AutoResolve,
   [switch]$ShowConflicts,
   [switch]$Backup
)

Write-Host ""
Write-Host "🚨🚨🚨 ALERTE PRIORITÉ URGENTE 🚨🚨🚨" -BackgroundColor Red -ForegroundColor White
Write-Host ""
Write-Host "🎯 Cible: fix/go-workflow-yaml-syntax" -ForegroundColor Red
Write-Host "📁 Fichier: .github/workflows/go-quality.yml" -ForegroundColor Yellow
Write-Host "🐛 Problème: Conflits de merge non résolus" -ForegroundColor Red
Write-Host ""

# Vérification de l'état actuel
Write-Host "🔍 Vérification de l'état du repository..." -ForegroundColor Cyan

$currentBranch = git rev-parse --abbrev-ref HEAD
Write-Host "📍 Branche actuelle: $currentBranch" -ForegroundColor White

# Switch vers la branche problématique
Write-Host ""
Write-Host "🔄 Changement vers fix/go-workflow-yaml-syntax..." -ForegroundColor Yellow
git checkout fix/go-workflow-yaml-syntax

if ($LASTEXITCODE -ne 0) {
   Write-Host "❌ Erreur lors du changement de branche!" -ForegroundColor Red
   exit 1
}

# Afficher les conflits
Write-Host ""
Write-Host "🔍 Analyse des conflits dans go-quality.yml..." -ForegroundColor Cyan

$conflictFile = ".github/workflows/go-quality.yml"

if (Test-Path $conflictFile) {
   Write-Host "📄 Fichier trouvé: $conflictFile" -ForegroundColor Green
    
   # Rechercher les marqueurs de conflit
   $conflicts = Select-String -Path $conflictFile -Pattern "(<<<<<<<|=======|>>>>>>>)"
    
   if ($conflicts) {
      Write-Host ""
      Write-Host "⚠️  CONFLITS DÉTECTÉS:" -ForegroundColor Red
      Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
        
      foreach ($conflict in $conflicts) {
         Write-Host "Ligne $($conflict.LineNumber): $($conflict.Line.Trim())" -ForegroundColor Yellow
      }
        
      Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
        
      if ($ShowConflicts) {
         Write-Host ""
         Write-Host "📄 CONTENU COMPLET DU FICHIER:" -ForegroundColor Cyan
         Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
         Get-Content $conflictFile | ForEach-Object { 
            if ($_ -match "(<<<<<<<|=======|>>>>>>>)") {
               Write-Host $_ -ForegroundColor Red
            }
            else {
               Write-Host $_
            }
         }
         Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
      }
        
      Write-Host ""
      Write-Host "🛠️  ACTIONS RECOMMANDÉES:" -ForegroundColor Yellow
      Write-Host "1. 📝 Éditer le fichier: .github/workflows/go-quality.yml" -ForegroundColor Cyan
      Write-Host "2. 🗑️  Supprimer les marqueurs: <<<<<<< HEAD, =======, >>>>>>> origin/..." -ForegroundColor Cyan
      Write-Host "3. ✅ Choisir la version correcte du code" -ForegroundColor Cyan
      Write-Host "4. 💾 Sauvegarder et committer" -ForegroundColor Cyan
      Write-Host ""
        
      if ($Backup) {
         $backupFile = "$conflictFile.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
         Copy-Item $conflictFile $backupFile
         Write-Host "💾 Backup créé: $backupFile" -ForegroundColor Green
      }
        
      if ($AutoResolve) {
         Write-Host "🤖 TENTATIVE DE RÉSOLUTION AUTOMATIQUE..." -ForegroundColor Yellow
         Write-Host "⚠️  ATTENTION: Vérifiez le résultat!" -ForegroundColor Red
            
         # Lecture du contenu
         $content = Get-Content $conflictFile -Raw
            
         # Tentative de résolution simple (garder la version HEAD)
         $resolved = $content -replace "<<<<<<< HEAD\r?\n", "" `
            -replace "=======\r?\n.*?>>>>>>> origin/fix/go-workflow-yaml-syntax", "" `
            -replace ">>>>>>> origin/fix/go-workflow-yaml-syntax", ""
            
         # Sauvegarde
         $resolved | Set-Content $conflictFile -NoNewline
            
         Write-Host "✅ Résolution automatique appliquée" -ForegroundColor Green
         Write-Host "🔍 Vérifiez le fichier avant de committer!" -ForegroundColor Yellow
      }
        
   }
   else {
      Write-Host "✅ Aucun conflit détecté dans le fichier" -ForegroundColor Green
   }
    
}
else {
   Write-Host "❌ Fichier non trouvé: $conflictFile" -ForegroundColor Red
}

Write-Host ""
Write-Host "🎯 ÉTAPES SUIVANTES:" -ForegroundColor Yellow
Write-Host "1. 🛠️  Résoudre les conflits manuellement si nécessaire" -ForegroundColor Cyan
Write-Host "2. 🧪 Tester la syntaxe YAML" -ForegroundColor Cyan  
Write-Host "3. 💾 git add $conflictFile" -ForegroundColor Cyan
Write-Host "4. 📝 git commit -m 'fix: resolve merge conflicts in go-quality.yml'" -ForegroundColor Cyan
Write-Host "5. 📤 git push origin fix/go-workflow-yaml-syntax" -ForegroundColor Cyan
Write-Host "6. 🔄 Merger vers manager/ci-cd-fixes" -ForegroundColor Cyan
Write-Host ""

Write-Host "📋 COMMANDES RAPIDES:" -ForegroundColor White
Write-Host "- Voir conflits: .\urgent-fix.ps1 -ShowConflicts" -ForegroundColor Gray
Write-Host "- Auto-résolution: .\urgent-fix.ps1 -AutoResolve -Backup" -ForegroundColor Gray
Write-Host "- Retour script manager: .\branch-manager.ps1 status" -ForegroundColor Gray
Write-Host ""

Write-Host "🚨 Cette erreur BLOQUE le build - traitement immédiat requis! 🚨" -BackgroundColor Red -ForegroundColor White
Write-Host ""
