# Module d'inventaire des scripts
# Ce module fournit des fonctionnalités pour inventorier et analyser les scripts PowerShell.
# Version: 0.1.0
# Date: 2025-06-01

# Variables globales
$Global:ScriptInventoryEnabled = $true
$Global:ScriptInventoryCacheEnabled = $true
$Global:ScriptInventoryCache = @{}
$Global:ScriptInventoryStats = [PSCustomObject]@{
    TotalScripts         = 0
    TotalDependencies    = 0
    AverageExecutionTime = 0
    CacheHits            = 0
    CacheMisses          = 0
}

# Initialise l'inventaire des scripts avec les paramètres spécifiés
function Initialize-ScriptInventory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [bool]$Enabled = $true,

        [Parameter(Mandatory = $false)]
        [bool]$CacheEnabled = $true,

        [Parameter(Mandatory = $false)]
        [string]$RepositoryPath = $PWD.Path
    )

    # Initialiser les variables globales
    Set-Variable -Name ScriptInventoryEnabled -Value $Enabled -Scope Global
    Set-Variable -Name ScriptInventoryCacheEnabled -Value $CacheEnabled -Scope Global

    # Retourner les valeurs pour indiquer à l'analyseur qu'elles sont utilisées
    return [PSCustomObject]@{
        Enabled        = $Global:ScriptInventoryEnabled
        CacheEnabled   = $Global:ScriptInventoryCacheEnabled
        RepositoryPath = $RepositoryPath
    }
}

# Récupère tous les scripts PowerShell dans un répertoire et ses sous-répertoires
function Get-ScriptFiles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Path = $PWD.Path,

        [Parameter(Mandatory = $false)]
        [string[]]$Include = @("*.ps1", "*.psm1"),

        [Parameter(Mandatory = $false)]
        [string[]]$Exclude = @()
    )

    # Vérifier si l'inventaire est activé
    if (-not $Global:ScriptInventoryEnabled) {
        Write-Warning "L'inventaire des scripts est désactivé."
        return @()
    }

    # Récupérer tous les fichiers de script
    $scriptFiles = Get-ChildItem -Path $Path -Include $Include -Exclude $Exclude -Recurse -File

    # Mettre à jour les statistiques
    $Global:ScriptInventoryStats.TotalScripts = $scriptFiles.Count

    return $scriptFiles
}

# Analyse un script PowerShell pour en extraire les dépendances
function Get-ScriptDependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,

        [Parameter(Mandatory = $false)]
        [switch]$SkipCache
    )

    # Vérifier si l'inventaire est activé
    if (-not $Global:ScriptInventoryEnabled) {
        Write-Warning "L'inventaire des scripts est désactivé."
        return @()
    }

    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $ScriptPath -PathType Leaf)) {
        Write-Error "Le fichier '$ScriptPath' n'existe pas."
        return @()
    }

    # Vérifier le cache
    if (-not $SkipCache -and $Global:ScriptInventoryCacheEnabled) {
        $scriptHash = Get-FileHash -Path $ScriptPath -Algorithm SHA256 | Select-Object -ExpandProperty Hash

        if ($Global:ScriptInventoryCache.ContainsKey($scriptHash)) {
            $Global:ScriptInventoryStats.CacheHits++
            return $Global:ScriptInventoryCache[$scriptHash]
        }

        $Global:ScriptInventoryStats.CacheMisses++
    }

    # Mesurer le temps d'exécution
    $startTime = Get-Date

    # Lire le contenu du script
    $scriptContent = Get-Content -Path $ScriptPath -Raw -ErrorAction SilentlyContinue

    # Analyser le script pour trouver les dépendances
    $dependencies = @()

    # Vérifier si le contenu du script est disponible
    if ($null -eq $scriptContent) {
        Write-Warning "Impossible de lire le contenu du script '$ScriptPath'."
        return $dependencies
    }

    # Rechercher les imports de modules
    $importModuleMatches = [regex]::Matches($scriptContent, '(?i)Import-Module\s+([^-\s][^\s,;]+)')
    foreach ($match in $importModuleMatches) {
        $moduleName = $match.Groups[1].Value.Trim("'`"")
        $dependencies += [PSCustomObject]@{
            Type = "Module"
            Name = $moduleName
            Path = $null
        }
    }

    # Rechercher les appels de scripts (dot-sourcing)
    $dotSourceMatches = [regex]::Matches($scriptContent, '(?i)\.\s+([^-\s][^\s,;]+)')
    foreach ($match in $dotSourceMatches) {
        $scriptName = $match.Groups[1].Value.Trim("'`"")
        $dependencies += [PSCustomObject]@{
            Type = "Script"
            Name = $scriptName
            Path = if (-not [string]::IsNullOrEmpty($scriptName)) {
                try {
                    Resolve-Path -Path $scriptName -ErrorAction Stop | Select-Object -ExpandProperty Path
                } catch {
                    $null
                }
            } else {
                $null
            }
        }
    }

    # Rechercher les appels de fonctions externes
    # Cette partie est plus complexe et nécessiterait une analyse plus approfondie du code

    # Mettre à jour les statistiques
    $endTime = Get-Date
    $executionTime = ($endTime - $startTime).TotalMilliseconds
    $Global:ScriptInventoryStats.AverageExecutionTime = (($Global:ScriptInventoryStats.AverageExecutionTime * ($Global:ScriptInventoryStats.TotalScripts - 1)) + $executionTime) / $Global:ScriptInventoryStats.TotalScripts
    $Global:ScriptInventoryStats.TotalDependencies += $dependencies.Count

    # Mettre en cache les résultats
    if ($Global:ScriptInventoryCacheEnabled) {
        $Global:ScriptInventoryCache[$scriptHash] = $dependencies
    }

    return $dependencies
}

# Génère un rapport des dépendances pour tous les scripts dans un répertoire
function Get-ScriptDependencyReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Path = $PWD.Path,

        [Parameter(Mandatory = $false)]
        [string[]]$Include = @("*.ps1", "*.psm1"),

        [Parameter(Mandatory = $false)]
        [string[]]$Exclude = @(),

        [Parameter(Mandatory = $false)]
        [switch]$SkipCache,

        [Parameter(Mandatory = $false)]
        [switch]$GenerateGraph,

        [Parameter(Mandatory = $false)]
        [string]$GraphOutputPath
    )

    # Vérifier si l'inventaire est activé
    if (-not $Global:ScriptInventoryEnabled) {
        Write-Warning "L'inventaire des scripts est désactivé."
        return @()
    }

    # Récupérer tous les fichiers de script
    $scriptFiles = Get-ScriptFiles -Path $Path -Include $Include -Exclude $Exclude

    # Analyser chaque script pour ses dépendances
    $report = @{}
    foreach ($script in $scriptFiles) {
        $dependencies = Get-ScriptDependencies -ScriptPath $script.FullName -SkipCache:$SkipCache
        $report[$script.FullName] = $dependencies
    }

    # Générer le graphe si demandé
    if ($GenerateGraph -and $GraphOutputPath) {
        # Vérifier si le module CycleDetector est disponible
        if (-not (Get-Module -Name CycleDetector)) {
            try {
                $cycleDetectorPath = Join-Path -Path $PSScriptRoot -ChildPath "CycleDetector.psm1"
                Import-Module $cycleDetectorPath -Force -ErrorAction Stop
            } catch {
                Write-Warning "Le module CycleDetector n'a pas été trouvé. Impossible de générer le graphe."
                return $report
            }
        }

        # Construire le graphe de dépendances
        $graph = @{}
        foreach ($scriptPath in $report.Keys) {
            $scriptName = Split-Path -Path $scriptPath -Leaf
            $dependencies = $report[$scriptPath] | Where-Object { $_.Type -eq "Script" } | Select-Object -ExpandProperty Name
            $graph[$scriptName] = $dependencies
        }

        # Générer le graphe
        Export-CycleVisualization -Graph $graph -OutputPath $GraphOutputPath -Format "HTML"
    }

    return $report
}

# Retourne les statistiques d'utilisation de l'inventaire des scripts
function Get-ScriptInventoryStatistics {
    [CmdletBinding()]
    param ()

    return $Global:ScriptInventoryStats
}

# Vide le cache de l'inventaire des scripts
function Clear-ScriptInventoryCache {
    [CmdletBinding()]
    param ()

    $Global:ScriptInventoryCache.Clear()
    Write-Host "Cache de l'inventaire des scripts vidé."
}

# Retourne l'inventaire des scripts
function Get-ScriptInventory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Path = $PWD.Path,

        [Parameter(Mandatory = $false)]
        [string[]]$Include = @("*.ps1", "*.psm1"),

        [Parameter(Mandatory = $false)]
        [string[]]$Exclude = @()
    )

    # Vérifier si l'inventaire est activé
    if (-not $Global:ScriptInventoryEnabled) {
        Write-Warning "L'inventaire des scripts est désactivé."
        return @()
    }

    # Récupérer tous les fichiers de script
    $scriptFiles = Get-ScriptFiles -Path $Path -Include $Include -Exclude $Exclude

    # Créer l'inventaire
    $inventory = @()
    foreach ($script in $scriptFiles) {
        $inventory += [PSCustomObject]@{
            FileName     = $script.Name
            FullPath     = $script.FullName
            Size         = $script.Length
            LastModified = $script.LastWriteTime
            Dependencies = Get-ScriptDependencies -ScriptPath $script.FullName
        }
    }

    return $inventory
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Initialize-ScriptInventory, Get-ScriptFiles, Get-ScriptDependencies, Get-ScriptDependencyReport, Get-ScriptInventoryStatistics, Clear-ScriptInventoryCache, Get-ScriptInventory
