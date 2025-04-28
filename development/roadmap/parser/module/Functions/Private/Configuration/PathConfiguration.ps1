<#
.SYNOPSIS
    Fonctions de configuration des chemins d'accès.

.DESCRIPTION
    Ce script contient des fonctions pour configurer et gérer les chemins d'accès
    utilisés par le module RoadmapParser.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2025-04-25
#>

# Importer les fonctions utilitaires de gestion des chemins
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$pathUtilsPath = Join-Path -Path $scriptPath -ChildPath "..\PathUtils"
$pathPermissionHelperPath = Join-Path -Path $pathUtilsPath -ChildPath "PathPermissionHelper.ps1"
$pathResolverPath = Join-Path -Path $pathUtilsPath -ChildPath "PathResolver.ps1"

if (Test-Path -Path $pathPermissionHelperPath) {
    . $pathPermissionHelperPath
}

if (Test-Path -Path $pathResolverPath) {
    . $pathResolverPath
}

# Fonction pour initialiser les chemins d'accès
function Initialize-Paths {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath,
        
        [Parameter(Mandatory = $false)]
        [string]$RoadmapPath,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [string]$TestsPath,
        
        [Parameter(Mandatory = $false)]
        [string]$LogsPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$CreateIfMissing,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    try {
        # Initialiser la table de hachage des chemins
        $paths = @{}
        
        # Détecter le répertoire racine du projet
        $projectRoot = Find-ProjectRoot -StartPath (Get-Location).Path
        $paths["ProjectRoot"] = $projectRoot
        
        # Configurer le chemin de configuration
        if (-not [string]::IsNullOrEmpty($ConfigPath)) {
            $paths["ConfigPath"] = Resolve-RelativePath -Path $ConfigPath -BasePath $projectRoot
        }
        else {
            $paths["ConfigPath"] = Join-Path -Path $projectRoot -ChildPath "tools\scripts\roadmap-parser\config"
        }
        
        # Configurer le chemin du fichier de roadmap
        if (-not [string]::IsNullOrEmpty($RoadmapPath)) {
            $paths["RoadmapPath"] = Resolve-RelativePath -Path $RoadmapPath -BasePath $projectRoot
        }
        else {
            $paths["RoadmapPath"] = Join-Path -Path $projectRoot -ChildPath "docs\plans\roadmap_complete_2.md"
        }
        
        # Configurer le chemin de sortie
        if (-not [string]::IsNullOrEmpty($OutputPath)) {
            $paths["OutputPath"] = Resolve-RelativePath -Path $OutputPath -BasePath $projectRoot
        }
        else {
            $paths["OutputPath"] = Join-Path -Path $projectRoot -ChildPath "tools\scripts\roadmap-parser\module\Functions\Public"
        }
        
        # Configurer le chemin des tests
        if (-not [string]::IsNullOrEmpty($TestsPath)) {
            $paths["TestsPath"] = Resolve-RelativePath -Path $TestsPath -BasePath $projectRoot
        }
        else {
            $paths["TestsPath"] = Join-Path -Path $projectRoot -ChildPath "tools\scripts\roadmap-parser\module\Tests"
        }
        
        # Configurer le chemin des logs
        if (-not [string]::IsNullOrEmpty($LogsPath)) {
            $paths["LogsPath"] = Resolve-RelativePath -Path $LogsPath -BasePath $projectRoot
        }
        else {
            $paths["LogsPath"] = Join-Path -Path $projectRoot -ChildPath "logs"
        }
        
        # Créer les répertoires si demandé
        if ($CreateIfMissing) {
            foreach ($key in $paths.Keys) {
                $path = $paths[$key]
                
                # Ne pas créer le fichier de roadmap, seulement les répertoires
                if ($key -ne "RoadmapPath" -and -not (Test-Path -Path $path -PathType Container)) {
                    New-DirectoryWithPermissions -Path $path -GrantFullControl -Force:$Force
                }
            }
        }
        
        return $paths
    }
    catch {
        Write-Error "Erreur lors de l'initialisation des chemins d'accès : $_"
        return @{}
    }
}

# Fonction pour valider les chemins d'accès
function Test-Paths {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Paths,
        
        [Parameter(Mandatory = $false)]
        [switch]$Detailed
    )
    
    try {
        # Initialiser la table de hachage des résultats
        $results = @{}
        
        # Vérifier chaque chemin
        foreach ($key in $Paths.Keys) {
            $path = $Paths[$key]
            
            # Vérifier si le chemin existe
            $exists = Test-Path -Path $path -ErrorAction SilentlyContinue
            
            # Vérifier les permissions
            $permissions = Test-PathPermissions -Path $path -TestRead -TestWrite -TestExecute -Detailed
            
            # Stocker les résultats
            $results[$key] = [PSCustomObject]@{
                Path = $path
                Exists = $exists
                Permissions = $permissions
            }
        }
        
        # Retourner les résultats détaillés si demandé
        if ($Detailed) {
            return $results
        }
        
        # Sinon, retourner un résultat simple
        return $results.Values | ForEach-Object { $_.Exists -and $_.Permissions.ReadAccess -and $_.Permissions.WriteAccess } | Where-Object { -not $_ } | Measure-Object | Select-Object -ExpandProperty Count -eq 0
    }
    catch {
        Write-Error "Erreur lors de la validation des chemins d'accès : $_"
        
        if ($Detailed) {
            return @{}
        }
        
        return $false
    }
}

# Fonction pour réparer les chemins d'accès
function Repair-Paths {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Paths,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    try {
        # Vérifier chaque chemin
        foreach ($key in $Paths.Keys) {
            $path = $Paths[$key]
            
            # Ne pas créer le fichier de roadmap, seulement les répertoires
            if ($key -ne "RoadmapPath") {
                # Vérifier si le chemin existe
                if (-not (Test-Path -Path $path -PathType Container)) {
                    # Créer le répertoire
                    if ($PSCmdlet.ShouldProcess($path, "Créer le répertoire")) {
                        New-DirectoryWithPermissions -Path $path -GrantFullControl -Force:$Force
                    }
                }
                else {
                    # Réparer les permissions
                    if ($PSCmdlet.ShouldProcess($path, "Réparer les permissions")) {
                        Repair-PathPermissions -Path $path -GrantFullControl -Force:$Force
                    }
                }
            }
        }
        
        return $true
    }
    catch {
        Write-Error "Erreur lors de la réparation des chemins d'accès : $_"
        return $false
    }
}

# Fonction pour obtenir le chemin absolu d'un fichier
function Get-AbsolutePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [string]$BasePath = (Get-Location).Path
    )
    
    try {
        return Resolve-RelativePath -Path $Path -BasePath $BasePath
    }
    catch {
        Write-Error "Erreur lors de la résolution du chemin absolu : $_"
        return $null
    }
}

# Fonction pour obtenir le chemin relatif d'un fichier
function Get-RelativePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [string]$BasePath = (Get-Location).Path
    )
    
    try {
        return Resolve-AbsolutePath -Path $Path -BasePath $BasePath
    }
    catch {
        Write-Error "Erreur lors de la résolution du chemin relatif : $_"
        return $null
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-Paths, Test-Paths, Repair-Paths, Get-AbsolutePath, Get-RelativePath
