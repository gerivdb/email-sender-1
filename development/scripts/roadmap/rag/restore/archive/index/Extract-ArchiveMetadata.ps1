# Export-ArchiveMetadata.ps1
# Script pour extraire les métadonnées des archives de points de restauration
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ArchivePath = "",
    
    [Parameter(Mandatory = $false)]
    [string[]]$ArchivePaths = @(),
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeContent,
    
    [Parameter(Mandatory = $false)]
    [switch]$Normalize,
    
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Error", "Warning", "Info", "Debug", "None")]
    [string]$LogLevel = "Info"
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$rootPath = Split-Path -Parent (Split-Path -Parent $parentPath)
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

# Fonction pour obtenir le chemin du répertoire des métadonnées
function Get-MetadataPath {
    [CmdletBinding()]
    param()
    
    $metadataPath = Join-Path -Path $rootPath -ChildPath "metadata"
    
    if (-not (Test-Path -Path $metadataPath)) {
        New-Item -Path $metadataPath -ItemType Directory -Force | Out-Null
    }
    
    return $metadataPath
}

# Fonction pour vérifier si 7-Zip est installé
function Test-7Zip {
    [CmdletBinding()]
    param()
    
    $7zPath = "C:\Program Files\7-Zip\7z.exe"
    
    if (Test-Path -Path $7zPath) {
        return $7zPath
    }
    
    $7zPath = "C:\Program Files (x86)\7-Zip\7z.exe"
    
    if (Test-Path -Path $7zPath) {
        return $7zPath
    }
    
    return $false
}

# Fonction pour lister le contenu d'une archive
function Get-ArchiveContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ArchivePath
    )
    
    # Vérifier si 7-Zip est installé
    $7zPath = Test-7Zip
    
    if ($7zPath) {
        try {
            $arguments = "l", "`"$ArchivePath`"", "-slt"
            $output = & $7zPath $arguments
            
            $files = @()
            $currentFile = $null
            
            foreach ($line in $output) {
                if ($line -match "^Path = (.+)$") {
                    if ($null -ne $currentFile) {
                        $files += $currentFile
                    }
                    
                    $currentFile = @{
                        path = $matches[1]
                        name = [System.IO.Path]::GetFileName($matches[1])
                        id = [System.IO.Path]::GetFileNameWithoutExtension($matches[1])
                    }
                } elseif ($line -match "^Size = (.+)$" -and $null -ne $currentFile) {
                    $currentFile.size = $matches[1]
                }
            }
            
            if ($null -ne $currentFile) {
                $files += $currentFile
            }
            
            return $files | Where-Object { $_.name -like "*.json" }
        } catch {
            Write-Log "Error listing archive content: $($_.Exception.Message)" -Level "Warning"
            return @()
        }
    } else {
        # Utiliser PowerShell pour les archives ZIP
        try {
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            $zip = [System.IO.Compression.ZipFile]::OpenRead($ArchivePath)
            
            $files = @()
            
            foreach ($entry in $zip.Entries) {
                if ($entry.Name -like "*.json") {
                    $files += @{
                        path = $entry.FullName
                        name = $entry.Name
                        id = [System.IO.Path]::GetFileNameWithoutExtension($entry.Name)
                        size = $entry.Length
                    }
                }
            }
            
            $zip.Dispose()
            
            return $files
        } catch {
            Write-Log "Error listing archive content: $($_.Exception.Message)" -Level "Warning"
            return @()
        }
    }
}

# Fonction pour extraire un fichier spécifique d'une archive
function Export-FileFromArchive {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ArchivePath,
        
        [Parameter(Mandatory = $true)]
        [string]$FileName,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    
    # Vérifier si 7-Zip est installé
    $7zPath = Test-7Zip
    
    if ($7zPath) {
        try {
            $arguments = "e", "`"$ArchivePath`"", "`"$FileName`"", "-o`"$OutputPath`"", "-y"
            $process = Start-Process -FilePath $7zPath -ArgumentList $arguments -NoNewWindow -PassThru -Wait
            
            if ($process.ExitCode -eq 0) {
                $extractedFilePath = Join-Path -Path $OutputPath -ChildPath ([System.IO.Path]::GetFileName($FileName))
                
                if (Test-Path -Path $extractedFilePath) {
                    return $extractedFilePath
                } else {
                    Write-Log "Extracted file not found: $extractedFilePath" -Level "Warning"
                    return $false
                }
            } else {
                Write-Log "Error extracting file from archive. 7-Zip exit code: $($process.ExitCode)" -Level "Warning"
                return $false
            }
        } catch {
            Write-Log "Error extracting file from archive: $($_.Exception.Message)" -Level "Warning"
            return $false
        }
    } else {
        # Utiliser PowerShell pour les archives ZIP
        try {
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            $zip = [System.IO.Compression.ZipFile]::OpenRead($ArchivePath)
            
            $entry = $zip.Entries | Where-Object { $_.FullName -eq $FileName }
            
            if ($null -eq $entry) {
                $zip.Dispose()
                Write-Log "File not found in archive: $FileName" -Level "Warning"
                return $false
            }
            
            $extractedFilePath = Join-Path -Path $OutputPath -ChildPath ([System.IO.Path]::GetFileName($FileName))
            $entryStream = $entry.Open()
            $fileStream = [System.IO.File]::Create($extractedFilePath)
            
            $entryStream.CopyTo($fileStream)
            
            $fileStream.Close()
            $entryStream.Close()
            $zip.Dispose()
            
            return $extractedFilePath
        } catch {
            Write-Log "Error extracting file from archive: $($_.Exception.Message)" -Level "Warning"
            return $false
        }
    }
}

# Fonction pour extraire les métadonnées d'un point de restauration
function Export-RestorePointMetadata {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RestorePointPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeContent
    )
    
    try {
        # Charger le point de restauration
        $restorePoint = Get-Content -Path $RestorePointPath -Raw | ConvertFrom-Json
        
        # Extraire les métadonnées de base
        $metadata = @{
            id = if ($restorePoint.PSObject.Properties.Name.Contains("metadata") -and 
                     $restorePoint.metadata.PSObject.Properties.Name.Contains("id")) {
                $restorePoint.metadata.id
            } else {
                [System.IO.Path]::GetFileNameWithoutExtension($RestorePointPath)
            }
            name = if ($restorePoint.PSObject.Properties.Name.Contains("metadata") -and 
                       $restorePoint.metadata.PSObject.Properties.Name.Contains("name")) {
                $restorePoint.metadata.name
            } else {
                ""
            }
            type = if ($restorePoint.PSObject.Properties.Name.Contains("metadata") -and 
                       $restorePoint.metadata.PSObject.Properties.Name.Contains("type")) {
                $restorePoint.metadata.type
            } else {
                ""
            }
            created_at = if ($restorePoint.PSObject.Properties.Name.Contains("metadata") -and 
                             $restorePoint.metadata.PSObject.Properties.Name.Contains("created_at")) {
                $restorePoint.metadata.created_at
            } else {
                (Get-Item -Path $RestorePointPath).CreationTime.ToString("o")
            }
            file_path = $RestorePointPath
            file_name = [System.IO.Path]::GetFileName($RestorePointPath)
            file_size = (Get-Item -Path $RestorePointPath).Length
            extracted_at = (Get-Date).ToString("o")
        }
        
        # Extraire les métadonnées d'importance
        if ($restorePoint.PSObject.Properties.Name.Contains("metadata") -and 
            $restorePoint.metadata.PSObject.Properties.Name.Contains("importance")) {
            $metadata.importance = $restorePoint.metadata.importance
        }
        
        # Extraire les métadonnées de restauration
        if ($restorePoint.PSObject.Properties.Name.Contains("restore_info")) {
            $metadata.restore_info = @{
                last_restored = $restorePoint.restore_info.last_restored
                restore_count = $restorePoint.restore_info.restore_count
            }
            
            if ($restorePoint.restore_info.PSObject.Properties.Name.Contains("restore_history")) {
                $metadata.restore_info.restore_history = $restorePoint.restore_info.restore_history
            }
        }
        
        # Extraire les métadonnées de configuration
        if ($restorePoint.PSObject.Properties.Name.Contains("content") -and 
            $restorePoint.content.PSObject.Properties.Name.Contains("configurations")) {
            $metadata.configurations = @()
            
            foreach ($config in $restorePoint.content.configurations) {
                $configMetadata = @{
                    type = $config.type
                    id = $config.id
                }
                
                $metadata.configurations += $configMetadata
            }
        }
        
        # Inclure le contenu complet si demandé
        if ($IncludeContent) {
            $metadata.content = $restorePoint
        }
        
        return $metadata
    } catch {
        Write-Log "Error extracting metadata from restore point $RestorePointPath: $($_.Exception.Message)" -Level "Warning"
        return $null
    }
}

# Fonction pour normaliser les métadonnées
function ConvertTo-Metadata {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Metadata
    )
    
    # Créer une copie des métadonnées
    $normalizedMetadata = $Metadata.PSObject.Copy()
    
    # Normaliser les dates
    if ($normalizedMetadata.PSObject.Properties.Name.Contains("created_at")) {
        try {
            $createdAt = [DateTime]::Parse($normalizedMetadata.created_at)
            $normalizedMetadata.created_at = $createdAt.ToString("o")
            $normalizedMetadata.created_year = $createdAt.Year
            $normalizedMetadata.created_month = $createdAt.Month
            $normalizedMetadata.created_day = $createdAt.Day
            $normalizedMetadata.created_hour = $createdAt.Hour
            $normalizedMetadata.created_minute = $createdAt.Minute
        } catch {
            # Ignorer les erreurs de parsing de date
        }
    }
    
    if ($normalizedMetadata.PSObject.Properties.Name.Contains("extracted_at")) {
        try {
            $extractedAt = [DateTime]::Parse($normalizedMetadata.extracted_at)
            $normalizedMetadata.extracted_at = $extractedAt.ToString("o")
        } catch {
            # Ignorer les erreurs de parsing de date
        }
    }
    
    if ($normalizedMetadata.PSObject.Properties.Name.Contains("restore_info") -and 
        $normalizedMetadata.restore_info.PSObject.Properties.Name.Contains("last_restored") -and 
        -not [string]::IsNullOrEmpty($normalizedMetadata.restore_info.last_restored)) {
        try {
            $lastRestored = [DateTime]::Parse($normalizedMetadata.restore_info.last_restored)
            $normalizedMetadata.restore_info.last_restored = $lastRestored.ToString("o")
            $normalizedMetadata.restore_info.last_restored_year = $lastRestored.Year
            $normalizedMetadata.restore_info.last_restored_month = $lastRestored.Month
            $normalizedMetadata.restore_info.last_restored_day = $lastRestored.Day
        } catch {
            # Ignorer les erreurs de parsing de date
        }
    }
    
    # Normaliser les tailles de fichier
    if ($normalizedMetadata.PSObject.Properties.Name.Contains("file_size")) {
        $normalizedMetadata.file_size_kb = [Math]::Round($normalizedMetadata.file_size / 1KB, 2)
        $normalizedMetadata.file_size_mb = [Math]::Round($normalizedMetadata.file_size / 1MB, 2)
    }
    
    # Normaliser les types
    if ($normalizedMetadata.PSObject.Properties.Name.Contains("type")) {
        $normalizedMetadata.type_lower = $normalizedMetadata.type.ToLower()
    }
    
    # Normaliser les configurations
    if ($normalizedMetadata.PSObject.Properties.Name.Contains("configurations")) {
        $normalizedMetadata.configuration_types = @()
        $normalizedMetadata.configuration_ids = @()
        
        foreach ($config in $normalizedMetadata.configurations) {
            $normalizedMetadata.configuration_types += $config.type
            $normalizedMetadata.configuration_ids += $config.id
        }
    }
    
    # Ajouter des champs de recherche
    $normalizedMetadata.search_text = ""
    
    if ($normalizedMetadata.PSObject.Properties.Name.Contains("id")) {
        $normalizedMetadata.search_text += "$($normalizedMetadata.id) "
    }
    
    if ($normalizedMetadata.PSObject.Properties.Name.Contains("name")) {
        $normalizedMetadata.search_text += "$($normalizedMetadata.name) "
    }
    
    if ($normalizedMetadata.PSObject.Properties.Name.Contains("type")) {
        $normalizedMetadata.search_text += "$($normalizedMetadata.type) "
    }
    
    if ($normalizedMetadata.PSObject.Properties.Name.Contains("configurations")) {
        foreach ($config in $normalizedMetadata.configurations) {
            $normalizedMetadata.search_text += "$($config.type) $($config.id) "
        }
    }
    
    $normalizedMetadata.search_text = $normalizedMetadata.search_text.Trim()
    
    return $normalizedMetadata
}

# Fonction principale pour extraire les métadonnées des archives
function Export-ArchiveMetadata {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "",
        
        [Parameter(Mandatory = $false)]
        [string[]]$ArchivePaths = @(),
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$Force,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeContent,
        
        [Parameter(Mandatory = $false)]
        [switch]$Normalize,
        
        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )
    
    # Vérifier si un chemin d'archive est spécifié
    if ([string]::IsNullOrEmpty($ArchivePath) -and $ArchivePaths.Count -eq 0) {
        # Utiliser le répertoire des archives par défaut
        $archivesPath = Get-ArchivesPath
        $archiveFiles = Get-ChildItem -Path $archivesPath -Filter "*.*" -Recurse | Where-Object { $_.Extension -in @(".zip", ".7z", ".tar", ".gz") }
        
        if ($archiveFiles.Count -eq 0) {
            Write-Log "No archives found" -Level "Warning"
            return $false
        }
        
        $ArchivePaths = $archiveFiles.FullName
    } elseif (-not [string]::IsNullOrEmpty($ArchivePath)) {
        $ArchivePaths += $ArchivePath
    }
    
    # Déterminer le chemin de sortie
    if ([string]::IsNullOrEmpty($OutputPath)) {
        $OutputPath = Get-MetadataPath
    }
    
    # Créer le répertoire de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }
    
    # Créer un répertoire temporaire
    $tempPath = Join-Path -Path $env:TEMP -ChildPath "ArchiveMetadata_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    New-Item -Path $tempPath -ItemType Directory -Force | Out-Null
    
    # Initialiser les compteurs
    $totalArchives = $ArchivePaths.Count
    $processedArchives = 0
    $extractedPoints = 0
    $errorCount = 0
    
    # Traiter chaque archive
    foreach ($path in $ArchivePaths) {
        $processedArchives++
        $archiveName = [System.IO.Path]::GetFileName($path)
        
        Write-Log "Processing archive $processedArchives of $totalArchives: $archiveName" -Level "Info"
        
        # Vérifier si l'archive existe
        if (-not (Test-Path -Path $path)) {
            Write-Log "Archive not found: $path" -Level "Warning"
            $errorCount++
            continue
        }
        
        # Vérifier si un fichier de métadonnées existe déjà pour cette archive
        $archiveId = [System.IO.Path]::GetFileNameWithoutExtension($path)
        $metadataFilePath = Join-Path -Path $OutputPath -ChildPath "$archiveId.metadata.json"
        
        if (Test-Path -Path $metadataFilePath -and -not $Force) {
            Write-Log "Metadata file already exists: $metadataFilePath. Use -Force to overwrite." -Level "Info"
            continue
        }
        
        # Vérifier si un fichier de métadonnées d'archive existe
        $archiveMetadataPath = [System.IO.Path]::ChangeExtension($path, ".metadata.json")
        
        if (Test-Path -Path $archiveMetadataPath) {
            try {
                $archiveMetadata = Get-Content -Path $archiveMetadataPath -Raw | ConvertFrom-Json
                
                # Vérifier si les métadonnées contiennent des informations sur les points de restauration
                if ($archiveMetadata.PSObject.Properties.Name.Contains("restore_points") -and 
                    $archiveMetadata.restore_points.Count -gt 0) {
                    
                    Write-Log "Using existing archive metadata file: $archiveMetadataPath" -Level "Info"
                    
                    $metadata = @{
                        archive_id = $archiveId
                        archive_path = $path
                        archive_name = $archiveName
                        archive_size = (Get-Item -Path $path).Length
                        extracted_at = (Get-Date).ToString("o")
                        restore_points = @()
                    }
                    
                    foreach ($point in $archiveMetadata.restore_points) {
                        $pointMetadata = @{
                            id = $point.id
                            name = $point.name
                            type = $point.type
                            created_at = $point.created_at
                            file_path = $point.file_path
                        }
                        
                        # Normaliser les métadonnées si demandé
                        if ($Normalize) {
                            $pointMetadata = ConvertTo-Metadata -Metadata $pointMetadata
                        }
                        
                        $metadata.restore_points += $pointMetadata
                    }
                    
                    # Sauvegarder les métadonnées
                    if (-not $WhatIf) {
                        $metadata | ConvertTo-Json -Depth 10 | Out-File -FilePath $metadataFilePath -Encoding UTF8
                        Write-Log "Metadata saved to: $metadataFilePath" -Level "Info"
                    } else {
                        Write-Log "WhatIf: Would save metadata to: $metadataFilePath" -Level "Info"
                    }
                    
                    $extractedPoints += $metadata.restore_points.Count
                    continue
                }
            } catch {
                Write-Log "Error reading archive metadata file: $($_.Exception.Message)" -Level "Warning"
            }
        }
        
        # Lister le contenu de l'archive
        $archiveContent = Get-ArchiveContent -ArchivePath $path
        
        if ($archiveContent.Count -eq 0) {
            Write-Log "No restore points found in archive: $path" -Level "Warning"
            $errorCount++
            continue
        }
        
        Write-Log "Found $($archiveContent.Count) restore points in archive" -Level "Info"
        
        # Extraire les métadonnées de chaque point de restauration
        $metadata = @{
            archive_id = $archiveId
            archive_path = $path
            archive_name = $archiveName
            archive_size = (Get-Item -Path $path).Length
            extracted_at = (Get-Date).ToString("o")
            restore_points = @()
        }
        
        foreach ($file in $archiveContent) {
            # Extraire le fichier de l'archive
            $extractedFilePath = Export-FileFromArchive -ArchivePath $path -FileName $file.path -OutputPath $tempPath
            
            if ($extractedFilePath -eq $false) {
                Write-Log "Failed to extract file: $($file.path)" -Level "Warning"
                $errorCount++
                continue
            }
            
            # Extraire les métadonnées du point de restauration
            $pointMetadata = Export-RestorePointMetadata -RestorePointPath $extractedFilePath -IncludeContent:$IncludeContent
            
            if ($null -eq $pointMetadata) {
                Write-Log "Failed to extract metadata from: $($file.name)" -Level "Warning"
                $errorCount++
                continue
            }
            
            # Normaliser les métadonnées si demandé
            if ($Normalize) {
                $pointMetadata = ConvertTo-Metadata -Metadata $pointMetadata
            }
            
            $metadata.restore_points += $pointMetadata
            $extractedPoints++
            
            # Supprimer le fichier extrait
            Remove-Item -Path $extractedFilePath -Force -ErrorAction SilentlyContinue
        }
        
        # Sauvegarder les métadonnées
        if (-not $WhatIf) {
            $metadata | ConvertTo-Json -Depth 10 | Out-File -FilePath $metadataFilePath -Encoding UTF8
            Write-Log "Metadata saved to: $metadataFilePath" -Level "Info"
        } else {
            Write-Log "WhatIf: Would save metadata to: $metadataFilePath" -Level "Info"
        }
    }
    
    # Nettoyer le répertoire temporaire
    Remove-Item -Path $tempPath -Recurse -Force -ErrorAction SilentlyContinue
    
    # Afficher le résumé
    Write-Log "Metadata extraction completed: $processedArchives archives processed, $extractedPoints restore points extracted, $errorCount errors" -Level "Info"
    
    return @{
        ProcessedArchives = $processedArchives
        ExtractedPoints = $extractedPoints
        ErrorCount = $errorCount
        OutputPath = $OutputPath
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Export-ArchiveMetadata -ArchivePath $ArchivePath -ArchivePaths $ArchivePaths -OutputPath $OutputPath -Force:$Force -IncludeContent:$IncludeContent -Normalize:$Normalize -WhatIf:$WhatIf
}


