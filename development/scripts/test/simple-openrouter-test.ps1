# Script simple pour tester l'API OpenRouter

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
    Write-Host "Appel de l'API OpenRouter..." -ForegroundColor Yellow
    $response = Invoke-RestMethod -Uri "https://openrouter.ai/api/v1/chat/completions" -Method Post -Headers $headers -Body $body
    
    # Afficher la réponse
    Write-Host "Réponse reçue:" -ForegroundColor Green
    Write-Host $response.choices[0].message.content
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
