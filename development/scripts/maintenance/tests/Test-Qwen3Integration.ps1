# Script de test pour l'intégration avec Qwen3 via OpenRouter

# Importer les modules nécessaires
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootPath = (Get-Item $ScriptPath).Parent.Parent.Parent.FullName
Import-Module "$RootPath\scripts\environment-compatibility\CredentialManager.psm1" -Force

# Fonction pour obtenir la clé API OpenRouter
function Get-OpenRouterApiKey {
    try {
        $apiKey = Get-StoredCredential -Target "openrouter_api_key" -AsPlainText
        if ([string]::IsNullOrEmpty($apiKey)) {
            throw "Clé API non trouvée dans le gestionnaire d'identifiants"
        }
        return $apiKey
    }
    catch {
        Write-Warning "Erreur lors de la récupération de la clé API depuis le gestionnaire d'identifiants: $_"
        $apiKey = Read-Host -Prompt "Entrez votre clé API OpenRouter" -AsSecureString
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($apiKey)
        $plainApiKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
        
        # Stocker la clé pour une utilisation future
        Set-StoredCredential -Target "openrouter_api_key" -UserName "api" -Password $plainApiKey
        
        return $plainApiKey
    }
}

# Fonction pour tester l'API OpenRouter avec Qwen3
function Test-OpenRouterQwen3 {
    param (
        [string]$ApiKey,
        [string]$Model = "qwen/qwen3-235b-a22b"
    )
    
    $headers = @{
        "Content-Type" = "application/json"
        "Authorization" = "Bearer $ApiKey"
        "HTTP-Referer" = "https://github.com/augmentcode-ai"
        "X-Title" = "Qwen3 Integration Test"
    }
    
    $body = @{
        model = $Model
        messages = @(
            @{
                role = "system"
                content = "Tu es un assistant utile et concis."
            },
            @{
                role = "user"
                content = "Réponds simplement 'Test réussi pour Qwen3 via OpenRouter' si tu reçois ce message."
            }
        )
        temperature = 0.7
        max_tokens = 100
    } | ConvertTo-Json -Depth 10
    
    try {
        Write-Host "Test de l'API $Model via OpenRouter..." -ForegroundColor Yellow
        $response = Invoke-RestMethod -Uri "https://openrouter.ai/api/v1/chat/completions" -Method Post -Headers $headers -Body $body
        
        $content = $response.choices[0].message.content
        Write-Host "Réponse reçue: $content" -ForegroundColor Green
        
        if ($content -match "Test réussi") {
            Write-Host "Test réussi!" -ForegroundColor Green
            return $true
        }
        else {
            Write-Warning "Test échoué: Réponse inattendue"
            return $false
        }
    }
    catch {
        Write-Error "Erreur lors de l'appel à l'API: $_"
        return $false
    }
}

# Fonction principale
function Invoke-Qwen3IntegrationTest {
    # Obtenir la clé API
    $apiKey = Get-OpenRouterApiKey
    if ([string]::IsNullOrEmpty($apiKey)) {
        Write-Error "Impossible d'obtenir la clé API OpenRouter"
        return $false
    }
    
    # Tester l'API
    $testResult = Test-OpenRouterQwen3 -ApiKey $apiKey
    
    if ($testResult) {
        Write-Host "L'intégration avec Qwen3 via OpenRouter fonctionne correctement" -ForegroundColor Green
    }
    else {
        Write-Error "L'intégration avec Qwen3 via OpenRouter a échoué"
    }
    
    return $testResult
}

# Exécuter le test
$result = Invoke-Qwen3IntegrationTest

# Retourner le résultat
return $result
