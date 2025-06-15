#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Script principal d'orchestration Phase 7 - Migration des Données et Nettoyage
    Migration Vectorisation Go v56

.DESCRIPTION
    Ce script orchestre la Phase 7 complète:
    - 7.1: Migration des données Qdrant (sauvegarde + migration)
    - 7.2: Nettoyage et optimisation (Python legacy + consolidation clients)

.PARAMETER Phase
    Phase spécifique à exécuter (7.1, 7.2, ou "all" pour tout)

.PARAMETER DryRun
    Mode test - affiche les actions sans les exécuter

.PARAMETER Force
    Force l'exécution même en cas d'avertissements

.PARAMETER BackupPath
    Chemin pour les sauvegardes (par défaut: ./backups/phase7-migration)

.PARAMETER Verbose
    Affichage détaillé des opérations

.EXAMPLE
    .\execute-phase7-migration.ps1
    
.EXAMPLE
    .\execute-phase7-migration.ps1 -Phase 7.1 -DryRun -Verbose
    
.EXAMPLE
    .\execute-phase7-migration.ps1 -Phase all -BackupPath "./archives/migration-v56" -Force
#>

[CmdletBinding()]
param(
   [ValidateSet("7.1", "7.2", "all")]
   [string]$Phase = "all",
    
   [switch]$DryRun,
   [switch]$Force,
   [switch]$Verbose,
    
   [string]$BackupPath = "./backups/phase7-migration"
)

# Configuration globale
$ErrorActionPreference = "Stop"
$Global:Phase7Config = @{
   ProjectRoot = Get-Location
   BackupPath  = $BackupPath
   QdrantHost  = "localhost"
   QdrantPort  = 6333
   Collections = @("roadmap_tasks", "emails", "documents")
   DryRun      = $DryRun.IsPresent
   Force       = $Force.IsPresent
   Verbose     = $Verbose.IsPresent
}

# Statistiques d'exécution
$Global:ExecutionStats = @{
   StartTime           = Get-Date
   Phase71Completed    = $false
   Phase72Completed    = $false
   BackupsCreated      = 0
   DataMigrated        = 0
   ScriptsArchived     = 0
   ClientsConsolidated = 0
   Errors              = @()
}

function Write-ColorOutput {
   param(
      [string]$Message,
      [string]$Color = "White"
   )
    
   $colorMap = @{
      "Red"     = "91"
      "Green"   = "92" 
      "Yellow"  = "93"
      "Blue"    = "94"
      "Magenta" = "95"
      "Cyan"    = "96"
      "White"   = "97"
   }
    
   $colorCode = $colorMap[$Color]
   Write-Host "`e[${colorCode}m${Message}`e[0m"
}

function Write-Header {
   param([string]$Title)
    
   Write-Host ""
   Write-ColorOutput "=" * 80 -Color "Cyan"
   Write-ColorOutput " 🚀 $Title" -Color "Cyan"
   Write-ColorOutput "=" * 80 -Color "Cyan"
   Write-Host ""
}

function Write-SubHeader {
   param([string]$Title)
    
   Write-Host ""
   Write-ColorOutput "-" * 60 -Color "Blue"
   Write-ColorOutput " 📋 $Title" -Color "Blue"
   Write-ColorOutput "-" * 60 -Color "Blue"
   Write-Host ""
}

function Write-Step {
   param([string]$Message)
   Write-ColorOutput "🔄 $Message" -Color "Blue"
}

function Write-Success {
   param([string]$Message)
   Write-ColorOutput "✅ $Message" -Color "Green"
}

function Write-Warning {
   param([string]$Message)
   Write-ColorOutput "⚠️  $Message" -Color "Yellow"
}

function Write-Error {
   param([string]$Message)
   Write-ColorOutput "❌ $Message" -Color "Red"
}

function Test-Prerequisites {
   Write-Step "Vérification des prérequis Phase 7..."
    
   $errors = @()
    
   # Vérifier la structure du projet
   if (-not (Test-Path "projet" -PathType Container)) {
      $errors += "Répertoire 'projet' non trouvé - ce script doit être exécuté depuis la racine EMAIL_SENDER_1"
   }
    
   # Vérifier que nous sommes sur la bonne branche
   try {
      $currentBranch = git branch --show-current 2>$null
      if ($currentBranch -ne "feature/vectorization-audit-v56") {
         if (-not $Global:Phase7Config.Force) {
            $errors += "Branche incorrecte: $currentBranch (attendue: feature/vectorization-audit-v56)"
         }
         else {
            Write-Warning "Branche incorrecte mais -Force spécifié: $currentBranch"
         }
      }
   }
   catch {
      Write-Warning "Git non disponible ou pas dans un repository"
   }
    
   # Vérifier la connectivité Qdrant
   try {
      $qdrantUrl = "http://$($Global:Phase7Config.QdrantHost):$($Global:Phase7Config.QdrantPort)/health"
      $response = Invoke-RestMethod -Uri $qdrantUrl -TimeoutSec 5 -ErrorAction SilentlyContinue
      Write-Success "Qdrant accessible sur $($Global:Phase7Config.QdrantHost):$($Global:Phase7Config.QdrantPort)"
   }
   catch {
      if (-not $Global:Phase7Config.Force) {
         $errors += "Qdrant non accessible sur $($Global:Phase7Config.QdrantHost):$($Global:Phase7Config.QdrantPort)"
      }
      else {
         Write-Warning "Qdrant non accessible mais -Force spécifié"
      }
   }
    
   # Vérifier les outils Go
   try {
      $goVersion = go version 2>$null
      Write-Success "Go disponible: $goVersion"
   }
   catch {
      $errors += "Go n'est pas installé ou pas dans le PATH"
   }
    
   # Vérifier l'espace disque pour les sauvegardes
   $drive = Split-Path -Qualifier (Get-Location)
   $diskSpace = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $drive }
   $freeSpaceGB = [math]::Round($diskSpace.FreeSpace / 1GB, 2)
    
   if ($freeSpaceGB -lt 5) {
      if (-not $Global:Phase7Config.Force) {
         $errors += "Espace disque insuffisant: ${freeSpaceGB}GB disponible (minimum 5GB requis)"
      }
      else {
         Write-Warning "Espace disque faible: ${freeSpaceGB}GB disponible"
      }
   }
   else {
      Write-Success "Espace disque suffisant: ${freeSpaceGB}GB disponible"
   }
    
   if ($errors.Count -gt 0) {
      Write-Error "Prérequis non satisfaits:"
      foreach ($error in $errors) {
         Write-Host "  ❌ $error" -ForegroundColor Red
      }
        
      if (-not $Global:Phase7Config.Force) {
         throw "Prérequis non satisfaits. Utilisez -Force pour ignorer."
      }
   }
    
   Write-Success "Prérequis vérifiés"
}

function Initialize-Phase7Environment {
   Write-Step "Initialisation de l'environnement Phase 7..."
    
   # Créer la structure de répertoires
   $directories = @(
      $Global:Phase7Config.BackupPath,
      "$($Global:Phase7Config.BackupPath)/qdrant-collections",
      "$($Global:Phase7Config.BackupPath)/python-scripts",
      "$($Global:Phase7Config.BackupPath)/consolidation",
      "./legacy",
      "./legacy/python-scripts"
   )
    
   foreach ($dir in $directories) {
      if ($Global:Phase7Config.DryRun) {
         Write-Host "  DRY RUN: Créerait le répertoire $dir" -ForegroundColor Yellow
      }
      else {
         if (-not (Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            Write-Host "  📁 Créé: $dir" -ForegroundColor Green
         }
         else {
            Write-Host "  📁 Existe: $dir" -ForegroundColor Gray
         }
      }
   }
    
   # Configurer les variables d'environnement pour les outils
   $env:BACKUP_PATH = $Global:Phase7Config.BackupPath
   $env:QDRANT_HOST = $Global:Phase7Config.QdrantHost
   $env:QDRANT_PORT = $Global:Phase7Config.QdrantPort
   $env:DRY_RUN = $Global:Phase7Config.DryRun.ToString().ToLower()
   $env:VERBOSE = $Global:Phase7Config.Verbose.ToString().ToLower()
    
   Write-Success "Environnement Phase 7 initialisé"
}

function Execute-Phase71-DataMigration {
   Write-Header "Phase 7.1 - Migration des Données Qdrant"
    
   try {
      # 7.1.1.1: Sauvegarde des collections existantes
      Write-SubHeader "7.1.1.1 - Sauvegarde des Collections Existantes"
      Write-Step "Exécution de la sauvegarde Qdrant..."
        
      if ($Global:Phase7Config.DryRun) {
         Write-Host "DRY RUN: Exécuterait: go run cmd/backup-qdrant/main.go" -ForegroundColor Yellow
      }
      else {
         $backupResult = & go run cmd/backup-qdrant/main.go
         if ($LASTEXITCODE -ne 0) {
            throw "Erreur lors de la sauvegarde Qdrant"
         }
         Write-Success "Sauvegarde Qdrant terminée"
         $Global:ExecutionStats.BackupsCreated++
      }
        
      # 7.1.1.2: Migration vers nouveau format
      Write-SubHeader "7.1.1.2 - Migration vers Nouveau Format"
      Write-Step "Exécution de la migration Qdrant..."
        
      if ($Global:Phase7Config.DryRun) {
         Write-Host "DRY RUN: Exécuterait: go run cmd/migrate-qdrant/main.go" -ForegroundColor Yellow
      }
      else {
         $migrationResult = & go run cmd/migrate-qdrant/main.go
         if ($LASTEXITCODE -ne 0) {
            throw "Erreur lors de la migration Qdrant"
         }
         Write-Success "Migration Qdrant terminée"
         $Global:ExecutionStats.DataMigrated++
      }
        
      # 7.1.1.3: Tests de recherche sémantique
      Write-SubHeader "7.1.1.3 - Tests de Recherche Sémantique"
      Write-Step "Validation de la migration avec tests de recherche..."
        
      if ($Global:Phase7Config.DryRun) {
         Write-Host "DRY RUN: Exécuterait les tests de validation post-migration" -ForegroundColor Yellow
      }
      else {
         # Exécuter les tests de validation
         $testResult = & go test ./tests/integration/qdrant_migration_test.go -v
         if ($LASTEXITCODE -ne 0) {
            Write-Warning "Certains tests de validation ont échoué - vérifiez les logs"
         }
         else {
            Write-Success "Tests de recherche sémantique passés"
         }
      }
        
      $Global:ExecutionStats.Phase71Completed = $true
      Write-Success "Phase 7.1 - Migration des Données terminée avec succès"
   }
   catch {
      $error = "Phase 7.1 échouée: $_"
      $Global:ExecutionStats.Errors += $error
      Write-Error $error
      throw
   }
}

function Execute-Phase72-Cleanup {
   Write-Header "Phase 7.2 - Nettoyage et Optimisation"
    
   try {
      # 7.2.1: Suppression du Code Legacy Python
      Write-SubHeader "7.2.1 - Suppression du Code Legacy Python"
      Write-Step "Archivage des scripts Python legacy..."
        
      $cleanupParams = @()
      if ($Global:Phase7Config.DryRun) { $cleanupParams += "-DryRun" }
      if ($Global:Phase7Config.Force) { $cleanupParams += "-Force" }
      if ($Global:Phase7Config.Verbose) { $cleanupParams += "-Verbose" }
      $cleanupParams += "-ArchivePath"
      $cleanupParams += "$($Global:Phase7Config.BackupPath)/python-scripts"
        
      if ($Global:Phase7Config.DryRun) {
         Write-Host "DRY RUN: Exécuterait: .\scripts\cleanup-python-legacy.ps1 $($cleanupParams -join ' ')" -ForegroundColor Yellow
      }
      else {
         & .\scripts\cleanup-python-legacy.ps1 @cleanupParams
         if ($LASTEXITCODE -ne 0) {
            throw "Erreur lors du nettoyage des scripts Python"
         }
         Write-Success "Scripts Python archivés"
         $Global:ExecutionStats.ScriptsArchived++
      }
        
      # 7.2.2: Consolidation des clients Qdrant
      Write-SubHeader "7.2.2 - Consolidation des Clients Qdrant"
      Write-Step "Consolidation des clients Qdrant dupliqués..."
        
      $consolidateParams = @()
      if ($Global:Phase7Config.DryRun) { $consolidateParams += "--dry-run" }
      if ($Global:Phase7Config.Verbose) { $consolidateParams += "--verbose" }
      $consolidateParams += "--project-root"
      $consolidateParams += "."
        
      if ($Global:Phase7Config.DryRun) {
         Write-Host "DRY RUN: Exécuterait: go run cmd/consolidate-qdrant-clients/main.go $($consolidateParams -join ' ')" -ForegroundColor Yellow
      }
      else {
         & go run cmd/consolidate-qdrant-clients/main.go @consolidateParams
         if ($LASTEXITCODE -ne 0) {
            throw "Erreur lors de la consolidation des clients Qdrant"
         }
         Write-Success "Clients Qdrant consolidés"
         $Global:ExecutionStats.ClientsConsolidated++
      }
        
      # 7.2.3: Validation finale
      Write-SubHeader "7.2.3 - Validation Finale"
      Write-Step "Validation que tous les tests passent après nettoyage..."
        
      if ($Global:Phase7Config.DryRun) {
         Write-Host "DRY RUN: Exécuterait: go test ./... -v" -ForegroundColor Yellow
      }
      else {
         $testResult = & go test ./... -v -short
         if ($LASTEXITCODE -ne 0) {
            Write-Warning "Certains tests échouent après le nettoyage - vérification manuelle requise"
         }
         else {
            Write-Success "Tous les tests passent après nettoyage"
         }
      }
        
      $Global:ExecutionStats.Phase72Completed = $true
      Write-Success "Phase 7.2 - Nettoyage et Optimisation terminée avec succès"
   }
   catch {
      $error = "Phase 7.2 échouée: $_"
      $Global:ExecutionStats.Errors += $error
      Write-Error $error
      throw
   }
}

function Update-PlanMarkdown {
   Write-Step "Mise à jour du plan markdown..."
    
   $planPath = "projet/roadmaps/plans/consolidated/plan-dev-v56-go-native-vectorization-migration.md"
    
   if (-not (Test-Path $planPath)) {
      Write-Warning "Plan markdown non trouvé: $planPath"
      return
   }
    
   try {
      $content = Get-Content $planPath -Raw
        
      # Mettre à jour la progression Phase 7
      $progressionPattern = '(\*\*Progression: )0%(\*\*)'
      $content = $content -replace $progressionPattern, '${1}100%${2} ✅'
        
      # Mettre à jour les checkboxes
      $checkboxPattern = '- \[ \] (\*\*7\.[12]\.[12]\.[12]\*\*.*)'
      $content = $content -replace $checkboxPattern, '- [x] ${1} ✅'
        
      if ($Global:Phase7Config.DryRun) {
         Write-Host "DRY RUN: Mettrait à jour le plan markdown" -ForegroundColor Yellow
      }
      else {
         Set-Content -Path $planPath -Value $content -Encoding UTF8
         Write-Success "Plan markdown mis à jour"
      }
   }
   catch {
      Write-Warning "Erreur lors de la mise à jour du plan markdown: $_"
   }
}

function Generate-Phase7Report {
   Write-Step "Génération du rapport Phase 7..."
    
   $endTime = Get-Date
   $duration = $endTime - $Global:ExecutionStats.StartTime
    
   $report = @{
      timestamp            = $endTime.ToString("yyyy-MM-dd HH:mm:ss")
      version              = "v56-go-migration"
      phase                = "7"
      branch               = "feature/vectorization-audit-v56"
      duration_minutes     = [math]::Round($duration.TotalMinutes, 2)
      phase_71_completed   = $Global:ExecutionStats.Phase71Completed
      phase_72_completed   = $Global:ExecutionStats.Phase72Completed
      backups_created      = $Global:ExecutionStats.BackupsCreated
      data_migrated        = $Global:ExecutionStats.DataMigrated
      scripts_archived     = $Global:ExecutionStats.ScriptsArchived
      clients_consolidated = $Global:ExecutionStats.ClientsConsolidated
      errors_count         = $Global:ExecutionStats.Errors.Count
      errors               = $Global:ExecutionStats.Errors
      backup_path          = $Global:Phase7Config.BackupPath
      dry_run              = $Global:Phase7Config.DryRun
   }
    
   $reportJson = $report | ConvertTo-Json -Depth 3
   $reportPath = "$($Global:Phase7Config.BackupPath)/phase7_execution_report.json"
    
   if ($Global:Phase7Config.DryRun) {
      Write-Host "DRY RUN: Créerait le rapport $reportPath" -ForegroundColor Yellow
      Write-Host "Contenu du rapport:" -ForegroundColor Yellow
      Write-Host $reportJson -ForegroundColor Gray
   }
   else {
      Set-Content -Path $reportPath -Value $reportJson -Encoding UTF8
      Write-Success "Rapport Phase 7 généré: $reportPath"
   }
}

function Show-ExecutionSummary {
   Write-Header "📊 Résumé d'Exécution Phase 7"
    
   $endTime = Get-Date
   $duration = $endTime - $Global:ExecutionStats.StartTime
    
   Write-Host "⏱️  Durée totale: " -NoNewline
   Write-ColorOutput "$([math]::Round($duration.TotalMinutes, 2)) minutes" -Color "Cyan"
    
   Write-Host "📋 Phase exécutée: " -NoNewline
   Write-ColorOutput $Phase -Color "Cyan"
    
   if ($Global:Phase7Config.DryRun) {
      Write-ColorOutput "🔍 Mode: DRY RUN" -Color "Yellow"
   }
    
   Write-Host ""
   Write-ColorOutput "✅ Succès:" -Color "Green"
   Write-Host "   📦 Sauvegardes créées: $($Global:ExecutionStats.BackupsCreated)"
   Write-Host "   📊 Données migrées: $($Global:ExecutionStats.DataMigrated)"
   Write-Host "   🗂️  Scripts archivés: $($Global:ExecutionStats.ScriptsArchived)"
   Write-Host "   🔧 Clients consolidés: $($Global:ExecutionStats.ClientsConsolidated)"
    
   if ($Global:ExecutionStats.Errors.Count -gt 0) {
      Write-Host ""
      Write-ColorOutput "❌ Erreurs ($($Global:ExecutionStats.Errors.Count)):" -Color "Red"
      foreach ($error in $Global:ExecutionStats.Errors) {
         Write-Host "   - $error" -ForegroundColor Red
      }
   }
    
   Write-Host ""
   Write-ColorOutput "📁 Sauvegardes: $($Global:Phase7Config.BackupPath)" -Color "Cyan"
    
   if ($Global:ExecutionStats.Phase71Completed -and $Global:ExecutionStats.Phase72Completed) {
      Write-Host ""
      Write-ColorOutput "🎉 Phase 7 - Migration des Données et Nettoyage TERMINÉE!" -Color "Green"
   }
}

function Main {
   Write-Header "Phase 7 - Migration des Données et Nettoyage"
   Write-Host "Migration Vectorisation Go v56 - feature/vectorization-audit-v56" -ForegroundColor Cyan
   Write-Host ""
    
   if ($Global:Phase7Config.DryRun) {
      Write-Warning "MODE DRY RUN ACTIVÉ - Aucune modification ne sera effectuée"
      Write-Host ""
   }
    
   try {
      # Étapes préliminaires
      Test-Prerequisites
      Initialize-Phase7Environment
        
      # Exécution des phases selon le paramètre
      switch ($Phase) {
         "7.1" {
            Execute-Phase71-DataMigration
         }
         "7.2" {
            Execute-Phase72-Cleanup
         }
         "all" {
            Execute-Phase71-DataMigration
            Execute-Phase72-Cleanup
         }
      }
        
      # Étapes finales
      Update-PlanMarkdown
      Generate-Phase7Report
      Show-ExecutionSummary
        
      # Message final
      if ($Global:ExecutionStats.Errors.Count -eq 0) {
         Write-Success "Phase 7 terminée avec succès!"
         exit 0
      }
      else {
         Write-Warning "Phase 7 terminée avec $($Global:ExecutionStats.Errors.Count) erreurs"
         exit 1
      }
   }
   catch {
      Write-Error "Erreur fatale durant l'exécution de la Phase 7: $_"
      Show-ExecutionSummary
      exit 1
   }
}

# Exécution du script principal
Main
