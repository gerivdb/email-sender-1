#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Serveur de passerelle API MCP

.DESCRIPTION
    Serveur de passerelle API MCP
    
.PARAMETER Port
    Port sur lequel le serveur MCP écoute.
    
.PARAMETER LogLevel
    Niveau de journalisation (DEBUG, INFO, WARNING, ERROR).
    
.EXAMPLE
    .\api-gateway.ps1 -Port 8000
    Démarre le serveur sur le port 8000.
    
.NOTES
    Version: 1.0.0
    Auteur: MCP Team
    Date de création: 2023-05-15
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [Parameter(Mandatory=$false)]
    [int]$Port = 8000,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("DEBUG", "INFO", "WARNING", "ERROR")]
    [string]$LogLevel = "INFO"
)

# Importer les modules nécessaires
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules"
Import-Module -Name (Join-Path -Path $modulesPath -ChildPath "MCPManager.psm1") -Force

# Configuration du serveur
$serverConfig = @{
    Port = $Port
    LogLevel = $LogLevel
    MaxConnections = 10
    Timeout = 30
    AllowedIPs = @("127.0.0.1", "::1")
    EnableCompression = $true
}

# Fonction pour écrire des logs
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("DEBUG", "INFO", "WARNING", "ERROR")]
        [string]$Level = "INFO"
    )
    
    # Vérifier le niveau de log
    $logLevels = @{
        "DEBUG" = 0
        "INFO" = 1
        "WARNING" = 2
        "ERROR" = 3
    }
    
    if ($logLevels[$Level] -lt $logLevels[$LogLevel]) {
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
}

# Fonction principale
function Start-Server {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param()
    
    Write-Log "Démarrage du serveur api-gateway sur le port $($serverConfig.Port)..." -Level "INFO"
    
    if ($PSCmdlet.ShouldProcess("Serveur api-gateway", "Démarrer")) {
        try {
            # Initialiser le serveur MCP
            Initialize-MCPServer -Port $serverConfig.Port -LogLevel $serverConfig.LogLevel
            
            # Enregistrer les outils disponibles
            Register-MCPTools
            
            # Démarrer le serveur
            Start-MCPServer
            
            Write-Log "Serveur api-gateway démarré avec succès" -Level "INFO"
        }
        catch {
            Write-Log "Erreur lors du démarrage du serveur api-gateway : $_" -Level "ERROR"
            exit 1
        }
    }
}

# Fonction pour enregistrer les outils disponibles
function Register-MCPTools {
    [CmdletBinding()]
    param()
    
    Write-Log "Enregistrement des outils..." -Level "INFO"
    
    # Outil : Obtenir des informations sur les API
    Register-MCPTool -Name "get_api_info" -ScriptBlock {
        param($params)
        
        return @{
            apis = @(
                @{
                    name = "users"
                    version = "1.0"
                    endpoints = @(
                        "/api/users",
                        "/api/users/{id}"
                    )
                },
                @{
                    name = "products"
                    version = "1.0"
                    endpoints = @(
                        "/api/products",
                        "/api/products/{id}"
                    )
                }
            )
        }
    }
    
    # Outil : Vérifier l'état des API
    Register-MCPTool -Name "check_api_status" -ScriptBlock {
        param($params)
        
        if (-not $params.ContainsKey("api_name")) {
            return @{
                error = "Le paramètre 'api_name' est requis"
            }
        }
        
        $apiName = $params.api_name
        
        # Simuler une vérification d'état
        $status = switch ($apiName) {
            "users" { "online" }
            "products" { "online" }
            default { "unknown" }
        }
        
        return @{
            api_name = $apiName
            status = $status
            last_check = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }
    
    # Outil : Rediriger une requête API
    Register-MCPTool -Name "proxy_api_request" -ScriptBlock {
        param($params)
        
        if (-not $params.ContainsKey("api_name")) {
            return @{
                error = "Le paramètre 'api_name' est requis"
            }
        }
        
        if (-not $params.ContainsKey("endpoint")) {
            return @{
                error = "Le paramètre 'endpoint' est requis"
            }
        }
        
        $apiName = $params.api_name
        $endpoint = $params.endpoint
        
        # Simuler une redirection de requête
        return @{
            api_name = $apiName
            endpoint = $endpoint
            status = "redirected"
            timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }
    
    Write-Log "Outils enregistrés avec succès" -Level "INFO"
}

# Démarrer le serveur
Start-Server
