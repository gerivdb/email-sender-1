#Requires -Version 5.1
<#
.SYNOPSIS
    Module d'analyse des dÃ©pendances entre modules PowerShell.

.DESCRIPTION
    Ce module permet d'analyser les dÃ©pendances entre modules PowerShell,
    en dÃ©tectant les dÃ©pendances via les manifestes (.psd1) et l'analyse du code.

.NOTES
    Auteur: Dependency Management Team
    Version: 1.0
#>

function Test-SystemModule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModuleName
    )

    # Liste des modules systÃ¨me PowerShell
    $systemModules = @(
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
        'PackageManagement',
        'PowerShellGet',
        'ThreadJob'
    )

    return $systemModules -contains $ModuleName
}

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

        # CrÃ©er l'objet rÃ©sultat
        $result = [PSCustomObject]@{
            ModuleName      = [System.IO.Path]::GetFileNameWithoutExtension($ManifestPath)
            ModuleVersion   = $manifest.ModuleVersion
            GUID            = $manifest.GUID
            Author          = $manifest.Author
            Description     = $manifest.Description
            RootModule      = $manifest.RootModule
            RequiredModules = @()
            NestedModules   = @()
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
        $errorMsg = 'Error analyzing manifest: ' + $_
        Write-Error $errorMsg
        return $null
    }
}

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
        Write-Warning "Manifest file does not exist: $ManifestPath"
        return $dependencies
    }

    # VÃ©rifier l'extension du fichier
    $extension = [System.IO.Path]::GetExtension($ManifestPath)
    if ($extension -ne ".psd1") {
        Write-Warning "File is not a PowerShell manifest (.psd1): $ManifestPath"
        return $dependencies
    }

    try {
        # Importer le manifeste
        $manifest = Import-PowerShellDataFile -Path $ManifestPath -ErrorAction Stop

        # Extraire les dÃ©pendances RequiredModules
        if ($manifest.ContainsKey('RequiredModules') -and $manifest.RequiredModules) {
            Write-Verbose "Analyzing RequiredModules in manifest: $ManifestPath"

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
                    Write-Verbose "System module ignored: $moduleName"
                    continue
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
            Write-Verbose "Analyzing NestedModules in manifest: $ManifestPath"

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
                    Write-Verbose "System module ignored: $moduleName"
                    continue
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
            Write-Verbose "Analyzing RootModule in manifest: $ManifestPath"

            # DÃ©terminer le type de RootModule
            if ($rootModule -is [string]) {
                # Format simple: 'ModuleName' ou 'Path\To\Module.psm1'
                $moduleName = $null
                $modulePath = $null

                if ($rootModule -match '\.ps[md]1$') {
                    # C'est un chemin vers un fichier .psm1 ou .psd1
                    $modulePath = $rootModule
                    $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($rootModule)

                    # Si le chemin est relatif, le rÃ©soudre par rapport au rÃ©pertoire du manifeste
                    if (-not [System.IO.Path]::IsPathRooted($modulePath)) {
                        $manifestDir = [System.IO.Path]::GetDirectoryName($ManifestPath)
                        $modulePath = Join-Path -Path $manifestDir -ChildPath $modulePath
                    }
                } else {
                    # C'est un nom de module
                    $moduleName = $rootModule
                }

                # Ignorer les modules systÃ¨me si demandÃ©
                if ($SkipSystemModules -and (Test-SystemModule -ModuleName $moduleName)) {
                    Write-Verbose "System module ignored: $moduleName"
                } else {
                    # Ajouter la dÃ©pendance Ã  la liste
                    [void]$dependencies.Add([PSCustomObject]@{
                            Name    = $moduleName
                            Version = $null
                            GUID    = $null
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
                }

                # Ignorer les modules systÃ¨me si demandÃ©
                if ($SkipSystemModules -and (Test-SystemModule -ModuleName $moduleName)) {
                    Write-Verbose "System module ignored: $moduleName"
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
        $errorMsg = 'Error analyzing manifest: ' + $_
        Write-Error $errorMsg
        return $dependencies
    }
}

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
        [switch]$Recurse
    )

    # Initialiser la liste des dÃ©pendances
    $dependencies = [System.Collections.ArrayList]::new()

    # VÃ©rifier si le chemin existe
    if (-not (Test-Path -Path $ModulePath)) {
        Write-Warning "Path does not exist: $ModulePath"
        return $dependencies
    }

    # DÃ©terminer les fichiers Ã  analyser
    $filesToAnalyze = @()
    if (Test-Path -Path $ModulePath -PathType Leaf) {
        # C'est un fichier unique
        $filesToAnalyze += Get-Item -Path $ModulePath
    } else {
        # C'est un rÃ©pertoire
        $filter = "*.ps1", "*.psm1", "*.psd1"
        $filesToAnalyze += Get-ChildItem -Path $ModulePath -Include $filter -File -Recurse:$Recurse
    }

    # Analyser chaque fichier
    foreach ($file in $filesToAnalyze) {
        Write-Verbose "Analyzing file: $($file.FullName)"

        # Lire le contenu du fichier
        try {
            $content = Get-Content -Path $file.FullName -Raw -ErrorAction Stop
        } catch {
            Write-Warning "Error reading file $($file.FullName): $_"
            continue
        }

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
                Write-Verbose "System module ignored: $moduleName"
                continue
            }

            # RÃ©soudre le chemin du module si demandÃ©
            if (-not $isPath) {
                $modulePath = $null
            } else {
                # Si le chemin est relatif, le rÃ©soudre par rapport au rÃ©pertoire du module
                if (-not [System.IO.Path]::IsPathRooted($modulePath)) {
                    $moduleDir = [System.IO.Path]::GetDirectoryName($file.FullName)
                    $modulePath = Join-Path -Path $moduleDir -ChildPath $modulePath
                }
            }

            # Ajouter la dÃ©pendance Ã  la liste
            [void]$dependencies.Add([PSCustomObject]@{
                    Name    = $moduleName
                    Version = $null
                    GUID    = $null
                    Path    = $modulePath
                    Type    = "ImportModule"
                    Source  = $file.FullName
                })
        }

        # DÃ©tecter les Using module
        $usingMatches = [regex]::Matches($content, '(?m)^\s*using\s+module\s+([''"]?)([^''"\s,;]+)\1')

        foreach ($match in $usingMatches) {
            $moduleName = $match.Groups[2].Value
            $isPath = $false

            # VÃ©rifier si c'est un chemin ou un nom de module
            if ($moduleName -match '\.ps[md]1$' -or $moduleName -match '[\\/]') {
                $isPath = $true
                $modulePath = $moduleName

                # Extraire le nom du module Ã  partir du chemin
                if ($modulePath -match '\.ps[md]1$') {
                    $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($modulePath)
                } else {
                    $moduleName = [System.IO.Path]::GetFileName($modulePath)
                }

                # Si le chemin est relatif, le rÃ©soudre par rapport au rÃ©pertoire du module
                if (-not [System.IO.Path]::IsPathRooted($modulePath)) {
                    $moduleDir = [System.IO.Path]::GetDirectoryName($file.FullName)
                    $modulePath = Join-Path -Path $moduleDir -ChildPath $modulePath
                }
            } else {
                # C'est un nom de module
                $modulePath = $null
            }

            # Ignorer les modules systÃ¨me si demandÃ©
            if ($SkipSystemModules -and (Test-SystemModule -ModuleName $moduleName)) {
                Write-Verbose "System module ignored: $moduleName"
                continue
            }

            # Ajouter la dÃ©pendance Ã  la liste
            [void]$dependencies.Add([PSCustomObject]@{
                    Name    = $moduleName
                    Version = $null
                    GUID    = $null
                    Path    = $modulePath
                    Type    = "UsingModule"
                    Source  = $file.FullName
                })
        }
    }

    return $dependencies
}

function Find-ModulePath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,

        [Parameter(Mandatory = $false)]
        [string]$ModuleVersion
    )

    # Rechercher le module dans les chemins de modules
    $module = $null

    if ($ModuleVersion) {
        # Rechercher une version spÃ©cifique
        $module = Get-Module -Name $ModuleName -ListAvailable |
            Where-Object { $_.Version -eq $ModuleVersion } |
            Select-Object -First 1
    } else {
        # Rechercher la derniÃ¨re version
        $module = Get-Module -Name $ModuleName -ListAvailable |
            Sort-Object -Property Version -Descending |
            Select-Object -First 1
    }

    if ($module) {
        return $module.Path
    }

    # Si le module n'est pas trouvÃ©, retourner $null
    return $null
}

function Get-FunctionCallDependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModulePath,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeInternalCalls,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeExternalCalls,

        [Parameter(Mandatory = $false)]
        [switch]$ResolveModulePaths,

        [Parameter(Mandatory = $false)]
        [switch]$Recurse,

        [Parameter(Mandatory = $false)]
        [switch]$NoCache
    )

    # Initialiser la liste des dÃ©pendances
    $dependencies = [System.Collections.ArrayList]::new()

    # VÃ©rifier si le chemin existe
    if (-not (Test-Path -Path $ModulePath)) {
        Write-Warning "Path does not exist: $ModulePath"
        return $dependencies
    }

    # VÃ©rifier si le rÃ©sultat est dans le cache
    $cacheKey = "$ModulePath|$IncludeInternalCalls|$IncludeExternalCalls|$ResolveModulePaths|$Recurse"
    if (-not $NoCache -and $script:DependencyCache.FunctionCalls.ContainsKey($cacheKey)) {
        Write-Verbose "Using cached result for function calls: $ModulePath"
        return $script:DependencyCache.FunctionCalls[$cacheKey]
    }

    # DÃ©terminer les fichiers Ã  analyser
    $filesToAnalyze = @()
    if (Test-Path -Path $ModulePath -PathType Container) {
        # C'est un rÃ©pertoire, analyser tous les fichiers PowerShell
        $filesToAnalyze = Get-ChildItem -Path $ModulePath -Recurse:$Recurse -File | Where-Object { $_.Extension -in '.ps1', '.psm1', '.psd1' }
    } else {
        # C'est un fichier, l'analyser directement
        $filesToAnalyze = Get-Item -Path $ModulePath
    }

    # Initialiser les dictionnaires pour stocker les informations
    $definedFunctions = [System.Collections.ArrayList]::new()
    $calledFunctions = [System.Collections.Hashtable]::new()
    $functionDefinitions = [System.Collections.Hashtable]::new()

    # PremiÃ¨re passe : collecter toutes les fonctions dÃ©finies dans le module
    foreach ($file in $filesToAnalyze) {
        Write-Verbose "Collecting defined functions in file: $($file.FullName)"

        try {
            $content = Get-Content -Path $file.FullName -Raw -ErrorAction Stop

            # DÃ©tecter les dÃ©finitions de fonctions
            # Format: function Nom-Fonction { ... }
            $functionMatches = [regex]::Matches($content, '(?m)^\s*function\s+([A-Za-z0-9\-_]+)')

            foreach ($match in $functionMatches) {
                $functionName = $match.Groups[1].Value
                [void]$definedFunctions.Add($functionName)

                # Stocker l'emplacement de la dÃ©finition
                $functionDefinitions[$functionName] = @{
                    File = $file.FullName
                    Line = ($content.Substring(0, $match.Index).Split("`n")).Length
                }
            }
        } catch {
            Write-Warning "Error reading file $($file.FullName): $_"
            continue
        }
    }

    # DeuxiÃ¨me passe : dÃ©tecter les appels de fonctions
    foreach ($file in $filesToAnalyze) {
        Write-Verbose "Analyzing function calls in file: $($file.FullName)"

        try {
            $content = Get-Content -Path $file.FullName -Raw -ErrorAction Stop

            # DÃ©tecter les appels de fonctions
            # Format 1: Nom-Fonction -Param1 Value1
            # Format 2: Nom-Fonction
            $functionCallMatches = [regex]::Matches($content, '(?m)(?<!function\s+)([A-Za-z0-9\-_]+)(?:\s+|\s*\()')

            foreach ($match in $functionCallMatches) {
                $functionName = $match.Groups[1].Value

                # Ignorer les mots-clÃ©s PowerShell et les structures de contrÃ´le
                $powershellKeywords = @(
                    'if', 'else', 'elseif', 'switch', 'while', 'do', 'for', 'foreach', 'return',
                    'break', 'continue', 'try', 'catch', 'finally', 'throw', 'param', 'begin',
                    'process', 'end', 'dynamicparam', 'filter', 'class', 'enum', 'using'
                )
                if ($powershellKeywords -contains $functionName.ToLower()) {
                    continue
                }

                # Ignorer les appels de mÃ©thodes (.Method())
                if ($content.Substring(0, $match.Index) -match [regex]::Escape(".$functionName") + "$") {
                    continue
                }

                # DÃ©terminer si c'est une fonction interne ou externe
                $isInternal = $definedFunctions -contains $functionName

                # Ajouter l'appel Ã  la liste des fonctions appelÃ©es
                if (-not $calledFunctions.ContainsKey($functionName)) {
                    $calledFunctions[$functionName] = @{
                        IsInternal = $isInternal
                        Calls      = [System.Collections.ArrayList]::new()
                    }
                }

                # Ajouter cet appel spÃ©cifique
                [void]$calledFunctions[$functionName].Calls.Add(@{
                        File            = $file.FullName
                        Line            = ($content.Substring(0, $match.Index).Split("`n")).Length
                        CallingFunction = $null  # Sera rempli plus tard
                    })
            }
        } catch {
            Write-Warning "Error analyzing file $($file.FullName): $_"
            continue
        }
    }

    # TroisiÃ¨me passe : dÃ©terminer la fonction appelante pour chaque appel
    foreach ($functionName in $calledFunctions.Keys) {
        foreach ($call in $calledFunctions[$functionName].Calls) {
            # Trouver la fonction qui contient cet appel
            $callingFunction = $null

            # VÃ©rifier si l'appel est dans une fonction dÃ©finie
            foreach ($definedFunction in $functionDefinitions.Keys) {
                if ($functionDefinitions[$definedFunction].File -eq $call.File) {
                    # VÃ©rifier si l'appel est aprÃ¨s la dÃ©finition de la fonction
                    if ($functionDefinitions[$definedFunction].Line -lt $call.Line) {
                        # VÃ©rifier si c'est la fonction dÃ©finie la plus proche avant l'appel
                        if ($null -eq $callingFunction -or
                            $functionDefinitions[$definedFunction].Line -gt $functionDefinitions[$callingFunction].Line) {
                            $callingFunction = $definedFunction
                        }
                    }
                }
            }

            # VÃ©rifier si l'appel est au niveau du script
            if ($call.Line -gt 40) {
                # Ligne approximative oÃ¹ commence le niveau du script
                $callingFunction = $null
            }

            $call.CallingFunction = $callingFunction
        }
    }

    # CrÃ©er les objets de dÃ©pendance
    foreach ($functionName in $calledFunctions.Keys) {
        $isInternal = $calledFunctions[$functionName].IsInternal

        # Filtrer selon les paramÃ¨tres
        if (($isInternal -and -not $IncludeInternalCalls) -or
            (-not $isInternal -and -not $IncludeExternalCalls)) {
            continue
        }

        # Pour les fonctions externes, essayer de rÃ©soudre le module
        $moduleName = $null
        $modulePath = $null

        if (-not $isInternal -and $ResolveModulePaths) {
            $resolvedFunction = Resolve-ExternalFunctionPath -FunctionName $functionName
            if ($resolvedFunction) {
                $moduleName = $resolvedFunction.ModuleName
                $modulePath = $resolvedFunction.ModulePath
            }
        }

        # CrÃ©er un objet pour chaque appel
        foreach ($call in $calledFunctions[$functionName].Calls) {
            [void]$dependencies.Add([PSCustomObject]@{
                    FunctionName    = $functionName
                    IsInternal      = $isInternal
                    CallingFunction = $call.CallingFunction
                    CallingFile     = $call.File
                    CallingLine     = $call.Line
                    ModuleName      = $moduleName
                    ModulePath      = $modulePath
                    Type            = if ($isInternal) { "InternalFunctionCall" } else { "ExternalFunctionCall" }
                })
        }
    }

    # Stocker le rÃ©sultat dans le cache
    if (-not $NoCache) {
        $script:DependencyCache.FunctionCalls[$cacheKey] = $dependencies
        Write-Verbose "Cached result for function calls: $ModulePath"
    }

    return $dependencies
}

function Get-ExternalFunctionDependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModulePath,

        [Parameter(Mandatory = $false)]
        [switch]$SkipSystemModules,

        [Parameter(Mandatory = $false)]
        [switch]$ResolveModulePaths,

        [Parameter(Mandatory = $false)]
        [switch]$Recurse
    )

    # Initialiser la liste des dÃ©pendances
    $dependencies = [System.Collections.ArrayList]::new()

    # Initialiser la liste des fonctions dÃ©finies dans le module
    $definedFunctions = [System.Collections.ArrayList]::new()

    # VÃ©rifier si le chemin existe
    if (-not (Test-Path -Path $ModulePath)) {
        Write-Warning "Path does not exist: $ModulePath"
        return $dependencies
    }

    # DÃ©terminer les fichiers Ã  analyser
    $filesToAnalyze = @()
    if (Test-Path -Path $ModulePath -PathType Leaf) {
        # C'est un fichier unique
        $filesToAnalyze += Get-Item -Path $ModulePath
    } else {
        # C'est un rÃ©pertoire
        $filter = "*.ps1", "*.psm1", "*.psd1"
        $filesToAnalyze += Get-ChildItem -Path $ModulePath -Include $filter -File -Recurse:$Recurse
    }

    # PremiÃ¨re passe : collecter toutes les fonctions dÃ©finies dans le module
    foreach ($file in $filesToAnalyze) {
        Write-Verbose "Collecting defined functions in file: $($file.FullName)"

        try {
            $content = Get-Content -Path $file.FullName -Raw -ErrorAction Stop

            # DÃ©tecter les dÃ©finitions de fonctions
            # Format: function Nom-Fonction { ... }
            $functionMatches = [regex]::Matches($content, '(?m)^\s*function\s+([A-Za-z0-9\-_]+)')

            foreach ($match in $functionMatches) {
                $functionName = $match.Groups[1].Value
                [void]$definedFunctions.Add($functionName)
            }
        } catch {
            Write-Warning "Error reading file $($file.FullName): $_"
            continue
        }
    }

    # DeuxiÃ¨me passe : dÃ©tecter les appels Ã  des fonctions externes
    foreach ($file in $filesToAnalyze) {
        Write-Verbose "Analyzing external function calls in file: $($file.FullName)"

        try {
            $content = Get-Content -Path $file.FullName -Raw -ErrorAction Stop

            # DÃ©tecter les appels de fonctions
            # Format 1: Nom-Fonction -Param1 Value1
            # Format 2: Nom-Fonction
            $functionCallMatches = [regex]::Matches($content, '(?m)(?<!function\s+)([A-Za-z0-9\-_]+)(?:\s+|\s*\()')

            foreach ($match in $functionCallMatches) {
                $functionName = $match.Groups[1].Value

                # Ignorer les fonctions dÃ©finies dans le module
                if ($definedFunctions -contains $functionName) {
                    continue
                }

                # Ignorer les mots-clÃ©s PowerShell et les structures de contrÃ´le
                $powershellKeywords = @(
                    'if', 'else', 'elseif', 'switch', 'while', 'do', 'for', 'foreach', 'return',
                    'break', 'continue', 'try', 'catch', 'finally', 'throw', 'param', 'begin',
                    'process', 'end', 'dynamicparam', 'filter', 'class', 'enum', 'using'
                )
                if ($powershellKeywords -contains $functionName.ToLower()) {
                    continue
                }

                # Ignorer les appels de mÃ©thodes (.Method())
                if ($content -match [regex]::Escape(".$functionName")) {
                    continue
                }

                # VÃ©rifier si la fonction est un cmdlet PowerShell
                $cmdlet = Get-Command -Name $functionName -CommandType Cmdlet -ErrorAction SilentlyContinue

                if ($cmdlet) {
                    $moduleName = $cmdlet.ModuleName

                    # Ignorer les modules systÃ¨me si demandÃ©
                    if ($SkipSystemModules -and (Test-SystemModule -ModuleName $moduleName)) {
                        Write-Verbose "System module ignored for function $functionName from module $moduleName"
                        continue
                    }

                    # VÃ©rifier si cette dÃ©pendance a dÃ©jÃ  Ã©tÃ© ajoutÃ©e
                    $existingDependency = $dependencies | Where-Object {
                        $_.Name -eq $moduleName -and $_.FunctionName -eq $functionName
                    }

                    if (-not $existingDependency) {
                        # RÃ©soudre le chemin du module si demandÃ©
                        $modulePath = $null
                        if ($ResolveModulePaths) {
                            $modulePath = Find-ModulePath -ModuleName $moduleName
                        }

                        # Ajouter la dÃ©pendance Ã  la liste
                        [void]$dependencies.Add([PSCustomObject]@{
                                Name         = $moduleName
                                FunctionName = $functionName
                                Version      = $cmdlet.Version
                                Path         = $modulePath
                                Type         = "ExternalFunction"
                                Source       = $file.FullName
                            })
                    }
                }
            }
        } catch {
            Write-Warning "Error analyzing file $($file.FullName): $_"
            continue
        }
    }

    return $dependencies
}

function Resolve-ExternalFunctionPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FunctionName,

        [Parameter(Mandatory = $false)]
        [string]$ModuleName
    )

    # Initialiser le rÃ©sultat
    $result = [PSCustomObject]@{
        FunctionName = $FunctionName
        ModuleName   = $null
        ModulePath   = $null
        CommandType  = $null
        HelpFile     = $null
        Definition   = $null
    }

    try {
        # Rechercher la commande
        $command = $null

        if ($ModuleName) {
            # Si le nom du module est spÃ©cifiÃ©, rechercher la commande dans ce module
            $command = Get-Command -Name $FunctionName -Module $ModuleName -ErrorAction SilentlyContinue
        } else {
            # Sinon, rechercher la commande dans tous les modules
            $command = Get-Command -Name $FunctionName -ErrorAction SilentlyContinue
        }

        if ($command) {
            # Remplir les informations sur la commande
            $result.ModuleName = $command.ModuleName
            $result.CommandType = $command.CommandType
            $result.Definition = $command.Definition

            # RÃ©cupÃ©rer le chemin du module
            if ($command.Module) {
                $result.ModulePath = $command.Module.Path
            } else {
                # Si le module n'est pas chargÃ©, essayer de le trouver
                $module = Get-Module -Name $command.ModuleName -ListAvailable | Select-Object -First 1
                if ($module) {
                    $result.ModulePath = $module.Path
                }
            }

            # RÃ©cupÃ©rer le fichier d'aide
            $help = Get-Help -Name $FunctionName -ErrorAction SilentlyContinue
            if ($help -and $help.HelpFile) {
                $result.HelpFile = $help.HelpFile
            }
        }
    } catch {
        Write-Warning "Error resolving path for function $FunctionName : $_"
    }

    return $result
}

# Variables globales pour le cache
$script:DependencyCache = @{
    Manifests         = @{}
    Code              = @{}
    ExternalFunctions = @{}
    FunctionPaths     = @{}
    FunctionCalls     = @{}
}

function Clear-DependencyCache {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("All", "Manifests", "Code", "ExternalFunctions", "FunctionPaths", "FunctionCalls")]
        [string]$CacheType = "All"
    )

    if ($CacheType -eq "All" -or $CacheType -eq "Manifests") {
        $script:DependencyCache.Manifests = @{}
        Write-Verbose "Manifests cache cleared"
    }

    if ($CacheType -eq "All" -or $CacheType -eq "Code") {
        $script:DependencyCache.Code = @{}
        Write-Verbose "Code cache cleared"
    }

    if ($CacheType -eq "All" -or $CacheType -eq "ExternalFunctions") {
        $script:DependencyCache.ExternalFunctions = @{}
        Write-Verbose "ExternalFunctions cache cleared"
    }

    if ($CacheType -eq "All" -or $CacheType -eq "FunctionPaths") {
        $script:DependencyCache.FunctionPaths = @{}
        Write-Verbose "FunctionPaths cache cleared"
    }

    if ($CacheType -eq "All" -or $CacheType -eq "FunctionCalls") {
        $script:DependencyCache.FunctionCalls = @{}
        Write-Verbose "FunctionCalls cache cleared"
    }
}

function Get-DependencyCache {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("All", "Manifests", "Code", "ExternalFunctions", "FunctionPaths", "FunctionCalls")]
        [string]$CacheType = "All"
    )

    $result = @{}

    if ($CacheType -eq "All" -or $CacheType -eq "Manifests") {
        $result.Manifests = $script:DependencyCache.Manifests
    }

    if ($CacheType -eq "All" -or $CacheType -eq "Code") {
        $result.Code = $script:DependencyCache.Code
    }

    if ($CacheType -eq "All" -or $CacheType -eq "ExternalFunctions") {
        $result.ExternalFunctions = $script:DependencyCache.ExternalFunctions
    }

    if ($CacheType -eq "All" -or $CacheType -eq "FunctionPaths") {
        $result.FunctionPaths = $script:DependencyCache.FunctionPaths
    }

    if ($CacheType -eq "All" -or $CacheType -eq "FunctionCalls") {
        $result.FunctionCalls = $script:DependencyCache.FunctionCalls
    }

    return $result
}

# Modifier les fonctions existantes pour utiliser le cache

# Modifier Get-ModuleDependenciesFromManifest pour utiliser le cache
$originalGetModuleDependenciesFromManifest = ${function:Get-ModuleDependenciesFromManifest}.ToString()
function Get-ModuleDependenciesFromManifest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ManifestPath,

        [Parameter(Mandatory = $false)]
        [switch]$SkipSystemModules,

        [Parameter(Mandatory = $false)]
        [switch]$ResolveModulePaths,

        [Parameter(Mandatory = $false)]
        [switch]$NoCache
    )

    # VÃ©rifier si le rÃ©sultat est dans le cache
    $cacheKey = "$ManifestPath|$SkipSystemModules|$ResolveModulePaths"
    if (-not $NoCache -and $script:DependencyCache.Manifests.ContainsKey($cacheKey)) {
        Write-Verbose "Using cached result for manifest: $ManifestPath"
        return $script:DependencyCache.Manifests[$cacheKey]
    }

    # Appeler la fonction originale
    $result = & ([ScriptBlock]::Create($originalGetModuleDependenciesFromManifest)) -ManifestPath $ManifestPath -SkipSystemModules:$SkipSystemModules -ResolveModulePaths:$ResolveModulePaths

    # Stocker le rÃ©sultat dans le cache
    if (-not $NoCache) {
        $script:DependencyCache.Manifests[$cacheKey] = $result
        Write-Verbose "Cached result for manifest: $ManifestPath"
    }

    return $result
}

# Modifier Get-ModuleDependenciesFromCode pour utiliser le cache
$originalGetModuleDependenciesFromCode = ${function:Get-ModuleDependenciesFromCode}.ToString()
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
        [switch]$Recurse,

        [Parameter(Mandatory = $false)]
        [switch]$NoCache
    )

    # VÃ©rifier si le rÃ©sultat est dans le cache
    $cacheKey = "$ModulePath|$SkipSystemModules|$ResolveModulePaths|$Recurse"
    if (-not $NoCache -and $script:DependencyCache.Code.ContainsKey($cacheKey)) {
        Write-Verbose "Using cached result for code: $ModulePath"
        return $script:DependencyCache.Code[$cacheKey]
    }

    # Appeler la fonction originale
    $result = & ([ScriptBlock]::Create($originalGetModuleDependenciesFromCode)) -ModulePath $ModulePath -SkipSystemModules:$SkipSystemModules -ResolveModulePaths:$ResolveModulePaths -Recurse:$Recurse

    # Stocker le rÃ©sultat dans le cache
    if (-not $NoCache) {
        $script:DependencyCache.Code[$cacheKey] = $result
        Write-Verbose "Cached result for code: $ModulePath"
    }

    return $result
}

# Modifier Get-ExternalFunctionDependencies pour utiliser le cache
$originalGetExternalFunctionDependencies = ${function:Get-ExternalFunctionDependencies}.ToString()
function Get-ExternalFunctionDependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModulePath,

        [Parameter(Mandatory = $false)]
        [switch]$SkipSystemModules,

        [Parameter(Mandatory = $false)]
        [switch]$ResolveModulePaths,

        [Parameter(Mandatory = $false)]
        [switch]$Recurse,

        [Parameter(Mandatory = $false)]
        [switch]$NoCache
    )

    # VÃ©rifier si le rÃ©sultat est dans le cache
    $cacheKey = "$ModulePath|$SkipSystemModules|$ResolveModulePaths|$Recurse"
    if (-not $NoCache -and $script:DependencyCache.ExternalFunctions.ContainsKey($cacheKey)) {
        Write-Verbose "Using cached result for external functions: $ModulePath"
        return $script:DependencyCache.ExternalFunctions[$cacheKey]
    }

    # Appeler la fonction originale
    $result = & ([ScriptBlock]::Create($originalGetExternalFunctionDependencies)) -ModulePath $ModulePath -SkipSystemModules:$SkipSystemModules -ResolveModulePaths:$ResolveModulePaths -Recurse:$Recurse

    # Stocker le rÃ©sultat dans le cache
    if (-not $NoCache) {
        $script:DependencyCache.ExternalFunctions[$cacheKey] = $result
        Write-Verbose "Cached result for external functions: $ModulePath"
    }

    return $result
}

# Modifier Resolve-ExternalFunctionPath pour utiliser le cache
$originalResolveExternalFunctionPath = ${function:Resolve-ExternalFunctionPath}.ToString()
function Resolve-ExternalFunctionPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FunctionName,

        [Parameter(Mandatory = $false)]
        [string]$ModuleName,

        [Parameter(Mandatory = $false)]
        [switch]$NoCache
    )

    # VÃ©rifier si le rÃ©sultat est dans le cache
    $cacheKey = "$FunctionName|$ModuleName"
    if (-not $NoCache -and $script:DependencyCache.FunctionPaths.ContainsKey($cacheKey)) {
        Write-Verbose "Using cached result for function path: $FunctionName"
        return $script:DependencyCache.FunctionPaths[$cacheKey]
    }

    # Appeler la fonction originale
    $result = & ([ScriptBlock]::Create($originalResolveExternalFunctionPath)) -FunctionName $FunctionName -ModuleName $ModuleName

    # Stocker le rÃ©sultat dans le cache
    if (-not $NoCache) {
        $script:DependencyCache.FunctionPaths[$cacheKey] = $result
        Write-Verbose "Cached result for function path: $FunctionName"
    }

    return $result
}

function Export-DependencyReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModulePath,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "CSV", "HTML", "JSON")]
        [string]$Format = "Text",

        [Parameter(Mandatory = $false)]
        [switch]$IncludeSystemModules,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeDetails,

        [Parameter(Mandatory = $false)]
        [switch]$Recurse,

        [Parameter(Mandatory = $false)]
        [switch]$NoCache
    )

    # VÃ©rifier si le chemin du module existe
    if (-not (Test-Path -Path $ModulePath)) {
        Write-Error "Module path does not exist: $ModulePath"
        return $false
    }

    # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
    $outputDir = [System.IO.Path]::GetDirectoryName($OutputPath)
    if (-not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }

    # Collecter les dÃ©pendances
    Write-Verbose "Collecting dependencies from manifests..."
    $manifestDependencies = @()
    if (Test-Path -Path $ModulePath -PathType Leaf) {
        if ([System.IO.Path]::GetExtension($ModulePath) -eq ".psd1") {
            $manifestDependencies = Get-ModuleDependenciesFromManifest -ManifestPath $ModulePath -SkipSystemModules:(-not $IncludeSystemModules) -NoCache:$NoCache
        }
    } else {
        $manifestFiles = Get-ChildItem -Path $ModulePath -Filter "*.psd1" -Recurse:$Recurse
        foreach ($manifestFile in $manifestFiles) {
            $manifestDependencies += Get-ModuleDependenciesFromManifest -ManifestPath $manifestFile.FullName -SkipSystemModules:(-not $IncludeSystemModules) -NoCache:$NoCache
        }
    }

    Write-Verbose "Collecting dependencies from code..."
    $codeDependencies = Get-ModuleDependenciesFromCode -ModulePath $ModulePath -SkipSystemModules:(-not $IncludeSystemModules) -Recurse:$Recurse -NoCache:$NoCache

    Write-Verbose "Collecting external function dependencies..."
    $externalFunctionDependencies = Get-ExternalFunctionDependencies -ModulePath $ModulePath -SkipSystemModules:(-not $IncludeSystemModules) -Recurse:$Recurse -NoCache:$NoCache

    # CrÃ©er un rapport consolidÃ©
    $report = [PSCustomObject]@{
        ModulePath                   = $ModulePath
        AnalysisDate                 = Get-Date
        ManifestDependencies         = $manifestDependencies
        CodeDependencies             = $codeDependencies
        ExternalFunctionDependencies = $externalFunctionDependencies
        Summary                      = [PSCustomObject]@{
            TotalDependencies                 = ($manifestDependencies.Count + $codeDependencies.Count + $externalFunctionDependencies.Count)
            ManifestDependenciesCount         = $manifestDependencies.Count
            CodeDependenciesCount             = $codeDependencies.Count
            ExternalFunctionDependenciesCount = $externalFunctionDependencies.Count
            UniqueModules                     = @($manifestDependencies.Name + $codeDependencies.Name + $externalFunctionDependencies.Name | Select-Object -Unique).Count
        }
    }

    # GÃ©nÃ©rer le rapport dans le format demandÃ©
    switch ($Format) {
        "Text" {
            $reportContent = @"
# Module Dependency Report
Module Path: $ModulePath
Analysis Date: $((Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))

## Summary
Total Dependencies: $($report.Summary.TotalDependencies)
Manifest Dependencies: $($report.Summary.ManifestDependenciesCount)
Code Dependencies: $($report.Summary.CodeDependenciesCount)
External Function Dependencies: $($report.Summary.ExternalFunctionDependenciesCount)
Unique Modules: $($report.Summary.UniqueModules)

## Manifest Dependencies
"@

            if ($manifestDependencies.Count -eq 0) {
                $reportContent += "No manifest dependencies found.`r`n"
            } else {
                foreach ($dependency in $manifestDependencies) {
                    $reportContent += "- $($dependency.Name) (Type: $($dependency.Type))"
                    if ($IncludeDetails) {
                        if ($dependency.Version) {
                            $reportContent += ", Version: $($dependency.Version)"
                        }
                        if ($dependency.Path) {
                            $reportContent += ", Path: $($dependency.Path)"
                        }
                        if ($dependency.Source) {
                            $reportContent += ", Source: $($dependency.Source)"
                        }
                    }
                    $reportContent += "`r`n"
                }
            }

            $reportContent += @"

## Code Dependencies
"@

            if ($codeDependencies.Count -eq 0) {
                $reportContent += "No code dependencies found.`r`n"
            } else {
                foreach ($dependency in $codeDependencies) {
                    $reportContent += "- $($dependency.Name) (Type: $($dependency.Type))"
                    if ($IncludeDetails) {
                        if ($dependency.Path) {
                            $reportContent += ", Path: $($dependency.Path)"
                        }
                        if ($dependency.Source) {
                            $reportContent += ", Source: $($dependency.Source)"
                        }
                    }
                    $reportContent += "`r`n"
                }
            }

            $reportContent += @"

## External Function Dependencies
"@

            if ($externalFunctionDependencies.Count -eq 0) {
                $reportContent += "No external function dependencies found.`r`n"
            } else {
                foreach ($dependency in $externalFunctionDependencies) {
                    $reportContent += "- $($dependency.FunctionName) from $($dependency.Name) (Type: $($dependency.Type))"
                    if ($IncludeDetails) {
                        if ($dependency.Version) {
                            $reportContent += ", Version: $($dependency.Version)"
                        }
                        if ($dependency.Path) {
                            $reportContent += ", Path: $($dependency.Path)"
                        }
                        if ($dependency.Source) {
                            $reportContent += ", Source: $($dependency.Source)"
                        }
                    }
                    $reportContent += "`r`n"
                }
            }

            # Ã‰crire le rapport dans un fichier texte
            $reportContent | Out-File -FilePath $OutputPath -Encoding UTF8
        }

        "CSV" {
            # CrÃ©er un tableau pour le CSV
            $csvData = @()

            # Ajouter les dÃ©pendances de manifeste
            foreach ($dependency in $manifestDependencies) {
                $csvData += [PSCustomObject]@{
                    DependencyType = "Manifest"
                    Name           = $dependency.Name
                    Version        = $dependency.Version
                    Path           = $dependency.Path
                    Type           = $dependency.Type
                    Source         = $dependency.Source
                    FunctionName   = $null
                }
            }

            # Ajouter les dÃ©pendances de code
            foreach ($dependency in $codeDependencies) {
                $csvData += [PSCustomObject]@{
                    DependencyType = "Code"
                    Name           = $dependency.Name
                    Version        = $null
                    Path           = $dependency.Path
                    Type           = $dependency.Type
                    Source         = $dependency.Source
                    FunctionName   = $null
                }
            }

            # Ajouter les dÃ©pendances de fonctions externes
            foreach ($dependency in $externalFunctionDependencies) {
                $csvData += [PSCustomObject]@{
                    DependencyType = "ExternalFunction"
                    Name           = $dependency.Name
                    Version        = $dependency.Version
                    Path           = $dependency.Path
                    Type           = $dependency.Type
                    Source         = $dependency.Source
                    FunctionName   = $dependency.FunctionName
                }
            }

            # Exporter les donnÃ©es au format CSV
            $csvData | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
        }

        "HTML" {
            $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Module Dependency Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2 { color: #333; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .summary { background-color: #e6f7ff; padding: 10px; border-radius: 5px; margin-bottom: 20px; }
    </style>
</head>
<body>
    <h1>Module Dependency Report</h1>
    <p><strong>Module Path:</strong> $ModulePath</p>
    <p><strong>Analysis Date:</strong> $((Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))</p>

    <div class="summary">
        <h2>Summary</h2>
        <p><strong>Total Dependencies:</strong> $($report.Summary.TotalDependencies)</p>
        <p><strong>Manifest Dependencies:</strong> $($report.Summary.ManifestDependenciesCount)</p>
        <p><strong>Code Dependencies:</strong> $($report.Summary.CodeDependenciesCount)</p>
        <p><strong>External Function Dependencies:</strong> $($report.Summary.ExternalFunctionDependenciesCount)</p>
        <p><strong>Unique Modules:</strong> $($report.Summary.UniqueModules)</p>
    </div>

    <h2>Manifest Dependencies</h2>
"@

            if ($manifestDependencies.Count -eq 0) {
                $htmlContent += "<p>No manifest dependencies found.</p>"
            } else {
                $htmlContent += @"
    <table>
        <tr>
            <th>Name</th>
            <th>Type</th>
"@
                if ($IncludeDetails) {
                    $htmlContent += @"
            <th>Version</th>
            <th>Path</th>
            <th>Source</th>
"@
                }
                $htmlContent += @"
        </tr>
"@

                foreach ($dependency in $manifestDependencies) {
                    $htmlContent += @"
        <tr>
            <td>$($dependency.Name)</td>
            <td>$($dependency.Type)</td>
"@
                    if ($IncludeDetails) {
                        $htmlContent += @"
            <td>$($dependency.Version)</td>
            <td>$($dependency.Path)</td>
            <td>$($dependency.Source)</td>
"@
                    }
                    $htmlContent += @"
        </tr>
"@
                }

                $htmlContent += @"
    </table>
"@
            }

            $htmlContent += @"

    <h2>Code Dependencies</h2>
"@

            if ($codeDependencies.Count -eq 0) {
                $htmlContent += "<p>No code dependencies found.</p>"
            } else {
                $htmlContent += @"
    <table>
        <tr>
            <th>Name</th>
            <th>Type</th>
"@
                if ($IncludeDetails) {
                    $htmlContent += @"
            <th>Path</th>
            <th>Source</th>
"@
                }
                $htmlContent += @"
        </tr>
"@

                foreach ($dependency in $codeDependencies) {
                    $htmlContent += @"
        <tr>
            <td>$($dependency.Name)</td>
            <td>$($dependency.Type)</td>
"@
                    if ($IncludeDetails) {
                        $htmlContent += @"
            <td>$($dependency.Path)</td>
            <td>$($dependency.Source)</td>
"@
                    }
                    $htmlContent += @"
        </tr>
"@
                }

                $htmlContent += @"
    </table>
"@
            }

            $htmlContent += @"

    <h2>External Function Dependencies</h2>
"@

            if ($externalFunctionDependencies.Count -eq 0) {
                $htmlContent += "<p>No external function dependencies found.</p>"
            } else {
                $htmlContent += @"
    <table>
        <tr>
            <th>Function Name</th>
            <th>Module</th>
            <th>Type</th>
"@
                if ($IncludeDetails) {
                    $htmlContent += @"
            <th>Version</th>
            <th>Path</th>
            <th>Source</th>
"@
                }
                $htmlContent += @"
        </tr>
"@

                foreach ($dependency in $externalFunctionDependencies) {
                    $htmlContent += @"
        <tr>
            <td>$($dependency.FunctionName)</td>
            <td>$($dependency.Name)</td>
            <td>$($dependency.Type)</td>
"@
                    if ($IncludeDetails) {
                        $htmlContent += @"
            <td>$($dependency.Version)</td>
            <td>$($dependency.Path)</td>
            <td>$($dependency.Source)</td>
"@
                    }
                    $htmlContent += @"
        </tr>
"@
                }

                $htmlContent += @"
    </table>
"@
            }

            $htmlContent += @"
</body>
</html>
"@

            # Ã‰crire le rapport dans un fichier HTML
            $htmlContent | Out-File -FilePath $OutputPath -Encoding UTF8
        }

        "JSON" {
            # Convertir le rapport en JSON
            $jsonContent = $report | ConvertTo-Json -Depth 10

            # Ã‰crire le rapport dans un fichier JSON
            $jsonContent | Out-File -FilePath $OutputPath -Encoding UTF8
        }
    }

    Write-Verbose "Dependency report exported to: $OutputPath"
    return $true
}

function Get-CompleteDependencyAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModulePath,

        [Parameter(Mandatory = $false)]
        [switch]$SkipSystemModules,

        [Parameter(Mandatory = $false)]
        [switch]$ResolveModulePaths,

        [Parameter(Mandatory = $false)]
        [switch]$Recurse,

        [Parameter(Mandatory = $false)]
        [switch]$NoCache,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeDetails
    )

    # VÃ©rifier si le chemin du module existe
    if (-not (Test-Path -Path $ModulePath)) {
        Write-Error "Module path does not exist: $ModulePath"
        return $null
    }

    # Collecter les dÃ©pendances
    Write-Verbose "Collecting dependencies from manifests..."
    $manifestDependencies = @()
    if (Test-Path -Path $ModulePath -PathType Leaf) {
        if ([System.IO.Path]::GetExtension($ModulePath) -eq ".psd1") {
            $manifestDependencies = Get-ModuleDependenciesFromManifest -ManifestPath $ModulePath -SkipSystemModules:$SkipSystemModules -ResolveModulePaths:$ResolveModulePaths -NoCache:$NoCache
        }
    } else {
        $manifestFiles = Get-ChildItem -Path $ModulePath -Filter "*.psd1" -Recurse:$Recurse
        foreach ($manifestFile in $manifestFiles) {
            $manifestDependencies += Get-ModuleDependenciesFromManifest -ManifestPath $manifestFile.FullName -SkipSystemModules:$SkipSystemModules -ResolveModulePaths:$ResolveModulePaths -NoCache:$NoCache
        }
    }

    Write-Verbose "Collecting dependencies from code..."
    $codeDependencies = Get-ModuleDependenciesFromCode -ModulePath $ModulePath -SkipSystemModules:$SkipSystemModules -ResolveModulePaths:$ResolveModulePaths -Recurse:$Recurse -NoCache:$NoCache

    Write-Verbose "Collecting external function dependencies..."
    $externalFunctionDependencies = Get-ExternalFunctionDependencies -ModulePath $ModulePath -SkipSystemModules:$SkipSystemModules -ResolveModulePaths:$ResolveModulePaths -Recurse:$Recurse -NoCache:$NoCache

    # CrÃ©er un rapport consolidÃ©
    $result = [PSCustomObject]@{
        ModulePath                   = $ModulePath
        AnalysisDate                 = Get-Date
        ManifestDependencies         = $manifestDependencies
        CodeDependencies             = $codeDependencies
        ExternalFunctionDependencies = $externalFunctionDependencies
        Summary                      = [PSCustomObject]@{
            TotalDependencies                 = ($manifestDependencies.Count + $codeDependencies.Count + $externalFunctionDependencies.Count)
            ManifestDependenciesCount         = $manifestDependencies.Count
            CodeDependenciesCount             = $codeDependencies.Count
            ExternalFunctionDependenciesCount = $externalFunctionDependencies.Count
            UniqueModules                     = @($manifestDependencies.Name + $codeDependencies.Name + $externalFunctionDependencies.Name | Select-Object -Unique).Count
        }
    }

    # Si IncludeDetails est spÃ©cifiÃ©, ajouter des informations supplÃ©mentaires
    if ($IncludeDetails) {
        # Ajouter des informations sur les modules
        $uniqueModules = @($manifestDependencies.Name + $codeDependencies.Name + $externalFunctionDependencies.Name | Select-Object -Unique)
        $moduleDetails = @()

        foreach ($moduleName in $uniqueModules) {
            if ($null -eq $moduleName) {
                continue
            }

            $moduleInfo = $null
            try {
                $moduleInfo = Get-Module -Name $moduleName -ListAvailable | Select-Object -First 1
            } catch {
                Write-Verbose "Error getting module info for $moduleName : $_"
            }

            if ($moduleInfo) {
                $moduleDetails += [PSCustomObject]@{
                    Name        = $moduleName
                    Version     = $moduleInfo.Version
                    Path        = $moduleInfo.Path
                    Description = $moduleInfo.Description
                    Author      = $moduleInfo.Author
                    CompanyName = $moduleInfo.CompanyName
                    GUID        = $moduleInfo.Guid
                }
            } else {
                $moduleDetails += [PSCustomObject]@{
                    Name        = $moduleName
                    Version     = $null
                    Path        = $null
                    Description = $null
                    Author      = $null
                    CompanyName = $null
                    GUID        = $null
                }
            }
        }

        $result | Add-Member -MemberType NoteProperty -Name "ModuleDetails" -Value $moduleDetails
    }

    return $result
}

function ConvertTo-ModuleDependencyDetectorFormat {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$DependencyAnalysis,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Simple", "Detailed")]
        [string]$Format = "Simple"
    )

    # VÃ©rifier que l'objet d'entrÃ©e est valide
    if (-not $DependencyAnalysis -or -not $DependencyAnalysis.ModulePath) {
        Write-Error "Invalid dependency analysis object"
        return $null
    }

    # CrÃ©er un objet au format ModuleDependencyDetector
    $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($DependencyAnalysis.ModulePath)

    # Collecter toutes les dÃ©pendances
    $allDependencies = @()

    # Ajouter les dÃ©pendances de manifeste
    foreach ($dependency in $DependencyAnalysis.ManifestDependencies) {
        if ($null -eq $dependency.Name) {
            continue
        }

        $dependencyObject = [PSCustomObject]@{
            Name         = $dependency.Name
            Version      = $dependency.Version
            Type         = "Manifest"
            Source       = $dependency.Source
            DependencyOf = $moduleName
        }

        if ($Format -eq "Detailed") {
            $dependencyObject | Add-Member -MemberType NoteProperty -Name "Path" -Value $dependency.Path
            $dependencyObject | Add-Member -MemberType NoteProperty -Name "GUID" -Value $dependency.GUID
            $dependencyObject | Add-Member -MemberType NoteProperty -Name "DependencyType" -Value $dependency.Type
        }

        $allDependencies += $dependencyObject
    }

    # Ajouter les dÃ©pendances de code
    foreach ($dependency in $DependencyAnalysis.CodeDependencies) {
        if ($null -eq $dependency.Name) {
            continue
        }

        $dependencyObject = [PSCustomObject]@{
            Name         = $dependency.Name
            Version      = $null
            Type         = "Code"
            Source       = $dependency.Source
            DependencyOf = $moduleName
        }

        if ($Format -eq "Detailed") {
            $dependencyObject | Add-Member -MemberType NoteProperty -Name "Path" -Value $dependency.Path
            $dependencyObject | Add-Member -MemberType NoteProperty -Name "DependencyType" -Value $dependency.Type
        }

        $allDependencies += $dependencyObject
    }

    # Ajouter les dÃ©pendances de fonctions externes
    foreach ($dependency in $DependencyAnalysis.ExternalFunctionDependencies) {
        if ($null -eq $dependency.Name) {
            continue
        }

        $dependencyObject = [PSCustomObject]@{
            Name         = $dependency.Name
            Version      = $dependency.Version
            Type         = "ExternalFunction"
            Source       = $dependency.Source
            DependencyOf = $moduleName
        }

        if ($Format -eq "Detailed") {
            $dependencyObject | Add-Member -MemberType NoteProperty -Name "Path" -Value $dependency.Path
            $dependencyObject | Add-Member -MemberType NoteProperty -Name "FunctionName" -Value $dependency.FunctionName
            $dependencyObject | Add-Member -MemberType NoteProperty -Name "DependencyType" -Value $dependency.Type
        }

        $allDependencies += $dependencyObject
    }

    # CrÃ©er l'objet rÃ©sultat
    $result = [PSCustomObject]@{
        ModuleName    = $moduleName
        ModulePath    = $DependencyAnalysis.ModulePath
        AnalysisDate  = $DependencyAnalysis.AnalysisDate
        Dependencies  = $allDependencies
        DependencyMap = @{}
    }

    # CrÃ©er la carte des dÃ©pendances
    $dependencyMap = @{}
    foreach ($dependency in $allDependencies) {
        if (-not $dependencyMap.ContainsKey($dependency.Name)) {
            $dependencyMap[$dependency.Name] = @()
        }
        $dependencyMap[$dependency.Name] += $moduleName
    }
    $result.DependencyMap = $dependencyMap

    return $result
}

function Invoke-ModuleDependencyDetector {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModulePath,

        [Parameter(Mandatory = $false)]
        [switch]$SkipSystemModules,

        [Parameter(Mandatory = $false)]
        [switch]$ResolveModulePaths,

        [Parameter(Mandatory = $false)]
        [switch]$Recurse,

        [Parameter(Mandatory = $false)]
        [switch]$NoCache,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Simple", "Detailed")]
        [string]$Format = "Simple",

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "CSV", "HTML", "JSON")]
        [string]$OutputFormat = "Text"
    )

    # VÃ©rifier si le module ModuleDependencyDetector est disponible
    $moduleDependencyDetector = Get-Module -Name ModuleDependencyDetector -ListAvailable

    if ($moduleDependencyDetector) {
        Write-Verbose "ModuleDependencyDetector module found, using it directly"

        # Importer le module
        Import-Module -Name ModuleDependencyDetector -Force

        # Appeler la fonction du module
        $result = & "Get-ModuleDependencies" -Path $ModulePath -Recurse:$Recurse

        # Exporter le rÃ©sultat si demandÃ©
        if ($OutputPath) {
            switch ($OutputFormat) {
                "Text" {
                    $result | Out-File -FilePath $OutputPath -Encoding UTF8
                }
                "CSV" {
                    $result | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
                }
                "HTML" {
                    $result | ConvertTo-Html -Title "Module Dependencies" | Out-File -FilePath $OutputPath -Encoding UTF8
                }
                "JSON" {
                    $result | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
                }
            }
        }

        return $result
    } else {
        Write-Verbose "ModuleDependencyDetector module not found, using our implementation"

        # Utiliser notre implÃ©mentation
        $analysis = Get-CompleteDependencyAnalysis -ModulePath $ModulePath -SkipSystemModules:$SkipSystemModules -ResolveModulePaths:$ResolveModulePaths -Recurse:$Recurse -NoCache:$NoCache -IncludeDetails:($Format -eq "Detailed")

        # Convertir au format ModuleDependencyDetector
        $result = ConvertTo-ModuleDependencyDetectorFormat -DependencyAnalysis $analysis -Format $Format

        # Exporter le rÃ©sultat si demandÃ©
        if ($OutputPath) {
            switch ($OutputFormat) {
                "Text" {
                    $result | Out-File -FilePath $OutputPath -Encoding UTF8
                }
                "CSV" {
                    $result.Dependencies | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
                }
                "HTML" {
                    $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Module Dependencies</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2 { color: #333; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .summary { background-color: #e6f7ff; padding: 10px; border-radius: 5px; margin-bottom: 20px; }
    </style>
</head>
<body>
    <h1>Module Dependencies</h1>
    <p><strong>Module Name:</strong> $($result.ModuleName)</p>
    <p><strong>Module Path:</strong> $($result.ModulePath)</p>
    <p><strong>Analysis Date:</strong> $($result.AnalysisDate)</p>

    <h2>Dependencies</h2>
    <table>
        <tr>
            <th>Name</th>
            <th>Version</th>
            <th>Type</th>
            <th>Source</th>
            <th>DependencyOf</th>
"@

                    if ($Format -eq "Detailed") {
                        $htmlContent += @"
            <th>Path</th>
            <th>DependencyType</th>
"@
                    }

                    $htmlContent += @"
        </tr>
"@

                    foreach ($dependency in $result.Dependencies) {
                        $htmlContent += @"
        <tr>
            <td>$($dependency.Name)</td>
            <td>$($dependency.Version)</td>
            <td>$($dependency.Type)</td>
            <td>$($dependency.Source)</td>
            <td>$($dependency.DependencyOf)</td>
"@

                        if ($Format -eq "Detailed") {
                            $htmlContent += @"
            <td>$($dependency.Path)</td>
            <td>$($dependency.DependencyType)</td>
"@
                        }

                        $htmlContent += @"
        </tr>
"@
                    }

                    $htmlContent += @"
    </table>
</body>
</html>
"@

                    $htmlContent | Out-File -FilePath $OutputPath -Encoding UTF8
                }
                "JSON" {
                    $result | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
                }
            }
        }

        return $result
    }
}

function Get-ModuleDependencies {
    [CmdletBinding(DefaultParameterSetName = "Path")]
    param (
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "Path")]
        [string]$Path,

        [Parameter(Mandatory = $true, ParameterSetName = "Module")]
        [string]$ModuleName,

        [Parameter(Mandatory = $false, ParameterSetName = "Module")]
        [string]$ModuleVersion,

        [Parameter(Mandatory = $false)]
        [ValidateSet("All", "Manifest", "Code", "ExternalFunction")]
        [string[]]$DependencyTypes = @("All"),

        [Parameter(Mandatory = $false)]
        [switch]$SkipSystemModules,

        [Parameter(Mandatory = $false)]
        [switch]$ResolveModulePaths,

        [Parameter(Mandatory = $false)]
        [switch]$Recurse,

        [Parameter(Mandatory = $false)]
        [switch]$NoCache,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeDetails,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "CSV", "HTML", "JSON")]
        [string]$OutputFormat = "Text"
    )

    # DÃ©terminer le chemin du module
    $modulePath = $null

    if ($PSCmdlet.ParameterSetName -eq "Module") {
        # Rechercher le module par nom
        Write-Verbose "Searching for module: $ModuleName"

        if ($ModuleVersion) {
            $modulePath = Find-ModulePath -ModuleName $ModuleName -ModuleVersion $ModuleVersion
        } else {
            $modulePath = Find-ModulePath -ModuleName $ModuleName
        }

        if (-not $modulePath) {
            Write-Error "Module not found: $ModuleName"
            return $null
        }

        Write-Verbose "Module found at: $modulePath"
    } else {
        # Utiliser le chemin spÃ©cifiÃ©
        $modulePath = $Path

        if (-not (Test-Path -Path $modulePath)) {
            Write-Error "Path not found: $modulePath"
            return $null
        }
    }

    # Collecter les dÃ©pendances en fonction des types demandÃ©s
    $manifestDependencies = @()
    $codeDependencies = @()
    $externalFunctionDependencies = @()

    if ($DependencyTypes -contains "All" -or $DependencyTypes -contains "Manifest") {
        Write-Verbose "Collecting dependencies from manifests..."

        if (Test-Path -Path $modulePath -PathType Leaf) {
            if ([System.IO.Path]::GetExtension($modulePath) -eq ".psd1") {
                $manifestDependencies = Get-ModuleDependenciesFromManifest -ManifestPath $modulePath -SkipSystemModules:$SkipSystemModules -ResolveModulePaths:$ResolveModulePaths -NoCache:$NoCache
            }
        } else {
            $manifestFiles = Get-ChildItem -Path $modulePath -Filter "*.psd1" -Recurse:$Recurse
            foreach ($manifestFile in $manifestFiles) {
                $manifestDependencies += Get-ModuleDependenciesFromManifest -ManifestPath $manifestFile.FullName -SkipSystemModules:$SkipSystemModules -ResolveModulePaths:$ResolveModulePaths -NoCache:$NoCache
            }
        }
    }

    if ($DependencyTypes -contains "All" -or $DependencyTypes -contains "Code") {
        Write-Verbose "Collecting dependencies from code..."
        $codeDependencies = Get-ModuleDependenciesFromCode -ModulePath $modulePath -SkipSystemModules:$SkipSystemModules -ResolveModulePaths:$ResolveModulePaths -Recurse:$Recurse -NoCache:$NoCache
    }

    if ($DependencyTypes -contains "All" -or $DependencyTypes -contains "ExternalFunction") {
        Write-Verbose "Collecting external function dependencies..."
        $externalFunctionDependencies = Get-ExternalFunctionDependencies -ModulePath $modulePath -SkipSystemModules:$SkipSystemModules -ResolveModulePaths:$ResolveModulePaths -Recurse:$Recurse -NoCache:$NoCache
    }

    # CrÃ©er un rapport consolidÃ©
    $result = [PSCustomObject]@{
        ModulePath                   = $modulePath
        ModuleName                   = [System.IO.Path]::GetFileNameWithoutExtension($modulePath)
        AnalysisDate                 = Get-Date
        ManifestDependencies         = $manifestDependencies
        CodeDependencies             = $codeDependencies
        ExternalFunctionDependencies = $externalFunctionDependencies
        Summary                      = [PSCustomObject]@{
            TotalDependencies                 = ($manifestDependencies.Count + $codeDependencies.Count + $externalFunctionDependencies.Count)
            ManifestDependenciesCount         = $manifestDependencies.Count
            CodeDependenciesCount             = $codeDependencies.Count
            ExternalFunctionDependenciesCount = $externalFunctionDependencies.Count
            UniqueModules                     = @($manifestDependencies.Name + $codeDependencies.Name + $externalFunctionDependencies.Name | Select-Object -Unique).Count
        }
    }

    # Si IncludeDetails est spÃ©cifiÃ©, ajouter des informations supplÃ©mentaires
    if ($IncludeDetails) {
        # Ajouter des informations sur les modules
        $uniqueModules = @($manifestDependencies.Name + $codeDependencies.Name + $externalFunctionDependencies.Name | Select-Object -Unique)
        $moduleDetails = @()

        foreach ($moduleName in $uniqueModules) {
            if ($null -eq $moduleName) {
                continue
            }

            $moduleInfo = $null
            try {
                $moduleInfo = Get-Module -Name $moduleName -ListAvailable | Select-Object -First 1
            } catch {
                Write-Verbose "Error getting module info for $moduleName : $_"
            }

            if ($moduleInfo) {
                $moduleDetails += [PSCustomObject]@{
                    Name        = $moduleName
                    Version     = $moduleInfo.Version
                    Path        = $moduleInfo.Path
                    Description = $moduleInfo.Description
                    Author      = $moduleInfo.Author
                    CompanyName = $moduleInfo.CompanyName
                    GUID        = $moduleInfo.Guid
                }
            } else {
                $moduleDetails += [PSCustomObject]@{
                    Name        = $moduleName
                    Version     = $null
                    Path        = $null
                    Description = $null
                    Author      = $null
                    CompanyName = $null
                    GUID        = $null
                }
            }
        }

        $result | Add-Member -MemberType NoteProperty -Name "ModuleDetails" -Value $moduleDetails
    }

    # Exporter le rÃ©sultat si demandÃ©
    if ($OutputPath) {
        switch ($OutputFormat) {
            "Text" {
                $textContent = @"
# Module Dependency Report
Module Path: $($result.ModulePath)
Module Name: $($result.ModuleName)
Analysis Date: $((Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))

## Summary
Total Dependencies: $($result.Summary.TotalDependencies)
Manifest Dependencies: $($result.Summary.ManifestDependenciesCount)
Code Dependencies: $($result.Summary.CodeDependenciesCount)
External Function Dependencies: $($result.Summary.ExternalFunctionDependenciesCount)
Unique Modules: $($result.Summary.UniqueModules)

## Manifest Dependencies
"@

                if ($manifestDependencies.Count -eq 0) {
                    $textContent += "No manifest dependencies found.`r`n"
                } else {
                    foreach ($dependency in $manifestDependencies) {
                        $textContent += "- $($dependency.Name) (Type: $($dependency.Type))"
                        if ($IncludeDetails) {
                            if ($dependency.Version) {
                                $textContent += ", Version: $($dependency.Version)"
                            }
                            if ($dependency.Path) {
                                $textContent += ", Path: $($dependency.Path)"
                            }
                            if ($dependency.Source) {
                                $textContent += ", Source: $($dependency.Source)"
                            }
                        }
                        $textContent += "`r`n"
                    }
                }

                $textContent += @"

## Code Dependencies
"@

                if ($codeDependencies.Count -eq 0) {
                    $textContent += "No code dependencies found.`r`n"
                } else {
                    foreach ($dependency in $codeDependencies) {
                        $textContent += "- $($dependency.Name) (Type: $($dependency.Type))"
                        if ($IncludeDetails) {
                            if ($dependency.Path) {
                                $textContent += ", Path: $($dependency.Path)"
                            }
                            if ($dependency.Source) {
                                $textContent += ", Source: $($dependency.Source)"
                            }
                        }
                        $textContent += "`r`n"
                    }
                }

                $textContent += @"

## External Function Dependencies
"@

                if ($externalFunctionDependencies.Count -eq 0) {
                    $textContent += "No external function dependencies found.`r`n"
                } else {
                    foreach ($dependency in $externalFunctionDependencies) {
                        $textContent += "- $($dependency.FunctionName) from $($dependency.Name) (Type: $($dependency.Type))"
                        if ($IncludeDetails) {
                            if ($dependency.Version) {
                                $textContent += ", Version: $($dependency.Version)"
                            }
                            if ($dependency.Path) {
                                $textContent += ", Path: $($dependency.Path)"
                            }
                            if ($dependency.Source) {
                                $textContent += ", Source: $($dependency.Source)"
                            }
                        }
                        $textContent += "`r`n"
                    }
                }

                $textContent | Out-File -FilePath $OutputPath -Encoding UTF8
            }

            "CSV" {
                # CrÃ©er un tableau pour le CSV
                $csvData = @()

                # Ajouter les dÃ©pendances de manifeste
                foreach ($dependency in $manifestDependencies) {
                    $csvData += [PSCustomObject]@{
                        DependencyType = "Manifest"
                        Name           = $dependency.Name
                        Version        = $dependency.Version
                        Path           = $dependency.Path
                        Type           = $dependency.Type
                        Source         = $dependency.Source
                        FunctionName   = $null
                        ModuleName     = $result.ModuleName
                    }
                }

                # Ajouter les dÃ©pendances de code
                foreach ($dependency in $codeDependencies) {
                    $csvData += [PSCustomObject]@{
                        DependencyType = "Code"
                        Name           = $dependency.Name
                        Version        = $null
                        Path           = $dependency.Path
                        Type           = $dependency.Type
                        Source         = $dependency.Source
                        FunctionName   = $null
                        ModuleName     = $result.ModuleName
                    }
                }

                # Ajouter les dÃ©pendances de fonctions externes
                foreach ($dependency in $externalFunctionDependencies) {
                    $csvData += [PSCustomObject]@{
                        DependencyType = "ExternalFunction"
                        Name           = $dependency.Name
                        Version        = $dependency.Version
                        Path           = $dependency.Path
                        Type           = $dependency.Type
                        Source         = $dependency.Source
                        FunctionName   = $dependency.FunctionName
                        ModuleName     = $result.ModuleName
                    }
                }

                $csvData | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
            }

            "HTML" {
                $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Module Dependency Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2 { color: #333; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .summary { background-color: #e6f7ff; padding: 10px; border-radius: 5px; margin-bottom: 20px; }
    </style>
</head>
<body>
    <h1>Module Dependency Report</h1>
    <p><strong>Module Path:</strong> $($result.ModulePath)</p>
    <p><strong>Module Name:</strong> $($result.ModuleName)</p>
    <p><strong>Analysis Date:</strong> $((Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))</p>

    <div class="summary">
        <h2>Summary</h2>
        <p><strong>Total Dependencies:</strong> $($result.Summary.TotalDependencies)</p>
        <p><strong>Manifest Dependencies:</strong> $($result.Summary.ManifestDependenciesCount)</p>
        <p><strong>Code Dependencies:</strong> $($result.Summary.CodeDependenciesCount)</p>
        <p><strong>External Function Dependencies:</strong> $($result.Summary.ExternalFunctionDependenciesCount)</p>
        <p><strong>Unique Modules:</strong> $($result.Summary.UniqueModules)</p>
    </div>

    <h2>Manifest Dependencies</h2>
"@

                if ($manifestDependencies.Count -eq 0) {
                    $htmlContent += "<p>No manifest dependencies found.</p>"
                } else {
                    $htmlContent += @"
    <table>
        <tr>
            <th>Name</th>
            <th>Type</th>
"@
                    if ($IncludeDetails) {
                        $htmlContent += @"
            <th>Version</th>
            <th>Path</th>
            <th>Source</th>
"@
                    }
                    $htmlContent += @"
        </tr>
"@

                    foreach ($dependency in $manifestDependencies) {
                        $htmlContent += @"
        <tr>
            <td>$($dependency.Name)</td>
            <td>$($dependency.Type)</td>
"@
                        if ($IncludeDetails) {
                            $htmlContent += @"
            <td>$($dependency.Version)</td>
            <td>$($dependency.Path)</td>
            <td>$($dependency.Source)</td>
"@
                        }
                        $htmlContent += @"
        </tr>
"@
                    }

                    $htmlContent += @"
    </table>
"@
                }

                $htmlContent += @"

    <h2>Code Dependencies</h2>
"@

                if ($codeDependencies.Count -eq 0) {
                    $htmlContent += "<p>No code dependencies found.</p>"
                } else {
                    $htmlContent += @"
    <table>
        <tr>
            <th>Name</th>
            <th>Type</th>
"@
                    if ($IncludeDetails) {
                        $htmlContent += @"
            <th>Path</th>
            <th>Source</th>
"@
                    }
                    $htmlContent += @"
        </tr>
"@

                    foreach ($dependency in $codeDependencies) {
                        $htmlContent += @"
        <tr>
            <td>$($dependency.Name)</td>
            <td>$($dependency.Type)</td>
"@
                        if ($IncludeDetails) {
                            $htmlContent += @"
            <td>$($dependency.Path)</td>
            <td>$($dependency.Source)</td>
"@
                        }
                        $htmlContent += @"
        </tr>
"@
                    }

                    $htmlContent += @"
    </table>
"@
                }

                $htmlContent += @"

    <h2>External Function Dependencies</h2>
"@

                if ($externalFunctionDependencies.Count -eq 0) {
                    $htmlContent += "<p>No external function dependencies found.</p>"
                } else {
                    $htmlContent += @"
    <table>
        <tr>
            <th>Function Name</th>
            <th>Module</th>
            <th>Type</th>
"@
                    if ($IncludeDetails) {
                        $htmlContent += @"
            <th>Version</th>
            <th>Path</th>
            <th>Source</th>
"@
                    }
                    $htmlContent += @"
        </tr>
"@

                    foreach ($dependency in $externalFunctionDependencies) {
                        $htmlContent += @"
        <tr>
            <td>$($dependency.FunctionName)</td>
            <td>$($dependency.Name)</td>
            <td>$($dependency.Type)</td>
"@
                        if ($IncludeDetails) {
                            $htmlContent += @"
            <td>$($dependency.Version)</td>
            <td>$($dependency.Path)</td>
            <td>$($dependency.Source)</td>
"@
                        }
                        $htmlContent += @"
        </tr>
"@
                    }

                    $htmlContent += @"
    </table>
"@
                }

                $htmlContent += @"
</body>
</html>
"@

                $htmlContent | Out-File -FilePath $OutputPath -Encoding UTF8
            }

            "JSON" {
                $result | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
            }
        }

        Write-Verbose "Dependency report exported to: $OutputPath"
    }

    return $result
}

function Get-FunctionUsageAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModulePath,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeSystemFunctions,

        [Parameter(Mandatory = $false)]
        [switch]$IncludePrivateFunctions,

        [Parameter(Mandatory = $false)]
        [switch]$Recurse,

        [Parameter(Mandatory = $false)]
        [switch]$NoCache
    )

    # Obtenir les appels de fonction
    $functionCalls = Get-FunctionCallDependencies -ModulePath $ModulePath -IncludeInternalCalls -IncludeExternalCalls -Recurse:$Recurse -NoCache:$NoCache

    # Collecter les fonctions dÃ©finies et appelÃ©es
    $definedFunctions = @{}
    $calledFunctions = @{}
    $exportedFunctions = @()

    # Analyser les fichiers pour trouver les fonctions dÃ©finies et exportÃ©es
    $filesToAnalyze = @()
    if (Test-Path -Path $ModulePath -PathType Container) {
        # C'est un rÃ©pertoire, analyser tous les fichiers PowerShell
        $filesToAnalyze = Get-ChildItem -Path $ModulePath -Recurse:$Recurse -File | Where-Object { $_.Extension -in '.ps1', '.psm1', '.psd1' }
    } else {
        # C'est un fichier, l'analyser directement
        $filesToAnalyze = Get-Item -Path $ModulePath
    }

    foreach ($file in $filesToAnalyze) {
        Write-Verbose "Analyzing file for function definitions: $($file.FullName)"

        try {
            $content = Get-Content -Path $file.FullName -Raw -ErrorAction Stop

            # DÃ©tecter les dÃ©finitions de fonctions
            # Format: function Nom-Fonction { ... }
            $functionMatches = [regex]::Matches($content, '(?m)^\s*function\s+([A-Za-z0-9\-_]+)')

            foreach ($match in $functionMatches) {
                $functionName = $match.Groups[1].Value

                # VÃ©rifier si la fonction est dÃ©jÃ  connue
                if (-not $definedFunctions.ContainsKey($functionName)) {
                    $definedFunctions[$functionName] = @{
                        Name       = $functionName
                        DefinedIn  = @($file.FullName)
                        IsExported = $false
                        IsPrivate  = $functionName -like "*-Private*" -or $functionName -like "Private*" -or $functionName.StartsWith("_")
                    }
                } else {
                    # La fonction est dÃ©finie dans plusieurs fichiers
                    if (-not $definedFunctions[$functionName].DefinedIn.Contains($file.FullName)) {
                        $definedFunctions[$functionName].DefinedIn += $file.FullName
                    }
                }
            }

            # DÃ©tecter les fonctions exportÃ©es
            # Format: Export-ModuleMember -Function Func1, Func2, ...
            $exportMatches = [regex]::Matches($content, '(?m)Export-ModuleMember\s+(?:-Function)?\s+([^#\r\n]+)')

            foreach ($match in $exportMatches) {
                $exportLine = $match.Groups[1].Value.Trim()

                # Supprimer les paramÃ¨tres nommÃ©s qui ne sont pas -Function
                $exportLine = $exportLine -replace '-[A-Za-z]+\s+[^,]+,?', ''

                # Extraire les noms de fonction
                $exportedNames = $exportLine -split ',' | ForEach-Object { $_.Trim() -replace '^"|"$', '' -replace "^'|'$", '' }

                foreach ($name in $exportedNames) {
                    if (-not [string]::IsNullOrWhiteSpace($name)) {
                        $exportedFunctions += $name

                        # Marquer la fonction comme exportÃ©e si elle est dÃ©finie
                        if ($definedFunctions.ContainsKey($name)) {
                            $definedFunctions[$name].IsExported = $true
                        }
                    }
                }
            }
        } catch {
            Write-Warning "Error analyzing file $($file.FullName): $_"
            continue
        }
    }

    # Collecter les fonctions appelÃ©es
    foreach ($call in $functionCalls) {
        $functionName = $call.FunctionName

        # Ignorer les fonctions systÃ¨me si demandÃ©
        if (-not $IncludeSystemFunctions -and (Test-SystemFunction -FunctionName $functionName)) {
            continue
        }

        # VÃ©rifier si la fonction est dÃ©jÃ  connue
        if (-not $calledFunctions.ContainsKey($functionName)) {
            $calledFunctions[$functionName] = @{
                Name        = $functionName
                CalledFrom  = @()
                IsInternal  = $call.IsInternal
                CalledCount = 0
            }
        }

        # Ajouter l'appel
        $callingFunction = $call.CallingFunction
        if ($callingFunction -and -not $calledFunctions[$functionName].CalledFrom.Contains($callingFunction)) {
            $calledFunctions[$functionName].CalledFrom += $callingFunction
        }

        # IncrÃ©menter le compteur d'appels
        $calledFunctions[$functionName].CalledCount++
    }

    # Analyser les rÃ©sultats
    $definedButNotCalled = @()
    $calledButNotDefined = @()
    $definedAndCalled = @()

    # Fonctions dÃ©finies mais non appelÃ©es
    foreach ($functionName in $definedFunctions.Keys) {
        $function = $definedFunctions[$functionName]

        # Ignorer les fonctions privÃ©es si demandÃ©
        if (-not $IncludePrivateFunctions -and $function.IsPrivate) {
            continue
        }

        if (-not $calledFunctions.ContainsKey($functionName)) {
            $definedButNotCalled += [PSCustomObject]@{
                Name       = $functionName
                DefinedIn  = $function.DefinedIn
                IsExported = $function.IsExported
                IsPrivate  = $function.IsPrivate
                Type       = "DefinedButNotCalled"
            }
        } else {
            $definedAndCalled += [PSCustomObject]@{
                Name        = $functionName
                DefinedIn   = $function.DefinedIn
                CalledFrom  = $calledFunctions[$functionName].CalledFrom
                CalledCount = $calledFunctions[$functionName].CalledCount
                IsExported  = $function.IsExported
                IsPrivate   = $function.IsPrivate
                Type        = "DefinedAndCalled"
            }
        }
    }

    # Fonctions appelÃ©es mais non dÃ©finies
    foreach ($functionName in $calledFunctions.Keys) {
        if (-not $definedFunctions.ContainsKey($functionName)) {
            $calledButNotDefined += [PSCustomObject]@{
                Name        = $functionName
                CalledFrom  = $calledFunctions[$functionName].CalledFrom
                CalledCount = $calledFunctions[$functionName].CalledCount
                IsInternal  = $calledFunctions[$functionName].IsInternal
                Type        = "CalledButNotDefined"
            }
        }
    }

    # CrÃ©er le rapport
    $result = [PSCustomObject]@{
        ModulePath               = $ModulePath
        AnalysisDate             = Get-Date
        DefinedFunctionsCount    = $definedFunctions.Count
        CalledFunctionsCount     = $calledFunctions.Count
        ExportedFunctionsCount   = $exportedFunctions.Count
        DefinedButNotCalledCount = $definedButNotCalled.Count
        CalledButNotDefinedCount = $calledButNotDefined.Count
        DefinedAndCalledCount    = $definedAndCalled.Count
        DefinedButNotCalled      = $definedButNotCalled
        CalledButNotDefined      = $calledButNotDefined
        DefinedAndCalled         = $definedAndCalled
    }

    return $result
}

function Test-SystemFunction {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FunctionName
    )

    # Liste des prÃ©fixes de fonctions systÃ¨me PowerShell
    $systemPrefixes = @(
        'Get-', 'Set-', 'New-', 'Remove-', 'Clear-', 'Add-', 'Copy-', 'Export-', 'Import-',
        'Invoke-', 'Convert-', 'ConvertFrom-', 'ConvertTo-', 'Format-', 'Join-', 'Measure-',
        'Move-', 'Out-', 'Pop-', 'Push-', 'Read-', 'Rename-', 'Resolve-', 'Resume-', 'Select-',
        'Send-', 'Show-', 'Skip-', 'Split-', 'Start-', 'Stop-', 'Submit-', 'Suspend-', 'Switch-',
        'Test-', 'Trace-', 'Unblock-', 'Undo-', 'Uninstall-', 'Unprotect-', 'Update-', 'Use-',
        'Wait-', 'Watch-', 'Write-'
    )

    # Liste des fonctions systÃ¨me PowerShell courantes
    $systemFunctions = @(
        'ForEach-Object', 'Where-Object', 'Sort-Object', 'Group-Object', 'Measure-Object',
        'Select-Object', 'Get-Item', 'Get-ChildItem', 'Get-Content', 'Set-Content', 'Add-Content',
        'Get-Process', 'Start-Process', 'Stop-Process', 'Get-Service', 'Start-Service',
        'Stop-Service', 'Get-Date', 'Get-Random', 'Get-Member', 'Get-Command', 'Get-Help',
        'Get-Module', 'Import-Module', 'Export-ModuleMember', 'New-Object', 'New-Item',
        'Remove-Item', 'Invoke-Command', 'Invoke-Expression', 'Write-Host', 'Write-Output',
        'Write-Error', 'Write-Warning', 'Write-Verbose', 'Write-Debug', 'Out-File', 'Out-String',
        'Out-Null', 'ConvertTo-Json', 'ConvertFrom-Json', 'ConvertTo-Csv', 'ConvertFrom-Csv',
        'ConvertTo-Xml', 'ConvertFrom-Xml', 'ConvertTo-Html', 'Join-Path', 'Split-Path',
        'Test-Path', 'Resolve-Path', 'Get-Location', 'Set-Location', 'Push-Location',
        'Pop-Location', 'Get-Alias', 'New-Alias', 'Set-Alias', 'Remove-Alias'
    )

    # VÃ©rifier si la fonction est une fonction systÃ¨me
    if ($systemFunctions -contains $FunctionName) {
        return $true
    }

    # VÃ©rifier si la fonction commence par un prÃ©fixe systÃ¨me
    foreach ($prefix in $systemPrefixes) {
        if ($FunctionName -like "$prefix*") {
            # VÃ©rifier si la fonction existe dans les modules systÃ¨me
            $command = Get-Command -Name $FunctionName -ErrorAction SilentlyContinue
            if ($command -and (Test-SystemModule -ModuleName $command.ModuleName)) {
                return $true
            }
        }
    }

    return $false
}

function New-FunctionDependencyGraph {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModulePath,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeExternalFunctions,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeSystemFunctions,

        [Parameter(Mandatory = $false)]
        [switch]$Recurse,

        [Parameter(Mandatory = $false)]
        [switch]$NoCache,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "CSV", "JSON", "DOT", "DGML", "HTML")]
        [string]$OutputFormat = "Text"
    )

    # Obtenir les appels de fonction
    $functionCalls = Get-FunctionCallDependencies -ModulePath $ModulePath -IncludeInternalCalls -IncludeExternalCalls:$IncludeExternalFunctions -Recurse:$Recurse -NoCache:$NoCache

    # Obtenir l'analyse des fonctions
    $functionAnalysis = Get-FunctionUsageAnalysis -ModulePath $ModulePath -IncludeSystemFunctions:$IncludeSystemFunctions -IncludePrivateFunctions -Recurse:$Recurse -NoCache:$NoCache

    # CrÃ©er le graphe de dÃ©pendances
    $nodes = @{}
    $edges = @()

    # Ajouter les nÅ“uds pour les fonctions dÃ©finies
    foreach ($function in $functionAnalysis.DefinedAndCalled + $functionAnalysis.DefinedButNotCalled) {
        $nodes[$function.Name] = @{
            Name        = $function.Name
            Type        = "Internal"
            IsExported  = $function.IsExported
            IsPrivate   = $function.IsPrivate
            DefinedIn   = $function.DefinedIn
            CalledCount = if ($function.CalledCount) { $function.CalledCount } else { 0 }
        }
    }

    # Ajouter les nÅ“uds pour les fonctions externes appelÃ©es
    if ($IncludeExternalFunctions) {
        foreach ($function in $functionAnalysis.CalledButNotDefined) {
            # Ignorer les fonctions systÃ¨me si demandÃ©
            if (-not $IncludeSystemFunctions -and (Test-SystemFunction -FunctionName $function.Name)) {
                continue
            }

            $nodes[$function.Name] = @{
                Name        = $function.Name
                Type        = "External"
                IsExported  = $false
                IsPrivate   = $false
                DefinedIn   = $null
                CalledCount = $function.CalledCount
            }
        }
    }

    # Ajouter les arÃªtes pour les appels de fonction
    foreach ($call in $functionCalls) {
        $caller = $call.CallingFunction
        $callee = $call.FunctionName

        # Ignorer les fonctions systÃ¨me si demandÃ©
        if (-not $IncludeSystemFunctions -and (Test-SystemFunction -FunctionName $callee)) {
            continue
        }

        # Ignorer les fonctions externes si demandÃ©
        if (-not $IncludeExternalFunctions -and -not $call.IsInternal) {
            continue
        }

        # Si le caller est null, c'est un appel depuis le niveau supÃ©rieur du script
        if ($null -eq $caller) {
            $caller = "[Script]"

            # Ajouter le nÅ“ud pour le script si nÃ©cessaire
            if (-not $nodes.ContainsKey($caller)) {
                $nodes[$caller] = @{
                    Name        = $caller
                    Type        = "Script"
                    IsExported  = $false
                    IsPrivate   = $false
                    DefinedIn   = $ModulePath
                    CalledCount = 0
                }
            }
        }

        # VÃ©rifier si les nÅ“uds existent
        if (-not $nodes.ContainsKey($caller)) {
            # Le caller n'est pas dans la liste des nÅ“uds, l'ignorer
            continue
        }

        if (-not $nodes.ContainsKey($callee)) {
            # Le callee n'est pas dans la liste des nÅ“uds, l'ignorer
            continue
        }

        # Ajouter l'arÃªte
        $edges += [PSCustomObject]@{
            Source     = $caller
            Target     = $callee
            SourceType = $nodes[$caller].Type
            TargetType = $nodes[$callee].Type
            File       = $call.CallingFile
            Line       = $call.CallingLine
        }
    }

    # CrÃ©er l'objet rÃ©sultat
    $result = [PSCustomObject]@{
        ModulePath   = $ModulePath
        AnalysisDate = Get-Date
        Nodes        = $nodes.Values
        Edges        = $edges
        NodeCount    = $nodes.Count
        EdgeCount    = $edges.Count
    }

    # Exporter le rÃ©sultat si demandÃ©
    if ($OutputPath) {
        switch ($OutputFormat) {
            "Text" {
                $textContent = @"
# Function Dependency Graph
Module Path: $($result.ModulePath)
Analysis Date: $((Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))

## Summary
Total Nodes: $($result.NodeCount)
Total Edges: $($result.EdgeCount)

## Nodes
"@

                foreach ($node in $result.Nodes | Sort-Object -Property Name) {
                    $textContent += @"

- $($node.Name) (Type: $($node.Type))
  - Exported: $($node.IsExported)
  - Private: $($node.IsPrivate)
  - Called Count: $($node.CalledCount)
"@
                    if ($node.DefinedIn) {
                        $textContent += @"
  - Defined In: $($node.DefinedIn -join ", ")
"@
                    }
                }

                $textContent += @"

## Edges
"@

                foreach ($edge in $result.Edges | Sort-Object -Property Source, Target) {
                    $textContent += @"

- $($edge.Source) -> $($edge.Target)
  - Source Type: $($edge.SourceType)
  - Target Type: $($edge.TargetType)
"@
                    if ($edge.File) {
                        $textContent += @"
  - File: $($edge.File)
  - Line: $($edge.Line)
"@
                    }
                }

                $textContent | Out-File -FilePath $OutputPath -Encoding UTF8
            }

            "CSV" {
                # Exporter les nÅ“uds
                $nodesPath = [System.IO.Path]::ChangeExtension($OutputPath, "nodes.csv")
                $result.Nodes | Select-Object Name, Type, IsExported, IsPrivate, CalledCount, @{Name = "DefinedIn"; Expression = { $_.DefinedIn -join ";" } } | Export-Csv -Path $nodesPath -NoTypeInformation -Encoding UTF8

                # Exporter les arÃªtes
                $edgesPath = [System.IO.Path]::ChangeExtension($OutputPath, "edges.csv")
                $result.Edges | Export-Csv -Path $edgesPath -NoTypeInformation -Encoding UTF8
            }

            "JSON" {
                $result | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
            }

            "DOT" {
                # CrÃ©er un fichier DOT pour Graphviz
                $dotContent = @"
digraph FunctionDependencies {
    // Graph settings
    rankdir=LR;
    node [shape=box, style=filled, fontname="Arial"];
    edge [fontname="Arial"];

    // Nodes
"@

                foreach ($node in $result.Nodes) {
                    $nodeColor = switch ($node.Type) {
                        "Internal" { if ($node.IsExported) { "lightblue" } else { "lightgreen" } }
                        "External" { "lightsalmon" }
                        "Script" { "lightgray" }
                        default { "white" }
                    }

                    $nodeLabel = $node.Name
                    if ($node.CalledCount -gt 0) {
                        $nodeLabel += "\nCalled: $($node.CalledCount)"
                    }

                    $dotContent += @"
    "$($node.Name)" [label="$nodeLabel", fillcolor="$nodeColor"];
"@
                }

                $dotContent += @"

    // Edges
"@

                foreach ($edge in $result.Edges) {
                    $dotContent += @"
    "$($edge.Source)" -> "$($edge.Target)";
"@
                }

                $dotContent += @"
}
"@

                $dotContent | Out-File -FilePath $OutputPath -Encoding UTF8
            }

            "DGML" {
                # CrÃ©er un fichier DGML pour Visual Studio
                $dgmlContent = @"
<?xml version="1.0" encoding="utf-8"?>
<DirectedGraph xmlns="http://schemas.microsoft.com/vs/2009/dgml">
  <Nodes>
"@

                foreach ($node in $result.Nodes) {
                    $nodeCategory = switch ($node.Type) {
                        "Internal" { if ($node.IsExported) { "ExportedFunction" } else { "InternalFunction" } }
                        "External" { "ExternalFunction" }
                        "Script" { "Script" }
                        default { "Unknown" }
                    }

                    $dgmlContent += @"
    <Node Id="$($node.Name)" Label="$($node.Name)" Category="$nodeCategory" />
"@
                }

                $dgmlContent += @"
  </Nodes>
  <Links>
"@

                foreach ($edge in $result.Edges) {
                    $dgmlContent += @"
    <Link Source="$($edge.Source)" Target="$($edge.Target)" />
"@
                }

                $dgmlContent += @"
  </Links>
  <Categories>
    <Category Id="ExportedFunction" Label="Exported Function" Background="Blue" />
    <Category Id="InternalFunction" Label="Internal Function" Background="Green" />
    <Category Id="ExternalFunction" Label="External Function" Background="Orange" />
    <Category Id="Script" Label="Script" Background="Gray" />
  </Categories>
  <Properties>
    <Property Id="Background" Label="Background" DataType="System.Windows.Media.Brush" />
    <Property Id="Label" Label="Label" DataType="System.String" />
  </Properties>
</DirectedGraph>
"@

                $dgmlContent | Out-File -FilePath $OutputPath -Encoding UTF8
            }

            "HTML" {
                # CrÃ©er un fichier HTML avec visualisation D3.js
                $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Function Dependency Graph</title>
    <meta charset="utf-8">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2 { color: #333; }
        .summary { background-color: #f5f5f5; padding: 10px; border-radius: 5px; margin-bottom: 20px; }
        .node { cursor: pointer; }
        .link { stroke: #999; stroke-opacity: 0.6; }
        .node text { font-size: 12px; }
        .tooltip { position: absolute; background-color: white; border: 1px solid #ddd; padding: 10px; border-radius: 5px; pointer-events: none; }
    </style>
    <script src="https://d3js.org/d3.v7.min.js"></script>
</head>
<body>
    <h1>Function Dependency Graph</h1>
    <div class="summary">
        <p><strong>Module Path:</strong> $($result.ModulePath)</p>
        <p><strong>Analysis Date:</strong> $((Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))</p>
        <p><strong>Total Nodes:</strong> $($result.NodeCount)</p>
        <p><strong>Total Edges:</strong> $($result.EdgeCount)</p>
    </div>

    <div id="graph"></div>

    <script>
        // Graph data
        const nodes = $(ConvertTo-Json -InputObject $result.Nodes -Depth 10);
        const links = $(ConvertTo-Json -InputObject $result.Edges -Depth 10).map(link => ({
            source: link.Source,
            target: link.Target,
            sourceType: link.SourceType,
            targetType: link.TargetType,
            file: link.File,
            line: link.Line
        }));

        // Create the graph
        const width = window.innerWidth - 40;
        const height = window.innerHeight - 200;

        const svg = d3.select("#graph")
            .append("svg")
            .attr("width", width)
            .attr("height", height);

        // Create a tooltip
        const tooltip = d3.select("body").append("div")
            .attr("class", "tooltip")
            .style("opacity", 0);

        // Create a force simulation
        const simulation = d3.forceSimulation(nodes)
            .force("link", d3.forceLink(links).id(d => d.Name).distance(150))
            .force("charge", d3.forceManyBody().strength(-300))
            .force("center", d3.forceCenter(width / 2, height / 2));

        // Create the links
        const link = svg.append("g")
            .selectAll("line")
            .data(links)
            .enter().append("line")
            .attr("class", "link")
            .attr("stroke-width", 1);

        // Create the nodes
        const node = svg.append("g")
            .selectAll("g")
            .data(nodes)
            .enter().append("g")
            .attr("class", "node")
            .call(d3.drag()
                .on("start", dragstarted)
                .on("drag", dragged)
                .on("end", dragended));

        // Add circles to the nodes
        node.append("circle")
            .attr("r", d => 5 + Math.sqrt(d.CalledCount) * 2)
            .attr("fill", d => {
                if (d.Type === "Internal") {
                    return d.IsExported ? "#4285F4" : "#34A853";
                } else if (d.Type === "External") {
                    return "#FBBC05";
                } else {
                    return "#EA4335";
                }
            })
            .on("mouseover", function(event, d) {
                tooltip.transition()
                    .duration(200)
                    .style("opacity", .9);

                let tooltipContent = `<strong>${d.Name}</strong><br/>`;
                tooltipContent += `Type: ${d.Type}<br/>`;
                tooltipContent += `Exported: ${d.IsExported}<br/>`;
                tooltipContent += `Private: ${d.IsPrivate}<br/>`;
                tooltipContent += `Called Count: ${d.CalledCount}<br/>`;

                if (d.DefinedIn) {
                    tooltipContent += `Defined In: ${Array.isArray(d.DefinedIn) ? d.DefinedIn.join(", ") : d.DefinedIn}`;
                }

                tooltip.html(tooltipContent)
                    .style("left", (event.pageX + 10) + "px")
                    .style("top", (event.pageY - 28) + "px");
            })
            .on("mouseout", function() {
                tooltip.transition()
                    .duration(500)
                    .style("opacity", 0);
            });

        // Add labels to the nodes
        node.append("text")
            .attr("dx", 12)
            .attr("dy", ".35em")
            .text(d => d.Name);

        // Update the positions on each tick
        simulation.on("tick", () => {
            link
                .attr("x1", d => d.source.x)
                .attr("y1", d => d.source.y)
                .attr("x2", d => d.target.x)
                .attr("y2", d => d.target.y);

            node
                .attr("transform", d => `translate(${d.x},${d.y})`);
        });

        // Drag functions
        function dragstarted(event, d) {
            if (!event.active) simulation.alphaTarget(0.3).restart();
            d.fx = d.x;
            d.fy = d.y;
        }

        function dragged(event, d) {
            d.fx = event.x;
            d.fy = event.y;
        }

        function dragended(event, d) {
            if (!event.active) simulation.alphaTarget(0);
            d.fx = null;
            d.fy = null;
        }
    </script>
</body>
</html>
"@

                $htmlContent | Out-File -FilePath $OutputPath -Encoding UTF8
            }
        }

        Write-Verbose "Function dependency graph exported to: $OutputPath"
    }

    return $result
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Test-SystemModule, Get-PowerShellManifestStructure, Get-ModuleDependenciesFromManifest, Get-ModuleDependenciesFromCode, Find-ModulePath, Get-ExternalFunctionDependencies, Get-FunctionCallDependencies, Resolve-ExternalFunctionPath, Clear-DependencyCache, Get-DependencyCache, Export-DependencyReport, Get-CompleteDependencyAnalysis, ConvertTo-ModuleDependencyDetectorFormat, Invoke-ModuleDependencyDetector, Get-ModuleDependencies, Get-FunctionUsageAnalysis, New-FunctionDependencyGraph
