<#
.SYNOPSIS
    RÃ©solveur de conflits pour les dÃ©pendances.
.DESCRIPTION
    DÃ©tecte et rÃ©sout les conflits entre les dÃ©pendances.

<#
.SYNOPSIS
    RÃ©solveur de conflits pour les dÃ©pendances.
.DESCRIPTION
    DÃ©tecte et rÃ©sout les conflits entre les dÃ©pendances.
#>

# Configuration du rÃ©solveur de conflits
$script:ConflictResolverConfig = @{
    ConflictLog = Join-Path -Path $env:TEMP -ChildPath "dependency-conflicts.log"
    ResolutionStrategies = @{
        "HighestVersion" = { param($versions)

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
 $versions | Sort-Object { [version]$_ } -Descending | Select-Object -First 1 }
        "LowestVersion" = { param($versions) $versions | Sort-Object { [version]$_ } | Select-Object -First 1 }
        "Specific" = { param($versions, $specific) $specific }
    }
    DefaultStrategy = "HighestVersion"
}

# Initialiser le rÃ©solveur de conflits
function Initialize-ConflictResolver {
    [CmdletBinding()]
    param (
        [string]$ConflictLogPath,
        [string]$DefaultStrategy = "HighestVersion"
    )
    
    if ($ConflictLogPath) { $script:ConflictResolverConfig.ConflictLog = $ConflictLogPath }
    if ($DefaultStrategy) { $script:ConflictResolverConfig.DefaultStrategy = $DefaultStrategy }
    
    return $true
}

# DÃ©tecter les conflits
function Find-DependencyConflicts {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Dependencies
    )
    
    $conflicts = @{}
    $versions = @{}
    
    # Regrouper les versions par dÃ©pendance
    foreach ($name in $Dependencies.Keys) {
        $version = $Dependencies[$name]
        
        if (-not $versions.ContainsKey($name)) {
            $versions[$name] = @()
        }
        
        $versions[$name] += $version
    }
    
    # Identifier les conflits
    foreach ($name in $versions.Keys) {
        if ($versions[$name].Count -gt 1) {
            $uniqueVersions = $versions[$name] | Select-Object -Unique
            
            if ($uniqueVersions.Count -gt 1) {
                $conflicts[$name] = $uniqueVersions
            }
        }
    }
    
    return $conflicts
}

# RÃ©soudre les conflits
function Resolve-DependencyConflicts {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Conflicts,
        
        [Parameter(Mandatory = $false)]
        [string]$Strategy = "",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$SpecificVersions = @{}
    )
    
    $resolutions = @{}
    
    # Utiliser la stratÃ©gie par dÃ©faut si non spÃ©cifiÃ©e
    if ([string]::IsNullOrEmpty($Strategy)) {
        $Strategy = $script:ConflictResolverConfig.DefaultStrategy
    }
    
    # RÃ©soudre chaque conflit
    foreach ($name in $Conflicts.Keys) {
        $versions = $Conflicts[$name]
        
        if ($SpecificVersions.ContainsKey($name)) {
            # Utiliser une version spÃ©cifique
            $resolutions[$name] = & $script:ConflictResolverConfig.ResolutionStrategies["Specific"] $versions $SpecificVersions[$name]
        }
        else {
            # Utiliser la stratÃ©gie spÃ©cifiÃ©e
            $resolutions[$name] = & $script:ConflictResolverConfig.ResolutionStrategies[$Strategy] $versions
        }
        
        # Journaliser le conflit
        $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Conflit rÃ©solu pour '$name': Versions en conflit: $($versions -join ', ') -> Version choisie: $($resolutions[$name])"
        Add-Content -Path $script:ConflictResolverConfig.ConflictLog -Value $logEntry
    }
    
    return $resolutions
}

# Appliquer les rÃ©solutions
function Set-ConflictResolutions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Resolutions,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Dependencies
    )
    
    $resolvedDependencies = $Dependencies.Clone()
    
    # Appliquer les rÃ©solutions
    foreach ($name in $Resolutions.Keys) {
        $resolvedVersion = $Resolutions[$name]
        
        # Mettre Ã  jour toutes les occurrences de cette dÃ©pendance
        foreach ($key in $Dependencies.Keys) {
            if ($key -eq $name) {
                $resolvedDependencies[$key] = $resolvedVersion
            }
        }
    }
    
    return $resolvedDependencies
}

# Obtenir l'historique des conflits
function Get-ConflictHistory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$DependencyName = ""
    )
    
    if (-not (Test-Path -Path $script:ConflictResolverConfig.ConflictLog)) {
        return @()
    }
    
    $logEntries = Get-Content -Path $script:ConflictResolverConfig.ConflictLog
    
    if (-not [string]::IsNullOrEmpty($DependencyName)) {
        $logEntries = $logEntries | Where-Object { $_ -match "Conflit rÃ©solu pour '$DependencyName'" }
    }
    
    return $logEntries
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-ConflictResolver, Find-DependencyConflicts, Resolve-DependencyConflicts, Set-ConflictResolutions, Get-ConflictHistory

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}

