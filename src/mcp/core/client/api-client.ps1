#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Client API MCP

.DESCRIPTION
    Client API MCP pour interagir avec les serveurs MCP
    
.PARAMETER ServerUrl
    URL du serveur MCP.
    
.PARAMETER ApiKey
    Clé API pour l'authentification.
    
.PARAMETER Timeout
    Délai d'attente en secondes.
    
.EXAMPLE
    .\api-client.ps1 -ServerUrl "http://localhost:8000" -ApiKey "your-api-key"
    Connecte le client au serveur MCP local.
    
.NOTES
    Version: 1.0.0
    Auteur: MCP Team
    Date de création: 2023-05-15
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [Parameter(Mandatory=$false)]
    [string]$ServerUrl = "http://localhost:8000",
    
    [Parameter(Mandatory=$false)]
    [string]$ApiKey = "",
    
    [Parameter(Mandatory=$false)]
    [int]$Timeout = 30
)

# Importer les modules nécessaires
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules"
Import-Module -Name (Join-Path -Path $modulesPath -ChildPath "MCPClient.psm1") -Force

# Configuration du client
$clientConfig = @{
    ServerUrl = $ServerUrl
    ApiKey = $ApiKey
    Timeout = $Timeout
    UserAgent = "MCP API Client/1.0"
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
function Start-Client {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param()
    
    Write-Log "Démarrage du client API MCP..." -Level "INFO"
    
    if ($PSCmdlet.ShouldProcess("Client API MCP", "Démarrer")) {
        try {
            # Initialiser le client MCP
            Initialize-MCPClient -ServerUrl $clientConfig.ServerUrl -ApiKey $clientConfig.ApiKey -Timeout $clientConfig.Timeout
            
            # Vérifier la connexion au serveur
            $connectionStatus = Test-MCPConnection
            
            if ($connectionStatus.Success) {
                Write-Log "Connexion au serveur établie avec succès" -Level "INFO"
                
                # Afficher les informations du serveur
                $serverInfo = Get-MCPServerInfo
                Write-Log "Informations du serveur :" -Level "INFO"
                Write-Log "  Nom : $($serverInfo.Name)" -Level "INFO"
                Write-Log "  Version : $($serverInfo.Version)" -Level "INFO"
                Write-Log "  Uptime : $($serverInfo.Uptime)" -Level "INFO"
                
                # Afficher les outils disponibles
                $availableTools = Get-MCPAvailableTools
                Write-Log "Outils disponibles :" -Level "INFO"
                foreach ($tool in $availableTools) {
                    Write-Log "  $tool" -Level "INFO"
                }
                
                # Démarrer l'interface interactive
                Start-MCPInteractiveSession
            }
            else {
                Write-Log "Erreur lors de la connexion au serveur : $($connectionStatus.Error)" -Level "ERROR"
                exit 1
            }
        }
        catch {
            Write-Log "Erreur lors du démarrage du client API MCP : $_" -Level "ERROR"
            exit 1
        }
    }
}

# Fonction pour tester la connexion au serveur
function Test-MCPConnection {
    [CmdletBinding()]
    param()
    
    try {
        # Simuler un test de connexion
        Start-Sleep -Seconds 1
        
        return @{
            Success = $true
            Message = "Connexion établie avec succès"
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

# Fonction pour obtenir les informations du serveur
function Get-MCPServerInfo {
    [CmdletBinding()]
    param()
    
    try {
        # Simuler une requête pour obtenir les informations du serveur
        Start-Sleep -Milliseconds 500
        
        return @{
            Name = "MCP API Server"
            Version = "1.0.0"
            Uptime = "1 day, 2 hours, 34 minutes"
        }
    }
    catch {
        Write-Log "Erreur lors de la récupération des informations du serveur : $_" -Level "ERROR"
        return $null
    }
}

# Fonction pour obtenir les outils disponibles
function Get-MCPAvailableTools {
    [CmdletBinding()]
    param()
    
    try {
        # Simuler une requête pour obtenir les outils disponibles
        Start-Sleep -Milliseconds 500
        
        return @(
            "get_api_info",
            "check_api_status",
            "proxy_api_request"
        )
    }
    catch {
        Write-Log "Erreur lors de la récupération des outils disponibles : $_" -Level "ERROR"
        return @()
    }
}

# Fonction pour démarrer une session interactive
function Start-MCPInteractiveSession {
    [CmdletBinding()]
    param()
    
    Write-Log "Démarrage de la session interactive..." -Level "INFO"
    Write-Log "Tapez 'exit' pour quitter" -Level "INFO"
    
    $running = $true
    
    while ($running) {
        Write-Host "`nMCP> " -NoNewline -ForegroundColor Green
        $command = Read-Host
        
        switch -Regex ($command) {
            "^exit$" {
                $running = $false
                Write-Log "Fermeture de la session interactive" -Level "INFO"
            }
            "^help$" {
                Show-MCPHelp
            }
            "^get-api-info$" {
                Get-MCPApiInfo
            }
            "^check-api-status (.+)$" {
                $apiName = $matches[1]
                Test-MCPApiStatus -ApiName $apiName
            }
            "^proxy-request (.+) (.+)$" {
                $apiName = $matches[1]
                $endpoint = $matches[2]
                Invoke-MCPProxyRequest -ApiName $apiName -Endpoint $endpoint
            }
            default {
                Write-Log "Commande inconnue. Tapez 'help' pour afficher l'aide." -Level "WARNING"
            }
        }
    }
}

# Fonction pour afficher l'aide
function Show-MCPHelp {
    [CmdletBinding()]
    param()
    
    Write-Host "`nCommandes disponibles :" -ForegroundColor Yellow
    Write-Host "  help                     - Affiche cette aide"
    Write-Host "  get-api-info             - Obtient des informations sur les API disponibles"
    Write-Host "  check-api-status <api>   - Vérifie l'état d'une API"
    Write-Host "  proxy-request <api> <ep> - Redirige une requête vers une API"
    Write-Host "  exit                     - Quitte la session interactive"
}

# Fonction pour obtenir des informations sur les API
function Get-MCPApiInfo {
    [CmdletBinding()]
    param()
    
    try {
        # Simuler une requête pour obtenir des informations sur les API
        Start-Sleep -Milliseconds 500
        
        $apiInfo = @{
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
        
        Write-Host "`nAPI disponibles :" -ForegroundColor Yellow
        foreach ($api in $apiInfo.apis) {
            Write-Host "  $($api.name) (v$($api.version))"
            Write-Host "    Endpoints :"
            foreach ($endpoint in $api.endpoints) {
                Write-Host "      $endpoint"
            }
        }
    }
    catch {
        Write-Log "Erreur lors de la récupération des informations sur les API : $_" -Level "ERROR"
    }
}

# Fonction pour vérifier l'état d'une API
function Test-MCPApiStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ApiName
    )
    
    try {
        # Simuler une requête pour vérifier l'état d'une API
        Start-Sleep -Milliseconds 500
        
        $status = switch ($ApiName) {
            "users" { "online" }
            "products" { "online" }
            default { "unknown" }
        }
        
        Write-Host "`nÉtat de l'API $ApiName : " -NoNewline -ForegroundColor Yellow
        
        switch ($status) {
            "online" { Write-Host $status -ForegroundColor Green }
            "offline" { Write-Host $status -ForegroundColor Red }
            default { Write-Host $status -ForegroundColor Gray }
        }
        
        Write-Host "  Dernière vérification : $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")"
    }
    catch {
        Write-Log "Erreur lors de la vérification de l'état de l'API : $_" -Level "ERROR"
    }
}

# Fonction pour rediriger une requête API
function Invoke-MCPProxyRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ApiName,
        
        [Parameter(Mandatory=$true)]
        [string]$Endpoint
    )
    
    try {
        # Simuler une redirection de requête
        Start-Sleep -Milliseconds 500
        
        Write-Host "`nRedirection de la requête vers $ApiName$Endpoint" -ForegroundColor Yellow
        Write-Host "  Statut : " -NoNewline
        Write-Host "redirected" -ForegroundColor Green
        Write-Host "  Timestamp : $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")"
    }
    catch {
        Write-Log "Erreur lors de la redirection de la requête : $_" -Level "ERROR"
    }
}

# Démarrer le client
Start-Client

