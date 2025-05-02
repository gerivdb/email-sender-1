#Requires -Version 5.1

<#
.SYNOPSIS
    Module pour l'analyse récursive des dépendances de modules PowerShell.

.DESCRIPTION
    Ce module fournit des fonctions pour analyser les dépendances directes et indirectes
    des modules PowerShell, construire un graphe de dépendances et détecter les cycles.

.NOTES
    Auteur: Dependency Management Team
    Version: 1.0
    Date de création: 2023-06-15
#>

# Importer les modules requis s'ils ne sont pas déjà importés
$moduleRoot = $PSScriptRoot
$functionCallParserPath = Join-Path -Path $moduleRoot -ChildPath 'FunctionCallParser.psm1'
$importedFunctionDetectorPath = Join-Path -Path $moduleRoot -ChildPath 'ImportedFunctionDetector.psm1'
$functionDependencyAnalyzerPath = Join-Path -Path $moduleRoot -ChildPath 'FunctionDependencyAnalyzer.psm1'
$simpleCycleDetectorPath = Join-Path -Path $moduleRoot -ChildPath 'SimpleCycleDetector.psm1'

if (-not (Get-Module -Name 'FunctionCallParser')) {
    if (Test-Path -Path $functionCallParserPath) {
        Import-Module -Name $functionCallParserPath -Force
    } else {
        Write-Warning "Le module FunctionCallParser est requis mais n'a pas été trouvé à l'emplacement: $functionCallParserPath"
    }
}

if (-not (Get-Module -Name 'ImportedFunctionDetector')) {
    if (Test-Path -Path $importedFunctionDetectorPath) {
        Import-Module -Name $importedFunctionDetectorPath -Force
    } else {
        Write-Warning "Le module ImportedFunctionDetector est requis mais n'a pas été trouvé à l'emplacement: $importedFunctionDetectorPath"
    }
}

if (-not (Get-Module -Name 'FunctionDependencyAnalyzer')) {
    if (Test-Path -Path $functionDependencyAnalyzerPath) {
        Import-Module -Name $functionDependencyAnalyzerPath -Force
    } else {
        Write-Warning "Le module FunctionDependencyAnalyzer est requis mais n'a pas été trouvé à l'emplacement: $functionDependencyAnalyzerPath"
    }
}

if (-not (Get-Module -Name 'SimpleCycleDetector')) {
    if (Test-Path -Path $simpleCycleDetectorPath) {
        Import-Module -Name $simpleCycleDetectorPath -Force
    } else {
        Write-Warning "Le module SimpleCycleDetector est requis mais n'a pas été trouvé à l'emplacement: $simpleCycleDetectorPath"
    }
}

# Variables globales pour le module
$Global:MDT_VisitedModules = @{}
$Global:MDT_DependencyGraph = @{}
$Global:MDT_MaxRecursionDepth = 10
$Global:MDT_CurrentRecursionDepth = 0

# Alias pour la compatibilité avec le code existant
$script:VisitedModules = $Global:MDT_VisitedModules
$script:DependencyGraph = $Global:MDT_DependencyGraph
$script:MaxRecursionDepth = $Global:MDT_MaxRecursionDepth
$script:CurrentRecursionDepth = $Global:MDT_CurrentRecursionDepth

<#
.SYNOPSIS
    Obtient les dépendances directes d'un module PowerShell.

.DESCRIPTION
    Cette fonction analyse un module PowerShell et détecte ses dépendances directes
    en analysant son manifeste (.psd1) et son code (.psm1).

.PARAMETER ModuleName
    Nom du module PowerShell à analyser.

.PARAMETER ModulePath
    Chemin du module PowerShell à analyser. Si non spécifié, le module sera recherché
    dans les chemins de modules standards.

.PARAMETER SkipSystemModules
    Indique si les modules système doivent être exclus des résultats.

.PARAMETER ResolveModulePaths
    Indique si les chemins des modules dépendants doivent être résolus.

.EXAMPLE
    $dependencies = Get-ModuleDirectDependencies -ModuleName 'MyModule'
    Obtient les dépendances directes du module 'MyModule'.

.EXAMPLE
    $dependencies = Get-ModuleDirectDependencies -ModulePath 'C:\Modules\MyModule\MyModule.psd1' -SkipSystemModules
    Obtient les dépendances directes du module situé à 'C:\Modules\MyModule\MyModule.psd1', en excluant les modules système.

.OUTPUTS
    [PSCustomObject[]] Liste des dépendances directes du module.
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
        # Liste des modules système PowerShell
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

        # Fonction interne pour vérifier si un module est un module système
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
            # Initialiser la liste des dépendances
            $dependencies = [System.Collections.ArrayList]::new()

            # Obtenir le chemin du module si nécessaire
            if ($PSCmdlet.ParameterSetName -eq 'ByName') {
                $module = Get-Module -Name $ModuleName -ListAvailable | Select-Object -First 1
                if (-not $module) {
                    Write-Warning "Le module '$ModuleName' n'a pas été trouvé."
                    return $dependencies
                }
                $ModulePath = $module.Path
            }

            # Vérifier si le fichier existe
            if (-not (Test-Path -Path $ModulePath -PathType Leaf)) {
                Write-Warning "Le fichier module n'existe pas: $ModulePath"
                return $dependencies
            }

            # Déterminer le type de fichier (psd1 ou psm1)
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

            # Obtenir les dépendances du manifeste
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
                # Obtenir le chemin du module à partir du manifeste
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

            # Obtenir les dépendances du code du module
            if ($modulePath) {
                $codeDependencies = Get-ModuleDependenciesFromCode -ModulePath $modulePath -SkipSystemModules:$SkipSystemModules -ResolveModulePaths:$ResolveModulePaths
                foreach ($dependency in $codeDependencies) {
                    # Vérifier si la dépendance existe déjà
                    $existingDependency = $dependencies | Where-Object { $_.Name -eq $dependency.Name }
                    if (-not $existingDependency) {
                        [void]$dependencies.Add($dependency)
                    }
                }
            }

            # Filtrer les modules système si demandé
            if ($SkipSystemModules) {
                $dependencies = $dependencies | Where-Object { -not (Test-SystemModule -ModuleName $_.Name) }
            }

            # Résoudre les chemins des modules si demandé
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
            Write-Error "Erreur lors de l'obtention des dépendances directes du module: $_"
            return @()
        }
    }
}

<#
.SYNOPSIS
    Obtient les dépendances d'un module PowerShell à partir de son manifeste.

.DESCRIPTION
    Cette fonction analyse le manifeste d'un module PowerShell (.psd1) et détecte
    ses dépendances explicites (RequiredModules, NestedModules).

.PARAMETER ManifestPath
    Chemin du manifeste du module PowerShell (.psd1) à analyser.

.PARAMETER SkipSystemModules
    Indique si les modules système doivent être exclus des résultats.

.PARAMETER ResolveModulePaths
    Indique si les chemins des modules dépendants doivent être résolus.

.EXAMPLE
    $dependencies = Get-ModuleDependenciesFromManifest -ManifestPath 'C:\Modules\MyModule\MyModule.psd1'
    Obtient les dépendances du module à partir de son manifeste.

.OUTPUTS
    [PSCustomObject[]] Liste des dépendances du module extraites du manifeste.
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

    # Initialiser la liste des dépendances
    $dependencies = [System.Collections.ArrayList]::new()

    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $ManifestPath -PathType Leaf)) {
        Write-Warning "Le fichier manifeste n'existe pas: $ManifestPath"
        return $dependencies
    }

    # Vérifier l'extension du fichier
    $extension = [System.IO.Path]::GetExtension($ManifestPath)
    if ($extension -ne '.psd1') {
        Write-Warning "Le fichier spécifié n'est pas un fichier .psd1: $ManifestPath"
        return $dependencies
    }

    try {
        # Importer le manifeste
        $manifest = Import-PowerShellDataFile -Path $ManifestPath -ErrorAction Stop

        # Extraire les dépendances RequiredModules
        if ($manifest.ContainsKey('RequiredModules') -and $manifest.RequiredModules) {
            Write-Verbose "Analyse des RequiredModules dans le manifeste: $ManifestPath"

            # RequiredModules peut être une chaîne, un tableau de chaînes, ou un tableau d'objets
            foreach ($requiredModule in $manifest.RequiredModules) {
                $moduleName = $null
                $moduleVersion = $null
                $modulePath = $null

                # Déterminer le format du module requis
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

                # Ajouter la dépendance à la liste
                [void]$dependencies.Add([PSCustomObject]@{
                        Name    = $moduleName
                        Version = $moduleVersion
                        Path    = $modulePath
                        Type    = 'RequiredModule'
                        Source  = $ManifestPath
                    })
            }
        }

        # Extraire les dépendances NestedModules
        if ($manifest.ContainsKey('NestedModules') -and $manifest.NestedModules) {
            Write-Verbose "Analyse des NestedModules dans le manifeste: $ManifestPath"

            # NestedModules peut être une chaîne, un tableau de chaînes, ou un tableau d'objets
            foreach ($nestedModule in $manifest.NestedModules) {
                $moduleName = $null
                $moduleVersion = $null
                $modulePath = $null

                # Déterminer le format du module imbriqué
                if ($nestedModule -is [string]) {
                    # Format simple: 'ModuleName' ou chemin relatif
                    $moduleName = $nestedModule

                    # Vérifier si c'est un chemin relatif
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

                # Ajouter la dépendance à la liste
                [void]$dependencies.Add([PSCustomObject]@{
                        Name    = $moduleName
                        Version = $moduleVersion
                        Path    = $modulePath
                        Type    = 'NestedModule'
                        Source  = $ManifestPath
                    })
            }
        }

        # Extraire la dépendance RootModule/ModuleToProcess
        if ($manifest.ContainsKey('RootModule') -and $manifest.RootModule) {
            $rootModule = $manifest.RootModule

            # Vérifier si c'est un module externe (pas un fichier .psm1 local)
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

            # Vérifier si c'est un module externe (pas un fichier .psm1 local)
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
    Obtient les dépendances d'un module PowerShell à partir de son code.

.DESCRIPTION
    Cette fonction analyse le code d'un module PowerShell (.psm1) et détecte
    ses dépendances implicites (Import-Module, using module).

.PARAMETER ModulePath
    Chemin du fichier de code du module PowerShell (.psm1) à analyser.

.PARAMETER SkipSystemModules
    Indique si les modules système doivent être exclus des résultats.

.PARAMETER ResolveModulePaths
    Indique si les chemins des modules dépendants doivent être résolus.

.PARAMETER IncludeScriptDependencies
    Indique si les dépendances des scripts dot-sourcés doivent être incluses.

.EXAMPLE
    $dependencies = Get-ModuleDependenciesFromCode -ModulePath 'C:\Modules\MyModule\MyModule.psm1'
    Obtient les dépendances du module à partir de son code.

.OUTPUTS
    [PSCustomObject[]] Liste des dépendances du module extraites du code.
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

    # Initialiser la liste des dépendances
    $dependencies = [System.Collections.ArrayList]::new()

    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $ModulePath -PathType Leaf)) {
        Write-Warning "Le fichier module n'existe pas: $ModulePath"
        return $dependencies
    }

    try {
        # Charger le contenu du fichier
        $content = Get-Content -Path $ModulePath -Raw -ErrorAction Stop

        # Détecter les Import-Module
        $importMatches = [regex]::Matches($content, '(?m)^\s*Import-Module\s+(?:-Name\s+)?([''"]?)([^''"\s]+)\1')
        foreach ($match in $importMatches) {
            $moduleName = $match.Groups[2].Value

            # Ajouter la dépendance à la liste
            [void]$dependencies.Add([PSCustomObject]@{
                    Name    = $moduleName
                    Version = $null
                    Path    = $null
                    Type    = 'ImportModule'
                    Source  = $ModulePath
                })
        }

        # Détecter les using module
        $usingMatches = [regex]::Matches($content, '(?m)^\s*using\s+module\s+([''"]?)([^''"\s]+)\1')
        foreach ($match in $usingMatches) {
            $moduleName = $match.Groups[2].Value

            # Ajouter la dépendance à la liste
            [void]$dependencies.Add([PSCustomObject]@{
                    Name    = $moduleName
                    Version = $null
                    Path    = $null
                    Type    = 'UsingModule'
                    Source  = $ModulePath
                })
        }

        # Détecter les #Requires -Modules
        $requiresMatches = [regex]::Matches($content, '(?m)^\s*#Requires\s+-Modules\s+(.+)$')
        foreach ($match in $requiresMatches) {
            $modulesList = $match.Groups[1].Value

            # Analyser la liste des modules requis
            $moduleNames = $modulesList -split ',' | ForEach-Object { $_.Trim() }
            foreach ($moduleName in $moduleNames) {
                # Supprimer les guillemets si présents
                $moduleName = $moduleName -replace '^[''"]|[''"]$', ''

                # Ajouter la dépendance à la liste
                [void]$dependencies.Add([PSCustomObject]@{
                        Name    = $moduleName
                        Version = $null
                        Path    = $null
                        Type    = 'RequiresModule'
                        Source  = $ModulePath
                    })
            }
        }

        # Analyser les scripts dot-sourcés si demandé
        if ($IncludeScriptDependencies) {
            $moduleDir = Split-Path -Path $ModulePath -Parent
            $dotSourceMatches = [regex]::Matches($content, '(?m)^\s*\.\s+([''"]?)([^''"\s]+)\1')
            foreach ($match in $dotSourceMatches) {
                $scriptPath = $match.Groups[2].Value

                # Résoudre le chemin complet du script
                if (-not [System.IO.Path]::IsPathRooted($scriptPath)) {
                    $scriptPath = Join-Path -Path $moduleDir -ChildPath $scriptPath
                }

                # Vérifier si le script existe
                if (Test-Path -Path $scriptPath -PathType Leaf) {
                    # Analyser les dépendances du script
                    $scriptDependencies = Get-ModuleDependenciesFromCode -ModulePath $scriptPath -SkipSystemModules:$SkipSystemModules -ResolveModulePaths:$ResolveModulePaths
                    foreach ($dependency in $scriptDependencies) {
                        # Vérifier si la dépendance existe déjà
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
    Explore récursivement les dépendances d'un module PowerShell.

.DESCRIPTION
    Cette fonction explore récursivement les dépendances d'un module PowerShell
    en utilisant un algorithme de parcours en profondeur (DFS).

.PARAMETER ModuleName
    Nom du module PowerShell à explorer.

.PARAMETER ModulePath
    Chemin du module PowerShell à explorer. Si non spécifié, le module sera recherché
    dans les chemins de modules standards.

.PARAMETER CurrentDepth
    Profondeur actuelle de récursion. Utilisé en interne pour limiter la profondeur.

.PARAMETER SkipSystemModules
    Indique si les modules système doivent être exclus des résultats.

.PARAMETER ResolveModulePaths
    Indique si les chemins des modules dépendants doivent être résolus.

.EXAMPLE
    Invoke-ModuleDependencyExploration -ModuleName 'MyModule' -CurrentDepth 0
    Explore récursivement les dépendances du module 'MyModule'.

.OUTPUTS
    Aucun. Les résultats sont stockés dans les variables globales du script.
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

    # Vérifier la profondeur de récursion
    if ($CurrentDepth -gt $Global:MDT_MaxRecursionDepth) {
        Write-Verbose "Profondeur maximale de récursion atteinte pour le module: $ModuleName"
        return
    }

    # Déterminer le nom du module si le chemin est fourni
    if ($PSCmdlet.ParameterSetName -eq 'ByPath') {
        $ModuleName = [System.IO.Path]::GetFileNameWithoutExtension($ModulePath)
    }

    # Vérifier si le module a déjà été visité
    if ($Global:MDT_VisitedModules.ContainsKey($ModuleName)) {
        Write-Verbose "Module déjà visité: $ModuleName"
        return
    }

    # Marquer le module comme visité
    $Global:MDT_VisitedModules[$ModuleName] = @{
        Visited   = $true
        VisitedAt = Get-Date
        Depth     = $CurrentDepth
    }

    Write-Verbose "Exploration des dépendances du module: $ModuleName (Profondeur: $CurrentDepth)"

    # Obtenir les dépendances directes du module
    $dependencies = $null
    if ($PSCmdlet.ParameterSetName -eq 'ByName') {
        $dependencies = Get-ModuleDirectDependencies -ModuleName $ModuleName -SkipSystemModules:$SkipSystemModules -ResolveModulePaths:$ResolveModulePaths
    } else {
        $dependencies = Get-ModuleDirectDependencies -ModulePath $ModulePath -SkipSystemModules:$SkipSystemModules -ResolveModulePaths:$ResolveModulePaths
    }

    # Ajouter les dépendances au graphe
    $dependencyNames = $dependencies | Select-Object -ExpandProperty Name -Unique
    $Global:MDT_DependencyGraph[$ModuleName] = $dependencyNames

    # Explorer récursivement les dépendances
    foreach ($dependency in $dependencies) {
        $dependencyName = $dependency.Name
        $dependencyPath = $dependency.Path

        # Explorer la dépendance
        if ($dependencyPath) {
            Invoke-ModuleDependencyExploration -ModulePath $dependencyPath -CurrentDepth ($CurrentDepth + 1) -SkipSystemModules:$SkipSystemModules -ResolveModulePaths:$ResolveModulePaths
        } else {
            Invoke-ModuleDependencyExploration -ModuleName $dependencyName -CurrentDepth ($CurrentDepth + 1) -SkipSystemModules:$SkipSystemModules -ResolveModulePaths:$ResolveModulePaths
        }
    }
}

<#
.SYNOPSIS
    Obtient les statistiques des modules visités lors de l'exploration des dépendances.

.DESCRIPTION
    Cette fonction retourne des statistiques sur les modules visités lors de l'exploration
    des dépendances, notamment le nombre de modules visités, la profondeur maximale, etc.

.EXAMPLE
    $stats = Get-ModuleVisitStatistics
    Obtient les statistiques des modules visités.

.OUTPUTS
    [PSCustomObject] Statistiques des modules visités.
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
    Obtient le graphe de dépendances des modules.

.DESCRIPTION
    Cette fonction retourne le graphe de dépendances des modules construit lors de l'exploration
    des dépendances. Le graphe est représenté par une table de hachage où les clés sont les noms
    des modules et les valeurs sont des listes de noms de modules dépendants.

.PARAMETER ModuleName
    Nom du module pour lequel obtenir les dépendances. Si non spécifié, retourne le graphe complet.

.PARAMETER IncludeStats
    Indique si les statistiques du graphe doivent être incluses dans les résultats.

.PARAMETER Format
    Format de sortie du graphe. Les valeurs possibles sont: 'HashTable', 'PSObject', 'JSON'.

.EXAMPLE
    $graph = Get-ModuleDependencyGraph
    Obtient le graphe complet de dépendances des modules.

.EXAMPLE
    $moduleDependencies = Get-ModuleDependencyGraph -ModuleName 'MyModule'
    Obtient les dépendances directes du module 'MyModule'.

.OUTPUTS
    [System.Collections.Hashtable] ou [PSCustomObject] Graphe de dépendances des modules.
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

    # Vérifier si le graphe est vide
    if ($Global:MDT_DependencyGraph.Count -eq 0) {
        Write-Warning "Le graphe de dépendances est vide. Exécutez d'abord Invoke-ModuleDependencyExploration."
        return $null
    }

    # Obtenir le graphe pour un module spécifique ou le graphe complet
    $graph = $null
    if ($ModuleName) {
        if (-not $Global:MDT_DependencyGraph.ContainsKey($ModuleName)) {
            Write-Warning "Le module '$ModuleName' n'existe pas dans le graphe de dépendances."
            return $null
        }
        $graph = @{ $ModuleName = $Global:MDT_DependencyGraph[$ModuleName] }
    } else {
        $graph = $Global:MDT_DependencyGraph
    }

    # Calculer les statistiques si demandé
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

    # Formater le résultat selon le format demandé
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
    Exporte le graphe de dépendances des modules vers un fichier.

.DESCRIPTION
    Cette fonction exporte le graphe de dépendances des modules vers un fichier
    dans différents formats (JSON, CSV, XML, etc.).

.PARAMETER FilePath
    Chemin du fichier de sortie.

.PARAMETER Format
    Format de sortie du fichier. Les valeurs possibles sont: 'JSON', 'CSV', 'XML', 'YAML'.

.PARAMETER IncludeStats
    Indique si les statistiques du graphe doivent être incluses dans le fichier.

.PARAMETER Force
    Indique si le fichier existant doit être écrasé.

.EXAMPLE
    Export-ModuleDependencyGraph -FilePath 'C:\Temp\DependencyGraph.json' -Format 'JSON'
    Exporte le graphe de dépendances des modules vers un fichier JSON.

.OUTPUTS
    [System.IO.FileInfo] Informations sur le fichier créé.
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

    # Vérifier si le graphe est vide
    if ($Global:MDT_DependencyGraph.Count -eq 0) {
        Write-Warning "Le graphe de dépendances est vide. Exécutez d'abord Invoke-ModuleDependencyExploration."
        return $null
    }

    # Vérifier si le fichier existe déjà
    if (Test-Path -Path $FilePath -PathType Leaf) {
        if (-not $Force) {
            Write-Warning "Le fichier '$FilePath' existe déjà. Utilisez -Force pour l'écraser."
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

    # Préparer les données à exporter
    $data = $null
    if ($IncludeStats) {
        $data = [PSCustomObject]@{
            Graph = $graph
            Stats = $stats
        }
    } else {
        $data = $graph
    }

    # Exporter les données selon le format demandé
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
                # On utilise une approche simple basée sur des chaînes de caractères
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

        # Retourner les informations sur le fichier créé
        return Get-Item -Path $FilePath
    } catch {
        Write-Error "Erreur lors de l'exportation du graphe de dépendances: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Ajoute une dépendance au graphe de dépendances des modules.

.DESCRIPTION
    Cette fonction ajoute une dépendance entre deux modules dans le graphe de dépendances.

.PARAMETER ModuleName
    Nom du module source.

.PARAMETER DependencyName
    Nom du module dépendant.

.PARAMETER Force
    Indique si la dépendance doit être ajoutée même si elle existe déjà.

.EXAMPLE
    Add-ModuleDependency -ModuleName 'MyModule' -DependencyName 'DependentModule'
    Ajoute une dépendance entre 'MyModule' et 'DependentModule'.

.OUTPUTS
    [System.Boolean] Indique si la dépendance a été ajoutée avec succès.
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

    # Vérifier si le module source existe dans le graphe
    if (-not $Global:MDT_DependencyGraph.ContainsKey($ModuleName)) {
        $Global:MDT_DependencyGraph[$ModuleName] = @()
    }

    # Vérifier si la dépendance existe déjà
    if ($Global:MDT_DependencyGraph[$ModuleName] -contains $DependencyName) {
        if (-not $Force) {
            Write-Warning "La dépendance entre '$ModuleName' et '$DependencyName' existe déjà."
            return $false
        }
    }

    # Ajouter la dépendance
    $Global:MDT_DependencyGraph[$ModuleName] = @($Global:MDT_DependencyGraph[$ModuleName]) + @($DependencyName)
    return $true
}

<#
.SYNOPSIS
    Supprime une dépendance du graphe de dépendances des modules.

.DESCRIPTION
    Cette fonction supprime une dépendance entre deux modules dans le graphe de dépendances.

.PARAMETER ModuleName
    Nom du module source.

.PARAMETER DependencyName
    Nom du module dépendant. Si non spécifié, supprime toutes les dépendances du module source.

.EXAMPLE
    Remove-ModuleDependency -ModuleName 'MyModule' -DependencyName 'DependentModule'
    Supprime la dépendance entre 'MyModule' et 'DependentModule'.

.OUTPUTS
    [System.Boolean] Indique si la dépendance a été supprimée avec succès.
#>
function Remove-ModuleDependency {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,

        [Parameter(Mandatory = $false)]
        [string]$DependencyName
    )

    # Vérifier si le module source existe dans le graphe
    if (-not $Global:MDT_DependencyGraph.ContainsKey($ModuleName)) {
        Write-Warning "Le module '$ModuleName' n'existe pas dans le graphe de dépendances."
        return $false
    }

    # Supprimer une dépendance spécifique ou toutes les dépendances
    if ($DependencyName) {
        # Vérifier si la dépendance existe
        if ($Global:MDT_DependencyGraph[$ModuleName] -notcontains $DependencyName) {
            Write-Warning "La dépendance entre '$ModuleName' et '$DependencyName' n'existe pas."
            return $false
        }

        # Supprimer la dépendance
        $Global:MDT_DependencyGraph[$ModuleName] = @($Global:MDT_DependencyGraph[$ModuleName] | Where-Object { $_ -ne $DependencyName })
    } else {
        # Supprimer toutes les dépendances
        $Global:MDT_DependencyGraph[$ModuleName] = @()
    }

    return $true
}

<#
.SYNOPSIS
    Réinitialise le graphe de dépendances des modules.

.DESCRIPTION
    Cette fonction réinitialise le graphe de dépendances des modules et les variables
    globales associées.

.PARAMETER KeepVisitedModules
    Indique si les modules visités doivent être conservés.

.EXAMPLE
    Reset-ModuleDependencyGraph
    Réinitialise le graphe de dépendances des modules.

.OUTPUTS
    Aucun.
#>
function Reset-ModuleDependencyGraph {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$KeepVisitedModules
    )

    # Réinitialiser le graphe de dépendances
    $Global:MDT_DependencyGraph = @{}

    # Réinitialiser les modules visités si demandé
    if (-not $KeepVisitedModules) {
        $Global:MDT_VisitedModules = @{}
    }

    # Réinitialiser la profondeur de récursion
    $Global:MDT_CurrentRecursionDepth = 0

    Write-Verbose "Le graphe de dépendances a été réinitialisé."
}

<#
.SYNOPSIS
    Détecte les cycles dans le graphe de dépendances des modules.

.DESCRIPTION
    Cette fonction détecte les cycles dans le graphe de dépendances des modules
    en utilisant l'algorithme de détection de cycles dans un graphe orienté.

.PARAMETER DependencyGraph
    Graphe de dépendances des modules. Si non spécifié, utilise le graphe global.

.PARAMETER IncludeAllCycles
    Indique si tous les cycles doivent être détectés. Par défaut, s'arrête au premier cycle trouvé.

.EXAMPLE
    $cycles = Find-ModuleDependencyCycles
    Détecte les cycles dans le graphe de dépendances des modules.

.EXAMPLE
    $cycles = Find-ModuleDependencyCycles -IncludeAllCycles
    Détecte tous les cycles dans le graphe de dépendances des modules.

.OUTPUTS
    [PSCustomObject] Résultat de la détection des cycles.
#>
function Find-ModuleDependencyCycles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [hashtable]$DependencyGraph,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeAllCycles
    )

    # Utiliser le graphe global si non spécifié
    if (-not $DependencyGraph) {
        $DependencyGraph = $Global:MDT_DependencyGraph
    }

    # Vérifier si le graphe est vide
    if ($DependencyGraph.Count -eq 0) {
        Write-Warning "Le graphe de dépendances est vide. Exécutez d'abord Invoke-ModuleDependencyExploration."
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

    # Fonction récursive pour détecter les cycles
    function DetectCycle {
        param (
            [string]$Node,
            [System.Collections.ArrayList]$Path = $null
        )

        # Initialiser le chemin si nécessaire
        if ($null -eq $Path) {
            $Path = [System.Collections.ArrayList]@()
        }

        # Marquer le nœud comme visité et l'ajouter à la pile de récursion
        $visited[$Node] = $true
        $recStack[$Node] = $true
        [void]$Path.Add($Node)

        # Parcourir les voisins du nœud
        if ($DependencyGraph.ContainsKey($Node)) {
            foreach ($neighbor in $DependencyGraph[$Node]) {
                # Si le voisin n'a pas été visité, l'explorer
                if (-not $visited.ContainsKey($neighbor)) {
                    DetectCycle -Node $neighbor -Path $Path
                }
                # Si le voisin est dans la pile de récursion, un cycle a été détecté
                elseif ($recStack.ContainsKey($neighbor) -and $recStack[$neighbor]) {
                    # Créer un cycle
                    $cycle = [System.Collections.ArrayList]@()
                    $startIndex = $Path.IndexOf($neighbor)

                    # Si le voisin est dans le chemin actuel, extraire le cycle
                    if ($startIndex -ge 0) {
                        for ($i = $startIndex; $i -lt $Path.Count; $i++) {
                            [void]$cycle.Add($Path[$i])
                        }
                        [void]$cycle.Add($neighbor)
                    } else {
                        # Sinon, créer un cycle simple
                        [void]$cycle.Add($Node)
                        [void]$cycle.Add($neighbor)
                    }

                    # Ajouter le cycle à la liste des cycles
                    [void]$cyclesList.Add([PSCustomObject]@{
                            Nodes  = $cycle.ToArray()
                            Length = $cycle.Count
                            Path   = $cycle -join ' -> '
                        })

                    # Si on ne veut pas tous les cycles, on peut s'arrêter ici
                    if (-not $IncludeAllCycles) {
                        break
                    }
                }
            }
        }

        # Retirer le nœud de la pile de récursion et du chemin
        $recStack[$Node] = $false
        [void]$Path.RemoveAt($Path.Count - 1)
    }

    # Parcourir tous les nœuds du graphe
    foreach ($node in $DependencyGraph.Keys) {
        if (-not $visited.ContainsKey($node)) {
            $path = [System.Collections.ArrayList]@()
            DetectCycle -Node $node -Path $path

            # Si on a trouvé un cycle et qu'on ne veut pas tous les cycles, on peut s'arrêter ici
            if ($cyclesList.Count -gt 0 -and -not $IncludeAllCycles) {
                break
            }
        }
    }

    # Retourner le résultat
    return [PSCustomObject]@{
        HasCycles  = $cyclesList.Count -gt 0
        Cycles     = $cyclesList
        CycleCount = $cyclesList.Count
    }
}

<#
.SYNOPSIS
    Résout les dépendances circulaires dans le graphe de dépendances des modules.

.DESCRIPTION
    Cette fonction résout les dépendances circulaires dans le graphe de dépendances des modules
    en supprimant les dépendances qui créent des cycles.

.PARAMETER DependencyGraph
    Graphe de dépendances des modules. Si non spécifié, utilise le graphe global.

.PARAMETER UpdateGlobalGraph
    Indique si le graphe global doit être mis à jour avec les modifications.

.PARAMETER ReportOnly
    Indique si les cycles doivent être uniquement rapportés sans être résolus.

.EXAMPLE
    $result = Resolve-ModuleDependencyCycles
    Résout les dépendances circulaires dans le graphe de dépendances des modules.

.EXAMPLE
    $result = Resolve-ModuleDependencyCycles -ReportOnly
    Rapporte les dépendances circulaires sans les résoudre.

.OUTPUTS
    [PSCustomObject] Résultat de la résolution des cycles.
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

    # Utiliser le graphe global si non spécifié
    if (-not $DependencyGraph) {
        $DependencyGraph = $Global:MDT_DependencyGraph.Clone()
    } else {
        # Cloner le graphe pour ne pas modifier l'original
        $DependencyGraph = $DependencyGraph.Clone()
    }

    # Détecter les cycles
    $cyclesResult = Find-ModuleDependencyCycles -DependencyGraph $DependencyGraph -IncludeAllCycles

    # Vérifier s'il y a des cycles
    if (-not $cyclesResult.HasCycles) {
        Write-Verbose "Aucun cycle détecté dans le graphe de dépendances."
        return [PSCustomObject]@{
            HasCycles          = $false
            ResolvedCycles     = @()
            ResolvedCycleCount = 0
            ModifiedGraph      = $DependencyGraph
        }
    }

    # Initialiser la liste des cycles résolus
    $resolvedCycles = [System.Collections.ArrayList]@()

    # Résoudre les cycles si demandé
    if (-not $ReportOnly) {
        foreach ($cycle in $cyclesResult.Cycles) {
            # Déterminer la dépendance à supprimer
            $cycleNodes = $cycle.Nodes
            $lastNode = $cycleNodes[$cycleNodes.Count - 2]  # L'avant-dernier nœud
            $firstNode = $cycleNodes[$cycleNodes.Count - 1]  # Le dernier nœud (qui est le même que le premier)

            # Supprimer la dépendance
            if ($DependencyGraph.ContainsKey($lastNode) -and $DependencyGraph[$lastNode] -contains $firstNode) {
                $DependencyGraph[$lastNode] = @($DependencyGraph[$lastNode] | Where-Object { $_ -ne $firstNode })

                # Ajouter le cycle résolu à la liste
                [void]$resolvedCycles.Add([PSCustomObject]@{
                        Nodes             = $cycleNodes
                        Length            = $cycle.Length
                        Path              = $cycle.Path
                        RemovedDependency = "$lastNode -> $firstNode"
                    })
            }
        }

        # Mettre à jour le graphe global si demandé
        if ($UpdateGlobalGraph) {
            $Global:MDT_DependencyGraph = $DependencyGraph
        }
    } else {
        # Copier les cycles détectés dans la liste des cycles résolus
        foreach ($cycle in $cyclesResult.Cycles) {
            [void]$resolvedCycles.Add($cycle)
        }
    }

    # Retourner le résultat
    return [PSCustomObject]@{
        HasCycles          = $cyclesResult.HasCycles
        ResolvedCycles     = $resolvedCycles
        ResolvedCycleCount = $resolvedCycles.Count
        ModifiedGraph      = $DependencyGraph
    }
}

<#
.SYNOPSIS
    Obtient les dépendances récursives d'un module PowerShell.

.DESCRIPTION
    Cette fonction obtient les dépendances récursives d'un module PowerShell
    en explorant le graphe de dépendances.

.PARAMETER ModuleName
    Nom du module PowerShell à analyser.

.PARAMETER ModulePath
    Chemin du module PowerShell à analyser. Si non spécifié, le module sera recherché
    dans les chemins de modules standards.

.PARAMETER MaxDepth
    Profondeur maximale de récursion. Par défaut, 10.

.PARAMETER SkipSystemModules
    Indique si les modules système doivent être exclus des résultats.

.PARAMETER ResolveModulePaths
    Indique si les chemins des modules dépendants doivent être résolus.

.PARAMETER IncludeStats
    Indique si les statistiques doivent être incluses dans les résultats.

.PARAMETER DetectCycles
    Indique si les cycles doivent être détectés.

.EXAMPLE
    $dependencies = Get-ModuleDependencies -ModuleName 'MyModule'
    Obtient les dépendances récursives du module 'MyModule'.

.EXAMPLE
    $dependencies = Get-ModuleDependencies -ModulePath 'C:\Modules\MyModule\MyModule.psd1' -MaxDepth 5 -SkipSystemModules -DetectCycles
    Obtient les dépendances récursives du module situé à 'C:\Modules\MyModule\MyModule.psd1', en limitant la profondeur à 5, en excluant les modules système et en détectant les cycles.

.OUTPUTS
    [PSCustomObject] Résultat de l'analyse des dépendances.
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

    # Explorer les dépendances du module
    if ($PSCmdlet.ParameterSetName -eq 'ByName') {
        Invoke-ModuleDependencyExploration -ModuleName $ModuleName -CurrentDepth 0 -SkipSystemModules:$SkipSystemModules -ResolveModulePaths:$ResolveModulePaths
    } else {
        Invoke-ModuleDependencyExploration -ModulePath $ModulePath -CurrentDepth 0 -SkipSystemModules:$SkipSystemModules -ResolveModulePaths:$ResolveModulePaths
    }

    # Obtenir les statistiques si demandé
    $stats = $null
    if ($IncludeStats) {
        $stats = Get-ModuleVisitStatistics
    }

    # Détecter les cycles si demandé
    $cycles = $null
    if ($DetectCycles) {
        $cycles = Find-ModuleDependencyCycles
    }

    # Retourner le résultat
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
