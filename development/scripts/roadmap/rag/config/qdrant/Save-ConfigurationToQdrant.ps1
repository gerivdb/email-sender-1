# Save-ConfigurationToQdrant.ps1
# Script principal pour sauvegarder les configurations dans Qdrant
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search")]
    [string]$ConfigType,
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath,
    
    [Parameter(Mandatory = $false)]
    [object]$Configuration,
    
    [Parameter(Mandatory = $false)]
    [string]$ServerUrl = "http://localhost:6333",
    
    [Parameter(Mandatory = $false)]
    [string]$ApiKey = "",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("OpenAI", "DeepSeek", "Local", "Mock")]
    [string]$EmbeddingProvider = "OpenAI",
    
    [Parameter(Mandatory = $false)]
    [string]$ModelName = "text-embedding-3-large",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
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

# Importer les scripts nécessaires
$connectionPath = Join-Path -Path $scriptPath -ChildPath "Connect-QdrantServer.ps1"
$operationPath = Join-Path -Path $scriptPath -ChildPath "Invoke-QdrantOperation.ps1"
$vectorPath = Join-Path -Path $scriptPath -ChildPath "ConvertTo-Vector.ps1"
$schemaPath = Join-Path -Path $scriptPath -ChildPath "Get-QdrantCollectionSchema.ps1"

# Vérifier que tous les scripts nécessaires existent
$requiredScripts = @($connectionPath, $operationPath, $vectorPath, $schemaPath)
foreach ($script in $requiredScripts) {
    if (-not (Test-Path -Path $script)) {
        Write-Log "Required script not found: $script" -Level "Error"
        exit 1
    }
}

# Importer les scripts
. $connectionPath
. $operationPath
. $vectorPath
. $schemaPath

# Fonction pour obtenir le nom de collection en fonction du type de configuration
function Get-CollectionName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search")]
        [string]$ConfigType
    )
    
    $collectionName = switch ($ConfigType) {
        "Template" { "roadmap_templates" }
        "Visualization" { "roadmap_visualizations" }
        "DataMapping" { "roadmap_data_mappings" }
        "Chart" { "roadmap_charts" }
        "Export" { "roadmap_exports" }
        "Search" { "roadmap_searches" }
        default { "roadmap_configurations" }
    }
    
    return $collectionName
}

# Fonction pour préparer les métadonnées en fonction du type de configuration
function Get-ConfigurationMetadata {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Configuration,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search")]
        [string]$ConfigType
    )
    
    $metadata = @{}
    
    # Ajouter les métadonnées communes
    if ($Configuration.PSObject.Properties.Name.Contains("name")) {
        $metadata.name = $Configuration.name
    }
    
    if ($Configuration.PSObject.Properties.Name.Contains("version")) {
        $metadata.version = $Configuration.version
    }
    
    if ($Configuration.PSObject.Properties.Name.Contains("description")) {
        $metadata.description = $Configuration.description
    }
    
    if ($Configuration.PSObject.Properties.Name.Contains("author")) {
        $metadata.author = $Configuration.author
    }
    
    if ($Configuration.PSObject.Properties.Name.Contains("created_at")) {
        $metadata.created_at = $Configuration.created_at
    } elseif ($Configuration.PSObject.Properties.Name.Contains("created_date")) {
        $metadata.created_at = $Configuration.created_date
    }
    
    if ($Configuration.PSObject.Properties.Name.Contains("updated_at")) {
        $metadata.updated_at = $Configuration.updated_at
    } elseif ($Configuration.PSObject.Properties.Name.Contains("modified_date")) {
        $metadata.updated_at = $Configuration.modified_date
    }
    
    if ($Configuration.PSObject.Properties.Name.Contains("tags")) {
        $metadata.tags = $Configuration.tags
    }
    
    # Ajouter les métadonnées spécifiques au type
    switch ($ConfigType) {
        "Template" {
            if ($Configuration.PSObject.Properties.Name.Contains("type")) {
                $metadata.type = $Configuration.type
            }
            
            if ($Configuration.PSObject.Properties.Name.Contains("content")) {
                $metadata.content = $Configuration.content
            }
        }
        "Visualization" {
            if ($Configuration.PSObject.Properties.Name.Contains("chart_configuration")) {
                if ($Configuration.chart_configuration.PSObject.Properties.Name.Contains("chart_type")) {
                    $metadata.chart_type = $Configuration.chart_configuration.chart_type
                }
                
                if ($Configuration.chart_configuration.PSObject.Properties.Name.Contains("data_field")) {
                    $metadata.data_field = $Configuration.chart_configuration.data_field
                }
            }
        }
        "DataMapping" {
            if ($Configuration.PSObject.Properties.Name.Contains("mappings") -and $Configuration.mappings.Count -gt 0) {
                $firstMapping = $Configuration.mappings[0]
                
                if ($firstMapping.PSObject.Properties.Name.Contains("name")) {
                    $metadata.mapping_name = $firstMapping.name
                }
                
                if ($firstMapping.PSObject.Properties.Name.Contains("description")) {
                    $metadata.mapping_description = $firstMapping.description
                }
                
                if ($firstMapping.PSObject.Properties.Name.Contains("type")) {
                    $metadata.mapping_type = $firstMapping.type
                }
                
                if ($firstMapping.PSObject.Properties.Name.Contains("data_source")) {
                    $metadata.data_source = $firstMapping.data_source
                }
                
                if ($firstMapping.PSObject.Properties.Name.Contains("group_by")) {
                    $metadata.group_by = $firstMapping.group_by
                }
                
                if ($firstMapping.PSObject.Properties.Name.Contains("value_field")) {
                    $metadata.value_field = $firstMapping.value_field
                }
            }
        }
        "Chart" {
            if ($Configuration.PSObject.Properties.Name.Contains("chart_type")) {
                $metadata.chart_type = $Configuration.chart_type
            }
            
            if ($Configuration.PSObject.Properties.Name.Contains("data_field")) {
                $metadata.data_field = $Configuration.data_field
            }
            
            if ($Configuration.PSObject.Properties.Name.Contains("title")) {
                $metadata.title = $Configuration.title
            }
            
            if ($Configuration.PSObject.Properties.Name.Contains("show_legend")) {
                $metadata.show_legend = $Configuration.show_legend
            }
            
            if ($Configuration.PSObject.Properties.Name.Contains("enable_animation")) {
                $metadata.enable_animation = $Configuration.enable_animation
            }
        }
        "Export" {
            if ($Configuration.PSObject.Properties.Name.Contains("export_type")) {
                $metadata.export_type = $Configuration.export_type
            }
            
            if ($Configuration.PSObject.Properties.Name.Contains("format")) {
                $metadata.format = $Configuration.format
            }
            
            if ($Configuration.PSObject.Properties.Name.Contains("export_name")) {
                $metadata.export_name = $Configuration.export_name
            }
            
            if ($Configuration.PSObject.Properties.Name.Contains("export_description")) {
                $metadata.export_description = $Configuration.export_description
            }
            
            if ($Configuration.PSObject.Properties.Name.Contains("source_id")) {
                $metadata.source_id = $Configuration.source_id
            }
            
            if ($Configuration.PSObject.Properties.Name.Contains("source_type")) {
                $metadata.source_type = $Configuration.source_type
            }
        }
        "Search" {
            if ($Configuration.PSObject.Properties.Name.Contains("search_type")) {
                $metadata.search_type = $Configuration.search_type
            }
            
            if ($Configuration.PSObject.Properties.Name.Contains("query")) {
                $metadata.query = $Configuration.query
            }
            
            if ($Configuration.PSObject.Properties.Name.Contains("include_archived")) {
                $metadata.include_archived = $Configuration.include_archived
            }
            
            if ($Configuration.PSObject.Properties.Name.Contains("limit")) {
                $metadata.limit = $Configuration.limit
            }
        }
    }
    
    # Ajouter un champ pour indiquer que la configuration n'est pas archivée
    $metadata.is_archived = $false
    
    return $metadata
}

# Fonction pour générer un ID unique pour la configuration
function Get-ConfigurationId {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Configuration,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search")]
        [string]$ConfigType
    )
    
    $idParts = @()
    
    # Ajouter le type de configuration
    $idParts += $ConfigType.ToLower()
    
    # Ajouter le nom si disponible
    if ($Configuration.PSObject.Properties.Name.Contains("name")) {
        $idParts += $Configuration.name -replace '[^a-zA-Z0-9]', '_'
    }
    
    # Ajouter la version si disponible
    if ($Configuration.PSObject.Properties.Name.Contains("version")) {
        $idParts += $Configuration.version -replace '[^a-zA-Z0-9\.]', '_'
    }
    
    # Générer un ID unique si les parties sont insuffisantes
    if ($idParts.Count -lt 3) {
        $idParts += [Guid]::NewGuid().ToString("N").Substring(0, 8)
    }
    
    # Construire l'ID final
    $id = $idParts -join "_"
    
    return $id
}

# Fonction principale pour sauvegarder une configuration dans Qdrant
function Save-ConfigurationToQdrant {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search")]
        [string]$ConfigType,
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath,
        
        [Parameter(Mandatory = $false)]
        [object]$Configuration,
        
        [Parameter(Mandatory = $false)]
        [string]$ServerUrl = "http://localhost:6333",
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey = "",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("OpenAI", "DeepSeek", "Local", "Mock")]
        [string]$EmbeddingProvider = "OpenAI",
        
        [Parameter(Mandatory = $false)]
        [string]$ModelName = "text-embedding-3-large",
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Vérifier si un chemin de configuration ou une configuration est fourni
    if ([string]::IsNullOrEmpty($ConfigPath) -and $null -eq $Configuration) {
        Write-Log "Either ConfigPath or Configuration must be provided" -Level "Error"
        return $false
    }
    
    # Charger la configuration à partir du fichier si nécessaire
    if (-not [string]::IsNullOrEmpty($ConfigPath)) {
        if (-not (Test-Path -Path $ConfigPath)) {
            Write-Log "Configuration file not found: $ConfigPath" -Level "Error"
            return $false
        }
        
        try {
            $Configuration = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
        } catch {
            Write-Log "Error loading configuration from file: $_" -Level "Error"
            return $false
        }
    }
    
    # Déterminer le type de configuration si non spécifié
    if ([string]::IsNullOrEmpty($ConfigType)) {
        if ($Configuration.PSObject.Properties.Name.Contains("content") -and $Configuration.PSObject.Properties.Name.Contains("type")) {
            $ConfigType = "Template"
        } elseif ($Configuration.PSObject.Properties.Name.Contains("chart_configuration") -and $Configuration.PSObject.Properties.Name.Contains("data_mapping")) {
            $ConfigType = "Visualization"
        } elseif ($Configuration.PSObject.Properties.Name.Contains("mappings") -and $Configuration.PSObject.Properties.Name.Contains("version")) {
            $ConfigType = "DataMapping"
        } elseif ($Configuration.PSObject.Properties.Name.Contains("chart_type") -and $Configuration.PSObject.Properties.Name.Contains("data_field")) {
            $ConfigType = "Chart"
        } elseif ($Configuration.PSObject.Properties.Name.Contains("export_type")) {
            $ConfigType = "Export"
        } elseif ($Configuration.PSObject.Properties.Name.Contains("search_type") -and $Configuration.PSObject.Properties.Name.Contains("query")) {
            $ConfigType = "Search"
        } else {
            Write-Log "Could not determine configuration type" -Level "Error"
            return $false
        }
        
        Write-Log "Determined configuration type: $ConfigType" -Level "Info"
    }
    
    # Connecter au serveur Qdrant
    $connection = Connect-QdrantServer -ServerUrl $ServerUrl -ApiKey $ApiKey -Force:$Force
    
    if ($null -eq $connection) {
        Write-Log "Failed to connect to Qdrant server" -Level "Error"
        return $false
    }
    
    # Obtenir le nom de la collection
    $collectionName = Get-CollectionName -ConfigType $ConfigType
    
    # Vérifier si la collection existe, sinon la créer
    $collections = Invoke-QdrantOperation -Operation "ListCollections" -AsObject
    
    if ($null -eq $collections -or -not ($collections | Where-Object { $_ -eq $collectionName })) {
        Write-Log "Collection '$collectionName' does not exist, creating it" -Level "Info"
        
        $schema = Get-QdrantCollectionSchema -ConfigType $ConfigType -AsObject
        $result = Invoke-QdrantOperation -Operation "CreateCollection" -CollectionName $collectionName -AsObject
        
        if (-not $result) {
            Write-Log "Failed to create collection '$collectionName'" -Level "Error"
            return $false
        }
    }
    
    # Générer un ID pour la configuration
    $pointId = Get-ConfigurationId -Configuration $Configuration -ConfigType $ConfigType
    
    # Préparer les métadonnées
    $metadata = Get-ConfigurationMetadata -Configuration $Configuration -ConfigType $ConfigType
    
    # Ajouter la configuration complète aux métadonnées
    $metadata.configuration = $Configuration
    
    # Vectoriser la configuration
    $vector = ConvertTo-Vector -EmbeddingProvider $EmbeddingProvider -ModelName $ModelName -InputPath $ConfigPath -ConfigType $ConfigType -Normalize -AsObject
    
    if ($null -eq $vector) {
        Write-Log "Failed to vectorize configuration" -Level "Error"
        return $false
    }
    
    # Sauvegarder la configuration dans Qdrant
    $result = Invoke-QdrantOperation -Operation "UpsertPoint" -CollectionName $collectionName -PointId $pointId -Vector $vector -Payload $metadata -AsObject
    
    if ($result) {
        Write-Log "Configuration saved to Qdrant with ID: $pointId" -Level "Info"
        return $true
    } else {
        Write-Log "Failed to save configuration to Qdrant" -Level "Error"
        return $false
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Save-ConfigurationToQdrant -ConfigType $ConfigType -ConfigPath $ConfigPath -Configuration $Configuration -ServerUrl $ServerUrl -ApiKey $ApiKey -EmbeddingProvider $EmbeddingProvider -ModelName $ModelName -Force:$Force
}
