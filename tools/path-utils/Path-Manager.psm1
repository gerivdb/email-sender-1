# Path-Manager.psm1
# Module PowerShell pour la gestion des chemins dans le projet
# Ce module fournit des fonctions pour gÃ©rer les chemins relatifs et absolus de maniÃ¨re cohÃ©rente

# Variables globales
$script:ProjectRoot = $null
$script:PathMappings = @{}

<#
.SYNOPSIS
    Initialise le gestionnaire de chemins avec le rÃ©pertoire racine du projet.
.DESCRIPTION
    Cette fonction initialise le gestionnaire de chemins en dÃ©finissant le rÃ©pertoire racine du projet
    et en crÃ©ant les mappages de chemins pour les rÃ©pertoires principaux du projet.
.PARAMETER ProjectRootPath
    Le chemin absolu vers le rÃ©pertoire racine du projet. Si non spÃ©cifiÃ©, utilise le rÃ©pertoire courant.
.EXAMPLE
    Initialize-PathManager -ProjectRootPath "D:\DO\WEB\N8N_tests\scripts_ json_a_ tester\EMAIL_SENDER_1"
.EXAMPLE
    Initialize-PathManager # Utilise le rÃ©pertoire courant comme racine du projet
#>
function Initialize-PathManager {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ProjectRootPath = (Get-Location).Path
    )

    # VÃ©rifier que le chemin existe
    if (-not (Test-Path -Path $ProjectRootPath -PathType Container)) {
        throw "Le rÃ©pertoire racine du projet n'existe pas: $ProjectRootPath"
    }

    # DÃ©finir le rÃ©pertoire racine du projet
    $script:ProjectRoot = $ProjectRootPath

    # CrÃ©er les mappages de chemins pour les rÃ©pertoires principaux du projet
    $script:PathMappings = @{
        "root" = $script:ProjectRoot
        "scripts" = Join-Path -Path $script:ProjectRoot -ChildPath "scripts"
        "tools" = Join-Path -Path $script:ProjectRoot -ChildPath "tools"
        "src" = Join-Path -Path $script:ProjectRoot -ChildPath "src"
        "docs" = Join-Path -Path $script:ProjectRoot -ChildPath "docs"
        "workflows" = Join-Path -Path $script:ProjectRoot -ChildPath "workflows"
        "config" = Join-Path -Path $script:ProjectRoot -ChildPath "config"
        "logs" = Join-Path -Path $script:ProjectRoot -ChildPath "logs"
        "tests" = Join-Path -Path $script:ProjectRoot -ChildPath "tests"
        "assets" = Join-Path -Path $script:ProjectRoot -ChildPath "assets"
        "journal" = Join-Path -Path $script:ProjectRoot -ChildPath "journal"
        "mcp" = Join-Path -Path $script:ProjectRoot -ChildPath "mcp"
        "mcp-servers" = Join-Path -Path $script:ProjectRoot -ChildPath "mcp-servers"
        "node_modules" = Join-Path -Path $script:ProjectRoot -ChildPath "node_modules"
    }

    # Ajouter des sous-rÃ©pertoires importants
    $script:PathMappings["scripts-utils"] = Join-Path -Path $script:PathMappings["scripts"] -ChildPath "utils"
    $script:PathMappings["scripts-maintenance"] = Join-Path -Path $script:PathMappings["scripts"] -ChildPath "maintenance"
    $script:PathMappings["scripts-python"] = Join-Path -Path $script:PathMappings["scripts"] -ChildPath "python"
    $script:PathMappings["docs-journal"] = Join-Path -Path $script:PathMappings["docs"] -ChildPath "journal_de_bord"
    $script:PathMappings["docs-reference"] = Join-Path -Path $script:PathMappings["docs"] -ChildPath "reference"
    $script:PathMappings["tools-roadmap"] = Join-Path -Path $script:PathMappings["tools"] -ChildPath "roadmap"

    Write-Verbose "Gestionnaire de chemins initialisÃ© avec le rÃ©pertoire racine: $script:ProjectRoot"
    return $script:ProjectRoot
}

<#
.SYNOPSIS
    Obtient le chemin absolu Ã  partir d'un chemin relatif au rÃ©pertoire racine du projet.
.DESCRIPTION
    Cette fonction convertit un chemin relatif au rÃ©pertoire racine du projet en chemin absolu.
.PARAMETER RelativePath
    Le chemin relatif au rÃ©pertoire racine du projet.
.PARAMETER BasePath
    Le chemin de base Ã  utiliser pour la rÃ©solution. Par dÃ©faut, utilise le rÃ©pertoire racine du projet.
.EXAMPLE
    Get-ProjectPath -RelativePath "scripts\utils\path-utils.ps1"
.EXAMPLE
    Get-ProjectPath -RelativePath "path-utils.ps1" -BasePath "scripts\utils"
#>
function Get-ProjectPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$RelativePath,

        [Parameter(Mandatory = $false)]
        [string]$BasePath = ""
    )

    # VÃ©rifier que le gestionnaire de chemins est initialisÃ©
    if ($null -eq $script:ProjectRoot) {
        Initialize-PathManager
    }

    # Si le BasePath est une clÃ© dans PathMappings, utiliser le chemin correspondant
    if ($script:PathMappings.ContainsKey($BasePath)) {
        $BasePathResolved = $script:PathMappings[$BasePath]
    }
    # Sinon, si BasePath est spÃ©cifiÃ©, le joindre au rÃ©pertoire racine
    elseif ($BasePath) {
        $BasePathResolved = Join-Path -Path $script:ProjectRoot -ChildPath $BasePath
    }
    # Sinon, utiliser le rÃ©pertoire racine
    else {
        $BasePathResolved = $script:ProjectRoot
    }

    # Joindre le chemin relatif au chemin de base
    $AbsolutePath = Join-Path -Path $BasePathResolved -ChildPath $RelativePath

    return $AbsolutePath
}

<#
.SYNOPSIS
    Obtient le chemin relatif Ã  partir d'un chemin absolu.
.DESCRIPTION
    Cette fonction convertit un chemin absolu en chemin relatif au rÃ©pertoire racine du projet ou Ã  un autre rÃ©pertoire de base.
.PARAMETER AbsolutePath
    Le chemin absolu Ã  convertir.
.PARAMETER BasePath
    Le chemin de base Ã  utiliser pour la conversion. Par dÃ©faut, utilise le rÃ©pertoire racine du projet.
.EXAMPLE
    Get-RelativePath -AbsolutePath "D:\DO\WEB\N8N_tests\scripts_ json_a_ tester\EMAIL_SENDER_1\scripts\utils\path-utils.ps1"
.EXAMPLE
    Get-RelativePath -AbsolutePath "D:\DO\WEB\N8N_tests\scripts_ json_a_ tester\EMAIL_SENDER_1\scripts\utils\path-utils.ps1" -BasePath "scripts"
#>
function Get-RelativePath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$AbsolutePath,

        [Parameter(Mandatory = $false)]
        [string]$BasePath = ""
    )

    # VÃ©rifier que le gestionnaire de chemins est initialisÃ©
    if ($null -eq $script:ProjectRoot) {
        Initialize-PathManager
    }

    # Si le BasePath est une clÃ© dans PathMappings, utiliser le chemin correspondant
    if ($script:PathMappings.ContainsKey($BasePath)) {
        $BasePathResolved = $script:PathMappings[$BasePath]
    }
    # Sinon, si BasePath est spÃ©cifiÃ©, le joindre au rÃ©pertoire racine
    elseif ($BasePath) {
        $BasePathResolved = Join-Path -Path $script:ProjectRoot -ChildPath $BasePath
    }
    # Sinon, utiliser le rÃ©pertoire racine
    else {
        $BasePathResolved = $script:ProjectRoot
    }

    # Convertir les chemins en objets System.IO.FileInfo pour utiliser la mÃ©thode GetRelativePath
    $BasePathInfo = [System.IO.DirectoryInfo]::new($BasePathResolved)
    $AbsolutePathInfo = [System.IO.FileInfo]::new($AbsolutePath)

    # Obtenir le chemin relatif
    $Uri1 = [System.Uri]::new($BasePathInfo.FullName + [System.IO.Path]::DirectorySeparatorChar)
    $Uri2 = [System.Uri]::new($AbsolutePathInfo.FullName)
    $RelativePath = $Uri1.MakeRelativeUri($Uri2).ToString().Replace('/', [System.IO.Path]::DirectorySeparatorChar)

    return $RelativePath
}

<#
.SYNOPSIS
    Ajoute un nouveau mapping de chemin au gestionnaire de chemins.
.DESCRIPTION
    Cette fonction ajoute un nouveau mapping de chemin au gestionnaire de chemins.
.PARAMETER Name
    Le nom du mapping de chemin.
.PARAMETER Path
    Le chemin Ã  mapper. Peut Ãªtre un chemin absolu ou relatif au rÃ©pertoire racine du projet.
.EXAMPLE
    Add-PathMapping -Name "custom-scripts" -Path "scripts\custom"
.EXAMPLE
    Add-PathMapping -Name "external-lib" -Path "D:\Libraries\ExternalLib"
#>
function Add-PathMapping {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Path
    )

    # VÃ©rifier que le gestionnaire de chemins est initialisÃ©
    if ($null -eq $script:ProjectRoot) {
        Initialize-PathManager
    }

    # Si le chemin est relatif, le convertir en chemin absolu
    if (-not [System.IO.Path]::IsPathRooted($Path)) {
        $Path = Join-Path -Path $script:ProjectRoot -ChildPath $Path
    }

    # Ajouter le mapping de chemin
    $script:PathMappings[$Name] = $Path

    Write-Verbose "Mapping de chemin ajoutÃ©: $Name -> $Path"
}

<#
.SYNOPSIS
    Obtient tous les mappings de chemins dÃ©finis dans le gestionnaire de chemins.
.DESCRIPTION
    Cette fonction retourne tous les mappings de chemins dÃ©finis dans le gestionnaire de chemins.
.EXAMPLE
    Get-PathMappings
#>
function Get-PathMappings {
    [CmdletBinding()]
    param ()

    # VÃ©rifier que le gestionnaire de chemins est initialisÃ©
    if ($null -eq $script:ProjectRoot) {
        Initialize-PathManager
    }

    return $script:PathMappings
}

<#
.SYNOPSIS
    VÃ©rifie si un chemin est relatif au rÃ©pertoire racine du projet.
.DESCRIPTION
    Cette fonction vÃ©rifie si un chemin est relatif au rÃ©pertoire racine du projet.
.PARAMETER Path
    Le chemin Ã  vÃ©rifier.
.EXAMPLE
    Test-RelativePath -Path "scripts\utils\path-utils.ps1"
.EXAMPLE
    Test-RelativePath -Path "D:\DO\WEB\N8N_tests\scripts_ json_a_ tester\EMAIL_SENDER_1\scripts\utils\path-utils.ps1"
#>
function Test-RelativePath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path
    )

    # VÃ©rifier que le gestionnaire de chemins est initialisÃ©
    if ($null -eq $script:ProjectRoot) {
        Initialize-PathManager
    }

    # VÃ©rifier si le chemin est relatif
    return -not [System.IO.Path]::IsPathRooted($Path)
}

<#
.SYNOPSIS
    Normalise un chemin en fonction du systÃ¨me d'exploitation.
.DESCRIPTION
    Cette fonction normalise un chemin en fonction du systÃ¨me d'exploitation.
.PARAMETER Path
    Le chemin Ã  normaliser.
.PARAMETER ForceWindowsStyle
    Si spÃ©cifiÃ©, force l'utilisation du style Windows (backslashes).
.PARAMETER ForceUnixStyle
    Si spÃ©cifiÃ©, force l'utilisation du style Unix (forward slashes).
.EXAMPLE
    Normalize-Path -Path "scripts\utils\path-utils.ps1"
.EXAMPLE
    Normalize-Path -Path "scripts/utils/path-utils.ps1" -ForceWindowsStyle
#>
function Normalize-Path {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$ForceWindowsStyle,

        [Parameter(Mandatory = $false)]
        [switch]$ForceUnixStyle
    )

    # Normaliser le chemin en fonction du systÃ¨me d'exploitation
    if ($ForceWindowsStyle) {
        $NormalizedPath = $Path -replace '/', '\'
    }
    elseif ($ForceUnixStyle) {
        $NormalizedPath = $Path -replace '\\', '/'
    }
    else {
        # Utiliser le sÃ©parateur de chemin du systÃ¨me d'exploitation
        $NormalizedPath = $Path -replace '[/\\]', [System.IO.Path]::DirectorySeparatorChar
    }

    # Supprimer les sÃ©parateurs de chemin consÃ©cutifs
    $NormalizedPath = $NormalizedPath -replace '\\{2,}', '\' -replace '/{2,}', '/'

    return $NormalizedPath
}

# Exporter les fonctions du module
Export-ModuleMember -Function Initialize-PathManager, Get-ProjectPath, Get-RelativePath, Add-PathMapping, Get-PathMappings, Test-RelativePath, Normalize-Path
