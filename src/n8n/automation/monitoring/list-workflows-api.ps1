<#
.SYNOPSIS
    Script pour lister les workflows n8n via l'API REST.

.DESCRIPTION
    Ce script liste les workflows n8n via l'API REST en utilisant l'API Key configurée.

.PARAMETER ApiKey
    API Key à utiliser. Si non spécifiée, elle sera récupérée depuis les fichiers de configuration.

.PARAMETER Host
    Hôte n8n (par défaut: localhost).

.PARAMETER Port
    Port n8n (par défaut: 5678).

.PARAMETER Protocol
    Protocole (http ou https) (par défaut: http).

.PARAMETER Active
    Filtre les workflows par état d'activation (par défaut: tous).

.PARAMETER Tags
    Filtre les workflows par tags (séparés par des virgules).

.EXAMPLE
    .\list-workflows-api.ps1 -Active $true -Tags "tag1,tag2"

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
    [bool]$Active = $null,

    [Parameter(Mandatory = $false)]
    [string]$Tags = ""
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
        Write-Error "Aucune API Key trouvée. Exécutez le script configure-n8n-api-key.ps1 pour configurer une API Key."
        exit 1
    } else {
        Write-Host "API Key récupérée depuis la configuration: $ApiKey" -ForegroundColor Green
    }
} else {
    Write-Host "API Key spécifiée: $ApiKey" -ForegroundColor Green
}

# Construire l'URL de l'API
$apiUrl = "$Protocol`://$Hostname`:$Port/api/v1/workflows"

# Ajouter les paramètres de filtrage
$queryParams = @()
if ($null -ne $Active) {
    $queryParams += "active=$($Active.ToString().ToLower())"
}
if (-not [string]::IsNullOrEmpty($Tags)) {
    $queryParams += "tags=$Tags"
}

if ($queryParams.Count -gt 0) {
    $apiUrl += "?" + ($queryParams -join "&")
}

Write-Host "URL de l'API: $apiUrl" -ForegroundColor Cyan

# Préparer les en-têtes
$headers = @{
    "Accept"        = "application/json"
    "X-N8N-API-KEY" = $ApiKey
}

try {
    # Envoyer la requête
    $response = Invoke-RestMethod -Uri $apiUrl -Method Get -Headers $headers

    # Afficher les résultats
    Write-Host "`n=== Workflows n8n ===" -ForegroundColor Cyan

    if ($response.Count -eq 0) {
        Write-Host "Aucun workflow trouvé." -ForegroundColor Yellow
    } else {
        Write-Host "Nombre de workflows: $($response.Count)" -ForegroundColor Green

        # Créer un tableau pour afficher les workflows
        $workflowsTable = @()

        foreach ($workflow in $response) {
            $workflowsTable += [PSCustomObject]@{
                Id        = $workflow.id
                Name      = $workflow.name
                Active    = $workflow.active
                Tags      = if ($workflow.tags.Count -gt 0) { $workflow.tags -join ", " } else { "" }
                CreatedAt = [DateTime]::Parse($workflow.createdAt)
                UpdatedAt = [DateTime]::Parse($workflow.updatedAt)
            }
        }

        # Afficher le tableau
        $workflowsTable | Format-Table -AutoSize -Property Id, Name, Active, Tags, CreatedAt, UpdatedAt

        # Afficher des statistiques
        $activeWorkflows = $workflowsTable | Where-Object { $_.Active }
        $inactiveWorkflows = $workflowsTable | Where-Object { -not $_.Active }

        Write-Host "`n=== Statistiques ===" -ForegroundColor Cyan
        Write-Host "Workflows actifs: $($activeWorkflows.Count)" -ForegroundColor Green
        Write-Host "Workflows inactifs: $($inactiveWorkflows.Count)" -ForegroundColor Yellow

        # Afficher les tags uniques
        $uniqueTags = $workflowsTable | ForEach-Object { $_.Tags -split ", " } | Where-Object { -not [string]::IsNullOrEmpty($_) } | Sort-Object -Unique

        if ($uniqueTags.Count -gt 0) {
            Write-Host "`n=== Tags ===" -ForegroundColor Cyan
            foreach ($tag in $uniqueTags) {
                $tagCount = ($workflowsTable | Where-Object { $_.Tags -like "*$tag*" }).Count
                Write-Host "$tag ($tagCount)" -ForegroundColor Green
            }
        }
    }

    # Retourner les résultats
    return $response
} catch {
    Write-Error "Erreur lors de la récupération des workflows: $_"

    # Afficher des informations supplémentaires sur l'erreur
    if ($_.Exception.Response) {
        $statusCode = [int]$_.Exception.Response.StatusCode
        $statusDescription = $_.Exception.Response.StatusDescription
        Write-Host "Code d'état HTTP: $statusCode ($statusDescription)" -ForegroundColor Red

        # Essayer de lire le corps de la réponse d'erreur
        try {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            $reader.Close()

            if (-not [string]::IsNullOrEmpty($responseBody)) {
                Write-Host "Corps de la réponse:" -ForegroundColor Red
                Write-Host $responseBody
            }
        } catch {
            # Ignorer les erreurs lors de la lecture du corps de la réponse
        }
    }

    return $null
}
