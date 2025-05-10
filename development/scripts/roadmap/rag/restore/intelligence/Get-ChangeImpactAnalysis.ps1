# Get-ChangeImpactAnalysis.ps1
# Script pour analyser l'impact des modifications sur le système
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
    [string]$OldConfigPath,
    
    [Parameter(Mandatory = $false)]
    [string]$NewConfigPath,
    
    [Parameter(Mandatory = $false)]
    [object]$OldConfiguration,
    
    [Parameter(Mandatory = $false)]
    [object]$NewConfiguration,
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeDependencies,
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeReverseDependencies,
    
    [Parameter(Mandatory = $false)]
    [switch]$AsGraph,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Error", "Warning", "Info", "Debug", "None")]
    [string]$LogLevel = "Info"
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$rootPath = Split-Path -Parent $parentPath
$utilsPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $rootPath))) -ChildPath "utils"
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

# Importer le script de détection des changements significatifs
$significantChangePath = Join-Path -Path $scriptPath -ChildPath "Test-SignificantChange.ps1"

if (Test-Path -Path $significantChangePath) {
    . $significantChangePath
} else {
    Write-Log "Required script not found: $significantChangePath" -Level "Error"
    exit 1
}

# Importer le script de gestion des dépendances
$dependenciesPath = Join-Path -Path $rootPath -ChildPath "Get-ConfigurationDependencies.ps1"

if (Test-Path -Path $dependenciesPath) {
    . $dependenciesPath
} else {
    Write-Log "Required script not found: $dependenciesPath" -Level "Error"
    exit 1
}

# Fonction pour charger une configuration à partir d'un fichier
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

# Fonction pour évaluer l'impact d'un changement
function Get-ChangeImpact {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$ChangeAnalysis,
        
        [Parameter(Mandatory = $true)]
        [object]$Dependencies
    )
    
    # Initialiser les niveaux d'impact
    $impactLevels = @{
        "None" = 0
        "Low" = 1
        "Medium" = 2
        "High" = 3
        "Critical" = 4
    }
    
    # Déterminer le niveau d'impact initial basé sur l'analyse des changements
    $impactLevel = "None"
    
    if ($ChangeAnalysis.is_significant) {
        # Évaluer l'impact en fonction des métriques de changement
        if ($ChangeAnalysis.critical_changes.Count -gt 0) {
            $impactLevel = "Critical"
        } elseif ($ChangeAnalysis.global_change_percent -ge 50) {
            $impactLevel = "High"
        } elseif ($ChangeAnalysis.global_change_percent -ge 30) {
            $impactLevel = "Medium"
        } else {
            $impactLevel = "Low"
        }
    }
    
    # Évaluer l'impact sur les dépendances
    $affectedDependencies = @()
    $impactScore = $impactLevels[$impactLevel]
    
    # Analyser l'impact sur chaque dépendance
    foreach ($dependency in $Dependencies) {
        $dependencyImpact = "None"
        $dependencyScore = 0
        $reasons = @()
        
        # Déterminer l'impact sur la dépendance en fonction du type de dépendance
        switch ($dependency.dependency_type) {
            "required" {
                # Les dépendances requises sont fortement impactées
                $dependencyScore = $impactLevels[$impactLevel]
                
                if ($dependencyScore -ge $impactLevels["Medium"]) {
                    $dependencyImpact = "High"
                    $reasons += "Required dependency with $impactLevel impact"
                } elseif ($dependencyScore -gt 0) {
                    $dependencyImpact = "Medium"
                    $reasons += "Required dependency with $impactLevel impact"
                }
            }
            "recommended" {
                # Les dépendances recommandées sont modérément impactées
                $dependencyScore = [Math]::Max(0, $impactLevels[$impactLevel] - 1)
                
                if ($dependencyScore -ge $impactLevels["Medium"]) {
                    $dependencyImpact = "Medium"
                    $reasons += "Recommended dependency with $impactLevel impact"
                } elseif ($dependencyScore -gt 0) {
                    $dependencyImpact = "Low"
                    $reasons += "Recommended dependency with $impactLevel impact"
                }
            }
            "optional" {
                # Les dépendances optionnelles sont faiblement impactées
                $dependencyScore = [Math]::Max(0, $impactLevels[$impactLevel] - 2)
                
                if ($dependencyScore -gt 0) {
                    $dependencyImpact = "Low"
                    $reasons += "Optional dependency with $impactLevel impact"
                }
            }
            default {
                # Par défaut, considérer comme une dépendance faible
                $dependencyScore = [Math]::Max(0, $impactLevels[$impactLevel] - 2)
                
                if ($dependencyScore -gt 0) {
                    $dependencyImpact = "Low"
                    $reasons += "Dependency with $impactLevel impact"
                }
            }
        }
        
        # Ajouter la dépendance affectée si l'impact est non nul
        if ($dependencyScore -gt 0) {
            $affectedDependency = $dependency.Clone()
            $affectedDependency.impact_level = $dependencyImpact
            $affectedDependency.impact_score = $dependencyScore
            $affectedDependency.impact_reasons = $reasons
            
            $affectedDependencies += $affectedDependency
        }
    }
    
    # Créer le résultat de l'analyse d'impact
    $impact = @{
        impact_level = $impactLevel
        impact_score = $impactScore
        affected_dependencies_count = $affectedDependencies.Count
        affected_dependencies = $affectedDependencies
        change_analysis = $ChangeAnalysis
    }
    
    return $impact
}

# Fonction pour analyser l'impact des modifications
function Get-ChangeImpactAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search")]
        [string]$ConfigType,
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigId,
        
        [Parameter(Mandatory = $false)]
        [string]$OldConfigPath,
        
        [Parameter(Mandatory = $false)]
        [string]$NewConfigPath,
        
        [Parameter(Mandatory = $false)]
        [object]$OldConfiguration,
        
        [Parameter(Mandatory = $false)]
        [object]$NewConfiguration,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeDependencies,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeReverseDependencies,
        
        [Parameter(Mandatory = $false)]
        [switch]$AsGraph
    )
    
    # Charger les configurations à partir des fichiers si nécessaire
    if ($null -eq $OldConfiguration -and -not [string]::IsNullOrEmpty($OldConfigPath)) {
        $OldConfiguration = Get-ConfigurationFromPath -ConfigPath $OldConfigPath
    }
    
    if ($null -eq $NewConfiguration -and -not [string]::IsNullOrEmpty($NewConfigPath)) {
        $NewConfiguration = Get-ConfigurationFromPath -ConfigPath $NewConfigPath
    }
    
    # Vérifier si les configurations sont disponibles
    if ($null -eq $OldConfiguration -or $null -eq $NewConfiguration) {
        Write-Log "Both old and new configurations must be provided" -Level "Error"
        return $null
    }
    
    # Déterminer le type de configuration si non spécifié
    if ([string]::IsNullOrEmpty($ConfigType)) {
        if ($NewConfiguration.PSObject.Properties.Name.Contains("type")) {
            $ConfigType = $NewConfiguration.type
        } else {
            Write-Log "Configuration type must be specified" -Level "Error"
            return $null
        }
    }
    
    # Déterminer l'ID de la configuration si non spécifié
    if ([string]::IsNullOrEmpty($ConfigId)) {
        if ($NewConfiguration.PSObject.Properties.Name.Contains("id")) {
            $ConfigId = $NewConfiguration.id
        } else {
            Write-Log "Configuration ID must be specified" -Level "Error"
            return $null
        }
    }
    
    # Analyser les changements
    $changeAnalysis = Test-SignificantChange -ConfigType $ConfigType -ConfigId $ConfigId -OldConfiguration $OldConfiguration -NewConfiguration $NewConfiguration -Detailed
    
    # Initialiser le résultat
    $result = @{
        config_type = $ConfigType
        config_id = $ConfigId
        change_analysis = $changeAnalysis
        direct_impact = $null
        dependency_impact = $null
        reverse_dependency_impact = $null
        total_affected_count = 0
    }
    
    # Analyser l'impact direct
    $directImpact = @{
        impact_level = if ($changeAnalysis.is_significant) { "Self" } else { "None" }
        impact_score = if ($changeAnalysis.is_significant) { 5 } else { 0 }
        reasons = $changeAnalysis.reasons
    }
    
    $result.direct_impact = $directImpact
    
    # Analyser l'impact sur les dépendances si demandé
    if ($IncludeDependencies) {
        # Obtenir les dépendances
        $dependencies = Get-ConfigurationDependencies -ConfigType $ConfigType -ConfigId $ConfigId -Configuration $NewConfiguration -AsObject
        
        if ($null -ne $dependencies -and $dependencies.Count -gt 0) {
            # Analyser l'impact sur les dépendances
            $dependencyImpact = Get-ChangeImpact -ChangeAnalysis $changeAnalysis -Dependencies $dependencies
            $result.dependency_impact = $dependencyImpact
            $result.total_affected_count += $dependencyImpact.affected_dependencies_count
        } else {
            $result.dependency_impact = @{
                impact_level = "None"
                impact_score = 0
                affected_dependencies_count = 0
                affected_dependencies = @()
            }
        }
    }
    
    # Analyser l'impact sur les dépendances inverses si demandé
    if ($IncludeReverseDependencies) {
        # Obtenir les dépendances inverses
        $reverseDependencies = Get-ConfigurationDependencies -ConfigType $ConfigType -ConfigId $ConfigId -Configuration $NewConfiguration -IncludeReverse -AsObject
        
        if ($null -ne $reverseDependencies -and $reverseDependencies.Count -gt 0) {
            # Filtrer pour ne garder que les dépendances inverses
            $reverseDependencies = $reverseDependencies | Where-Object { $_.direction -eq "incoming" }
            
            # Analyser l'impact sur les dépendances inverses
            $reverseDependencyImpact = Get-ChangeImpact -ChangeAnalysis $changeAnalysis -Dependencies $reverseDependencies
            $result.reverse_dependency_impact = $reverseDependencyImpact
            $result.total_affected_count += $reverseDependencyImpact.affected_dependencies_count
        } else {
            $result.reverse_dependency_impact = @{
                impact_level = "None"
                impact_score = 0
                affected_dependencies_count = 0
                affected_dependencies = @()
            }
        }
    }
    
    # Créer un graphe d'impact si demandé
    if ($AsGraph) {
        $graph = @{
            nodes = @()
            edges = @()
        }
        
        # Ajouter le nœud principal
        $graph.nodes += @{
            id = "$ConfigType:$ConfigId"
            type = $ConfigType
            config_id = $ConfigId
            is_root = $true
            impact_level = $directImpact.impact_level
            impact_score = $directImpact.impact_score
        }
        
        # Ajouter les nœuds et les arêtes pour les dépendances
        if ($IncludeDependencies -and $null -ne $result.dependency_impact) {
            foreach ($dependency in $result.dependency_impact.affected_dependencies) {
                # Ajouter le nœud s'il n'existe pas déjà
                $nodeId = "$($dependency.type):$($dependency.id)"
                if (-not ($graph.nodes | Where-Object { $_.id -eq $nodeId })) {
                    $graph.nodes += @{
                        id = $nodeId
                        type = $dependency.type
                        config_id = $dependency.id
                        is_root = $false
                        impact_level = $dependency.impact_level
                        impact_score = $dependency.impact_score
                    }
                }
                
                # Ajouter l'arête
                $graph.edges += @{
                    source = "$ConfigType:$ConfigId"
                    target = $nodeId
                    type = $dependency.dependency_type
                    direction = "outgoing"
                    impact_level = $dependency.impact_level
                }
            }
        }
        
        # Ajouter les nœuds et les arêtes pour les dépendances inverses
        if ($IncludeReverseDependencies -and $null -ne $result.reverse_dependency_impact) {
            foreach ($dependency in $result.reverse_dependency_impact.affected_dependencies) {
                # Ajouter le nœud s'il n'existe pas déjà
                $nodeId = "$($dependency.type):$($dependency.id)"
                if (-not ($graph.nodes | Where-Object { $_.id -eq $nodeId })) {
                    $graph.nodes += @{
                        id = $nodeId
                        type = $dependency.type
                        config_id = $dependency.id
                        is_root = $false
                        impact_level = $dependency.impact_level
                        impact_score = $dependency.impact_score
                    }
                }
                
                # Ajouter l'arête
                $graph.edges += @{
                    source = $nodeId
                    target = "$ConfigType:$ConfigId"
                    type = $dependency.dependency_type
                    direction = "incoming"
                    impact_level = $dependency.impact_level
                }
            }
        }
        
        $result.impact_graph = $graph
    }
    
    # Journaliser le résultat
    if ($changeAnalysis.is_significant) {
        Write-Log "Change impact analysis completed for $ConfigType:$ConfigId - Significant changes detected" -Level "Info"
        Write-Log "  - Total affected components: $($result.total_affected_count)" -Level "Info"
    } else {
        Write-Log "Change impact analysis completed for $ConfigType:$ConfigId - No significant changes detected" -Level "Info"
    }
    
    return $result
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Get-ChangeImpactAnalysis -ConfigType $ConfigType -ConfigId $ConfigId -OldConfigPath $OldConfigPath -NewConfigPath $NewConfigPath -OldConfiguration $OldConfiguration -NewConfiguration $NewConfiguration -IncludeDependencies:$IncludeDependencies -IncludeReverseDependencies:$IncludeReverseDependencies -AsGraph:$AsGraph
}
