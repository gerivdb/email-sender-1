<#
.SYNOPSIS
    Système de verrouillage de versions pour les dépendances.
.DESCRIPTION
    Permet de verrouiller les versions des dépendances pour assurer la reproductibilité.
#>

# Configuration du verrouillage de versions
$script:VersionLockConfig = @{
    LockFilePath = Join-Path -Path $env:TEMP -ChildPath "version-lock.json"
    LockedVersions = @{}
}

# Initialiser le système de verrouillage
function Initialize-VersionLock {
    [CmdletBinding()]
    param (
        [string]$LockFilePath
    )
    
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
    
    # Mettre à jour le fichier de verrouillage
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

# Obtenir une version verrouillée
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

# Vérifier si une version est compatible
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

# Obtenir toutes les versions verrouillées
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

# Déverrouiller une version
function Unlock-Version {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    if ($script:VersionLockConfig.LockedVersions.ContainsKey($Name)) {
        $script:VersionLockConfig.LockedVersions.Remove($Name)
        
        # Mettre à jour le fichier de verrouillage
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
        Write-Warning "La dépendance $Name n'est pas verrouillée."
        return $false
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-VersionLock, Lock-Version, Get-LockedVersion, Test-VersionCompatibility, Get-AllLockedVersions, Unlock-Version
