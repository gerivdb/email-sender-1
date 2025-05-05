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
        Write-Warning ('Le fichier manifeste n''existe pas: ' + $ManifestPath)
        return $dependencies
    }

    # VÃ©rifier l'extension du fichier
    $extension = [System.IO.Path]::GetExtension($ManifestPath)
    if ($extension -ne '.psd1') {
        Write-Warning ('Le fichier spÃ©cifiÃ© n''est pas un fichier .psd1: ' + $ManifestPath)
        return $dependencies
    }

    try {
        # Importer le manifeste
        $manifest = Import-PowerShellDataFile -Path $ManifestPath -ErrorAction Stop

        # Extraire les dÃ©pendances RequiredModules
        if ($manifest.ContainsKey('RequiredModules') -and $manifest.RequiredModules) {
            Write-Verbose ('Analyse des RequiredModules dans le manifeste: ' + $ManifestPath)
            
            # RequiredModules peut Ãªtre une chaÃ®ne, un tableau de chaÃ®nes, ou un tableau d'objets
            foreach ($requiredModule in $manifest.RequiredModules) {
                $moduleName = $null
                $moduleVersion = $null
                $modulePath = $null

                # DÃ©terminer le format du module requis
                if ($requiredModule -is [string]) {
                    # Format simple: 'ModuleName'
                    $moduleName = $requiredModule
                }
                elseif ($requiredModule -is [hashtable] -or $requiredModule -is [System.Collections.Specialized.OrderedDictionary]) {
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
                }
                elseif ($requiredModule -is [System.Management.Automation.PSModuleInfo]) {
                    # Format objet: [PSModuleInfo]
                    $moduleName = $requiredModule.Name
                    $moduleVersion = $requiredModule.Version
                    $modulePath = $requiredModule.Path
                }

                # Ajouter la dÃ©pendance Ã  la liste
                [void]$dependencies.Add([PSCustomObject]@{
                    Name = $moduleName
                    Version = $moduleVersion
                    Path = $modulePath
                    Type = 'RequiredModule'
                    Source = $ManifestPath
                })
            }
        }

        return $dependencies
    }
    catch {
        Write-Error ('Erreur lors de l''analyse du manifeste ' + $ManifestPath + ' : ' + $_)
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
        Write-Warning ('Le fichier module n''existe pas: ' + $ModulePath)
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
                Name = $moduleName
                Version = $null
                Path = $null
                Type = 'ImportModule'
                Source = $ModulePath
            })
        }
        
        # DÃ©tecter les using module
        $usingMatches = [regex]::Matches($content, '(?m)^\s*using\s+module\s+([''"]?)([^''"\s]+)\1')
        foreach ($match in $usingMatches) {
            $moduleName = $match.Groups[2].Value
            
            # Ajouter la dÃ©pendance Ã  la liste
            [void]$dependencies.Add([PSCustomObject]@{
                Name = $moduleName
                Version = $null
                Path = $null
                Type = 'UsingModule'
                Source = $ModulePath
            })
        }
        
        return $dependencies
    }
    catch {
        Write-Error ('Erreur lors de l''analyse du code du module ' + $ModulePath + ' : ' + $_)
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

    # Parcourir tous les nÅ“uds du graphe
    foreach ($node in $DependencyGraph.Keys) {
        if (-not $visited.ContainsKey($node) -or -not $visited[$node]) {
            $cycleFound = $false
            
            # Marquer le nÅ“ud comme visitÃ©
            $visited[$node] = $true
            $recursionStack[$node] = $true
            
            # Parcourir les voisins du nÅ“ud
            foreach ($neighbor in $DependencyGraph[$node]) {
                # Si le voisin est dans la pile de rÃ©cursion, un cycle a Ã©tÃ© dÃ©tectÃ©
                if ($recursionStack.ContainsKey($neighbor) -and $recursionStack[$neighbor]) {
                    # Ajouter le cycle Ã  la liste des cycles
                    [void]$cycles.Add([PSCustomObject]@{
                        Nodes = @($node, $neighbor)
                        Length = 2
                    })
                    
                    $cycleFound = $true
                    if (-not $IncludeAllCycles) {
                        break
                    }
                }
            }
            
            # Retirer le nÅ“ud de la pile de rÃ©cursion
            $recursionStack[$node] = $false
            
            if ($cycleFound -and -not $IncludeAllCycles) {
                break
            }
        }
    }

    return [PSCustomObject]@{
        HasCycles = $cycles.Count -gt 0
        Cycles = $cycles
        CycleCount = $cycles.Count
    }
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Get-ModuleDependenciesFromManifest, Get-ModuleDependenciesFromCode, Find-ModuleDependencyCycles
