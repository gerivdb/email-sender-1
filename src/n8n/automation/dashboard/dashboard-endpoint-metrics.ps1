<#
.SYNOPSIS
    Collecte les métriques des endpoints n8n.

.DESCRIPTION
    Ce script collecte les métriques des endpoints n8n, comme l'état des endpoints /healthz, /rest et /webhook.

.PARAMETER DefaultPort
    Port par défaut utilisé par n8n.

.PARAMETER DefaultProtocol
    Protocole par défaut utilisé par n8n (http ou https).

.PARAMETER DefaultHostname
    Nom d'hôte par défaut utilisé par n8n.

.PARAMETER MetricsConfig
    Configuration des métriques à collecter.

.EXAMPLE
    .\dashboard-endpoint-metrics.ps1 -DefaultPort 5678 -DefaultProtocol "http" -DefaultHostname "localhost"

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  26/04/2025
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [int]$DefaultPort = 5678,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("http", "https")]
    [string]$DefaultProtocol = "http",
    
    [Parameter(Mandatory=$false)]
    [string]$DefaultHostname = "localhost",
    
    [Parameter(Mandatory=$false)]
    [object]$MetricsConfig = $null
)

# Fonction pour tester un endpoint
function Test-Endpoint {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Protocol,
        
        [Parameter(Mandatory=$true)]
        [string]$Hostname,
        
        [Parameter(Mandatory=$true)]
        [int]$Port,
        
        [Parameter(Mandatory=$true)]
        [string]$Endpoint,
        
        [Parameter(Mandatory=$false)]
        [int]$Timeout = 5000
    )
    
    $url = "${Protocol}://${Hostname}:${Port}${Endpoint}"
    
    try {
        $startTime = Get-Date
        $response = Invoke-WebRequest -Uri $url -TimeoutSec ($Timeout / 1000) -UseBasicParsing
        $endTime = Get-Date
        $responseTime = ($endTime - $startTime).TotalMilliseconds
        
        return @{
            Success = $true
            StatusCode = $response.StatusCode
            ResponseTime = $responseTime
            Error = $null
        }
    } catch {
        return @{
            Success = $false
            StatusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.value__ } else { $null }
            ResponseTime = $null
            Error = $_.Exception.Message
        }
    }
}

# Fonction principale pour collecter les métriques des endpoints
function Get-EndpointMetrics {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Protocol,
        
        [Parameter(Mandatory=$true)]
        [string]$Hostname,
        
        [Parameter(Mandatory=$true)]
        [int]$Port,
        
        [Parameter(Mandatory=$false)]
        [object]$MetricsConfig = $null
    )
    
    # Définir les endpoints à tester
    $endpoints = @(
        @{
            Id = "healthz"
            Name = "Endpoint /healthz"
            Path = "/healthz"
            Description = "État de l'endpoint /healthz"
        },
        @{
            Id = "rest"
            Name = "Endpoint /rest"
            Path = "/rest/workflows"
            Description = "État de l'endpoint /rest"
        },
        @{
            Id = "webhook"
            Name = "Endpoint /webhook"
            Path = "/webhook"
            Description = "État de l'endpoint /webhook"
        }
    )
    
    # Tester chaque endpoint
    $metrics = @{}
    
    foreach ($endpoint in $endpoints) {
        $result = Test-Endpoint -Protocol $Protocol -Hostname $Hostname -Port $Port -Endpoint $endpoint.Path
        
        $metrics[$endpoint.Id] = @{
            Value = $result.Success
            DisplayValue = if ($result.Success) { "Accessible" } else { "Inaccessible" }
            Status = if ($result.Success) { "success" } else { "danger" }
            Description = $endpoint.Description
            Details = if ($result.Success) {
                "Code: $($result.StatusCode), Temps de réponse: $([Math]::Round($result.ResponseTime, 2)) ms"
            } else {
                "Erreur: $($result.Error)"
            }
            ResponseTime = $result.ResponseTime
            StatusCode = $result.StatusCode
        }
    }
    
    # Retourner les métriques
    return @{
        Metrics = $metrics
        CollectedAt = Get-Date
    }
}

# Si le script est exécuté directement, collecter et retourner les métriques
if ($MyInvocation.InvocationName -ne ".") {
    Get-EndpointMetrics -Protocol $DefaultProtocol -Hostname $DefaultHostname -Port $DefaultPort -MetricsConfig $MetricsConfig
}
