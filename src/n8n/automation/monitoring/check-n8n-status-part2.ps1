<#
.SYNOPSIS
    Script de surveillance du port et de l'API n8n (Partie 2 : Fonctions de vérification).

.DESCRIPTION
    Ce script contient les fonctions de vérification pour la surveillance du port et de l'API n8n.
    Il est conçu pour être utilisé avec les autres parties du script de surveillance.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  22/04/2025
#>

# Importer les fonctions et variables de la partie 1
. "$PSScriptRoot\check-n8n-status-part1.ps1"

# Fonction pour tester si un port est ouvert
function Test-PortOpen {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Hostname,
        
        [Parameter(Mandatory=$true)]
        [int]$Port,
        
        [Parameter(Mandatory=$false)]
        [int]$Timeout = 10,
        
        [Parameter(Mandatory=$false)]
        [int]$RetryCount = 3,
        
        [Parameter(Mandatory=$false)]
        [int]$RetryDelay = 2
    )
    
    $result = @{
        Success = $false
        ResponseTime = 0
        Error = ""
        Attempts = 0
    }
    
    for ($attempt = 1; $attempt -le $RetryCount; $attempt++) {
        $result.Attempts = $attempt
        
        try {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $connectionTask = $tcpClient.ConnectAsync($Hostname, $Port)
            
            $startTime = Get-Date
            $connectionTask.Wait($Timeout * 1000) | Out-Null
            $endTime = Get-Date
            
            $responseTime = ($endTime - $startTime).TotalMilliseconds
            
            if ($connectionTask.IsCompleted -and -not $connectionTask.IsFaulted) {
                $tcpClient.Close()
                $result.Success = $true
                $result.ResponseTime = $responseTime
                return $result
            } else {
                $tcpClient.Close()
                $result.Error = "Timeout lors de la connexion au port $Port sur $Hostname"
            }
        } catch {
            $result.Error = "Erreur lors de la connexion au port $Port sur $Hostname : $_"
        }
        
        if ($attempt -lt $RetryCount) {
            Write-Log "Tentative $attempt échouée. Nouvelle tentative dans $RetryDelay secondes..." -Level "WARNING"
            Start-Sleep -Seconds $RetryDelay
        }
    }
    
    return $result
}

# Fonction pour tester un endpoint HTTP
function Test-HttpEndpoint {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Url,
        
        [Parameter(Mandatory=$false)]
        [string]$ApiKey = "",
        
        [Parameter(Mandatory=$false)]
        [string]$Method = "GET",
        
        [Parameter(Mandatory=$false)]
        [int]$Timeout = 10,
        
        [Parameter(Mandatory=$false)]
        [int]$RetryCount = 3,
        
        [Parameter(Mandatory=$false)]
        [int]$RetryDelay = 2,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Headers = @{},
        
        [Parameter(Mandatory=$false)]
        [string]$Body = ""
    )
    
    $result = @{
        Success = $false
        StatusCode = 0
        ResponseTime = 0
        Response = ""
        Error = ""
        Attempts = 0
    }
    
    # Ajouter l'API Key aux en-têtes si elle est fournie
    if (-not [string]::IsNullOrEmpty($ApiKey)) {
        $Headers["X-N8N-API-KEY"] = $ApiKey
    }
    
    for ($attempt = 1; $attempt -le $RetryCount; $attempt++) {
        $result.Attempts = $attempt
        
        try {
            $params = @{
                Uri = $Url
                Method = $Method
                Headers = $Headers
                TimeoutSec = $Timeout
                UseBasicParsing = $true
            }
            
            if (-not [string]::IsNullOrEmpty($Body)) {
                $params.Body = $Body
                $params.ContentType = "application/json"
            }
            
            $startTime = Get-Date
            $response = Invoke-WebRequest @params
            $endTime = Get-Date
            
            $responseTime = ($endTime - $startTime).TotalMilliseconds
            
            $result.Success = $true
            $result.StatusCode = $response.StatusCode
            $result.ResponseTime = $responseTime
            $result.Response = $response.Content
            
            return $result
        } catch [System.Net.WebException] {
            $ex = $_.Exception
            
            # Récupérer le code d'état si disponible
            if ($ex.Response -ne $null) {
                $result.StatusCode = [int]$ex.Response.StatusCode
            }
            
            $result.Error = "Erreur HTTP: $($ex.Message)"
            
            # Essayer de lire le corps de la réponse d'erreur
            if ($ex.Response -ne $null) {
                try {
                    $reader = New-Object System.IO.StreamReader($ex.Response.GetResponseStream())
                    $responseBody = $reader.ReadToEnd()
                    $reader.Close()
                    
                    if (-not [string]::IsNullOrEmpty($responseBody)) {
                        $result.Response = $responseBody
                    }
                } catch {
                    # Ignorer les erreurs lors de la lecture du corps de la réponse
                }
            }
        } catch {
            $result.Error = "Erreur lors de la requête HTTP: $_"
        }
        
        if ($attempt -lt $RetryCount) {
            Write-Log "Tentative $attempt échouée. Nouvelle tentative dans $RetryDelay secondes..." -Level "WARNING"
            Start-Sleep -Seconds $RetryDelay
        }
    }
    
    return $result
}

# Fonction pour tester l'API n8n
function Test-N8nApi {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Hostname,
        
        [Parameter(Mandatory=$true)]
        [int]$Port,
        
        [Parameter(Mandatory=$true)]
        [string]$Protocol,
        
        [Parameter(Mandatory=$false)]
        [array]$Endpoints = @("/", "/healthz"),
        
        [Parameter(Mandatory=$false)]
        [string]$ApiKey = "",
        
        [Parameter(Mandatory=$false)]
        [int]$Timeout = 10,
        
        [Parameter(Mandatory=$false)]
        [int]$RetryCount = 3,
        
        [Parameter(Mandatory=$false)]
        [int]$RetryDelay = 2
    )
    
    $results = @{
        PortTest = $null
        EndpointTests = @{}
        OverallSuccess = $false
        StartTime = Get-Date
        EndTime = $null
        TotalTime = 0
    }
    
    # Tester si le port est ouvert
    Write-Log "Test du port $Port sur $Hostname..." -Level "INFO"
    $portResult = Test-PortOpen -Hostname $Hostname -Port $Port -Timeout $Timeout -RetryCount $RetryCount -RetryDelay $RetryDelay
    $results.PortTest = $portResult
    
    if (-not $portResult.Success) {
        Write-Log "Le port $Port n'est pas accessible sur $Hostname: $($portResult.Error)" -Level "ERROR"
        $results.EndTime = Get-Date
        $results.TotalTime = ($results.EndTime - $results.StartTime).TotalMilliseconds
        return $results
    }
    
    Write-Log "Port $Port accessible sur $Hostname (Temps de réponse: $($portResult.ResponseTime) ms)" -Level "SUCCESS"
    
    # Tester chaque endpoint
    $endpointSuccessCount = 0
    
    foreach ($endpoint in $Endpoints) {
        $url = "$Protocol`://$Hostname`:$Port$endpoint"
        Write-Log "Test de l'endpoint: $url" -Level "INFO"
        
        $endpointResult = Test-HttpEndpoint -Url $url -ApiKey $ApiKey -Timeout $Timeout -RetryCount $RetryCount -RetryDelay $RetryDelay
        $results.EndpointTests[$endpoint] = $endpointResult
        
        if ($endpointResult.Success) {
            $endpointSuccessCount++
            Write-Log "Endpoint $url accessible (Code: $($endpointResult.StatusCode), Temps: $($endpointResult.ResponseTime) ms)" -Level "SUCCESS"
        } else {
            Write-Log "Échec de l'accès à l'endpoint $url: $($endpointResult.Error)" -Level "ERROR"
        }
    }
    
    # Déterminer le succès global
    $results.OverallSuccess = ($endpointSuccessCount -eq $Endpoints.Count)
    $results.EndTime = Get-Date
    $results.TotalTime = ($results.EndTime - $results.StartTime).TotalMilliseconds
    
    return $results
}

# Fonction pour redémarrer n8n
function Restart-N8n {
    param (
        [Parameter(Mandatory=$false)]
        [string]$RestartScript = $script:CommonParams.RestartScript
    )
    
    # Vérifier si le script de redémarrage existe
    if (-not (Test-Path -Path $RestartScript)) {
        Write-Log "Script de redémarrage non trouvé: $RestartScript" -Level "ERROR"
        return $false
    }
    
    # Exécuter le script de redémarrage
    try {
        Write-Log "Redémarrage de n8n..." -Level "WARNING"
        & $RestartScript
        Write-Log "n8n redémarré avec succès" -Level "SUCCESS"
        return $true
    } catch {
        Write-Log "Erreur lors du redémarrage de n8n: $_" -Level "ERROR"
        return $false
    }
}

# Exporter les fonctions pour les autres parties du script
Export-ModuleMember -Function Test-PortOpen, Test-HttpEndpoint, Test-N8nApi, Restart-N8n
