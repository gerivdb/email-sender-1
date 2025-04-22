<#
.SYNOPSIS
    Script de test de l'API Key pour n8n.

.DESCRIPTION
    Ce script teste l'accès à l'API n8n en utilisant l'API Key configurée.

.PARAMETER ApiKey
    API Key à utiliser. Si non spécifiée, elle sera récupérée depuis les fichiers de configuration.

.PARAMETER Host
    Hôte n8n (par défaut: localhost).

.PARAMETER Port
    Port n8n (par défaut: 5678).

.PARAMETER Protocol
    Protocole (http ou https) (par défaut: http).

.PARAMETER Endpoints
    Liste des endpoints à tester (par défaut: /api/v1/workflows, /api/v1/executions, /healthz).

.EXAMPLE
    .\test-n8n-api-key.ps1 -ApiKey "votre-api-key" -Port 5679

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  22/04/2025
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ApiKey = "",

    [Parameter(Mandatory = $false)]
    [string]$Hostname = "localhost",

    [Parameter(Mandatory = $false)]
    [int]$Port = 5678,

    [Parameter(Mandatory = $false)]
    [string]$Protocol = "http",

    [Parameter(Mandatory = $false)]
    [string[]]$Endpoints = @("/api/v1/workflows", "/api/v1/executions", "/healthz")
)

# Fonction pour récupérer l'API Key depuis les fichiers de configuration
function Get-ApiKeyFromConfig {
    # Essayer de récupérer l'API Key depuis le fichier de configuration
    $configFile = Join-Path -Path (Get-Location) -ChildPath "n8n/core/n8n-config.json"
    if (Test-Path -Path $configFile) {
        try {
            $config = Get-Content -Path $configFile -Raw | ConvertFrom-Json
            if ($config.security -and $config.security.apiKey -and $config.security.apiKey.value) {
                return $config.security.apiKey.value
            }
        } catch {
            Write-Warning "Erreur lors de la lecture du fichier de configuration: $_"
        }
    }

    # Essayer de récupérer l'API Key depuis le fichier .env
    $envFile = Join-Path -Path (Get-Location) -ChildPath "n8n/.env"
    if (Test-Path -Path $envFile) {
        try {
            $envContent = Get-Content -Path $envFile
            foreach ($line in $envContent) {
                if ($line -match "^N8N_API_KEY=(.+)$") {
                    return $matches[1]
                }
            }
        } catch {
            Write-Warning "Erreur lors de la lecture du fichier .env: $_"
        }
    }

    return ""
}

# Fonction pour tester un endpoint
function Test-Endpoint {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Url,

        [Parameter(Mandatory = $false)]
        [string]$ApiKey = "",

        [Parameter(Mandatory = $false)]
        [string]$Method = "GET"
    )

    try {
        $headers = @{}
        if (-not [string]::IsNullOrEmpty($ApiKey)) {
            $headers["X-N8N-API-KEY"] = $ApiKey
        }

        $params = @{
            Uri         = $Url
            Method      = $Method
            Headers     = $headers
            ErrorAction = "Stop"
        }

        $response = Invoke-RestMethod @params
        return @{
            Success  = $true
            Response = $response
            Error    = $null
        }
    } catch {
        return @{
            Success  = $false
            Response = $null
            Error    = $_
        }
    }
}

# Récupérer l'API Key si non spécifiée
if ([string]::IsNullOrEmpty($ApiKey)) {
    $ApiKey = Get-ApiKeyFromConfig
    if ([string]::IsNullOrEmpty($ApiKey)) {
        Write-Warning "Aucune API Key trouvée. Les tests seront effectués sans API Key."
    } else {
        Write-Host "API Key récupérée depuis la configuration: $ApiKey" -ForegroundColor Green
    }
} else {
    Write-Host "API Key spécifiée: $ApiKey" -ForegroundColor Green
}

# Afficher les informations de test
Write-Host "`n=== Test de l'API n8n ===" -ForegroundColor Cyan
Write-Host "URL de base: $Protocol`://$Hostname`:$Port" -ForegroundColor Cyan
Write-Host "API Key: $(if ([string]::IsNullOrEmpty($ApiKey)) { "Non spécifiée" } else { $ApiKey })" -ForegroundColor Cyan
Write-Host "Endpoints à tester: $($Endpoints -join ", ")" -ForegroundColor Cyan

# Tester chaque endpoint
$results = @()

foreach ($endpoint in $Endpoints) {
    $url = "$Protocol`://$Hostname`:$Port$endpoint"
    Write-Host "`nTest de l'endpoint: $url" -ForegroundColor Yellow

    $result = Test-Endpoint -Url $url -ApiKey $ApiKey

    if ($result.Success) {
        Write-Host "  Succès!" -ForegroundColor Green

        # Afficher la réponse de manière formatée
        if ($null -ne $result.Response) {
            if ($result.Response -is [PSCustomObject]) {
                $responseJson = $result.Response | ConvertTo-Json -Depth 3
                Write-Host "  Réponse:" -ForegroundColor Green
                Write-Host $responseJson
            } else {
                Write-Host "  Réponse: $($result.Response)" -ForegroundColor Green
            }
        }
    } else {
        Write-Host "  Échec!" -ForegroundColor Red
        Write-Host "  Erreur: $($result.Error.Exception.Message)" -ForegroundColor Red

        # Afficher des informations supplémentaires sur l'erreur
        if ($result.Error.Exception.Response) {
            $statusCode = [int]$result.Error.Exception.Response.StatusCode
            $statusDescription = $result.Error.Exception.Response.StatusDescription
            Write-Host "  Code d'état HTTP: $statusCode ($statusDescription)" -ForegroundColor Red

            # Essayer de lire le corps de la réponse d'erreur
            try {
                $reader = New-Object System.IO.StreamReader($result.Error.Exception.Response.GetResponseStream())
                $responseBody = $reader.ReadToEnd()
                $reader.Close()

                if (-not [string]::IsNullOrEmpty($responseBody)) {
                    Write-Host "  Corps de la réponse:" -ForegroundColor Red
                    Write-Host $responseBody
                }
            } catch {
                # Ignorer les erreurs lors de la lecture du corps de la réponse
            }
        }
    }

    $results += [PSCustomObject]@{
        Endpoint = $endpoint
        Url      = $url
        Success  = $result.Success
        Error    = if ($result.Success) { $null } else { $result.Error.Exception.Message }
    }
}

# Afficher le résumé
Write-Host "`n=== Résumé des tests ===" -ForegroundColor Cyan
$results | Format-Table -AutoSize -Property Endpoint, Success, Error

# Calculer le taux de réussite
$successCount = ($results | Where-Object { $_.Success }).Count
$totalCount = $results.Count
$successRate = [Math]::Round(($successCount / $totalCount) * 100, 2)

Write-Host "Taux de réussite: $successRate% ($successCount/$totalCount)" -ForegroundColor $(if ($successRate -eq 100) { "Green" } elseif ($successRate -gt 50) { "Yellow" } else { "Red" })

# Suggestions en cas d'échec
if ($successRate -lt 100) {
    Write-Host "`n=== Suggestions en cas d'échec ===" -ForegroundColor Yellow

    # Vérifier si l'API Key est vide
    if ([string]::IsNullOrEmpty($ApiKey)) {
        Write-Host "- Aucune API Key n'a été spécifiée. Exécutez le script configure-n8n-api-key.ps1 pour configurer une API Key." -ForegroundColor Yellow
    }

    # Vérifier si n8n est en cours d'exécution
    $healthzResult = $results | Where-Object { $_.Endpoint -eq "/healthz" }
    if ($healthzResult -and -not $healthzResult.Success) {
        Write-Host "- n8n ne semble pas être en cours d'exécution. Démarrez n8n et réessayez." -ForegroundColor Yellow
    }

    # Vérifier si l'authentification est activée
    $apiResult = $results | Where-Object { $_.Endpoint -eq "/api/v1/workflows" }
    if ($apiResult -and -not $apiResult.Success) {
        Write-Host "- L'accès à l'API a échoué. Vérifiez que l'API Key est correcte et que l'authentification est correctement configurée." -ForegroundColor Yellow
        Write-Host "  - Vérifiez que la section security.apiKey est correctement configurée dans le fichier n8n-config.json." -ForegroundColor Yellow
        Write-Host "  - Vérifiez que la variable N8N_API_KEY est correctement définie dans le fichier .env." -ForegroundColor Yellow
        Write-Host "  - Vérifiez que n8n est configuré pour utiliser l'API Key (N8N_AUTH_DISABLED=false)." -ForegroundColor Yellow
    }
}

# Retourner les résultats
return $results
