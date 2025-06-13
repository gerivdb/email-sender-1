# =============================================================================
# Jules Google Bot Contributions Manager
# System complet de redirection automatique des contributions
# =============================================================================

param(
   [Parameter(Position = 0)]
   [ValidateSet("setup", "force-redirect", "monitor", "test")]
   [string]$Action = "setup",
    
   [Parameter(Mandatory = $false)]
   [string]$ContributionBranch,
    
   [Parameter(Mandatory = $false)]
   [switch]$Force
)

$ProjectPath = $PWD.Path
$BotName = "google-labs-jules[bot]"

Write-Host "=== GESTIONNAIRE CONTRIBUTIONS JULES GOOGLE BOT ===" -ForegroundColor Cyan
Write-Host "Action: $Action" -ForegroundColor Yellow
Write-Host "Project Path: $ProjectPath" -ForegroundColor Gray
Write-Host ""

function Initialize-JulesContributionSystem {
   Write-Host "Configuration du systeme de contributions Jules..." -ForegroundColor Green
    
   # 1. Creer la structure de branches jules-google
   Write-Host "1. Creation de la structure jules-google/*" -ForegroundColor Yellow
    
   # Branches pour organiser les contributions par type
   $julesBranches = @(
      "jules-google/features", # Nouvelles fonctionnalites
      "jules-google/fixes", # Corrections de bugs
      "jules-google/docs", # Documentation
      "jules-google/experiments", # Experimentations
      "jules-google/integrations", # Integrations
      "jules-google/auto-redirect", # Redirections automatiques
      "jules-google/archive"        # Archives
   )
    
   # Verifier que jules-google existe
   if (-not (Test-Path ".git\refs\heads\jules-google")) {
      Write-Host "ERREUR: Branche jules-google non trouvee. Creez-la d'abord avec:" -ForegroundColor Red
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
         Write-Host "  ✓ Cree: $branch" -ForegroundColor Green
      }
      else {
         Write-Host "  → Existe: $branch" -ForegroundColor Yellow
      }
   }
    
   # 2. Creer les hooks Git
   Write-Host "`n2. Configuration des hooks Git" -ForegroundColor Yellow
   Initialize-GitHooks
    
   # 3. Creer les regles GitHub Actions
   Write-Host "`n3. Configuration GitHub Actions" -ForegroundColor Yellow
   Initialize-GitHubActions
    
   # 4. Creer le script de redirection automatique
   Write-Host "`n4. Script de redirection automatique" -ForegroundColor Yellow
   New-AutoRedirectScript
    
   # 5. Creer la configuration
   Write-Host "`n5. Configuration systeme" -ForegroundColor Yellow
   New-SystemConfiguration
    
   Write-Host "`nSysteme de contributions Jules configure avec succes !" -ForegroundColor Green
   Write-Host "Utilisez './jules-contributions.ps1 monitor' pour surveiller les contributions" -ForegroundColor Cyan
}

function Initialize-GitHooks {
   $hooksDir = ".git\hooks"
   if (-not (Test-Path $hooksDir)) {
      New-Item -ItemType Directory -Force -Path $hooksDir | Out-Null
   }
    
   # Hook pre-receive simple pour rediriger les pushes du bot
   $preReceiveHook = @"
#!/bin/sh
# Hook pour rediriger les contributions de google-labs-jules[bot]
echo 'Jules Bot Hook: Monitoring contributions...'
# Ce hook sera active lors du deploiement sur le serveur Git
"@
    
   $hookPath = Join-Path $hooksDir "pre-receive"
   $preReceiveHook | Out-File $hookPath -Encoding ascii
   
   Write-Host "  ✓ Hook pre-receive configure" -ForegroundColor Green
}

function Initialize-GitHubActions {
   $workflowsDir = ".github\workflows"
   if (-not (Test-Path $workflowsDir)) {
      New-Item -ItemType Directory -Force -Path $workflowsDir | Out-Null
   }
    
   # Workflow principal pour gerer les contributions Jules
   $julesWorkflow = @"
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
      
      - name: Configure Git
        run: |
          git config user.name "Jules Contribution Manager"
          git config user.email "actions@github.com"
        - name: Redirect Jules Contribution
        run: |
          echo "Jules bot activity detected on branch: `${{ github.ref_name }}"
        env:
          GITHUB_TOKEN: `${{ secrets.GITHUB_TOKEN }}

  jules-activity-monitor:
    runs-on: ubuntu-latest
    if: github.actor == 'google-labs-jules[bot]'
    
    steps:      - name: Log Jules Activity
        run: |
          echo "Jules bot activity detected"
          echo "Repository: `${{ github.repository }}"
          echo "Branch: `${{ github.ref_name }}"
"@
    
   $workflowPath = Join-Path $workflowsDir "jules-contributions.yml"
   $julesWorkflow | Out-File $workflowPath -Encoding UTF8
   Write-Host "  ✓ Workflow GitHub Actions cree: .github/workflows/jules-contributions.yml" -ForegroundColor Green
}

function New-AutoRedirectScript {
   $autoRedirectScript = @'
# =============================================================================
# Script automatique de redirection des contributions Jules
# A executer regulierement pour nettoyer et organiser
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

# Rechercher les branches qui ne sont pas sous jules-google/* mais creees par le bot
$allBranches = git branch -r --format='%(refname:short)' | Where-Object { 
    $_ -notmatch '^origin/(main|dev|jules-google|contextual-memory)' -and 
    $_ -notmatch '^origin/jules-google/' 
}

foreach ($branch in $allBranches) {
    if ($branch -match '^origin/(.+)') {
        $branchName = $matches[1]
        
        if ($Verbose) {
            Write-Host "Verification branche: $branchName" -ForegroundColor Gray
        }
        
        # Verifier si c'est une contribution Jules (via commit author)
        $lastCommitAuthor = git log --format='%an' "$branch" -1 2>$null
        
        if ($lastCommitAuthor -match 'google-labs-jules.*bot') {
            $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
            $newBranchName = "jules-google/auto-redirect-$timestamp-$branchName"
            
            Write-Host "Detection contribution Jules: $branchName -> $newBranchName" -ForegroundColor Yellow
            
            if (-not $DryRun) {
                try {
                    # Creer la nouvelle branche
                    git checkout -b "$newBranchName" "$branch" 2>$null
                    git push origin "$newBranchName" 2>$null
                    
                    # Supprimer l'ancienne (seulement si pas protegee)
                    if ($branchName -notin $protectedBranches) {
                        git push origin --delete "$branchName" 2>$null
                    }
                    
                    Write-Host "  ✓ Redirige: $newBranchName" -ForegroundColor Green
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
    Write-Host "Aucune contribution Jules a rediriger." -ForegroundColor Green
} else {
    Write-Host "Redirections $(if($DryRun){'simulees'}else{'effectuees'}): $redirectCount" -ForegroundColor $(if($DryRun){'Yellow'}else{'Green'})
}
'@
    
   $scriptPath = "jules-auto-redirect.ps1"
   $autoRedirectScript | Out-File $scriptPath -Encoding UTF8
   Write-Host "  ✓ Script auto-redirect cree: jules-auto-redirect.ps1" -ForegroundColor Green
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
         name               = $BotName
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
    
   $configPath = Join-Path $configDir "jules-bot-config.json"
   $config | Out-File $configPath -Encoding UTF8
   Write-Host "  ✓ Configuration creee: config/jules-bot-config.json" -ForegroundColor Green
}

function Invoke-RedirectContribution {
   param([string]$BranchName)
    
   Write-Host "Redirection forcee de la contribution: $BranchName" -ForegroundColor Yellow
    
   if (-not $BranchName) {
      Write-Host "ERREUR: Nom de branche requis" -ForegroundColor Red
      Write-Host "Usage: .\jules-contributions.ps1 force-redirect -ContributionBranch 'nom-branche'" -ForegroundColor Yellow
      return
   }
    
   # Verifier si la branche existe
   if (-not (Test-Path ".git\refs\heads\$BranchName")) {
      Write-Host "ERREUR: Branche $BranchName introuvable" -ForegroundColor Red
      return
   }
    
   # Creer le nouveau nom de branche
   $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
   $newBranchName = "jules-google/manual-redirect-$timestamp-$BranchName"
    
   # Obtenir le hash de commit
   $commitHash = Get-Content ".git\refs\heads\$BranchName"
    
   # Creer le repertoire si necessaire
   $newBranchPath = ".git\refs\heads\$($newBranchName -replace '/', '\')"
   $newBranchDir = Split-Path $newBranchPath -Parent
   if (-not (Test-Path $newBranchDir)) {
      New-Item -ItemType Directory -Force -Path $newBranchDir | Out-Null
   }
    
   # Creer la nouvelle branche
   $commitHash | Out-File $newBranchPath -Encoding ascii
    
   Write-Host "✓ Contribution redirigee vers: $newBranchName" -ForegroundColor Green
    
   # Proposer de supprimer l'ancienne branche
   if ($Force) {
      Remove-Item ".git\refs\heads\$BranchName" -Force
      Write-Host "✓ Ancienne branche supprimee: $BranchName" -ForegroundColor Green
   }
   else {
      Write-Host "⚠ Ancienne branche conservee. Utilisez -Force pour la supprimer." -ForegroundColor Yellow
   }
}

function Show-JulesContributions {
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
    
   # Resume
   Write-Host "`n=== RESUME ===" -ForegroundColor Cyan
   Write-Host "Total contributions Jules: $julesCount" -ForegroundColor Green
}

function Test-JulesSystem {
   Write-Host "Test du systeme Jules..." -ForegroundColor Green
    
   # Test 1: Verifier la structure
   Write-Host "`n1. Verification structure..." -ForegroundColor Yellow
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
    
   # Test 2: Verifier les fichiers
   Write-Host "`n2. Verification fichiers..." -ForegroundColor Yellow
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
    
   # Test 3: Verifier les branches
   Write-Host "`n3. Verification branches..." -ForegroundColor Yellow
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
    
   # Resultat final
   Write-Host "`n=== RESULTAT TEST ===" -ForegroundColor Cyan
   $allOK = $structureOK -and $filesOK -and $branchesOK
   
   if ($allOK) {
      Write-Host "✓ Systeme Jules OPERATIONNEL" -ForegroundColor Green
   }
   else {
      Write-Host "✗ Systeme Jules INCOMPLET" -ForegroundColor Red
      Write-Host "Executez: .\jules-contributions.ps1 setup" -ForegroundColor Yellow
   }
}

# Execution selon l'action
switch ($Action.ToLower()) {
   "setup" { 
      Initialize-JulesContributionSystem 
   }
   "force-redirect" { 
      Invoke-RedirectContribution $ContributionBranch 
   }
   "monitor" { 
      Show-JulesContributions 
   }
   "test" {
      Test-JulesSystem
   }
   default { 
      Initialize-JulesContributionSystem 
   }
}

Write-Host ""
Write-Host "=== COMMANDES DISPONIBLES ===" -ForegroundColor Cyan
Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  .\jules-contributions.ps1 setup                    # Configuration initiale" -ForegroundColor White
Write-Host "  .\jules-contributions.ps1 test                     # Test du systeme" -ForegroundColor White
Write-Host ""
Write-Host "Gestion:" -ForegroundColor Yellow
Write-Host "  .\jules-contributions.ps1 force-redirect [branch]  # Redirection manuelle" -ForegroundColor White
Write-Host "  .\jules-contributions.ps1 monitor                  # Surveillance" -ForegroundColor White
Write-Host ""
Write-Host "Automatisation:" -ForegroundColor Yellow
Write-Host "  .\jules-auto-redirect.ps1                         # Redirection automatique" -ForegroundColor White
Write-Host "  .\jules-realtime-monitor.ps1                      # Monitoring temps reel" -ForegroundColor White
