# Export-RestoreSchedules.ps1
# Script pour exporter et importer les planifications de points de restauration
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [string]$ImportPath,
    
    [Parameter(Mandatory = $false)]
    [switch]$Backup,
    
    [Parameter(Mandatory = $false)]
    [switch]$Restore,
    
    [Parameter(Mandatory = $false)]
    [switch]$Merge,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Error", "Warning", "Info", "Debug", "None")]
    [string]$LogLevel = "Info"
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$rootPath = Split-Path -Parent $parentPath
$utilsPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $rootPath))) -ChildPath "utils"
$logModulePath = Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1"

if (Test-Path -Path $logModulePath) {
    . $logModulePath
} else {
    function Write-Log {
        param (
            [string]$Message,
            [string]$Level = "Info"
        )
        
        if ($LogLevel -eq "None") {
            return
        }
        
        $logLevels = @{
            "Error" = 0
            "Warning" = 1
            "Info" = 2
            "Debug" = 3
        }
        
        if ($logLevels[$Level] -le $logLevels[$LogLevel]) {
            $color = switch ($Level) {
                "Error" { "Red" }
                "Warning" { "Yellow" }
                "Info" { "White" }
                "Debug" { "Gray" }
                default { "White" }
            }
            
            Write-Host "[$Level] $Message" -ForegroundColor $color
        }
    }
}

# Fonction pour obtenir le chemin du fichier de configuration des planifications
function Get-SchedulesConfigPath {
    [CmdletBinding()]
    param()
    
    $configPath = Join-Path -Path $parentPath -ChildPath "config"
    $schedulesPath = Join-Path -Path $configPath -ChildPath "schedules"
    
    if (-not (Test-Path -Path $schedulesPath)) {
        New-Item -Path $schedulesPath -ItemType Directory -Force | Out-Null
    }
    
    return Join-Path -Path $schedulesPath -ChildPath "schedules.json"
}

# Fonction pour obtenir le chemin du répertoire de sauvegarde
function Get-BackupPath {
    [CmdletBinding()]
    param()
    
    $backupPath = Join-Path -Path $parentPath -ChildPath "backups"
    
    if (-not (Test-Path -Path $backupPath)) {
        New-Item -Path $backupPath -ItemType Directory -Force | Out-Null
    }
    
    return $backupPath
}

# Fonction pour charger les planifications existantes
function Get-Schedules {
    [CmdletBinding()]
    param()
    
    $schedulesPath = Get-SchedulesConfigPath
    
    if (Test-Path -Path $schedulesPath) {
        try {
            $schedules = Get-Content -Path $schedulesPath -Raw | ConvertFrom-Json
            return $schedules
        } catch {
            Write-Log "Error loading schedules: $_" -Level "Error"
            return @()
        }
    } else {
        return @()
    }
}

# Fonction pour sauvegarder les planifications
function Save-Schedules {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Schedules,
        
        [Parameter(Mandatory = $false)]
        [string]$Path
    )
    
    if ([string]::IsNullOrEmpty($Path)) {
        $Path = Get-SchedulesConfigPath
    }
    
    try {
        $Schedules | ConvertTo-Json -Depth 10 | Out-File -FilePath $Path -Encoding UTF8
        Write-Log "Schedules saved to: $Path" -Level "Info"
        return $true
    } catch {
        Write-Log "Error saving schedules: $_" -Level "Error"
        return $false
    }
}

# Fonction pour exporter les planifications
function Export-RestoreSchedules {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Backup
    )
    
    # Charger les planifications
    $schedules = Get-Schedules
    
    if ($null -eq $schedules -or $schedules.Count -eq 0) {
        Write-Log "No schedules found to export" -Level "Warning"
        return $false
    }
    
    # Déterminer le chemin de sortie
    if ([string]::IsNullOrEmpty($OutputPath)) {
        if ($Backup) {
            $backupPath = Get-BackupPath
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $OutputPath = Join-Path -Path $backupPath -ChildPath "schedules_backup_$timestamp.json"
        } else {
            $OutputPath = Join-Path -Path (Get-Location) -ChildPath "schedules_export_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        }
    }
    
    # Créer le répertoire de sortie s'il n'existe pas
    $outputDir = Split-Path -Parent $OutputPath
    if (-not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    # Ajouter des métadonnées d'exportation
    $export = @{
        metadata = @{
            exported_at = (Get-Date).ToString("o")
            exported_by = [Environment]::UserName
            schedule_count = $schedules.Count
            version = "1.0"
        }
        schedules = $schedules
    }
    
    # Sauvegarder les planifications
    try {
        $export | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Log "Schedules exported successfully to: $OutputPath" -Level "Info"
        return $true
    } catch {
        Write-Log "Error exporting schedules: $_" -Level "Error"
        return $false
    }
}

# Fonction pour importer les planifications
function Import-RestoreSchedules {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ImportPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Merge,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Vérifier si le fichier d'importation existe
    if (-not (Test-Path -Path $ImportPath)) {
        Write-Log "Import file not found: $ImportPath" -Level "Error"
        return $false
    }
    
    # Charger les planifications à importer
    try {
        $import = Get-Content -Path $ImportPath -Raw | ConvertFrom-Json
        
        # Vérifier si le fichier a le bon format
        if ($null -eq $import.schedules) {
            Write-Log "Invalid import file format: $ImportPath" -Level "Error"
            return $false
        }
        
        $importedSchedules = $import.schedules
    } catch {
        Write-Log "Error loading import file: $_" -Level "Error"
        return $false
    }
    
    if ($null -eq $importedSchedules -or $importedSchedules.Count -eq 0) {
        Write-Log "No schedules found in import file: $ImportPath" -Level "Warning"
        return $false
    }
    
    # Charger les planifications existantes si fusion demandée
    $existingSchedules = @()
    
    if ($Merge) {
        $existingSchedules = Get-Schedules
    }
    
    # Fusionner ou remplacer les planifications
    if ($Merge -and $null -ne $existingSchedules -and $existingSchedules.Count -gt 0) {
        # Créer un dictionnaire des planifications existantes pour faciliter la recherche
        $existingSchedulesDict = @{}
        foreach ($schedule in $existingSchedules) {
            $existingSchedulesDict[$schedule.name] = $schedule
        }
        
        # Fusionner les planifications
        $mergedSchedules = @()
        $addedCount = 0
        $updatedCount = 0
        
        foreach ($schedule in $importedSchedules) {
            if ($existingSchedulesDict.ContainsKey($schedule.name)) {
                # La planification existe déjà
                if ($Force) {
                    # Remplacer la planification existante
                    $mergedSchedules += $schedule
                    $updatedCount++
                    Write-Log "Schedule updated: $($schedule.name)" -Level "Info"
                } else {
                    # Conserver la planification existante
                    $mergedSchedules += $existingSchedulesDict[$schedule.name]
                    Write-Log "Schedule skipped (already exists): $($schedule.name). Use -Force to overwrite." -Level "Warning"
                }
            } else {
                # Ajouter la nouvelle planification
                $mergedSchedules += $schedule
                $addedCount++
                Write-Log "Schedule added: $($schedule.name)" -Level "Info"
            }
        }
        
        # Ajouter les planifications existantes qui ne sont pas dans l'importation
        foreach ($name in $existingSchedulesDict.Keys) {
            if (-not ($importedSchedules | Where-Object { $_.name -eq $name })) {
                $mergedSchedules += $existingSchedulesDict[$name]
            }
        }
        
        # Sauvegarder les planifications fusionnées
        $result = Save-Schedules -Schedules $mergedSchedules
        
        if ($result) {
            Write-Log "Schedules imported successfully: $addedCount added, $updatedCount updated" -Level "Info"
            return $true
        } else {
            Write-Log "Failed to save merged schedules" -Level "Error"
            return $false
        }
    } else {
        # Remplacer toutes les planifications
        $result = Save-Schedules -Schedules $importedSchedules
        
        if ($result) {
            Write-Log "Schedules imported successfully: $($importedSchedules.Count) schedules" -Level "Info"
            return $true
        } else {
            Write-Log "Failed to save imported schedules" -Level "Error"
            return $false
        }
    }
}

# Fonction pour restaurer une sauvegarde
function Restore-SchedulesBackup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$BackupPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Si aucun chemin de sauvegarde n'est spécifié, utiliser la dernière sauvegarde
    if ([string]::IsNullOrEmpty($BackupPath)) {
        $backupsDir = Get-BackupPath
        $backupFiles = Get-ChildItem -Path $backupsDir -Filter "schedules_backup_*.json" | Sort-Object LastWriteTime -Descending
        
        if ($null -eq $backupFiles -or $backupFiles.Count -eq 0) {
            Write-Log "No backup files found in: $backupsDir" -Level "Error"
            return $false
        }
        
        $BackupPath = $backupFiles[0].FullName
        Write-Log "Using latest backup file: $BackupPath" -Level "Info"
    }
    
    # Importer la sauvegarde
    return Import-RestoreSchedules -ImportPath $BackupPath -Force:$Force
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    if ($Backup) {
        Export-RestoreSchedules -OutputPath $OutputPath -Backup
    } elseif ($Restore) {
        Restore-SchedulesBackup -BackupPath $ImportPath -Force:$Force
    } elseif (-not [string]::IsNullOrEmpty($ImportPath)) {
        Import-RestoreSchedules -ImportPath $ImportPath -Merge:$Merge -Force:$Force
    } else {
        Export-RestoreSchedules -OutputPath $OutputPath
    }
}
