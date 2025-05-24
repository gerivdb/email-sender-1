# Connect-QdrantServer.ps1
# Script pour établir la connexion avec le serveur Qdrant
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ServerUrl = "http://localhost:6333",
    
    [Parameter(Mandatory = $false)]
    [string]$ApiKey = "",
    
    [Parameter(Mandatory = $false)]
    [int]$Timeout = 30,
    
    [Parameter(Mandatory = $false)]
    [int]$RetryCount = 3,
    
    [Parameter(Mandatory = $false)]
    [int]$RetryDelay = 2,
    
    [Parameter(Mandatory = $false)]
    [switch]$UseConnectionPool,
    
    [Parameter(Mandatory = $false)]
    [int]$PoolSize = 5,
    
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

# Variables globales pour la connexion
$script:QdrantConnection = $null
$script:ConnectionPool = @()

# Fonction pour créer les en-têtes de requête
function Get-QdrantHeaders {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ApiKey
    )
    
    $headers = @{
        "Content-Type" = "application/json"
    }
    
    if (-not [string]::IsNullOrEmpty($ApiKey)) {
        $headers["Api-Key"] = $ApiKey
    }
    
    return $headers
}

# Fonction pour tester la connexion au serveur Qdrant
function Test-QdrantConnection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ServerUrl,
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey,
        
        [Parameter(Mandatory = $false)]
        [int]$Timeout = 30
    )
    
    $headers = Get-QdrantHeaders -ApiKey $ApiKey
    
    try {
        $healthEndpoint = "$ServerUrl/health"
        
        $params = @{
            Uri = $healthEndpoint
            Method = "GET"
            Headers = $headers
            TimeoutSec = $Timeout
            UseBasicParsing = $true
        }
        
        $response = Invoke-RestMethod @params
        
        if ($response.status -eq "ok") {
            Write-Log "Successfully connected to Qdrant server at $ServerUrl" -Level "Info"
            return $true
        } else {
            Write-Log "Qdrant server at $ServerUrl is not healthy: $($response.status)" -Level "Warning"
            return $false
        }
    } catch {
        Write-Log "Failed to connect to Qdrant server at $ServerUrl: $_" -Level "Error"
        return $false
    }
}

# Fonction pour initialiser le pool de connexions
function Initialize-ConnectionPool {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ServerUrl,
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey,
        
        [Parameter(Mandatory = $false)]
        [int]$PoolSize = 5
    )
    
    $script:ConnectionPool = @()
    
    for ($i = 0; $i -lt $PoolSize; $i++) {
        $connection = @{
            ServerUrl = $ServerUrl
            ApiKey = $ApiKey
            Headers = Get-QdrantHeaders -ApiKey $ApiKey
            IsInUse = $false
            LastUsed = [DateTime]::MinValue
            Id = $i
        }
        
        $script:ConnectionPool += $connection
        Write-Log "Added connection #$i to the pool" -Level "Debug"
    }
    
    Write-Log "Initialized connection pool with $PoolSize connections" -Level "Info"
}

# Fonction pour obtenir une connexion du pool
function Get-ConnectionFromPool {
    [CmdletBinding()]
    param()
    
    # Rechercher une connexion disponible
    $availableConnection = $script:ConnectionPool | Where-Object { -not $_.IsInUse } | Sort-Object -Property LastUsed | Select-Object -First 1
    
    if ($null -ne $availableConnection) {
        $availableConnection.IsInUse = $true
        $availableConnection.LastUsed = Get-Date
        Write-Log "Using connection #$($availableConnection.Id) from pool" -Level "Debug"
        return $availableConnection
    }
    
    # Si toutes les connexions sont utilisées, attendre et réessayer
    Write-Log "All connections in pool are in use, waiting for one to become available" -Level "Warning"
    Start-Sleep -Seconds 1
    
    # Réessayer après un délai
    return Get-ConnectionFromPool
}

# Fonction pour libérer une connexion du pool
function Publish-ConnectionToPool {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Connection
    )
    
    $connection = $script:ConnectionPool | Where-Object { $_.Id -eq $Connection.Id }
    
    if ($null -ne $connection) {
        $connection.IsInUse = $false
        $connection.LastUsed = Get-Date
        Write-Log "Released connection #$($connection.Id) back to pool" -Level "Debug"
    }
}

# Fonction pour établir la connexion au serveur Qdrant
function Connect-QdrantServer {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ServerUrl = "http://localhost:6333",
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey = "",
        
        [Parameter(Mandatory = $false)]
        [int]$Timeout = 30,
        
        [Parameter(Mandatory = $false)]
        [int]$RetryCount = 3,
        
        [Parameter(Mandatory = $false)]
        [int]$RetryDelay = 2,
        
        [Parameter(Mandatory = $false)]
        [switch]$UseConnectionPool,
        
        [Parameter(Mandatory = $false)]
        [int]$PoolSize = 5,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Vérifier si une connexion existe déjà
    if ($null -ne $script:QdrantConnection -and -not $Force) {
        Write-Log "Qdrant connection already exists. Use -Force to reconnect." -Level "Warning"
        return $script:QdrantConnection
    }
    
    # Tester la connexion avec des tentatives
    $connected = $false
    $attempt = 0
    
    while (-not $connected -and $attempt -lt $RetryCount) {
        $attempt++
        Write-Log "Attempting to connect to Qdrant server (Attempt $attempt of $RetryCount)" -Level "Info"
        
        $connected = Test-QdrantConnection -ServerUrl $ServerUrl -ApiKey $ApiKey -Timeout $Timeout
        
        if (-not $connected -and $attempt -lt $RetryCount) {
            Write-Log "Retrying in $RetryDelay seconds..." -Level "Info"
            Start-Sleep -Seconds $RetryDelay
        }
    }
    
    if (-not $connected) {
        Write-Log "Failed to connect to Qdrant server after $RetryCount attempts" -Level "Error"
        return $null
    }
    
    # Créer l'objet de connexion
    $connection = @{
        ServerUrl = $ServerUrl
        ApiKey = $ApiKey
        Headers = Get-QdrantHeaders -ApiKey $ApiKey
        Connected = $true
        ConnectedAt = Get-Date
        Timeout = $Timeout
    }
    
    # Initialiser le pool de connexions si demandé
    if ($UseConnectionPool) {
        Initialize-ConnectionPool -ServerUrl $ServerUrl -ApiKey $ApiKey -PoolSize $PoolSize
        $connection.UseConnectionPool = $true
        $connection.PoolSize = $PoolSize
    } else {
        $connection.UseConnectionPool = $false
    }
    
    # Stocker la connexion globalement
    $script:QdrantConnection = $connection
    
    Write-Log "Successfully connected to Qdrant server at $ServerUrl" -Level "Info"
    
    return $connection
}

# Fonction pour obtenir la connexion actuelle
function Get-QdrantConnection {
    [CmdletBinding()]
    param()
    
    if ($null -eq $script:QdrantConnection) {
        Write-Log "No active Qdrant connection. Use Connect-QdrantServer first." -Level "Error"
        return $null
    }
    
    return $script:QdrantConnection
}

# Fonction pour fermer la connexion
function Disconnect-QdrantServer {
    [CmdletBinding()]
    param()
    
    if ($null -eq $script:QdrantConnection) {
        Write-Log "No active Qdrant connection to disconnect" -Level "Warning"
        return $true
    }
    
    # Nettoyer le pool de connexions si utilisé
    if ($script:QdrantConnection.UseConnectionPool) {
        $script:ConnectionPool = @()
        Write-Log "Connection pool cleared" -Level "Info"
    }
    
    # Réinitialiser la connexion
    $script:QdrantConnection = $null
    
    Write-Log "Disconnected from Qdrant server" -Level "Info"
    return $true
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Connect-QdrantServer -ServerUrl $ServerUrl -ApiKey $ApiKey -Timeout $Timeout -RetryCount $RetryCount -RetryDelay $RetryDelay -UseConnectionPool:$UseConnectionPool -PoolSize $PoolSize -Force:$Force
}

