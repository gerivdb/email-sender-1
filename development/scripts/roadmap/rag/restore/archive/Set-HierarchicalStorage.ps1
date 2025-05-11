# Set-HierarchicalStorage.ps1
# Script pour configurer et gérer le stockage hiérarchique des points de restauration par âge
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("Configure", "Apply", "Status")]
    [string]$Action = "Status",
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigName = "default",
    
    [Parameter(Mandatory = $false)]
    [int]$HotStorageDays = 30,
    
    [Parameter(Mandatory = $false)]
    [int]$WarmStorageDays = 90,
    
    [Parameter(Mandatory = $false)]
    [string]$HotStoragePath = "",
    
    [Parameter(Mandatory = $false)]
    [string]$WarmStoragePath = "",
    
    [Parameter(Mandatory = $false)]
    [string]$ColdStoragePath = "",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Zip", "7z", "Tar", "TarGz")]
    [string]$ArchiveFormat = "Zip",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("None", "Fast", "Normal", "Maximum", "Ultra")]
    [string]$CompressionLevel = "Normal",
    
    [Parameter(Mandatory = $false)]
    [switch]$RemoveOriginals,
    
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf,
    
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

# Importer le script de compression
$compressScriptPath = Join-Path -Path $scriptPath -ChildPath "Compress-RestorePoints.ps1"

if (Test-Path -Path $compressScriptPath) {
    . $compressScriptPath
} else {
    Write-Log "Required script not found: Compress-RestorePoints.ps1" -Level "Error"
    exit 1
}

# Fonction pour obtenir le chemin du répertoire des points de restauration
function Get-RestorePointsPath {
    [CmdletBinding()]
    param()
    
    $pointsPath = Join-Path -Path $rootPath -ChildPath "points"
    
    if (-not (Test-Path -Path $pointsPath)) {
        New-Item -Path $pointsPath -ItemType Directory -Force | Out-Null
    }
    
    return $pointsPath
}

# Fonction pour obtenir le chemin du répertoire des archives
function Get-ArchivesPath {
    [CmdletBinding()]
    param()
    
    $archivesPath = Join-Path -Path $rootPath -ChildPath "archives"
    
    if (-not (Test-Path -Path $archivesPath)) {
        New-Item -Path $archivesPath -ItemType Directory -Force | Out-Null
    }
    
    return $archivesPath
}

# Fonction pour obtenir le chemin du fichier de configuration du stockage hiérarchique
function Get-HierarchicalStorageConfigPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigName = "default"
    )
    
    $configPath = Join-Path -Path $parentPath -ChildPath "config"
    
    if (-not (Test-Path -Path $configPath)) {
        New-Item -Path $configPath -ItemType Directory -Force | Out-Null
    }
    
    $storagePath = Join-Path -Path $configPath -ChildPath "storage"
    
    if (-not (Test-Path -Path $storagePath)) {
        New-Item -Path $storagePath -ItemType Directory -Force | Out-Null
    }
    
    return Join-Path -Path $storagePath -ChildPath "$ConfigName.json"
}

# Fonction pour charger la configuration du stockage hiérarchique
function Get-HierarchicalStorageConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigName = "default"
    )
    
    $configPath = Get-HierarchicalStorageConfigPath -ConfigName $ConfigName
    
    if (Test-Path -Path $configPath) {
        try {
            $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
            return $config
        } catch {
            Write-Log "Error loading hierarchical storage configuration: $_" -Level "Error"
            return $null
        }
    } else {
        return $null
    }
}

# Fonction pour sauvegarder la configuration du stockage hiérarchique
function Save-HierarchicalStorageConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Config,
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigName = "default"
    )
    
    $configPath = Get-HierarchicalStorageConfigPath -ConfigName $ConfigName
    
    try {
        $Config | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Encoding UTF8
        Write-Log "Hierarchical storage configuration saved to: $configPath" -Level "Info"
        return $true
    } catch {
        Write-Log "Error saving hierarchical storage configuration: $_" -Level "Error"
        return $false
    }
}

# Fonction pour configurer le stockage hiérarchique
function Set-HierarchicalStorageConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigName = "default",
        
        [Parameter(Mandatory = $false)]
        [int]$HotStorageDays = 30,
        
        [Parameter(Mandatory = $false)]
        [int]$WarmStorageDays = 90,
        
        [Parameter(Mandatory = $false)]
        [string]$HotStoragePath = "",
        
        [Parameter(Mandatory = $false)]
        [string]$WarmStoragePath = "",
        
        [Parameter(Mandatory = $false)]
        [string]$ColdStoragePath = "",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Zip", "7z", "Tar", "TarGz")]
        [string]$ArchiveFormat = "Zip",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("None", "Fast", "Normal", "Maximum", "Ultra")]
        [string]$CompressionLevel = "Normal",
        
        [Parameter(Mandatory = $false)]
        [switch]$RemoveOriginals
    )
    
    # Valider les paramètres
    if ($HotStorageDays -lt 1) {
        Write-Log "HotStorageDays must be at least 1" -Level "Error"
        return $false
    }
    
    if ($WarmStorageDays -lt $HotStorageDays) {
        Write-Log "WarmStorageDays must be greater than or equal to HotStorageDays" -Level "Error"
        return $false
    }
    
    # Définir les chemins par défaut si non spécifiés
    if ([string]::IsNullOrEmpty($HotStoragePath)) {
        $HotStoragePath = Get-RestorePointsPath
    }
    
    if ([string]::IsNullOrEmpty($WarmStoragePath)) {
        $archivesPath = Get-ArchivesPath
        $WarmStoragePath = Join-Path -Path $archivesPath -ChildPath "warm"
    }
    
    if ([string]::IsNullOrEmpty($ColdStoragePath)) {
        $archivesPath = Get-ArchivesPath
        $ColdStoragePath = Join-Path -Path $archivesPath -ChildPath "cold"
    }
    
    # Créer les répertoires s'ils n'existent pas
    if (-not (Test-Path -Path $HotStoragePath)) {
        New-Item -Path $HotStoragePath -ItemType Directory -Force | Out-Null
    }
    
    if (-not (Test-Path -Path $WarmStoragePath)) {
        New-Item -Path $WarmStoragePath -ItemType Directory -Force | Out-Null
    }
    
    if (-not (Test-Path -Path $ColdStoragePath)) {
        New-Item -Path $ColdStoragePath -ItemType Directory -Force | Out-Null
    }
    
    # Charger la configuration existante ou créer une nouvelle
    $config = Get-HierarchicalStorageConfig -ConfigName $ConfigName
    
    if ($null -eq $config) {
        $config = @{
            name = $ConfigName
            created_at = (Get-Date).ToString("o")
            last_modified = (Get-Date).ToString("o")
            storage = @{
                hot = @{
                    days = $HotStorageDays
                    path = $HotStoragePath
                }
                warm = @{
                    days = $WarmStorageDays
                    path = $WarmStoragePath
                }
                cold = @{
                    path = $ColdStoragePath
                }
            }
            archive = @{
                format = $ArchiveFormat
                compression_level = $CompressionLevel
                remove_originals = $RemoveOriginals.IsPresent
            }
            last_run = $null
        }
    } else {
        $config.last_modified = (Get-Date).ToString("o")
        $config.storage.hot.days = $HotStorageDays
        $config.storage.hot.path = $HotStoragePath
        $config.storage.warm.days = $WarmStorageDays
        $config.storage.warm.path = $WarmStoragePath
        $config.storage.cold.path = $ColdStoragePath
        $config.archive.format = $ArchiveFormat
        $config.archive.compression_level = $CompressionLevel
        $config.archive.remove_originals = $RemoveOriginals.IsPresent
    }
    
    # Sauvegarder la configuration
    $result = Save-HierarchicalStorageConfig -Config $config -ConfigName $ConfigName
    
    if ($result) {
        Write-Log "Hierarchical storage configuration updated successfully" -Level "Info"
        return $true
    } else {
        Write-Log "Failed to update hierarchical storage configuration" -Level "Error"
        return $false
    }
}

# Fonction pour appliquer le stockage hiérarchique
function Apply-HierarchicalStorage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigName = "default",
        
        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )
    
    # Charger la configuration
    $config = Get-HierarchicalStorageConfig -ConfigName $ConfigName
    
    if ($null -eq $config) {
        Write-Log "Hierarchical storage configuration not found: $ConfigName" -Level "Error"
        return $false
    }
    
    # Obtenir les paramètres de configuration
    $hotStorageDays = $config.storage.hot.days
    $warmStorageDays = $config.storage.warm.days
    $hotStoragePath = $config.storage.hot.path
    $warmStoragePath = $config.storage.warm.path
    $coldStoragePath = $config.storage.cold.path
    $archiveFormat = $config.archive.format
    $compressionLevel = $config.archive.compression_level
    $removeOriginals = $config.archive.remove_originals
    
    # Calculer les dates limites
    $hotCutoffDate = (Get-Date).AddDays(-$hotStorageDays)
    $warmCutoffDate = (Get-Date).AddDays(-$warmStorageDays)
    
    Write-Log "Hot storage cutoff date: $hotCutoffDate" -Level "Info"
    Write-Log "Warm storage cutoff date: $warmCutoffDate" -Level "Info"
    
    # Trouver les points de restauration à déplacer vers le stockage warm
    Write-Log "Finding restore points to move to warm storage..." -Level "Info"
    $warmCandidates = Find-RestorePoints -StartDate ([DateTime]::MinValue) -EndDate $hotCutoffDate
    
    if ($warmCandidates.Count -gt 0) {
        Write-Log "Found $($warmCandidates.Count) restore points to move to warm storage" -Level "Info"
        
        # Regrouper les points par mois
        $warmGroups = $warmCandidates | Group-Object -Property { 
            $createdAt = [DateTime]::Parse($_.metadata.created_at)
            "$($createdAt.Year)-$($createdAt.Month.ToString('00'))"
        }
        
        foreach ($group in $warmGroups) {
            $yearMonth = $group.Name
            $pointIds = $group.Group | ForEach-Object { $_.metadata.id }
            
            Write-Log "Processing $($group.Count) restore points for $yearMonth" -Level "Info"
            
            $archiveName = "restore_points_$yearMonth"
            $outputPath = Join-Path -Path $warmStoragePath -ChildPath $archiveName
            
            # Compresser les points de restauration
            $result = Compress-RestorePoints -RestorePointIds $pointIds -OutputPath $outputPath -ArchiveFormat $archiveFormat -CompressionLevel $compressionLevel -RemoveOriginals:$removeOriginals -IncludeMetadataFile -WhatIf:$WhatIf
            
            if ($result -eq $false) {
                Write-Log "Failed to archive restore points for $yearMonth" -Level "Error"
            }
        }
    } else {
        Write-Log "No restore points to move to warm storage" -Level "Info"
    }
    
    # Trouver les archives à déplacer vers le stockage cold
    Write-Log "Finding archives to move to cold storage..." -Level "Info"
    $warmArchives = Get-ChildItem -Path $warmStoragePath -Filter "*.*" | Where-Object { $_.Extension -in @(".zip", ".7z", ".tar", ".gz") }
    $coldCandidates = @()
    
    foreach ($archive in $warmArchives) {
        # Vérifier si l'archive contient des points de restauration antérieurs à la date limite warm
        $metadata = Get-ArchiveMetadata -ArchivePath $archive.FullName
        
        if ($null -ne $metadata -and $metadata.PSObject.Properties.Name.Contains("restore_points")) {
            $oldestPoint = $null
            
            foreach ($point in $metadata.restore_points) {
                try {
                    $createdAt = [DateTime]::Parse($point.created_at)
                    
                    if ($null -eq $oldestPoint -or $createdAt -lt $oldestPoint) {
                        $oldestPoint = $createdAt
                    }
                } catch {
                    # Ignorer les erreurs de parsing de date
                }
            }
            
            if ($null -ne $oldestPoint -and $oldestPoint -lt $warmCutoffDate) {
                $coldCandidates += $archive
            }
        } else {
            # Si les métadonnées ne sont pas disponibles, utiliser la date de création du fichier
            if ($archive.CreationTime -lt $warmCutoffDate) {
                $coldCandidates += $archive
            }
        }
    }
    
    if ($coldCandidates.Count -gt 0) {
        Write-Log "Found $($coldCandidates.Count) archives to move to cold storage" -Level "Info"
        
        foreach ($archive in $coldCandidates) {
            $targetPath = Join-Path -Path $coldStoragePath -ChildPath $archive.Name
            
            if (-not $WhatIf) {
                try {
                    Move-Item -Path $archive.FullName -Destination $targetPath -Force
                    Write-Log "Moved archive to cold storage: $($archive.Name)" -Level "Info"
                } catch {
                    Write-Log "Error moving archive to cold storage: $($archive.Name) - $($_.Exception.Message)" -Level "Error"
                }
            } else {
                Write-Log "WhatIf: Would move archive to cold storage: $($archive.Name)" -Level "Info"
            }
        }
    } else {
        Write-Log "No archives to move to cold storage" -Level "Info"
    }
    
    # Mettre à jour la date de dernière exécution
    if (-not $WhatIf) {
        $config.last_run = (Get-Date).ToString("o")
        Save-HierarchicalStorageConfig -Config $config -ConfigName $ConfigName
    }
    
    Write-Log "Hierarchical storage operation completed" -Level "Info"
    return $true
}

# Fonction pour afficher l'état du stockage hiérarchique
function Get-HierarchicalStorageStatus {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigName = "default"
    )
    
    # Charger la configuration
    $config = Get-HierarchicalStorageConfig -ConfigName $ConfigName
    
    if ($null -eq $config) {
        Write-Log "Hierarchical storage configuration not found: $ConfigName" -Level "Error"
        return $false
    }
    
    # Obtenir les paramètres de configuration
    $hotStorageDays = $config.storage.hot.days
    $warmStorageDays = $config.storage.warm.days
    $hotStoragePath = $config.storage.hot.path
    $warmStoragePath = $config.storage.warm.path
    $coldStoragePath = $config.storage.cold.path
    $archiveFormat = $config.archive.format
    $compressionLevel = $config.archive.compression_level
    $removeOriginals = $config.archive.remove_originals
    $lastRun = if ($null -ne $config.last_run) { [DateTime]::Parse($config.last_run) } else { $null }
    
    # Calculer les dates limites
    $hotCutoffDate = (Get-Date).AddDays(-$hotStorageDays)
    $warmCutoffDate = (Get-Date).AddDays(-$warmStorageDays)
    
    # Obtenir les statistiques de stockage
    $hotFiles = if (Test-Path -Path $hotStoragePath) { Get-ChildItem -Path $hotStoragePath -Filter "*.json" -Recurse } else { @() }
    $warmFiles = if (Test-Path -Path $warmStoragePath) { Get-ChildItem -Path $warmStoragePath -Filter "*.*" -Recurse | Where-Object { $_.Extension -in @(".zip", ".7z", ".tar", ".gz") } } else { @() }
    $coldFiles = if (Test-Path -Path $coldStoragePath) { Get-ChildItem -Path $coldStoragePath -Filter "*.*" -Recurse | Where-Object { $_.Extension -in @(".zip", ".7z", ".tar", ".gz") } } else { @() }
    
    $hotCount = $hotFiles.Count
    $warmCount = $warmFiles.Count
    $coldCount = $coldFiles.Count
    
    $hotSize = ($hotFiles | Measure-Object -Property Length -Sum).Sum
    $warmSize = ($warmFiles | Measure-Object -Property Length -Sum).Sum
    $coldSize = ($coldFiles | Measure-Object -Property Length -Sum).Sum
    
    # Afficher les informations
    Write-Log "Hierarchical Storage Status for configuration: $ConfigName" -Level "Info"
    Write-Log "------------------------------------------------" -Level "Info"
    Write-Log "Hot Storage (< $hotStorageDays days):" -Level "Info"
    Write-Log "  Path: $hotStoragePath" -Level "Info"
    Write-Log "  Files: $hotCount" -Level "Info"
    Write-Log "  Size: $([Math]::Round($hotSize / 1MB, 2)) MB" -Level "Info"
    Write-Log "" -Level "Info"
    Write-Log "Warm Storage ($hotStorageDays - $warmStorageDays days):" -Level "Info"
    Write-Log "  Path: $warmStoragePath" -Level "Info"
    Write-Log "  Archives: $warmCount" -Level "Info"
    Write-Log "  Size: $([Math]::Round($warmSize / 1MB, 2)) MB" -Level "Info"
    Write-Log "" -Level "Info"
    Write-Log "Cold Storage (> $warmStorageDays days):" -Level "Info"
    Write-Log "  Path: $coldStoragePath" -Level "Info"
    Write-Log "  Archives: $coldCount" -Level "Info"
    Write-Log "  Size: $([Math]::Round($coldSize / 1MB, 2)) MB" -Level "Info"
    Write-Log "" -Level "Info"
    Write-Log "Archive Settings:" -Level "Info"
    Write-Log "  Format: $archiveFormat" -Level "Info"
    Write-Log "  Compression Level: $compressionLevel" -Level "Info"
    Write-Log "  Remove Originals: $removeOriginals" -Level "Info"
    Write-Log "" -Level "Info"
    Write-Log "Last Run: $(if ($null -ne $lastRun) { $lastRun.ToString('yyyy-MM-dd HH:mm:ss') } else { 'Never' })" -Level "Info"
    Write-Log "Hot Cutoff Date: $($hotCutoffDate.ToString('yyyy-MM-dd'))" -Level "Info"
    Write-Log "Warm Cutoff Date: $($warmCutoffDate.ToString('yyyy-MM-dd'))" -Level "Info"
    Write-Log "------------------------------------------------" -Level "Info"
    
    return @{
        ConfigName = $ConfigName
        HotStorageDays = $hotStorageDays
        WarmStorageDays = $warmStorageDays
        HotStoragePath = $hotStoragePath
        WarmStoragePath = $warmStoragePath
        ColdStoragePath = $coldStoragePath
        ArchiveFormat = $archiveFormat
        CompressionLevel = $compressionLevel
        RemoveOriginals = $removeOriginals
        LastRun = $lastRun
        HotCutoffDate = $hotCutoffDate
        WarmCutoffDate = $warmCutoffDate
        HotCount = $hotCount
        WarmCount = $warmCount
        ColdCount = $coldCount
        HotSize = $hotSize
        WarmSize = $warmSize
        ColdSize = $coldSize
    }
}

# Fonction principale pour gérer le stockage hiérarchique
function Set-HierarchicalStorage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Configure", "Apply", "Status")]
        [string]$Action = "Status",
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigName = "default",
        
        [Parameter(Mandatory = $false)]
        [int]$HotStorageDays = 30,
        
        [Parameter(Mandatory = $false)]
        [int]$WarmStorageDays = 90,
        
        [Parameter(Mandatory = $false)]
        [string]$HotStoragePath = "",
        
        [Parameter(Mandatory = $false)]
        [string]$WarmStoragePath = "",
        
        [Parameter(Mandatory = $false)]
        [string]$ColdStoragePath = "",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Zip", "7z", "Tar", "TarGz")]
        [string]$ArchiveFormat = "Zip",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("None", "Fast", "Normal", "Maximum", "Ultra")]
        [string]$CompressionLevel = "Normal",
        
        [Parameter(Mandatory = $false)]
        [switch]$RemoveOriginals,
        
        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )
    
    switch ($Action) {
        "Configure" {
            return Set-HierarchicalStorageConfig -ConfigName $ConfigName -HotStorageDays $HotStorageDays -WarmStorageDays $WarmStorageDays -HotStoragePath $HotStoragePath -WarmStoragePath $WarmStoragePath -ColdStoragePath $ColdStoragePath -ArchiveFormat $ArchiveFormat -CompressionLevel $CompressionLevel -RemoveOriginals:$RemoveOriginals
        }
        "Apply" {
            return Apply-HierarchicalStorage -ConfigName $ConfigName -WhatIf:$WhatIf
        }
        "Status" {
            return Get-HierarchicalStorageStatus -ConfigName $ConfigName
        }
        default {
            Write-Log "Invalid action: $Action" -Level "Error"
            return $false
        }
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Set-HierarchicalStorage -Action $Action -ConfigName $ConfigName -HotStorageDays $HotStorageDays -WarmStorageDays $WarmStorageDays -HotStoragePath $HotStoragePath -WarmStoragePath $WarmStoragePath -ColdStoragePath $ColdStoragePath -ArchiveFormat $ArchiveFormat -CompressionLevel $CompressionLevel -RemoveOriginals:$RemoveOriginals -WhatIf:$WhatIf
}
