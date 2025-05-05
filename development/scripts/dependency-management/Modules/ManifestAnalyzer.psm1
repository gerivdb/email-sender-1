﻿#Requires -Version 5.1
<#
.SYNOPSIS
    Module pour l'analyse des manifestes de modules PowerShell (.psd1).

.DESCRIPTION
    Ce module fournit des fonctions pour analyser les manifestes de modules PowerShell,
    extraire les dÃ©pendances RequiredModules, NestedModules, etc.

.NOTES
    Auteur: Dependency Management Team
    Version: 1.0
#>

function Get-PowerShellManifestStructure {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ManifestPath
    )

    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $ManifestPath -PathType Leaf)) {
        $errorMsg = "File not found: $ManifestPath"
        Write-Error $errorMsg
        return $null
    }

    # VÃ©rifier l'extension du fichier
    $extension = [System.IO.Path]::GetExtension($ManifestPath)
    if ($extension -ne ".psd1") {
        $errorMsg = "File is not a PowerShell manifest (.psd1): $ManifestPath"
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
        Write-Error "Error analyzing manifest: $_"
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
                    # RÃ©soudre le chemin du module si demandÃ©
                    if ($ResolveModulePaths -and -not $modulePath) {
                        $modulePath = Find-ModulePath -ModuleName $moduleName
                    }

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
                } elseif ($ResolveModulePaths) {
                    $modulePath = Find-ModulePath -ModuleName $moduleName -ModuleVersion $moduleVersion
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
        Write-Error "Error analyzing manifest $ManifestPath : $_"
        return $dependencies
    }
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Get-PowerShellManifestStructure, Get-ModuleDependenciesFromManifest
