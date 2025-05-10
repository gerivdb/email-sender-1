# Connect-QdrantStorage.ps1
# Script pour gérer la connexion au stockage Qdrant
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$QdrantUrl = "http://localhost:6333",
    
    [Parameter(Mandatory = $false)]
    [string]$ApiKey,
    
    [Parameter(Mandatory = $false)]
    [switch]$TestConnection,
    
    [Parameter(Mandatory = $false)]
    [switch]$SaveConnection,
    
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

# Fonction pour obtenir le chemin du fichier de configuration de connexion
function Get-ConnectionConfigPath {
    [CmdletBinding()]
    param()
    
    $configDir = Join-Path -Path $rootPath -ChildPath "config"
    
    if (-not (Test-Path -Path $configDir)) {
        New-Item -Path $configDir -ItemType Directory -Force | Out-Null
    }
    
    $configPath = Join-Path -Path $configDir -ChildPath "qdrant_connection.json"
    
    return $configPath
}

# Fonction pour charger la configuration de connexion
function Get-ConnectionConfig {
    [CmdletBinding()]
    param()
    
    $configPath = Get-ConnectionConfigPath
    
    if (Test-Path -Path $configPath) {
        try {
            $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
            return $config
        } catch {
            Write-Log "Error loading connection configuration: $_" -Level "Error"
            return $null
        }
    }
    
    return $null
}

# Fonction pour sauvegarder la configuration de connexion
function Save-ConnectionConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl,
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey
    )
    
    $configPath = Get-ConnectionConfigPath
    
    $config = @{
        url = $QdrantUrl
        api_key = $ApiKey
        last_updated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    try {
        $config | ConvertTo-Json | Out-File -FilePath $configPath -Encoding UTF8
        Write-Log "Connection configuration saved to: $configPath" -Level "Info"
        return $true
    } catch {
        Write-Log "Error saving connection configuration: $_" -Level "Error"
        return $false
    }
}

# Fonction pour tester la connexion à Qdrant
function Test-QdrantConnection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl,
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey
    )
    
    $headers = @{
        "Content-Type" = "application/json"
    }
    
    if (-not [string]::IsNullOrEmpty($ApiKey)) {
        $headers["Api-Key"] = $ApiKey
    }
    
    $endpoint = "$QdrantUrl/collections"
    
    try {
        $response = Invoke-RestMethod -Uri $endpoint -Method Get -Headers $headers
        
        Write-Log "Successfully connected to Qdrant at: $QdrantUrl" -Level "Info"
        Write-Log "Available collections: $($response.result.collections.Count)" -Level "Info"
        
        return @{
            Success = $true
            Collections = $response.result.collections
            Message = "Connection successful"
        }
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $errorMessage = $_.Exception.Message
        
        Write-Log "Failed to connect to Qdrant: $errorMessage (Status code: $statusCode)" -Level "Error"
        
        return @{
            Success = $false
            StatusCode = $statusCode
            Message = $errorMessage
        }
    }
}

# Fonction pour créer une collection dans Qdrant
function New-QdrantCollection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl,
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey,
        
        [Parameter(Mandatory = $true)]
        [string]$CollectionName,
        
        [Parameter(Mandatory = $true)]
        [int]$VectorSize,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Cosine", "Euclid", "Dot")]
        [string]$Distance = "Cosine",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Metadata = @{}
    )
    
    $headers = @{
        "Content-Type" = "application/json"
    }
    
    if (-not [string]::IsNullOrEmpty($ApiKey)) {
        $headers["Api-Key"] = $ApiKey
    }
    
    $endpoint = "$QdrantUrl/collections/$CollectionName"
    
    # Vérifier si la collection existe déjà
    try {
        $response = Invoke-RestMethod -Uri $endpoint -Method Get -Headers $headers
        Write-Log "Collection '$CollectionName' already exists" -Level "Warning"
        return @{
            Success = $true
            Exists = $true
            Message = "Collection already exists"
        }
    } catch {
        # La collection n'existe pas, on peut la créer
    }
    
    # Préparer le corps de la requête
    $body = @{
        vectors = @{
            size = $VectorSize
            distance = $Distance.ToLower()
        }
    }
    
    # Ajouter les métadonnées si fournies
    if ($Metadata.Count -gt 0) {
        $body.metadata = $Metadata
    }
    
    # Créer la collection
    try {
        $response = Invoke-RestMethod -Uri $endpoint -Method Put -Headers $headers -Body ($body | ConvertTo-Json -Depth 10)
        
        Write-Log "Collection '$CollectionName' created successfully" -Level "Info"
        
        return @{
            Success = $true
            Exists = $false
            Message = "Collection created successfully"
        }
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $errorMessage = $_.Exception.Message
        
        Write-Log "Failed to create collection '$CollectionName': $errorMessage (Status code: $statusCode)" -Level "Error"
        
        return @{
            Success = $false
            StatusCode = $statusCode
            Message = $errorMessage
        }
    }
}

# Fonction pour obtenir les informations sur une collection
function Get-QdrantCollection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl,
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey,
        
        [Parameter(Mandatory = $true)]
        [string]$CollectionName
    )
    
    $headers = @{
        "Content-Type" = "application/json"
    }
    
    if (-not [string]::IsNullOrEmpty($ApiKey)) {
        $headers["Api-Key"] = $ApiKey
    }
    
    $endpoint = "$QdrantUrl/collections/$CollectionName"
    
    try {
        $response = Invoke-RestMethod -Uri $endpoint -Method Get -Headers $headers
        
        Write-Log "Collection '$CollectionName' information retrieved successfully" -Level "Info"
        
        return @{
            Success = $true
            Collection = $response.result
            Message = "Collection information retrieved successfully"
        }
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $errorMessage = $_.Exception.Message
        
        Write-Log "Failed to get collection '$CollectionName': $errorMessage (Status code: $statusCode)" -Level "Error"
        
        return @{
            Success = $false
            StatusCode = $statusCode
            Message = $errorMessage
        }
    }
}

# Fonction pour lister toutes les collections
function Get-QdrantCollections {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl,
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey
    )
    
    $headers = @{
        "Content-Type" = "application/json"
    }
    
    if (-not [string]::IsNullOrEmpty($ApiKey)) {
        $headers["Api-Key"] = $ApiKey
    }
    
    $endpoint = "$QdrantUrl/collections"
    
    try {
        $response = Invoke-RestMethod -Uri $endpoint -Method Get -Headers $headers
        
        Write-Log "Retrieved $($response.result.collections.Count) collections" -Level "Info"
        
        return @{
            Success = $true
            Collections = $response.result.collections
            Message = "Collections retrieved successfully"
        }
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $errorMessage = $_.Exception.Message
        
        Write-Log "Failed to list collections: $errorMessage (Status code: $statusCode)" -Level "Error"
        
        return @{
            Success = $false
            StatusCode = $statusCode
            Message = $errorMessage
        }
    }
}

# Fonction pour supprimer une collection
function Remove-QdrantCollection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl,
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey,
        
        [Parameter(Mandatory = $true)]
        [string]$CollectionName
    )
    
    $headers = @{
        "Content-Type" = "application/json"
    }
    
    if (-not [string]::IsNullOrEmpty($ApiKey)) {
        $headers["Api-Key"] = $ApiKey
    }
    
    $endpoint = "$QdrantUrl/collections/$CollectionName"
    
    try {
        $response = Invoke-RestMethod -Uri $endpoint -Method Delete -Headers $headers
        
        Write-Log "Collection '$CollectionName' deleted successfully" -Level "Info"
        
        return @{
            Success = $true
            Message = "Collection deleted successfully"
        }
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $errorMessage = $_.Exception.Message
        
        Write-Log "Failed to delete collection '$CollectionName': $errorMessage (Status code: $statusCode)" -Level "Error"
        
        return @{
            Success = $false
            StatusCode = $statusCode
            Message = $errorMessage
        }
    }
}

# Fonction principale
function Connect-QdrantStorage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$QdrantUrl = "http://localhost:6333",
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey,
        
        [Parameter(Mandatory = $false)]
        [switch]$TestConnection,
        
        [Parameter(Mandatory = $false)]
        [switch]$SaveConnection
    )
    
    # Si aucun URL n'est fourni, essayer de charger la configuration
    if ([string]::IsNullOrEmpty($QdrantUrl)) {
        $config = Get-ConnectionConfig
        
        if ($null -ne $config) {
            $QdrantUrl = $config.url
            
            if ([string]::IsNullOrEmpty($ApiKey) -and -not [string]::IsNullOrEmpty($config.api_key)) {
                $ApiKey = $config.api_key
            }
            
            Write-Log "Loaded connection configuration: $QdrantUrl" -Level "Info"
        } else {
            $QdrantUrl = "http://localhost:6333"
            Write-Log "No connection configuration found, using default URL: $QdrantUrl" -Level "Warning"
        }
    }
    
    # Tester la connexion si demandé
    if ($TestConnection) {
        $testResult = Test-QdrantConnection -QdrantUrl $QdrantUrl -ApiKey $ApiKey
        
        if (-not $testResult.Success) {
            return $testResult
        }
    }
    
    # Sauvegarder la configuration si demandé
    if ($SaveConnection) {
        $saveResult = Save-ConnectionConfig -QdrantUrl $QdrantUrl -ApiKey $ApiKey
        
        if (-not $saveResult) {
            Write-Log "Failed to save connection configuration" -Level "Warning"
        }
    }
    
    # Retourner les informations de connexion
    return @{
        Success = $true
        QdrantUrl = $QdrantUrl
        ApiKey = $ApiKey
        Message = "Qdrant connection configured successfully"
    }
}

# Exporter les fonctions pour qu'elles soient disponibles pour d'autres scripts
Export-ModuleMember -Function Connect-QdrantStorage, Test-QdrantConnection, New-QdrantCollection, Get-QdrantCollection, Get-QdrantCollections, Remove-QdrantCollection

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Connect-QdrantStorage -QdrantUrl $QdrantUrl -ApiKey $ApiKey -TestConnection:$TestConnection -SaveConnection:$SaveConnection
}
