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
    ServerUrl = $null
    Timeout = 30
    RetryCount = 3
    RetryDelay = 2
    DefaultHeaders = @{
        "Content-Type" = "application/json"
        "Accept" = "application/json"
    }
    LogEnabled = $true
    LogLevel = "INFO" # DEBUG, INFO, WARNING, ERROR
    LogPath = Join-Path -Path $env:TEMP -ChildPath "MCPClient.log"
}

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
        "DEBUG" = 0
        "INFO" = 1
        "WARNING" = 2
        "ERROR" = 3
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
    param ()

    # Vérifier que la connexion est initialisée
    if (-not $script:MCPConfig.ServerUrl) {
        Write-MCPLog "La connexion au serveur MCP n'est pas initialisée. Utilisez Initialize-MCPConnection." -Level "ERROR"
        return $null
    }

    # Récupérer la liste des outils
    try {
        $toolsEndpoint = "$($script:MCPConfig.ServerUrl)/tools"
        $response = Invoke-RestMethod -Uri $toolsEndpoint -Method Get -TimeoutSec $script:MCPConfig.Timeout -ErrorAction Stop
        
        Write-MCPLog "Liste des outils récupérée avec succès" -Level "INFO"
        Write-MCPLog "Nombre d'outils disponibles: $($response.tools.Count)" -Level "DEBUG"
        
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
        [hashtable]$Parameters = @{}
    )

    # Vérifier que la connexion est initialisée
    if (-not $script:MCPConfig.ServerUrl) {
        Write-MCPLog "La connexion au serveur MCP n'est pas initialisée. Utilisez Initialize-MCPConnection." -Level "ERROR"
        return $null
    }

    # Exécuter l'outil
    try {
        $toolEndpoint = "$($script:MCPConfig.ServerUrl)/tools/$ToolName"
        
        # Convertir les paramètres en JSON
        $body = $Parameters | ConvertTo-Json -Depth 10
        
        Write-MCPLog "Exécution de l'outil '$ToolName' avec les paramètres: $body" -Level "DEBUG"
        
        $response = Invoke-RestMethod -Uri $toolEndpoint -Method Post -Body $body -ContentType "application/json" -TimeoutSec $script:MCPConfig.Timeout -ErrorAction Stop
        
        Write-MCPLog "Outil '$ToolName' exécuté avec succès" -Level "INFO"
        
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
                $response = Invoke-RestMethod -Uri $toolEndpoint -Method Post -Body $body -ContentType "application/json" -TimeoutSec $script:MCPConfig.Timeout -ErrorAction Stop
                
                Write-MCPLog "Outil '$ToolName' exécuté avec succès après $i tentatives" -Level "INFO"
                
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
        script = $Script
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
        url = $Url
        method = $Method
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

# Exportation des fonctions
Export-ModuleMember -Function Initialize-MCPConnection, Get-MCPTools, Invoke-MCPTool, Invoke-MCPPowerShell, Get-MCPSystemInfo, Find-MCPServers, Invoke-MCPPython, Invoke-MCPHttpRequest, Set-MCPClientConfiguration, Get-MCPClientConfiguration
