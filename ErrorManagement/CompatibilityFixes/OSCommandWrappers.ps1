# Wrappers pour les commandes spécifiques à l'OS
$script:IsWindows = $PSVersionTable.PSVersion.Major -lt 6 -or ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows)
$script:IsLinux = $PSVersionTable.PSVersion.Major -ge 6 -and $IsLinux
$script:IsMacOS = $PSVersionTable.PSVersion.Major -ge 6 -and $IsMacOS

# Wrapper pour Get-Content avec encodage automatique
function Get-FileContentAuto {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [switch]$Raw
    )
    
    # Détecter l'encodage (simplifié)
    $encoding = "UTF8"
    
    # Lire le contenu
    return Get-Content -Path $Path -Encoding $encoding -Raw:$Raw
}

# Wrapper pour Start-Process
function Start-CrossPlatformProcess {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [string[]]$ArgumentList,
        
        [Parameter(Mandatory = $false)]
        [switch]$Wait
    )
    
    if ($script:IsWindows) {
        $startParams = @{
            FilePath = $FilePath
            Wait = $Wait
        }
        
        if ($ArgumentList) {
            $startParams.ArgumentList = $ArgumentList
        }
        
        Start-Process @startParams
    }
    else {
        # Sur Linux/macOS
        $command = $FilePath
        
        if ($ArgumentList) {
            $command += " " + ($ArgumentList -join " ")
        }
        
        if ($Wait) {
            Invoke-Expression -Command $command
        }
        else {
            Invoke-Expression -Command "$command &"
        }
    }
}

# Wrapper pour Test-Path
function Test-CrossPlatformPath {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Any", "Container", "Leaf")]
        [string]$PathType = "Any"
    )
    
    # Normaliser le chemin
    $normalizedPath = $Path.Replace('\', [System.IO.Path]::DirectorySeparatorChar)
    $normalizedPath = $normalizedPath.Replace('/', [System.IO.Path]::DirectorySeparatorChar)
    
    # Tester le chemin
    return Test-Path -Path $normalizedPath -PathType $PathType
}

# Wrapper pour Get-Process
function Get-CrossPlatformProcess {
    param (
        [Parameter(Mandatory = $false)]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [int]$Id
    )
    
    if ($script:IsWindows) {
        $params = @{}
        if ($Name) { $params.Name = $Name }
        if ($Id) { $params.Id = $Id }
        return Get-Process @params
    }
    else {
        # Sur Linux/macOS, utiliser ps
        if ($Name) {
            $processes = & ps -e | Where-Object { $_ -match $Name }
        }
        elseif ($Id) {
            $processes = & ps -p $Id
        }
        else {
            $processes = & ps -e
        }
        
        return $processes
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Get-FileContentAuto, Start-CrossPlatformProcess
Export-ModuleMember -Function Test-CrossPlatformPath, Get-CrossPlatformProcess
