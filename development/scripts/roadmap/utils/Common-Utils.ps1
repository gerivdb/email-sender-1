# Common-Utils.ps1
# Fonctions utilitaires communes pour les scripts de roadmap

# Fonction pour écrire des messages de log
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Warning", "Error", "Success", "Debug")]
        [string]$Level = "Info"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "Info" { "White" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Success" { "Green" }
        "Debug" { "Cyan" }
        default { "White" }
    }

    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

# Fonction pour vérifier si une commande existe
function Test-CommandExists {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Command
    )

    $exists = $null -ne (Get-Command -Name $Command -ErrorAction SilentlyContinue)
    return $exists
}

# Fonction pour vérifier si un module est installé
function Test-ModuleInstalled {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModuleName
    )

    $installed = $null -ne (Get-Module -Name $ModuleName -ListAvailable -ErrorAction SilentlyContinue)
    return $installed
}

# Fonction pour vérifier si un chemin est valide
function Test-ValidPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $valid = Test-Path -Path $Path
    return $valid
}

# Fonction pour obtenir le chemin absolu
function Get-AbsolutePath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return $Path
    } else {
        return [System.IO.Path]::GetFullPath((Join-Path -Path (Get-Location) -ChildPath $Path))
    }
}

# Fonction pour créer un répertoire s'il n'existe pas
function Confirm-Directory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
        Write-Log "Répertoire créé: $Path" -Level Info
    }
}

# Fonction pour obtenir l'extension d'un fichier
function Get-FileExtension {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    return [System.IO.Path]::GetExtension($FilePath)
}

# Fonction pour obtenir le nom d'un fichier sans extension
function Get-FileNameWithoutExtension {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    return [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
}

# Fonction pour obtenir le répertoire parent d'un fichier
function Get-ParentDirectory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    return [System.IO.Path]::GetDirectoryName($FilePath)
}

# Fonction pour vérifier si un fichier est en cours d'utilisation
function Test-FileInUse {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    try {
        $fileInfo = New-Object System.IO.FileInfo $FilePath
        $stream = $fileInfo.Open([System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)

        if ($stream) {
            $stream.Close()
        }
        return $false
    } catch {
        return $true
    }
}

# Fonction pour obtenir la taille d'un fichier
function Get-FileSize {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    $fileInfo = New-Object System.IO.FileInfo $FilePath
    return $fileInfo.Length
}

# Fonction pour formater une taille de fichier
function Format-FileSize {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [long]$Size
    )

    if ($Size -lt 1KB) {
        return "$Size B"
    } elseif ($Size -lt 1MB) {
        return "{0:N2} KB" -f ($Size / 1KB)
    } elseif ($Size -lt 1GB) {
        return "{0:N2} MB" -f ($Size / 1MB)
    } else {
        return "{0:N2} GB" -f ($Size / 1GB)
    }
}

# Fonction pour obtenir la date de dernière modification d'un fichier
function Get-LastModifiedDate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    $fileInfo = New-Object System.IO.FileInfo $FilePath
    return $fileInfo.LastWriteTime
}

# Fonction pour obtenir la date de création d'un fichier
function Get-CreationDate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    $fileInfo = New-Object System.IO.FileInfo $FilePath
    return $fileInfo.CreationTime
}

# Fonction pour vérifier si un fichier est plus récent qu'un autre
function Test-FileNewer {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath1,

        [Parameter(Mandatory = $true)]
        [string]$FilePath2
    )

    $file1Date = (Get-Item -Path $FilePath1).LastWriteTime
    $file2Date = (Get-Item -Path $FilePath2).LastWriteTime

    return $file1Date -gt $file2Date
}

# Fonction pour obtenir le contenu d'un fichier avec encodage
function Get-FileContentWithEncoding {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [string]$Encoding = "UTF8"
    )

    $content = Get-Content -Path $FilePath -Raw -Encoding $Encoding
    return $content
}

# Fonction pour définir le contenu d'un fichier avec encodage
function Set-FileContentWithEncoding {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $false)]
        [string]$Encoding = "UTF8"
    )

    $Content | Set-Content -Path $FilePath -Encoding $Encoding
}

# Fonction pour obtenir l'encodage d'un fichier
function Get-FileEncoding {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    [byte[]]$bytes = Get-Content -Path $FilePath -Encoding Byte -ReadCount 4 -TotalCount 4

    if ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        return "UTF8"
    } elseif ($bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
        return "Unicode"
    } elseif ($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
        return "Unicode"
    } elseif ($bytes[0] -eq 0 -and $bytes[1] -eq 0 -and $bytes[2] -eq 0xFE -and $bytes[3] -eq 0xFF) {
        return "UTF32"
    } elseif ($bytes[0] -eq 0x2B -and $bytes[1] -eq 0x2F -and $bytes[2] -eq 0x76) {
        return "UTF7"
    } else {
        return "ASCII"
    }
}

# Exporter les fonctions
Export-ModuleMember -Function *

