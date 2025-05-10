# Invoke-QdrantOperation.ps1
# Script pour gérer les opérations CRUD avec Qdrant
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("CreateCollection", "GetCollection", "DeleteCollection", "ListCollections", 
                "UpsertPoint", "GetPoint", "DeletePoint", "SearchPoints", "ScrollPoints", 
                "CountPoints", "CreateFieldIndex", "DeleteFieldIndex")]
    [string]$Operation = "ListCollections",
    
    [Parameter(Mandatory = $false)]
    [string]$CollectionName,
    
    [Parameter(Mandatory = $false)]
    [string]$PointId,
    
    [Parameter(Mandatory = $false)]
    [object]$Payload,
    
    [Parameter(Mandatory = $false)]
    [object]$Vector,
    
    [Parameter(Mandatory = $false)]
    [object]$Filter,
    
    [Parameter(Mandatory = $false)]
    [object]$SearchParams,
    
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

# Importer le script de connexion
$connectionPath = Join-Path -Path $scriptPath -ChildPath "Connect-QdrantServer.ps1"
$schemaPath = Join-Path -Path $scriptPath -ChildPath "Get-QdrantCollectionSchema.ps1"

if (Test-Path -Path $connectionPath) {
    . $connectionPath
} else {
    Write-Log "Connection script not found: $connectionPath" -Level "Error"
    exit 1
}

if (Test-Path -Path $schemaPath) {
    . $schemaPath
} else {
    Write-Log "Schema script not found: $schemaPath" -Level "Error"
    exit 1
}

# Fonction pour invoquer une requête REST à Qdrant
function Invoke-QdrantRequest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Endpoint,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("GET", "POST", "PUT", "DELETE")]
        [string]$Method,
        
        [Parameter(Mandatory = $false)]
        [object]$Body,
        
        [Parameter(Mandatory = $false)]
        [int]$Timeout = 30
    )
    
    # Obtenir la connexion
    $connection = Get-QdrantConnection
    
    if ($null -eq $connection) {
        Write-Log "No active Qdrant connection. Use Connect-QdrantServer first." -Level "Error"
        return $null
    }
    
    # Construire l'URL complète
    $url = "$($connection.ServerUrl)$Endpoint"
    
    # Préparer les paramètres de la requête
    $params = @{
        Uri = $url
        Method = $Method
        Headers = $connection.Headers
        TimeoutSec = $Timeout
        UseBasicParsing = $true
    }
    
    # Ajouter le corps de la requête si nécessaire
    if ($null -ne $Body) {
        $params.Body = ($Body | ConvertTo-Json -Depth 10)
        $params.ContentType = "application/json"
    }
    
    # Exécuter la requête
    try {
        Write-Log "Sending $Method request to $url" -Level "Debug"
        
        if ($connection.UseConnectionPool) {
            $poolConnection = Get-ConnectionFromPool
            
            try {
                $response = Invoke-RestMethod @params
            } finally {
                Release-ConnectionToPool -Connection $poolConnection
            }
        } else {
            $response = Invoke-RestMethod @params
        }
        
        return $response
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $statusDescription = $_.Exception.Response.StatusDescription
        
        Write-Log "Error in Qdrant request: $Method $url - Status: $statusCode $statusDescription" -Level "Error"
        Write-Log "Error details: $_" -Level "Error"
        
        return $null
    }
}

# Fonction pour créer une collection
function New-QdrantCollection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$CollectionName,
        
        [Parameter(Mandatory = $false)]
        [object]$Schema
    )
    
    # Si aucun schéma n'est fourni, utiliser le schéma par défaut
    if ($null -eq $Schema) {
        $Schema = Get-QdrantCollectionSchema -ConfigType "Template" -AsObject
    }
    
    # Préparer le corps de la requête
    $body = @{
        vectors = $Schema.vectors
        optimizers_config = $Schema.optimizers_config
    }
    
    # Ajouter les configurations optionnelles si présentes
    if ($null -ne $Schema.shard_number) {
        $body.shard_number = $Schema.shard_number
    }
    
    if ($null -ne $Schema.replication_factor) {
        $body.replication_factor = $Schema.replication_factor
    }
    
    if ($null -ne $Schema.write_consistency_factor) {
        $body.write_consistency_factor = $Schema.write_consistency_factor
    }
    
    if ($null -ne $Schema.on_disk_payload) {
        $body.on_disk_payload = $Schema.on_disk_payload
    }
    
    if ($null -ne $Schema.hnsw_config) {
        $body.hnsw_config = $Schema.hnsw_config
    }
    
    if ($null -ne $Schema.wal_config) {
        $body.wal_config = $Schema.wal_config
    }
    
    # Envoyer la requête
    $endpoint = "/collections/$CollectionName"
    $response = Invoke-QdrantRequest -Endpoint $endpoint -Method "PUT" -Body $body
    
    if ($null -ne $response -and $response.result -eq $true) {
        Write-Log "Collection '$CollectionName' created successfully" -Level "Info"
        
        # Créer les index de champs si définis dans le schéma
        if ($null -ne $Schema.metadata_schema) {
            foreach ($field in $Schema.metadata_schema.Keys) {
                $fieldSchema = $Schema.metadata_schema[$field]
                
                if ($fieldSchema.index -eq $true) {
                    $fieldType = $fieldSchema.type
                    
                    $indexBody = @{
                        field_name = $field
                        field_schema = $fieldType
                    }
                    
                    if ($fieldType -eq "text" -and $null -ne $fieldSchema.tokenizer) {
                        $indexBody.field_schema = @{
                            type = "text"
                            tokenizer = $fieldSchema.tokenizer
                        }
                    }
                    
                    $indexEndpoint = "/collections/$CollectionName/index"
                    $indexResponse = Invoke-QdrantRequest -Endpoint $indexEndpoint -Method "PUT" -Body $indexBody
                    
                    if ($null -ne $indexResponse -and $indexResponse.result -eq $true) {
                        Write-Log "Created index for field '$field' in collection '$CollectionName'" -Level "Info"
                    } else {
                        Write-Log "Failed to create index for field '$field' in collection '$CollectionName'" -Level "Warning"
                    }
                }
            }
        }
        
        return $true
    } else {
        Write-Log "Failed to create collection '$CollectionName'" -Level "Error"
        return $false
    }
}

# Fonction pour obtenir les informations d'une collection
function Get-QdrantCollection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$CollectionName
    )
    
    $endpoint = "/collections/$CollectionName"
    $response = Invoke-QdrantRequest -Endpoint $endpoint -Method "GET"
    
    if ($null -ne $response -and $null -ne $response.result) {
        Write-Log "Retrieved information for collection '$CollectionName'" -Level "Info"
        return $response.result
    } else {
        Write-Log "Failed to retrieve information for collection '$CollectionName'" -Level "Error"
        return $null
    }
}

# Fonction pour supprimer une collection
function Remove-QdrantCollection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$CollectionName
    )
    
    $endpoint = "/collections/$CollectionName"
    $response = Invoke-QdrantRequest -Endpoint $endpoint -Method "DELETE"
    
    if ($null -ne $response -and $response.result -eq $true) {
        Write-Log "Collection '$CollectionName' deleted successfully" -Level "Info"
        return $true
    } else {
        Write-Log "Failed to delete collection '$CollectionName'" -Level "Error"
        return $false
    }
}

# Fonction pour lister toutes les collections
function Get-QdrantCollections {
    [CmdletBinding()]
    param()
    
    $endpoint = "/collections"
    $response = Invoke-QdrantRequest -Endpoint $endpoint -Method "GET"
    
    if ($null -ne $response -and $null -ne $response.result) {
        Write-Log "Retrieved list of collections" -Level "Info"
        return $response.result.collections
    } else {
        Write-Log "Failed to retrieve list of collections" -Level "Error"
        return $null
    }
}

# Fonction pour ajouter ou mettre à jour un point
function Set-QdrantPoint {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$CollectionName,
        
        [Parameter(Mandatory = $true)]
        [string]$PointId,
        
        [Parameter(Mandatory = $true)]
        [object]$Vector,
        
        [Parameter(Mandatory = $false)]
        [object]$Payload
    )
    
    $endpoint = "/collections/$CollectionName/points"
    
    $body = @{
        points = @(
            @{
                id = $PointId
                vector = $Vector
            }
        )
    }
    
    if ($null -ne $Payload) {
        $body.points[0].payload = $Payload
    }
    
    $response = Invoke-QdrantRequest -Endpoint $endpoint -Method "PUT" -Body $body
    
    if ($null -ne $response -and $response.result -eq $true) {
        Write-Log "Point '$PointId' upserted successfully in collection '$CollectionName'" -Level "Info"
        return $true
    } else {
        Write-Log "Failed to upsert point '$PointId' in collection '$CollectionName'" -Level "Error"
        return $false
    }
}

# Fonction pour obtenir un point
function Get-QdrantPoint {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$CollectionName,
        
        [Parameter(Mandatory = $true)]
        [string]$PointId
    )
    
    $endpoint = "/collections/$CollectionName/points/$PointId"
    $response = Invoke-QdrantRequest -Endpoint $endpoint -Method "GET"
    
    if ($null -ne $response -and $null -ne $response.result) {
        Write-Log "Retrieved point '$PointId' from collection '$CollectionName'" -Level "Info"
        return $response.result
    } else {
        Write-Log "Failed to retrieve point '$PointId' from collection '$CollectionName'" -Level "Error"
        return $null
    }
}

# Fonction pour supprimer un point
function Remove-QdrantPoint {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$CollectionName,
        
        [Parameter(Mandatory = $true)]
        [string]$PointId
    )
    
    $endpoint = "/collections/$CollectionName/points/delete"
    
    $body = @{
        points = @($PointId)
    }
    
    $response = Invoke-QdrantRequest -Endpoint $endpoint -Method "POST" -Body $body
    
    if ($null -ne $response -and $response.result -eq $true) {
        Write-Log "Point '$PointId' deleted successfully from collection '$CollectionName'" -Level "Info"
        return $true
    } else {
        Write-Log "Failed to delete point '$PointId' from collection '$CollectionName'" -Level "Error"
        return $false
    }
}

# Fonction pour rechercher des points
function Search-QdrantPoints {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$CollectionName,
        
        [Parameter(Mandatory = $true)]
        [object]$Vector,
        
        [Parameter(Mandatory = $false)]
        [object]$Filter,
        
        [Parameter(Mandatory = $false)]
        [int]$Limit = 10,
        
        [Parameter(Mandatory = $false)]
        [int]$Offset = 0,
        
        [Parameter(Mandatory = $false)]
        [switch]$WithPayload,
        
        [Parameter(Mandatory = $false)]
        [switch]$WithVector
    )
    
    $endpoint = "/collections/$CollectionName/points/search"
    
    $body = @{
        vector = $Vector
        limit = $Limit
        offset = $Offset
        with_payload = $WithPayload.IsPresent
        with_vector = $WithVector.IsPresent
    }
    
    if ($null -ne $Filter) {
        $body.filter = $Filter
    }
    
    $response = Invoke-QdrantRequest -Endpoint $endpoint -Method "POST" -Body $body
    
    if ($null -ne $response -and $null -ne $response.result) {
        Write-Log "Search completed in collection '$CollectionName' with $($response.result.Count) results" -Level "Info"
        return $response.result
    } else {
        Write-Log "Failed to search in collection '$CollectionName'" -Level "Error"
        return $null
    }
}

# Fonction pour parcourir les points
function Get-QdrantPointsScroll {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$CollectionName,
        
        [Parameter(Mandatory = $false)]
        [object]$Filter,
        
        [Parameter(Mandatory = $false)]
        [int]$Limit = 10,
        
        [Parameter(Mandatory = $false)]
        [string]$ScrollId,
        
        [Parameter(Mandatory = $false)]
        [switch]$WithPayload,
        
        [Parameter(Mandatory = $false)]
        [switch]$WithVector
    )
    
    $endpoint = "/collections/$CollectionName/points/scroll"
    
    $body = @{
        limit = $Limit
        with_payload = $WithPayload.IsPresent
        with_vector = $WithVector.IsPresent
    }
    
    if ($null -ne $Filter) {
        $body.filter = $Filter
    }
    
    if (-not [string]::IsNullOrEmpty($ScrollId)) {
        $body.offset = $ScrollId
    }
    
    $response = Invoke-QdrantRequest -Endpoint $endpoint -Method "POST" -Body $body
    
    if ($null -ne $response -and $null -ne $response.result) {
        Write-Log "Scroll completed in collection '$CollectionName' with $($response.result.points.Count) results" -Level "Info"
        return $response.result
    } else {
        Write-Log "Failed to scroll in collection '$CollectionName'" -Level "Error"
        return $null
    }
}

# Fonction pour compter les points
function Get-QdrantPointsCount {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$CollectionName,
        
        [Parameter(Mandatory = $false)]
        [object]$Filter
    )
    
    $endpoint = "/collections/$CollectionName/points/count"
    
    $body = @{}
    
    if ($null -ne $Filter) {
        $body.filter = $Filter
    }
    
    $response = Invoke-QdrantRequest -Endpoint $endpoint -Method "POST" -Body $body
    
    if ($null -ne $response -and $null -ne $response.result) {
        Write-Log "Count completed in collection '$CollectionName': $($response.result.count) points" -Level "Info"
        return $response.result.count
    } else {
        Write-Log "Failed to count points in collection '$CollectionName'" -Level "Error"
        return $null
    }
}

# Fonction pour créer un index de champ
function New-QdrantFieldIndex {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$CollectionName,
        
        [Parameter(Mandatory = $true)]
        [string]$FieldName,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("keyword", "integer", "float", "geo", "text", "bool", "datetime")]
        [string]$FieldType,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("word", "whitespace", "prefix", "fasttext")]
        [string]$Tokenizer
    )
    
    $endpoint = "/collections/$CollectionName/index"
    
    $body = @{
        field_name = $FieldName
    }
    
    if ($FieldType -eq "text" -and -not [string]::IsNullOrEmpty($Tokenizer)) {
        $body.field_schema = @{
            type = $FieldType
            tokenizer = $Tokenizer
        }
    } else {
        $body.field_schema = $FieldType
    }
    
    $response = Invoke-QdrantRequest -Endpoint $endpoint -Method "PUT" -Body $body
    
    if ($null -ne $response -and $response.result -eq $true) {
        Write-Log "Index created for field '$FieldName' in collection '$CollectionName'" -Level "Info"
        return $true
    } else {
        Write-Log "Failed to create index for field '$FieldName' in collection '$CollectionName'" -Level "Error"
        return $false
    }
}

# Fonction pour supprimer un index de champ
function Remove-QdrantFieldIndex {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$CollectionName,
        
        [Parameter(Mandatory = $true)]
        [string]$FieldName
    )
    
    $endpoint = "/collections/$CollectionName/index/$FieldName"
    $response = Invoke-QdrantRequest -Endpoint $endpoint -Method "DELETE"
    
    if ($null -ne $response -and $response.result -eq $true) {
        Write-Log "Index deleted for field '$FieldName' in collection '$CollectionName'" -Level "Info"
        return $true
    } else {
        Write-Log "Failed to delete index for field '$FieldName' in collection '$CollectionName'" -Level "Error"
        return $false
    }
}

# Fonction principale
function Invoke-QdrantOperation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("CreateCollection", "GetCollection", "DeleteCollection", "ListCollections", 
                    "UpsertPoint", "GetPoint", "DeletePoint", "SearchPoints", "ScrollPoints", 
                    "CountPoints", "CreateFieldIndex", "DeleteFieldIndex")]
        [string]$Operation = "ListCollections",
        
        [Parameter(Mandatory = $false)]
        [string]$CollectionName,
        
        [Parameter(Mandatory = $false)]
        [string]$PointId,
        
        [Parameter(Mandatory = $false)]
        [object]$Payload,
        
        [Parameter(Mandatory = $false)]
        [object]$Vector,
        
        [Parameter(Mandatory = $false)]
        [object]$Filter,
        
        [Parameter(Mandatory = $false)]
        [object]$SearchParams,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$AsObject
    )
    
    # Vérifier si une connexion existe
    $connection = Get-QdrantConnection
    
    if ($null -eq $connection) {
        Write-Log "No active Qdrant connection. Use Connect-QdrantServer first." -Level "Error"
        return $null
    }
    
    # Exécuter l'opération demandée
    $result = $null
    
    switch ($Operation) {
        "CreateCollection" {
            if ([string]::IsNullOrEmpty($CollectionName)) {
                Write-Log "CollectionName is required for CreateCollection operation" -Level "Error"
                return $null
            }
            
            $schema = Get-QdrantCollectionSchema -ConfigType "Template" -AsObject
            $result = New-QdrantCollection -CollectionName $CollectionName -Schema $schema
        }
        "GetCollection" {
            if ([string]::IsNullOrEmpty($CollectionName)) {
                Write-Log "CollectionName is required for GetCollection operation" -Level "Error"
                return $null
            }
            
            $result = Get-QdrantCollection -CollectionName $CollectionName
        }
        "DeleteCollection" {
            if ([string]::IsNullOrEmpty($CollectionName)) {
                Write-Log "CollectionName is required for DeleteCollection operation" -Level "Error"
                return $null
            }
            
            $result = Remove-QdrantCollection -CollectionName $CollectionName
        }
        "ListCollections" {
            $result = Get-QdrantCollections
        }
        "UpsertPoint" {
            if ([string]::IsNullOrEmpty($CollectionName) -or [string]::IsNullOrEmpty($PointId) -or $null -eq $Vector) {
                Write-Log "CollectionName, PointId, and Vector are required for UpsertPoint operation" -Level "Error"
                return $null
            }
            
            $result = Set-QdrantPoint -CollectionName $CollectionName -PointId $PointId -Vector $Vector -Payload $Payload
        }
        "GetPoint" {
            if ([string]::IsNullOrEmpty($CollectionName) -or [string]::IsNullOrEmpty($PointId)) {
                Write-Log "CollectionName and PointId are required for GetPoint operation" -Level "Error"
                return $null
            }
            
            $result = Get-QdrantPoint -CollectionName $CollectionName -PointId $PointId
        }
        "DeletePoint" {
            if ([string]::IsNullOrEmpty($CollectionName) -or [string]::IsNullOrEmpty($PointId)) {
                Write-Log "CollectionName and PointId are required for DeletePoint operation" -Level "Error"
                return $null
            }
            
            $result = Remove-QdrantPoint -CollectionName $CollectionName -PointId $PointId
        }
        "SearchPoints" {
            if ([string]::IsNullOrEmpty($CollectionName) -or $null -eq $Vector) {
                Write-Log "CollectionName and Vector are required for SearchPoints operation" -Level "Error"
                return $null
            }
            
            $limit = 10
            $offset = 0
            $withPayload = $true
            $withVector = $false
            
            if ($null -ne $SearchParams) {
                if ($null -ne $SearchParams.limit) {
                    $limit = $SearchParams.limit
                }
                
                if ($null -ne $SearchParams.offset) {
                    $offset = $SearchParams.offset
                }
                
                if ($null -ne $SearchParams.with_payload) {
                    $withPayload = $SearchParams.with_payload
                }
                
                if ($null -ne $SearchParams.with_vector) {
                    $withVector = $SearchParams.with_vector
                }
            }
            
            $result = Search-QdrantPoints -CollectionName $CollectionName -Vector $Vector -Filter $Filter -Limit $limit -Offset $offset -WithPayload:$withPayload -WithVector:$withVector
        }
        "ScrollPoints" {
            if ([string]::IsNullOrEmpty($CollectionName)) {
                Write-Log "CollectionName is required for ScrollPoints operation" -Level "Error"
                return $null
            }
            
            $limit = 10
            $scrollId = $null
            $withPayload = $true
            $withVector = $false
            
            if ($null -ne $SearchParams) {
                if ($null -ne $SearchParams.limit) {
                    $limit = $SearchParams.limit
                }
                
                if ($null -ne $SearchParams.scroll_id) {
                    $scrollId = $SearchParams.scroll_id
                }
                
                if ($null -ne $SearchParams.with_payload) {
                    $withPayload = $SearchParams.with_payload
                }
                
                if ($null -ne $SearchParams.with_vector) {
                    $withVector = $SearchParams.with_vector
                }
            }
            
            $result = Get-QdrantPointsScroll -CollectionName $CollectionName -Filter $Filter -Limit $limit -ScrollId $scrollId -WithPayload:$withPayload -WithVector:$withVector
        }
        "CountPoints" {
            if ([string]::IsNullOrEmpty($CollectionName)) {
                Write-Log "CollectionName is required for CountPoints operation" -Level "Error"
                return $null
            }
            
            $result = Get-QdrantPointsCount -CollectionName $CollectionName -Filter $Filter
        }
        "CreateFieldIndex" {
            if ([string]::IsNullOrEmpty($CollectionName) -or $null -eq $SearchParams -or [string]::IsNullOrEmpty($SearchParams.field_name) -or [string]::IsNullOrEmpty($SearchParams.field_type)) {
                Write-Log "CollectionName, field_name, and field_type are required for CreateFieldIndex operation" -Level "Error"
                return $null
            }
            
            $tokenizer = $null
            
            if ($null -ne $SearchParams.tokenizer) {
                $tokenizer = $SearchParams.tokenizer
            }
            
            $result = New-QdrantFieldIndex -CollectionName $CollectionName -FieldName $SearchParams.field_name -FieldType $SearchParams.field_type -Tokenizer $tokenizer
        }
        "DeleteFieldIndex" {
            if ([string]::IsNullOrEmpty($CollectionName) -or $null -eq $SearchParams -or [string]::IsNullOrEmpty($SearchParams.field_name)) {
                Write-Log "CollectionName and field_name are required for DeleteFieldIndex operation" -Level "Error"
                return $null
            }
            
            $result = Remove-QdrantFieldIndex -CollectionName $CollectionName -FieldName $SearchParams.field_name
        }
    }
    
    # Sauvegarder le résultat si un chemin de sortie est spécifié
    if (-not [string]::IsNullOrEmpty($OutputPath) -and $null -ne $result) {
        try {
            $result | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
            Write-Log "Result saved to: $OutputPath" -Level "Info"
        } catch {
            Write-Log "Error saving result: $_" -Level "Error"
        }
    }
    
    # Retourner le résultat selon le format demandé
    if ($AsObject) {
        return $result
    } else {
        return $result | ConvertTo-Json -Depth 10
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Invoke-QdrantOperation -Operation $Operation -CollectionName $CollectionName -PointId $PointId -Payload $Payload -Vector $Vector -Filter $Filter -SearchParams $SearchParams -OutputPath $OutputPath -AsObject:$AsObject
}
