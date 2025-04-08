<#
.SYNOPSIS
    Gestionnaire de dépendances centralisé pour les scripts PowerShell.
.DESCRIPTION
    Gère les dépendances des scripts PowerShell de manière centralisée.
#>

# Configuration des dépendances
$script:DependencyConfig = @{
    RepositoryPath = Join-Path -Path $env:TEMP -ChildPath "Dependencies"
    Repositories = @{
        "PSGallery" = "https://www.powershellgallery.com/api/v2"
        "Local" = Join-Path -Path $env:TEMP -ChildPath "LocalRepo"
    }
    InstalledModules = @{}
    LockFile = Join-Path -Path $env:TEMP -ChildPath "dependency-lock.json"
}

# Initialiser le gestionnaire
function Initialize-DependencyManager {
    [CmdletBinding()]
    param (
        [string]$RepositoryPath,
        [hashtable]$Repositories,
        [string]$LockFilePath
    )
    
    if ($RepositoryPath) { $script:DependencyConfig.RepositoryPath = $RepositoryPath }
    if ($Repositories) { $script:DependencyConfig.Repositories = $Repositories }
    if ($LockFilePath) { $script:DependencyConfig.LockFile = $LockFilePath }
    
    # Créer les dossiers nécessaires
    if (-not (Test-Path -Path $script:DependencyConfig.RepositoryPath)) {
        New-Item -Path $script:DependencyConfig.RepositoryPath -ItemType Directory -Force | Out-Null
    }
    
    foreach ($repo in $script:DependencyConfig.Repositories.Values) {
        if ($repo -match "^[A-Za-z]:\\" -and -not (Test-Path -Path $repo)) {
            New-Item -Path $repo -ItemType Directory -Force | Out-Null
        }
    }
    
    # Charger le fichier de verrouillage s'il existe
    if (Test-Path -Path $script:DependencyConfig.LockFile) {
        $lockContent = Get-Content -Path $script:DependencyConfig.LockFile -Raw | ConvertFrom-Json
        $script:DependencyConfig.InstalledModules = @{}
        
        foreach ($module in $lockContent.modules) {
            $script:DependencyConfig.InstalledModules[$module.name] = @{
                Version = $module.version
                Path = $module.path
                Dependencies = $module.dependencies
            }
        }
    }
    
    return $true
}

# Installer un module
function Install-Dependency {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [string]$Version,
        
        [Parameter(Mandatory = $false)]
        [string]$Repository = "PSGallery",
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Vérifier si le module est déjà installé
    if (-not $Force -and $script:DependencyConfig.InstalledModules.ContainsKey($Name)) {
        $installedVersion = $script:DependencyConfig.InstalledModules[$Name].Version
        
        if (-not $Version -or [version]$installedVersion -ge [version]$Version) {
            Write-Verbose "Le module $Name (version $installedVersion) est déjà installé."
            return $script:DependencyConfig.InstalledModules[$Name]
        }
    }
    
    # Installer le module
    try {
        $params = @{
            Name = $Name
            Repository = $Repository
            Scope = "CurrentUser"
            ErrorAction = "Stop"
        }
        
        if ($Version) {
            $params.RequiredVersion = $Version
        }
        
        $module = Install-Module @params -PassThru
        
        # Enregistrer les informations du module
        $script:DependencyConfig.InstalledModules[$Name] = @{
            Version = $module.Version.ToString()
            Path = $module.ModuleBase
            Dependencies = @()
        }
        
        # Mettre à jour le fichier de verrouillage
        Update-DependencyLock
        
        return $script:DependencyConfig.InstalledModules[$Name]
    }
    catch {
        Write-Error "Erreur lors de l'installation du module $Name : $_"
        return $null
    }
}

# Importer un module
function Import-Dependency {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [string]$Version,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Vérifier si le module est installé
    if (-not $script:DependencyConfig.InstalledModules.ContainsKey($Name)) {
        Write-Error "Le module $Name n'est pas installé. Utilisez Install-Dependency pour l'installer."
        return $false
    }
    
    # Vérifier la version
    if ($Version -and [version]$script:DependencyConfig.InstalledModules[$Name].Version -lt [version]$Version) {
        Write-Error "La version installée du module $Name ($($script:DependencyConfig.InstalledModules[$Name].Version)) est inférieure à la version requise ($Version)."
        return $false
    }
    
    # Importer le module
    try {
        Import-Module -Name $Name -Force:$Force -ErrorAction Stop
        return $true
    }
    catch {
        Write-Error "Erreur lors de l'importation du module $Name : $_"
        return $false
    }
}

# Mettre à jour le fichier de verrouillage
function Update-DependencyLock {
    [CmdletBinding()]
    param ()
    
    $lockContent = @{
        modules = @()
    }
    
    foreach ($name in $script:DependencyConfig.InstalledModules.Keys) {
        $module = $script:DependencyConfig.InstalledModules[$name]
        
        $lockContent.modules += @{
            name = $name
            version = $module.Version
            path = $module.Path
            dependencies = $module.Dependencies
        }
    }
    
    $lockJson = ConvertTo-Json -InputObject $lockContent -Depth 10
    Set-Content -Path $script:DependencyConfig.LockFile -Value $lockJson -Force
    
    return $true
}

# Obtenir les dépendances installées
function Get-InstalledDependencies {
    [CmdletBinding()]
    param ()
    
    $result = @()
    
    foreach ($name in $script:DependencyConfig.InstalledModules.Keys) {
        $module = $script:DependencyConfig.InstalledModules[$name]
        
        $result += [PSCustomObject]@{
            Name = $name
            Version = $module.Version
            Path = $module.Path
            Dependencies = $module.Dependencies
        }
    }
    
    return $result
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-DependencyManager, Install-Dependency, Import-Dependency, Update-DependencyLock, Get-InstalledDependencies
