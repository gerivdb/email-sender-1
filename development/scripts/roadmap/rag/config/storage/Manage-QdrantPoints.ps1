# Manage-QdrantPoints.ps1
# Script pour gérer les points dans Qdrant
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("Add", "Get", "Update", "Delete", "Search")]
    [string]$Action = "Get",
    
    [Parameter(Mandatory = $false)]
    [string]$QdrantUrl = "http://localhost:6333",
    
    [Parameter(Mandatory = $false)]
    [string]$ApiKey,
    
    [Parameter(Mandatory = $true)]
    [string]$CollectionName,
    
    [Parameter(Mandatory = $false)]
    [string]$PointId,
    
    [Parameter(Mandatory = $false)]
    [float[]]$Vector,
    
    [Parameter(Mandatory = $false)]
    [hashtable]$Payload,
    
    [Parameter(Mandatory = $false)]
    [float[]]$QueryVector,
    
    [Parameter(Mandatory = $false)]
    [int]$Limit = 10,
    
    [Parameter(Mandatory = $false)]
    [float]$Threshold = 0.7,
    
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

# Importer le script de connexion à Qdrant
$connectionScriptPath = Join-Path -Path $scriptPath -ChildPath "Connect-QdrantStorage.ps1"

if (Test-Path -Path $connectionScriptPath) {
    . $connectionScriptPath
} else {
    Write-Log "Qdrant connection script not found: $connectionScriptPath" -Level "Error"
    exit 1
}

# Fonction pour ajouter un point à Qdrant
function Add-QdrantPoint {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl,
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey,
        
        [Parameter(Mandatory = $true)]
        [string]$CollectionName,
        
        [Parameter(Mandatory = $true)]
        [string]$PointId,
        
        [Parameter(Mandatory = $true)]
        [float[]]$Vector,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Payload = @{}
    )
    
    $headers = @{
        "Content-Type" = "application/json"
    }
    
    if (-not [string]::IsNullOrEmpty($ApiKey)) {
        $headers["Api-Key"] = $ApiKey
    }
    
    $endpoint = "$QdrantUrl/collections/$CollectionName/points"
    
    # Préparer le corps de la requête
    $body = @{
        points = @(
            @{
                id = $PointId
                vector = $Vector
                payload = $Payload
            }
        )
    }
    
    try {
        $response = Invoke-RestMethod -Uri $endpoint -Method Put -Headers $headers -Body ($body | ConvertTo-Json -Depth 10)
        
        Write-Log "Point '$PointId' added to collection '$CollectionName'" -Level "Info"
        
        return @{
            Success = $true
            Message = "Point added successfully"
        }
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $errorMessage = $_.Exception.Message
        
        Write-Log "Failed to add point '$PointId': $errorMessage (Status code: $statusCode)" -Level "Error"
        
        return @{
            Success = $false
            StatusCode = $statusCode
            Message = $errorMessage
        }
    }
}

# Fonction pour obtenir un point de Qdrant
function Get-QdrantPoint {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl,
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey,
        
        [Parameter(Mandatory = $true)]
        [string]$CollectionName,
        
        [Parameter(Mandatory = $true)]
        [string]$PointId,
        
        [Parameter(Mandatory = $false)]
        [switch]$WithVector
    )
    
    $headers = @{
        "Content-Type" = "application/json"
    }
    
    if (-not [string]::IsNullOrEmpty($ApiKey)) {
        $headers["Api-Key"] = $ApiKey
    }
    
    $endpoint = "$QdrantUrl/collections/$CollectionName/points/$PointId"
    
    if ($WithVector) {
        $endpoint += "?with_vector=true"
    }
    
    try {
        $response = Invoke-RestMethod -Uri $endpoint -Method Get -Headers $headers
        
        Write-Log "Point '$PointId' retrieved from collection '$CollectionName'" -Level "Info"
        
        return @{
            Success = $true
            Point = $response.result
            Message = "Point retrieved successfully"
        }
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $errorMessage = $_.Exception.Message
        
        Write-Log "Failed to get point '$PointId': $errorMessage (Status code: $statusCode)" -Level "Error"
        
        return @{
            Success = $false
            StatusCode = $statusCode
            Message = $errorMessage
        }
    }
}

# Fonction pour mettre à jour un point dans Qdrant
function Update-QdrantPoint {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl,
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey,
        
        [Parameter(Mandatory = $true)]
        [string]$CollectionName,
        
        [Parameter(Mandatory = $true)]
        [string]$PointId,
        
        [Parameter(Mandatory = $false)]
        [float[]]$Vector,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Payload
    )
    
    $headers = @{
        "Content-Type" = "application/json"
    }
    
    if (-not [string]::IsNullOrEmpty($ApiKey)) {
        $headers["Api-Key"] = $ApiKey
    }
    
    $endpoint = "$QdrantUrl/collections/$CollectionName/points"
    
    # Préparer le corps de la requête
    $point = @{
        id = $PointId
    }
    
    if ($null -ne $Vector) {
        $point.vector = $Vector
    }
    
    if ($null -ne $Payload) {
        $point.payload = $Payload
    }
    
    $body = @{
        points = @(
            $point
        )
    }
    
    try {
        $response = Invoke-RestMethod -Uri $endpoint -Method Put -Headers $headers -Body ($body | ConvertTo-Json -Depth 10)
        
        Write-Log "Point '$PointId' updated in collection '$CollectionName'" -Level "Info"
        
        return @{
            Success = $true
            Message = "Point updated successfully"
        }
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $errorMessage = $_.Exception.Message
        
        Write-Log "Failed to update point '$PointId': $errorMessage (Status code: $statusCode)" -Level "Error"
        
        return @{
            Success = $false
            StatusCode = $statusCode
            Message = $errorMessage
        }
    }
}

# Fonction pour supprimer un point de Qdrant
function Remove-QdrantPoint {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl,
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey,
        
        [Parameter(Mandatory = $true)]
        [string]$CollectionName,
        
        [Parameter(Mandatory = $true)]
        [string]$PointId
    )
    
    $headers = @{
        "Content-Type" = "application/json"
    }
    
    if (-not [string]::IsNullOrEmpty($ApiKey)) {
        $headers["Api-Key"] = $ApiKey
    }
    
    $endpoint = "$QdrantUrl/collections/$CollectionName/points/delete"
    
    # Préparer le corps de la requête
    $body = @{
        points = @(
            $PointId
        )
    }
    
    try {
        $response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body ($body | ConvertTo-Json -Depth 10)
        
        Write-Log "Point '$PointId' deleted from collection '$CollectionName'" -Level "Info"
        
        return @{
            Success = $true
            Message = "Point deleted successfully"
        }
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $errorMessage = $_.Exception.Message
        
        Write-Log "Failed to delete point '$PointId': $errorMessage (Status code: $statusCode)" -Level "Error"
        
        return @{
            Success = $false
            StatusCode = $statusCode
            Message = $errorMessage
        }
    }
}

# Fonction pour rechercher des points similaires dans Qdrant
function Search-QdrantPoints {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl,
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey,
        
        [Parameter(Mandatory = $true)]
        [string]$CollectionName,
        
        [Parameter(Mandatory = $true)]
        [float[]]$QueryVector,
        
        [Parameter(Mandatory = $false)]
        [int]$Limit = 10,
        
        [Parameter(Mandatory = $false)]
        [float]$Threshold = 0.7,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Filter
    )
    
    $headers = @{
        "Content-Type" = "application/json"
    }
    
    if (-not [string]::IsNullOrEmpty($ApiKey)) {
        $headers["Api-Key"] = $ApiKey
    }
    
    $endpoint = "$QdrantUrl/collections/$CollectionName/points/search"
    
    # Préparer le corps de la requête
    $body = @{
        vector = $QueryVector
        limit = $Limit
        score_threshold = $Threshold
    }
    
    if ($null -ne $Filter -and $Filter.Count -gt 0) {
        $body.filter = $Filter
    }
    
    try {
        $response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body ($body | ConvertTo-Json -Depth 10)
        
        Write-Log "Search completed in collection '$CollectionName', found $($response.result.Count) results" -Level "Info"
        
        return @{
            Success = $true
            Results = $response.result
            Message = "Search completed successfully"
        }
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $errorMessage = $_.Exception.Message
        
        Write-Log "Failed to search in collection '$CollectionName': $errorMessage (Status code: $statusCode)" -Level "Error"
        
        return @{
            Success = $false
            StatusCode = $statusCode
            Message = $errorMessage
        }
    }
}

# Fonction principale
function Manage-QdrantPoints {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Add", "Get", "Update", "Delete", "Search")]
        [string]$Action = "Get",
        
        [Parameter(Mandatory = $false)]
        [string]$QdrantUrl = "http://localhost:6333",
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey,
        
        [Parameter(Mandatory = $true)]
        [string]$CollectionName,
        
        [Parameter(Mandatory = $false)]
        [string]$PointId,
        
        [Parameter(Mandatory = $false)]
        [float[]]$Vector,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Payload,
        
        [Parameter(Mandatory = $false)]
        [float[]]$QueryVector,
        
        [Parameter(Mandatory = $false)]
        [int]$Limit = 10,
        
        [Parameter(Mandatory = $false)]
        [float]$Threshold = 0.7
    )
    
    # Vérifier la connexion à Qdrant
    $connection = Connect-QdrantStorage -QdrantUrl $QdrantUrl -ApiKey $ApiKey -TestConnection
    
    if (-not $connection.Success) {
        return $connection
    }
    
    # Exécuter l'action demandée
    switch ($Action) {
        "Add" {
            if ([string]::IsNullOrEmpty($PointId) -or $null -eq $Vector) {
                Write-Log "PointId and Vector are required for Add action" -Level "Error"
                return @{
                    Success = $false
                    Message = "PointId and Vector are required for Add action"
                }
            }
            
            return Add-QdrantPoint -QdrantUrl $QdrantUrl -ApiKey $ApiKey -CollectionName $CollectionName -PointId $PointId -Vector $Vector -Payload $Payload
        }
        "Get" {
            if ([string]::IsNullOrEmpty($PointId)) {
                Write-Log "PointId is required for Get action" -Level "Error"
                return @{
                    Success = $false
                    Message = "PointId is required for Get action"
                }
            }
            
            return Get-QdrantPoint -QdrantUrl $QdrantUrl -ApiKey $ApiKey -CollectionName $CollectionName -PointId $PointId
        }
        "Update" {
            if ([string]::IsNullOrEmpty($PointId)) {
                Write-Log "PointId is required for Update action" -Level "Error"
                return @{
                    Success = $false
                    Message = "PointId is required for Update action"
                }
            }
            
            if ($null -eq $Vector -and $null -eq $Payload) {
                Write-Log "Either Vector or Payload must be provided for Update action" -Level "Error"
                return @{
                    Success = $false
                    Message = "Either Vector or Payload must be provided for Update action"
                }
            }
            
            return Update-QdrantPoint -QdrantUrl $QdrantUrl -ApiKey $ApiKey -CollectionName $CollectionName -PointId $PointId -Vector $Vector -Payload $Payload
        }
        "Delete" {
            if ([string]::IsNullOrEmpty($PointId)) {
                Write-Log "PointId is required for Delete action" -Level "Error"
                return @{
                    Success = $false
                    Message = "PointId is required for Delete action"
                }
            }
            
            return Remove-QdrantPoint -QdrantUrl $QdrantUrl -ApiKey $ApiKey -CollectionName $CollectionName -PointId $PointId
        }
        "Search" {
            if ($null -eq $QueryVector) {
                Write-Log "QueryVector is required for Search action" -Level "Error"
                return @{
                    Success = $false
                    Message = "QueryVector is required for Search action"
                }
            }
            
            return Search-QdrantPoints -QdrantUrl $QdrantUrl -ApiKey $ApiKey -CollectionName $CollectionName -QueryVector $QueryVector -Limit $Limit -Threshold $Threshold
        }
    }
}

# Exporter les fonctions pour qu'elles soient disponibles pour d'autres scripts
Export-ModuleMember -Function Manage-QdrantPoints, Add-QdrantPoint, Get-QdrantPoint, Update-QdrantPoint, Remove-QdrantPoint, Search-QdrantPoints

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Manage-QdrantPoints -Action $Action -QdrantUrl $QdrantUrl -ApiKey $ApiKey -CollectionName $CollectionName -PointId $PointId -Vector $Vector -Payload $Payload -QueryVector $QueryVector -Limit $Limit -Threshold $Threshold
}
