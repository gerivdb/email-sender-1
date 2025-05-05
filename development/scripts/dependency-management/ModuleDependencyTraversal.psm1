#Requires -Version 5.1

<#
.SYNOPSIS
    Module pour l'analyse rÃ©cursive des dÃ©pendances de modules PowerShell.

.DESCRIPTION
    Ce module fournit des fonctions pour analyser les dÃ©pendances directes et indirectes
    des modules PowerShell, construire un graphe de dÃ©pendances et dÃ©tecter les cycles.

.NOTES
    Auteur: Dependency Management Team
    Version: 1.0
    Date de crÃ©ation: 2023-06-15
#>

# Importer les modules requis s'ils ne sont pas dÃ©jÃ  importÃ©s
$moduleRoot = $PSScriptRoot
$functionCallParserPath = Join-Path -Path $moduleRoot -ChildPath 'FunctionCallParser.psm1'
$importedFunctionDetectorPath = Join-Path -Path $moduleRoot -ChildPath 'ImportedFunctionDetector.psm1'
$functionDependencyAnalyzerPath = Join-Path -Path $moduleRoot -ChildPath 'FunctionDependencyAnalyzer.psm1'
$simpleCycleDetectorPath = Join-Path -Path $moduleRoot -ChildPath 'SimpleCycleDetector.psm1'

if (-not (Get-Module -Name 'FunctionCallParser')) {
    if (Test-Path -Path $functionCallParserPath) {
        Import-Module -Name $functionCallParserPath -Force
    } else {
        Write-Warning "Le module FunctionCallParser est requis mais n'a pas Ã©tÃ© trouvÃ© Ã  l'emplacement: $functionCallParserPath"
    }
}

if (-not (Get-Module -Name 'ImportedFunctionDetector')) {
    if (Test-Path -Path $importedFunctionDetectorPath) {
        Import-Module -Name $importedFunctionDetectorPath -Force
    } else {
        Write-Warning "Le module ImportedFunctionDetector est requis mais n'a pas Ã©tÃ© trouvÃ© Ã  l'emplacement: $importedFunctionDetectorPath"
    }
}

if (-not (Get-Module -Name 'FunctionDependencyAnalyzer')) {
    if (Test-Path -Path $functionDependencyAnalyzerPath) {
        Import-Module -Name $functionDependencyAnalyzerPath -Force
    } else {
        Write-Warning "Le module FunctionDependencyAnalyzer est requis mais n'a pas Ã©tÃ© trouvÃ© Ã  l'emplacement: $functionDependencyAnalyzerPath"
    }
}

if (-not (Get-Module -Name 'SimpleCycleDetector')) {
    if (Test-Path -Path $simpleCycleDetectorPath) {
        Import-Module -Name $simpleCycleDetectorPath -Force
    } else {
        Write-Warning "Le module SimpleCycleDetector est requis mais n'a pas Ã©tÃ© trouvÃ© Ã  l'emplacement: $simpleCycleDetectorPath"
    }
}

# Variables globales pour le module
$Global:MDT_VisitedModules = @{}
$Global:MDT_DependencyGraph = @{}
$Global:MDT_MaxRecursionDepth = 10
$Global:MDT_CurrentRecursionDepth = 0

# Alias pour la compatibilitÃ© avec le code existant
$script:VisitedModules = $Global:MDT_VisitedModules
$script:DependencyGraph = $Global:MDT_DependencyGraph
$script:MaxRecursionDepth = $Global:MDT_MaxRecursionDepth
$script:CurrentRecursionDepth = $Global:MDT_CurrentRecursionDepth

<#
.SYNOPSIS
    Obtient les dÃ©pendances directes d'un module PowerShell.

.DESCRIPTION
    Cette fonction analyse un module PowerShell et dÃ©tecte ses dÃ©pendances directes
    en analysant son manifeste (.psd1) et son code (.psm1).

.PARAMETER ModuleName
    Nom du module PowerShell Ã  analyser.

.PARAMETER ModulePath
    Chemin du module PowerShell Ã  analyser. Si non spÃ©cifiÃ©, le module sera recherchÃ©
    dans les chemins de modules standards.

.PARAMETER SkipSystemModules
    Indique si les modules systÃ¨me doivent Ãªtre exclus des rÃ©sultats.

.PARAMETER ResolveModulePaths
    Indique si les chemins des modules dÃ©pendants doivent Ãªtre rÃ©solus.

.EXAMPLE
    $dependencies = Get-ModuleDirectDependencies -ModuleName 'MyModule'
    Obtient les dÃ©pendances directes du module 'MyModule'.

.EXAMPLE
    $dependencies = Get-ModuleDirectDependencies -ModulePath 'C:\Modules\MyModule\MyModule.psd1' -SkipSystemModules
    Obtient les dÃ©pendances directes du module situÃ© Ã  'C:\Modules\MyModule\MyModule.psd1', en excluant les modules systÃ¨me.

.OUTPUTS
    [PSCustomObject[]] Liste des dÃ©pendances directes du module.
#>
function Get-ModuleDirectDependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'ByName')]
        [string]$ModuleName,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByPath')]
        [string]$ModulePath,

        [Parameter(Mandatory = $false)]
        [switch]$SkipSystemModules,

        [Parameter(Mandatory = $false)]
        [switch]$ResolveModulePaths
    )

    begin {
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
            'PSReadLine'
        )

        # Fonction interne pour vÃ©rifier si un module est un module systÃ¨me
        function Test-SystemModule {
            param (
                [Parameter(Mandatory = $true)]
                [string]$ModuleName
            )

            return $systemModules -contains $ModuleName
        }
    }

    process {
        try {
            # Initialiser la liste des dÃ©pendances
            $dependencies = [System.Collections.ArrayList]::new()

            # Obtenir le chemin du module si nÃ©cessaire
            if ($PSCmdlet.ParameterSetName -eq 'ByName') {
                $module = Get-Module -Name $ModuleName -ListAvailable | Select-Object -First 1
                if (-not $module) {
                    Write-Warning "Le module '$ModuleName' n'a pas Ã©tÃ© trouvÃ©."
                    return $dependencies
                }
                $ModulePath = $module.Path
            }

            # VÃ©rifier si le fichier existe
            if (-not (Test-Path -Path $ModulePath -PathType Leaf)) {
                Write-Warning "Le fichier module n'existe pas: $ModulePath"
                return $dependencies
            }

            # DÃ©terminer le type de fichier (psd1 ou psm1)
            $extension = [System.IO.Path]::GetExtension($ModulePath)
            $moduleRoot = Split-Path -Path $ModulePath -Parent
            $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($ModulePath)

            # Analyser le manifeste du module si disponible
            $manifestPath = $null
            if ($extension -eq '.psm1') {
                $manifestPath = Join-Path -Path $moduleRoot -ChildPath "$moduleName.psd1"
                if (-not (Test-Path -Path $manifestPath -PathType Leaf)) {
                    $manifestPath = $null
                }
            } elseif ($extension -eq '.psd1') {
                $manifestPath = $ModulePath
            }

            # Obtenir les dÃ©pendances du manifeste
            if ($manifestPath) {
                $manifestDependencies = Get-ModuleDependenciesFromManifest -ManifestPath $manifestPath -SkipSystemModules:$SkipSystemModules -ResolveModulePaths:$ResolveModulePaths
                foreach ($dependency in $manifestDependencies) {
                    [void]$dependencies.Add($dependency)
                }
            }

            # Analyser le code du module si disponible
            $modulePath = $null
            if ($extension -eq '.psm1') {
                $modulePath = $ModulePath
            } elseif ($extension -eq '.psd1' -and $manifestPath) {
                # Obtenir le chemin du module Ã  partir du manifeste
                try {
                    $manifest = Import-PowerShellDataFile -Path $manifestPath -ErrorAction Stop
                    if ($manifest.ContainsKey('RootModule') -and $manifest.RootModule) {
                        $modulePath = Join-Path -Path $moduleRoot -ChildPath $manifest.RootModule
                        if (-not (Test-Path -Path $modulePath -PathType Leaf)) {
                            $modulePath = $null
                        }
                    } elseif ($manifest.ContainsKey('ModuleToProcess') -and $manifest.ModuleToProcess) {
                        $modulePath = Join-Path -Path $moduleRoot -ChildPath $manifest.ModuleToProcess
                        if (-not (Test-Path -Path $modulePath -PathType Leaf)) {
                            $modulePath = $null
                        }
                    }
                } catch {
                    Write-Warning "Erreur lors de l'analyse du manifeste $manifestPath : $_"
                }
            }

            # Obtenir les dÃ©pendances du code du module
            if ($modulePath) {
                $codeDependencies = Get-ModuleDependenciesFromCode -ModulePath $modulePath -SkipSystemModules:$SkipSystemModules -ResolveModulePaths:$ResolveModulePaths
                foreach ($dependency in $codeDependencies) {
                    # VÃ©rifier si la dÃ©pendance existe dÃ©jÃ 
                    $existingDependency = $dependencies | Where-Object { $_.Name -eq $dependency.Name }
                    if (-not $existingDependency) {
                        [void]$dependencies.Add($dependency)
                    }
                }
            }

            # Filtrer les modules systÃ¨me si demandÃ©
            if ($SkipSystemModules) {
                $dependencies = $dependencies | Where-Object { -not (Test-SystemModule -ModuleName $_.Name) }
            }

            # RÃ©soudre les chemins des modules si demandÃ©
            if ($ResolveModulePaths) {
                foreach ($dependency in $dependencies) {
                    if (-not $dependency.Path) {
                        $dependencyModule = Get-Module -Name $dependency.Name -ListAvailable | Select-Object -First 1
                        if ($dependencyModule) {
                            $dependency.Path = $dependencyModule.Path
                        }
                    }
                }
            }

            return $dependencies
        } catch {
            Write-Error "Erreur lors de l'obtention des dÃ©pendances directes du module: $_"
            return @()
        }
    }
}

<#
.SYNOPSIS
    Obtient les dÃ©pendances d'un module PowerShell Ã  partir de son manifeste.

.DESCRIPTION
    Cette fonction analyse le manifeste d'un module PowerShell (.psd1) et dÃ©tecte
    ses dÃ©pendances explicites (RequiredModules, NestedModules).

.PARAMETER ManifestPath
    Chemin du manifeste du module PowerShell (.psd1) Ã  analyser.

.PARAMETER SkipSystemModules
    Indique si les modules systÃ¨me doivent Ãªtre exclus des rÃ©sultats.

.PARAMETER ResolveModulePaths
    Indique si les chemins des modules dÃ©pendants doivent Ãªtre rÃ©solus.

.EXAMPLE
    $dependencies = Get-ModuleDependenciesFromManifest -ManifestPath 'C:\Modules\MyModule\MyModule.psd1'
    Obtient les dÃ©pendances du module Ã  partir de son manifeste.

.OUTPUTS
    [PSCustomObject[]] Liste des dÃ©pendances du module extraites du manifeste.
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
    if ($extension -ne '.psd1') {
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
            foreach ($requiredModule in $manifest.RequiredModules) {
                $moduleName = $null
                $moduleVersion = $null
                $modulePath = $null

                # DÃ©terminer le format du module requis
                if ($requiredModule -is [string]) {
                    # Format simple: 'ModuleName'
                    $moduleName = $requiredModule
                } elseif ($requiredModule -is [hashtable] -or $requiredModule -is [System.Collections.Specialized.OrderedDictionary]) {
                    # Format complexe: @{ModuleName='Name'; ModuleVersion='1.0.0'}
                    if ($requiredModule.ContainsKey('ModuleName')) {
                        $moduleName = $requiredModule.ModuleName
                    }
                    if ($requiredModule.ContainsKey('ModuleVersion')) {
                        $moduleVersion = $requiredModule.ModuleVersion
                    }
                    if ($requiredModule.ContainsKey('RequiredVersion')) {
                        $moduleVersion = $requiredModule.RequiredVersion
                    }
                } elseif ($requiredModule -is [System.Management.Automation.PSModuleInfo]) {
                    # Format objet: [PSModuleInfo]
                    $moduleName = $requiredModule.Name
                    $moduleVersion = $requiredModule.Version
                    $modulePath = $requiredModule.Path
                }

                # Ajouter la dÃ©pendance Ã  la liste
                [void]$dependencies.Add([PSCustomObject]@{
                        Name    = $moduleName
                        Version = $moduleVersion
                        Path    = $modulePath
                        Type    = 'RequiredModule'
                        Source  = $ManifestPath
                    })
            }
        }

        # Extraire les dÃ©pendances NestedModules
        if ($manifest.ContainsKey('NestedModules') -and $manifest.NestedModules) {
            Write-Verbose "Analyse des NestedModules dans le manifeste: $ManifestPath"

            # NestedModules peut Ãªtre une chaÃ®ne, un tableau de chaÃ®nes, ou un tableau d'objets
            foreach ($nestedModule in $manifest.NestedModules) {
                $moduleName = $null
                $moduleVersion = $null
                $modulePath = $null

                # DÃ©terminer le format du module imbriquÃ©
                if ($nestedModule -is [string]) {
                    # Format simple: 'ModuleName' ou chemin relatif
                    $moduleName = $nestedModule

                    # VÃ©rifier si c'est un chemin relatif
                    if ($moduleName -match '[\\/]' -or $moduleName -match '\.ps[md]1$') {
                        $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($moduleName)
                    }
                } elseif ($nestedModule -is [hashtable] -or $nestedModule -is [System.Collections.Specialized.OrderedDictionary]) {
                    # Format complexe: @{ModuleName='Name'; ModuleVersion='1.0.0'}
                    if ($nestedModule.ContainsKey('ModuleName')) {
                        $moduleName = $nestedModule.ModuleName
                    }
                    if ($nestedModule.ContainsKey('ModuleVersion')) {
                        $moduleVersion = $nestedModule.ModuleVersion
                    }
                    if ($nestedModule.ContainsKey('RequiredVersion')) {
                        $moduleVersion = $nestedModule.RequiredVersion
                    }
                } elseif ($nestedModule -is [System.Management.Automation.PSModuleInfo]) {
                    # Format objet: [PSModuleInfo]
                    $moduleName = $nestedModule.Name
                    $moduleVersion = $nestedModule.Version
                    $modulePath = $nestedModule.Path
                }

                # Ajouter la dÃ©pendance Ã  la liste
                [void]$dependencies.Add([PSCustomObject]@{
                        Name    = $moduleName
                        Version = $moduleVersion
                        Path    = $modulePath
                        Type    = 'NestedModule'
                        Source  = $ManifestPath
                    })
            }
        }

        # Extraire la dÃ©pendance RootModule/ModuleToProcess
        if ($manifest.ContainsKey('RootModule') -and $manifest.RootModule) {
            $rootModule = $manifest.RootModule

            # VÃ©rifier si c'est un module externe (pas un fichier .psm1 local)
            if (-not ($rootModule -match '\.psm1$' -or $rootModule -match '[\\/]')) {
                [void]$dependencies.Add([PSCustomObject]@{
                        Name    = $rootModule
                        Version = $null
                        Path    = $null
                        Type    = 'RootModule'
                        Source  = $ManifestPath
                    })
            }
        } elseif ($manifest.ContainsKey('ModuleToProcess') -and $manifest.ModuleToProcess) {
            $moduleToProcess = $manifest.ModuleToProcess

            # VÃ©rifier si c'est un module externe (pas un fichier .psm1 local)
            if (-not ($moduleToProcess -match '\.psm1$' -or $moduleToProcess -match '[\\/]')) {
                [void]$dependencies.Add([PSCustomObject]@{
                        Name    = $moduleToProcess
                        Version = $null
                        Path    = $null
                        Type    = 'ModuleToProcess'
                        Source  = $ManifestPath
                    })
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
    Obtient les dÃ©pendances d'un module PowerShell Ã  partir de son code.

.DESCRIPTION
    Cette fonction analyse le code d'un module PowerShell (.psm1) et dÃ©tecte
    ses dÃ©pendances implicites (Import-Module, using module).

.PARAMETER ModulePath
    Chemin du fichier de code du module PowerShell (.psm1) Ã  analyser.

.PARAMETER SkipSystemModules
    Indique si les modules systÃ¨me doivent Ãªtre exclus des rÃ©sultats.

.PARAMETER ResolveModulePaths
    Indique si les chemins des modules dÃ©pendants doivent Ãªtre rÃ©solus.

.PARAMETER IncludeScriptDependencies
    Indique si les dÃ©pendances des scripts dot-sourcÃ©s doivent Ãªtre incluses.

.EXAMPLE
    $dependencies = Get-ModuleDependenciesFromCode -ModulePath 'C:\Modules\MyModule\MyModule.psm1'
    Obtient les dÃ©pendances du module Ã  partir de son code.

.OUTPUTS
    [PSCustomObject[]] Liste des dÃ©pendances du module extraites du code.
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

    try {
        # Charger le contenu du fichier
        $content = Get-Content -Path $ModulePath -Raw -ErrorAction Stop

        # DÃ©tecter les Import-Module
        $importMatches = [regex]::Matches($content, '(?m)^\s*Import-Module\s+(?:-Name\s+)?([''"]?)([^''"\s]+)\1')
        foreach ($match in $importMatches) {
            $moduleName = $match.Groups[2].Value

            # Ajouter la dÃ©pendance Ã  la liste
            [void]$dependencies.Add([PSCustomObject]@{
                    Name    = $moduleName
                    Version = $null
                    Path    = $null
                    Type    = 'ImportModule'
                    Source  = $ModulePath
                })
        }

        # DÃ©tecter les using module
        $usingMatches = [regex]::Matches($content, '(?m)^\s*using\s+module\s+([''"]?)([^''"\s]+)\1')
        foreach ($match in $usingMatches) {
            $moduleName = $match.Groups[2].Value

            # Ajouter la dÃ©pendance Ã  la liste
            [void]$dependencies.Add([PSCustomObject]@{
                    Name    = $moduleName
                    Version = $null
                    Path    = $null
                    Type    = 'UsingModule'
                    Source  = $ModulePath
                })
        }

        # DÃ©tecter les #Requires -Modules
        $requiresMatches = [regex]::Matches($content, '(?m)^\s*#Requires\s+-Modules\s+(.+)$')
        foreach ($match in $requiresMatches) {
            $modulesList = $match.Groups[1].Value

            # Analyser la liste des modules requis
            $moduleNames = $modulesList -split ',' | ForEach-Object { $_.Trim() }
            foreach ($moduleName in $moduleNames) {
                # Supprimer les guillemets si prÃ©sents
                $moduleName = $moduleName -replace '^[''"]|[''"]$', ''

                # Ajouter la dÃ©pendance Ã  la liste
                [void]$dependencies.Add([PSCustomObject]@{
                        Name    = $moduleName
                        Version = $null
                        Path    = $null
                        Type    = 'RequiresModule'
                        Source  = $ModulePath
                    })
            }
        }

        # Analyser les scripts dot-sourcÃ©s si demandÃ©
        if ($IncludeScriptDependencies) {
            $moduleDir = Split-Path -Path $ModulePath -Parent
            $dotSourceMatches = [regex]::Matches($content, '(?m)^\s*\.\s+([''"]?)([^''"\s]+)\1')
            foreach ($match in $dotSourceMatches) {
                $scriptPath = $match.Groups[2].Value

                # RÃ©soudre le chemin complet du script
                if (-not [System.IO.Path]::IsPathRooted($scriptPath)) {
                    $scriptPath = Join-Path -Path $moduleDir -ChildPath $scriptPath
                }

                # VÃ©rifier si le script existe
                if (Test-Path -Path $scriptPath -PathType Leaf) {
                    # Analyser les dÃ©pendances du script
                    $scriptDependencies = Get-ModuleDependenciesFromCode -ModulePath $scriptPath -SkipSystemModules:$SkipSystemModules -ResolveModulePaths:$ResolveModulePaths
                    foreach ($dependency in $scriptDependencies) {
                        # VÃ©rifier si la dÃ©pendance existe dÃ©jÃ 
                        $existingDependency = $dependencies | Where-Object { $_.Name -eq $dependency.Name }
                        if (-not $existingDependency) {
                            [void]$dependencies.Add($dependency)
                        }
                    }
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
    Explore rÃ©cursivement les dÃ©pendances d'un module PowerShell.

.DESCRIPTION
    Cette fonction explore rÃ©cursivement les dÃ©pendances d'un module PowerShell
    en utilisant un algorithme de parcours en profondeur (DFS).

.PARAMETER ModuleName
    Nom du module PowerShell Ã  explorer.

.PARAMETER ModulePath
    Chemin du module PowerShell Ã  explorer. Si non spÃ©cifiÃ©, le module sera recherchÃ©
    dans les chemins de modules standards.

.PARAMETER CurrentDepth
    Profondeur actuelle de rÃ©cursion. UtilisÃ© en interne pour limiter la profondeur.

.PARAMETER SkipSystemModules
    Indique si les modules systÃ¨me doivent Ãªtre exclus des rÃ©sultats.

.PARAMETER ResolveModulePaths
    Indique si les chemins des modules dÃ©pendants doivent Ãªtre rÃ©solus.

.EXAMPLE
    Invoke-ModuleDependencyExploration -ModuleName 'MyModule' -CurrentDepth 0
    Explore rÃ©cursivement les dÃ©pendances du module 'MyModule'.

.OUTPUTS
    Aucun. Les rÃ©sultats sont stockÃ©s dans les variables globales du script.
#>
function Invoke-ModuleDependencyExploration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'ByName')]
        [string]$ModuleName,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByPath')]
        [string]$ModulePath,

        [Parameter(Mandatory = $true)]
        [int]$CurrentDepth,

        [Parameter(Mandatory = $false)]
        [switch]$SkipSystemModules,

        [Parameter(Mandatory = $false)]
        [switch]$ResolveModulePaths
    )

    # VÃ©rifier la profondeur de rÃ©cursion
    if ($CurrentDepth -gt $Global:MDT_MaxRecursionDepth) {
        Write-Verbose "Profondeur maximale de rÃ©cursion atteinte pour le module: $ModuleName"
        return
    }

    # DÃ©terminer le nom du module si le chemin est fourni
    if ($PSCmdlet.ParameterSetName -eq 'ByPath') {
        $ModuleName = [System.IO.Path]::GetFileNameWithoutExtension($ModulePath)
    }

    # VÃ©rifier si le module a dÃ©jÃ  Ã©tÃ© visitÃ©
    if ($Global:MDT_VisitedModules.ContainsKey($ModuleName)) {
        Write-Verbose "Module dÃ©jÃ  visitÃ©: $ModuleName"
        return
    }

    # Marquer le module comme visitÃ©
    $Global:MDT_VisitedModules[$ModuleName] = @{
        Visited   = $true
        VisitedAt = Get-Date
        Depth     = $CurrentDepth
    }

    Write-Verbose "Exploration des dÃ©pendances du module: $ModuleName (Profondeur: $CurrentDepth)"

    # Obtenir les dÃ©pendances directes du module
    $dependencies = $null
    if ($PSCmdlet.ParameterSetName -eq 'ByName') {
        $dependencies = Get-ModuleDirectDependencies -ModuleName $ModuleName -SkipSystemModules:$SkipSystemModules -ResolveModulePaths:$ResolveModulePaths
    } else {
        $dependencies = Get-ModuleDirectDependencies -ModulePath $ModulePath -SkipSystemModules:$SkipSystemModules -ResolveModulePaths:$ResolveModulePaths
    }

    # Ajouter les dÃ©pendances au graphe
    $dependencyNames = $dependencies | Select-Object -ExpandProperty Name -Unique
    $Global:MDT_DependencyGraph[$ModuleName] = $dependencyNames

    # Explorer rÃ©cursivement les dÃ©pendances
    foreach ($dependency in $dependencies) {
        $dependencyName = $dependency.Name
        $dependencyPath = $dependency.Path

        # Explorer la dÃ©pendance
        if ($dependencyPath) {
            Invoke-ModuleDependencyExploration -ModulePath $dependencyPath -CurrentDepth ($CurrentDepth + 1) -SkipSystemModules:$SkipSystemModules -ResolveModulePaths:$ResolveModulePaths
        } else {
            Invoke-ModuleDependencyExploration -ModuleName $dependencyName -CurrentDepth ($CurrentDepth + 1) -SkipSystemModules:$SkipSystemModules -ResolveModulePaths:$ResolveModulePaths
        }
    }
}

<#
.SYNOPSIS
    Obtient les statistiques des modules visitÃ©s lors de l'exploration des dÃ©pendances.

.DESCRIPTION
    Cette fonction retourne des statistiques sur les modules visitÃ©s lors de l'exploration
    des dÃ©pendances, notamment le nombre de modules visitÃ©s, la profondeur maximale, etc.

.EXAMPLE
    $stats = Get-ModuleVisitStatistics
    Obtient les statistiques des modules visitÃ©s.

.OUTPUTS
    [PSCustomObject] Statistiques des modules visitÃ©s.
#>
function Get-ModuleVisitStatistics {
    [CmdletBinding()]
    param ()

    # Calculer les statistiques
    $visitedCount = $Global:MDT_VisitedModules.Count
    $maxDepth = ($Global:MDT_VisitedModules.Values | Measure-Object -Property Depth -Maximum).Maximum
    $minDepth = ($Global:MDT_VisitedModules.Values | Measure-Object -Property Depth -Minimum).Minimum
    $avgDepth = ($Global:MDT_VisitedModules.Values | Measure-Object -Property Depth -Average).Average

    # Retourner les statistiques
    return [PSCustomObject]@{
        VisitedModulesCount = $visitedCount
        MaxDepth            = $maxDepth
        MinDepth            = $minDepth
        AverageDepth        = $avgDepth
        VisitedModules      = $Global:MDT_VisitedModules.Keys
    }
}

<#
.SYNOPSIS
    Obtient le graphe de dÃ©pendances des modules.

.DESCRIPTION
    Cette fonction retourne le graphe de dÃ©pendances des modules construit lors de l'exploration
    des dÃ©pendances. Le graphe est reprÃ©sentÃ© par une table de hachage oÃ¹ les clÃ©s sont les noms
    des modules et les valeurs sont des listes de noms de modules dÃ©pendants.

.PARAMETER ModuleName
    Nom du module pour lequel obtenir les dÃ©pendances. Si non spÃ©cifiÃ©, retourne le graphe complet.

.PARAMETER IncludeStats
    Indique si les statistiques du graphe doivent Ãªtre incluses dans les rÃ©sultats.

.PARAMETER Format
    Format de sortie du graphe. Les valeurs possibles sont: 'HashTable', 'PSObject', 'JSON'.

.EXAMPLE
    $graph = Get-ModuleDependencyGraph
    Obtient le graphe complet de dÃ©pendances des modules.

.EXAMPLE
    $moduleDependencies = Get-ModuleDependencyGraph -ModuleName 'MyModule'
    Obtient les dÃ©pendances directes du module 'MyModule'.

.OUTPUTS
    [System.Collections.Hashtable] ou [PSCustomObject] Graphe de dÃ©pendances des modules.
#>
function Get-ModuleDependencyGraph {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ModuleName,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeStats,

        [Parameter(Mandatory = $false)]
        [ValidateSet('HashTable', 'PSObject', 'JSON')]
        [string]$Format = 'HashTable'
    )

    # VÃ©rifier si le graphe est vide
    if ($Global:MDT_DependencyGraph.Count -eq 0) {
        Write-Warning "Le graphe de dÃ©pendances est vide. ExÃ©cutez d'abord Invoke-ModuleDependencyExploration."
        return $null
    }

    # Obtenir le graphe pour un module spÃ©cifique ou le graphe complet
    $graph = $null
    if ($ModuleName) {
        if (-not $Global:MDT_DependencyGraph.ContainsKey($ModuleName)) {
            Write-Warning "Le module '$ModuleName' n'existe pas dans le graphe de dÃ©pendances."
            return $null
        }
        $graph = @{ $ModuleName = $Global:MDT_DependencyGraph[$ModuleName] }
    } else {
        $graph = $Global:MDT_DependencyGraph
    }

    # Calculer les statistiques si demandÃ©
    $stats = $null
    if ($IncludeStats) {
        $moduleCount = $graph.Count
        $dependencyCount = ($graph.Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum
        $avgDependencies = if ($moduleCount -gt 0) { $dependencyCount / $moduleCount } else { 0 }
        $maxDependencies = ($graph.Values | ForEach-Object { $_.Count } | Measure-Object -Maximum).Maximum
        $minDependencies = ($graph.Values | ForEach-Object { $_.Count } | Measure-Object -Minimum).Minimum

        $stats = [PSCustomObject]@{
            ModuleCount         = $moduleCount
            DependencyCount     = $dependencyCount
            AverageDependencies = $avgDependencies
            MaxDependencies     = $maxDependencies
            MinDependencies     = $minDependencies
        }
    }

    # Formater le rÃ©sultat selon le format demandÃ©
    switch ($Format) {
        'HashTable' {
            if ($IncludeStats) {
                return [PSCustomObject]@{
                    Graph = $graph
                    Stats = $stats
                }
            } else {
                return $graph
            }
        }
        'PSObject' {
            $result = [PSCustomObject]@{}
            foreach ($key in $graph.Keys) {
                $result | Add-Member -MemberType NoteProperty -Name $key -Value $graph[$key]
            }
            if ($IncludeStats) {
                return [PSCustomObject]@{
                    Graph = $result
                    Stats = $stats
                }
            } else {
                return $result
            }
        }
        'JSON' {
            if ($IncludeStats) {
                return ConvertTo-Json -InputObject @{
                    Graph = $graph
                    Stats = $stats
                } -Depth 10
            } else {
                return ConvertTo-Json -InputObject $graph -Depth 10
            }
        }
    }
}

<#
.SYNOPSIS
    Exporte le graphe de dÃ©pendances des modules vers un fichier.

.DESCRIPTION
    Cette fonction exporte le graphe de dÃ©pendances des modules vers un fichier
    dans diffÃ©rents formats (JSON, CSV, XML, etc.).

.PARAMETER FilePath
    Chemin du fichier de sortie.

.PARAMETER Format
    Format de sortie du fichier. Les valeurs possibles sont: 'JSON', 'CSV', 'XML', 'YAML'.

.PARAMETER IncludeStats
    Indique si les statistiques du graphe doivent Ãªtre incluses dans le fichier.

.PARAMETER Force
    Indique si le fichier existant doit Ãªtre Ã©crasÃ©.

.EXAMPLE
    Export-ModuleDependencyGraph -FilePath 'C:\Temp\DependencyGraph.json' -Format 'JSON'
    Exporte le graphe de dÃ©pendances des modules vers un fichier JSON.

.OUTPUTS
    [System.IO.FileInfo] Informations sur le fichier crÃ©Ã©.
#>
function Export-ModuleDependencyGraph {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [ValidateSet('JSON', 'CSV', 'XML', 'YAML')]
        [string]$Format = 'JSON',

        [Parameter(Mandatory = $false)]
        [switch]$IncludeStats,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # VÃ©rifier si le graphe est vide
    if ($Global:MDT_DependencyGraph.Count -eq 0) {
        Write-Warning "Le graphe de dÃ©pendances est vide. ExÃ©cutez d'abord Invoke-ModuleDependencyExploration."
        return $null
    }

    # VÃ©rifier si le fichier existe dÃ©jÃ 
    if (Test-Path -Path $FilePath -PathType Leaf) {
        if (-not $Force) {
            Write-Warning "Le fichier '$FilePath' existe dÃ©jÃ . Utilisez -Force pour l'Ã©craser."
            return $null
        }
    }

    # Obtenir le graphe et les statistiques
    $graph = $Global:MDT_DependencyGraph
    $stats = $null
    if ($IncludeStats) {
        $moduleCount = $graph.Count
        $dependencyCount = ($graph.Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum
        $avgDependencies = if ($moduleCount -gt 0) { $dependencyCount / $moduleCount } else { 0 }
        $maxDependencies = ($graph.Values | ForEach-Object { $_.Count } | Measure-Object -Maximum).Maximum
        $minDependencies = ($graph.Values | ForEach-Object { $_.Count } | Measure-Object -Minimum).Minimum

        $stats = [PSCustomObject]@{
            ModuleCount         = $moduleCount
            DependencyCount     = $dependencyCount
            AverageDependencies = $avgDependencies
            MaxDependencies     = $maxDependencies
            MinDependencies     = $minDependencies
        }
    }

    # PrÃ©parer les donnÃ©es Ã  exporter
    $data = $null
    if ($IncludeStats) {
        $data = [PSCustomObject]@{
            Graph = $graph
            Stats = $stats
        }
    } else {
        $data = $graph
    }

    # Exporter les donnÃ©es selon le format demandÃ©
    try {
        switch ($Format) {
            'JSON' {
                $json = ConvertTo-Json -InputObject $data -Depth 10
                $json | Out-File -FilePath $FilePath -Encoding UTF8 -Force
            }
            'CSV' {
                $csv = @()
                foreach ($module in $graph.Keys) {
                    foreach ($dependency in $graph[$module]) {
                        $csv += [PSCustomObject]@{
                            Module     = $module
                            Dependency = $dependency
                        }
                    }
                }
                $csv | Export-Csv -Path $FilePath -NoTypeInformation -Encoding UTF8 -Force
            }
            'XML' {
                $xml = [PSCustomObject]@{
                    DependencyGraph = $data
                }
                $xml | Export-Clixml -Path $FilePath -Force
            }
            'YAML' {
                # PowerShell n'a pas de cmdlet native pour exporter en YAML
                # On utilise une approche simple basÃ©e sur des chaÃ®nes de caractÃ¨res
                $yaml = "---`n"
                $yaml += "# Module Dependency Graph`n"
                $yaml += "# Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"
                $yaml += "graph:`n"
                foreach ($module in $graph.Keys | Sort-Object) {
                    $yaml += "  ${module}:`n"
                    foreach ($dependency in $graph[$module] | Sort-Object) {
                        $yaml += "    - $dependency`n"
                    }
                }
                if ($IncludeStats) {
                    $yaml += "stats:`n"
                    $yaml += "  moduleCount: $($stats.ModuleCount)`n"
                    $yaml += "  dependencyCount: $($stats.DependencyCount)`n"
                    $yaml += "  averageDependencies: $($stats.AverageDependencies)`n"
                    $yaml += "  maxDependencies: $($stats.MaxDependencies)`n"
                    $yaml += "  minDependencies: $($stats.MinDependencies)`n"
                }
                $yaml | Out-File -FilePath $FilePath -Encoding UTF8 -Force
            }
        }

        # Retourner les informations sur le fichier crÃ©Ã©
        return Get-Item -Path $FilePath
    } catch {
        Write-Error "Erreur lors de l'exportation du graphe de dÃ©pendances: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Ajoute une dÃ©pendance au graphe de dÃ©pendances des modules.

.DESCRIPTION
    Cette fonction ajoute une dÃ©pendance entre deux modules dans le graphe de dÃ©pendances.

.PARAMETER ModuleName
    Nom du module source.

.PARAMETER DependencyName
    Nom du module dÃ©pendant.

.PARAMETER Force
    Indique si la dÃ©pendance doit Ãªtre ajoutÃ©e mÃªme si elle existe dÃ©jÃ .

.EXAMPLE
    Add-ModuleDependency -ModuleName 'MyModule' -DependencyName 'DependentModule'
    Ajoute une dÃ©pendance entre 'MyModule' et 'DependentModule'.

.OUTPUTS
    [System.Boolean] Indique si la dÃ©pendance a Ã©tÃ© ajoutÃ©e avec succÃ¨s.
#>
function Add-ModuleDependency {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,

        [Parameter(Mandatory = $true)]
        [string]$DependencyName,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # VÃ©rifier si le module source existe dans le graphe
    if (-not $Global:MDT_DependencyGraph.ContainsKey($ModuleName)) {
        $Global:MDT_DependencyGraph[$ModuleName] = @()
    }

    # VÃ©rifier si la dÃ©pendance existe dÃ©jÃ 
    if ($Global:MDT_DependencyGraph[$ModuleName] -contains $DependencyName) {
        if (-not $Force) {
            Write-Warning "La dÃ©pendance entre '$ModuleName' et '$DependencyName' existe dÃ©jÃ ."
            return $false
        }
    }

    # Ajouter la dÃ©pendance
    $Global:MDT_DependencyGraph[$ModuleName] = @($Global:MDT_DependencyGraph[$ModuleName]) + @($DependencyName)
    return $true
}

<#
.SYNOPSIS
    Supprime une dÃ©pendance du graphe de dÃ©pendances des modules.

.DESCRIPTION
    Cette fonction supprime une dÃ©pendance entre deux modules dans le graphe de dÃ©pendances.

.PARAMETER ModuleName
    Nom du module source.

.PARAMETER DependencyName
    Nom du module dÃ©pendant. Si non spÃ©cifiÃ©, supprime toutes les dÃ©pendances du module source.

.EXAMPLE
    Remove-ModuleDependency -ModuleName 'MyModule' -DependencyName 'DependentModule'
    Supprime la dÃ©pendance entre 'MyModule' et 'DependentModule'.

.OUTPUTS
    [System.Boolean] Indique si la dÃ©pendance a Ã©tÃ© supprimÃ©e avec succÃ¨s.
#>
function Remove-ModuleDependency {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,

        [Parameter(Mandatory = $false)]
        [string]$DependencyName
    )

    # VÃ©rifier si le module source existe dans le graphe
    if (-not $Global:MDT_DependencyGraph.ContainsKey($ModuleName)) {
        Write-Warning "Le module '$ModuleName' n'existe pas dans le graphe de dÃ©pendances."
        return $false
    }

    # Supprimer une dÃ©pendance spÃ©cifique ou toutes les dÃ©pendances
    if ($DependencyName) {
        # VÃ©rifier si la dÃ©pendance existe
        if ($Global:MDT_DependencyGraph[$ModuleName] -notcontains $DependencyName) {
            Write-Warning "La dÃ©pendance entre '$ModuleName' et '$DependencyName' n'existe pas."
            return $false
        }

        # Supprimer la dÃ©pendance
        $Global:MDT_DependencyGraph[$ModuleName] = @($Global:MDT_DependencyGraph[$ModuleName] | Where-Object { $_ -ne $DependencyName })
    } else {
        # Supprimer toutes les dÃ©pendances
        $Global:MDT_DependencyGraph[$ModuleName] = @()
    }

    return $true
}

<#
.SYNOPSIS
    RÃ©initialise le graphe de dÃ©pendances des modules.

.DESCRIPTION
    Cette fonction rÃ©initialise le graphe de dÃ©pendances des modules et les variables
    globales associÃ©es.

.PARAMETER KeepVisitedModules
    Indique si les modules visitÃ©s doivent Ãªtre conservÃ©s.

.EXAMPLE
    Reset-ModuleDependencyGraph
    RÃ©initialise le graphe de dÃ©pendances des modules.

.OUTPUTS
    Aucun.
#>
function Reset-ModuleDependencyGraph {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$KeepVisitedModules
    )

    # RÃ©initialiser le graphe de dÃ©pendances
    $Global:MDT_DependencyGraph = @{}

    # RÃ©initialiser les modules visitÃ©s si demandÃ©
    if (-not $KeepVisitedModules) {
        $Global:MDT_VisitedModules = @{}
    }

    # RÃ©initialiser la profondeur de rÃ©cursion
    $Global:MDT_CurrentRecursionDepth = 0

    Write-Verbose "Le graphe de dÃ©pendances a Ã©tÃ© rÃ©initialisÃ©."
}

<#
.SYNOPSIS
    DÃ©tecte les cycles dans le graphe de dÃ©pendances des modules.

.DESCRIPTION
    Cette fonction dÃ©tecte les cycles dans le graphe de dÃ©pendances des modules
    en utilisant l'algorithme de dÃ©tection de cycles dans un graphe orientÃ©.

.PARAMETER DependencyGraph
    Graphe de dÃ©pendances des modules. Si non spÃ©cifiÃ©, utilise le graphe global.

.PARAMETER IncludeAllCycles
    Indique si tous les cycles doivent Ãªtre dÃ©tectÃ©s. Par dÃ©faut, s'arrÃªte au premier cycle trouvÃ©.

.EXAMPLE
    $cycles = Find-ModuleDependencyCycles
    DÃ©tecte les cycles dans le graphe de dÃ©pendances des modules.

.EXAMPLE
    $cycles = Find-ModuleDependencyCycles -IncludeAllCycles
    DÃ©tecte tous les cycles dans le graphe de dÃ©pendances des modules.

.OUTPUTS
    [PSCustomObject] RÃ©sultat de la dÃ©tection des cycles.
#>
function Find-ModuleDependencyCycles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [hashtable]$DependencyGraph,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeAllCycles
    )

    # Utiliser le graphe global si non spÃ©cifiÃ©
    if (-not $DependencyGraph) {
        $DependencyGraph = $Global:MDT_DependencyGraph
    }

    # VÃ©rifier si le graphe est vide
    if ($DependencyGraph.Count -eq 0) {
        Write-Warning "Le graphe de dÃ©pendances est vide. ExÃ©cutez d'abord Invoke-ModuleDependencyExploration."
        return [PSCustomObject]@{
            HasCycles  = $false
            Cycles     = @()
            CycleCount = 0
        }
    }

    # Initialiser les variables
    $visited = @{}
    $recStack = @{}
    $cyclesList = [System.Collections.ArrayList]@()

    # Fonction rÃ©cursive pour dÃ©tecter les cycles
    function DetectCycle {
        param (
            [string]$Node,
            [System.Collections.ArrayList]$Path = $null
        )

        # Initialiser le chemin si nÃ©cessaire
        if ($null -eq $Path) {
            $Path = [System.Collections.ArrayList]@()
        }

        # Marquer le nÅ“ud comme visitÃ© et l'ajouter Ã  la pile de rÃ©cursion
        $visited[$Node] = $true
        $recStack[$Node] = $true
        [void]$Path.Add($Node)

        # Parcourir les voisins du nÅ“ud
        if ($DependencyGraph.ContainsKey($Node)) {
            foreach ($neighbor in $DependencyGraph[$Node]) {
                # Si le voisin n'a pas Ã©tÃ© visitÃ©, l'explorer
                if (-not $visited.ContainsKey($neighbor)) {
                    DetectCycle -Node $neighbor -Path $Path
                }
                # Si le voisin est dans la pile de rÃ©cursion, un cycle a Ã©tÃ© dÃ©tectÃ©
                elseif ($recStack.ContainsKey($neighbor) -and $recStack[$neighbor]) {
                    # CrÃ©er un cycle
                    $cycle = [System.Collections.ArrayList]@()
                    $startIndex = $Path.IndexOf($neighbor)

                    # Si le voisin est dans le chemin actuel, extraire le cycle
                    if ($startIndex -ge 0) {
                        for ($i = $startIndex; $i -lt $Path.Count; $i++) {
                            [void]$cycle.Add($Path[$i])
                        }
                        [void]$cycle.Add($neighbor)
                    } else {
                        # Sinon, crÃ©er un cycle simple
                        [void]$cycle.Add($Node)
                        [void]$cycle.Add($neighbor)
                    }

                    # Ajouter le cycle Ã  la liste des cycles
                    [void]$cyclesList.Add([PSCustomObject]@{
                            Nodes  = $cycle.ToArray()
                            Length = $cycle.Count
                            Path   = $cycle -join ' -> '
                        })

                    # Si on ne veut pas tous les cycles, on peut s'arrÃªter ici
                    if (-not $IncludeAllCycles) {
                        break
                    }
                }
            }
        }

        # Retirer le nÅ“ud de la pile de rÃ©cursion et du chemin
        $recStack[$Node] = $false
        [void]$Path.RemoveAt($Path.Count - 1)
    }

    # Parcourir tous les nÅ“uds du graphe
    foreach ($node in $DependencyGraph.Keys) {
        if (-not $visited.ContainsKey($node)) {
            $path = [System.Collections.ArrayList]@()
            DetectCycle -Node $node -Path $path

            # Si on a trouvÃ© un cycle et qu'on ne veut pas tous les cycles, on peut s'arrÃªter ici
            if ($cyclesList.Count -gt 0 -and -not $IncludeAllCycles) {
                break
            }
        }
    }

    # Retourner le rÃ©sultat
    return [PSCustomObject]@{
        HasCycles  = $cyclesList.Count -gt 0
        Cycles     = $cyclesList
        CycleCount = $cyclesList.Count
    }
}

<#
.SYNOPSIS
    RÃ©sout les dÃ©pendances circulaires dans le graphe de dÃ©pendances des modules.

.DESCRIPTION
    Cette fonction rÃ©sout les dÃ©pendances circulaires dans le graphe de dÃ©pendances des modules
    en supprimant les dÃ©pendances qui crÃ©ent des cycles.

.PARAMETER DependencyGraph
    Graphe de dÃ©pendances des modules. Si non spÃ©cifiÃ©, utilise le graphe global.

.PARAMETER UpdateGlobalGraph
    Indique si le graphe global doit Ãªtre mis Ã  jour avec les modifications.

.PARAMETER ReportOnly
    Indique si les cycles doivent Ãªtre uniquement rapportÃ©s sans Ãªtre rÃ©solus.

.EXAMPLE
    $result = Resolve-ModuleDependencyCycles
    RÃ©sout les dÃ©pendances circulaires dans le graphe de dÃ©pendances des modules.

.EXAMPLE
    $result = Resolve-ModuleDependencyCycles -ReportOnly
    Rapporte les dÃ©pendances circulaires sans les rÃ©soudre.

.OUTPUTS
    [PSCustomObject] RÃ©sultat de la rÃ©solution des cycles.
#>
function Resolve-ModuleDependencyCycles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [hashtable]$DependencyGraph,

        [Parameter(Mandatory = $false)]
        [switch]$UpdateGlobalGraph,

        [Parameter(Mandatory = $false)]
        [switch]$ReportOnly
    )

    # Utiliser le graphe global si non spÃ©cifiÃ©
    if (-not $DependencyGraph) {
        $DependencyGraph = $Global:MDT_DependencyGraph.Clone()
    } else {
        # Cloner le graphe pour ne pas modifier l'original
        $DependencyGraph = $DependencyGraph.Clone()
    }

    # DÃ©tecter les cycles
    $cyclesResult = Find-ModuleDependencyCycles -DependencyGraph $DependencyGraph -IncludeAllCycles

    # VÃ©rifier s'il y a des cycles
    if (-not $cyclesResult.HasCycles) {
        Write-Verbose "Aucun cycle dÃ©tectÃ© dans le graphe de dÃ©pendances."
        return [PSCustomObject]@{
            HasCycles          = $false
            ResolvedCycles     = @()
            ResolvedCycleCount = 0
            ModifiedGraph      = $DependencyGraph
        }
    }

    # Initialiser la liste des cycles rÃ©solus
    $resolvedCycles = [System.Collections.ArrayList]@()

    # RÃ©soudre les cycles si demandÃ©
    if (-not $ReportOnly) {
        foreach ($cycle in $cyclesResult.Cycles) {
            # DÃ©terminer la dÃ©pendance Ã  supprimer
            $cycleNodes = $cycle.Nodes
            $lastNode = $cycleNodes[$cycleNodes.Count - 2]  # L'avant-dernier nÅ“ud
            $firstNode = $cycleNodes[$cycleNodes.Count - 1]  # Le dernier nÅ“ud (qui est le mÃªme que le premier)

            # Supprimer la dÃ©pendance
            if ($DependencyGraph.ContainsKey($lastNode) -and $DependencyGraph[$lastNode] -contains $firstNode) {
                $DependencyGraph[$lastNode] = @($DependencyGraph[$lastNode] | Where-Object { $_ -ne $firstNode })

                # Ajouter le cycle rÃ©solu Ã  la liste
                [void]$resolvedCycles.Add([PSCustomObject]@{
                        Nodes             = $cycleNodes
                        Length            = $cycle.Length
                        Path              = $cycle.Path
                        RemovedDependency = "$lastNode -> $firstNode"
                    })
            }
        }

        # Mettre Ã  jour le graphe global si demandÃ©
        if ($UpdateGlobalGraph) {
            $Global:MDT_DependencyGraph = $DependencyGraph
        }
    } else {
        # Copier les cycles dÃ©tectÃ©s dans la liste des cycles rÃ©solus
        foreach ($cycle in $cyclesResult.Cycles) {
            [void]$resolvedCycles.Add($cycle)
        }
    }

    # Retourner le rÃ©sultat
    return [PSCustomObject]@{
        HasCycles          = $cyclesResult.HasCycles
        ResolvedCycles     = $resolvedCycles
        ResolvedCycleCount = $resolvedCycles.Count
        ModifiedGraph      = $DependencyGraph
    }
}

<#
.SYNOPSIS
    Obtient les dÃ©pendances rÃ©cursives d'un module PowerShell.

.DESCRIPTION
    Cette fonction obtient les dÃ©pendances rÃ©cursives d'un module PowerShell
    en explorant le graphe de dÃ©pendances.

.PARAMETER ModuleName
    Nom du module PowerShell Ã  analyser.

.PARAMETER ModulePath
    Chemin du module PowerShell Ã  analyser. Si non spÃ©cifiÃ©, le module sera recherchÃ©
    dans les chemins de modules standards.

.PARAMETER MaxDepth
    Profondeur maximale de rÃ©cursion. Par dÃ©faut, 10.

.PARAMETER SkipSystemModules
    Indique si les modules systÃ¨me doivent Ãªtre exclus des rÃ©sultats.

.PARAMETER ResolveModulePaths
    Indique si les chemins des modules dÃ©pendants doivent Ãªtre rÃ©solus.

.PARAMETER IncludeStats
    Indique si les statistiques doivent Ãªtre incluses dans les rÃ©sultats.

.PARAMETER DetectCycles
    Indique si les cycles doivent Ãªtre dÃ©tectÃ©s.

.EXAMPLE
    $dependencies = Get-ModuleDependencies -ModuleName 'MyModule'
    Obtient les dÃ©pendances rÃ©cursives du module 'MyModule'.

.EXAMPLE
    $dependencies = Get-ModuleDependencies -ModulePath 'C:\Modules\MyModule\MyModule.psd1' -MaxDepth 5 -SkipSystemModules -DetectCycles
    Obtient les dÃ©pendances rÃ©cursives du module situÃ© Ã  'C:\Modules\MyModule\MyModule.psd1', en limitant la profondeur Ã  5, en excluant les modules systÃ¨me et en dÃ©tectant les cycles.

.OUTPUTS
    [PSCustomObject] RÃ©sultat de l'analyse des dÃ©pendances.
#>
function Get-ModuleDependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'ByName')]
        [string]$ModuleName,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByPath')]
        [string]$ModulePath,

        [Parameter(Mandatory = $false)]
        [int]$MaxDepth = 10,

        [Parameter(Mandatory = $false)]
        [switch]$SkipSystemModules,

        [Parameter(Mandatory = $false)]
        [switch]$ResolveModulePaths,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeStats,

        [Parameter(Mandatory = $false)]
        [switch]$DetectCycles
    )

    # Initialiser les variables globales
    $Global:MDT_VisitedModules = @{}
    $Global:MDT_DependencyGraph = @{}
    $Global:MDT_MaxRecursionDepth = $MaxDepth
    $Global:MDT_CurrentRecursionDepth = 0

    # Explorer les dÃ©pendances du module
    if ($PSCmdlet.ParameterSetName -eq 'ByName') {
        Invoke-ModuleDependencyExploration -ModuleName $ModuleName -CurrentDepth 0 -SkipSystemModules:$SkipSystemModules -ResolveModulePaths:$ResolveModulePaths
    } else {
        Invoke-ModuleDependencyExploration -ModulePath $ModulePath -CurrentDepth 0 -SkipSystemModules:$SkipSystemModules -ResolveModulePaths:$ResolveModulePaths
    }

    # Obtenir les statistiques si demandÃ©
    $stats = $null
    if ($IncludeStats) {
        $stats = Get-ModuleVisitStatistics
    }

    # DÃ©tecter les cycles si demandÃ©
    $cycles = $null
    if ($DetectCycles) {
        $cycles = Find-ModuleDependencyCycles
    }

    # Retourner le rÃ©sultat
    $result = [PSCustomObject]@{
        ModuleName      = if ($PSCmdlet.ParameterSetName -eq 'ByName') { $ModuleName } else { [System.IO.Path]::GetFileNameWithoutExtension($ModulePath) }
        DependencyGraph = $Global:MDT_DependencyGraph
        VisitedModules  = $Global:MDT_VisitedModules.Keys
        MaxDepth        = $MaxDepth
    }

    if ($IncludeStats) {
        $result | Add-Member -MemberType NoteProperty -Name 'Stats' -Value $stats
    }

    if ($DetectCycles) {
        $result | Add-Member -MemberType NoteProperty -Name 'Cycles' -Value $cycles
    }

    return $result
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Get-ModuleDirectDependencies, Get-ModuleDependenciesFromManifest, Get-ModuleDependenciesFromCode, Invoke-ModuleDependencyExploration, Get-ModuleVisitStatistics, Get-ModuleDependencyGraph, Export-ModuleDependencyGraph, Add-ModuleDependency, Remove-ModuleDependency, Reset-ModuleDependencyGraph, Find-ModuleDependencyCycles, Resolve-ModuleDependencyCycles, Get-ModuleDependencies
