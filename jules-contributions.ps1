
# Jules Google Bot Contributions Manager
# System complet de redirection automatique des contributions
# ===   # Rendre le hook exécutable (PowerShell ne peut pas chmod, mais l'info est utile)
Write-Host "  ✓ Hook pre-receive configuré" -ForegroundColor Green
Write-Host "    Note: Rendre exécutable avec 'chmod +x .git/hooks/pre-receive' si nécessaire" -ForegroundColor Gray=======================================================================

param(
   [Parameter(Position = 0)]
   [ValidateSet("setup", "force-redirect", "create-pr-rules", "monitor", "cleanup", "test")]
   [string]$Action = "setup",
    
   [Parameter(Mandatory = $false)]
   [string]$ContributionBranch,
    
   [Parameter(Mandatory = $false)]
   [switch]$Force,
    
   [Parameter(Mandatory = $false)]
   [switch]$DryRun
)

$script:ProjectPath = $PWD.Path
$script:BotName = "google-labs-jules[bot]"

Write-Host "=== GESTIONNAIRE CONTRIBUTIONS JULES GOOGLE BOT ===" -ForegroundColor Cyan
Write-Host "Action: $Action" -ForegroundColor Yellow
Write-Host "Project Path: $script:ProjectPath" -ForegroundColor Gray
Write-Host ""

function Setup-JulesContributionSystem {
   Write-Host "Configuration du système de contributions Jules..." -ForegroundColor Green
    
   # 1. Créer la structure de branches jules-google
   Write-Host "1. Création de la structure jules-google/*" -ForegroundColor Yellow
    
   # Branches pour organiser les contributions par type
   $julesBranches = @(
      "jules-google/features", # Nouvelles fonctionnalités
      "jules-google/fixes", # Corrections de bugs
      "jules-google/docs", # Documentation
      "jules-google/experiments", # Expérimentations
      "jules-google/integrations", # Intégrations
      "jules-google/auto-redirect", # Redirections automatiques
      "jules-google/archive"        # Archives
   )
    
   # Vérifier que jules-google existe
   if (-not (Test-Path ".git\refs\heads\jules-google")) {
      Write-Host "ERREUR: Branche jules-google non trouvée. Créez-la d'abord avec:" -ForegroundColor Red
      Write-Host "  git checkout -b jules-google" -ForegroundColor Yellow
      return $false
   }
    
   # Obtenir le hash de jules-google comme base
   $julesGoogleHash = Get-Content ".git\refs\heads\jules-google" -ErrorAction SilentlyContinue
   if (-not $julesGoogleHash) {
      Write-Host "ERREUR: Impossible de lire le hash de jules-google" -ForegroundColor Red
      return $false
   }
    
   foreach ($branch in $julesBranches) {
      $branchPath = ".git\refs\heads\$($branch -replace '/', '\')"
      $branchDir = Split-Path $branchPath -Parent
        
      if (-not (Test-Path $branchDir)) {
         New-Item -ItemType Directory -Force -Path $branchDir | Out-Null
      }
        
      if (-not (Test-Path $branchPath)) {
         $julesGoogleHash | Out-File $branchPath -Encoding ascii
         Write-Host "  ✓ Créé: $branch" -ForegroundColor Green
      }
      else {
         Write-Host "  → Existe: $branch" -ForegroundColor Yellow
      }
   }
    
   # 2. Créer les hooks Git
   Write-Host "`n2. Configuration des hooks Git" -ForegroundColor Yellow
   Setup-GitHooks
    
   # 3. Créer les règles GitHub Actions
   Write-Host "`n3. Configuration GitHub Actions" -ForegroundColor Yellow
   Setup-GitHubActions
    
   # 4. Créer le script de redirection automatique
   Write-Host "`n4. Script de redirection automatique" -ForegroundColor Yellow
   Create-AutoRedirectScript
    
   # 5. Créer la configuration
   Write-Host "`n5. Configuration système" -ForegroundColor Yellow
   Create-SystemConfiguration
    
   Write-Host "`nSystème de contributions Jules configuré avec succès !" -ForegroundColor Green
   Write-Host "Utilisez './jules-contributions.ps1 monitor' pour surveiller les contributions" -ForegroundColor Cyan
}

function Setup-GitHooks {
   $hooksDir = ".git\hooks"
   if (-not (Test-Path $hooksDir)) {
      New-Item -ItemType Directory -Force -Path $hooksDir | Out-Null
   }
   # Hook pre-receive pour rediriger les pushes du bot
   $preReceiveHook = @"
#!/bin/sh
# Hook pour rediriger les contributions de google-labs-jules[bot]

echo 'Jules Bot Hook: Monitoring contributions...'
# Ce hook sera activé lors du déploiement sur le serveur Git
"@
    
   $preReceiveHook | Out-File "$hooksDir\pre-receive" -Encoding ascii
   
   # Rendre le hook exécutable (PowerShell ne peut pas chmod, mais l'info est utile)
   Write-Host "  ✓ Hook pre-receive configuré" -ForegroundColor Green
   Write-Host "    Note: Rendre exécutable avec 'chmod +x .git/hooks/pre-receive' si nécessaire" -ForegroundColor Gray
}

function Setup-GitHubActions {
   $workflowsDir = ".github\workflows"
   if (-not (Test-Path $workflowsDir)) {
      New-Item -ItemType Directory -Force -Path $workflowsDir | Out-Null
   }
    
   # Workflow principal pour gérer les contributions Jules
   $julesWorkflow = @'
name: Jules Google Bot Contributions Manager

on:
  push:
    branches: ['**']
  pull_request:
    branches: ['**']

jobs:
  manage-jules-contributions:
    runs-on: ubuntu-latest
    if: github.actor == 'google-labs-jules[bot]'
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0
          token: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Configure Git
        run: |
          git config user.name "Jules Contribution Manager"
          git config user.email "actions@github.com"
      
      - name: Redirect Jules Contribution
        run: |
          # Obtenir la branche actuelle
          CURRENT_BRANCH=${{ github.ref_name }}
          
          # Vérifier si c'est déjà sous jules-google/*
          if [[ "$CURRENT_BRANCH" != jules-google/* ]]; then
            echo "Redirection de la contribution Jules..."
            
            # Créer nom de branche avec timestamp
            NEW_BRANCH="jules-google/auto-$(date +%Y%m%d-%H%M%S)-$CURRENT_BRANCH"
            
            # Créer la nouvelle branche
            git checkout -b "$NEW_BRANCH"
            git push origin "$NEW_BRANCH"
            
            # Créer PR vers jules-google si GitHub CLI est disponible
            if command -v gh &> /dev/null; then
              gh pr create \
                --title "🤖 Contribution Jules: $CURRENT_BRANCH" \
                --body "Contribution automatique de google-labs-jules[bot] redirigée vers jules-google/*" \
                --base jules-google \
                --head "$NEW_BRANCH" \
                --label "jules-bot,auto-contribution" || echo "PR creation failed, continuing..."
            fi
            
            # Supprimer la branche originale si pas main/dev/contextual-memory
            if [[ "$CURRENT_BRANCH" != "main" && "$CURRENT_BRANCH" != "dev" && "$CURRENT_BRANCH" != "contextual-memory" ]]; then
              git push origin --delete "$CURRENT_BRANCH" || echo "Failed to delete original branch, continuing..."
            fi
          fi
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

  jules-activity-monitor:
    runs-on: ubuntu-latest
    if: github.actor == 'google-labs-jules[bot]'
    
    steps:
      - name: Log Jules Activity
        run: |
          echo "Jules bot activity detected:"
          echo "  Repository: ${{ github.repository }}"
          echo "  Branch: ${{ github.ref_name }}"
          echo "  Event: ${{ github.event_name }}"
          echo "  Commit: ${{ github.sha }}"
          echo "  Timestamp: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
'@
    
   $julesWorkflow | Out-File "$workflowsDir\jules-contributions.yml" -Encoding UTF8
   Write-Host "  ✓ Workflow GitHub Actions créé: .github/workflows/jules-contributions.yml" -ForegroundColor Green
}

function New-AutoRedirectScript {
   $autoRedirectScript = @'
# =============================================================================
# Script automatique de redirection des contributions Jules
# À exécuter régulièrement pour nettoyer et organiser
# =============================================================================

param(
    [Parameter(Mandatory=$false)]
    [switch]$DryRun,
    
    [Parameter(Mandatory=$false)]
    [switch]$Verbose
)

Write-Host "=== REDIRECTION AUTOMATIQUE CONTRIBUTIONS JULES ===" -ForegroundColor Cyan
Write-Host "Mode: $(if($DryRun){'DRY RUN'}else{'EXECUTION'})" -ForegroundColor $(if($DryRun){'Yellow'}else{'Green'})
Write-Host ""

$protectedBranches = @('main', 'dev', 'contextual-memory', 'jules-google')
$redirectCount = 0

# Rechercher les branches qui ne sont pas sous jules-google/* mais créées par le bot
$allBranches = git branch -r --format='%(refname:short)' | Where-Object { 
    $_ -notmatch '^origin/(main|dev|jules-google|contextual-memory)' -and 
    $_ -notmatch '^origin/jules-google/' 
}

foreach ($branch in $allBranches) {
    if ($branch -match '^origin/(.+)') {
        $branchName = $matches[1]
        
        if ($Verbose) {
            Write-Host "Vérification branche: $branchName" -ForegroundColor Gray
        }
        
        # Vérifier si c'est une contribution Jules (via commit author)
        $lastCommitAuthor = git log --format='%an' "$branch" -1 2>$null
        
        if ($lastCommitAuthor -match 'google-labs-jules.*bot') {
            $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
            $newBranchName = "jules-google/auto-redirect-$timestamp-$branchName"
            
            Write-Host "Détection contribution Jules: $branchName -> $newBranchName" -ForegroundColor Yellow
            
            if (-not $DryRun) {
                try {
                    # Créer la nouvelle branche
                    git checkout -b "$newBranchName" "$branch" 2>$null
                    git push origin "$newBranchName" 2>$null
                    
                    # Supprimer l'ancienne (seulement si pas protégée)
                    if ($branchName -notin $protectedBranches) {
                        git push origin --delete "$branchName" 2>$null
                    }
                    
                    Write-Host "  ✓ Redirigé: $newBranchName" -ForegroundColor Green
                    $redirectCount++
                }
                catch {
                    Write-Host "  ✗ Erreur redirection: $_" -ForegroundColor Red
                }
            } else {
                Write-Host "  → DryRun: $newBranchName" -ForegroundColor Cyan
                $redirectCount++
            }
        }
    }
}

Write-Host ""
if ($redirectCount -eq 0) {
    Write-Host "Aucune contribution Jules à rediriger." -ForegroundColor Green
} else {
    Write-Host "Redirections $(if($DryRun){'simulées'}else{'effectuées'}): $redirectCount" -ForegroundColor $(if($DryRun){'Yellow'}else{'Green'})
}

Write-Host ""
Write-Host "Commandes utiles:" -ForegroundColor Cyan
Write-Host "  .\jules-auto-redirect.ps1 -DryRun      # Simulation" -ForegroundColor White
Write-Host "  .\jules-auto-redirect.ps1 -Verbose     # Mode verbeux" -ForegroundColor White
Write-Host "  .\jules-contributions.ps1 monitor      # Surveillance" -ForegroundColor White
'@
    
   $autoRedirectScript | Out-File "jules-auto-redirect.ps1" -Encoding UTF8
   Write-Host "  ✓ Script auto-redirect créé: jules-auto-redirect.ps1" -ForegroundColor Green
}

function New-SystemConfiguration {
   $configDir = "config"
   if (-not (Test-Path $configDir)) {
      New-Item -ItemType Directory -Force -Path $configDir | Out-Null
   }
    
   $config = @{
      system      = @{
         name    = "Jules Google Bot Contributions Manager"
         version = "1.0.0"
         enabled = $true
      }
      bot         = @{
         name               = $script:BotName
         detection_patterns = @(
            "google-labs-jules[bot]",
            "google-labs-jules\[bot\]"
         )
      }
      redirection = @{
         target_prefix      = "jules-google/"
         auto_redirect      = $true
         preserve_original  = $false
         protected_branches = @("main", "dev", "contextual-memory", "jules-google")
      }
      monitoring  = @{
         enabled          = $true
         interval_seconds = 30
         log_to_file      = $true
         log_file         = "logs/jules-bot-activity.log"
      }
   } | ConvertTo-Json -Depth 10
    
   $config | Out-File "$configDir\jules-bot-config.json" -Encoding UTF8
   Write-Host "  ✓ Configuration créée: config/jules-bot-config.json" -ForegroundColor Green
}

function Force-RedirectContribution {
   param([string]$BranchName)
    
   Write-Host "Redirection forcée de la contribution: $BranchName" -ForegroundColor Yellow
    
   if (-not $BranchName) {
      Write-Host "ERREUR: Nom de branche requis" -ForegroundColor Red
      Write-Host "Usage: .\jules-contributions.ps1 force-redirect -ContributionBranch 'nom-branche'" -ForegroundColor Yellow
      return
   }
    
   # Vérifier si la branche existe
   if (-not (Test-Path ".git\refs\heads\$BranchName")) {
      Write-Host "ERREUR: Branche $BranchName introuvable" -ForegroundColor Red
      return
   }
    
   # Créer le nouveau nom de branche
   $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
   $newBranchName = "jules-google/manual-redirect-$timestamp-$BranchName"
    
   # Obtenir le hash de commit
   $commitHash = Get-Content ".git\refs\heads\$BranchName"
    
   # Créer le répertoire si nécessaire
   $newBranchPath = ".git\refs\heads\$($newBranchName -replace '/', '\')"
   $newBranchDir = Split-Path $newBranchPath -Parent
   if (-not (Test-Path $newBranchDir)) {
      New-Item -ItemType Directory -Force -Path $newBranchDir | Out-Null
   }
    
   # Créer la nouvelle branche
   $commitHash | Out-File $newBranchPath -Encoding ascii
    
   Write-Host "✓ Contribution redirigée vers: $newBranchName" -ForegroundColor Green
    
   # Proposer de supprimer l'ancienne branche
   if ($Force) {
      Remove-Item ".git\refs\heads\$BranchName" -Force
      Write-Host "✓ Ancienne branche supprimée: $BranchName" -ForegroundColor Green
   }
   else {
      Write-Host "⚠ Ancienne branche conservée. Utilisez -Force pour la supprimer." -ForegroundColor Yellow
   }
}

function Monitor-JulesContributions {
   Write-Host "Monitoring des contributions Jules..." -ForegroundColor Green
    
   # Lister toutes les branches jules-google/*
   Write-Host "`nBranches Jules Google:" -ForegroundColor Yellow
   $julesCount = 0
   
   if (Test-Path ".git\refs\heads\jules-google") {
      Get-ChildItem ".git\refs\heads\jules-google" -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
         $branchName = $_.FullName -replace '.*\\refs\\heads\\', '' -replace '\\', '/'
         $hash = Get-Content $_.FullName
         $shortHash = $hash.Substring(0, 8)
         Write-Host "  $branchName : $shortHash" -ForegroundColor Cyan
         $julesCount++
      }
   }
    
   # Statistiques branches principales
   Write-Host "`nBranches principales:" -ForegroundColor Yellow
   @("main", "dev", "contextual-memory", "jules-google") | ForEach-Object {
      if (Test-Path ".git\refs\heads\$_") {
         $hash = Get-Content ".git\refs\heads\$_"
         $shortHash = $hash.Substring(0, 8)
         Write-Host "  $_ : $shortHash" -ForegroundColor White
      }
   }
    
   # Recherche de contributions non redirigées
   Write-Host "`nRecherche contributions non redirigées..." -ForegroundColor Yellow
   $unredirectedCount = 0
   
   try {
      $allBranches = git branch -r --format='%(refname:short)' 2>$null | Where-Object { 
         $_ -notmatch '^origin/(main|dev|contextual-memory|jules-google)' -and 
         $_ -notmatch '^origin/jules-google/' 
      }
      
      foreach ($branch in $allBranches) {
         if ($branch -match '^origin/(.+)') {
            $branchName = $matches[1]
            $lastCommitAuthor = git log --format='%an' "$branch" -1 2>$null
            
            if ($lastCommitAuthor -match 'google-labs-jules.*bot') {
               Write-Host "  ⚠ Non redirigée: $branchName (par $lastCommitAuthor)" -ForegroundColor Red
               $unredirectedCount++
            }
         }
      }
   }
   catch {
      Write-Host "  Erreur lors de la recherche: $_" -ForegroundColor Red
   }
    
   # Résumé
   Write-Host "`n=== RÉSUMÉ ===" -ForegroundColor Cyan
   Write-Host "Total contributions Jules: $julesCount" -ForegroundColor Green
   Write-Host "Contributions non redirigées: $unredirectedCount" -ForegroundColor $(if ($unredirectedCount -eq 0) { 'Green' }else { 'Red' })
   
   if ($unredirectedCount -gt 0) {
      Write-Host "`nActions recommandées:" -ForegroundColor Yellow
      Write-Host "  .\jules-auto-redirect.ps1          # Redirection automatique" -ForegroundColor White
      Write-Host "  .\jules-auto-redirect.ps1 -DryRun  # Simulation d'abord" -ForegroundColor White
   }
}

function Test-JulesSystem {
   Write-Host "Test du système Jules..." -ForegroundColor Green
    
   # Test 1: Vérifier la structure
   Write-Host "`n1. Vérification structure..." -ForegroundColor Yellow
   $structureOK = $true
   
   @(".git", ".github", ".github\workflows", "config") | ForEach-Object {
      if (Test-Path $_) {
         Write-Host "  ✓ $_" -ForegroundColor Green
      }
      else {
         Write-Host "  ✗ $_" -ForegroundColor Red
         $structureOK = $false
      }
   }
    
   # Test 2: Vérifier les fichiers
   Write-Host "`n2. Vérification fichiers..." -ForegroundColor Yellow
   $filesOK = $true
   
   @(
      ".github\workflows\jules-contributions.yml",
      "config\jules-bot-config.json",
      "jules-auto-redirect.ps1"
   ) | ForEach-Object {
      if (Test-Path $_) {
         Write-Host "  ✓ $_" -ForegroundColor Green
      }
      else {
         Write-Host "  ✗ $_" -ForegroundColor Red
         $filesOK = $false
      }
   }
    
   # Test 3: Vérifier les branches
   Write-Host "`n3. Vérification branches..." -ForegroundColor Yellow
   $branchesOK = $true
   
   @("main", "dev", "contextual-memory", "jules-google") | ForEach-Object {
      if (Test-Path ".git\refs\heads\$_") {
         Write-Host "  ✓ $_" -ForegroundColor Green
      }
      else {
         Write-Host "  ✗ $_" -ForegroundColor Red
         $branchesOK = $false
      }
   }
    
   # Résultat final
   Write-Host "`n=== RÉSULTAT TEST ===" -ForegroundColor Cyan
   $allOK = $structureOK -and $filesOK -and $branchesOK
   
   if ($allOK) {
      Write-Host "✓ Système Jules OPÉRATIONNEL" -ForegroundColor Green
   }
   else {
      Write-Host "✗ Système Jules INCOMPLET" -ForegroundColor Red
      Write-Host "Exécutez: .\jules-contributions.ps1 setup" -ForegroundColor Yellow
   }
}

# Exécution selon l'action
switch ($Action.ToLower()) {
   "setup" { 
      Setup-JulesContributionSystem 
   }
   "force-redirect" { 
      Force-RedirectContribution $ContributionBranch 
   }
   "monitor" { 
      Monitor-JulesContributions 
   }
   "test" {
      Test-JulesSystem
   }
   "cleanup" {
      Write-Host "Nettoyage système Jules..." -ForegroundColor Yellow
      # TODO: Implémenter nettoyage
      Write-Host "Fonctionnalité à implémenter" -ForegroundColor Gray
   }
   default { 
      Setup-JulesContributionSystem 
   }
}

Write-Host ""
Write-Host "=== COMMANDES DISPONIBLES ===" -ForegroundColor Cyan
Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  .\jules-contributions.ps1 setup                    # Configuration initiale" -ForegroundColor White
Write-Host "  .\jules-contributions.ps1 test                     # Test du système" -ForegroundColor White
Write-Host ""
Write-Host "Gestion:" -ForegroundColor Yellow
Write-Host "  .\jules-contributions.ps1 force-redirect [branch]  # Redirection manuelle" -ForegroundColor White
Write-Host "  .\jules-contributions.ps1 monitor                  # Surveillance" -ForegroundColor White
Write-Host ""
Write-Host "Automatisation:" -ForegroundColor Yellow
Write-Host "  .\jules-auto-redirect.ps1                         # Redirection automatique" -ForegroundColor White
Write-Host "  .\jules-auto-redirect.ps1 -DryRun                 # Simulation" -ForegroundColor White
Write-Host "  .\jules-realtime-monitor.ps1                      # Monitoring temps réel" -ForegroundColor White

