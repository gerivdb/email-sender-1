# Script d'intégration pour Qwen3 via OpenRouter
# Ce script permet de tester et d'utiliser le modèle Qwen3 via l'API OpenRouter

param (
    [Parameter(Mandatory = $false)]
    [string]$ApiKey = "",

    [Parameter(Mandatory = $false)]
    [string]$Prompt = "Réponds simplement 'Test réussi pour Qwen3 via OpenRouter' si tu reçois ce message.",

    [Parameter(Mandatory = $false)]
    [string]$Model = "qwen/qwen3-235b-a22b",

    [Parameter(Mandatory = $false)]
    [switch]$SaveConfig = $false
)

# Fonction pour obtenir la clé API
function Get-ApiKey {
    param (
        [string]$ProvidedKey
    )

    # Si une clé est fournie en paramètre, l'utiliser
    if (-not [string]::IsNullOrEmpty($ProvidedKey)) {
        return $ProvidedKey
    }

    # Essayer de charger la clé depuis le fichier de configuration
    $configPath = Join-Path $PSScriptRoot "..\..\projet\config\openrouter_config.json"
    if (Test-Path $configPath) {
        try {
            $config = Get-Content $configPath -Raw | ConvertFrom-Json
            if ($config.api_key) {
                return $config.api_key
            }
        } catch {
            Write-Warning "Erreur lors de la lecture du fichier de configuration: $_"
        }
    }

    # Demander la clé à l'utilisateur
    $apiKey = Read-Host -Prompt "Entrez votre clé API OpenRouter"

    # Sauvegarder la configuration si demandé
    if ($SaveConfig) {
        $configDir = Split-Path $configPath -Parent
        if (-not (Test-Path $configDir)) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }

        $config = @{
            api_key       = $apiKey
            default_model = $Model
        }

        $config | ConvertTo-Json | Out-File -FilePath $configPath -Encoding utf8
        Write-Host "Configuration sauvegardée dans $configPath" -ForegroundColor Green
    }

    return $apiKey
}

# Fonction pour appeler l'API OpenRouter
function Invoke-OpenRouterAPI {
    param (
        [string]$ApiKey,
        [string]$Model,
        [string]$Prompt,
        [int]$MaxTokens = 1000,
        [double]$Temperature = 0.7
    )

    $headers = @{
        "Content-Type"  = "application/json"
        "Authorization" = "Bearer $ApiKey"
        "HTTP-Referer"  = "https://github.com/augmentcode-ai"
        "X-Title"       = "Qwen3 Integration Test"
    }

    $body = @{
        model       = $Model
        messages    = @(
            @{
                role    = "system"
                content = "Tu es un assistant utile et concis."
            },
            @{
                role    = "user"
                content = $Prompt
            }
        )
        temperature = $Temperature
        max_tokens  = $MaxTokens
    } | ConvertTo-Json -Depth 10

    try {
        Write-Host "Appel de l'API $Model via OpenRouter..." -ForegroundColor Yellow
        $response = Invoke-RestMethod -Uri "https://openrouter.ai/api/v1/chat/completions" -Method Post -Headers $headers -Body $body

        return $response
    } catch {
        Write-Error "Erreur lors de l'appel à l'API: $_"

        # Afficher plus de détails sur l'erreur
        if ($_.Exception.Response) {
            $responseStream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($responseStream)
            $responseBody = $reader.ReadToEnd()
            Write-Error "Détails de l'erreur: $responseBody"
        }

        return $null
    }
}

# Fonction principale
function Test-Qwen3Integration {
    # Obtenir la clé API
    $apiKey = Get-ApiKey -ProvidedKey $ApiKey

    if ([string]::IsNullOrEmpty($apiKey)) {
        Write-Error "Aucune clé API fournie."
        return $false
    }

    # Appeler l'API
    $response = Invoke-OpenRouterAPI -ApiKey $apiKey -Model $Model -Prompt $Prompt

    if ($null -eq $response) {
        return $false
    }

    # Afficher la réponse
    $content = $response.choices[0].message.content
    Write-Host "`nReponse du modele:" -ForegroundColor Cyan
    Write-Host "--------------------"
    Write-Host $content
    Write-Host "--------------------"

    # Afficher les informations d'utilisation
    Write-Host "`nInformations d'utilisation:" -ForegroundColor Cyan
    Write-Host "Tokens d'entrée: $($response.usage.prompt_tokens)"
    Write-Host "Tokens de sortie: $($response.usage.completion_tokens)"
    Write-Host "Total tokens: $($response.usage.total_tokens)"

    # Vérifier si le test est réussi
    $success = $content -match "Test réussi"

    if ($success) {
        Write-Host "`nTest d'intégration réussi!" -ForegroundColor Green
    } else {
        Write-Host "`nTest d'intégration échoué." -ForegroundColor Red
    }

    return $success
}

# Exécuter le test d'intégration
$result = Test-Qwen3Integration

# Retourner le résultat
return $result
