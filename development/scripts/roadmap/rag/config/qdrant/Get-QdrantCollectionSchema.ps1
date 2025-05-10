# Get-QdrantCollectionSchema.ps1
# Script pour définir le schéma de collection pour Qdrant
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search", "All")]
    [string]$ConfigType = "All",
    
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

# Fonction pour obtenir le schéma de collection pour les templates
function Get-TemplateCollectionSchema {
    [CmdletBinding()]
    param()
    
    $schema = @{
        collection_name = "roadmap_templates"
        vectors = @{
            size = 1536  # Dimension pour les embeddings
            distance = "Cosine"
        }
        optimizers = @{
            indexing_threshold = 20000  # Seuil pour l'indexation automatique
            max_segment_size = 100000   # Taille maximale des segments
        }
        shard_number = 1  # Nombre de shards pour la collection
        replication_factor = 1  # Facteur de réplication
        write_consistency_factor = 1  # Facteur de cohérence d'écriture
        on_disk_payload = $true  # Stocker les payloads sur disque
        hnsw_config = @{
            m = 16  # Nombre de connexions par nœud
            ef_construct = 100  # Facteur d'exploration lors de la construction
            full_scan_threshold = 10000  # Seuil pour le scan complet
        }
        wal_config = @{
            wal_capacity_mb = 32  # Capacité du WAL en Mo
            wal_segments_ahead = 2  # Nombre de segments WAL à l'avance
        }
        optimizers_config = @{
            deleted_threshold = 0.2  # Seuil de suppression pour l'optimisation
            vacuum_min_vector_number = 1000  # Nombre minimum de vecteurs pour le vacuum
            default_segment_number = 2  # Nombre de segments par défaut
            max_segment_size = 100000  # Taille maximale des segments
            memmap_threshold = 50000  # Seuil pour utiliser memmap
            indexing_threshold = 20000  # Seuil pour l'indexation
            flush_interval_sec = 5  # Intervalle de flush en secondes
        }
        metadata_schema = @{
            name = @{
                type = "keyword"
                index = $true
            }
            version = @{
                type = "keyword"
                index = $true
            }
            type = @{
                type = "keyword"
                index = $true
            }
            author = @{
                type = "keyword"
                index = $true
            }
            created_at = @{
                type = "datetime"
                index = $true
            }
            updated_at = @{
                type = "datetime"
                index = $true
            }
            tags = @{
                type = "keyword"
                index = $true
            }
            description = @{
                type = "text"
                index = $true
                tokenizer = "word"
            }
            content = @{
                type = "text"
                index = $true
                tokenizer = "word"
            }
            is_archived = @{
                type = "bool"
                index = $true
            }
        }
        vector_metadata = @{
            source = "content"  # Champ source pour la vectorisation
            model = "text-embedding-3-large"  # Modèle d'embedding à utiliser
            dimensions = 1536  # Dimensions du vecteur
            normalize = $true  # Normaliser les vecteurs
        }
    }
    
    return $schema
}

# Fonction pour obtenir le schéma de collection pour les visualisations
function Get-VisualizationCollectionSchema {
    [CmdletBinding()]
    param()
    
    $schema = @{
        collection_name = "roadmap_visualizations"
        vectors = @{
            size = 1536  # Dimension pour les embeddings
            distance = "Cosine"
        }
        optimizers = @{
            indexing_threshold = 20000  # Seuil pour l'indexation automatique
            max_segment_size = 100000   # Taille maximale des segments
        }
        shard_number = 1  # Nombre de shards pour la collection
        replication_factor = 1  # Facteur de réplication
        write_consistency_factor = 1  # Facteur de cohérence d'écriture
        on_disk_payload = $true  # Stocker les payloads sur disque
        hnsw_config = @{
            m = 16  # Nombre de connexions par nœud
            ef_construct = 100  # Facteur d'exploration lors de la construction
            full_scan_threshold = 10000  # Seuil pour le scan complet
        }
        wal_config = @{
            wal_capacity_mb = 32  # Capacité du WAL en Mo
            wal_segments_ahead = 2  # Nombre de segments WAL à l'avance
        }
        optimizers_config = @{
            deleted_threshold = 0.2  # Seuil de suppression pour l'optimisation
            vacuum_min_vector_number = 1000  # Nombre minimum de vecteurs pour le vacuum
            default_segment_number = 2  # Nombre de segments par défaut
            max_segment_size = 100000  # Taille maximale des segments
            memmap_threshold = 50000  # Seuil pour utiliser memmap
            indexing_threshold = 20000  # Seuil pour l'indexation
            flush_interval_sec = 5  # Intervalle de flush en secondes
        }
        metadata_schema = @{
            name = @{
                type = "keyword"
                index = $true
            }
            version = @{
                type = "keyword"
                index = $true
            }
            author = @{
                type = "keyword"
                index = $true
            }
            created_at = @{
                type = "datetime"
                index = $true
            }
            updated_at = @{
                type = "datetime"
                index = $true
            }
            tags = @{
                type = "keyword"
                index = $true
            }
            description = @{
                type = "text"
                index = $true
                tokenizer = "word"
            }
            chart_type = @{
                type = "keyword"
                index = $true
            }
            data_field = @{
                type = "keyword"
                index = $true
            }
            is_archived = @{
                type = "bool"
                index = $true
            }
        }
        vector_metadata = @{
            source = "description"  # Champ source pour la vectorisation
            model = "text-embedding-3-large"  # Modèle d'embedding à utiliser
            dimensions = 1536  # Dimensions du vecteur
            normalize = $true  # Normaliser les vecteurs
        }
    }
    
    return $schema
}

# Fonction pour obtenir le schéma de collection pour les mappages de données
function Get-DataMappingCollectionSchema {
    [CmdletBinding()]
    param()
    
    $schema = @{
        collection_name = "roadmap_data_mappings"
        vectors = @{
            size = 1536  # Dimension pour les embeddings
            distance = "Cosine"
        }
        optimizers = @{
            indexing_threshold = 20000  # Seuil pour l'indexation automatique
            max_segment_size = 100000   # Taille maximale des segments
        }
        shard_number = 1  # Nombre de shards pour la collection
        replication_factor = 1  # Facteur de réplication
        write_consistency_factor = 1  # Facteur de cohérence d'écriture
        on_disk_payload = $true  # Stocker les payloads sur disque
        hnsw_config = @{
            m = 16  # Nombre de connexions par nœud
            ef_construct = 100  # Facteur d'exploration lors de la construction
            full_scan_threshold = 10000  # Seuil pour le scan complet
        }
        wal_config = @{
            wal_capacity_mb = 32  # Capacité du WAL en Mo
            wal_segments_ahead = 2  # Nombre de segments WAL à l'avance
        }
        optimizers_config = @{
            deleted_threshold = 0.2  # Seuil de suppression pour l'optimisation
            vacuum_min_vector_number = 1000  # Nombre minimum de vecteurs pour le vacuum
            default_segment_number = 2  # Nombre de segments par défaut
            max_segment_size = 100000  # Taille maximale des segments
            memmap_threshold = 50000  # Seuil pour utiliser memmap
            indexing_threshold = 20000  # Seuil pour l'indexation
            flush_interval_sec = 5  # Intervalle de flush en secondes
        }
        metadata_schema = @{
            version = @{
                type = "keyword"
                index = $true
            }
            created_date = @{
                type = "datetime"
                index = $true
            }
            modified_date = @{
                type = "datetime"
                index = $true
            }
            mapping_name = @{
                type = "keyword"
                index = $true
            }
            mapping_description = @{
                type = "text"
                index = $true
                tokenizer = "word"
            }
            mapping_type = @{
                type = "keyword"
                index = $true
            }
            data_source = @{
                type = "keyword"
                index = $true
            }
            group_by = @{
                type = "keyword"
                index = $true
            }
            value_field = @{
                type = "keyword"
                index = $true
            }
            is_archived = @{
                type = "bool"
                index = $true
            }
        }
        vector_metadata = @{
            source = "mapping_description"  # Champ source pour la vectorisation
            model = "text-embedding-3-large"  # Modèle d'embedding à utiliser
            dimensions = 1536  # Dimensions du vecteur
            normalize = $true  # Normaliser les vecteurs
        }
    }
    
    return $schema
}

# Fonction pour obtenir le schéma de collection pour les graphiques
function Get-ChartCollectionSchema {
    [CmdletBinding()]
    param()
    
    $schema = @{
        collection_name = "roadmap_charts"
        vectors = @{
            size = 1536  # Dimension pour les embeddings
            distance = "Cosine"
        }
        optimizers = @{
            indexing_threshold = 20000  # Seuil pour l'indexation automatique
            max_segment_size = 100000   # Taille maximale des segments
        }
        shard_number = 1  # Nombre de shards pour la collection
        replication_factor = 1  # Facteur de réplication
        write_consistency_factor = 1  # Facteur de cohérence d'écriture
        on_disk_payload = $true  # Stocker les payloads sur disque
        hnsw_config = @{
            m = 16  # Nombre de connexions par nœud
            ef_construct = 100  # Facteur d'exploration lors de la construction
            full_scan_threshold = 10000  # Seuil pour le scan complet
        }
        wal_config = @{
            wal_capacity_mb = 32  # Capacité du WAL en Mo
            wal_segments_ahead = 2  # Nombre de segments WAL à l'avance
        }
        optimizers_config = @{
            deleted_threshold = 0.2  # Seuil de suppression pour l'optimisation
            vacuum_min_vector_number = 1000  # Nombre minimum de vecteurs pour le vacuum
            default_segment_number = 2  # Nombre de segments par défaut
            max_segment_size = 100000  # Taille maximale des segments
            memmap_threshold = 50000  # Seuil pour utiliser memmap
            indexing_threshold = 20000  # Seuil pour l'indexation
            flush_interval_sec = 5  # Intervalle de flush en secondes
        }
        metadata_schema = @{
            chart_type = @{
                type = "keyword"
                index = $true
            }
            data_field = @{
                type = "keyword"
                index = $true
            }
            title = @{
                type = "text"
                index = $true
                tokenizer = "word"
            }
            show_legend = @{
                type = "bool"
                index = $true
            }
            enable_animation = @{
                type = "bool"
                index = $true
            }
            created_at = @{
                type = "datetime"
                index = $true
            }
            updated_at = @{
                type = "datetime"
                index = $true
            }
            is_archived = @{
                type = "bool"
                index = $true
            }
        }
        vector_metadata = @{
            source = "title"  # Champ source pour la vectorisation
            model = "text-embedding-3-large"  # Modèle d'embedding à utiliser
            dimensions = 1536  # Dimensions du vecteur
            normalize = $true  # Normaliser les vecteurs
        }
    }
    
    return $schema
}

# Fonction pour obtenir le schéma de collection pour les exports
function Get-ExportCollectionSchema {
    [CmdletBinding()]
    param()
    
    $schema = @{
        collection_name = "roadmap_exports"
        vectors = @{
            size = 1536  # Dimension pour les embeddings
            distance = "Cosine"
        }
        optimizers = @{
            indexing_threshold = 20000  # Seuil pour l'indexation automatique
            max_segment_size = 100000   # Taille maximale des segments
        }
        shard_number = 1  # Nombre de shards pour la collection
        replication_factor = 1  # Facteur de réplication
        write_consistency_factor = 1  # Facteur de cohérence d'écriture
        on_disk_payload = $true  # Stocker les payloads sur disque
        hnsw_config = @{
            m = 16  # Nombre de connexions par nœud
            ef_construct = 100  # Facteur d'exploration lors de la construction
            full_scan_threshold = 10000  # Seuil pour le scan complet
        }
        wal_config = @{
            wal_capacity_mb = 32  # Capacité du WAL en Mo
            wal_segments_ahead = 2  # Nombre de segments WAL à l'avance
        }
        optimizers_config = @{
            deleted_threshold = 0.2  # Seuil de suppression pour l'optimisation
            vacuum_min_vector_number = 1000  # Nombre minimum de vecteurs pour le vacuum
            default_segment_number = 2  # Nombre de segments par défaut
            max_segment_size = 100000  # Taille maximale des segments
            memmap_threshold = 50000  # Seuil pour utiliser memmap
            indexing_threshold = 20000  # Seuil pour l'indexation
            flush_interval_sec = 5  # Intervalle de flush en secondes
        }
        metadata_schema = @{
            export_type = @{
                type = "keyword"
                index = $true
            }
            export_name = @{
                type = "keyword"
                index = $true
            }
            export_description = @{
                type = "text"
                index = $true
                tokenizer = "word"
            }
            format = @{
                type = "keyword"
                index = $true
            }
            created_at = @{
                type = "datetime"
                index = $true
            }
            source_id = @{
                type = "keyword"
                index = $true
            }
            source_type = @{
                type = "keyword"
                index = $true
            }
            is_archived = @{
                type = "bool"
                index = $true
            }
        }
        vector_metadata = @{
            source = "export_description"  # Champ source pour la vectorisation
            model = "text-embedding-3-large"  # Modèle d'embedding à utiliser
            dimensions = 1536  # Dimensions du vecteur
            normalize = $true  # Normaliser les vecteurs
        }
    }
    
    return $schema
}

# Fonction pour obtenir le schéma de collection pour les recherches
function Get-SearchCollectionSchema {
    [CmdletBinding()]
    param()
    
    $schema = @{
        collection_name = "roadmap_searches"
        vectors = @{
            size = 1536  # Dimension pour les embeddings
            distance = "Cosine"
        }
        optimizers = @{
            indexing_threshold = 20000  # Seuil pour l'indexation automatique
            max_segment_size = 100000   # Taille maximale des segments
        }
        shard_number = 1  # Nombre de shards pour la collection
        replication_factor = 1  # Facteur de réplication
        write_consistency_factor = 1  # Facteur de cohérence d'écriture
        on_disk_payload = $true  # Stocker les payloads sur disque
        hnsw_config = @{
            m = 16  # Nombre de connexions par nœud
            ef_construct = 100  # Facteur d'exploration lors de la construction
            full_scan_threshold = 10000  # Seuil pour le scan complet
        }
        wal_config = @{
            wal_capacity_mb = 32  # Capacité du WAL en Mo
            wal_segments_ahead = 2  # Nombre de segments WAL à l'avance
        }
        optimizers_config = @{
            deleted_threshold = 0.2  # Seuil de suppression pour l'optimisation
            vacuum_min_vector_number = 1000  # Nombre minimum de vecteurs pour le vacuum
            default_segment_number = 2  # Nombre de segments par défaut
            max_segment_size = 100000  # Taille maximale des segments
            memmap_threshold = 50000  # Seuil pour utiliser memmap
            indexing_threshold = 20000  # Seuil pour l'indexation
            flush_interval_sec = 5  # Intervalle de flush en secondes
        }
        metadata_schema = @{
            search_type = @{
                type = "keyword"
                index = $true
            }
            query = @{
                type = "text"
                index = $true
                tokenizer = "word"
            }
            created_at = @{
                type = "datetime"
                index = $true
            }
            user_id = @{
                type = "keyword"
                index = $true
            }
            filters = @{
                type = "json"
                index = $false
            }
            sort = @{
                type = "json"
                index = $false
            }
            limit = @{
                type = "integer"
                index = $true
            }
            include_archived = @{
                type = "bool"
                index = $true
            }
            is_saved = @{
                type = "bool"
                index = $true
            }
        }
        vector_metadata = @{
            source = "query"  # Champ source pour la vectorisation
            model = "text-embedding-3-large"  # Modèle d'embedding à utiliser
            dimensions = 1536  # Dimensions du vecteur
            normalize = $true  # Normaliser les vecteurs
        }
    }
    
    return $schema
}

# Fonction pour obtenir tous les schémas de collection
function Get-AllCollectionSchemas {
    [CmdletBinding()]
    param()
    
    $schemas = @{
        template = Get-TemplateCollectionSchema
        visualization = Get-VisualizationCollectionSchema
        data_mapping = Get-DataMappingCollectionSchema
        chart = Get-ChartCollectionSchema
        export = Get-ExportCollectionSchema
        search = Get-SearchCollectionSchema
    }
    
    return $schemas
}

# Fonction principale
function Get-QdrantCollectionSchema {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search", "All")]
        [string]$ConfigType = "All",
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$AsObject
    )
    
    # Obtenir le schéma demandé
    $schema = $null
    
    switch ($ConfigType) {
        "Template" {
            $schema = Get-TemplateCollectionSchema
            Write-Log "Generated template collection schema" -Level "Info"
        }
        "Visualization" {
            $schema = Get-VisualizationCollectionSchema
            Write-Log "Generated visualization collection schema" -Level "Info"
        }
        "DataMapping" {
            $schema = Get-DataMappingCollectionSchema
            Write-Log "Generated data mapping collection schema" -Level "Info"
        }
        "Chart" {
            $schema = Get-ChartCollectionSchema
            Write-Log "Generated chart collection schema" -Level "Info"
        }
        "Export" {
            $schema = Get-ExportCollectionSchema
            Write-Log "Generated export collection schema" -Level "Info"
        }
        "Search" {
            $schema = Get-SearchCollectionSchema
            Write-Log "Generated search collection schema" -Level "Info"
        }
        "All" {
            $schema = Get-AllCollectionSchemas
            Write-Log "Generated all collection schemas" -Level "Info"
        }
    }
    
    # Sauvegarder le schéma si un chemin de sortie est spécifié
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        try {
            $schema | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
            Write-Log "Schema saved to: $OutputPath" -Level "Info"
        } catch {
            Write-Log "Error saving schema: $_" -Level "Error"
        }
    }
    
    # Retourner le schéma selon le format demandé
    if ($AsObject) {
        return $schema
    } else {
        return $schema | ConvertTo-Json -Depth 10
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Get-QdrantCollectionSchema -ConfigType $ConfigType -OutputPath $OutputPath -AsObject:$AsObject
}
