# 🏗️ Manager Ecosystem - Scripts de Gestion
# Version: 1.0.0
# Date: 7 juin 2025

# Configuration des couleurs pour PowerShell
$ErrorActionPreference = "Stop"

# Configuration des managers
$MANAGERS = @(
   "dependency-manager",
   "security-manager", 
   "storage-manager",
   "email-manager",
   "notification-manager",
   "integration-manager",
   "git-workflow-manager"
)

$MAIN_BRANCH = "manager-ecosystem"
$BRANCH_PREFIX = "feature/"

# Fonctions utilitaires
function Write-ColorOutput {
   param([string]$Message, [string]$Color = "White")
   switch ($Color) {
      "Green" { Write-Host $Message -ForegroundColor Green }
      "Yellow" { Write-Host $Message -ForegroundColor Yellow }
      "Red" { Write-Host $Message -ForegroundColor Red }
      "Blue" { Write-Host $Message -ForegroundColor Blue }
      "Cyan" { Write-Host $Message -ForegroundColor Cyan }
      default { Write-Host $Message }
   }
}

function Show-Help {
   Write-ColorOutput "🏗️ Manager Ecosystem - Scripts de Gestion" "Cyan"
   Write-ColorOutput "==========================================" "Cyan"
   Write-Host ""
   Write-ColorOutput "COMMANDES DISPONIBLES:" "Yellow"
   Write-Host ""
   Write-ColorOutput "  .\manager-ecosystem.ps1 status" "Green"
   Write-Host "    Affiche l'état de toutes les branches managers"
   Write-Host ""
   Write-ColorOutput "  .\manager-ecosystem.ps1 sync" "Green" 
   Write-Host "    Synchronise toutes les branches avec le remote"
   Write-Host ""
   Write-ColorOutput "  .\manager-ecosystem.ps1 switch <manager>" "Green"
   Write-Host "    Bascule vers une branche manager spécifique"
   Write-Host "    Exemple: .\manager-ecosystem.ps1 switch dependency-manager"
   Write-Host ""
   Write-ColorOutput "  .\manager-ecosystem.ps1 create-feature <manager> <feature>" "Green"
   Write-Host "    Crée une sous-branche pour une fonctionnalité"
   Write-Host "    Exemple: .\manager-ecosystem.ps1 create-feature dependency-manager auto-resolver"
   Write-Host ""
   Write-ColorOutput "  .\manager-ecosystem.ps1 merge-feature <manager> <feature>" "Green"
   Write-Host "    Merge une sous-branche vers le manager principal"
   Write-Host ""
   Write-ColorOutput "  .\manager-ecosystem.ps1 test <manager>" "Green"
   Write-Host "    Lance les tests pour un manager spécifique"
   Write-Host ""
   Write-ColorOutput "  .\manager-ecosystem.ps1 build-all" "Green"
   Write-Host "    Compile tous les managers"
   Write-Host ""
   Write-ColorOutput "  .\manager-ecosystem.ps1 cleanup" "Green"
   Write-Host "    Nettoie les branches mergées"
   Write-Host ""
   Write-ColorOutput "MANAGERS DISPONIBLES:" "Yellow"
   foreach ($manager in $MANAGERS) {
      Write-ColorOutput "  - $manager" "Blue"
   }
}

function Get-BranchStatus {
   Write-ColorOutput "📊 État des branches managers:" "Cyan"
   Write-Host ""
    
   $currentBranch = git branch --show-current
   Write-ColorOutput "Branche actuelle: $currentBranch" "Yellow"
   Write-Host ""
    
   foreach ($manager in $MANAGERS) {
      $branchName = "$BRANCH_PREFIX$manager"
      $exists = git branch --list $branchName
        
      if ($exists) {
         # Vérifier si la branche a des commits non pushés
         git fetch origin $branchName 2>$null
         $behind = git rev-list --count "$branchName..origin/$branchName" 2>$null
         $ahead = git rev-list --count "origin/$branchName..$branchName" 2>$null
            
         $status = "✅ OK"
         $color = "Green"
            
         if ($ahead -gt 0) {
            $status = "🔄 $ahead commits à pousser"
            $color = "Yellow"
         }
            
         if ($behind -gt 0) {
            $status = "⬇️ $behind commits à récupérer" 
            $color = "Red"
         }
            
         Write-ColorOutput "  $manager`: $status" $color
      }
      else {
         Write-ColorOutput "  $manager`: ❌ Branche manquante" "Red"
      }
   }
}

function Sync-AllBranches {
   Write-ColorOutput "🔄 Synchronisation de toutes les branches..." "Cyan"
    
   # Fetch toutes les branches
   git fetch --all
    
   # Synchroniser manager-ecosystem
   git checkout $MAIN_BRANCH
   git pull origin $MAIN_BRANCH
    
   foreach ($manager in $MANAGERS) {
      $branchName = "$BRANCH_PREFIX$manager"
      Write-ColorOutput "Synchronisation de $branchName..." "Blue"
        
      git checkout $branchName
      git pull origin $branchName 2>$null
        
      if ($LASTEXITCODE -eq 0) {
         Write-ColorOutput "  ✅ $branchName synchronisée" "Green"
      }
      else {
         Write-ColorOutput "  ⚠️ Erreur lors de la synchronisation de $branchName" "Yellow"
      }
   }
    
   git checkout $MAIN_BRANCH
   Write-ColorOutput "✅ Synchronisation terminée" "Green"
}

function Switch-ToManager {
   param([string]$Manager)
    
   if ($Manager -notin $MANAGERS) {
      Write-ColorOutput "❌ Manager '$Manager' non reconnu" "Red"
      Write-ColorOutput "Managers disponibles: $($MANAGERS -join ', ')" "Yellow"
      return
   }
    
   $branchName = "$BRANCH_PREFIX$Manager"
   Write-ColorOutput "🔄 Basculement vers $branchName..." "Blue"
    
   git checkout $branchName
   if ($LASTEXITCODE -eq 0) {
      Write-ColorOutput "✅ Maintenant sur la branche $branchName" "Green"
        
      # Afficher les derniers commits
      Write-ColorOutput "`nDerniers commits:" "Yellow"
      git log --oneline -5
   }
   else {
      Write-ColorOutput "❌ Erreur lors du basculement" "Red"
   }
}

function Create-FeatureBranch {
   param([string]$Manager, [string]$Feature)
    
   if ($Manager -notin $MANAGERS) {
      Write-ColorOutput "❌ Manager '$Manager' non reconnu" "Red"
      return
   }
    
   $parentBranch = "$BRANCH_PREFIX$Manager"
   $featureBranch = "$BRANCH_PREFIX$Manager/$Feature"
    
   Write-ColorOutput "🌿 Création de la branche fonctionnalité: $featureBranch" "Cyan"
    
   git checkout $parentBranch
   git checkout -b $featureBranch
    
   if ($LASTEXITCODE -eq 0) {
      Write-ColorOutput "✅ Branche créée: $featureBranch" "Green"
      Write-ColorOutput "💡 N'oubliez pas de commiter avec le scope ($Manager)" "Yellow"
      Write-ColorOutput "   Exemple: git commit -m 'feat($Manager): implement $Feature'" "Blue"
   }
   else {
      Write-ColorOutput "❌ Erreur lors de la création de la branche" "Red"
   }
}

function Merge-FeatureBranch {
   param([string]$Manager, [string]$Feature)
    
   if ($Manager -notin $MANAGERS) {
      Write-ColorOutput "❌ Manager '$Manager' non reconnu" "Red"
      return
   }
    
   $parentBranch = "$BRANCH_PREFIX$Manager"
   $featureBranch = "$BRANCH_PREFIX$Manager/$Feature"
    
   Write-ColorOutput "🔄 Merge de $featureBranch vers $parentBranch..." "Cyan"
    
   # Vérifier que la branche feature existe
   $exists = git branch --list $featureBranch
   if (-not $exists) {
      Write-ColorOutput "❌ La branche $featureBranch n'existe pas" "Red"
      return
   }
    
   # Basculer vers la branche parent et merger
   git checkout $parentBranch
   git merge $featureBranch --no-ff -m "feat($Manager): merge $Feature implementation"
    
   if ($LASTEXITCODE -eq 0) {
      Write-ColorOutput "✅ Merge réussi!" "Green"
        
      # Proposer de supprimer la branche feature
      $response = Read-Host "Supprimer la branche $featureBranch? (y/N)"
      if ($response -eq "y" -or $response -eq "Y") {
         git branch -d $featureBranch
         Write-ColorOutput "🗑️ Branche $featureBranch supprimée" "Blue"
      }
   }
   else {
      Write-ColorOutput "❌ Erreur lors du merge" "Red"
   }
}

function Test-Manager {
   param([string]$Manager)
    
   if ($Manager -notin $MANAGERS) {
      Write-ColorOutput "❌ Manager '$Manager' non reconnu" "Red"
      return
   }
    
   $managerPath = "development/managers/$Manager"
   if (-not (Test-Path $managerPath)) {
      Write-ColorOutput "❌ Répertoire $managerPath non trouvé" "Red"
      return
   }
    
   Write-ColorOutput "🧪 Tests pour $Manager..." "Cyan"
    
   Push-Location $managerPath
   try {
      go test -v ./...
      if ($LASTEXITCODE -eq 0) {
         Write-ColorOutput "✅ Tests réussis pour $Manager" "Green"
      }
      else {
         Write-ColorOutput "❌ Tests échoués pour $Manager" "Red"
      }
   }
   finally {
      Pop-Location
   }
}

function Build-AllManagers {
   Write-ColorOutput "🔨 Compilation de tous les managers..." "Cyan"
    
   foreach ($manager in $MANAGERS) {
      $managerPath = "development/managers/$manager"
      if (Test-Path $managerPath) {
         Write-ColorOutput "Compilation de $manager..." "Blue"
            
         Push-Location $managerPath
         try {
            go build -v ./...
            if ($LASTEXITCODE -eq 0) {
               Write-ColorOutput "  ✅ $manager compilé" "Green"
            }
            else {
               Write-ColorOutput "  ❌ Erreur compilation $manager" "Red"
            }
         }
         finally {
            Pop-Location
         }
      }
      else {
         Write-ColorOutput "  ⚠️ $manager non trouvé" "Yellow"
      }
   }
}

function Cleanup-MergedBranches {
   Write-ColorOutput "🧹 Nettoyage des branches mergées..." "Cyan"
    
   # Lister les branches mergées dans manager-ecosystem
   git checkout $MAIN_BRANCH
   $mergedBranches = git branch --merged $MAIN_BRANCH | Where-Object { 
      $_ -match "feature/" -and $_ -notmatch $MAIN_BRANCH 
   }
    
   if ($mergedBranches) {
      Write-ColorOutput "Branches mergées trouvées:" "Yellow"
      foreach ($branch in $mergedBranches) {
         $cleanBranch = $branch.Trim()
         Write-ColorOutput "  - $cleanBranch" "Blue"
      }
        
      $response = Read-Host "Supprimer ces branches? (y/N)"
      if ($response -eq "y" -or $response -eq "Y") {
         foreach ($branch in $mergedBranches) {
            $cleanBranch = $branch.Trim()
            git branch -d $cleanBranch
         }
         Write-ColorOutput "✅ Nettoyage terminé" "Green"
      }
   }
   else {
      Write-ColorOutput "✅ Aucune branche à nettoyer" "Green"
   }
}

# Point d'entrée principal
param(
   [string]$Command = "",
   [string]$Manager = "",
   [string]$Feature = ""
)

switch ($Command.ToLower()) {
   "status" { Get-BranchStatus }
   "sync" { Sync-AllBranches }
   "switch" { 
      if (-not $Manager) {
         Write-ColorOutput "❌ Manager requis pour la commande switch" "Red"
         Show-Help
         return
      }
      Switch-ToManager $Manager 
   }
   "create-feature" { 
      if (-not $Manager -or -not $Feature) {
         Write-ColorOutput "❌ Manager et Feature requis" "Red"
         Show-Help
         return
      }
      Create-FeatureBranch $Manager $Feature 
   }
   "merge-feature" { 
      if (-not $Manager -or -not $Feature) {
         Write-ColorOutput "❌ Manager et Feature requis" "Red"
         Show-Help
         return
      }
      Merge-FeatureBranch $Manager $Feature 
   }
   "test" { 
      if (-not $Manager) {
         Write-ColorOutput "❌ Manager requis pour les tests" "Red"
         Show-Help
         return
      }
      Test-Manager $Manager 
   }
   "build-all" { Build-AllManagers }
   "cleanup" { Cleanup-MergedBranches }
   "help" { Show-Help }
   default { 
      if ($Command) {
         Write-ColorOutput "❌ Commande '$Command' non reconnue" "Red"
         Write-Host ""
      }
      Show-Help 
   }
}
