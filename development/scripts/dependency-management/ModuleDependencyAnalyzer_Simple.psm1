#Requires -Version 5.1

# Variables globales pour le module
$script:VisitedModules = @{}
$script:DependencyGraph = @{}
$script:MaxRecursionDepth = 10
$script:CurrentRecursionDepth = 0

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
                        Type    = "RequiredModule"
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
                    Type    = "ImportModule"
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
                    Type    = "UsingModule"
                    Source  = $ModulePath
                })
        }

        return $dependencies
    } catch {
        Write-Error "Erreur lors de l'analyse du code du module $ModulePath : $_"
        return $dependencies
    }
}

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

# Exporter les fonctions publiques
Export-ModuleMember -Function Get-ModuleDependenciesFromManifest, Get-ModuleDependenciesFromCode, Find-ModuleDependencyCycles
