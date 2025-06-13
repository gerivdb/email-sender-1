
# 🌳 BRANCH MANAGER - EMAIL_SENDER_1 Specialized Error Resolution System
# ================================================================================================
# Script de gestion avancée des branches pour l'organisation des corrections d'erreurs
# Basé sur la structure documentée dans BRANCH_MANAGEMENT_STRUCTURE.md

param(
   [ValidateSet("Status", "Switch", "Create", "Push", "Merge", "List", "Sync", "Priority", "CurrentBranch")]
   [string]$Action = "Status",
    
   [string]$BranchName,
   [string]$ManagerName,
   [switch]$All,
   [switch]$Force,
   [switch]$DryRun
)

# Couleurs pour l'affichage
$Colors = @{
   Urgent  = "Red"
   High    = "Yellow" 
   Medium  = "Cyan"
   Low     = "Gray"
   Success = "Green"
   Warning = "DarkYellow"
   Info    = "White"
   Error   = "Red"
}

# Structure des managers et leurs priorités
$BranchManagers = @{
   "manager/ci-cd-fixes"             = @{
      Priority    = 1
      Level       = "URGENT"
      Color       = $Colors.Urgent
      Description = "Résolution des conflits de merge et workflows GitHub Actions"
      SubBranches = @(
         "fix/go-workflow-yaml-syntax",
         "fix/github-actions-yaml", 
         "fix/workflow-validation"
      )
      Errors      = @(
         "Conflits Git <<<<<<< HEAD / >>>>>>> origin/fix/go-workflow-yaml-syntax",
         "Erreurs YAML dans .github/workflows/go-quality.yml",
         "Problèmes d'indentation et structure YAML"
      )
   }
   "manager/jules-bot-system"        = @{
      Priority    = 2
      Level       = "HIGH"
      Color       = $Colors.High
      Description = "Système complet de gestion des contributions Jules Bot"
      SubBranches = @(
         "feature/jules-bot-workflows",
         "fix/jules-bot-redirect",
         "fix/jules-bot-validator",
         "feature/bot-contribution-detection"
      )
      Errors      = @(
         "jules-bot-redirect.yml - Types boolean/string incorrects",
         "jules-bot-validator.yml - Problèmes d'indentation YAML",
         "jules-contributions.yml - Erreurs de structure YAML",
         "Context access invalides dans les workflows"
      )
   }
   "manager/go-development"          = @{
      Priority    = 3
      Level       = "MEDIUM"
      Color       = $Colors.Medium
      Description = "Architecture Go et résolution des problèmes d'imports"
      SubBranches = @(
         "fix/go-imports",
         "fix/go-package-structure", 
         "fix/manager-toolkit-import"
      )
      Errors      = @(
         "validation_test_phase1.1.go - Import package incompatible",
         "manager-toolkit package import errors",
         "Incompatibilité types toolkit.Operation"
      )
   }
   "manager/powershell-optimization" = @{
      Priority    = 4
      Level       = "LOW"
      Color       = $Colors.Low
      Description = "Nettoyage et optimisation des scripts PowerShell"
      SubBranches = @(
         "refactor/powershell-scripts",
         "fix/powershell-warnings",
         "cleanup/unused-variables"
      )
      Errors      = @(
         "Variables non utilisées (\$gitStatus, \$scriptResult, etc.)",
         "Verbes non approuvés (Setup-, Create-, Force-, etc.)",
         "Comparaisons null incorrectes",
         "Paramètres switch par défaut"
      )
   }
}

function Write-Banner {
   param([string]$Title, [string]$Color = "White")
    
   Write-Host ""
   Write-Host "═══════════════════════════════════════════════════════════════════════════════════" -ForegroundColor $Color
   Write-Host "🌳 $Title" -ForegroundColor $Color
   Write-Host "═══════════════════════════════════════════════════════════════════════════════════" -ForegroundColor $Color
   Write-Host ""
}

function Get-CurrentBranch {
   try {
      $branch = git rev-parse --abbrev-ref HEAD 2>$null
      if ($LASTEXITCODE -eq 0) {
         return $branch.Trim()
      }
   }
   catch {}
   return "unknown"
}

function Get-BranchStatus {
   param([string]$Branch)
    
   try {
      git show-ref --verify --quiet refs/heads/$Branch 2>$null
      if ($LASTEXITCODE -eq 0) {
         return "✅ Exists"
      }
      else {
         return "❌ Missing"
      }
   }
   catch {
      return "❓ Unknown"
   }
}

function Show-BranchStatus {
   Write-Banner "BRANCH MANAGEMENT STATUS" $Colors.Info
    
   $currentBranch = Get-CurrentBranch
   Write-Host "📍 Branche actuelle: " -NoNewline -ForegroundColor $Colors.Info
   Write-Host $currentBranch -ForegroundColor $Colors.Success
   Write-Host ""
    
   $sortedManagers = $BranchManagers.GetEnumerator() | Sort-Object { $_.Value.Priority }
    
   foreach ($manager in $sortedManagers) {
      $managerName = $manager.Key
      $config = $manager.Value
        
      Write-Host "🔥 PRIORITÉ $($config.Priority) - $($config.Level)" -ForegroundColor $config.Color
      Write-Host "📂 $managerName" -ForegroundColor White
      Write-Host "📝 $($config.Description)" -ForegroundColor Gray
        
      $managerStatus = Get-BranchStatus $managerName
      Write-Host "   Status: $managerStatus" -ForegroundColor $(if ($managerStatus -like "*Exists*") { $Colors.Success } else { $Colors.Error })
        
      Write-Host ""
      Write-Host "   Sous-branches:" -ForegroundColor $Colors.Info
      foreach ($subBranch in $config.SubBranches) {
         $status = Get-BranchStatus $subBranch
         $statusColor = if ($status -like "*Exists*") { $Colors.Success } else { $Colors.Error }
         Write-Host "   • $subBranch - $status" -ForegroundColor $statusColor
      }
        
      Write-Host ""
      Write-Host "   Erreurs ciblées:" -ForegroundColor $Colors.Warning
      foreach ($error in $config.Errors) {
         Write-Host "   • $error" -ForegroundColor Gray
      }
        
      Write-Host ""
      Write-Host "────────────────────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
      Write-Host ""
   }
}

function Switch-ToBranch {
   param([string]$TargetBranch)
    
   if (-not $TargetBranch) {
      Write-Host "❌ Nom de branche requis pour l'action Switch" -ForegroundColor $Colors.Error
      return
   }
    
   Write-Host "🔄 Changement vers la branche: $TargetBranch" -ForegroundColor $Colors.Info
    
   if ($DryRun) {
      Write-Host "🔍 [DRY-RUN] git checkout $TargetBranch" -ForegroundColor $Colors.Warning
      return
   }
    
   git checkout $TargetBranch
   if ($LASTEXITCODE -eq 0) {
      Write-Host "✅ Changement vers $TargetBranch réussi" -ForegroundColor $Colors.Success
   }
   else {
      Write-Host "❌ Échec du changement vers $TargetBranch" -ForegroundColor $Colors.Error
   }
}

function Create-ManagerBranches {
   Write-Banner "CRÉATION DES BRANCHES MANAGERS" $Colors.Info
    
   foreach ($manager in $BranchManagers.Keys) {
      Write-Host "📂 Création du manager: $manager" -ForegroundColor $Colors.Info
        
      if ($DryRun) {
         Write-Host "🔍 [DRY-RUN] git checkout -b $manager" -ForegroundColor $Colors.Warning
      }
      else {
         $status = Get-BranchStatus $manager
         if ($status -like "*Missing*") {
            git checkout -b $manager
            if ($LASTEXITCODE -eq 0) {
               Write-Host "✅ Manager $manager créé" -ForegroundColor $Colors.Success
            }
            else {
               Write-Host "❌ Échec création $manager" -ForegroundColor $Colors.Error
            }
         }
         else {
            Write-Host "ℹ️  Manager $manager existe déjà" -ForegroundColor $Colors.Info
         }
      }
        
      # Créer les sous-branches
      $config = $BranchManagers[$manager]
      foreach ($subBranch in $config.SubBranches) {
         Write-Host "  📄 Création sous-branche: $subBranch" -ForegroundColor Gray
            
         if ($DryRun) {
            Write-Host "  🔍 [DRY-RUN] git checkout -b $subBranch" -ForegroundColor $Colors.Warning
         }
         else {
            $status = Get-BranchStatus $subBranch
            if ($status -like "*Missing*") {
               git checkout -b $subBranch
               if ($LASTEXITCODE -eq 0) {
                  Write-Host "  ✅ Sous-branche $subBranch créée" -ForegroundColor $Colors.Success
               }
               else {
                  Write-Host "  ❌ Échec création $subBranch" -ForegroundColor $Colors.Error
               }
            }
            else {
               Write-Host "  ℹ️  Sous-branche $subBranch existe déjà" -ForegroundColor $Colors.Info
            }
         }
      }
      Write-Host ""
   }
}

function Push-AllBranches {
   Write-Banner "SYNCHRONISATION REMOTE" $Colors.Info
    
   if ($DryRun) {
      Write-Host "🔍 [DRY-RUN] Mode actif - aucune action ne sera exécutée" -ForegroundColor $Colors.Warning
      Write-Host ""
   }
    
   # Pousser les managers
   foreach ($manager in $BranchManagers.Keys) {
      Write-Host "📤 Push manager: $manager" -ForegroundColor $Colors.Info
        
      if ($DryRun) {
         Write-Host "🔍 [DRY-RUN] git push origin $manager" -ForegroundColor $Colors.Warning
      }
      else {
         git push origin $manager
         if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Push $manager réussi" -ForegroundColor $Colors.Success
         }
         else {
            Write-Host "❌ Échec push $manager" -ForegroundColor $Colors.Error
         }
      }
   }
    
   # Pousser toutes les autres branches
   Write-Host ""
   Write-Host "📤 Push de toutes les sous-branches..." -ForegroundColor $Colors.Info
    
   if ($DryRun) {
      Write-Host "🔍 [DRY-RUN] git push origin --all" -ForegroundColor $Colors.Warning
   }
   else {
      git push origin --all
      if ($LASTEXITCODE -eq 0) {
         Write-Host "✅ Push de toutes les branches réussi" -ForegroundColor $Colors.Success
      }
      else {
         Write-Host "❌ Échec push de toutes les branches" -ForegroundColor $Colors.Error
      }
   }
}

function Show-PriorityQueue {
   Write-Banner "ORDRE DE TRAITEMENT PRIORITÉ" $Colors.Info
    
   $sortedManagers = $BranchManagers.GetEnumerator() | Sort-Object { $_.Value.Priority }
    
   Write-Host "🚦 Ordre recommandé de traitement des erreurs:" -ForegroundColor $Colors.Info
   Write-Host ""
    
   foreach ($manager in $sortedManagers) {
      $config = $manager.Value
      $priority = switch ($config.Priority) {
         1 { "🔥 IMMÉDIAT" }
         2 { "🚀 URGENT" }
         3 { "🔧 MEDIUM" }
         4 { "🧹 LOW" }
      }
        
      Write-Host "$priority : $($manager.Key)" -ForegroundColor $config.Color
        
      # Montrer la première sous-branche comme action immédiate
      if ($config.SubBranches.Count -gt 0) {
         Write-Host "   → Action immédiate: $($config.SubBranches[0])" -ForegroundColor Gray
      }
      Write-Host ""
   }
    
   Write-Host "📋 Commandes rapides:" -ForegroundColor $Colors.Info
   Write-Host "• .\branch-manager.ps1 -Action Switch -BranchName 'fix/go-workflow-yaml-syntax'" -ForegroundColor Gray
   Write-Host "• .\urgent-fix.ps1 -AutoResolve -Backup" -ForegroundColor Gray
   Write-Host "• .\branch-manager.ps1 -Action Push -All" -ForegroundColor Gray
   Write-Host ""
}

function Merge-SubBranch {
   param([string]$SubBranch, [string]$Manager)
    
   if (-not $SubBranch) {
      Write-Host "❌ Nom de sous-branche requis" -ForegroundColor $Colors.Error
      return
   }
    
   if (-not $Manager) {
      # Déterminer automatiquement le manager
      foreach ($mgr in $BranchManagers.Keys) {
         if ($BranchManagers[$mgr].SubBranches -contains $SubBranch) {
            $Manager = $mgr
            break
         }
      }
   }
    
   if (-not $Manager) {
      Write-Host "❌ Impossible de déterminer le manager pour $SubBranch" -ForegroundColor $Colors.Error
      return
   }
    
   Write-Host "🔄 Merge de $SubBranch vers $Manager" -ForegroundColor $Colors.Info
    
   if ($DryRun) {
      Write-Host "🔍 [DRY-RUN] git checkout $Manager" -ForegroundColor $Colors.Warning
      Write-Host "🔍 [DRY-RUN] git merge $SubBranch" -ForegroundColor $Colors.Warning
      return
   }
    
   # Changement vers le manager
   git checkout $Manager
   if ($LASTEXITCODE -ne 0) {
      Write-Host "❌ Échec du changement vers $Manager" -ForegroundColor $Colors.Error
      return
   }
    
   # Merge de la sous-branche
   git merge $SubBranch
   if ($LASTEXITCODE -eq 0) {
      Write-Host "✅ Merge de $SubBranch vers $Manager réussi" -ForegroundColor $Colors.Success
   }
   else {
      Write-Host "❌ Échec du merge - conflits possibles" -ForegroundColor $Colors.Error
   }
}

function Show-BranchList {
   Write-Banner "LISTE DES BRANCHES DISPONIBLES" $Colors.Info
    
   Write-Host "📋 Branches existantes:" -ForegroundColor $Colors.Info
   git branch --list
    
   Write-Host ""
   Write-Host "📋 Branches remote:" -ForegroundColor $Colors.Info
   git branch -r
}

# Fonction principale d'exécution
switch ($Action) {
   "Status" { Show-BranchStatus }
   "CurrentBranch" { 
      $current = Get-CurrentBranch
      Write-Host "📍 Branche actuelle: $current" -ForegroundColor $Colors.Success
   }
   "Switch" { Switch-ToBranch -TargetBranch $BranchName }
   "Create" { Create-ManagerBranches }
   "Push" { Push-AllBranches }
   "Merge" { Merge-SubBranch -SubBranch $BranchName -Manager $ManagerName }
   "List" { Show-BranchList }
   "Priority" { Show-PriorityQueue }
   "Sync" { 
      Create-ManagerBranches
      Push-AllBranches
   }
   default { Show-BranchStatus }
}

Write-Host ""
Write-Host "🔗 Pour plus d'informations: voir BRANCH_MANAGEMENT_STRUCTURE.md" -ForegroundColor $Colors.Info
Write-Host ""
