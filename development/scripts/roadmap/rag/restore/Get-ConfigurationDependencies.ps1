# Get-ConfigurationDependencies.ps1
# Script pour gérer les dépendances entre configurations
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search")]
    [string]$ConfigType,
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigId,
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath,
    
    [Parameter(Mandatory = $false)]
    [object]$Configuration,
    
    [Parameter(Mandatory = $false)]
    [switch]$Recursive,
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeReverse,
    
    [Parameter(Mandatory = $false)]
    [switch]$AsGraph,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [switch]$AsObject,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Error", "Warning", "Info", "Debug", "None")]
    [string]$LogLevel = "Info"
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$rootPath = Split-Path -Parent $parentPath
$utilsPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $rootPath)) -ChildPath "utils"
$logModulePath = Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1"

if (Test-Path -Path $logModulePath) {
    . $logModulePath
} else {
    function Write-Log {
        param (
            [string]$Message,
            [string]$Level = "Info"
        )
        
        if ($LogLevel -eq "None") {
            return
        }
        
        $logLevels = @{
            "Error" = 0
            "Warning" = 1
            "Info" = 2
            "Debug" = 3
        }
        
        if ($logLevels[$Level] -le $logLevels[$LogLevel]) {
            $color = switch ($Level) {
                "Error" { "Red" }
                "Warning" { "Yellow" }
                "Info" { "White" }
                "Debug" { "Gray" }
                default { "White" }
            }
            
            Write-Host "[$Level] $Message" -ForegroundColor $color
        }
    }
}

# Fonction pour charger une configuration
function Get-ConfigurationFromPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )
    
    if (-not (Test-Path -Path $ConfigPath)) {
        Write-Log "Configuration file not found: $ConfigPath" -Level "Error"
        return $null
    }
    
    try {
        $configuration = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
        return $configuration
    } catch {
        Write-Log "Error loading configuration from file: $_" -Level "Error"
        return $null
    }
}

# Fonction pour déterminer le type de configuration
function Get-ConfigurationType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Configuration
    )
    
    if ($Configuration.PSObject.Properties.Name.Contains("content") -and $Configuration.PSObject.Properties.Name.Contains("type")) {
        return "Template"
    } elseif ($Configuration.PSObject.Properties.Name.Contains("chart_configuration") -and $Configuration.PSObject.Properties.Name.Contains("data_mapping")) {
        return "Visualization"
    } elseif ($Configuration.PSObject.Properties.Name.Contains("mappings") -and $Configuration.PSObject.Properties.Name.Contains("version")) {
        return "DataMapping"
    } elseif ($Configuration.PSObject.Properties.Name.Contains("chart_type") -and $Configuration.PSObject.Properties.Name.Contains("data_field")) {
        return "Chart"
    } elseif ($Configuration.PSObject.Properties.Name.Contains("export_type")) {
        return "Export"
    } elseif ($Configuration.PSObject.Properties.Name.Contains("search_type") -and $Configuration.PSObject.Properties.Name.Contains("query")) {
        return "Search"
    } else {
        Write-Log "Could not determine configuration type" -Level "Error"
        return $null
    }
}

# Fonction pour extraire les dépendances directes d'une configuration
function Get-DirectDependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search")]
        [string]$ConfigType,
        
        [Parameter(Mandatory = $true)]
        [object]$Configuration
    )
    
    $dependencies = @()
    
    # Analyser les dépendances en fonction du type de configuration
    switch ($ConfigType) {
        "Template" {
            # Les templates n'ont généralement pas de dépendances
        }
        "Visualization" {
            # Les visualisations dépendent souvent des mappages de données et des charts
            if ($Configuration.PSObject.Properties.Name.Contains("data_mapping")) {
                $dependencies += @{
                    type = "DataMapping"
                    id = $Configuration.data_mapping.id
                    dependency_type = "required"
                }
            }
            
            if ($Configuration.PSObject.Properties.Name.Contains("chart_configuration")) {
                $dependencies += @{
                    type = "Chart"
                    id = $Configuration.chart_configuration.id
                    dependency_type = "required"
                }
            }
        }
        "DataMapping" {
            # Les mappages de données peuvent dépendre d'autres mappages
            if ($Configuration.PSObject.Properties.Name.Contains("dependencies")) {
                foreach ($dep in $Configuration.dependencies) {
                    $dependencies += @{
                        type = "DataMapping"
                        id = $dep.id
                        dependency_type = $dep.type
                    }
                }
            }
        }
        "Chart" {
            # Les charts peuvent dépendre des mappages de données
            if ($Configuration.PSObject.Properties.Name.Contains("data_field")) {
                $dependencies += @{
                    type = "DataMapping"
                    id = $Configuration.data_field
                    dependency_type = "recommended"
                }
            }
        }
        "Export" {
            # Les exports dépendent souvent des visualisations ou des charts
            if ($Configuration.PSObject.Properties.Name.Contains("source_id")) {
                $dependencies += @{
                    type = $Configuration.source_type
                    id = $Configuration.source_id
                    dependency_type = "required"
                }
            }
        }
        "Search" {
            # Les recherches peuvent dépendre de divers types de configurations
            if ($Configuration.PSObject.Properties.Name.Contains("search_targets")) {
                foreach ($target in $Configuration.search_targets) {
                    $dependencies += @{
                        type = $target.type
                        id = $target.id
                        dependency_type = "optional"
                    }
                }
            }
        }
    }
    
    return $dependencies
}

# Fonction pour trouver les configurations qui dépendent d'une configuration donnée
function Get-ReverseDependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search")]
        [string]$ConfigType,
        
        [Parameter(Mandatory = $true)]
        [string]$ConfigId
    )
    
    $reverseDependencies = @()
    
    # Obtenir tous les états de configuration
    $statesPath = Join-Path -Path $scriptPath -ChildPath "states"
    
    if (-not (Test-Path -Path $statesPath)) {
        Write-Log "States directory not found: $statesPath" -Level "Warning"
        return $reverseDependencies
    }
    
    $stateFiles = Get-ChildItem -Path $statesPath -Filter "*_state.json"
    
    foreach ($stateFile in $stateFiles) {
        try {
            $state = Get-Content -Path $stateFile.FullName -Raw | ConvertFrom-Json
            
            # Vérifier si cette configuration dépend de la configuration donnée
            if ($state.dependencies) {
                foreach ($dep in $state.dependencies) {
                    if ($dep.type -eq $ConfigType -and $dep.id -eq $ConfigId) {
                        $reverseDependencies += @{
                            type = $state.type
                            id = $state.id
                            dependency_type = $dep.dependency_type
                        }
                        break
                    }
                }
            }
        } catch {
            Write-Log "Error processing state file $($stateFile.Name): $_" -Level "Warning"
        }
    }
    
    return $reverseDependencies
}

# Fonction pour obtenir les dépendances récursives
function Get-RecursiveDependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search")]
        [string]$ConfigType,
        
        [Parameter(Mandatory = $true)]
        [string]$ConfigId,
        
        [Parameter(Mandatory = $false)]
        [object]$Configuration,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Visited = @{}
    )
    
    # Éviter les boucles infinies
    $key = "$ConfigType:$ConfigId"
    if ($Visited.ContainsKey($key)) {
        return @()
    }
    
    $Visited[$key] = $true
    
    # Obtenir la configuration si elle n'est pas fournie
    if ($null -eq $Configuration) {
        $statesPath = Join-Path -Path $scriptPath -ChildPath "states"
        $stateFiles = Get-ChildItem -Path $statesPath -Filter "*${ConfigType}_${ConfigId}_state.json"
        
        if ($stateFiles.Count -eq 0) {
            Write-Log "No state file found for $ConfigType:$ConfigId" -Level "Warning"
            return @()
        }
        
        try {
            $state = Get-Content -Path $stateFiles[0].FullName -Raw | ConvertFrom-Json
            $Configuration = $state.state
        } catch {
            Write-Log "Error loading state for $ConfigType:$ConfigId: $_" -Level "Warning"
            return @()
        }
    }
    
    # Obtenir les dépendances directes
    $directDependencies = Get-DirectDependencies -ConfigType $ConfigType -Configuration $Configuration
    
    # Initialiser le résultat avec les dépendances directes
    $allDependencies = $directDependencies
    
    # Obtenir les dépendances récursives
    foreach ($dep in $directDependencies) {
        $recursiveDependencies = Get-RecursiveDependencies -ConfigType $dep.type -ConfigId $dep.id -Visited $Visited
        $allDependencies += $recursiveDependencies
    }
    
    return $allDependencies
}

# Fonction pour créer un graphe de dépendances
function New-DependencyGraph {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search")]
        [string]$ConfigType,
        
        [Parameter(Mandatory = $true)]
        [string]$ConfigId,
        
        [Parameter(Mandatory = $false)]
        [object]$Configuration,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeReverse
    )
    
    # Initialiser le graphe
    $graph = @{
        nodes = @()
        edges = @()
    }
    
    # Ajouter le nœud racine
    $graph.nodes += @{
        id = "$ConfigType:$ConfigId"
        type = $ConfigType
        config_id = $ConfigId
        is_root = $true
    }
    
    # Obtenir les dépendances récursives
    $dependencies = Get-RecursiveDependencies -ConfigType $ConfigType -ConfigId $ConfigId -Configuration $Configuration
    
    # Ajouter les nœuds et les arêtes pour les dépendances
    foreach ($dep in $dependencies) {
        # Ajouter le nœud s'il n'existe pas déjà
        $nodeId = "$($dep.type):$($dep.id)"
        if (-not ($graph.nodes | Where-Object { $_.id -eq $nodeId })) {
            $graph.nodes += @{
                id = $nodeId
                type = $dep.type
                config_id = $dep.id
                is_root = $false
            }
        }
        
        # Ajouter l'arête
        $graph.edges += @{
            source = "$ConfigType:$ConfigId"
            target = $nodeId
            type = $dep.dependency_type
            direction = "outgoing"
        }
    }
    
    # Ajouter les dépendances inverses si demandé
    if ($IncludeReverse) {
        $reverseDependencies = Get-ReverseDependencies -ConfigType $ConfigType -ConfigId $ConfigId
        
        foreach ($dep in $reverseDependencies) {
            # Ajouter le nœud s'il n'existe pas déjà
            $nodeId = "$($dep.type):$($dep.id)"
            if (-not ($graph.nodes | Where-Object { $_.id -eq $nodeId })) {
                $graph.nodes += @{
                    id = $nodeId
                    type = $dep.type
                    config_id = $dep.id
                    is_root = $false
                }
            }
            
            # Ajouter l'arête
            $graph.edges += @{
                source = $nodeId
                target = "$ConfigType:$ConfigId"
                type = $dep.dependency_type
                direction = "incoming"
            }
        }
    }
    
    return $graph
}

# Fonction principale
function Get-ConfigurationDependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search")]
        [string]$ConfigType,
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigId,
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath,
        
        [Parameter(Mandatory = $false)]
        [object]$Configuration,
        
        [Parameter(Mandatory = $false)]
        [switch]$Recursive,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeReverse,
        
        [Parameter(Mandatory = $false)]
        [switch]$AsGraph,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$AsObject
    )
    
    # Vérifier si un chemin de configuration ou une configuration est fourni
    if ([string]::IsNullOrEmpty($ConfigPath) -and $null -eq $Configuration) {
        Write-Log "Either ConfigPath or Configuration must be provided" -Level "Error"
        return $null
    }
    
    # Charger la configuration à partir du fichier si nécessaire
    if (-not [string]::IsNullOrEmpty($ConfigPath)) {
        $Configuration = Get-ConfigurationFromPath -ConfigPath $ConfigPath
        
        if ($null -eq $Configuration) {
            return $null
        }
    }
    
    # Déterminer le type de configuration si non spécifié
    if ([string]::IsNullOrEmpty($ConfigType)) {
        $ConfigType = Get-ConfigurationType -Configuration $Configuration
        
        if ($null -eq $ConfigType) {
            return $null
        }
        
        Write-Log "Determined configuration type: $ConfigType" -Level "Info"
    }
    
    # Déterminer l'ID de la configuration si non spécifié
    if ([string]::IsNullOrEmpty($ConfigId)) {
        if ($Configuration.PSObject.Properties.Name.Contains("id")) {
            $ConfigId = $Configuration.id
        } elseif ($Configuration.PSObject.Properties.Name.Contains("name") -and $Configuration.PSObject.Properties.Name.Contains("version")) {
            $ConfigId = "$($Configuration.name)_v$($Configuration.version)"
        } else {
            $ConfigId = [Guid]::NewGuid().ToString()
        }
        
        Write-Log "Determined configuration ID: $ConfigId" -Level "Info"
    }
    
    # Obtenir les dépendances
    $dependencies = $null
    
    if ($AsGraph) {
        # Créer un graphe de dépendances
        $dependencies = New-DependencyGraph -ConfigType $ConfigType -ConfigId $ConfigId -Configuration $Configuration -IncludeReverse:$IncludeReverse
    } elseif ($Recursive) {
        # Obtenir les dépendances récursives
        $dependencies = Get-RecursiveDependencies -ConfigType $ConfigType -ConfigId $ConfigId -Configuration $Configuration
    } else {
        # Obtenir les dépendances directes
        $dependencies = Get-DirectDependencies -ConfigType $ConfigType -Configuration $Configuration
        
        # Ajouter les dépendances inverses si demandé
        if ($IncludeReverse) {
            $reverseDependencies = Get-ReverseDependencies -ConfigType $ConfigType -ConfigId $ConfigId
            
            foreach ($dep in $reverseDependencies) {
                $dep.direction = "incoming"
            }
            
            $dependencies += $reverseDependencies
        }
    }
    
    # Sauvegarder les dépendances si un chemin de sortie est spécifié
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        try {
            # Créer le répertoire de sortie s'il n'existe pas
            if (-not (Test-Path -Path $OutputPath)) {
                New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
            }
            
            # Générer un nom de fichier
            $fileName = "${ConfigType}_${ConfigId}_dependencies.json"
            $filePath = Join-Path -Path $OutputPath -ChildPath $fileName
            
            # Sauvegarder les dépendances
            $dependencies | ConvertTo-Json -Depth 10 | Out-File -FilePath $filePath -Encoding UTF8
            Write-Log "Dependencies saved to: $filePath" -Level "Info"
        } catch {
            Write-Log "Error saving dependencies: $_" -Level "Error"
        }
    }
    
    # Retourner les dépendances selon le format demandé
    if ($AsObject) {
        return $dependencies
    } else {
        return $dependencies | ConvertTo-Json -Depth 10
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Get-ConfigurationDependencies -ConfigType $ConfigType -ConfigId $ConfigId -ConfigPath $ConfigPath -Configuration $Configuration -Recursive:$Recursive -IncludeReverse:$IncludeReverse -AsGraph:$AsGraph -OutputPath $OutputPath -AsObject:$AsObject
}
