# Rollback and Recovery System - Plan Dev v41
# Phase 1.1.1.3 - Système de retour en arrière et récupération
# Version: 1.0
# Date: 2025-06-03

[CmdletBinding()]
param(
   [Parameter(HelpMessage = "Mode d'opération du système de rollback")]
   [ValidateSet("CreateBackup", "ListBackups", "Rollback", "Verify", "Clean")]
   [string]$Mode = "CreateBackup",
    
   [Parameter(HelpMessage = "Identifiant de la session à restaurer")]
   [string]$SessionId = "",
    
   [Parameter(HelpMessage = "Chemin vers le répertoire de sauvegarde")]
   [string]$BackupPath = ".\projet\security\backups",
    
   [Parameter(HelpMessage = "Nombre maximum de sauvegardes à conserver")]
   [int]$MaxBackups = 10,
    
   [Parameter(HelpMessage = "Mode verbose pour plus de détails")]
   [switch]$Verbose,
    
   [Parameter(HelpMessage = "Forcer les opérations sans confirmation")]
   [switch]$Force
)

# ===== CONFIGURATION GLOBALE =====

$Global:RollbackConfig = @{
   ProjectRoot     = Get-Location
   BackupPath      = $BackupPath
   MaxBackups      = $MaxBackups
   CriticalFiles   = @(
      "go.mod",
      "go.sum", 
      "package.json",
      ".gitmodules",
      "Dockerfile",
      "docker-compose.yml",
      "Makefile",
      "LICENSE",
      "README.md"
   )
   ConfigFiles     = @(
      "projet\security\protection-config.json",
      "tools\security\*.ps1",
      "organize-root-files-secure.ps1"
   )
   ExcludePatterns = @(
      "*.exe",
      "*.log",
      ".git\*",
      "node_modules\*",
      "*.tmp",
      "*.cache"
   )
}

# ===== FONCTIONS UTILITAIRES =====

function Write-RollbackLog {
   param(
      [string]$Message,
      [ValidateSet("Info", "Warning", "Error", "Success")]
      [string]$Level = "Info",
      [string]$SessionId = ""
   )
    
   $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
   $logEntry = "[$timestamp] [$Level] $Message"
    
   if ($SessionId) {
      $logEntry += " [Session: $SessionId]"
   }
    
   switch ($Level) {
      "Info" { Write-Host $logEntry -ForegroundColor White }
      "Warning" { Write-Host $logEntry -ForegroundColor Yellow }
      "Error" { Write-Host $logEntry -ForegroundColor Red }
      "Success" { Write-Host $logEntry -ForegroundColor Green }
   }
    
   # Également écrire dans le fichier de log
   $logPath = Join-Path $RollbackConfig.BackupPath "rollback.log"
   Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
}

function Initialize-RollbackSystem {
   Write-RollbackLog "Initialisation du système de rollback" -Level "Info"
    
   # Créer le répertoire de sauvegarde si nécessaire
   if (-not (Test-Path $RollbackConfig.BackupPath)) {
      New-Item -ItemType Directory -Path $RollbackConfig.BackupPath -Force | Out-Null
      Write-RollbackLog "Répertoire de sauvegarde créé: $($RollbackConfig.BackupPath)" -Level "Success"
   }
    
   # Créer les sous-répertoires
   $subDirs = @("sessions", "critical", "config", "logs")
   foreach ($dir in $subDirs) {
      $fullPath = Join-Path $RollbackConfig.BackupPath $dir
      if (-not (Test-Path $fullPath)) {
         New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
      }
   }
    
   Write-RollbackLog "Système de rollback initialisé" -Level "Success"
}

# ===== FONCTIONS DE SAUVEGARDE =====

function New-BackupSession {
   param(
      [string]$Description = "Sauvegarde automatique"
   )
    
   $sessionId = [Guid]::NewGuid().ToString()
   $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
   $sessionPath = Join-Path $RollbackConfig.BackupPath "sessions\$timestamp-$sessionId"
    
   Write-RollbackLog "Création d'une nouvelle session de sauvegarde" -Level "Info" -SessionId $sessionId
    
   try {
      # Créer le répertoire de session
      New-Item -ItemType Directory -Path $sessionPath -Force | Out-Null
        
      # Métadonnées de la session
      $metadata = @{
         SessionId   = $sessionId
         Timestamp   = Get-Date
         Description = $Description
         ProjectRoot = $RollbackConfig.ProjectRoot.Path
         BackupPath  = $sessionPath
         Files       = @()
         Status      = "InProgress"
      }
        
      # Sauvegarder les fichiers critiques
      $criticalBackupPath = Join-Path $sessionPath "critical"
      New-Item -ItemType Directory -Path $criticalBackupPath -Force | Out-Null
        
      foreach ($file in $RollbackConfig.CriticalFiles) {
         $sourcePath = Join-Path $RollbackConfig.ProjectRoot $file
         if (Test-Path $sourcePath) {
            $destinationPath = Join-Path $criticalBackupPath $file
            $destinationDir = Split-Path $destinationPath -Parent
            if (-not (Test-Path $destinationDir)) {
               New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
            }
                
            Copy-Item -Path $sourcePath -Destination $destinationPath -Force
            $metadata.Files += @{
               SourcePath = $sourcePath
               BackupPath = $destinationPath
               Type       = "Critical"
               Size       = (Get-Item $sourcePath).Length
               Hash       = (Get-FileHash $sourcePath -Algorithm SHA256).Hash
            }
                
            Write-RollbackLog "Fichier critique sauvegardé: $file" -Level "Info" -SessionId $sessionId
         }
      }
        
      # Sauvegarder les fichiers de configuration
      $configBackupPath = Join-Path $sessionPath "config"
      New-Item -ItemType Directory -Path $configBackupPath -Force | Out-Null
        
      foreach ($pattern in $RollbackConfig.ConfigFiles) {
         $files = Get-ChildItem -Path $RollbackConfig.ProjectRoot -Filter $pattern -Recurse -ErrorAction SilentlyContinue
         foreach ($file in $files) {
            $relativePath = $file.FullName.Substring($RollbackConfig.ProjectRoot.Path.Length + 1)
            $destinationPath = Join-Path $configBackupPath $relativePath
            $destinationDir = Split-Path $destinationPath -Parent
            if (-not (Test-Path $destinationDir)) {
               New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
            }
                
            Copy-Item -Path $file.FullName -Destination $destinationPath -Force
            $metadata.Files += @{
               SourcePath = $file.FullName
               BackupPath = $destinationPath
               Type       = "Config"
               Size       = $file.Length
               Hash       = (Get-FileHash $file.FullName -Algorithm SHA256).Hash
            }
                
            Write-RollbackLog "Fichier de configuration sauvegardé: $relativePath" -Level "Info" -SessionId $sessionId
         }
      }
        
      # Finaliser les métadonnées
      $metadata.Status = "Completed"
      $metadata.EndTime = Get-Date
      $metadata.TotalFiles = $metadata.Files.Count
      $metadata.TotalSize = ($metadata.Files | Measure-Object -Property Size -Sum).Sum
        
      # Sauvegarder les métadonnées
      $metadataPath = Join-Path $sessionPath "metadata.json"
      $metadata | ConvertTo-Json -Depth 10 | Out-File -FilePath $metadataPath -Encoding utf8
        
      Write-RollbackLog "Session de sauvegarde créée avec succès" -Level "Success" -SessionId $sessionId
      Write-RollbackLog "Fichiers sauvegardés: $($metadata.TotalFiles)" -Level "Info" -SessionId $sessionId
      Write-RollbackLog "Taille totale: $([math]::Round($metadata.TotalSize / 1MB, 2)) MB" -Level "Info" -SessionId $sessionId
        
      return $sessionId
   }
   catch {
      Write-RollbackLog "Erreur lors de la création de la session: $_" -Level "Error" -SessionId $sessionId
      throw
   }
}

function Get-BackupSessions {
   Write-RollbackLog "Récupération de la liste des sessions de sauvegarde" -Level "Info"
    
   $sessionsPath = Join-Path $RollbackConfig.BackupPath "sessions"
   if (-not (Test-Path $sessionsPath)) {
      Write-RollbackLog "Aucune session de sauvegarde trouvée" -Level "Warning"
      return @()
   }
    
   $sessions = @()
   $sessionDirs = Get-ChildItem -Path $sessionsPath -Directory | Sort-Object Name -Descending
    
   foreach ($dir in $sessionDirs) {
      $metadataPath = Join-Path $dir.FullName "metadata.json"
      if (Test-Path $metadataPath) {
         try {
            $metadata = Get-Content $metadataPath | ConvertFrom-Json
            $sessions += $metadata
         }
         catch {
            Write-RollbackLog "Erreur lors de la lecture des métadonnées pour: $($dir.Name)" -Level "Warning"
         }
      }
   }
    
   Write-RollbackLog "Sessions trouvées: $($sessions.Count)" -Level "Info"
   return $sessions
}

function Show-BackupSessions {
   $sessions = Get-BackupSessions
    
   if ($sessions.Count -eq 0) {
      Write-Host "`nAucune session de sauvegarde disponible." -ForegroundColor Yellow
      return
   }
    
   Write-Host "`n" + "="*80 -ForegroundColor Cyan
   Write-Host " 📋 SESSIONS DE SAUVEGARDE DISPONIBLES" -ForegroundColor Cyan
   Write-Host "="*80 -ForegroundColor Cyan
    
   $counter = 1
   foreach ($session in $sessions) {
      $timestamp = ([DateTime]$session.Timestamp).ToString("yyyy-MM-dd HH:mm:ss")
      $size = [math]::Round($session.TotalSize / 1MB, 2)
        
      Write-Host "`n$counter. Session: $($session.SessionId)" -ForegroundColor White
      Write-Host "   📅 Date: $timestamp" -ForegroundColor Gray
      Write-Host "   📝 Description: $($session.Description)" -ForegroundColor Gray
      Write-Host "   📁 Fichiers: $($session.TotalFiles)" -ForegroundColor Gray
      Write-Host "   💾 Taille: $size MB" -ForegroundColor Gray
      Write-Host "   ✅ Statut: $($session.Status)" -ForegroundColor $(if ($session.Status -eq "Completed") { "Green" } else { "Yellow" })
        
      $counter++
   }
    
   Write-Host "`n" + "="*80 -ForegroundColor Cyan
}

# ===== FONCTIONS DE RESTAURATION =====

function Restore-BackupSession {
   param(
      [string]$SessionId,
      [switch]$DryRun = $false
   )
    
   Write-RollbackLog "Début de la restauration de session" -Level "Info" -SessionId $SessionId
    
   # Trouver la session
   $sessions = Get-BackupSessions
   $session = $sessions | Where-Object { $_.SessionId -eq $SessionId }
    
   if (-not $session) {
      Write-RollbackLog "Session non trouvée: $SessionId" -Level "Error"
      throw "Session de sauvegarde non trouvée"
   }
    
   if ($DryRun) {
      Write-Host "`n🎭 MODE SIMULATION - Aucun fichier ne sera modifié" -ForegroundColor Yellow
   }
    
   Write-Host "`n📦 Restauration de la session: $SessionId" -ForegroundColor Cyan
   Write-Host "📅 Date de sauvegarde: $($session.Timestamp)" -ForegroundColor Gray
   Write-Host "📝 Description: $($session.Description)" -ForegroundColor Gray
    
   $restoredFiles = 0
   $failedFiles = 0
    
   foreach ($fileInfo in $session.Files) {
      try {
         $sourcePath = $fileInfo.BackupPath
         $destinationPath = $fileInfo.SourcePath
            
         if (-not (Test-Path $sourcePath)) {
            Write-RollbackLog "Fichier de sauvegarde manquant: $sourcePath" -Level "Warning" -SessionId $SessionId
            $failedFiles++
            continue
         }
            
         if ($DryRun) {
            Write-Host "   🔄 Simulation: $destinationPath" -ForegroundColor Yellow
         }
         else {
            # Créer le répertoire de destination si nécessaire
            $destinationDir = Split-Path $destinationPath -Parent
            if (-not (Test-Path $destinationDir)) {
               New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
            }
                
            # Restaurer le fichier
            Copy-Item -Path $sourcePath -Destination $destinationPath -Force
                
            # Vérifier l'intégrité
            $newHash = (Get-FileHash $destinationPath -Algorithm SHA256).Hash
            if ($newHash -eq $fileInfo.Hash) {
               Write-RollbackLog "Fichier restauré avec succès: $destinationPath" -Level "Success" -SessionId $SessionId
               $restoredFiles++
            }
            else {
               Write-RollbackLog "Erreur d'intégrité pour: $destinationPath" -Level "Error" -SessionId $SessionId
               $failedFiles++
            }
         }
      }
      catch {
         Write-RollbackLog "Erreur lors de la restauration de $($fileInfo.SourcePath): $_" -Level "Error" -SessionId $SessionId
         $failedFiles++
      }
   }
    
   if (-not $DryRun) {
      Write-Host "`n✅ Restauration terminée:" -ForegroundColor Green
      Write-Host "   📁 Fichiers restaurés: $restoredFiles" -ForegroundColor Green
      Write-Host "   ❌ Échecs: $failedFiles" -ForegroundColor $(if ($failedFiles -eq 0) { "Green" } else { "Red" })
   }
   else {
      Write-Host "`n🎭 Simulation terminée - $($session.Files.Count) fichiers seraient restaurés" -ForegroundColor Yellow
   }
}

function Remove-OldBackups {
   Write-RollbackLog "Nettoyage des anciennes sauvegardes" -Level "Info"
    
   $sessions = Get-BackupSessions
   if ($sessions.Count -le $RollbackConfig.MaxBackups) {
      Write-RollbackLog "Aucun nettoyage nécessaire ($($sessions.Count)/$($RollbackConfig.MaxBackups))" -Level "Info"
      return
   }
    
   $sessionsToRemove = $sessions | Sort-Object Timestamp | Select-Object -First ($sessions.Count - $RollbackConfig.MaxBackups)
    
   foreach ($session in $sessionsToRemove) {
      try {
         $sessionPath = $session.BackupPath
         if (Test-Path $sessionPath) {
            Remove-Item -Path $sessionPath -Recurse -Force
            Write-RollbackLog "Session supprimée: $($session.SessionId)" -Level "Info"
         }
      }
      catch {
         Write-RollbackLog "Erreur lors de la suppression de la session $($session.SessionId): $_" -Level "Warning"
      }
   }
    
   Write-RollbackLog "Nettoyage terminé" -Level "Success"
}

# ===== FONCTION PRINCIPALE =====

function Start-RollbackSystem {
   try {
      Initialize-RollbackSystem
        
      switch ($Mode) {
         "CreateBackup" {
            $sessionId = New-BackupSession -Description "Sauvegarde manuelle"
            Write-Host "`n✅ Sauvegarde créée avec succès!" -ForegroundColor Green
            Write-Host "🔑 ID de session: $sessionId" -ForegroundColor Cyan
                
            # Nettoyer les anciennes sauvegardes
            Remove-OldBackups
         }
            
         "ListBackups" {
            Show-BackupSessions
         }
            
         "Rollback" {
            if (-not $SessionId) {
               Write-Host "❌ Veuillez spécifier un ID de session avec -SessionId" -ForegroundColor Red
               Show-BackupSessions
               return 1
            }
                
            # Confirmation avant restauration
            if (-not $Force) {
               Write-Host "`n⚠️  ATTENTION: Cette opération va restaurer les fichiers de la session $SessionId" -ForegroundColor Yellow
               Write-Host "Cela écrasera les fichiers actuels. Êtes-vous sûr? (o/N): " -NoNewline -ForegroundColor Yellow
               $confirmation = Read-Host
               if ($confirmation -notmatch '^[oO]$') {
                  Write-Host "❌ Opération annulée" -ForegroundColor Red
                  return 0
               }
            }
                
            Restore-BackupSession -SessionId $SessionId
         }
            
         "Verify" {
            if (-not $SessionId) {
               Write-Host "❌ Veuillez spécifier un ID de session avec -SessionId" -ForegroundColor Red
               return 1
            }
                
            Write-Host "`n🔍 Vérification de la session $SessionId..." -ForegroundColor Cyan
            Restore-BackupSession -SessionId $SessionId -DryRun
         }
            
         "Clean" {
            if (-not $Force) {
               Write-Host "`n⚠️  ATTENTION: Cette opération va supprimer les anciennes sauvegardes" -ForegroundColor Yellow
               Write-Host "Êtes-vous sûr? (o/N): " -NoNewline -ForegroundColor Yellow
               $confirmation = Read-Host
               if ($confirmation -notmatch '^[oO]$') {
                  Write-Host "❌ Opération annulée" -ForegroundColor Red
                  return 0
               }
            }
                
            Remove-OldBackups
         }
      }
        
      return 0
   }
   catch {
      Write-RollbackLog "Erreur critique: $_" -Level "Error"
      return 1
   }
}

# ===== POINT D'ENTRÉE =====

# Configuration globale
$ErrorActionPreference = "Continue"
$InformationPreference = "Continue"

# Exécution du système de rollback
exit (Start-RollbackSystem)
