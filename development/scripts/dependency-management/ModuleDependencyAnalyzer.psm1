#Requires -Version 5.1
<#
.SYNOPSIS
    Module pour l'analyse rÃ©cursive des dÃ©pendances de modules PowerShell.

.DESCRIPTION
    Ce module fournit des fonctions pour analyser les dÃ©pendances entre modules PowerShell,
    dÃ©tecter les dÃ©pendances via les manifestes (.psd1) et l'analyse du code,
    Ã©viter les boucles infinies dans la rÃ©solution, et visualiser le graphe de dÃ©pendances.

.NOTES
    Auteur: Dependency Management Team
    Version: 1.1
    Date de crÃ©ation: 2023-06-15
    Date de mise Ã  jour: 2023-07-20
#>

# Variables globales pour le module
$script:VisitedModules = @{}
$script:DependencyGraph = @{}
$script:MaxRecursionDepth = 10
$script:CurrentRecursionDepth = 0

<#
.SYNOPSIS
    Analyse rÃ©cursivement les dÃ©pendances d'un module PowerShell.

.DESCRIPTION
    Cette fonction analyse rÃ©cursivement les dÃ©pendances d'un module PowerShell
    en parcourant les manifestes (.psd1) et le code source des modules.

.PARAMETER ModulePath
    Chemin du module Ã  analyser. Peut Ãªtre un chemin vers un fichier .psm1, .psd1 ou un rÃ©pertoire contenant un module.

.PARAMETER MaxDepth
    Profondeur maximale de rÃ©cursion pour l'analyse des dÃ©pendances. Par dÃ©faut: 10.

.PARAMETER IncludeNestedDependencies
    Indique si les dÃ©pendances imbriquÃ©es doivent Ãªtre incluses dans l'analyse.

.PARAMETER SkipSystemModules
    Indique si les modules systÃ¨me doivent Ãªtre exclus de l'analyse.

.PARAMETER OutputFormat
    Format de sortie des rÃ©sultats. Valeurs possibles: Object, HashTable, Graph. Par dÃ©faut: Object.

.EXAMPLE
    $dependencies = Get-ModuleDependenciesRecursive -ModulePath C:\Modules\MyModule\MyModule.psd1
    Analyse rÃ©cursivement les dÃ©pendances du module MyModule.

.EXAMPLE
    $dependencies = Get-ModuleDependenciesRecursive -ModulePath C:\Modules\MyModule -MaxDepth 5 -IncludeNestedDependencies
    Analyse rÃ©cursivement les dÃ©pendances du module MyModule avec une profondeur maximale de 5 et inclut les dÃ©pendances imbriquÃ©es.

.OUTPUTS
    [PSCustomObject] ou [HashTable] selon le paramÃ¨tre OutputFormat.
#>
function Get-ModuleDependenciesRecursive {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$ModulePath,

        [Parameter(Mandatory = $false)]
        [int]$MaxDepth = 10,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeNestedDependencies,

        [Parameter(Mandatory = $false)]
        [switch]$SkipSystemModules,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Object', 'HashTable', 'Graph')]
        [string]$OutputFormat = 'Object'
    )

    begin {
        # Initialiser les variables globales
        $script:VisitedModules = @{}
        $script:DependencyGraph = @{}
        $script:MaxRecursionDepth = $MaxDepth
        $script:CurrentRecursionDepth = 0

        # Fonction interne pour normaliser le chemin du module
        function Get-NormalizedModulePath {
            param (
                [Parameter(Mandatory = $true)]
                [string]$Path
            )

            # VÃ©rifier si le chemin existe
            if (-not (Test-Path -Path $Path)) {
                Write-Warning "Le chemin spÃ©cifiÃ© n'existe pas: $Path"
                return $null
            }

            # Obtenir le chemin complet
            $fullPath = Resolve-Path -Path $Path

            # Si c'est un rÃ©pertoire, chercher le fichier .psd1 ou .psm1
            if (Test-Path -Path $fullPath -PathType Container) {
                $psd1Files = Get-ChildItem -Path $fullPath -Filter "*.psd1" -File
                if ($psd1Files.Count -gt 0) {
                    return $psd1Files[0].FullName
                }

                $psm1Files = Get-ChildItem -Path $fullPath -Filter "*.psm1" -File
                if ($psm1Files.Count -gt 0) {
                    return $psm1Files[0].FullName
                }

                Write-Warning "Aucun fichier .psd1 ou .psm1 trouvÃ© dans le rÃ©pertoire: $fullPath"
                return $null
            }

            # Si c'est un fichier, vÃ©rifier l'extension
            $extension = [System.IO.Path]::GetExtension($fullPath)
            if ($extension -notin ".psd1", ".psm1") {
                Write-Warning "Le fichier spÃ©cifiÃ© n'est pas un fichier .psd1 ou .psm1: $fullPath"
                return $null
            }

            return $fullPath
        }
    }

    process {
        # Normaliser le chemin du module
        $normalizedPath = Get-NormalizedModulePath -Path $ModulePath
        if (-not $normalizedPath) {
            Write-Error "Impossible de rÃ©soudre le chemin du module: $ModulePath"
            return $null
        }

        # Analyser les dÃ©pendances rÃ©cursivement
        $dependencies = Invoke-RecursiveDependencyAnalysis -ModulePath $normalizedPath -Depth 0 -IncludeNestedDependencies:$IncludeNestedDependencies -SkipSystemModules:$SkipSystemModules

        # Formater la sortie selon le paramÃ¨tre OutputFormat
        switch ($OutputFormat) {
            "Object" {
                return [PSCustomObject]@{
                    ModulePath      = $normalizedPath
                    ModuleName      = [System.IO.Path]::GetFileNameWithoutExtension($normalizedPath)
                    Dependencies    = $dependencies
                    DependencyGraph = $script:DependencyGraph
                    VisitedModules  = $script:VisitedModules.Keys
                }
            }
            "HashTable" {
                return @{
                    ModulePath      = $normalizedPath
                    ModuleName      = [System.IO.Path]::GetFileNameWithoutExtension($normalizedPath)
                    Dependencies    = $dependencies
                    DependencyGraph = $script:DependencyGraph
                    VisitedModules  = $script:VisitedModules.Keys
                }
            }
            "Graph" {
                return $script:DependencyGraph
            }
        }
    }
}

<#
.SYNOPSIS
    Fonction interne pour l'analyse rÃ©cursive des dÃ©pendances.

.DESCRIPTION
    Cette fonction interne est utilisÃ©e par Get-ModuleDependenciesRecursive pour
    analyser rÃ©cursivement les dÃ©pendances d'un module PowerShell.

.PARAMETER ModulePath
    Chemin du module Ã  analyser.

.PARAMETER Depth
    Profondeur actuelle de rÃ©cursion.

.PARAMETER IncludeNestedDependencies
    Indique si les dÃ©pendances imbriquÃ©es doivent Ãªtre incluses dans l'analyse.

.PARAMETER SkipSystemModules
    Indique si les modules systÃ¨me doivent Ãªtre exclus de l'analyse.

.OUTPUTS
    [System.Collections.ArrayList] Liste des dÃ©pendances du module.
#>
function Invoke-RecursiveDependencyAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModulePath,

        [Parameter(Mandatory = $true)]
        [int]$Depth,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeNestedDependencies,

        [Parameter(Mandatory = $false)]
        [switch]$SkipSystemModules
    )

    # VÃ©rifier si le module a dÃ©jÃ  Ã©tÃ© visitÃ©
    if ($script:VisitedModules.ContainsKey($ModulePath)) {
        Write-Verbose "Module dÃ©jÃ  visitÃ©: $ModulePath"
        return @()
    }

    # VÃ©rifier la profondeur maximale de rÃ©cursion
    if ($Depth -gt $script:MaxRecursionDepth) {
        Write-Verbose "Profondeur maximale de rÃ©cursion atteinte: $Depth > $script:MaxRecursionDepth"
        return @()
    }

    # Marquer le module comme visitÃ©
    $script:VisitedModules[$ModulePath] = $true

    # Initialiser la liste des dÃ©pendances
    $dependencies = [System.Collections.ArrayList]::new()

    # Obtenir le nom du module
    $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($ModulePath)

    # Initialiser le graphe de dÃ©pendances pour ce module
    if (-not $script:DependencyGraph.ContainsKey($moduleName)) {
        $script:DependencyGraph[$moduleName] = @()
    }

    # Analyser les dÃ©pendances du module
    $moduleDependencies = @()

    # DÃ©terminer le type de fichier
    $extension = [System.IO.Path]::GetExtension($ModulePath)
    if ($extension -eq ".psd1") {
        # Analyser le manifeste du module
        Write-Verbose "Analyse du manifeste du module: $ModulePath"
        $moduleDependencies = Get-ModuleDependenciesFromManifest -ManifestPath $ModulePath -SkipSystemModules:$SkipSystemModules -ResolveModulePaths
    } elseif ($extension -eq ".psm1") {
        # Analyser le code du module
        Write-Verbose "Analyse du code du module: $ModulePath"
        $moduleDependencies = Get-ModuleDependenciesFromCode -ModulePath $ModulePath -SkipSystemModules:$SkipSystemModules -ResolveModulePaths -IncludeScriptDependencies
    }

    # Ajouter les dÃ©pendances Ã  la liste
    foreach ($dependency in $moduleDependencies) {
        # Ajouter la dÃ©pendance au graphe
        if (-not ($script:DependencyGraph[$moduleName] -contains $dependency.Name)) {
            $script:DependencyGraph[$moduleName] += $dependency.Name
        }

        # Ajouter la dÃ©pendance Ã  la liste
        [void]$dependencies.Add($dependency)

        # Analyser rÃ©cursivement les dÃ©pendances imbriquÃ©es
        if ($IncludeNestedDependencies -and $dependency.Path) {
            $nestedDependencies = Invoke-RecursiveDependencyAnalysis -ModulePath $dependency.Path -Depth ($Depth + 1) -IncludeNestedDependencies:$IncludeNestedDependencies -SkipSystemModules:$SkipSystemModules

            # Ajouter les dÃ©pendances imbriquÃ©es Ã  la liste
            foreach ($nestedDependency in $nestedDependencies) {
                [void]$dependencies.Add($nestedDependency)
            }
        }
    }

    return $dependencies
}

<#
.SYNOPSIS
    Analyse les dÃ©pendances d'un module PowerShell Ã  partir de son manifeste (.psd1).

.DESCRIPTION
    Cette fonction analyse le manifeste d'un module PowerShell (.psd1) pour
    extraire ses dÃ©pendances (RequiredModules, NestedModules, etc.).

.PARAMETER ManifestPath
    Chemin du fichier manifeste (.psd1) Ã  analyser.

.PARAMETER SkipSystemModules
    Indique si les modules systÃ¨me doivent Ãªtre exclus de l'analyse.

.PARAMETER ResolveModulePaths
    Indique si les chemins des modules dÃ©pendants doivent Ãªtre rÃ©solus.

.EXAMPLE
    $dependencies = Get-ModuleDependenciesFromManifest -ManifestPath C:\Modules\MyModule\MyModule.psd1
    Analyse les dÃ©pendances du module MyModule Ã  partir de son manifeste.

.OUTPUTS
    [System.Collections.ArrayList] Liste des dÃ©pendances du module.
#>
function Get-ModuleDependenciesFromManifest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ManifestPath,

        [Parameter(Mandatory = $false)]
        [switch]$SkipSystemModules,

        [Parameter(Mandatory = $false)]
        [switch]$ResolveModulePaths
    )

    # Initialiser la liste des dÃ©pendances
    $dependencies = [System.Collections.ArrayList]::new()

    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $ManifestPath -PathType Leaf)) {
        Write-Warning "Le fichier manifeste n'existe pas: $ManifestPath"
        return $dependencies
    }

    # VÃ©rifier l'extension du fichier
    $extension = [System.IO.Path]::GetExtension($ManifestPath)
    if ($extension -ne ".psd1") {
        Write-Warning "Le fichier spÃ©cifiÃ© n'est pas un fichier .psd1: $ManifestPath"
        return $dependencies
    }

    try {
        # Importer le manifeste
        $manifest = Import-PowerShellDataFile -Path $ManifestPath -ErrorAction Stop

        # Extraire les dÃ©pendances RequiredModules
        if ($manifest.ContainsKey('RequiredModules') -and $manifest.RequiredModules) {
            Write-Verbose "Analyse des RequiredModules dans le manifeste: $ManifestPath"

            # RequiredModules peut Ãªtre une chaÃ®ne, un tableau de chaÃ®nes, ou un tableau d'objets
            $requiredModules = $manifest.RequiredModules

            # Si RequiredModules est une chaÃ®ne unique, la convertir en tableau
            if ($requiredModules -is [string]) {
                $requiredModules = @($requiredModules)
            }

            foreach ($requiredModule in $requiredModules) {
                $moduleName = $null
                $moduleVersion = $null
                $moduleGuid = $null
                $modulePath = $null
                $moduleMaxVersion = $null
                $moduleMinVersion = $null

                # DÃ©terminer le format du module requis
                if ($requiredModule -is [string]) {
                    # Format simple: 'ModuleName'
                    $moduleName = $requiredModule
                } elseif ($requiredModule -is [hashtable] -or $requiredModule -is [System.Collections.Specialized.OrderedDictionary]) {
                    # Format complexe: @{ModuleName='Name'; ModuleVersion='1.0.0'}
                    if ($requiredModule.ContainsKey('ModuleName')) {
                        $moduleName = $requiredModule.ModuleName
                    }

                    # GÃ©rer les diffÃ©rentes faÃ§ons de spÃ©cifier la version
                    if ($requiredModule.ContainsKey('ModuleVersion')) {
                        $moduleVersion = $requiredModule.ModuleVersion
                    }
                    if ($requiredModule.ContainsKey('RequiredVersion')) {
                        $moduleVersion = $requiredModule.RequiredVersion
                    }
                    if ($requiredModule.ContainsKey('MaximumVersion')) {
                        $moduleMaxVersion = $requiredModule.MaximumVersion
                    }
                    if ($requiredModule.ContainsKey('MinimumVersion')) {
                        $moduleMinVersion = $requiredModule.MinimumVersion
                    }

                    # GÃ©rer le GUID du module
                    if ($requiredModule.ContainsKey('GUID')) {
                        $moduleGuid = $requiredModule.GUID
                    }
                } elseif ($requiredModule -is [System.Management.Automation.PSModuleInfo]) {
                    # Format objet: [PSModuleInfo]
                    $moduleName = $requiredModule.Name
                    $moduleVersion = $requiredModule.Version
                    $moduleGuid = $requiredModule.Guid
                    $modulePath = $requiredModule.Path
                } elseif ($requiredModule -is [array]) {
                    # Format tableau: @('ModuleName', 'Version')
                    if ($requiredModule.Length -ge 1) {
                        $moduleName = $requiredModule[0]
                        if ($requiredModule.Length -ge 2) {
                            $moduleVersion = $requiredModule[1]
                        }
                    }
                }

                # Ignorer les modules systÃ¨me si demandÃ©
                if ($SkipSystemModules -and (Test-SystemModule -ModuleName $moduleName)) {
                    Write-Verbose "Module systÃ¨me ignorÃ©: $moduleName"
                    continue
                }

                # RÃ©soudre le chemin du module si demandÃ©
                if ($ResolveModulePaths -and -not $modulePath) {
                    $modulePath = Find-ModulePath -ModuleName $moduleName -ModuleVersion $moduleVersion
                }

                # Ajouter la dÃ©pendance Ã  la liste
                [void]$dependencies.Add([PSCustomObject]@{
                        Name       = $moduleName
                        Version    = $moduleVersion
                        MinVersion = $moduleMinVersion
                        MaxVersion = $moduleMaxVersion
                        GUID       = $moduleGuid
                        Path       = $modulePath
                        Type       = "RequiredModule"
                        Source     = $ManifestPath
                    })
            }
        }

        # Extraire les dÃ©pendances NestedModules
        if ($manifest.ContainsKey('NestedModules') -and $manifest.NestedModules) {
            Write-Verbose "Analyse des NestedModules dans le manifeste: $ManifestPath"

            # NestedModules peut Ãªtre une chaÃ®ne, un tableau de chaÃ®nes, ou un tableau d'objets
            $nestedModules = $manifest.NestedModules

            # Si NestedModules est une chaÃ®ne unique, la convertir en tableau
            if ($nestedModules -is [string]) {
                $nestedModules = @($nestedModules)
            }

            foreach ($nestedModule in $nestedModules) {
                $moduleName = $null
                $moduleVersion = $null
                $moduleGuid = $null
                $modulePath = $null
                $moduleMaxVersion = $null
                $moduleMinVersion = $null

                # DÃ©terminer le format du module imbriquÃ©
                if ($nestedModule -is [string]) {
                    # Format simple: 'ModuleName' ou 'Path\To\Module.psm1'
                    if ($nestedModule -match '\.ps[md]1$') {
                        # C'est un chemin vers un fichier .psm1 ou .psd1
                        $modulePath = $nestedModule
                        $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($nestedModule)

                        # Si le chemin est relatif, le rÃ©soudre par rapport au rÃ©pertoire du manifeste
                        if (-not [System.IO.Path]::IsPathRooted($modulePath)) {
                            $manifestDir = [System.IO.Path]::GetDirectoryName($ManifestPath)
                            $modulePath = Join-Path -Path $manifestDir -ChildPath $modulePath
                        }
                    } else {
                        # C'est un nom de module
                        $moduleName = $nestedModule
                    }
                } elseif ($nestedModule -is [hashtable] -or $nestedModule -is [System.Collections.Specialized.OrderedDictionary]) {
                    # Format complexe: @{ModuleName='Name'; ModuleVersion='1.0.0'}
                    if ($nestedModule.ContainsKey('ModuleName')) {
                        $moduleName = $nestedModule.ModuleName
                    }

                    # GÃ©rer les diffÃ©rentes faÃ§ons de spÃ©cifier la version
                    if ($nestedModule.ContainsKey('ModuleVersion')) {
                        $moduleVersion = $nestedModule.ModuleVersion
                    }
                    if ($nestedModule.ContainsKey('RequiredVersion')) {
                        $moduleVersion = $nestedModule.RequiredVersion
                    }
                    if ($nestedModule.ContainsKey('MaximumVersion')) {
                        $moduleMaxVersion = $nestedModule.MaximumVersion
                    }
                    if ($nestedModule.ContainsKey('MinimumVersion')) {
                        $moduleMinVersion = $nestedModule.MinimumVersion
                    }

                    # GÃ©rer le GUID du module
                    if ($nestedModule.ContainsKey('GUID')) {
                        $moduleGuid = $nestedModule.GUID
                    }

                    # GÃ©rer le chemin du module
                    if ($nestedModule.ContainsKey('Path')) {
                        $modulePath = $nestedModule.Path

                        # Si le chemin est relatif, le rÃ©soudre par rapport au rÃ©pertoire du manifeste
                        if (-not [System.IO.Path]::IsPathRooted($modulePath)) {
                            $manifestDir = [System.IO.Path]::GetDirectoryName($ManifestPath)
                            $modulePath = Join-Path -Path $manifestDir -ChildPath $modulePath
                        }
                    }
                } elseif ($nestedModule -is [System.Management.Automation.PSModuleInfo]) {
                    # Format objet: [PSModuleInfo]
                    $moduleName = $nestedModule.Name
                    $moduleVersion = $nestedModule.Version
                    $moduleGuid = $nestedModule.Guid
                    $modulePath = $nestedModule.Path
                } elseif ($nestedModule -is [array]) {
                    # Format tableau: @('ModuleName', 'Version')
                    if ($nestedModule.Length -ge 1) {
                        $moduleName = $nestedModule[0]
                        if ($nestedModule.Length -ge 2) {
                            $moduleVersion = $nestedModule[1]
                        }
                    }
                }

                # Ignorer les modules systÃ¨me si demandÃ©
                if ($SkipSystemModules -and (Test-SystemModule -ModuleName $moduleName)) {
                    Write-Verbose "Module systÃ¨me ignorÃ©: $moduleName"
                    continue
                }

                # RÃ©soudre le chemin du module si demandÃ©
                if ($ResolveModulePaths -and -not $modulePath) {
                    $modulePath = Find-ModulePath -ModuleName $moduleName -ModuleVersion $moduleVersion
                }

                # Ajouter la dÃ©pendance Ã  la liste
                [void]$dependencies.Add([PSCustomObject]@{
                        Name       = $moduleName
                        Version    = $moduleVersion
                        MinVersion = $moduleMinVersion
                        MaxVersion = $moduleMaxVersion
                        GUID       = $moduleGuid
                        Path       = $modulePath
                        Type       = "NestedModule"
                        Source     = $ManifestPath
                    })
            }
        }

        # Extraire les dÃ©pendances ModuleToProcess (alias RootModule)
        if (($manifest.ContainsKey('ModuleToProcess') -and $manifest.ModuleToProcess) -or
            ($manifest.ContainsKey('RootModule') -and $manifest.RootModule)) {

            $rootModule = if ($manifest.ContainsKey('ModuleToProcess') -and $manifest.ModuleToProcess) {
                $manifest.ModuleToProcess
            } else {
                $manifest.RootModule
            }
            Write-Verbose "Analyse du RootModule dans le manifeste: $ManifestPath"

            # DÃ©terminer le type de RootModule
            if ($rootModule -is [string]) {
                $moduleName = $null
                $modulePath = $null

                # VÃ©rifier si le RootModule est un chemin vers un fichier .psm1 ou .psd1
                if ($rootModule -match '\.ps[md]1$') {
                    $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($rootModule)
                    $modulePath = $rootModule

                    # Si le chemin est relatif, le rÃ©soudre par rapport au rÃ©pertoire du manifeste
                    if (-not [System.IO.Path]::IsPathRooted($modulePath)) {
                        $manifestDir = [System.IO.Path]::GetDirectoryName($ManifestPath)
                        $modulePath = Join-Path -Path $manifestDir -ChildPath $modulePath
                    }
                } else {
                    # C'est un nom de module
                    $moduleName = $rootModule

                    # RÃ©soudre le chemin du module si demandÃ©
                    if ($ResolveModulePaths) {
                        $modulePath = Find-ModulePath -ModuleName $moduleName
                    }
                }

                # Ignorer les modules systÃ¨me si demandÃ©
                if ($SkipSystemModules -and (Test-SystemModule -ModuleName $moduleName)) {
                    Write-Verbose "Module systÃ¨me ignorÃ©: $moduleName"
                } else {
                    # Ajouter la dÃ©pendance Ã  la liste
                    [void]$dependencies.Add([PSCustomObject]@{
                            Name    = $moduleName
                            Version = $null
                            Path    = $modulePath
                            Type    = "RootModule"
                            Source  = $ManifestPath
                        })
                }
            } elseif ($rootModule -is [hashtable] -or $rootModule -is [System.Collections.Specialized.OrderedDictionary]) {
                # Format complexe: @{ModuleName='Name'; ModuleVersion='1.0.0'}
                $moduleName = $null
                $moduleVersion = $null
                $moduleGuid = $null
                $modulePath = $null

                if ($rootModule.ContainsKey('ModuleName')) {
                    $moduleName = $rootModule.ModuleName
                }

                # GÃ©rer les diffÃ©rentes faÃ§ons de spÃ©cifier la version
                if ($rootModule.ContainsKey('ModuleVersion')) {
                    $moduleVersion = $rootModule.ModuleVersion
                }
                if ($rootModule.ContainsKey('RequiredVersion')) {
                    $moduleVersion = $rootModule.RequiredVersion
                }

                # GÃ©rer le GUID du module
                if ($rootModule.ContainsKey('GUID')) {
                    $moduleGuid = $rootModule.GUID
                }

                # GÃ©rer le chemin du module
                if ($rootModule.ContainsKey('Path')) {
                    $modulePath = $rootModule.Path

                    # Si le chemin est relatif, le rÃ©soudre par rapport au rÃ©pertoire du manifeste
                    if (-not [System.IO.Path]::IsPathRooted($modulePath)) {
                        $manifestDir = [System.IO.Path]::GetDirectoryName($ManifestPath)
                        $modulePath = Join-Path -Path $manifestDir -ChildPath $modulePath
                    }
                } elseif ($ResolveModulePaths) {
                    $modulePath = Find-ModulePath -ModuleName $moduleName -ModuleVersion $moduleVersion
                }

                # Ignorer les modules systÃ¨me si demandÃ©
                if ($SkipSystemModules -and (Test-SystemModule -ModuleName $moduleName)) {
                    Write-Verbose "Module systÃ¨me ignorÃ©: $moduleName"
                } else {
                    # Ajouter la dÃ©pendance Ã  la liste
                    [void]$dependencies.Add([PSCustomObject]@{
                            Name    = $moduleName
                            Version = $moduleVersion
                            GUID    = $moduleGuid
                            Path    = $modulePath
                            Type    = "RootModule"
                            Source  = $ManifestPath
                        })
                }
            }
        }

        return $dependencies
    } catch {
        Write-Error "Erreur lors de l'analyse du manifeste $ManifestPath : $_"
        return $dependencies
    }
}

<#
.SYNOPSIS
    VÃ©rifie si un module est un module systÃ¨me.

.DESCRIPTION
    Cette fonction vÃ©rifie si un module est un module systÃ¨me PowerShell.

.PARAMETER ModuleName
    Nom du module Ã  vÃ©rifier.

.OUTPUTS
    [bool] True si le module est un module systÃ¨me, False sinon.
#>
function Test-SystemModule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,

        [Parameter(Mandatory = $false)]
        [string[]]$AdditionalSystemModules = @()
    )

    # Liste des modules systÃ¨me PowerShell
    $systemModules = @(
        # Modules de base PowerShell
        'Microsoft.PowerShell.Archive',
        'Microsoft.PowerShell.Core',
        'Microsoft.PowerShell.Diagnostics',
        'Microsoft.PowerShell.Host',
        'Microsoft.PowerShell.Management',
        'Microsoft.PowerShell.Security',
        'Microsoft.PowerShell.Utility',
        'Microsoft.WSMan.Management',
        'PSDesiredStateConfiguration',
        'PSScheduledJob',
        'PSWorkflow',
        'PSWorkflowUtility',
        'CimCmdlets',
        'ISE',
        'PSReadLine',

        # Modules d'administration Windows
        'ActiveDirectory',
        'GroupPolicy',
        'ServerManager',
        'DnsClient',
        'NetAdapter',
        'NetConnection',
        'NetSecurity',
        'NetTCPIP',

        # Modules de gestion Azure
        'Az',
        'Az.Accounts',
        'Az.Compute',
        'Az.Resources',
        'Az.Storage',
        'AzureRM',

        # Modules de gestion AWS
        'AWS.Tools.Common',
        'AWSPowerShell',

        # Modules de dÃ©veloppement
        'Pester',
        'PSScriptAnalyzer',

        # Modules d'automatisation
        'ThreadJob',
        'PSWorkflow',
        'PSScheduledJob',

        # Modules de sÃ©curitÃ©
        'PKI',
        'CertificateDsc'
    )

    # Ajouter les modules supplÃ©mentaires Ã  la liste
    if ($AdditionalSystemModules) {
        $systemModules += $AdditionalSystemModules
    }

    # VÃ©rifier si le module est un module systÃ¨me
    $isSystemModule = $systemModules -contains $ModuleName

    # VÃ©rifier si le module est installÃ© dans un rÃ©pertoire systÃ¨me
    if (-not $isSystemModule) {
        $module = Get-Module -Name $ModuleName -ListAvailable -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($module) {
            $modulePath = $module.Path
            $isSystemPath = $modulePath -like "$env:SystemRoot\*" -or
            $modulePath -like "$env:ProgramFiles\*" -or
            $modulePath -like "$env:windir\*" -or
            $modulePath -like "$($env:ProgramFiles)\WindowsPowerShell\Modules\*" -or
            $modulePath -like "$($env:ProgramFiles)\PowerShell\*"

            $isSystemModule = $isSystemModule -or $isSystemPath
        }
    }

    return $isSystemModule
}

<#
.SYNOPSIS
    Recherche le chemin d'un module PowerShell.

.DESCRIPTION
    Cette fonction recherche le chemin d'un module PowerShell en fonction de son nom et de sa version.

.PARAMETER ModuleName
    Nom du module Ã  rechercher.

.PARAMETER ModuleVersion
    Version du module Ã  rechercher. Si non spÃ©cifiÃ©, la derniÃ¨re version disponible est utilisÃ©e.

.OUTPUTS
    [string] Chemin du module, ou $null si le module n'est pas trouvÃ©.
#>
function Find-ModulePath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,

        [Parameter(Mandatory = $false)]
        [string]$ModuleVersion,

        [Parameter(Mandatory = $false)]
        [string]$MinimumVersion,

        [Parameter(Mandatory = $false)]
        [string]$MaximumVersion,

        [Parameter(Mandatory = $false)]
        [string]$GUID,

        [Parameter(Mandatory = $false)]
        [string[]]$AdditionalPaths = @(),

        [Parameter(Mandatory = $false)]
        [switch]$AllVersions
    )

    # Rechercher le module
    $moduleParams = @{
        Name        = $ModuleName
        ErrorAction = 'SilentlyContinue'
    }

    # GÃ©rer les contraintes de version
    if ($ModuleVersion) {
        $moduleParams['RequiredVersion'] = $ModuleVersion
    } else {
        if ($MinimumVersion) {
            $moduleParams['MinimumVersion'] = $MinimumVersion
        }
        if ($MaximumVersion) {
            $moduleParams['MaximumVersion'] = $MaximumVersion
        }
    }

    # Rechercher le module dans les chemins standard
    $modules = Get-Module -ListAvailable @moduleParams

    # Filtrer par GUID si spÃ©cifiÃ©
    if ($GUID) {
        $modules = $modules | Where-Object { $_.Guid -eq $GUID }
    }

    # Rechercher le module dans les chemins supplÃ©mentaires
    if ($AdditionalPaths) {
        foreach ($path in $AdditionalPaths) {
            if (Test-Path -Path $path -PathType Container) {
                # Rechercher les fichiers .psd1 dans le chemin
                $psd1Files = Get-ChildItem -Path $path -Filter "*.psd1" -Recurse -File
                foreach ($psd1File in $psd1Files) {
                    try {
                        $manifest = Import-PowerShellDataFile -Path $psd1File.FullName -ErrorAction SilentlyContinue
                        if ($manifest -and $manifest.ContainsKey('ModuleName') -and $manifest.ModuleName -eq $ModuleName) {
                            # VÃ©rifier la version si spÃ©cifiÃ©e
                            $versionMatch = $true
                            if ($ModuleVersion -and $manifest.ContainsKey('ModuleVersion') -and $manifest.ModuleVersion -ne $ModuleVersion) {
                                $versionMatch = $false
                            }
                            if ($MinimumVersion -and $manifest.ContainsKey('ModuleVersion') -and [version]$manifest.ModuleVersion -lt [version]$MinimumVersion) {
                                $versionMatch = $false
                            }
                            if ($MaximumVersion -and $manifest.ContainsKey('ModuleVersion') -and [version]$manifest.ModuleVersion -gt [version]$MaximumVersion) {
                                $versionMatch = $false
                            }
                            if ($GUID -and $manifest.ContainsKey('GUID') -and $manifest.GUID -ne $GUID) {
                                $versionMatch = $false
                            }

                            if ($versionMatch) {
                                $moduleInfo = [PSCustomObject]@{
                                    Name    = $ModuleName
                                    Version = $manifest.ModuleVersion
                                    Path    = $psd1File.FullName
                                    GUID    = $manifest.GUID
                                }
                                $modules += $moduleInfo
                            }
                        }
                    } catch {
                        Write-Verbose "Erreur lors de l'analyse du fichier $($psd1File.FullName) : $_"
                    }
                }
            }
        }
    }

    # Retourner tous les modules ou seulement le premier
    if ($AllVersions) {
        if ($modules) {
            return $modules | ForEach-Object { $_.Path }
        }
    } else {
        if ($modules) {
            # Trier par version et prendre le plus rÃ©cent
            $module = $modules | Sort-Object -Property Version -Descending | Select-Object -First 1
            return $module.Path
        }
    }

    return $null
}

<#
.SYNOPSIS
    Analyse les dÃ©pendances d'un module PowerShell Ã  partir de son code source.

.DESCRIPTION
    Cette fonction analyse le code source d'un module PowerShell (.psm1) pour
    extraire ses dÃ©pendances (Import-Module, using module, etc.).

.PARAMETER ModulePath
    Chemin du fichier module (.psm1) Ã  analyser.

.PARAMETER SkipSystemModules
    Indique si les modules systÃ¨me doivent Ãªtre exclus de l'analyse.

.PARAMETER ResolveModulePaths
    Indique si les chemins des modules dÃ©pendants doivent Ãªtre rÃ©solus.

.PARAMETER IncludeScriptDependencies
    Indique si les dÃ©pendances de scripts (dot-sourcing) doivent Ãªtre incluses.

.EXAMPLE
    $dependencies = Get-ModuleDependenciesFromCode -ModulePath "C:\Modules\MyModule\MyModule.psm1"
    Analyse les dÃ©pendances du module MyModule Ã  partir de son code source.

.OUTPUTS
    [System.Collections.ArrayList] Liste des dÃ©pendances du module.
#>
function Get-ModuleDependenciesFromCode {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModulePath,

        [Parameter(Mandatory = $false)]
        [switch]$SkipSystemModules,

        [Parameter(Mandatory = $false)]
        [switch]$ResolveModulePaths,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeScriptDependencies
    )

    # Initialiser la liste des dÃ©pendances
    $dependencies = [System.Collections.ArrayList]::new()

    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $ModulePath -PathType Leaf)) {
        Write-Warning "Le fichier module n'existe pas: $ModulePath"
        return $dependencies
    }

    # VÃ©rifier l'extension du fichier
    $extension = [System.IO.Path]::GetExtension($ModulePath)
    if ($extension -ne ".psm1" -and $extension -ne ".ps1") {
        Write-Warning "Le fichier spÃ©cifiÃ© n'est pas un fichier .psm1 ou .ps1: $ModulePath"
        return $dependencies
    }

    try {
        # Charger le contenu du fichier
        $content = Get-Content -Path $ModulePath -Raw -ErrorAction Stop

        # Obtenir le rÃ©pertoire du module
        $moduleDir = [System.IO.Path]::GetDirectoryName($ModulePath)

        # Analyser les dÃ©pendances avec l'AST (Abstract Syntax Tree)
        if ($PSVersionTable.PSVersion.Major -ge 3) {
            # Utiliser l'AST pour une analyse plus prÃ©cise
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($ModulePath, [ref]$null, [ref]$null)

            # Analyser les dÃ©pendances avec l'AST
            $astDependencies = Get-AstDependencies -Ast $ast -ModulePath $ModulePath -SkipSystemModules:$SkipSystemModules -ResolveModulePaths:$ResolveModulePaths

            # Ajouter les dÃ©pendances AST Ã  la liste
            foreach ($dependency in $astDependencies) {
                [void]$dependencies.Add($dependency)
            }
        } else {
            # Utiliser des expressions rÃ©guliÃ¨res pour les versions antÃ©rieures de PowerShell
            # DÃ©tecter les Import-Module avec diffÃ©rents formats
            # Format 1: Import-Module ModuleName
            # Format 2: Import-Module -Name ModuleName
            # Format 3: Import-Module -Name "ModuleName"
            # Format 4: Import-Module -Name 'ModuleName'
            # Format 5: Import-Module -Path "C:\Path\To\Module.psd1"
            $importMatches = [regex]::Matches($content, '(?m)^\s*Import-Module\s+(?:-Name\s+)?([''"]?)([^''"\s,;]+)\1|^\s*Import-Module\s+-Name\s+([''"]?)([^''"\s,;]+)\3|^\s*Import-Module\s+-Path\s+([''"]?)([^''"\s,;]+)\5')
            foreach ($match in $importMatches) {
                # Extraire le nom du module en fonction du format dÃ©tectÃ©
                $moduleName = $null
                $isPath = $false

                if ($match.Groups[2].Success) {
                    # Format 1: Import-Module ModuleName ou Format 2: Import-Module -Name ModuleName
                    $moduleName = $match.Groups[2].Value
                } elseif ($match.Groups[4].Success) {
                    # Format 3/4: Import-Module -Name "ModuleName" ou Import-Module -Name 'ModuleName'
                    $moduleName = $match.Groups[4].Value
                } elseif ($match.Groups[6].Success) {
                    # Format 5: Import-Module -Path "C:\Path\To\Module.psd1"
                    $modulePath = $match.Groups[6].Value
                    $isPath = $true

                    # Extraire le nom du module Ã  partir du chemin
                    if ($modulePath -match '\.ps[md]1$') {
                        $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($modulePath)
                    } else {
                        $moduleName = [System.IO.Path]::GetFileName($modulePath)
                    }
                }

                # VÃ©rifier si un nom de module a Ã©tÃ© trouvÃ©
                if (-not $moduleName) {
                    continue
                }

                # Ignorer les modules systÃ¨me si demandÃ©
                if ($SkipSystemModules -and (Test-SystemModule -ModuleName $moduleName)) {
                    Write-Verbose "Module systÃ¨me ignorÃ©: $moduleName"
                    continue
                }

                # RÃ©soudre le chemin du module si demandÃ©
                if (-not $isPath) {
                    $modulePath = $null
                    if ($ResolveModulePaths) {
                        $modulePath = Find-ModulePath -ModuleName $moduleName
                    }
                } else {
                    # Si le chemin est relatif, le rÃ©soudre par rapport au rÃ©pertoire du module
                    if (-not [System.IO.Path]::IsPathRooted($modulePath)) {
                        $moduleDir = [System.IO.Path]::GetDirectoryName($ModulePath)
                        $modulePath = Join-Path -Path $moduleDir -ChildPath $modulePath
                    }
                }

                # Ajouter la dÃ©pendance Ã  la liste
                [void]$dependencies.Add([PSCustomObject]@{
                        Name    = $moduleName
                        Version = $null
                        Path    = $modulePath
                        Type    = "ImportModule"
                        Source  = $ModulePath
                    })
            }

            # DÃ©tecter les using module
            $usingMatches = [regex]::Matches($content, '(?m)^\s*using\s+module\s+([''"]?)([^''"\s]+)\1')
            foreach ($match in $usingMatches) {
                $moduleName = $match.Groups[2].Value

                # Ignorer les modules systÃ¨me si demandÃ©
                if ($SkipSystemModules -and (Test-SystemModule -ModuleName $moduleName)) {
                    Write-Verbose "Module systÃ¨me ignorÃ©: $moduleName"
                    continue
                }

                # RÃ©soudre le chemin du module si demandÃ©
                $modulePath = $null
                if ($ResolveModulePaths) {
                    $modulePath = Find-ModulePath -ModuleName $moduleName
                }

                # Ajouter la dÃ©pendance Ã  la liste
                [void]$dependencies.Add([PSCustomObject]@{
                        Name    = $moduleName
                        Version = $null
                        Path    = $modulePath
                        Type    = "UsingModule"
                        Source  = $ModulePath
                    })
            }
        }

        # DÃ©tecter les dÃ©pendances de scripts (dot-sourcing)
        if ($IncludeScriptDependencies) {
            $dotMatches = [regex]::Matches($content, '(?m)^\s*\.\s+([''"]?)([^''"\s]+)\1')
            foreach ($match in $dotMatches) {
                $scriptPath = $match.Groups[2].Value

                # RÃ©soudre le chemin du script
                $resolvedPath = $scriptPath
                if (-not [System.IO.Path]::IsPathRooted($scriptPath)) {
                    $resolvedPath = Join-Path -Path $moduleDir -ChildPath $scriptPath
                }

                # VÃ©rifier si le script existe
                if (Test-Path -Path $resolvedPath -PathType Leaf) {
                    # Ajouter la dÃ©pendance Ã  la liste
                    [void]$dependencies.Add([PSCustomObject]@{
                            Name    = [System.IO.Path]::GetFileNameWithoutExtension($scriptPath)
                            Version = $null
                            Path    = $resolvedPath
                            Type    = "DotSourced"
                            Source  = $ModulePath
                        })
                }
            }
        }

        return $dependencies
    } catch {
        Write-Error "Erreur lors de l'analyse du code du module $ModulePath : $_"
        return $dependencies
    }
}

<#
.SYNOPSIS
    Analyse les dÃ©pendances d'un module PowerShell Ã  partir de son AST.

.DESCRIPTION
    Cette fonction interne analyse l'AST (Abstract Syntax Tree) d'un module PowerShell
    pour extraire ses dÃ©pendances.

.PARAMETER Ast
    L'AST du module Ã  analyser.

.PARAMETER ModulePath
    Chemin du fichier module (.psm1) analysÃ©.

.PARAMETER SkipSystemModules
    Indique si les modules systÃ¨me doivent Ãªtre exclus de l'analyse.

.PARAMETER ResolveModulePaths
    Indique si les chemins des modules dÃ©pendants doivent Ãªtre rÃ©solus.

.OUTPUTS
    [System.Collections.ArrayList] Liste des dÃ©pendances du module.
#>
function Get-AstDependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.Ast]$Ast,

        [Parameter(Mandatory = $true)]
        [string]$ModulePath,

        [Parameter(Mandatory = $false)]
        [switch]$SkipSystemModules,

        [Parameter(Mandatory = $false)]
        [switch]$ResolveModulePaths
    )

    # Initialiser la liste des dÃ©pendances
    $dependencies = [System.Collections.ArrayList]::new()

    # Rechercher les commandes Import-Module
    $importModuleCmdlets = $Ast.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.CommandAst] -and
            $node.CommandElements.Count -ge 1 -and
            $node.CommandElements[0] -is [System.Management.Automation.Language.StringConstantExpressionAst] -and
            $node.CommandElements[0].Value -eq "Import-Module"
        }, $true)

    foreach ($cmdlet in $importModuleCmdlets) {
        # Extraire le nom du module
        $moduleName = $null

        # Rechercher le paramÃ¨tre Name ou le premier argument positionnel
        for ($i = 1; $i -lt $cmdlet.CommandElements.Count; $i++) {
            $element = $cmdlet.CommandElements[$i]

            # VÃ©rifier si c'est un paramÃ¨tre nommÃ©
            if ($element -is [System.Management.Automation.Language.CommandParameterAst] -and
                $element.ParameterName -eq "Name" -and
                $i + 1 -lt $cmdlet.CommandElements.Count) {

                $moduleNameElement = $cmdlet.CommandElements[$i + 1]
                if ($moduleNameElement -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
                    $moduleName = $moduleNameElement.Value
                    break
                }
            }
            # VÃ©rifier si c'est un argument positionnel
            elseif ($element -is [System.Management.Automation.Language.StringConstantExpressionAst] -and -not $moduleName) {
                $moduleName = $element.Value
                break
            }
        }

        if ($moduleName) {
            # Ignorer les modules systÃ¨me si demandÃ©
            if ($SkipSystemModules -and (Test-SystemModule -ModuleName $moduleName)) {
                Write-Verbose "Module systÃ¨me ignorÃ©: $moduleName"
                continue
            }

            # RÃ©soudre le chemin du module si demandÃ©
            $modulePath = $null
            if ($ResolveModulePaths) {
                $modulePath = Find-ModulePath -ModuleName $moduleName
            }

            # Ajouter la dÃ©pendance Ã  la liste
            [void]$dependencies.Add([PSCustomObject]@{
                    Name    = $moduleName
                    Version = $null
                    Path    = $modulePath
                    Type    = "ImportModule"
                    Source  = $ModulePath
                })
        }
    }

    # Rechercher les instructions using module
    $usingModuleStatements = $Ast.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.UsingStatementAst] -and
            $node.UsingStatementKind -eq [System.Management.Automation.Language.UsingStatementKind]::Module
        }, $true)

    foreach ($statement in $usingModuleStatements) {
        $moduleName = $statement.Name.Value

        # Ignorer les modules systÃ¨me si demandÃ©
        if ($SkipSystemModules -and (Test-SystemModule -ModuleName $moduleName)) {
            Write-Verbose "Module systÃ¨me ignorÃ©: $moduleName"
            continue
        }

        # RÃ©soudre le chemin du module si demandÃ©
        $modulePath = $null
        if ($ResolveModulePaths) {
            $modulePath = Find-ModulePath -ModuleName $moduleName
        }

        # Ajouter la dÃ©pendance Ã  la liste
        [void]$dependencies.Add([PSCustomObject]@{
                Name    = $moduleName
                Version = $null
                Path    = $modulePath
                Type    = "UsingModule"
                Source  = $ModulePath
            })
    }

    # Rechercher les directives #Requires -Modules
    $requiresAst = $Ast.ScriptRequirements
    if ($requiresAst -and $requiresAst.RequiredModules) {
        foreach ($requiredModule in $requiresAst.RequiredModules) {
            $moduleName = $requiredModule.Name

            # Ignorer les modules systÃ¨me si demandÃ©
            if ($SkipSystemModules -and (Test-SystemModule -ModuleName $moduleName)) {
                Write-Verbose "Module systÃ¨me ignorÃ©: $moduleName"
                continue
            }

            # RÃ©soudre le chemin du module si demandÃ©
            $modulePath = $null
            if ($ResolveModulePaths) {
                $modulePath = Find-ModulePath -ModuleName $moduleName
            }

            # Ajouter la dÃ©pendance Ã  la liste
            [void]$dependencies.Add([PSCustomObject]@{
                    Name    = $moduleName
                    Version = $requiredModule.Version
                    Path    = $modulePath
                    Type    = "RequiresModule"
                    Source  = $ModulePath
                })
        }
    }

    return $dependencies
}

<#
.SYNOPSIS
    DÃ©tecte les cycles de dÃ©pendances entre modules PowerShell.

.DESCRIPTION
    Cette fonction dÃ©tecte les cycles de dÃ©pendances entre modules PowerShell
    en utilisant l'algorithme de dÃ©tection de cycles de Tarjan.

.PARAMETER DependencyGraph
    Graphe de dÃ©pendances Ã  analyser. Doit Ãªtre un hashtable oÃ¹ les clÃ©s sont les noms des modules
    et les valeurs sont des tableaux contenant les noms des modules dÃ©pendants.

.PARAMETER IncludeAllCycles
    Indique si tous les cycles doivent Ãªtre inclus dans le rÃ©sultat, ou seulement le premier cycle dÃ©tectÃ©.

.EXAMPLE
    $graph = @{
        ModuleA = @(ModuleB, ModuleC)
        ModuleB = @(ModuleD)
        ModuleC = @(ModuleA)
        ModuleD = @()
    }
    $cycles = Find-ModuleDependencyCycles -DependencyGraph $graph
    DÃ©tecte les cycles de dÃ©pendances dans le graphe spÃ©cifiÃ©.

.OUTPUTS
    [PSCustomObject] RÃ©sultat de la dÃ©tection de cycles.
#>
function Find-ModuleDependencyCycles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$DependencyGraph,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeAllCycles
    )

    # Initialiser les variables
    $visited = @{}
    $recursionStack = @{}
    $cycles = [System.Collections.ArrayList]::new()

    # Fonction rÃ©cursive pour la dÃ©tection de cycles (DFS)
    function Find-CyclesDFS {
        param (
            [Parameter(Mandatory = $true)]
            [string]$Node,

            [Parameter(Mandatory = $false)]
            [System.Collections.ArrayList]$Path = $null
        )

        # Initialiser le chemin si nÃ©cessaire
        if ($null -eq $Path) {
            $Path = [System.Collections.ArrayList]::new()
        }

        # Marquer le nÅ“ud comme visitÃ© et l'ajouter Ã  la pile de rÃ©cursion
        $visited[$Node] = $true
        $recursionStack[$Node] = $true
        [void]$Path.Add($Node)

        # Parcourir les voisins du nÅ“ud
        if ($DependencyGraph.ContainsKey($Node)) {
            foreach ($neighbor in $DependencyGraph[$Node]) {
                # Si le voisin n'a pas Ã©tÃ© visitÃ©, le visiter
                if (-not $visited.ContainsKey($neighbor) -or -not $visited[$neighbor]) {
                    $cycleFound = Find-CyclesDFS -Node $neighbor -Path $Path
                    if ($cycleFound -and -not $IncludeAllCycles) {
                        return $true
                    }
                }
                # Si le voisin est dans la pile de rÃ©cursion, un cycle a Ã©tÃ© dÃ©tectÃ©
                elseif ($recursionStack.ContainsKey($neighbor) -and $recursionStack[$neighbor]) {
                    # DÃ©terminer le cycle
                    $cycleStartIndex = $Path.IndexOf($neighbor)
                    $cycle = $Path.GetRange($cycleStartIndex, $Path.Count - $cycleStartIndex)
                    $cycle.Add($neighbor)

                    # Ajouter le cycle Ã  la liste des cycles
                    [void]$cycles.Add([PSCustomObject]@{
                            Nodes  = $cycle.ToArray()
                            Length = $cycle.Count
                        })

                    if (-not $IncludeAllCycles) {
                        return $true
                    }
                }
            }
        }

        # Retirer le nÅ“ud de la pile de rÃ©cursion et du chemin
        $recursionStack[$Node] = $false
        [void]$Path.RemoveAt($Path.Count - 1)

        return $false
    }

    # Parcourir tous les nÅ“uds du graphe
    foreach ($node in $DependencyGraph.Keys) {
        if (-not $visited.ContainsKey($node) -or -not $visited[$node]) {
            $cycleFound = Find-CyclesDFS -Node $node
            if ($cycleFound -and -not $IncludeAllCycles) {
                break
            }
        }
    }

    return [PSCustomObject]@{
        HasCycles  = $cycles.Count -gt 0
        Cycles     = $cycles
        CycleCount = $cycles.Count
    }
}

<#
.SYNOPSIS
    RÃ©sout les dÃ©pendances d'un module PowerShell en Ã©vitant les boucles infinies.

.DESCRIPTION
    Cette fonction rÃ©sout les dÃ©pendances d'un module PowerShell en Ã©vitant les boucles infinies
    en utilisant un algorithme de tri topologique.

.PARAMETER ModulePath
    Chemin du module Ã  analyser.

.PARAMETER MaxDepth
    Profondeur maximale de rÃ©cursion pour l'analyse des dÃ©pendances. Par dÃ©faut: 10.

.PARAMETER SkipSystemModules
    Indique si les modules systÃ¨me doivent Ãªtre exclus de l'analyse.

.PARAMETER BreakCycles
    Indique si les cycles de dÃ©pendances doivent Ãªtre brisÃ©s automatiquement.

.PARAMETER OutputFormat
    Format de sortie des rÃ©sultats. Valeurs possibles: Object, HashTable, Graph. Par dÃ©faut: Object.

.EXAMPLE
    $dependencies = Resolve-ModuleDependencies -ModulePath C:\Modules\MyModule\MyModule.psd1
    RÃ©sout les dÃ©pendances du module MyModule en Ã©vitant les boucles infinies.

.OUTPUTS
    [PSCustomObject] ou [HashTable] selon le paramÃ¨tre OutputFormat.
#>
function Resolve-ModuleDependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$ModulePath,

        [Parameter(Mandatory = $false)]
        [int]$MaxDepth = 10,

        [Parameter(Mandatory = $false)]
        [switch]$SkipSystemModules,

        [Parameter(Mandatory = $false)]
        [switch]$BreakCycles,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Object', 'HashTable', 'Graph')]
        [string]$OutputFormat = 'Object'
    )

    # Analyser les dÃ©pendances rÃ©cursivement
    $recursiveResult = Get-ModuleDependenciesRecursive -ModulePath $ModulePath -MaxDepth $MaxDepth -SkipSystemModules:$SkipSystemModules -OutputFormat 'HashTable'

    # VÃ©rifier si des dÃ©pendances ont Ã©tÃ© trouvÃ©es
    if (-not $recursiveResult -or -not $recursiveResult.DependencyGraph) {
        Write-Warning ('Aucune dÃ©pendance trouvÃ©e pour le module: ' + $ModulePath)
        return $null
    }

    # DÃ©tecter les cycles de dÃ©pendances
    $cycleResult = Find-ModuleDependencyCycles -DependencyGraph $recursiveResult.DependencyGraph -IncludeAllCycles

    # Initialiser le rÃ©sultat
    $result = [PSCustomObject]@{
        ModulePath      = $recursiveResult.ModulePath
        ModuleName      = $recursiveResult.ModuleName
        Dependencies    = $recursiveResult.Dependencies
        DependencyGraph = $recursiveResult.DependencyGraph
        HasCycles       = $cycleResult.HasCycles
        Cycles          = $cycleResult.Cycles
        CycleCount      = $cycleResult.CycleCount
        BrokenCycles    = @()
    }

    # Briser les cycles si demandÃ©
    if ($BreakCycles -and $cycleResult.HasCycles) {
        $brokenCycles = [System.Collections.ArrayList]::new()

        foreach ($cycle in $cycleResult.Cycles) {
            # Briser le cycle en supprimant la derniÃ¨re dÃ©pendance
            $lastNode = $cycle.Nodes[$cycle.Nodes.Count - 2]
            $firstNode = $cycle.Nodes[0]

            # Supprimer la dÃ©pendance
            $recursiveResult.DependencyGraph[$lastNode] = $recursiveResult.DependencyGraph[$lastNode] | Where-Object { $_ -ne $firstNode }

            # Ajouter le cycle brisÃ© Ã  la liste
            [void]$brokenCycles.Add([PSCustomObject]@{
                    Cycle      = $cycle.Nodes
                    BrokenEdge = @{
                        From = $lastNode
                        To   = $firstNode
                    }
                })
        }

        # Mettre Ã  jour le rÃ©sultat
        $result.DependencyGraph = $recursiveResult.DependencyGraph
        $result.BrokenCycles = $brokenCycles
    }

    # Formater la sortie selon le paramÃ¨tre OutputFormat
    switch ($OutputFormat) {
        "Object" {
            return $result
        }
        "HashTable" {
            return @{
                ModulePath      = $result.ModulePath
                ModuleName      = $result.ModuleName
                Dependencies    = $result.Dependencies
                DependencyGraph = $result.DependencyGraph
                HasCycles       = $result.HasCycles
                Cycles          = $result.Cycles
                CycleCount      = $result.CycleCount
                BrokenCycles    = $result.BrokenCycles
            }
        }
        "Graph" {
            return $result.DependencyGraph
        }
    }
}

<#
.SYNOPSIS
    Exporte un graphe de dÃ©pendances de modules PowerShell vers un fichier de visualisation.

.DESCRIPTION
    Cette fonction exporte un graphe de dÃ©pendances de modules PowerShell vers un fichier
    de visualisation dans diffÃ©rents formats (HTML, DOT, JSON, Mermaid).

.PARAMETER DependencyGraph
    Graphe de dÃ©pendances Ã  exporter. Doit Ãªtre un hashtable oÃ¹ les clÃ©s sont les noms des modules
    et les valeurs sont des tableaux contenant les noms des modules dÃ©pendants.

.PARAMETER OutputPath
    Chemin du fichier de sortie. Si non spÃ©cifiÃ©, un fichier temporaire est crÃ©Ã©.

.PARAMETER Format
    Format de sortie. Valeurs possibles: HTML, DOT, JSON, Mermaid. Par dÃ©faut: HTML.

.PARAMETER HighlightCycles
    Indique si les cycles de dÃ©pendances doivent Ãªtre mis en Ã©vidence.

.PARAMETER OpenInBrowser
    Indique si le fichier de visualisation doit Ãªtre ouvert dans le navigateur par dÃ©faut.

.PARAMETER Title
    Titre de la visualisation.

.EXAMPLE
    $graph = @{
        ModuleA = @(ModuleB, ModuleC)
        ModuleB = @(ModuleD)
        ModuleC = @(ModuleA)
        ModuleD = @()
    }
    Export-ModuleDependencyGraph -DependencyGraph $graph -OutputPath C:\Temp\dependencies.html -Format HTML -HighlightCycles -OpenInBrowser
    Exporte le graphe de dÃ©pendances vers un fichier HTML et l'ouvre dans le navigateur par dÃ©faut.

.OUTPUTS
    [string] Chemin du fichier de visualisation.
#>
function Export-ModuleDependencyGraph {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable]$DependencyGraph,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet('HTML', 'DOT', 'JSON', 'Mermaid')]
        [string]$Format = 'HTML',

        [Parameter(Mandatory = $false)]
        [switch]$HighlightCycles,

        [Parameter(Mandatory = $false)]
        [switch]$OpenInBrowser,

        [Parameter(Mandatory = $false)]
        [string]$Title = "Module Dependency Graph"
    )

    # DÃ©terminer le chemin de sortie
    if (-not $OutputPath) {
        $tempDir = [System.IO.Path]::GetTempPath()
        $tempFileName = "ModuleDependencies_" + [System.Guid]::NewGuid().ToString() + "." + $Format.ToLower()
        $OutputPath = Join-Path -Path $tempDir -ChildPath $tempFileName
    }

    # DÃ©tecter les cycles si nÃ©cessaire
    $cycles = @()
    $cyclicNodes = @()
    if ($HighlightCycles) {
        $cycleResult = Find-ModuleDependencyCycles -DependencyGraph $DependencyGraph -IncludeAllCycles
        $cycles = $cycleResult.Cycles

        # Extraire les nÅ“uds cycliques
        foreach ($cycle in $cycles) {
            foreach ($node in $cycle.Nodes) {
                if (-not $cyclicNodes.Contains($node)) {
                    $cyclicNodes += $node
                }
            }
        }
    }

    # GÃ©nÃ©rer la visualisation selon le format
    switch ($Format) {
        "HTML" {
            # GÃ©nÃ©rer la visualisation HTML avec vis.js
            $html = Export-DependencyGraphToHtml -DependencyGraph $DependencyGraph -Title $Title -HighlightCycles:$HighlightCycles -CyclicNodes $cyclicNodes

            # Ã‰crire le fichier HTML
            $html | Out-File -FilePath $OutputPath -Encoding UTF8
        }
        "DOT" {
            # GÃ©nÃ©rer la visualisation DOT (Graphviz)
            $dot = Export-DependencyGraphToDot -DependencyGraph $DependencyGraph -Title $Title -HighlightCycles:$HighlightCycles -CyclicNodes $cyclicNodes

            # Ã‰crire le fichier DOT
            $dot | Out-File -FilePath $OutputPath -Encoding UTF8
        }
        "JSON" {
            # GÃ©nÃ©rer la visualisation JSON
            $json = Export-DependencyGraphToJson -DependencyGraph $DependencyGraph -HighlightCycles:$HighlightCycles -CyclicNodes $cyclicNodes

            # Ã‰crire le fichier JSON
            $json | Out-File -FilePath $OutputPath -Encoding UTF8
        }
        "Mermaid" {
            # GÃ©nÃ©rer la visualisation Mermaid
            $mermaid = Export-DependencyGraphToMermaid -DependencyGraph $DependencyGraph -Title $Title -HighlightCycles:$HighlightCycles -CyclicNodes $cyclicNodes

            # Ã‰crire le fichier Mermaid
            $mermaid | Out-File -FilePath $OutputPath -Encoding UTF8
        }
    }

    # Ouvrir le fichier dans le navigateur si demandÃ©
    if ($OpenInBrowser -and $Format -eq "HTML") {
        Start-Process $OutputPath
    }

    return $OutputPath
}

<#
.SYNOPSIS
    Exporte un graphe de dÃ©pendances vers un fichier HTML avec vis.js.

.DESCRIPTION
    Cette fonction interne exporte un graphe de dÃ©pendances vers un fichier HTML
    en utilisant la bibliothÃ¨que vis.js pour la visualisation.

.PARAMETER DependencyGraph
    Graphe de dÃ©pendances Ã  exporter.

.PARAMETER Title
    Titre de la visualisation.

.PARAMETER HighlightCycles
    Indique si les cycles de dÃ©pendances doivent Ãªtre mis en Ã©vidence.

.PARAMETER CyclicNodes
    Liste des nÅ“uds impliquÃ©s dans des cycles.

.OUTPUTS
    [string] Contenu HTML de la visualisation.
#>
function Export-DependencyGraphToHtml {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$DependencyGraph,

        [Parameter(Mandatory = $false)]
        [string]$Title = "Module Dependency Graph",

        [Parameter(Mandatory = $false)]
        [switch]$HighlightCycles,

        [Parameter(Mandatory = $false)]
        [string[]]$CyclicNodes = @()
    )

    # PrÃ©parer les donnÃ©es pour vis.js
    $nodes = [System.Collections.ArrayList]::new()
    $edges = [System.Collections.ArrayList]::new()
    $nodeId = 0
    $nodeMap = @{}

    # CrÃ©er les nÅ“uds
    foreach ($module in $DependencyGraph.Keys) {
        $nodeMap[$module] = $nodeId

        # DÃ©terminer si le nÅ“ud est impliquÃ© dans un cycle
        $isCyclic = $CyclicNodes -contains $module
        $group = if ($isCyclic -and $HighlightCycles) { "cyclic" } else { "normal" }

        [void]$nodes.Add(@{
                id    = $nodeId
                label = $module
                group = $group
            })

        $nodeId++
    }

    # CrÃ©er les arÃªtes
    foreach ($module in $DependencyGraph.Keys) {
        $fromId = $nodeMap[$module]

        foreach ($dependency in $DependencyGraph[$module]) {
            if ($nodeMap.ContainsKey($dependency)) {
                $toId = $nodeMap[$dependency]

                # DÃ©terminer si l'arÃªte fait partie d'un cycle
                $isCyclicEdge = $CyclicNodes -contains $module -and $CyclicNodes -contains $dependency
                $color = if ($isCyclicEdge -and $HighlightCycles) { "#ff0000" } else { "#848484" }

                [void]$edges.Add(@{
                        from   = $fromId
                        to     = $toId
                        arrows = "to"
                        color  = @{
                            color = $color
                        }
                    })
            }
        }
    }

    # Convertir les donnÃ©es en JSON
    $nodesJson = $nodes | ConvertTo-Json
    $edgesJson = $edges | ConvertTo-Json
    $cyclesJson = $CyclicNodes | ConvertTo-Json

    # GÃ©nÃ©rer le HTML
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>$Title</title>
    <script type="text/javascript" src="https://unpkg.com/vis-network/standalone/umd/vis-network.min.js"></script>
    <style type="text/css">
        #mynetwork {
            width: 100%;
            height: 800px;
            border: 1px solid lightgray;
        }
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
        }
        h1 {
            color: #333;
        }
        .controls {
            margin-bottom: 20px;
        }
        button {
            padding: 8px 16px;
            background-color: #4CAF50;
            color: white;
            border: none;
            cursor: pointer;
            margin-right: 10px;
        }
        button:hover {
            background-color: #45a049;
        }
        .stats {
            margin-top: 20px;
            padding: 10px;
            background-color: #f8f8f8;
            border: 1px solid #ddd;
        }
    </style>
</head>
<body>
    <h1>$Title</h1>
    <div class="controls">
        <button onclick="highlightCycles()">Highlight Cycles</button>
        <button onclick="resetHighlighting()">Reset Highlighting</button>
        <button onclick="fitNetwork()">Fit View</button>
    </div>
    <div id="mynetwork"></div>
    <div class="stats">
        <p>Total Modules: <strong>${($DependencyGraph.Keys.Count)}</strong></p>
        <p>Total Dependencies: <strong>${($edges.Count)}</strong></p>
        <p>Cyclic Modules: <strong>${($CyclicNodes.Count)}</strong></p>
    </div>
    <script type="text/javascript">
        // DonnÃ©es du graphe
        var nodes = new vis.DataSet($nodesJson);
        var edges = new vis.DataSet($edgesJson);
        var cyclicNodes = $cyclesJson;

        // Configuration du graphe
        var container = document.getElementById('mynetwork');
        var data = {
            nodes: nodes,
            edges: edges
        };
        var options = {
            nodes: {
                shape: 'box',
                font: {
                    size: 14
                }
            },
            edges: {
                width: 2
            },
            groups: {
                cyclic: {
                    color: {
                        background: '#ffcccc',
                        border: '#ff0000'
                    }
                },
                normal: {
                    color: {
                        background: '#d2e5ff',
                        border: '#2b7ce9'
                    }
                }
            },
            physics: {
                stabilization: true,
                barnesHut: {
                    gravitationalConstant: -5000,
                    centralGravity: 0.3,
                    springLength: 150,
                    springConstant: 0.04
                }
            },
            layout: {
                hierarchical: {
                    enabled: false
                }
            }
        };

        // CrÃ©er le rÃ©seau
        var network = new vis.Network(container, data, options);

        // Fonction pour mettre en Ã©vidence les cycles
        function highlightCycles() {
            // Mettre Ã  jour les nÅ“uds cycliques
            nodes.forEach(function(node) {
                if (cyclicNodes.includes(node.label)) {
                    nodes.update({
                        id: node.id,
                        group: 'cyclic'
                    });
                }
            });

            // Mettre Ã  jour les arÃªtes cycliques
            edges.forEach(function(edge) {
                var fromNode = nodes.get(edge.from);
                var toNode = nodes.get(edge.to);
                if (cyclicNodes.includes(fromNode.label) && cyclicNodes.includes(toNode.label)) {
                    edges.update({
                        id: edge.id,
                        color: {
                            color: '#ff0000'
                        }
                    });
                }
            });
        }

        // Fonction pour rÃ©initialiser la mise en Ã©vidence
        function resetHighlighting() {
            // RÃ©initialiser les nÅ“uds
            nodes.forEach(function(node) {
                nodes.update({
                    id: node.id,
                    group: 'normal'
                });
            });

            // RÃ©initialiser les arÃªtes
            edges.forEach(function(edge) {
                edges.update({
                    id: edge.id,
                    color: {
                        color: '#848484'
                    }
                });
            });
        }

        // Fonction pour ajuster la vue
        function fitNetwork() {
            network.fit();
        }

        // Initialiser la mise en Ã©vidence des cycles si demandÃ©
        if ($($HighlightCycles.ToString().ToLower())) {
            highlightCycles();
        }
    </script>
</body>
</html>
"@

    return $html
}

<#
.SYNOPSIS
    Exporte un graphe de dÃ©pendances vers un fichier DOT (Graphviz).

.DESCRIPTION
    Cette fonction interne exporte un graphe de dÃ©pendances vers un fichier DOT
    pour une utilisation avec Graphviz.

.PARAMETER DependencyGraph
    Graphe de dÃ©pendances Ã  exporter.

.PARAMETER Title
    Titre de la visualisation.

.PARAMETER HighlightCycles
    Indique si les cycles de dÃ©pendances doivent Ãªtre mis en Ã©vidence.

.PARAMETER CyclicNodes
    Liste des nÅ“uds impliquÃ©s dans des cycles.

.OUTPUTS
    [string] Contenu DOT de la visualisation.
#>
function Export-DependencyGraphToDot {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$DependencyGraph,

        [Parameter(Mandatory = $false)]
        [string]$Title = "Module Dependency Graph",

        [Parameter(Mandatory = $false)]
        [switch]$HighlightCycles,

        [Parameter(Mandatory = $false)]
        [string[]]$CyclicNodes = @()
    )

    # Initialiser le contenu DOT
    $dot = "digraph `"$Title`" {`n"
    $dot += "  rankdir=LR;`n"
    $dot += "  node [shape=box, style=filled, fillcolor=lightblue];`n"

    # Ajouter les nÅ“uds
    foreach ($module in $DependencyGraph.Keys) {
        $isCyclic = $CyclicNodes -contains $module
        $color = if ($isCyclic -and $HighlightCycles) { "fillcolor=lightpink, color=red" } else { "fillcolor=lightblue" }

        $dot += "  `"$module`" [$color];`n"
    }

    # Ajouter les arÃªtes
    foreach ($module in $DependencyGraph.Keys) {
        foreach ($dependency in $DependencyGraph[$module]) {
            $isCyclicEdge = $CyclicNodes -contains $module -and $CyclicNodes -contains $dependency
            $color = if ($isCyclicEdge -and $HighlightCycles) { "color=red" } else { "" }

            $dot += "  `"$module`" -> `"$dependency`" [$color];`n"
        }
    }

    $dot += "}`n"

    return $dot
}

<#
.SYNOPSIS
    Exporte un graphe de dÃ©pendances vers un fichier JSON.

.DESCRIPTION
    Cette fonction interne exporte un graphe de dÃ©pendances vers un fichier JSON.

.PARAMETER DependencyGraph
    Graphe de dÃ©pendances Ã  exporter.

.PARAMETER HighlightCycles
    Indique si les cycles de dÃ©pendances doivent Ãªtre mis en Ã©vidence.

.PARAMETER CyclicNodes
    Liste des nÅ“uds impliquÃ©s dans des cycles.

.OUTPUTS
    [string] Contenu JSON de la visualisation.
#>
function Export-DependencyGraphToJson {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$DependencyGraph,

        [Parameter(Mandatory = $false)]
        [switch]$HighlightCycles,

        [Parameter(Mandatory = $false)]
        [string[]]$CyclicNodes = @()
    )

    # CrÃ©er l'objet JSON
    $jsonObj = @{
        nodes  = [System.Collections.ArrayList]::new()
        edges  = [System.Collections.ArrayList]::new()
        cycles = if ($HighlightCycles) { $CyclicNodes } else { @() }
    }

    # Ajouter les nÅ“uds
    foreach ($module in $DependencyGraph.Keys) {
        $isCyclic = $CyclicNodes -contains $module

        [void]$jsonObj.nodes.Add(@{
                id       = $module
                label    = $module
                isCyclic = $isCyclic
            })
    }

    # Ajouter les arÃªtes
    foreach ($module in $DependencyGraph.Keys) {
        foreach ($dependency in $DependencyGraph[$module]) {
            $isCyclicEdge = $CyclicNodes -contains $module -and $CyclicNodes -contains $dependency

            [void]$jsonObj.edges.Add(@{
                    source   = $module
                    target   = $dependency
                    isCyclic = $isCyclicEdge
                })
        }
    }

    # Convertir en JSON
    $json = $jsonObj | ConvertTo-Json -Depth 5

    return $json
}

<#
.SYNOPSIS
    Exporte un graphe de dÃ©pendances vers un fichier Mermaid.

.DESCRIPTION
    Cette fonction interne exporte un graphe de dÃ©pendances vers un fichier Mermaid
    pour une utilisation dans des documents Markdown.

.PARAMETER DependencyGraph
    Graphe de dÃ©pendances Ã  exporter.

.PARAMETER Title
    Titre de la visualisation.

.PARAMETER HighlightCycles
    Indique si les cycles de dÃ©pendances doivent Ãªtre mis en Ã©vidence.

.PARAMETER CyclicNodes
    Liste des nÅ“uds impliquÃ©s dans des cycles.

.OUTPUTS
    [string] Contenu Mermaid de la visualisation.
#>
function Export-DependencyGraphToMermaid {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$DependencyGraph,

        [Parameter(Mandatory = $false)]
        [string]$Title = "Module Dependency Graph",

        [Parameter(Mandatory = $false)]
        [switch]$HighlightCycles,

        [Parameter(Mandatory = $false)]
        [string[]]$CyclicNodes = @()
    )

    # Initialiser le contenu Mermaid
    $mermaid = "```mermaid`n"
    $mermaid += "graph LR`n"
    $mermaid += "  %% $($Title)`n"

    # Ajouter les nÅ“uds
    foreach ($module in $DependencyGraph.Keys) {
        $moduleId = $module -replace '[^a-zA-Z0-9]', '_'
        $isCyclic = $CyclicNodes -contains $module
        $style = if ($isCyclic -and $HighlightCycles) { "style $moduleId fill:#ffcccc,stroke:#ff0000`n" } else { "" }

        $mermaid += "  $moduleId[$module]`n"
        if ($style) {
            $mermaid += "  $style"
        }
    }

    # Ajouter les arÃªtes
    foreach ($module in $DependencyGraph.Keys) {
        $moduleId = $module -replace '[^a-zA-Z0-9]', '_'

        foreach ($dependency in $DependencyGraph[$module]) {
            $dependencyId = $dependency -replace '[^a-zA-Z0-9]', '_'
            $isCyclicEdge = $CyclicNodes -contains $module -and $CyclicNodes -contains $dependency
            $color = if ($isCyclicEdge -and $HighlightCycles) { "|red" } else { "" }

            $mermaid += "  $moduleId --> $dependencyId$color`n"
        }
    }

    $mermaid += "```"

    return $mermaid
}

<#
.SYNOPSIS
    Affiche un graphe de dÃ©pendances de modules PowerShell dans le navigateur par dÃ©faut.

.DESCRIPTION
    Cette fonction affiche un graphe de dÃ©pendances de modules PowerShell dans le navigateur par dÃ©faut.

.PARAMETER ModulePath
    Chemin du module Ã  analyser.

.PARAMETER MaxDepth
    Profondeur maximale de rÃ©cursion pour l'analyse des dÃ©pendances. Par dÃ©faut: 10.

.PARAMETER SkipSystemModules
    Indique si les modules systÃ¨me doivent Ãªtre exclus de l'analyse.

.PARAMETER HighlightCycles
    Indique si les cycles de dÃ©pendances doivent Ãªtre mis en Ã©vidence.

.PARAMETER OutputPath
    Chemin du fichier de sortie. Si non spÃ©cifiÃ©, un fichier temporaire est crÃ©Ã©.

.PARAMETER Format
    Format de sortie. Valeurs possibles: HTML, DOT, JSON, Mermaid. Par dÃ©faut: HTML.

.EXAMPLE
    Show-ModuleDependencyGraph -ModulePath C:\Modules\MyModule\MyModule.psd1 -HighlightCycles
    Affiche le graphe de dÃ©pendances du module MyModule dans le navigateur par dÃ©faut.

.OUTPUTS
    [string] Chemin du fichier de visualisation.
#>
function Show-ModuleDependencyGraph {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$ModulePath,

        [Parameter(Mandatory = $false)]
        [int]$MaxDepth = 10,

        [Parameter(Mandatory = $false)]
        [switch]$SkipSystemModules,

        [Parameter(Mandatory = $false)]
        [switch]$HighlightCycles,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet('HTML', 'DOT', 'JSON', 'Mermaid')]
        [string]$Format = 'HTML'
    )

    # Analyser les dÃ©pendances rÃ©cursivement
    $recursiveResult = Get-ModuleDependenciesRecursive -ModulePath $ModulePath -MaxDepth $MaxDepth -SkipSystemModules:$SkipSystemModules -OutputFormat 'HashTable'

    # VÃ©rifier si des dÃ©pendances ont Ã©tÃ© trouvÃ©es
    if (-not $recursiveResult -or -not $recursiveResult.DependencyGraph) {
        Write-Warning ('Aucune dÃ©pendance trouvÃ©e pour le module: ' + $ModulePath)
        return $null
    }

    # Exporter le graphe de dÃ©pendances
    $title = 'Module Dependency Graph - ' + $recursiveResult.ModuleName
    $visualizationPath = Export-ModuleDependencyGraph -DependencyGraph $recursiveResult.DependencyGraph -OutputPath $OutputPath -Format $Format -HighlightCycles:$HighlightCycles -OpenInBrowser -Title $title

    return $visualizationPath
}

<#
.SYNOPSIS
    Analyse la structure d'un fichier manifeste PowerShell (.psd1).

.DESCRIPTION
    Cette fonction analyse la structure d'un fichier manifeste PowerShell (.psd1)
    et retourne un objet contenant les informations sur le manifeste.

.PARAMETER ManifestPath
    Chemin du fichier manifeste (.psd1) Ã  analyser.

.EXAMPLE
    $manifestInfo = Get-PowerShellManifestStructure -ManifestPath C:\Modules\MyModule\MyModule.psd1
    Analyse la structure du manifeste du module MyModule.

.OUTPUTS
    [PSCustomObject] Informations sur la structure du manifeste.
#>
function Get-PowerShellManifestStructure {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ManifestPath
    )

    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $ManifestPath -PathType Leaf)) {
        $errorMsg = 'Manifest file not found: ' + $ManifestPath
        Write-Error $errorMsg
        return $null
    }

    # VÃ©rifier l'extension du fichier
    $extension = [System.IO.Path]::GetExtension($ManifestPath)
    if ($extension -ne ".psd1") {
        $errorMsg = 'Not a PowerShell manifest file (.psd1): ' + $ManifestPath
        Write-Error $errorMsg
        return $null
    }

    try {
        # Importer le manifeste
        $manifest = Import-PowerShellDataFile -Path $ManifestPath -ErrorAction Stop

        # Initialiser l'objet rÃ©sultat
    $result = [PSCustomObject]@{
        Path                   = $ManifestPath
        ModuleName             = [System.IO.Path]::GetFileNameWithoutExtension($ManifestPath)
        ModuleVersion          = $manifest.ModuleVersion
        GUID                   = $manifest.GUID
        Author                 = $manifest.Author
        CompanyName            = $manifest.CompanyName
        Copyright              = $manifest.Copyright
        Description            = $manifest.Description
        PowerShellVersion      = $manifest.PowerShellVersion
        PowerShellHostName     = $manifest.PowerShellHostName
        PowerShellHostVersion  = $manifest.PowerShellHostVersion
        DotNetFrameworkVersion = $manifest.DotNetFrameworkVersion
        CLRVersion             = $manifest.CLRVersion
        ProcessorArchitecture  = $manifest.ProcessorArchitecture
        RequiredModules        = $manifest.RequiredModules
        RequiredAssemblies     = $manifest.RequiredAssemblies
        ScriptsToProcess       = $manifest.ScriptsToProcess
        TypesToProcess         = $manifest.TypesToProcess
        FormatsToProcess       = $manifest.FormatsToProcess
        NestedModules          = $manifest.NestedModules
        FunctionsToExport      = $manifest.FunctionsToExport
        CmdletsToExport        = $manifest.CmdletsToExport
        VariablesToExport      = $manifest.VariablesToExport
        AliasesToExport        = $manifest.AliasesToExport
        DscResourcesToExport   = $manifest.DscResourcesToExport
        ModuleList             = $manifest.ModuleList
        FileList               = $manifest.FileList
        PrivateData            = $manifest.PrivateData
        Tags                   = $manifest.PrivateData.PSData.Tags
        ProjectUri             = $manifest.PrivateData.PSData.ProjectUri
        LicenseUri             = $manifest.PrivateData.PSData.LicenseUri
        IconUri                = $manifest.PrivateData.PSData.IconUri
        ReleaseNotes           = $manifest.PrivateData.PSData.ReleaseNotes
        Prerelease             = $manifest.PrivateData.PSData.Prerelease
        HelpInfoURI            = $manifest.HelpInfoURI
        DefaultCommandPrefix   = $manifest.DefaultCommandPrefix
    }

    # GÃ©rer le cas oÃ¹ RootModule ou ModuleToProcess est dÃ©fini
    if ($manifest.ContainsKey('RootModule') -and $manifest.RootModule) {
        $result | Add-Member -MemberType NoteProperty -Name 'RootModule' -Value $manifest.RootModule
    } elseif ($manifest.ContainsKey('ModuleToProcess') -and $manifest.ModuleToProcess) {
        $result | Add-Member -MemberType NoteProperty -Name 'RootModule' -Value $manifest.ModuleToProcess
        $result | Add-Member -MemberType NoteProperty -Name 'ModuleToProcess' -Value $manifest.ModuleToProcess
    }

    # Analyser les dÃ©pendances RequiredModules
    if ($manifest.ContainsKey('RequiredModules') -and $manifest.RequiredModules) {
        $requiredModules = @()
        foreach ($module in $manifest.RequiredModules) {
            if ($module -is [string]) {
                $requiredModules += [PSCustomObject]@{
                    Name    = $module
                    Version = $null
                    GUID    = $null
                }
            } elseif ($module -is [hashtable] -or $module -is [System.Collections.Specialized.OrderedDictionary]) {
                $requiredModules += [PSCustomObject]@{
                    Name    = $module.ModuleName
                    Version = if ($module.ModuleVersion) { $module.ModuleVersion } else { $module.RequiredVersion }
                    GUID    = $module.GUID
                }
            }
        }
        $result.RequiredModules = $requiredModules
    }

    # Analyser les dÃ©pendances NestedModules
    if ($manifest.ContainsKey('NestedModules') -and $manifest.NestedModules) {
        $nestedModules = @()
        foreach ($module in $manifest.NestedModules) {
            if ($module -is [string]) {
                $nestedModules += [PSCustomObject]@{
                    Name    = if ($module -match '\.ps[md]1$') { [System.IO.Path]::GetFileNameWithoutExtension($module) } else { $module }
                    Path    = $module
                    Version = $null
                    GUID    = $null
                }
            } elseif ($module -is [hashtable] -or $module -is [System.Collections.Specialized.OrderedDictionary]) {
                $nestedModules += [PSCustomObject]@{
                    Name    = $module.ModuleName
                    Path    = $module.Path
                    Version = if ($module.ModuleVersion) { $module.ModuleVersion } else { $module.RequiredVersion }
                    GUID    = $module.GUID
                }
            }
        }
        $result.NestedModules = $nestedModules
    }

    return $result
} catch {
    Write-Error "Get-Error analyzing manifest: $_"
    return $null
}
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Get-ModuleDependenciesRecursive, Get-ModuleDependenciesFromManifest, Get-ModuleDependenciesFromCode, Find-ModuleDependencyCycles, Resolve-ModuleDependencies, Export-ModuleDependencyGraph, Show-ModuleDependencyGraph, Get-PowerShellManifestStructure
