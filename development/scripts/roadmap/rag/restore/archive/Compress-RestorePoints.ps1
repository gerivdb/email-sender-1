# Compress-RestorePoints.ps1
# Script pour compresser les points de restauration en archives
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string[]]$RestorePointIds = @(),
    
    [Parameter(Mandatory = $false)]
    [string]$RestorePointType = "",
    
    [Parameter(Mandatory = $false)]
    [DateTime]$StartDate,
    
    [Parameter(Mandatory = $false)]
    [DateTime]$EndDate,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Zip", "7z", "Tar", "TarGz")]
    [string]$ArchiveFormat = "Zip",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("None", "Fast", "Normal", "Maximum", "Ultra")]
    [string]$CompressionLevel = "Normal",
    
    [Parameter(Mandatory = $false)]
    [switch]$RemoveOriginals,
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeMetadataFile,
    
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

# Fonction pour obtenir l'extension de fichier en fonction du format d'archive
function Get-ArchiveExtension {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Zip", "7z", "Tar", "TarGz")]
        [string]$ArchiveFormat
    )
    
    switch ($ArchiveFormat) {
        "Zip" { return ".zip" }
        "7z" { return ".7z" }
        "Tar" { return ".tar" }
        "TarGz" { return ".tar.gz" }
        default { return ".zip" }
    }
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

# Fonction pour obtenir les paramètres de compression pour 7-Zip
function Get-7ZipCompressionLevel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("None", "Fast", "Normal", "Maximum", "Ultra")]
        [string]$CompressionLevel
    )
    
    switch ($CompressionLevel) {
        "None" { return "-mx0" }
        "Fast" { return "-mx1" }
        "Normal" { return "-mx5" }
        "Maximum" { return "-mx7" }
        "Ultra" { return "-mx9" }
        default { return "-mx5" }
    }
}

# Fonction pour créer un fichier de métadonnées pour l'archive
function New-ArchiveMetadata {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ArchivePath,
        
        [Parameter(Mandatory = $true)]
        [array]$RestorePoints
    )
    
    $metadata = @{
        archive_path = $ArchivePath
        created_at = (Get-Date).ToString("o")
        created_by = [Environment]::UserName
        hostname = [Environment]::MachineName
        restore_points = @()
    }
    
    foreach ($point in $RestorePoints) {
        $pointMetadata = @{
            id = $point.metadata.id
            name = $point.metadata.name
            type = $point.metadata.type
            created_at = $point.metadata.created_at
            file_path = $point.FilePath
        }
        
        $metadata.restore_points += $pointMetadata
    }
    
    $metadataPath = [System.IO.Path]::ChangeExtension($ArchivePath, ".metadata.json")
    
    try {
        $metadata | ConvertTo-Json -Depth 10 | Out-File -FilePath $metadataPath -Encoding UTF8
        Write-Log "Created archive metadata file: $metadataPath" -Level "Info"
        return $metadataPath
    } catch {
        Write-Log "Error creating archive metadata file: $($_.Exception.Message)" -Level "Error"
        return $false
    }
}

# Fonction pour compresser des fichiers avec 7-Zip
function Compress-With7Zip {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ArchivePath,
        
        [Parameter(Mandatory = $true)]
        [string[]]$FilePaths,
        
        [Parameter(Mandatory = $true)]
        [string]$CompressionLevel,
        
        [Parameter(Mandatory = $true)]
        [string]$ArchiveFormat
    )
    
    $7zPath = Test-7Zip
    
    if (-not $7zPath) {
        Write-Log "7-Zip is not installed" -Level "Error"
        return $false
    }
    
    $compressionParam = Get-7ZipCompressionLevel -CompressionLevel $CompressionLevel
    
    $formatParam = switch ($ArchiveFormat) {
        "Zip" { "-tzip" }
        "7z" { "-t7z" }
        "Tar" { "-ttar" }
        "TarGz" { "-tgzip" }
        default { "-tzip" }
    }
    
    try {
        $fileListPath = [System.IO.Path]::GetTempFileName()
        $FilePaths | Out-File -FilePath $fileListPath -Encoding UTF8
        
        $arguments = "a", $formatParam, $compressionParam, $ArchivePath, "@$fileListPath"
        
        $process = Start-Process -FilePath $7zPath -ArgumentList $arguments -NoNewWindow -PassThru -Wait
        
        Remove-Item -Path $fileListPath -Force
        
        if ($process.ExitCode -eq 0) {
            Write-Log "Successfully compressed files to: $ArchivePath" -Level "Info"
            return $true
        } else {
            Write-Log "Error compressing files. 7-Zip exit code: $($process.ExitCode)" -Level "Error"
            return $false
        }
    } catch {
        Write-Log "Error compressing files: $($_.Exception.Message)" -Level "Error"
        return $false
    }
}

# Fonction pour compresser des fichiers avec PowerShell
function Compress-WithPowerShell {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ArchivePath,
        
        [Parameter(Mandatory = $true)]
        [string[]]$FilePaths,
        
        [Parameter(Mandatory = $true)]
        [string]$CompressionLevel
    )
    
    try {
        $compressionLevel = switch ($CompressionLevel) {
            "None" { "NoCompression" }
            "Fast" { "Fastest" }
            "Normal" { "Optimal" }
            "Maximum" { "Optimal" }
            "Ultra" { "Optimal" }
            default { "Optimal" }
        }
        
        Compress-Archive -Path $FilePaths -DestinationPath $ArchivePath -CompressionLevel $compressionLevel -Force
        
        Write-Log "Successfully compressed files to: $ArchivePath" -Level "Info"
        return $true
    } catch {
        Write-Log "Error compressing files: $($_.Exception.Message)" -Level "Error"
        return $false
    }
}

# Fonction pour trouver les points de restauration à archiver
function Find-RestorePoints {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string[]]$RestorePointIds = @(),
        
        [Parameter(Mandatory = $false)]
        [string]$RestorePointType = "",
        
        [Parameter(Mandatory = $false)]
        [DateTime]$StartDate,
        
        [Parameter(Mandatory = $false)]
        [DateTime]$EndDate
    )
    
    $pointsPath = Get-RestorePointsPath
    $restorePointFiles = Get-ChildItem -Path $pointsPath -Filter "*.json"
    $matchingPoints = @()
    
    foreach ($file in $restorePointFiles) {
        try {
            $restorePoint = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
            $restorePoint | Add-Member -NotePropertyName "FilePath" -NotePropertyValue $file.FullName
            
            $matches = $true
            
            # Filtrer par ID
            if ($RestorePointIds.Count -gt 0) {
                $pointId = if ($restorePoint.PSObject.Properties.Name.Contains("metadata") -and 
                               $restorePoint.metadata.PSObject.Properties.Name.Contains("id")) {
                    $restorePoint.metadata.id
                } else {
                    [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
                }
                
                if ($RestorePointIds -notcontains $pointId) {
                    $matches = $false
                }
            }
            
            # Filtrer par type
            if (-not [string]::IsNullOrEmpty($RestorePointType) -and $matches) {
                $pointType = if ($restorePoint.PSObject.Properties.Name.Contains("metadata") -and 
                                 $restorePoint.metadata.PSObject.Properties.Name.Contains("type")) {
                    $restorePoint.metadata.type
                } else {
                    ""
                }
                
                if ($pointType -ne $RestorePointType) {
                    $matches = $false
                }
            }
            
            # Filtrer par date
            if (($PSBoundParameters.ContainsKey("StartDate") -or $PSBoundParameters.ContainsKey("EndDate")) -and $matches) {
                $createdAt = if ($restorePoint.PSObject.Properties.Name.Contains("metadata") -and 
                                 $restorePoint.metadata.PSObject.Properties.Name.Contains("created_at")) {
                    try {
                        [DateTime]::Parse($restorePoint.metadata.created_at)
                    } catch {
                        $null
                    }
                } else {
                    $null
                }
                
                if ($null -ne $createdAt) {
                    if ($PSBoundParameters.ContainsKey("StartDate") -and $createdAt -lt $StartDate) {
                        $matches = $false
                    }
                    
                    if ($PSBoundParameters.ContainsKey("EndDate") -and $createdAt -gt $EndDate) {
                        $matches = $false
                    }
                }
            }
            
            if ($matches) {
                $matchingPoints += $restorePoint
            }
        } catch {
            Write-Log "Error processing restore point $($file.Name): $($_.Exception.Message)" -Level "Warning"
        }
    }
    
    return $matchingPoints
}

# Fonction principale pour compresser les points de restauration
function Compress-RestorePoints {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string[]]$RestorePointIds = @(),
        
        [Parameter(Mandatory = $false)]
        [string]$RestorePointType = "",
        
        [Parameter(Mandatory = $false)]
        [DateTime]$StartDate,
        
        [Parameter(Mandatory = $false)]
        [DateTime]$EndDate,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Zip", "7z", "Tar", "TarGz")]
        [string]$ArchiveFormat = "Zip",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("None", "Fast", "Normal", "Maximum", "Ultra")]
        [string]$CompressionLevel = "Normal",
        
        [Parameter(Mandatory = $false)]
        [switch]$RemoveOriginals,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetadataFile,
        
        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )
    
    # Trouver les points de restauration à archiver
    $restorePoints = Find-RestorePoints -RestorePointIds $RestorePointIds -RestorePointType $RestorePointType -StartDate $StartDate -EndDate $EndDate
    
    if ($restorePoints.Count -eq 0) {
        Write-Log "No matching restore points found" -Level "Warning"
        return $false
    }
    
    Write-Log "Found $($restorePoints.Count) restore points to archive" -Level "Info"
    
    # Déterminer le chemin de sortie
    if ([string]::IsNullOrEmpty($OutputPath)) {
        $archivesPath = Get-ArchivesPath
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $archiveExtension = Get-ArchiveExtension -ArchiveFormat $ArchiveFormat
        
        if (-not [string]::IsNullOrEmpty($RestorePointType)) {
            $OutputPath = Join-Path -Path $archivesPath -ChildPath "restore_points_${RestorePointType}_${timestamp}$archiveExtension"
        } else {
            $OutputPath = Join-Path -Path $archivesPath -ChildPath "restore_points_${timestamp}$archiveExtension"
        }
    } else {
        # Vérifier si le chemin est un répertoire
        if (Test-Path -Path $OutputPath -PathType Container) {
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $archiveExtension = Get-ArchiveExtension -ArchiveFormat $ArchiveFormat
            
            if (-not [string]::IsNullOrEmpty($RestorePointType)) {
                $OutputPath = Join-Path -Path $OutputPath -ChildPath "restore_points_${RestorePointType}_${timestamp}$archiveExtension"
            } else {
                $OutputPath = Join-Path -Path $OutputPath -ChildPath "restore_points_${timestamp}$archiveExtension"
            }
        }
    }
    
    # Créer le répertoire parent si nécessaire
    $parentDir = Split-Path -Parent $OutputPath
    
    if (-not (Test-Path -Path $parentDir)) {
        New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
    }
    
    # Obtenir les chemins des fichiers à compresser
    $filePaths = $restorePoints | ForEach-Object { $_.FilePath }
    
    # Compresser les fichiers
    $success = $false
    
    if (-not $WhatIf) {
        if ($ArchiveFormat -eq "Zip" -and (Get-Command -Name "Compress-Archive" -ErrorAction SilentlyContinue)) {
            $success = Compress-WithPowerShell -ArchivePath $OutputPath -FilePaths $filePaths -CompressionLevel $CompressionLevel
        } else {
            $success = Compress-With7Zip -ArchivePath $OutputPath -FilePaths $filePaths -CompressionLevel $CompressionLevel -ArchiveFormat $ArchiveFormat
        }
        
        # Créer le fichier de métadonnées si demandé
        if ($success -and $IncludeMetadataFile) {
            New-ArchiveMetadata -ArchivePath $OutputPath -RestorePoints $restorePoints
        }
        
        # Supprimer les fichiers originaux si demandé
        if ($success -and $RemoveOriginals) {
            foreach ($file in $filePaths) {
                try {
                    Remove-Item -Path $file -Force
                    Write-Log "Removed original file: $file" -Level "Info"
                } catch {
                    Write-Log "Error removing original file $file: $($_.Exception.Message)" -Level "Warning"
                }
            }
        }
    } else {
        Write-Log "WhatIf: Would compress $($restorePoints.Count) restore points to: $OutputPath" -Level "Info"
        
        foreach ($point in $restorePoints) {
            $pointId = if ($point.PSObject.Properties.Name.Contains("metadata") -and 
                           $point.metadata.PSObject.Properties.Name.Contains("id")) {
                $point.metadata.id
            } else {
                [System.IO.Path]::GetFileNameWithoutExtension($point.FilePath)
            }
            
            Write-Log "  - $pointId" -Level "Info"
        }
        
        $success = $true
    }
    
    if ($success) {
        Write-Log "Archive operation completed successfully" -Level "Info"
        return $OutputPath
    } else {
        Write-Log "Archive operation failed" -Level "Error"
        return $false
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Compress-RestorePoints -RestorePointIds $RestorePointIds -RestorePointType $RestorePointType -StartDate $StartDate -EndDate $EndDate -OutputPath $OutputPath -ArchiveFormat $ArchiveFormat -CompressionLevel $CompressionLevel -RemoveOriginals:$RemoveOriginals -IncludeMetadataFile:$IncludeMetadataFile -WhatIf:$WhatIf
}
