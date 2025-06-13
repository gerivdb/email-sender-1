# Analyse de la stratégie de branching et contributions Jules
# Vérification de la qualité des commits et remontée qualitative

Write-Host "🔍 ANALYSE DE LA STRATÉGIE DE BRANCHING JULES" -ForegroundColor Cyan
Write-Host "=" * 50

# 1. Identifier toutes les branches Jules
Write-Host "`n1️⃣ BRANCHES DÉDIÉES À JULES:" -ForegroundColor Yellow
$julesBranches = git branch -a | Where-Object { $_ -match "jules" }
$julesBranches | ForEach-Object { 
   Write-Host "   📂 $_" -ForegroundColor Green 
}

# 2. Analyser les commits de Jules par branch
Write-Host "`n2️⃣ COMMITS JULES PAR BRANCHE:" -ForegroundColor Yellow
foreach ($branch in $julesBranches) {
   $cleanBranch = $branch.Trim().Replace("remotes/origin/", "").Replace("* ", "")
   Write-Host "`n   🌿 Branche: $cleanBranch" -ForegroundColor Magenta
    
   # Obtenir les commits de cette branche
   $commits = git log $cleanBranch --oneline --author="jules" -5 2>$null
   if ($commits) {
      $commits | ForEach-Object { Write-Host "      💾 $_" -ForegroundColor Gray }
   }
   else {
      Write-Host "      ⚠️ Aucun commit jules trouvé" -ForegroundColor DarkYellow
   }
}

# 3. Analyser la qualité des commits (SOLID, KISS, DRY)
Write-Host "`n3️⃣ ANALYSE QUALITATIVE DES COMMITS:" -ForegroundColor Yellow

$qualityKeywords = @(
   "SOLID", "DRY", "KISS", "refactor", "optimize", "clean", 
   "improve", "enhance", "fix", "resolve", "implement", "update"
)

Write-Host "   🎯 Mots-clés qualité recherchés: $($qualityKeywords -join ', ')" -ForegroundColor Cyan

$allJulesCommits = git log --all --author="jules" --oneline -20 2>$null
$qualityCommits = @()

if ($allJulesCommits) {
   foreach ($commit in $allJulesCommits) {
      foreach ($keyword in $qualityKeywords) {
         if ($commit -match $keyword) {
            $qualityCommits += $commit
            break
         }
      }
   }
}

Write-Host "`n   📊 COMMITS DE QUALITÉ DÉTECTÉS:" -ForegroundColor Green
if ($qualityCommits.Count -gt 0) {
   $qualityCommits | ForEach-Object { 
      Write-Host "      ✅ $_" -ForegroundColor Green 
   }
    
   $qualityRatio = [math]::Round(($qualityCommits.Count / $allJulesCommits.Count) * 100, 2)
   Write-Host "`n   📈 Ratio qualité: $qualityRatio% ($($qualityCommits.Count)/$($allJulesCommits.Count))" -ForegroundColor Cyan
}
else {
   Write-Host "      ⚠️ Aucun commit de qualité détecté avec les critères SOLID/KISS/DRY" -ForegroundColor DarkYellow
}

# 4. Analyse des merges et remontées
Write-Host "`n4️⃣ STRATÉGIE DE REMONTÉE:" -ForegroundColor Yellow

# Vérifier les merges vers les branches principales
$mainBranches = @("main", "dev", "manager-ecosystem")
foreach ($mainBranch in $mainBranches) {
   Write-Host "`n   🔀 Remontées vers $mainBranch:" -ForegroundColor Magenta
   $merges = git log $mainBranch --grep="jules" --grep="Merge.*jules" --oneline -10 2>$null
   if ($merges) {
      $merges | ForEach-Object { Write-Host "      🔄 $_" -ForegroundColor Blue }
   }
   else {
      Write-Host "      ⚠️ Aucune remontée jules détectée" -ForegroundColor DarkYellow
   }
}

# 5. Recommandations pour améliorer la stratégie
Write-Host "`n5️⃣ RECOMMANDATIONS STRATÉGIQUES:" -ForegroundColor Yellow
Write-Host "   💡 Pour optimiser la remontée qualitative:" -ForegroundColor Cyan
Write-Host "      - Utiliser des tags [SOLID], [DRY], [KISS] dans les messages de commit"
Write-Host "      - Créer une branche jules-quality pour les commits de haute qualité"
Write-Host "      - Automatiser l'analyse de qualité avec des hooks Git"
Write-Host "      - Implémenter un système de scoring des commits"
Write-Host "      - Créer des PR templates pour les contributions Jules"

# 6. Status actuel
Write-Host "`n6️⃣ STATUS ACTUEL:" -ForegroundColor Yellow
$currentBranch = git branch --show-current
Write-Host "   📍 Branche actuelle: $currentBranch" -ForegroundColor Green
Write-Host "   📈 Nombre total de branches Jules: $($julesBranches.Count)" -ForegroundColor Cyan
Write-Host "   💻 Dernière activité Jules:" -ForegroundColor Cyan
$lastJulesCommit = git log --all --author="jules" --oneline -1 2>$null
if ($lastJulesCommit) {
   Write-Host "      $lastJulesCommit" -ForegroundColor Gray
}
else {
   Write-Host "      ⚠️ Aucun commit jules récent trouvé" -ForegroundColor DarkYellow
}

Write-Host "`n✅ ANALYSE TERMINÉE" -ForegroundColor Green
