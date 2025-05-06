# Script simple pour tester l'API OpenRouter avec Qwen3

# Demander la clé API à l'utilisateur
$apiKey = Read-Host -Prompt "Entrez votre clé API OpenRouter"

# Définir les en-têtes de la requête
$headers = @{
    "Content-Type"  = "application/json"
    "Authorization" = "Bearer $apiKey"
}

# Définir le corps de la requête
$body = @{
    model    = "qwen/qwen3-235b-a22b"
    messages = @(
        @{
            role    = "user"
            content = "Réponds simplement 'Test réussi pour Qwen3 via OpenRouter' si tu reçois ce message."
        }
    )
} | ConvertTo-Json

# Appeler l'API
try {
    Write-Host "Appel de l'API OpenRouter avec Qwen3..." -ForegroundColor Yellow
    $response = Invoke-RestMethod -Uri "https://openrouter.ai/api/v1/chat/completions" -Method Post -Headers $headers -Body $body
    
    # Afficher la réponse
    Write-Host "Réponse reçue:" -ForegroundColor Green
    Write-Host $response.choices[0].message.content
    
    # Sauvegarder la clé API dans un fichier de configuration
    $configPath = "projet\config\openrouter_config.json"
    $configDir = Split-Path $configPath -Parent
    
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }
    
    $config = @{
        api_key = $apiKey
        default_model = "qwen/qwen3-235b-a22b"
    }
    
    $config | ConvertTo-Json | Out-File -FilePath $configPath -Encoding utf8
    Write-Host "Configuration sauvegardée dans $configPath" -ForegroundColor Green
}
catch {
    Write-Error "Erreur lors de l'appel à l'API: $_"
    
    # Afficher plus de détails sur l'erreur
    if ($_.Exception.Response) {
        $responseStream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($responseStream)
        $responseBody = $reader.ReadToEnd()
        Write-Error "Détails de l'erreur: $responseBody"
    }
}
