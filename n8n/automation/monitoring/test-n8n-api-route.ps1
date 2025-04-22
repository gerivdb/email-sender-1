<#
.SYNOPSIS
    Script pour tester une route API spécifique de n8n.

.DESCRIPTION
    Ce script teste une route API spécifique de n8n avec différentes méthodes et paramètres.

.PARAMETER Url
    URL de la route à tester (sans le protocole, l'hôte et le port).

.PARAMETER Method
    Méthode HTTP à utiliser (GET, POST, PUT, DELETE, etc.).

.PARAMETER ApiKey
    API Key à utiliser. Si non spécifiée, elle sera récupérée depuis les fichiers de configuration.

.PARAMETER Hostname
    Hôte n8n (par défaut: localhost).

.PARAMETER Port
    Port n8n (par défaut: 5678).

.PARAMETER Protocol
    Protocole (http ou https) (par défaut: http).

.PARAMETER Body
    Corps de la requête au format JSON (pour les méthodes POST, PUT, etc.).

.PARAMETER OutputFormat
    Format de sortie (json ou table, par défaut: table).

.EXAMPLE
    .\test-n8n-api-route.ps1 -Url "/api/v1/workflows" -Method "GET"

.EXAMPLE
    .\test-n8n-api-route.ps1 -Url "/api/v1/workflows" -Method "POST" -Body '{"name":"Test Workflow","active":false}'

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  22/04/2025
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$Url,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS")]
    [string]$Method,
    
    [Parameter(Mandatory=$false)]
    [string]$ApiKey = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Hostname = "localhost",
    
    [Parameter(Mandatory=$false)]
    [int]$Port = 5678,
    
    [Parameter(Mandatory=$false)]
    [string]$Protocol = "http",
    
    [Parameter(Mandatory=$false)]
    [string]$Body = "",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("json", "table")]
    [string]$OutputFormat = "table"
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

# Récupérer l'API Key si non spécifiée
if ([string]::IsNullOrEmpty($ApiKey)) {
    $ApiKey = Get-ApiKeyFromConfig
    if ([string]::IsNullOrEmpty($ApiKey)) {
        Write-Warning "Aucune API Key trouvée. La requête échouera probablement si l'authentification est requise."
    } else {
        Write-Host "API Key récupérée depuis la configuration: $ApiKey" -ForegroundColor Green
    }
} else {
    Write-Host "API Key spécifiée: $ApiKey" -ForegroundColor Green
}

# Construire l'URL complète
$fullUrl = "$Protocol`://$Hostname`:$Port$Url"
Write-Host "URL: $fullUrl" -ForegroundColor Cyan
Write-Host "Méthode: $Method" -ForegroundColor Cyan

# Préparer les en-têtes
$headers = @{
    "Accept" = "application/json"
}

if (-not [string]::IsNullOrEmpty($ApiKey)) {
    $headers["X-N8N-API-KEY"] = $ApiKey
}

Write-Host "En-têtes:" -ForegroundColor Cyan
foreach ($key in $headers.Keys) {
    Write-Host "  $key`: $($headers[$key])" -ForegroundColor Cyan
}

# Préparer le corps de la requête
$bodyObject = $null
if (-not [string]::IsNullOrEmpty($Body)) {
    try {
        $bodyObject = $Body | ConvertFrom-Json
        Write-Host "Corps de la requête:" -ForegroundColor Cyan
        Write-Host $Body -ForegroundColor Cyan
    } catch {
        Write-Error "Le corps de la requête n'est pas un JSON valide: $_"
        exit 1
    }
}

# Préparer les paramètres de la requête
$params = @{
    Uri = $fullUrl
    Method = $Method
    Headers = $headers
    ErrorAction = "Stop"
}

if ($null -ne $bodyObject) {
    $params["Body"] = $Body
    $params["ContentType"] = "application/json"
}

# Exécuter la requête
try {
    Write-Host "`nExécution de la requête..." -ForegroundColor Yellow
    $startTime = Get-Date
    $response = Invoke-RestMethod @params
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalMilliseconds
    
    Write-Host "Requête réussie! (Durée: $duration ms)" -ForegroundColor Green
    
    # Afficher la réponse
    if ($OutputFormat -eq "json") {
        $response | ConvertTo-Json -Depth 10
    } else {
        # Essayer d'afficher la réponse sous forme de tableau
        if ($response -is [System.Array]) {
            Write-Host "`nRéponse (tableau de $($response.Count) éléments):" -ForegroundColor Green
            $response | Format-Table -AutoSize
        } elseif ($response -is [PSCustomObject]) {
            Write-Host "`nRéponse (objet):" -ForegroundColor Green
            $response | Format-List
        } else {
            Write-Host "`nRéponse:" -ForegroundColor Green
            $response
        }
    }
    
    # Retourner la réponse
    return @{
        Success = $true
        StatusCode = 200
        Response = $response
        Duration = $duration
    }
} catch {
    $statusCode = if ($_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { 0 }
    $errorMessage = $_.Exception.Message
    
    Write-Host "Requête échouée! (Code: $statusCode)" -ForegroundColor Red
    Write-Host "Erreur: $errorMessage" -ForegroundColor Red
    
    # Essayer de lire le corps de la réponse d'erreur
    if ($_.Exception.Response) {
        try {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            $reader.Close()
            
            if (-not [string]::IsNullOrEmpty($responseBody)) {
                Write-Host "Corps de la réponse:" -ForegroundColor Red
                Write-Host $responseBody -ForegroundColor Red
            }
        } catch {
            # Ignorer les erreurs lors de la lecture du corps de la réponse
        }
    }
    
    # Retourner l'erreur
    return @{
        Success = $false
        StatusCode = $statusCode
        Error = $errorMessage
    }
}
