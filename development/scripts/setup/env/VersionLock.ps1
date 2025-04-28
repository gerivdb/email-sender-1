<#
.SYNOPSIS
    SystÃ¨me de verrouillage de versions pour les dÃ©pendances.
.DESCRIPTION
    Permet de verrouiller les versions des dÃ©pendances pour assurer la reproductibilitÃ©.

<#
.SYNOPSIS
    SystÃ¨me de verrouillage de versions pour les dÃ©pendances.
.DESCRIPTION
    Permet de verrouiller les versions des dÃ©pendances pour assurer la reproductibilitÃ©.
#>

# Configuration du verrouillage de versions
$script:VersionLockConfig = @{
    LockFilePath = Join-Path -Path $env:TEMP -ChildPath "version-lock.json"
    LockedVersions = @{}
}

# Initialiser le systÃ¨me de verrouillage
function Initialize-VersionLock {
    [CmdletBinding()]
    param (
        [string]$LockFilePath
    )

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()
# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
    
    # Ã‰crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃ©er le rÃ©pertoire de logs si nÃ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
    }
}
try {
    # Script principal

    
    if ($LockFilePath) { $script:VersionLockConfig.LockFilePath = $LockFilePath }
    
    # Charger le fichier de verrouillage s'il existe
    if (Test-Path -Path $script:VersionLockConfig.LockFilePath) {
        $lockContent = Get-Content -Path $script:VersionLockConfig.LockFilePath -Raw | ConvertFrom-Json
        $script:VersionLockConfig.LockedVersions = @{}
        
        foreach ($dependency in $lockContent.dependencies) {
            $script:VersionLockConfig.LockedVersions[$dependency.name] = $dependency.version
        }
    }
    
    return $true
}

# Verrouiller une version
function Lock-Version {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [string]$Version
    )
    
    $script:VersionLockConfig.LockedVersions[$Name] = $Version
    
    # Mettre Ã  jour le fichier de verrouillage
    $lockContent = @{
        dependencies = @()
    }
    
    foreach ($depName in $script:VersionLockConfig.LockedVersions.Keys) {
        $lockContent.dependencies += @{
            name = $depName
            version = $script:VersionLockConfig.LockedVersions[$depName]
        }
    }
    
    $lockJson = ConvertTo-Json -InputObject $lockContent -Depth 5
    Set-Content -Path $script:VersionLockConfig.LockFilePath -Value $lockJson -Force
    
    return $true
}

# Obtenir une version verrouillÃ©e
function Get-LockedVersion {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    if ($script:VersionLockConfig.LockedVersions.ContainsKey($Name)) {
        return $script:VersionLockConfig.LockedVersions[$Name]
    }
    else {
        return $null
    }
}

# VÃ©rifier si une version est compatible
function Test-VersionCompatibility {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [string]$Version
    )
    
    $lockedVersion = Get-LockedVersion -Name $Name
    
    if ($null -eq $lockedVersion) {
        return $true
    }
    
    return [version]$Version -eq [version]$lockedVersion
}

# Obtenir toutes les versions verrouillÃ©es
function Get-AllLockedVersions {
    [CmdletBinding()]
    param ()
    
    $result = @()
    
    foreach ($name in $script:VersionLockConfig.LockedVersions.Keys) {
        $result += [PSCustomObject]@{
            Name = $name
            Version = $script:VersionLockConfig.LockedVersions[$name]
        }
    }
    
    return $result
}

# DÃ©verrouiller une version
function Unlock-Version {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    if ($script:VersionLockConfig.LockedVersions.ContainsKey($Name)) {
        $script:VersionLockConfig.LockedVersions.Remove($Name)
        
        # Mettre Ã  jour le fichier de verrouillage
        $lockContent = @{
            dependencies = @()
        }
        
        foreach ($depName in $script:VersionLockConfig.LockedVersions.Keys) {
            $lockContent.dependencies += @{
                name = $depName
                version = $script:VersionLockConfig.LockedVersions[$depName]
            }
        }
        
        $lockJson = ConvertTo-Json -InputObject $lockContent -Depth 5
        Set-Content -Path $script:VersionLockConfig.LockFilePath -Value $lockJson -Force
        
        return $true
    }
    else {
        Write-Warning "La dÃ©pendance $Name n'est pas verrouillÃ©e."
        return $false
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-VersionLock, Lock-Version, Get-LockedVersion, Test-VersionCompatibility, Get-AllLockedVersions, Unlock-Version

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
