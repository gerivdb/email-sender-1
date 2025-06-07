# ================================================================================================
# 🌳 BRANCH MANAGER AUTOMATION SCRIPT
# ================================================================================================
# Script PowerShell pour automatiser la gestion des branches managers
# Créé le 7 juin 2025 pour le projet EMAIL_SENDER_1

param(
   [Parameter(Position = 0)]
   [ValidateSet("status", "switch", "merge", "push", "pull", "sync", "list", "help")]
   [string]$Action = "help",
    
   [Parameter(Position = 1)]
   [ValidateSet("ci-cd-fixes", "jules-bot-system", "go-development", "powershell-optimization")]
   [string]$Manager,
    
   [Parameter(Position = 2)]
   [string]$SubBranch,
    
   [switch]$Force,
   [switch]$All
)

# Configuration des branches managers
$BranchManagers = @{
   "ci-cd-fixes"             = @{
      "name"        = "manager/ci-cd-fixes"
      "priority"    = 1
      "status"      = "🔥 URGENT"
      "subBranches" = @(
         "fix/go-workflow-yaml-syntax",
         "fix/github-actions-yaml", 
         "fix/workflow-validation"
      )
      "description" = "Résolution des conflits de merge et correction des workflows GitHub Actions"
   }
   "jules-bot-system"        = @{
      "name"        = "manager/jules-bot-system"
      "priority"    = 2
      "status"      = "🚀 HIGH"
      "subBranches" = @(
         "feature/jules-bot-workflows",
         "fix/jules-bot-redirect",
         "fix/jules-bot-validator",
         "feature/bot-contribution-detection"
      )
      "description" = "Système complet de gestion des contributions Jules Bot"
   }
   "go-development"          = @{
      "name"        = "manager/go-development" 
      "priority"    = 3
      "status"      = "🔧 MEDIUM"
      "subBranches" = @(
         "fix/go-imports",
         "fix/go-package-structure",
         "fix/manager-toolkit-import"
      )
      "description" = "Architecture Go et résolution des problèmes d'imports"
   }
   "powershell-optimization" = @{
      "name"        = "manager/powershell-optimization"
      "priority"    = 4
      "status"      = "🧹 LOW"
      "subBranches" = @(
         "refactor/powershell-scripts",
         "fix/powershell-warnings",
         "cleanup/unused-variables"
      )
      "description" = "Nettoyage et optimisation des scripts PowerShell"
   }
}

function Write-Header {
   param([string]$Title)
   Write-Host ""
   Write-Host "================================================================================================" -ForegroundColor Cyan
   Write-Host "🌳 $Title" -ForegroundColor Yellow
   Write-Host "================================================================================================" -ForegroundColor Cyan
   Write-Host ""
}

function Write-ManagerInfo {
   param($ManagerKey, $ManagerData)
    
   Write-Host "📋 Manager: " -NoNewline -ForegroundColor White
   Write-Host $ManagerData.name -ForegroundColor Green
   Write-Host "🎯 Statut: " -NoNewline -ForegroundColor White  
   Write-Host $ManagerData.status -ForegroundColor Yellow
   Write-Host "📝 Description: " -NoNewline -ForegroundColor White
   Write-Host $ManagerData.description -ForegroundColor Gray
   Write-Host "🌿 Sous-branches:" -ForegroundColor White
    
   foreach ($subBranch in $ManagerData.subBranches) {
      Write-Host "   ├── $subBranch" -ForegroundColor Cyan
   }
   Write-Host ""
}

function Show-Status {
   Write-Header "STATUS DES BRANCH MANAGERS"
    
   $orderedManagers = $BranchManagers.GetEnumerator() | Sort-Object { $_.Value.priority }
    
   foreach ($manager in $orderedManagers) {
      Write-ManagerInfo $manager.Key $manager.Value
        
      # Vérifier si la branche existe
      $branchExists = git branch | Select-String -Pattern $manager.Value.name -Quiet
      if ($branchExists) {
         Write-Host "   ✅ Branche manager disponible" -ForegroundColor Green
      }
      else {
         Write-Host "   ❌ Branche manager manquante" -ForegroundColor Red
      }
        
      # Vérifier les sous-branches
      foreach ($subBranch in $manager.Value.subBranches) {
         $subBranchExists = git branch | Select-String -Pattern $subBranch -Quiet
         if ($subBranchExists) {
            Write-Host "   ├── ✅ $subBranch" -ForegroundColor Green
         }
         else {
            Write-Host "   ├── ❌ $subBranch (manquante)" -ForegroundColor Red
         }
      }
      Write-Host ""
   }
}

function Switch-ToManager {
   param([string]$ManagerKey, [string]$SubBranchName)
    
   if (-not $BranchManagers.ContainsKey($ManagerKey)) {
      Write-Host "❌ Manager '$ManagerKey' non trouvé!" -ForegroundColor Red
      return
   }
    
   $manager = $BranchManagers[$ManagerKey]
    
   if ($SubBranchName) {
      if ($manager.subBranches -contains $SubBranchName) {
         Write-Host "🔄 Changement vers la sous-branche: $SubBranchName" -ForegroundColor Yellow
         git checkout $SubBranchName
      }
      else {
         Write-Host "❌ Sous-branche '$SubBranchName' non trouvée dans $ManagerKey!" -ForegroundColor Red
         Write-Host "Sous-branches disponibles:" -ForegroundColor White
         $manager.subBranches | ForEach-Object { Write-Host "  - $_" -ForegroundColor Cyan }
      }
   }
   else {
      Write-Host "🔄 Changement vers le manager: $($manager.name)" -ForegroundColor Yellow  
      git checkout $manager.name
   }
}

function Sync-Branches {
   Write-Header "SYNCHRONISATION DES BRANCHES"
    
   Write-Host "📥 Récupération des dernières modifications..." -ForegroundColor Yellow
   git fetch origin
    
   Write-Host "📤 Envoi de toutes les branches locales..." -ForegroundColor Yellow
   git push origin --all
    
   Write-Host "✅ Synchronisation terminée!" -ForegroundColor Green
}

function Show-Help {
   Write-Header "AIDE - BRANCH MANAGER AUTOMATION"
    
   Write-Host "Usage: .\branch-manager.ps1 <action> [manager] [sub-branch] [options]" -ForegroundColor White
   Write-Host ""
   Write-Host "Actions disponibles:" -ForegroundColor Yellow
   Write-Host "  status          - Afficher l'état des branch managers" -ForegroundColor Cyan
   Write-Host "  switch <mgr>    - Changer vers un manager" -ForegroundColor Cyan
   Write-Host "  switch <mgr> <sub> - Changer vers une sous-branche" -ForegroundColor Cyan
   Write-Host "  sync            - Synchroniser avec le remote" -ForegroundColor Cyan
   Write-Host "  list            - Lister tous les managers" -ForegroundColor Cyan
   Write-Host "  help            - Afficher cette aide" -ForegroundColor Cyan
   Write-Host ""
   Write-Host "Managers disponibles:" -ForegroundColor Yellow
   foreach ($key in $BranchManagers.Keys) {
      $manager = $BranchManagers[$key]
      Write-Host "  $key - $($manager.status) - $($manager.description)" -ForegroundColor Cyan
   }
   Write-Host ""
   Write-Host "Exemples:" -ForegroundColor Yellow
   Write-Host "  .\branch-manager.ps1 status" -ForegroundColor Gray
   Write-Host "  .\branch-manager.ps1 switch ci-cd-fixes" -ForegroundColor Gray
   Write-Host "  .\branch-manager.ps1 switch jules-bot-system feature/jules-bot-workflows" -ForegroundColor Gray
   Write-Host "  .\branch-manager.ps1 sync" -ForegroundColor Gray
}

function Show-List {
   Write-Header "LISTE DES BRANCH MANAGERS"
    
   $orderedManagers = $BranchManagers.GetEnumerator() | Sort-Object { $_.Value.priority }
    
   foreach ($manager in $orderedManagers) {
      Write-Host "🏷️  " -NoNewline -ForegroundColor White
      Write-Host $manager.Key -NoNewline -ForegroundColor Green  
      Write-Host " ($($manager.Value.status))" -ForegroundColor Yellow
      Write-Host "   📋 $($manager.Value.name)" -ForegroundColor Cyan
      Write-Host "   📝 $($manager.Value.description)" -ForegroundColor Gray
      Write-Host ""
   }
}

# ================================================================================================
# EXECUTION PRINCIPALE
# ================================================================================================

switch ($Action.ToLower()) {
   "status" {
      Show-Status
   }
   "switch" {
      if (-not $Manager) {
         Write-Host "❌ Veuillez spécifier un manager!" -ForegroundColor Red
         Show-Help
         return
      }
      Switch-ToManager $Manager $SubBranch
   }
   "sync" {
      Sync-Branches
   }
   "list" {
      Show-List
   }
   "help" {
      Show-Help
   }
   default {
      Show-Help
   }
}

Write-Host ""
