# Expand-RestorePointArchive.ps1
# Script pour extraire les points de restauration des archives
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$ArchivePath,
    
    [Parameter(Mandatory = $false)]
    [string[]]$RestorePointIds = @(),
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "",
    
    [Parameter(Mandatory = $false)]
    [switch]$OverwriteExisting,
    
    [Parameter(Mandatory = $false)]
    [switch]$RestoreToOriginalLocation,
    
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

# Fonction pour obtenir le chemin du répertoire temporaire
function Get-TempPath {
    [CmdletBinding()]
    param()
    
    $tempPath = Join-Path -Path $env:TEMP -ChildPath "RestorePointArchive_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    
    if (-not (Test-Path -Path $tempPath)) {
        New-Item -Path $tempPath -ItemType Directory -Force | Out-Null
    }
    
    return $tempPath
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

# Fonction pour extraire une archive avec 7-Zip
function Expand-With7Zip {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ArchivePath,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [string[]]$FileNames = @()
    )
    
    $7zPath = Test-7Zip
    
    if (-not $7zPath) {
        Write-Log "7-Zip is not installed" -Level "Error"
        return $false
    }
    
    try {
        $arguments = "x", "`"$ArchivePath`"", "-o`"$OutputPath`"", "-y"
        
        if ($FileNames.Count -gt 0) {
            $fileListPath = [System.IO.Path]::GetTempFileName()
            $FileNames | Out-File -FilePath $fileListPath -Encoding UTF8
            $arguments += "@$fileListPath"
        }
        
        $process = Start-Process -FilePath $7zPath -ArgumentList $arguments -NoNewWindow -PassThru -Wait
        
        if ($FileNames.Count -gt 0) {
            Remove-Item -Path $fileListPath -Force -ErrorAction SilentlyContinue
        }
        
        if ($process.ExitCode -eq 0) {
            Write-Log "Successfully extracted archive to: $OutputPath" -Level "Info"
            return $true
        } else {
            Write-Log "Error extracting archive. 7-Zip exit code: $($process.ExitCode)" -Level "Error"
            return $false
        }
    } catch {
        Write-Log "Error extracting archive: $($_.Exception.Message)" -Level "Error"
        return $false
    }
}

# Fonction pour extraire une archive avec PowerShell
function Expand-WithPowerShell {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ArchivePath,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [string[]]$FileNames = @()
    )
    
    try {
        if ($FileNames.Count -gt 0) {
            # PowerShell ne permet pas d'extraire des fichiers spécifiques directement
            # Nous devons extraire toute l'archive puis filtrer
            Expand-Archive -Path $ArchivePath -DestinationPath $OutputPath -Force
            
            # Supprimer les fichiers non demandés
            $extractedFiles = Get-ChildItem -Path $OutputPath -Recurse -File
            
            foreach ($file in $extractedFiles) {
                if ($FileNames -notcontains $file.Name) {
                    Remove-Item -Path $file.FullName -Force
                }
            }
        } else {
            Expand-Archive -Path $ArchivePath -DestinationPath $OutputPath -Force
        }
        
        Write-Log "Successfully extracted archive to: $OutputPath" -Level "Info"
        return $true
    } catch {
        Write-Log "Error extracting archive: $($_.Exception.Message)" -Level "Error"
        return $false
    }
}

# Fonction pour charger les métadonnées de l'archive
function Get-ArchiveMetadata {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ArchivePath
    )
    
    $metadataPath = [System.IO.Path]::ChangeExtension($ArchivePath, ".metadata.json")
    
    if (Test-Path -Path $metadataPath) {
        try {
            $metadata = Get-Content -Path $metadataPath -Raw | ConvertFrom-Json
            return $metadata
        } catch {
            Write-Log "Error loading archive metadata: $($_.Exception.Message)" -Level "Warning"
            return $null
        }
    } else {
        Write-Log "Archive metadata file not found: $metadataPath" -Level "Warning"
        return $null
    }
}

# Fonction pour lister le contenu d'une archive
function Get-ArchiveContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ArchivePath
    )
    
    # Essayer d'abord de charger les métadonnées
    $metadata = Get-ArchiveMetadata -ArchivePath $ArchivePath
    
    if ($null -ne $metadata -and $metadata.PSObject.Properties.Name.Contains("restore_points")) {
        return $metadata.restore_points
    }
    
    # Si les métadonnées ne sont pas disponibles, utiliser 7-Zip pour lister le contenu
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

# Fonction principale pour extraire les points de restauration d'une archive
function Expand-RestorePointArchive {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ArchivePath,
        
        [Parameter(Mandatory = $false)]
        [string[]]$RestorePointIds = @(),
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$OverwriteExisting,
        
        [Parameter(Mandatory = $false)]
        [switch]$RestoreToOriginalLocation,
        
        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )
    
    # Vérifier si l'archive existe
    if (-not (Test-Path -Path $ArchivePath)) {
        Write-Log "Archive file not found: $ArchivePath" -Level "Error"
        return $false
    }
    
    # Déterminer le chemin de sortie
    if ([string]::IsNullOrEmpty($OutputPath) -or $RestoreToOriginalLocation) {
        $OutputPath = Get-RestorePointsPath
    }
    
    # Créer le répertoire de sortie si nécessaire
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }
    
    # Obtenir le contenu de l'archive
    $archiveContent = Get-ArchiveContent -ArchivePath $ArchivePath
    
    if ($archiveContent.Count -eq 0) {
        Write-Log "No restore points found in archive" -Level "Warning"
        return $false
    }
    
    Write-Log "Found $($archiveContent.Count) restore points in archive" -Level "Info"
    
    # Filtrer les points de restauration si des IDs sont spécifiés
    if ($RestorePointIds.Count -gt 0) {
        $archiveContent = $archiveContent | Where-Object { $RestorePointIds -contains $_.id }
        
        if ($archiveContent.Count -eq 0) {
            Write-Log "No matching restore points found in archive" -Level "Warning"
            return $false
        }
        
        Write-Log "Filtered to $($archiveContent.Count) matching restore points" -Level "Info"
    }
    
    # Extraire les fichiers
    if (-not $WhatIf) {
        $tempPath = Get-TempPath
        
        try {
            # Extraire l'archive
            $fileNames = $archiveContent | ForEach-Object { $_.name }
            $success = $false
            
            if ($ArchivePath -like "*.zip" -and (Get-Command -Name "Expand-Archive" -ErrorAction SilentlyContinue)) {
                $success = Expand-WithPowerShell -ArchivePath $ArchivePath -OutputPath $tempPath -FileNames $fileNames
            } else {
                $success = Expand-With7Zip -ArchivePath $ArchivePath -OutputPath $tempPath -FileNames $fileNames
            }
            
            if (-not $success) {
                Write-Log "Failed to extract archive" -Level "Error"
                return $false
            }
            
            # Déplacer les fichiers vers le répertoire de sortie
            $extractedFiles = Get-ChildItem -Path $tempPath -Recurse -File -Filter "*.json"
            $restoredCount = 0
            $errorCount = 0
            
            foreach ($file in $extractedFiles) {
                $targetPath = Join-Path -Path $OutputPath -ChildPath $file.Name
                
                if (Test-Path -Path $targetPath -and -not $OverwriteExisting) {
                    Write-Log "File already exists: $targetPath. Use -OverwriteExisting to overwrite." -Level "Warning"
                    $errorCount++
                    continue
                }
                
                try {
                    Copy-Item -Path $file.FullName -Destination $targetPath -Force
                    Write-Log "Restored: $targetPath" -Level "Info"
                    $restoredCount++
                } catch {
                    Write-Log "Error restoring $($file.Name): $($_.Exception.Message)" -Level "Error"
                    $errorCount++
                }
            }
            
            # Nettoyer le répertoire temporaire
            Remove-Item -Path $tempPath -Recurse -Force -ErrorAction SilentlyContinue
            
            Write-Log "Restore operation completed: $restoredCount files restored, $errorCount errors" -Level "Info"
            
            return $restoredCount -gt 0
        } catch {
            Write-Log "Error during restore operation: $($_.Exception.Message)" -Level "Error"
            
            # Nettoyer le répertoire temporaire
            Remove-Item -Path $tempPath -Recurse -Force -ErrorAction SilentlyContinue
            
            return $false
        }
    } else {
        Write-Log "WhatIf: Would extract $($archiveContent.Count) restore points from: $ArchivePath" -Level "Info"
        
        foreach ($item in $archiveContent) {
            $targetPath = Join-Path -Path $OutputPath -ChildPath $item.name
            
            if (Test-Path -Path $targetPath -and -not $OverwriteExisting) {
                Write-Log "  - $($item.id) (would skip - file already exists)" -Level "Info"
            } else {
                Write-Log "  - $($item.id) (would restore)" -Level "Info"
            }
        }
        
        return $true
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Expand-RestorePointArchive -ArchivePath $ArchivePath -RestorePointIds $RestorePointIds -OutputPath $OutputPath -OverwriteExisting:$OverwriteExisting -RestoreToOriginalLocation:$RestoreToOriginalLocation -WhatIf:$WhatIf
}
