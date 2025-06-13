# ========================================
# Script de Backup et Restore des Plans
# Phase 6.1.2 - Scripts PowerShell d'Administration
# ========================================

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("backup", "restore", "list", "cleanup")]
    [string]$Action,
    
    [string]$BackupPath = "./backups/plans/$(Get-Date -Format 'yyyyMMdd_HHmmss')",
    [string]$SourcePath = "./projet/roadmaps/plans/",
    [string]$RestoreFrom = "",
    [switch]$Force,
    [switch]$Verbose,
    [int]$RetentionDays = 30,
    [switch]$DryRun
)

# Configuration des couleurs
$ErrorColor = "Red"
$WarningColor = "Yellow"
$SuccessColor = "Green"
$InfoColor = "Cyan"

function Write-LogMessage {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Color = "White"
    )
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    $prefix = switch ($Level) {
        "ERROR" { "❌" }
        "WARNING" { "⚠️" }
        "SUCCESS" { "✅" }
        "INFO" { "ℹ️" }
        default { "📝" }
    }
    
    Write-Host "[$timestamp] $prefix $Message" -ForegroundColor $Color
}

function Initialize-BackupEnvironment {
    Write-LogMessage "Initialisation de l'environnement de backup..." "INFO" $InfoColor
    
    # Créer le répertoire de backup racine s'il n'existe pas
    $backupRoot = "./backups"
    if (-not (Test-Path $backupRoot)) {
        if ($DryRun) {
            Write-LogMessage "[DRY-RUN] Créerait le répertoire: $backupRoot" "INFO" $InfoColor
        } else {
            New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
            Write-LogMessage "Répertoire de backup créé: $backupRoot" "SUCCESS" $SuccessColor
        }
    }
    
    # Créer le sous-répertoire pour les plans
    $plansBackupDir = "$backupRoot/plans"
    if (-not (Test-Path $plansBackupDir)) {
        if ($DryRun) {
            Write-LogMessage "[DRY-RUN] Créerait le répertoire: $plansBackupDir" "INFO" $InfoColor
        } else {
            New-Item -ItemType Directory -Path $plansBackupDir -Force | Out-Null
            Write-LogMessage "Répertoire plans créé: $plansBackupDir" "SUCCESS" $SuccessColor
        }
    }
    
    return $true
}

function Get-PlansToBackup {
    param([string]$SourcePath)
    
    Write-LogMessage "Recherche des plans à sauvegarder dans: $SourcePath" "INFO" $InfoColor
    
    if (-not (Test-Path $SourcePath)) {
        Write-LogMessage "Chemin source non trouvé: $SourcePath" "ERROR" $ErrorColor
        return @()
    }
    
    # Rechercher tous les fichiers markdown de plans
    $planFiles = Get-ChildItem -Path $SourcePath -Filter "*.md" -Recurse | 
                 Where-Object { 
                     $_.Name -match "plan-dev-v\d+" -or 
                     $_.Name -match "roadmap" -or
                     $_.Directory.Name -match "plans" 
                 }
    
    Write-LogMessage "Trouvé $($planFiles.Count) fichier(s) de plans" "INFO" $InfoColor
    
    if ($Verbose) {
        foreach ($file in $planFiles) {
            $relativePath = $file.FullName.Replace((Get-Location).Path, ".")
            $size = [math]::Round($file.Length / 1KB, 2)
            Write-LogMessage "  📄 $relativePath ($size KB)" "INFO" "Gray"
        }
    }
    
    return $planFiles
}

function New-BackupArchive {
    param(
        [array]$Files,
        [string]$BackupPath,
        [string]$SourcePath
    )
    
    Write-LogMessage "Création du backup dans: $BackupPath" "INFO" $InfoColor
    
    if ($DryRun) {
        Write-LogMessage "[DRY-RUN] Simulerait la création du backup" "INFO" $InfoColor
        foreach ($file in $Files) {
            $relativePath = $file.FullName.Replace((Resolve-Path $SourcePath).Path, "")
            Write-LogMessage "[DRY-RUN] Copierait: $relativePath" "INFO" "Gray"
        }
        return @{
            Success = $true
            BackupPath = $BackupPath
            FilesCount = $Files.Count
            TotalSize = ($Files | Measure-Object -Property Length -Sum).Sum
        }
    }
    
    # Créer le répertoire de backup
    New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
    
    $backupManifest = @{
        BackupDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        SourcePath = $SourcePath
        BackupPath = $BackupPath
        FilesCount = $Files.Count
        Files = @()
        TotalSize = 0
    }
    
    $copiedFiles = 0
    $totalSize = 0
    
    foreach ($file in $Files) {
        try {
            # Calculer le chemin relatif pour préserver la structure
            $relativePath = $file.FullName.Replace((Resolve-Path $SourcePath).Path, "")
            $destinationPath = Join-Path $BackupPath $relativePath
            
            # Créer le répertoire de destination si nécessaire
            $destinationDir = Split-Path $destinationPath -Parent
            if (-not (Test-Path $destinationDir)) {
                New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
            }
            
            # Copier le fichier
            Copy-Item -Path $file.FullName -Destination $destinationPath -Force
            
            # Ajouter au manifeste
            $fileInfo = @{
                OriginalPath = $file.FullName
                RelativePath = $relativePath
                BackupPath = $destinationPath
                Size = $file.Length
                LastModified = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
                MD5Hash = (Get-FileHash -Path $file.FullName -Algorithm MD5).Hash
            }
            
            $backupManifest.Files += $fileInfo
            $copiedFiles++
            $totalSize += $file.Length
            
            if ($Verbose) {
                $sizeKB = [math]::Round($file.Length / 1KB, 2)
                Write-LogMessage "  ✅ $relativePath ($sizeKB KB)" "SUCCESS" "Gray"
            }
        }
        catch {
            Write-LogMessage "Erreur lors de la copie de $($file.FullName): $($_.Exception.Message)" "ERROR" $ErrorColor
        }
    }
    
    $backupManifest.TotalSize = $totalSize
    
    # Sauvegarder le manifeste
    $manifestPath = Join-Path $BackupPath "backup-manifest.json"
    $backupManifest | ConvertTo-Json -Depth 10 | Set-Content -Path $manifestPath -Encoding UTF8
    
    # Créer un fichier de métadonnées lisible
    $readmePath = Join-Path $BackupPath "README.txt"
    $readmeContent = @"
BACKUP DES PLANS DE DÉVELOPPEMENT
=================================

Date de création: $($backupManifest.BackupDate)
Chemin source: $($backupManifest.SourcePath)
Nombre de fichiers: $($backupManifest.FilesCount)
Taille totale: $([math]::Round($totalSize / 1MB, 2)) MB

Pour restaurer ce backup:
./scripts/backup-restore.ps1 -Action restore -RestoreFrom "$BackupPath"

Fichiers inclus:
$($backupManifest.Files | ForEach-Object { "  - $($_.RelativePath) ($([math]::Round($_.Size / 1KB, 2)) KB)" } | Out-String)
"@
    
    Set-Content -Path $readmePath -Value $readmeContent -Encoding UTF8
    
    Write-LogMessage "Backup créé avec succès: $copiedFiles fichiers, $([math]::Round($totalSize / 1MB, 2)) MB" "SUCCESS" $SuccessColor
    
    return @{
        Success = $true
        BackupPath = $BackupPath
        FilesCount = $copiedFiles
        TotalSize = $totalSize
        ManifestPath = $manifestPath
    }
}

function Restore-FromBackup {
    param(
        [string]$BackupPath,
        [string]$DestinationPath
    )
    
    Write-LogMessage "Restauration depuis: $BackupPath" "INFO" $InfoColor
    Write-LogMessage "Vers: $DestinationPath" "INFO" $InfoColor
    
    # Vérifier l'existence du backup
    if (-not (Test-Path $BackupPath)) {
        Write-LogMessage "Backup non trouvé: $BackupPath" "ERROR" $ErrorColor
        return $false
    }
    
    # Charger le manifeste
    $manifestPath = Join-Path $BackupPath "backup-manifest.json"
    if (-not (Test-Path $manifestPath)) {
        Write-LogMessage "Manifeste de backup non trouvé: $manifestPath" "ERROR" $ErrorColor
        return $false
    }
    
    $manifest = Get-Content $manifestPath | ConvertFrom-Json
    Write-LogMessage "Backup du $($manifest.BackupDate), $($manifest.FilesCount) fichiers" "INFO" $InfoColor
    
    if ($DryRun) {
        Write-LogMessage "[DRY-RUN] Simulerait la restauration de $($manifest.FilesCount) fichiers" "INFO" $InfoColor
        foreach ($file in $manifest.Files) {
            Write-LogMessage "[DRY-RUN] Restaurerait: $($file.RelativePath)" "INFO" "Gray"
        }
        return $true
    }
    
    # Demander confirmation si pas de mode force
    if (-not $Force) {
        $existingFiles = @()
        foreach ($file in $manifest.Files) {
            $targetPath = Join-Path $DestinationPath $file.RelativePath
            if (Test-Path $targetPath) {
                $existingFiles += $targetPath
            }
        }
        
        if ($existingFiles.Count -gt 0) {
            Write-LogMessage "$($existingFiles.Count) fichier(s) existant(s) seront écrasés" "WARNING" $WarningColor
            $response = Read-Host "Continuer? (o/N)"
            if ($response -ne "o" -and $response -ne "O") {
                Write-LogMessage "Restauration annulée par l'utilisateur" "WARNING" $WarningColor
                return $false
            }
        }
    }
    
    # Restaurer les fichiers
    $restoredFiles = 0
    $errors = 0
    
    foreach ($file in $manifest.Files) {
        try {
            $sourcePath = $file.BackupPath
            $targetPath = Join-Path $DestinationPath $file.RelativePath
            
            # Créer le répertoire de destination si nécessaire
            $targetDir = Split-Path $targetPath -Parent
            if (-not (Test-Path $targetDir)) {
                New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
            }
            
            # Copier le fichier
            Copy-Item -Path $sourcePath -Destination $targetPath -Force
            
            # Vérifier l'intégrité (optionnel)
            if (Test-Path $targetPath) {
                $newHash = (Get-FileHash -Path $targetPath -Algorithm MD5).Hash
                if ($newHash -eq $file.MD5Hash) {
                    $restoredFiles++
                    if ($Verbose) {
                        Write-LogMessage "  ✅ $($file.RelativePath)" "SUCCESS" "Gray"
                    }
                } else {
                    Write-LogMessage "Erreur d'intégrité pour: $($file.RelativePath)" "ERROR" $ErrorColor
                    $errors++
                }
            } else {
                Write-LogMessage "Échec de la restauration: $($file.RelativePath)" "ERROR" $ErrorColor
                $errors++
            }
        }
        catch {
            Write-LogMessage "Erreur lors de la restauration de $($file.RelativePath): $($_.Exception.Message)" "ERROR" $ErrorColor
            $errors++
        }
    }
    
    if ($errors -eq 0) {
        Write-LogMessage "Restauration réussie: $restoredFiles fichiers restaurés" "SUCCESS" $SuccessColor
    } else {
        Write-LogMessage "Restauration avec erreurs: $restoredFiles succès, $errors erreurs" "WARNING" $WarningColor
    }
    
    return $errors -eq 0
}

function Get-BackupList {
    param([string]$BackupRoot = "./backups/plans")
    
    Write-LogMessage "Liste des backups disponibles:" "INFO" $InfoColor
    
    if (-not (Test-Path $BackupRoot)) {
        Write-LogMessage "Répertoire de backup non trouvé: $BackupRoot" "WARNING" $WarningColor
        return @()
    }
    
    $backupDirs = Get-ChildItem -Path $BackupRoot -Directory | Sort-Object Name -Descending
    $backups = @()
    
    foreach ($dir in $backupDirs) {
        $manifestPath = Join-Path $dir.FullName "backup-manifest.json"
        if (Test-Path $manifestPath) {
            try {
                $manifest = Get-Content $manifestPath | ConvertFrom-Json
                $backup = @{
                    Name = $dir.Name
                    Path = $dir.FullName
                    Date = $manifest.BackupDate
                    FilesCount = $manifest.FilesCount
                    Size = $manifest.TotalSize
                    SourcePath = $manifest.SourcePath
                }
                $backups += $backup
                
                $sizeDisplay = if ($backup.Size -gt 1MB) {
                    "$([math]::Round($backup.Size / 1MB, 2)) MB"
                } else {
                    "$([math]::Round($backup.Size / 1KB, 2)) KB"
                }
                
                Write-LogMessage "  📦 $($backup.Name) - $($backup.Date) - $($backup.FilesCount) fichiers - $sizeDisplay" "INFO" "Gray"
            }
            catch {
                Write-LogMessage "  ❌ $($dir.Name) - Manifeste corrompu" "ERROR" $ErrorColor
            }
        } else {
            Write-LogMessage "  ⚠️ $($dir.Name) - Pas de manifeste" "WARNING" $WarningColor
        }
    }
    
    return $backups
}

function Remove-OldBackups {
    param(
        [string]$BackupRoot = "./backups/plans",
        [int]$RetentionDays
    )
    
    Write-LogMessage "Nettoyage des backups de plus de $RetentionDays jours..." "INFO" $InfoColor
    
    if (-not (Test-Path $BackupRoot)) {
        Write-LogMessage "Répertoire de backup non trouvé: $BackupRoot" "WARNING" $WarningColor
        return
    }
    
    $cutoffDate = (Get-Date).AddDays(-$RetentionDays)
    $backupDirs = Get-ChildItem -Path $BackupRoot -Directory
    $removedCount = 0
    $freedSpace = 0
    
    foreach ($dir in $backupDirs) {
        if ($dir.CreationTime -lt $cutoffDate) {
            $dirSize = (Get-ChildItem -Path $dir.FullName -Recurse | Measure-Object -Property Length -Sum).Sum
            
            if ($DryRun) {
                Write-LogMessage "[DRY-RUN] Supprimerait: $($dir.Name) ($([math]::Round($dirSize / 1MB, 2)) MB)" "INFO" $InfoColor
            } else {
                try {
                    Remove-Item -Path $dir.FullName -Recurse -Force
                    Write-LogMessage "Supprimé: $($dir.Name) ($([math]::Round($dirSize / 1MB, 2)) MB)" "SUCCESS" $SuccessColor
                    $removedCount++
                    $freedSpace += $dirSize
                }
                catch {
                    Write-LogMessage "Erreur lors de la suppression de $($dir.Name): $($_.Exception.Message)" "ERROR" $ErrorColor
                }
            }
        }
    }
    
    if ($removedCount -gt 0) {
        Write-LogMessage "Nettoyage terminé: $removedCount backup(s) supprimé(s), $([math]::Round($freedSpace / 1MB, 2)) MB libérés" "SUCCESS" $SuccessColor
    } else {
        Write-LogMessage "Aucun backup ancien à supprimer" "INFO" $InfoColor
    }
}

# ========================================
# EXECUTION PRINCIPALE
# ========================================

Write-Host "💾 GESTIONNAIRE DE BACKUP DES PLANS" -ForegroundColor $InfoColor
Write-Host "Action: $Action" -ForegroundColor $InfoColor
if ($DryRun) {
    Write-Host "🧪 MODE SIMULATION ACTIVÉ" -ForegroundColor $WarningColor
}
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $InfoColor

switch ($Action) {
    "backup" {
        if (-not (Initialize-BackupEnvironment)) {
            exit 1
        }
        
        $planFiles = Get-PlansToBackup $SourcePath
        if ($planFiles.Count -eq 0) {
            Write-LogMessage "Aucun plan à sauvegarder trouvé" "WARNING" $WarningColor
            exit 1
        }
        
        $result = New-BackupArchive $planFiles $BackupPath $SourcePath
        if ($result.Success) {
            Write-LogMessage "✅ Backup créé avec succès dans: $($result.BackupPath)" "SUCCESS" $SuccessColor
            exit 0
        } else {
            Write-LogMessage "❌ Échec de la création du backup" "ERROR" $ErrorColor
            exit 1
        }
    }
    
    "restore" {
        if (-not $RestoreFrom) {
            Write-LogMessage "Paramètre -RestoreFrom requis pour la restauration" "ERROR" $ErrorColor
            exit 1
        }
        
        $success = Restore-FromBackup $RestoreFrom $SourcePath
        if ($success) {
            Write-LogMessage "✅ Restauration réussie" "SUCCESS" $SuccessColor
            exit 0
        } else {
            Write-LogMessage "❌ Échec de la restauration" "ERROR" $ErrorColor
            exit 1
        }
    }
    
    "list" {
        $backups = Get-BackupList
        if ($backups.Count -eq 0) {
            Write-LogMessage "Aucun backup trouvé" "INFO" $InfoColor
        } else {
            Write-LogMessage "Total: $($backups.Count) backup(s) disponible(s)" "INFO" $InfoColor
        }
        exit 0
    }
    
    "cleanup" {
        Remove-OldBackups "./backups/plans" $RetentionDays
        exit 0
    }
}
