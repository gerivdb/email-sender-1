---
to: mcp/modules/<%= name %>.psm1
---
#Requires -Version 5.1
<#
.SYNOPSIS
    <%= description %>

.DESCRIPTION
    <%= description %>

.NOTES
    Version: 1.0.0
    Auteur: <%= author || 'MCP Team' %>
    Date de création: <%= new Date().toISOString().split('T')[0] %>
#>

# Variables globales
$script:<%= name %>Config = @{
    Timeout               = 30
    RetryCount            = 3
    RetryDelay            = 2
    DefaultHeaders        = @{
        "Content-Type" = "application/json"
        "Accept"       = "application/json"
    }
    LogEnabled            = $true
    LogLevel              = "INFO" # DEBUG, INFO, WARNING, ERROR
    LogPath               = Join-Path -Path $env:TEMP -ChildPath "<%= name %>.log"

    # Options de performance
    CacheEnabled          = $true
    CacheTTL              = 300 # Durée de vie du cache en secondes (5 minutes)
    MaxConcurrentRequests = 5 # Nombre maximum de requêtes simultanées
    BatchSize             = 10 # Taille des lots pour le traitement par lots
    CompressionEnabled    = $true # Activer la compression des données
}

# Cache pour les résultats
$script:<%= name %>Cache = @{}

# Horodatage du dernier nettoyage du cache
$script:LastCacheCleanup = Get-Date

# Fonction pour écrire des logs
function Write-<%= name %>Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("DEBUG", "INFO", "WARNING", "ERROR")]
        [string]$Level = "INFO"
    )

    if (-not $script:<%= name %>Config.LogEnabled) {
        return
    }

    # Vérifier le niveau de log
    $logLevels = @{
        "DEBUG"   = 0
        "INFO"    = 1
        "WARNING" = 2
        "ERROR"   = 3
    }

    if ($logLevels[$Level] -lt $logLevels[$script:<%= name %>Config.LogLevel]) {
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
        Add-Content -Path $script:<%= name %>Config.LogPath -Value $logMessage -ErrorAction SilentlyContinue
    } catch {
        # Ignorer les erreurs d'écriture dans le fichier de log
    }
}

<#
.SYNOPSIS
    Initialise la configuration du module <%= name %>.
.DESCRIPTION
    Cette fonction initialise la configuration du module <%= name %>.
.PARAMETER Timeout
    Le délai d'attente en secondes pour les opérations.
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
    Initialize-<%= name %>Config -Timeout 60 -RetryCount 5
    Initialise la configuration avec un délai d'attente de 60 secondes et 5 tentatives en cas d'échec.
#>
function Initialize-<%= name %>Config {
    [CmdletBinding()]
    param (
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
        [string]$LogPath = (Join-Path -Path $env:TEMP -ChildPath "<%= name %>.log")
    )

    # Mettre à jour la configuration
    $script:<%= name %>Config.Timeout = $Timeout
    $script:<%= name %>Config.RetryCount = $RetryCount
    $script:<%= name %>Config.RetryDelay = $RetryDelay
    $script:<%= name %>Config.LogEnabled = $LogEnabled
    $script:<%= name %>Config.LogLevel = $LogLevel
    $script:<%= name %>Config.LogPath = $LogPath

    Write-<%= name %>Log "Configuration initialisée" -Level "INFO"
    return $true
}

<#
.SYNOPSIS
    Nettoie le cache du module <%= name %>.
.DESCRIPTION
    Cette fonction nettoie le cache du module <%= name %>.
.EXAMPLE
    Clear-<%= name %>Cache
    Nettoie le cache du module <%= name %>.
#>
function Clear-<%= name %>Cache {
    [CmdletBinding()]
    param()

    $script:<%= name %>Cache = @{}
    $script:LastCacheCleanup = Get-Date
    Write-<%= name %>Log "Cache nettoyé" -Level "DEBUG"
}

<#
.SYNOPSIS
    Exemple de fonction du module <%= name %>.
.DESCRIPTION
    Cette fonction est un exemple de fonction du module <%= name %>.
.PARAMETER Name
    Le nom à utiliser dans le message.
.EXAMPLE
    Get-<%= name %>Example -Name "John"
    Retourne "Hello, John!".
#>
function Get-<%= name %>Example {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    Write-<%= name %>Log "Exécution de Get-<%= name %>Example avec le nom '$Name'" -Level "DEBUG"
    return "Hello, $Name!"
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-<%= name %>Config, Clear-<%= name %>Cache, Get-<%= name %>Example
