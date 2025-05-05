#Requires -Version 5.1
<#
.SYNOPSIS
    Module simplifiÃ© pour l'analyse des dÃ©pendances entre modules PowerShell.

.DESCRIPTION
    Ce module fournit des fonctions de base pour analyser les dÃ©pendances entre modules PowerShell.

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
        [switch]$SkipSystemModules
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

                    # GÃ©rer le GUID du module
                    if ($requiredModule.ContainsKey('GUID')) {
                        $moduleGuid = $requiredModule.GUID
                    }
                }

                # Ignorer les modules systÃ¨me si demandÃ©
                if ($SkipSystemModules -and (Test-SystemModule -ModuleName $moduleName)) {
                    Write-Verbose "System module ignored: $moduleName"
                    continue
                }

                # Ajouter la dÃ©pendance Ã  la liste
                [void]$dependencies.Add([PSCustomObject]@{
                        Name    = $moduleName
                        Version = $moduleVersion
                        GUID    = $moduleGuid
                        Type    = "RequiredModule"
                        Source  = $ManifestPath
                    })
            }
        }

        return $dependencies
    } catch {
        Write-Error "Error analyzing manifest: $_"
        return $dependencies
    }
}

function Get-ModuleDependenciesFromCode {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModulePath,

        [Parameter(Mandatory = $false)]
        [switch]$SkipSystemModules
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
        $filesToAnalyze += Get-ChildItem -Path $ModulePath -Include $filter -File
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

        # DÃ©tecter les Import-Module
        $importMatches = [regex]::Matches($content, '(?m)^\s*Import-Module\s+([''"]?)([^''"\s]+)\1')

        foreach ($match in $importMatches) {
            $moduleName = $match.Groups[2].Value

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
                    Type    = "ImportModule"
                    Source  = $file.FullName
                })
        }
    }

    return $dependencies
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Test-SystemModule, Get-PowerShellManifestStructure, Get-ModuleDependenciesFromManifest, Get-ModuleDependenciesFromCode
