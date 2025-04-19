#Requires -Version 5.1
<#
.SYNOPSIS
    Module PowerShell pour interagir avec un serveur MCP (Model Context Protocol).
.DESCRIPTION
    Ce module fournit des fonctions pour se connecter à un serveur MCP, récupérer la liste
    des outils disponibles et exécuter des outils via le protocole MCP.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-20
#>

# Variables globales
$script:MCPConfig = @{
    ServerUrl             = $null
    Timeout               = 30
    RetryCount            = 3
    RetryDelay            = 2
    DefaultHeaders        = @{
        "Content-Type" = "application/json"
        "Accept"       = "application/json"
    }
    LogEnabled            = $true
    LogLevel              = "INFO" # DEBUG, INFO, WARNING, ERROR
    LogPath               = Join-Path -Path $env:TEMP -ChildPath "MCPClient.log"

    # Options de performance
    CacheEnabled          = $true
    CacheTTL              = 300 # Durée de vie du cache en secondes (5 minutes)
    MaxConcurrentRequests = 5 # Nombre maximum de requêtes simultanées
    BatchSize             = 10 # Taille des lots pour le traitement par lots
    CompressionEnabled    = $true # Activer la compression des données
}

# Cache pour les résultats des outils
$script:MCPCache = @{}

# Horodatage du dernier nettoyage du cache
$script:LastCacheCleanup = Get-Date

# Fonction pour écrire des logs
function Write-MCPLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("DEBUG", "INFO", "WARNING", "ERROR")]
        [string]$Level = "INFO"
    )

    if (-not $script:MCPConfig.LogEnabled) {
        return
    }

    # Vérifier le niveau de log
    $logLevels = @{
        "DEBUG"   = 0
        "INFO"    = 1
        "WARNING" = 2
        "ERROR"   = 3
    }

    if ($logLevels[$Level] -lt $logLevels[$script:MCPConfig.LogLevel]) {
        return
    }

    # Formater le message de log
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    # Écrire dans la console avec la couleur appropriée
    switch ($Level) {
        "DEBUG" { Write-Verbose $logMessage }
        "INFO" { Write-Host $logMessage -ForegroundColor Cyan }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
    }

    # Écrire dans le fichier de log
    try {
        Add-Content -Path $script:MCPConfig.LogPath -Value $logMessage -ErrorAction SilentlyContinue
    } catch {
        # Ignorer les erreurs d'écriture dans le fichier de log
    }
}

<#
.SYNOPSIS
    Initialise la connexion à un serveur MCP.
.DESCRIPTION
    Cette fonction initialise la connexion à un serveur MCP en définissant l'URL du serveur
    et d'autres paramètres de configuration.
.PARAMETER ServerUrl
    L'URL du serveur MCP.
.PARAMETER Timeout
    Le délai d'attente en secondes pour les requêtes HTTP.
.PARAMETER RetryCount
    Le nombre de tentatives en cas d'échec.
.PARAMETER RetryDelay
    Le délai en secondes entre les tentatives.
.PARAMETER LogEnabled
    Indique si la journalisation est activée.
.PARAMETER LogLevel
    Le niveau de journalisation (DEBUG, INFO, WARNING, ERROR).
.PARAMETER LogPath
    Le chemin du fichier de log.
.EXAMPLE
    Initialize-MCPConnection -ServerUrl "http://localhost:8000"
    Initialise la connexion au serveur MCP local sur le port 8000.
.EXAMPLE
    Initialize-MCPConnection -ServerUrl "http://localhost:8000" -Timeout 60 -RetryCount 5
    Initialise la connexion avec un délai d'attente de 60 secondes et 5 tentatives en cas d'échec.
#>
function Initialize-MCPConnection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ServerUrl,

        [Parameter(Mandatory = $false)]
        [int]$Timeout = 30,

        [Parameter(Mandatory = $false)]
        [int]$RetryCount = 3,

        [Parameter(Mandatory = $false)]
        [int]$RetryDelay = 2,

        [Parameter(Mandatory = $false)]
        [bool]$LogEnabled = $true,

        [Parameter(Mandatory = $false)]
        [ValidateSet("DEBUG", "INFO", "WARNING", "ERROR")]
        [string]$LogLevel = "INFO",

        [Parameter(Mandatory = $false)]
        [string]$LogPath = (Join-Path -Path $env:TEMP -ChildPath "MCPClient.log")
    )

    # Mettre à jour la configuration
    $script:MCPConfig.ServerUrl = $ServerUrl
    $script:MCPConfig.Timeout = $Timeout
    $script:MCPConfig.RetryCount = $RetryCount
    $script:MCPConfig.RetryDelay = $RetryDelay
    $script:MCPConfig.LogEnabled = $LogEnabled
    $script:MCPConfig.LogLevel = $LogLevel
    $script:MCPConfig.LogPath = $LogPath

    # Vérifier la connexion au serveur
    try {
        $healthEndpoint = "$ServerUrl/health"
        $response = Invoke-RestMethod -Uri $healthEndpoint -Method Get -TimeoutSec $Timeout -ErrorAction Stop

        Write-MCPLog "Connexion établie avec le serveur MCP à l'adresse $ServerUrl" -Level "INFO"
        Write-MCPLog "Version du serveur: $($response.version)" -Level "INFO"
        Write-MCPLog "Statut du serveur: $($response.status)" -Level "INFO"

        return $true
    } catch {
        Write-MCPLog "Erreur lors de la connexion au serveur MCP à l'adresse $ServerUrl : $_" -Level "ERROR"
        Write-MCPLog "Vérifiez que le serveur MCP est en cours d'exécution et accessible." -Level "WARNING"

        return $false
    }
}

<#
.SYNOPSIS
    Récupère la liste des outils disponibles sur le serveur MCP.
.DESCRIPTION
    Cette fonction récupère la liste des outils disponibles sur le serveur MCP.
.EXAMPLE
    Get-MCPTools
    Récupère la liste des outils disponibles sur le serveur MCP.
#>
function Get-MCPTools {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$NoCache,

        [Parameter(Mandatory = $false)]
        [switch]$ForceRefresh
    )

    # Vérifier que la connexion est initialisée
    if (-not $script:MCPConfig.ServerUrl) {
        Write-MCPLog "La connexion au serveur MCP n'est pas initialisée. Utilisez Initialize-MCPConnection." -Level "ERROR"
        return $null
    }

    # Nettoyer le cache si nécessaire (toutes les 5 minutes)
    $now = Get-Date
    if (($now - $script:LastCacheCleanup).TotalMinutes -ge 5) {
        Clear-MCPCache
    }

    # Clé de cache pour la liste des outils
    $cacheKey = "tools-list"

    # Vérifier si la liste des outils est en cache et si le cache est activé
    if ($script:MCPConfig.CacheEnabled -and -not $NoCache -and -not $ForceRefresh) {
        if ($script:MCPCache.ContainsKey($cacheKey)) {
            $cacheEntry = $script:MCPCache[$cacheKey]
            $expirationTime = $cacheEntry.Timestamp.AddSeconds($script:MCPConfig.CacheTTL)

            # Si l'entrée du cache est encore valide, la retourner
            if ($now -lt $expirationTime) {
                Write-MCPLog "Liste des outils récupérée du cache" -Level "DEBUG"
                return $cacheEntry.Result
            }
        }
    }

    # Récupérer la liste des outils
    try {
        $toolsEndpoint = "$($script:MCPConfig.ServerUrl)/tools"
        $response = Invoke-RestMethod -Uri $toolsEndpoint -Method Get -TimeoutSec $script:MCPConfig.Timeout -ErrorAction Stop

        Write-MCPLog "Liste des outils récupérée avec succès" -Level "INFO"
        Write-MCPLog "Nombre d'outils disponibles: $($response.tools.Count)" -Level "DEBUG"

        # Mettre en cache la liste des outils si le cache est activé
        if ($script:MCPConfig.CacheEnabled -and -not $NoCache) {
            $script:MCPCache[$cacheKey] = @{
                Result    = $response.tools
                Timestamp = $now
            }
            Write-MCPLog "Liste des outils mise en cache" -Level "DEBUG"
        }

        return $response.tools
    } catch {
        Write-MCPLog "Erreur lors de la récupération de la liste des outils : $_" -Level "ERROR"

        # Tentatives de reconnexion
        for ($i = 1; $i -le $script:MCPConfig.RetryCount; $i++) {
            Write-MCPLog "Tentative de reconnexion ($i/$($script:MCPConfig.RetryCount))..." -Level "WARNING"
            Start-Sleep -Seconds $script:MCPConfig.RetryDelay

            try {
                $toolsEndpoint = "$($script:MCPConfig.ServerUrl)/tools"
                $response = Invoke-RestMethod -Uri $toolsEndpoint -Method Get -TimeoutSec $script:MCPConfig.Timeout -ErrorAction Stop

                Write-MCPLog "Liste des outils récupérée avec succès après $i tentatives" -Level "INFO"
                Write-MCPLog "Nombre d'outils disponibles: $($response.tools.Count)" -Level "DEBUG"

                # Mettre en cache la liste des outils si le cache est activé
                if ($script:MCPConfig.CacheEnabled -and -not $NoCache) {
                    $script:MCPCache[$cacheKey] = @{
                        Result    = $response.tools
                        Timestamp = $now
                    }
                    Write-MCPLog "Liste des outils mise en cache" -Level "DEBUG"
                }

                return $response.tools
            } catch {
                Write-MCPLog "Échec de la tentative $i : $_" -Level "DEBUG"
            }
        }

        Write-MCPLog "Échec de la récupération de la liste des outils après $($script:MCPConfig.RetryCount) tentatives" -Level "ERROR"
        return $null
    }
}

<#
.SYNOPSIS
    Exécute un outil sur le serveur MCP.
.DESCRIPTION
    Cette fonction exécute un outil sur le serveur MCP avec les paramètres spécifiés.
.PARAMETER ToolName
    Le nom de l'outil à exécuter.
.PARAMETER Parameters
    Les paramètres à passer à l'outil.
.EXAMPLE
    Invoke-MCPTool -ToolName "add" -Parameters @{ a = 2; b = 3 }
    Exécute l'outil "add" avec les paramètres a=2 et b=3.
#>
function Invoke-MCPTool {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ToolName,

        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{},

        [Parameter(Mandatory = $false)]
        [switch]$NoCache,

        [Parameter(Mandatory = $false)]
        [switch]$ForceRefresh
    )

    # Vérifier que la connexion est initialisée
    if (-not $script:MCPConfig.ServerUrl) {
        Write-MCPLog "La connexion au serveur MCP n'est pas initialisée. Utilisez Initialize-MCPConnection." -Level "ERROR"
        return $null
    }

    # Nettoyer le cache si nécessaire (toutes les 5 minutes)
    $now = Get-Date
    if (($now - $script:LastCacheCleanup).TotalMinutes -ge 5) {
        Clear-MCPCache
    }

    # Générer une clé de cache unique basée sur l'outil et les paramètres
    $cacheKey = "$ToolName-" + ($Parameters | ConvertTo-Json -Depth 10 -Compress)

    # Vérifier si l'outil est en cache et si le cache est activé
    if ($script:MCPConfig.CacheEnabled -and -not $NoCache -and -not $ForceRefresh) {
        if ($script:MCPCache.ContainsKey($cacheKey)) {
            $cacheEntry = $script:MCPCache[$cacheKey]
            $expirationTime = $cacheEntry.Timestamp.AddSeconds($script:MCPConfig.CacheTTL)

            # Si l'entrée du cache est encore valide, la retourner
            if ($now -lt $expirationTime) {
                Write-MCPLog "Résultat récupéré du cache pour l'outil '$ToolName'" -Level "DEBUG"
                return $cacheEntry.Result
            }
        }
    }

    # Exécuter l'outil
    try {
        $toolEndpoint = "$($script:MCPConfig.ServerUrl)/tools/$ToolName"

        # Convertir les paramètres en JSON
        $body = $Parameters | ConvertTo-Json -Depth 10

        # Compresser le corps si nécessaire
        if ($script:MCPConfig.CompressionEnabled -and $body.Length -gt 1024) {
            $compressedBody = Compress-MCPData -Data $body
            $headers = @{
                "Content-Encoding" = "gzip"
                "Content-Type"     = "application/json"
            }
            Write-MCPLog "Corps compressé pour l'outil '$ToolName'" -Level "DEBUG"
        } else {
            $compressedBody = $body
            $headers = @{
                "Content-Type" = "application/json"
            }
        }

        Write-MCPLog "Exécution de l'outil '$ToolName' avec les paramètres: $body" -Level "DEBUG"

        $response = Invoke-RestMethod -Uri $toolEndpoint -Method Post -Body $compressedBody -Headers $headers -TimeoutSec $script:MCPConfig.Timeout -ErrorAction Stop

        Write-MCPLog "Outil '$ToolName' exécuté avec succès" -Level "INFO"

        # Mettre en cache le résultat si le cache est activé
        if ($script:MCPConfig.CacheEnabled -and -not $NoCache) {
            $script:MCPCache[$cacheKey] = @{
                Result    = $response
                Timestamp = $now
            }
            Write-MCPLog "Résultat mis en cache pour l'outil '$ToolName'" -Level "DEBUG"
        }

        return $response
    } catch {
        Write-MCPLog "Erreur lors de l'exécution de l'outil '$ToolName' : $_" -Level "ERROR"

        # Tentatives de reconnexion
        for ($i = 1; $i -le $script:MCPConfig.RetryCount; $i++) {
            Write-MCPLog "Tentative de reconnexion ($i/$($script:MCPConfig.RetryCount))..." -Level "WARNING"
            Start-Sleep -Seconds $script:MCPConfig.RetryDelay

            try {
                $toolEndpoint = "$($script:MCPConfig.ServerUrl)/tools/$ToolName"
                $body = $Parameters | ConvertTo-Json -Depth 10

                # Compresser le corps si nécessaire
                if ($script:MCPConfig.CompressionEnabled -and $body.Length -gt 1024) {
                    $compressedBody = Compress-MCPData -Data $body
                    $headers = @{
                        "Content-Encoding" = "gzip"
                        "Content-Type"     = "application/json"
                    }
                } else {
                    $compressedBody = $body
                    $headers = @{
                        "Content-Type" = "application/json"
                    }
                }

                $response = Invoke-RestMethod -Uri $toolEndpoint -Method Post -Body $compressedBody -Headers $headers -TimeoutSec $script:MCPConfig.Timeout -ErrorAction Stop

                Write-MCPLog "Outil '$ToolName' exécuté avec succès après $i tentatives" -Level "INFO"

                # Mettre en cache le résultat si le cache est activé
                if ($script:MCPConfig.CacheEnabled -and -not $NoCache) {
                    $script:MCPCache[$cacheKey] = @{
                        Result    = $response
                        Timestamp = $now
                    }
                    Write-MCPLog "Résultat mis en cache pour l'outil '$ToolName'" -Level "DEBUG"
                }

                return $response
            } catch {
                Write-MCPLog "Échec de la tentative $i : $_" -Level "DEBUG"
            }
        }

        Write-MCPLog "Échec de l'exécution de l'outil '$ToolName' après $($script:MCPConfig.RetryCount) tentatives" -Level "ERROR"
        return $null
    }
}

<#
.SYNOPSIS
    Exécute une commande PowerShell via le serveur MCP.
.DESCRIPTION
    Cette fonction exécute une commande PowerShell via le serveur MCP.
.PARAMETER Command
    La commande PowerShell à exécuter.
.EXAMPLE
    Invoke-MCPPowerShell -Command "Get-Process"
    Exécute la commande "Get-Process" via le serveur MCP.
#>
function Invoke-MCPPowerShell {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Command
    )

    return Invoke-MCPTool -ToolName "run_powershell_command" -Parameters @{
        command = $Command
    }
}

<#
.SYNOPSIS
    Récupère des informations sur le système via le serveur MCP.
.DESCRIPTION
    Cette fonction récupère des informations sur le système via le serveur MCP.
.EXAMPLE
    Get-MCPSystemInfo
    Récupère des informations sur le système via le serveur MCP.
#>
function Get-MCPSystemInfo {
    [CmdletBinding()]
    param ()

    return Invoke-MCPTool -ToolName "get_system_info" -Parameters @{}
}

<#
.SYNOPSIS
    Détecte les serveurs MCP disponibles.
.DESCRIPTION
    Cette fonction détecte les serveurs MCP disponibles sur le réseau local.
.PARAMETER Scan
    Indique si un scan complet du réseau doit être effectué.
.EXAMPLE
    Find-MCPServers
    Détecte les serveurs MCP disponibles.
.EXAMPLE
    Find-MCPServers -Scan
    Effectue un scan complet du réseau pour détecter les serveurs MCP.
#>
function Find-MCPServers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$Scan
    )

    return Invoke-MCPTool -ToolName "find_mcp_servers" -Parameters @{
        scan = $Scan.IsPresent
    }
}

<#
.SYNOPSIS
    Exécute un script Python via le serveur MCP.
.DESCRIPTION
    Cette fonction exécute un script Python via le serveur MCP.
.PARAMETER Script
    Le script Python à exécuter.
.PARAMETER Arguments
    Les arguments à passer au script Python.
.EXAMPLE
    Invoke-MCPPython -Script "print('Hello, World!')"
    Exécute le script Python "print('Hello, World!')" via le serveur MCP.
.EXAMPLE
    Invoke-MCPPython -Script "import sys; print(sys.argv[1])" -Arguments @("Hello")
    Exécute le script Python avec l'argument "Hello".
#>
function Invoke-MCPPython {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Script,

        [Parameter(Mandatory = $false)]
        [string[]]$Arguments = @()
    )

    return Invoke-MCPTool -ToolName "run_python_script" -Parameters @{
        script    = $Script
        arguments = $Arguments
    }
}

<#
.SYNOPSIS
    Exécute une requête HTTP via le serveur MCP.
.DESCRIPTION
    Cette fonction exécute une requête HTTP via le serveur MCP.
.PARAMETER Url
    L'URL de la requête.
.PARAMETER Method
    La méthode HTTP (GET, POST, PUT, DELETE).
.PARAMETER Headers
    Les en-têtes HTTP.
.PARAMETER Body
    Le corps de la requête.
.EXAMPLE
    Invoke-MCPHttpRequest -Url "https://api.example.com/data" -Method "GET"
    Exécute une requête GET vers "https://api.example.com/data" via le serveur MCP.
.EXAMPLE
    Invoke-MCPHttpRequest -Url "https://api.example.com/data" -Method "POST" -Body @{ name = "John" }
    Exécute une requête POST vers "https://api.example.com/data" avec un corps JSON via le serveur MCP.
#>
function Invoke-MCPHttpRequest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Url,

        [Parameter(Mandatory = $false)]
        [ValidateSet("GET", "POST", "PUT", "DELETE")]
        [string]$Method = "GET",

        [Parameter(Mandatory = $false)]
        [hashtable]$Headers = @{},

        [Parameter(Mandatory = $false)]
        [object]$Body = $null
    )

    $parameters = @{
        url     = $Url
        method  = $Method
        headers = $Headers
    }

    if ($Body) {
        $parameters.body = $Body
    }

    return Invoke-MCPTool -ToolName "http_request" -Parameters $parameters
}

<#
.SYNOPSIS
    Configure le module MCPClient.
.DESCRIPTION
    Cette fonction configure le module MCPClient.
.PARAMETER Timeout
    Le délai d'attente en secondes pour les requêtes HTTP.
.PARAMETER RetryCount
    Le nombre de tentatives en cas d'échec.
.PARAMETER RetryDelay
    Le délai en secondes entre les tentatives.
.PARAMETER LogEnabled
    Indique si la journalisation est activée.
.PARAMETER LogLevel
    Le niveau de journalisation (DEBUG, INFO, WARNING, ERROR).
.PARAMETER LogPath
    Le chemin du fichier de log.
.EXAMPLE
    Set-MCPClientConfiguration -Timeout 60 -RetryCount 5
    Configure le module MCPClient avec un délai d'attente de 60 secondes et 5 tentatives en cas d'échec.
#>
function Set-MCPClientConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$Timeout,

        [Parameter(Mandatory = $false)]
        [int]$RetryCount,

        [Parameter(Mandatory = $false)]
        [int]$RetryDelay,

        [Parameter(Mandatory = $false)]
        [bool]$LogEnabled,

        [Parameter(Mandatory = $false)]
        [ValidateSet("DEBUG", "INFO", "WARNING", "ERROR")]
        [string]$LogLevel,

        [Parameter(Mandatory = $false)]
        [string]$LogPath
    )

    # Mettre à jour la configuration
    if ($PSBoundParameters.ContainsKey('Timeout')) {
        $script:MCPConfig.Timeout = $Timeout
    }

    if ($PSBoundParameters.ContainsKey('RetryCount')) {
        $script:MCPConfig.RetryCount = $RetryCount
    }

    if ($PSBoundParameters.ContainsKey('RetryDelay')) {
        $script:MCPConfig.RetryDelay = $RetryDelay
    }

    if ($PSBoundParameters.ContainsKey('LogEnabled')) {
        $script:MCPConfig.LogEnabled = $LogEnabled
    }

    if ($PSBoundParameters.ContainsKey('LogLevel')) {
        $script:MCPConfig.LogLevel = $LogLevel
    }

    if ($PSBoundParameters.ContainsKey('LogPath')) {
        $script:MCPConfig.LogPath = $LogPath
    }

    Write-MCPLog "Configuration du module MCPClient mise à jour" -Level "INFO"
    Write-MCPLog "Timeout: $($script:MCPConfig.Timeout)" -Level "DEBUG"
    Write-MCPLog "RetryCount: $($script:MCPConfig.RetryCount)" -Level "DEBUG"
    Write-MCPLog "RetryDelay: $($script:MCPConfig.RetryDelay)" -Level "DEBUG"
    Write-MCPLog "LogEnabled: $($script:MCPConfig.LogEnabled)" -Level "DEBUG"
    Write-MCPLog "LogLevel: $($script:MCPConfig.LogLevel)" -Level "DEBUG"
    Write-MCPLog "LogPath: $($script:MCPConfig.LogPath)" -Level "DEBUG"

    return $true
}

<#
.SYNOPSIS
    Récupère la configuration actuelle du module MCPClient.
.DESCRIPTION
    Cette fonction récupère la configuration actuelle du module MCPClient.
.EXAMPLE
    Get-MCPClientConfiguration
    Récupère la configuration actuelle du module MCPClient.
#>
function Get-MCPClientConfiguration {
    [CmdletBinding()]
    param ()

    return $script:MCPConfig
}

# Fonction pour nettoyer le cache
function Clear-MCPCache {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # Si Force est spécifié, vider complètement le cache
    if ($Force) {
        $script:MCPCache = @{}
        $script:LastCacheCleanup = Get-Date
        Write-MCPLog "Cache vidé complètement" -Level "INFO"
        return $true
    }

    # Sinon, supprimer uniquement les entrées expirées
    $now = Get-Date
    $keysToRemove = @()

    foreach ($key in $script:MCPCache.Keys) {
        $cacheEntry = $script:MCPCache[$key]
        $expirationTime = $cacheEntry.Timestamp.AddSeconds($script:MCPConfig.CacheTTL)

        if ($now -gt $expirationTime) {
            $keysToRemove += $key
        }
    }

    foreach ($key in $keysToRemove) {
        $script:MCPCache.Remove($key)
    }

    $script:LastCacheCleanup = $now
    Write-MCPLog "$($keysToRemove.Count) entrées supprimées du cache" -Level "DEBUG"

    return $true
}

# Fonction pour compresser les données
function Compress-MCPData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Data
    )

    if (-not $script:MCPConfig.CompressionEnabled) {
        return $Data
    }

    try {
        $dataBytes = [System.Text.Encoding]::UTF8.GetBytes($Data)
        $outputStream = New-Object System.IO.MemoryStream
        $gzipStream = New-Object System.IO.Compression.GZipStream($outputStream, [System.IO.Compression.CompressionMode]::Compress)
        $gzipStream.Write($dataBytes, 0, $dataBytes.Length)
        $gzipStream.Close()
        $outputStream.Close()
        $compressedBytes = $outputStream.ToArray()
        $compressedData = [Convert]::ToBase64String($compressedBytes)

        Write-MCPLog "Données compressées : ${$dataBytes.Length} octets -> ${$compressedBytes.Length} octets" -Level "DEBUG"

        return $compressedData
    } catch {
        Write-MCPLog "Erreur lors de la compression des données : $_" -Level "WARNING"
        return $Data
    }
}

# Fonction pour décompresser les données
function Expand-MCPData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$CompressedData
    )

    if (-not $script:MCPConfig.CompressionEnabled) {
        return $CompressedData
    }

    try {
        $compressedBytes = [Convert]::FromBase64String($CompressedData)
        $inputStream = New-Object System.IO.MemoryStream($compressedBytes, 0, $compressedBytes.Length)
        $gzipStream = New-Object System.IO.Compression.GZipStream($inputStream, [System.IO.Compression.CompressionMode]::Decompress)
        $outputStream = New-Object System.IO.MemoryStream
        $buffer = New-Object byte[](4096)

        $count = 0
        do {
            $count = $gzipStream.Read($buffer, 0, $buffer.Length)
            if ($count -gt 0) {
                $outputStream.Write($buffer, 0, $count)
            }
        } while ($count -gt 0)

        $gzipStream.Close()
        $inputStream.Close()
        $outputStream.Close()

        $decompressedBytes = $outputStream.ToArray()
        $decompressedData = [System.Text.Encoding]::UTF8.GetString($decompressedBytes)

        Write-MCPLog "Données décompressées : ${$compressedBytes.Length} octets -> ${$decompressedBytes.Length} octets" -Level "DEBUG"

        return $decompressedData
    } catch {
        Write-MCPLog "Erreur lors de la décompression des données : $_" -Level "WARNING"
        return $CompressedData
    }
}

# Fonction pour exécuter des requêtes en parallèle
function Invoke-MCPParallel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $true)]
        [object[]]$InputObjects,

        [Parameter(Mandatory = $false)]
        [int]$ThrottleLimit = $script:MCPConfig.MaxConcurrentRequests
    )

    # Vérifier si PowerShell 7+ est disponible pour utiliser ForEach-Object -Parallel
    $isPowerShell7 = $PSVersionTable.PSVersion.Major -ge 7

    if ($isPowerShell7) {
        Write-MCPLog "Utilisation de ForEach-Object -Parallel avec PowerShell $($PSVersionTable.PSVersion)" -Level "DEBUG"

        # Utiliser ForEach-Object -Parallel de PowerShell 7+
        $results = $InputObjects | ForEach-Object -Parallel $ScriptBlock -ThrottleLimit $ThrottleLimit
        return $results
    } else {
        Write-MCPLog "Utilisation de RunspacePool avec PowerShell $($PSVersionTable.PSVersion)" -Level "DEBUG"

        # Utiliser RunspacePool pour PowerShell 5.1
        $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $runspacePool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $ThrottleLimit, $sessionState, $Host)
        $runspacePool.Open()

        $scriptBlockWithParams = {
            param($InputObject, $ScriptBlock)
            & $ScriptBlock $InputObject
        }

        $runspaces = @()
        $results = @()

        # Créer et démarrer les runspaces
        foreach ($inputObject in $InputObjects) {
            $powershell = [System.Management.Automation.PowerShell]::Create()
            $powershell.RunspacePool = $runspacePool
            [void]$powershell.AddScript($scriptBlockWithParams).AddParameter("InputObject", $inputObject).AddParameter("ScriptBlock", $ScriptBlock)

            $runspaces += [PSCustomObject]@{
                PowerShell  = $powershell
                AsyncResult = $powershell.BeginInvoke()
                InputObject = $inputObject
            }
        }

        # Récupérer les résultats
        foreach ($runspace in $runspaces) {
            $results += $runspace.PowerShell.EndInvoke($runspace.AsyncResult)
            $runspace.PowerShell.Dispose()
        }

        $runspacePool.Close()
        $runspacePool.Dispose()

        return $results
    }
}

# Fonction pour exécuter des outils MCP en parallèle
function Invoke-MCPToolParallel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$ToolNames,

        [Parameter(Mandatory = $false)]
        [hashtable[]]$ParametersList = @(),

        [Parameter(Mandatory = $false)]
        [int]$ThrottleLimit = $script:MCPConfig.MaxConcurrentRequests
    )

    # Vérifier que la connexion est initialisée
    if (-not $script:MCPConfig.ServerUrl) {
        Write-MCPLog "La connexion au serveur MCP n'est pas initialisée. Utilisez Initialize-MCPConnection." -Level "ERROR"
        return $null
    }

    # Préparer les objets d'entrée
    $inputObjects = @()
    for ($i = 0; $i -lt $ToolNames.Count; $i++) {
        $parameters = if ($i -lt $ParametersList.Count) { $ParametersList[$i] } else { @{} }
        $inputObjects += [PSCustomObject]@{
            ToolName   = $ToolNames[$i]
            Parameters = $parameters
        }
    }

    # Définir le script block pour exécuter l'outil MCP
    $scriptBlock = {
        param($InputObject)
        Invoke-MCPTool -ToolName $InputObject.ToolName -Parameters $InputObject.Parameters
    }

    # Exécuter les outils en parallèle
    $results = Invoke-MCPParallel -ScriptBlock $scriptBlock -InputObjects $inputObjects -ThrottleLimit $ThrottleLimit

    return $results
}

# Fonction pour exécuter des commandes PowerShell en parallèle
function Invoke-MCPPowerShellParallel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Commands,

        [Parameter(Mandatory = $false)]
        [int]$ThrottleLimit = $script:MCPConfig.MaxConcurrentRequests
    )

    # Préparer les objets d'entrée
    $inputObjects = $Commands | ForEach-Object {
        [PSCustomObject]@{
            ToolName   = "run_powershell_command"
            Parameters = @{ command = $_ }
        }
    }

    # Définir le script block pour exécuter l'outil MCP
    $scriptBlock = {
        param($InputObject)
        Invoke-MCPTool -ToolName $InputObject.ToolName -Parameters $InputObject.Parameters
    }

    # Exécuter les commandes en parallèle
    $results = Invoke-MCPParallel -ScriptBlock $scriptBlock -InputObjects $inputObjects -ThrottleLimit $ThrottleLimit

    return $results
}

# Fonction pour exécuter des scripts Python en parallèle
function Invoke-MCPPythonParallel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Scripts,

        [Parameter(Mandatory = $false)]
        [string[][]]$ArgumentsList = @(),

        [Parameter(Mandatory = $false)]
        [int]$ThrottleLimit = $script:MCPConfig.MaxConcurrentRequests
    )

    # Préparer les objets d'entrée
    $inputObjects = @()
    for ($i = 0; $i -lt $Scripts.Count; $i++) {
        $arguments = if ($i -lt $ArgumentsList.Count) { $ArgumentsList[$i] } else { @() }
        $inputObjects += [PSCustomObject]@{
            ToolName   = "run_python_script"
            Parameters = @{
                script    = $Scripts[$i]
                arguments = $arguments
            }
        }
    }

    # Définir le script block pour exécuter l'outil MCP
    $scriptBlock = {
        param($InputObject)
        Invoke-MCPTool -ToolName $InputObject.ToolName -Parameters $InputObject.Parameters
    }

    # Exécuter les scripts en parallèle
    $results = Invoke-MCPParallel -ScriptBlock $scriptBlock -InputObjects $inputObjects -ThrottleLimit $ThrottleLimit

    return $results
}

# Fonction pour exécuter des requêtes HTTP en parallèle
function Invoke-MCPHttpRequestParallel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Urls,

        [Parameter(Mandatory = $false)]
        [string[]]$Methods = @(),

        [Parameter(Mandatory = $false)]
        [hashtable[]]$HeadersList = @(),

        [Parameter(Mandatory = $false)]
        [object[]]$Bodies = @(),

        [Parameter(Mandatory = $false)]
        [int]$ThrottleLimit = $script:MCPConfig.MaxConcurrentRequests
    )

    # Préparer les objets d'entrée
    $inputObjects = @()
    for ($i = 0; $i -lt $Urls.Count; $i++) {
        $method = if ($i -lt $Methods.Count) { $Methods[$i] } else { "GET" }
        $headers = if ($i -lt $HeadersList.Count) { $HeadersList[$i] } else { @{} }
        $body = if ($i -lt $Bodies.Count) { $Bodies[$i] } else { $null }

        $parameters = @{
            url     = $Urls[$i]
            method  = $method
            headers = $headers
        }

        if ($body) {
            $parameters.body = $body
        }

        $inputObjects += [PSCustomObject]@{
            ToolName   = "http_request"
            Parameters = $parameters
        }
    }

    # Définir le script block pour exécuter l'outil MCP
    $scriptBlock = {
        param($InputObject)
        Invoke-MCPTool -ToolName $InputObject.ToolName -Parameters $InputObject.Parameters
    }

    # Exécuter les requêtes en parallèle
    $results = Invoke-MCPParallel -ScriptBlock $scriptBlock -InputObjects $inputObjects -ThrottleLimit $ThrottleLimit

    return $results
}

# Fonction pour traiter des données par lots
function Invoke-MCPBatch {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $true)]
        [object[]]$InputObjects,

        [Parameter(Mandatory = $false)]
        [int]$BatchSize = $script:MCPConfig.BatchSize
    )

    $results = @()
    $batches = [Math]::Ceiling($InputObjects.Count / $BatchSize)

    Write-MCPLog "Traitement de $($InputObjects.Count) objets en $batches lots de $BatchSize" -Level "DEBUG"

    for ($i = 0; $i -lt $batches; $i++) {
        $start = $i * $BatchSize
        $end = [Math]::Min(($i + 1) * $BatchSize - 1, $InputObjects.Count - 1)
        $batchItems = $InputObjects[$start..$end]

        Write-MCPLog "Traitement du lot $($i + 1)/$batches ($($batchItems.Count) objets)" -Level "DEBUG"

        $batchResults = & $ScriptBlock $batchItems
        $results += $batchResults
    }

    return $results
}

<#
.SYNOPSIS
    Récupère la configuration actuelle du module MCPClient.
.DESCRIPTION
    Cette fonction récupère la configuration actuelle du module MCPClient.
.EXAMPLE
    Get-MCPClientConfiguration
    Récupère la configuration actuelle du module MCPClient.
#>
function Get-MCPClientConfiguration {
    [CmdletBinding()]
    param ()

    return $script:MCPConfig
}

# Exportation des fonctions
Export-ModuleMember -Function Initialize-MCPConnection, Get-MCPTools, Invoke-MCPTool, Invoke-MCPPowerShell, Get-MCPSystemInfo, Find-MCPServers, Invoke-MCPPython, Invoke-MCPHttpRequest, Set-MCPClientConfiguration, Get-MCPClientConfiguration, Clear-MCPCache, Invoke-MCPToolParallel, Invoke-MCPPowerShellParallel, Invoke-MCPPythonParallel, Invoke-MCPHttpRequestParallel, Invoke-MCPBatch
