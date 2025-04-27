<#
.SYNOPSIS
    Fonctions de rotation des journaux pour les modes RoadmapParser.

.DESCRIPTION
    Ce script contient des fonctions pour la rotation des fichiers de journalisation
    dans les diffÃ©rents modes de RoadmapParser.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>

# Configuration par dÃ©faut pour la rotation des journaux
$script:LogRotationConfig = @{
    # Configuration de rotation par taille
    SizeBasedRotation = @{
        Enabled     = $true
        MaxSizeKB   = 1024  # Taille maximale du fichier de journal en KB (1 MB par dÃ©faut)
        BackupCount = 5   # Nombre de fichiers de sauvegarde Ã  conserver
    }

    # Configuration de rotation par date
    DateBasedRotation = @{
        Enabled       = $true
        Interval      = "Daily"  # Valeurs possibles : "Hourly", "Daily", "Weekly", "Monthly"
        RetentionDays = 30  # Nombre de jours de conservation des journaux
    }

    # Configuration de compression
    Compression       = @{
        Enabled           = $false
        Format            = "Zip"  # Valeurs possibles : "Zip", "GZip"
        CompressAfterDays = 7  # Compresser les fichiers plus anciens que X jours
    }

    # Configuration de purge automatique
    AutoPurge         = @{
        Enabled        = $true
        MaxAge         = 90  # Ã‚ge maximal des fichiers en jours
        MaxCount       = 100  # Nombre maximal de fichiers Ã  conserver
        MinDiskSpaceGB = 1  # Espace disque minimal requis en GB
    }
}

<#
.SYNOPSIS
    Obtient la configuration actuelle de rotation des journaux.

.DESCRIPTION
    Cette fonction retourne la configuration actuelle de rotation des journaux.

.EXAMPLE
    $config = Get-LogRotationConfig

.OUTPUTS
    System.Collections.Hashtable
#>
function Get-LogRotationConfig {
    [CmdletBinding()]
    param()

    return $script:LogRotationConfig
}

<#
.SYNOPSIS
    DÃ©finit la configuration de rotation des journaux.

.DESCRIPTION
    Cette fonction permet de modifier la configuration de rotation des journaux.

.PARAMETER SizeBasedEnabled
    Indique si la rotation basÃ©e sur la taille est activÃ©e.

.PARAMETER MaxSizeKB
    Taille maximale du fichier de journal en KB.

.PARAMETER BackupCount
    Nombre de fichiers de sauvegarde Ã  conserver.

.PARAMETER DateBasedEnabled
    Indique si la rotation basÃ©e sur la date est activÃ©e.

.PARAMETER Interval
    Intervalle de rotation basÃ©e sur la date.

.PARAMETER RetentionDays
    Nombre de jours de conservation des journaux.

.PARAMETER CompressionEnabled
    Indique si la compression des journaux est activÃ©e.

.PARAMETER CompressionFormat
    Format de compression des journaux.

.PARAMETER CompressAfterDays
    Compresser les fichiers plus anciens que X jours.

.PARAMETER AutoPurgeEnabled
    Indique si la purge automatique est activÃ©e.

.PARAMETER MaxAge
    Ã‚ge maximal des fichiers en jours.

.PARAMETER MaxCount
    Nombre maximal de fichiers Ã  conserver.

.PARAMETER MinDiskSpaceGB
    Espace disque minimal requis en GB.

.EXAMPLE
    Set-LogRotationConfig -SizeBasedEnabled $true -MaxSizeKB 2048 -BackupCount 10

.OUTPUTS
    None
#>
function Set-LogRotationConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$SizeBasedEnabled,

        [Parameter(Mandatory = $false)]
        [int]$MaxSizeKB,

        [Parameter(Mandatory = $false)]
        [int]$BackupCount,

        [Parameter(Mandatory = $false)]
        [bool]$DateBasedEnabled,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Hourly", "Daily", "Weekly", "Monthly")]
        [string]$Interval,

        [Parameter(Mandatory = $false)]
        [int]$RetentionDays,

        [Parameter(Mandatory = $false)]
        [bool]$CompressionEnabled,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Zip", "GZip")]
        [string]$CompressionFormat,

        [Parameter(Mandatory = $false)]
        [int]$CompressAfterDays,

        [Parameter(Mandatory = $false)]
        [bool]$AutoPurgeEnabled,

        [Parameter(Mandatory = $false)]
        [int]$MaxAge,

        [Parameter(Mandatory = $false)]
        [int]$MaxCount,

        [Parameter(Mandatory = $false)]
        [double]$MinDiskSpaceGB
    )

    # Mettre Ã  jour la configuration de rotation par taille
    if ($PSBoundParameters.ContainsKey('SizeBasedEnabled')) {
        $script:LogRotationConfig.SizeBasedRotation.Enabled = $SizeBasedEnabled
    }

    if ($PSBoundParameters.ContainsKey('MaxSizeKB')) {
        $script:LogRotationConfig.SizeBasedRotation.MaxSizeKB = $MaxSizeKB
    }

    if ($PSBoundParameters.ContainsKey('BackupCount')) {
        $script:LogRotationConfig.SizeBasedRotation.BackupCount = $BackupCount
    }

    # Mettre Ã  jour la configuration de rotation par date
    if ($PSBoundParameters.ContainsKey('DateBasedEnabled')) {
        $script:LogRotationConfig.DateBasedRotation.Enabled = $DateBasedEnabled
    }

    if ($PSBoundParameters.ContainsKey('Interval')) {
        $script:LogRotationConfig.DateBasedRotation.Interval = $Interval
    }

    if ($PSBoundParameters.ContainsKey('RetentionDays')) {
        $script:LogRotationConfig.DateBasedRotation.RetentionDays = $RetentionDays
    }

    # Mettre Ã  jour la configuration de compression
    if ($PSBoundParameters.ContainsKey('CompressionEnabled')) {
        $script:LogRotationConfig.Compression.Enabled = $CompressionEnabled
    }

    if ($PSBoundParameters.ContainsKey('CompressionFormat')) {
        $script:LogRotationConfig.Compression.Format = $CompressionFormat
    }

    if ($PSBoundParameters.ContainsKey('CompressAfterDays')) {
        $script:LogRotationConfig.Compression.CompressAfterDays = $CompressAfterDays
    }

    # Mettre Ã  jour la configuration de purge automatique
    if ($PSBoundParameters.ContainsKey('AutoPurgeEnabled')) {
        $script:LogRotationConfig.AutoPurge.Enabled = $AutoPurgeEnabled
    }

    if ($PSBoundParameters.ContainsKey('MaxAge')) {
        $script:LogRotationConfig.AutoPurge.MaxAge = $MaxAge
    }

    if ($PSBoundParameters.ContainsKey('MaxCount')) {
        $script:LogRotationConfig.AutoPurge.MaxCount = $MaxCount
    }

    if ($PSBoundParameters.ContainsKey('MinDiskSpaceGB')) {
        $script:LogRotationConfig.AutoPurge.MinDiskSpaceGB = $MinDiskSpaceGB
    }

    Write-Verbose "Configuration de rotation des journaux mise Ã  jour."
}

<#
.SYNOPSIS
    VÃ©rifie si un fichier de journal doit Ãªtre rotatÃ© en fonction de sa taille.

.DESCRIPTION
    Cette fonction vÃ©rifie si un fichier de journal doit Ãªtre rotatÃ© en fonction de sa taille.

.PARAMETER LogFile
    Chemin vers le fichier de journal Ã  vÃ©rifier.

.EXAMPLE
    $shouldRotate = Test-LogRotationBySize -LogFile "logs\app.log"

.OUTPUTS
    System.Boolean
#>
function Test-LogRotationBySize {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogFile
    )

    if (-not $script:LogRotationConfig.SizeBasedRotation.Enabled) {
        return $false
    }

    if (-not (Test-Path -Path $LogFile)) {
        return $false
    }

    $fileInfo = Get-Item -Path $LogFile
    $fileSizeKB = $fileInfo.Length / 1KB

    return $fileSizeKB -ge $script:LogRotationConfig.SizeBasedRotation.MaxSizeKB
}

<#
.SYNOPSIS
    VÃ©rifie si un fichier de journal doit Ãªtre rotatÃ© en fonction de sa date.

.DESCRIPTION
    Cette fonction vÃ©rifie si un fichier de journal doit Ãªtre rotatÃ© en fonction de sa date.

.PARAMETER LogFile
    Chemin vers le fichier de journal Ã  vÃ©rifier.

.EXAMPLE
    $shouldRotate = Test-LogRotationByDate -LogFile "logs\app.log"

.OUTPUTS
    System.Boolean
#>
function Test-LogRotationByDate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogFile
    )

    if (-not $script:LogRotationConfig.DateBasedRotation.Enabled) {
        return $false
    }

    if (-not (Test-Path -Path $LogFile)) {
        return $false
    }

    $fileInfo = Get-Item -Path $LogFile
    $now = Get-Date

    switch ($script:LogRotationConfig.DateBasedRotation.Interval) {
        "Hourly" {
            return $fileInfo.LastWriteTime.Hour -ne $now.Hour -or $fileInfo.LastWriteTime.Date -ne $now.Date
        }
        "Daily" {
            return $fileInfo.LastWriteTime.Date -ne $now.Date
        }
        "Weekly" {
            $currentWeek = Get-Date -UFormat %V
            $fileWeek = $fileInfo.LastWriteTime | Get-Date -UFormat %V
            return $currentWeek -ne $fileWeek
        }
        "Monthly" {
            return $fileInfo.LastWriteTime.Month -ne $now.Month -or $fileInfo.LastWriteTime.Year -ne $now.Year
        }
    }

    return $false
}

<#
.SYNOPSIS
    Effectue la rotation d'un fichier de journal en fonction de sa taille.

.DESCRIPTION
    Cette fonction effectue la rotation d'un fichier de journal en fonction de sa taille.
    Elle crÃ©e des fichiers de sauvegarde numÃ©rotÃ©s.

.PARAMETER LogFile
    Chemin vers le fichier de journal Ã  rotater.

.EXAMPLE
    Invoke-LogRotationBySize -LogFile "logs\app.log"

.OUTPUTS
    None
#>
function Invoke-LogRotationBySize {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogFile
    )

    if (-not (Test-Path -Path $LogFile)) {
        Write-Warning "Le fichier de journal n'existe pas : $LogFile"
        return
    }

    $backupCount = $script:LogRotationConfig.SizeBasedRotation.BackupCount

    # Supprimer le fichier de sauvegarde le plus ancien s'il existe
    $oldestBackup = "$LogFile.$backupCount"
    if (Test-Path -Path $oldestBackup) {
        Remove-Item -Path $oldestBackup -Force
    }

    # DÃ©caler les fichiers de sauvegarde existants
    for ($i = $backupCount - 1; $i -ge 1; $i--) {
        $currentBackup = "$LogFile.$i"
        $nextBackup = "$LogFile.$($i + 1)"

        if (Test-Path -Path $currentBackup) {
            Move-Item -Path $currentBackup -Destination $nextBackup -Force
        }
    }

    # CrÃ©er le premier fichier de sauvegarde
    Copy-Item -Path $LogFile -Destination "$LogFile.1" -Force

    # Vider le fichier de journal actuel
    Clear-Content -Path $LogFile

    Write-Verbose "Rotation par taille effectuÃ©e pour le fichier : $LogFile"
}

<#
.SYNOPSIS
    Effectue la rotation d'un fichier de journal en fonction de sa date.

.DESCRIPTION
    Cette fonction effectue la rotation d'un fichier de journal en fonction de sa date.
    Elle crÃ©e des fichiers de sauvegarde avec un horodatage.

.PARAMETER LogFile
    Chemin vers le fichier de journal Ã  rotater.

.EXAMPLE
    Invoke-LogRotationByDate -LogFile "logs\app.log"

.OUTPUTS
    None
#>
function Invoke-LogRotationByDate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogFile
    )

    if (-not (Test-Path -Path $LogFile)) {
        Write-Warning "Le fichier de journal n'existe pas : $LogFile"
        return
    }

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFile = "$LogFile.$timestamp"

    # CrÃ©er le fichier de sauvegarde
    Copy-Item -Path $LogFile -Destination $backupFile -Force

    # Vider le fichier de journal actuel
    Clear-Content -Path $LogFile

    Write-Verbose "Rotation par date effectuÃ©e pour le fichier : $LogFile"

    # Purger les anciens fichiers de journal si nÃ©cessaire
    if ($script:LogRotationConfig.DateBasedRotation.RetentionDays -gt 0) {
        $cutoffDate = (Get-Date).AddDays(-$script:LogRotationConfig.DateBasedRotation.RetentionDays)
        $logDir = Split-Path -Parent $LogFile
        $logFileName = Split-Path -Leaf $LogFile

        Get-ChildItem -Path $logDir -Filter "$logFileName.*" | Where-Object {
            $_.LastWriteTime -lt $cutoffDate
        } | ForEach-Object {
            Remove-Item -Path $_.FullName -Force
            Write-Verbose "Fichier de journal supprimÃ© (rÃ©tention) : $($_.FullName)"
        }
    }
}

<#
.SYNOPSIS
    Compresse un fichier de journal.

.DESCRIPTION
    Cette fonction compresse un fichier de journal en utilisant le format spÃ©cifiÃ©.

.PARAMETER LogFile
    Chemin vers le fichier de journal Ã  compresser.

.EXAMPLE
    Compress-LogFile -LogFile "logs\app.log.20230815_120000"

.OUTPUTS
    None
#>
function Compress-LogFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogFile
    )

    if (-not $script:LogRotationConfig.Compression.Enabled) {
        return
    }

    if (-not (Test-Path -Path $LogFile)) {
        Write-Warning "Le fichier de journal n'existe pas : $LogFile"
        return
    }

    $compressionFormat = $script:LogRotationConfig.Compression.Format
    $compressedFile = "$LogFile.$compressionFormat".ToLower()

    try {
        switch ($compressionFormat) {
            "Zip" {
                Compress-Archive -Path $LogFile -DestinationPath $compressedFile -Force
            }
            "GZip" {
                $content = Get-Content -Path $LogFile -Raw
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($content)
                $outputStream = [System.IO.File]::Create($compressedFile)
                $gzipStream = New-Object System.IO.Compression.GZipStream($outputStream, [System.IO.Compression.CompressionMode]::Compress)
                $gzipStream.Write($bytes, 0, $bytes.Length)
                $gzipStream.Close()
                $outputStream.Close()
            }
        }

        # Supprimer le fichier original aprÃ¨s compression
        Remove-Item -Path $LogFile -Force

        Write-Verbose "Fichier de journal compressÃ© : $LogFile -> $compressedFile"
    } catch {
        Write-Warning "Erreur lors de la compression du fichier de journal : $LogFile`n$_"
    }
}

<#
.SYNOPSIS
    Effectue la purge automatique des fichiers de journal.

.DESCRIPTION
    Cette fonction effectue la purge automatique des fichiers de journal en fonction
    de leur Ã¢ge, du nombre maximal de fichiers Ã  conserver et de l'espace disque disponible.

.PARAMETER LogDirectory
    RÃ©pertoire contenant les fichiers de journal Ã  purger.

.PARAMETER LogFilePattern
    ModÃ¨le de nom de fichier pour les fichiers de journal Ã  purger.

.EXAMPLE
    Invoke-LogAutoPurge -LogDirectory "logs" -LogFilePattern "app.log.*"

.OUTPUTS
    None
#>
function Invoke-LogAutoPurge {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogDirectory,

        [Parameter(Mandatory = $true)]
        [string]$LogFilePattern
    )

    if (-not $script:LogRotationConfig.AutoPurge.Enabled) {
        return
    }

    if (-not (Test-Path -Path $LogDirectory)) {
        Write-Warning "Le rÃ©pertoire de journaux n'existe pas : $LogDirectory"
        return
    }

    # Purger les fichiers en fonction de leur Ã¢ge
    if ($script:LogRotationConfig.AutoPurge.MaxAge -gt 0) {
        $cutoffDate = (Get-Date).AddDays(-$script:LogRotationConfig.AutoPurge.MaxAge)

        Get-ChildItem -Path $LogDirectory -Filter $LogFilePattern | Where-Object {
            $_.LastWriteTime -lt $cutoffDate
        } | ForEach-Object {
            Remove-Item -Path $_.FullName -Force
            Write-Verbose "Fichier de journal supprimÃ© (Ã¢ge) : $($_.FullName)"
        }
    }

    # Purger les fichiers en fonction du nombre maximal Ã  conserver
    if ($script:LogRotationConfig.AutoPurge.MaxCount -gt 0) {
        $logFiles = Get-ChildItem -Path $LogDirectory -Filter $LogFilePattern | Sort-Object -Property LastWriteTime -Descending

        if ($logFiles.Count -gt $script:LogRotationConfig.AutoPurge.MaxCount) {
            $filesToDelete = $logFiles | Select-Object -Skip $script:LogRotationConfig.AutoPurge.MaxCount

            foreach ($file in $filesToDelete) {
                Remove-Item -Path $file.FullName -Force
                Write-Verbose "Fichier de journal supprimÃ© (nombre) : $($file.FullName)"
            }
        }
    }

    # Purger les fichiers en fonction de l'espace disque disponible
    if ($script:LogRotationConfig.AutoPurge.MinDiskSpaceGB -gt 0) {
        $drive = Split-Path -Qualifier $LogDirectory
        $driveInfo = Get-PSDrive -Name $drive.Replace(":", "")
        $freeSpaceGB = $driveInfo.Free / 1GB

        if ($freeSpaceGB -lt $script:LogRotationConfig.AutoPurge.MinDiskSpaceGB) {
            $logFiles = Get-ChildItem -Path $LogDirectory -Filter $LogFilePattern | Sort-Object -Property LastWriteTime

            foreach ($file in $logFiles) {
                Remove-Item -Path $file.FullName -Force
                Write-Verbose "Fichier de journal supprimÃ© (espace disque) : $($file.FullName)"

                # VÃ©rifier si l'espace disque est maintenant suffisant
                $driveInfo = Get-PSDrive -Name $drive.Replace(":", "")
                $freeSpaceGB = $driveInfo.Free / 1GB

                if ($freeSpaceGB -ge $script:LogRotationConfig.AutoPurge.MinDiskSpaceGB) {
                    break
                }
            }
        }
    }
}

<#
.SYNOPSIS
    Effectue la rotation d'un fichier de journal.

.DESCRIPTION
    Cette fonction effectue la rotation d'un fichier de journal en fonction de sa taille et/ou de sa date.
    Elle gÃ¨re Ã©galement la compression et la purge automatique des fichiers de journal.

.PARAMETER LogFile
    Chemin vers le fichier de journal Ã  rotater.

.EXAMPLE
    Invoke-LogRotation -LogFile "logs\app.log"

.OUTPUTS
    None
#>
function Invoke-LogRotation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogFile
    )

    if (-not (Test-Path -Path $LogFile)) {
        Write-Verbose "Le fichier de journal n'existe pas : $LogFile"
        return
    }

    $rotated = $false

    # VÃ©rifier si une rotation par taille est nÃ©cessaire
    if (Test-LogRotationBySize -LogFile $LogFile) {
        Invoke-LogRotationBySize -LogFile $LogFile
        $rotated = $true
    }

    # VÃ©rifier si une rotation par date est nÃ©cessaire
    if (Test-LogRotationByDate -LogFile $LogFile) {
        Invoke-LogRotationByDate -LogFile $LogFile
        $rotated = $true
    }

    # Si une rotation a Ã©tÃ© effectuÃ©e, vÃ©rifier si des fichiers doivent Ãªtre compressÃ©s
    if ($rotated -and $script:LogRotationConfig.Compression.Enabled) {
        $logDir = Split-Path -Parent $LogFile
        $logFileName = Split-Path -Leaf $LogFile

        Get-ChildItem -Path $logDir -Filter "$logFileName.*" | Where-Object {
            $_.Extension -ne ".zip" -and $_.Extension -ne ".gzip" -and
            $_.LastWriteTime -lt (Get-Date).AddDays(-$script:LogRotationConfig.Compression.CompressAfterDays)
        } | ForEach-Object {
            Compress-LogFile -LogFile $_.FullName
        }
    }

    # Effectuer la purge automatique si nÃ©cessaire
    if ($script:LogRotationConfig.AutoPurge.Enabled) {
        $logDir = Split-Path -Parent $LogFile
        $logFileName = Split-Path -Leaf $LogFile

        Invoke-LogAutoPurge -LogDirectory $logDir -LogFilePattern "$logFileName.*"
    }
}

# Exporter les fonctions
if ($MyInvocation.ScriptName -ne '') {
    # Nous sommes dans un module
    Export-ModuleMember -Function Get-LogRotationConfig, Set-LogRotationConfig, Test-LogRotationBySize, Test-LogRotationByDate, Invoke-LogRotationBySize, Invoke-LogRotationByDate, Compress-LogFile, Invoke-LogAutoPurge, Invoke-LogRotation
}
