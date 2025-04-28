#Requires -Version 5.1
<#
.SYNOPSIS
    Initialise le cache prÃ©dictif pour n8n.
.DESCRIPTION
    Ce script configure et initialise le cache prÃ©dictif pour n8n,
    amÃ©liorant les performances des workflows en anticipant les besoins en donnÃ©es.
.PARAMETER N8nApiUrl
    URL de l'API n8n (par dÃ©faut: http://localhost:5678/api/v1).
.PARAMETER ApiKey
    ClÃ© API pour l'authentification n8n.
.PARAMETER CachePath
    Chemin du dossier de cache.
.PARAMETER MaxCacheSizeMB
    Taille maximale du cache en MB (par dÃ©faut: 100).
.PARAMETER DefaultTTL
    DurÃ©e de vie par dÃ©faut des entrÃ©es du cache en secondes (par dÃ©faut: 3600).
.EXAMPLE
    .\Initialize-N8nPredictiveCache.ps1 -ApiKey "n8n_api_key" -MaxCacheSizeMB 200
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$N8nApiUrl = "http://localhost:5678/api/v1",
    
    [Parameter(Mandatory = $false)]
    [string]$ApiKey = "",
    
    [Parameter(Mandatory = $false)]
    [string]$CachePath = ".\cache\predictive",
    
    [Parameter(Mandatory = $false)]
    [int]$MaxCacheSizeMB = 100,
    
    [Parameter(Mandatory = $false)]
    [int]$DefaultTTL = 3600
)

# Importer le module de cache prÃ©dictif
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\PredictiveCache.psm1"

if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Module de cache prÃ©dictif introuvable: $modulePath"
    exit 1
}

Import-Module $modulePath -Force

# Fonction pour Ã©crire dans le journal
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS", "TITLE")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        "TITLE" { "Cyan" }
    }
    
    Write-Host "[$timestamp] " -NoNewline
    Write-Host "[$Level] " -NoNewline -ForegroundColor $color
    Write-Host $Message
}

# Fonction pour tester la connexion Ã  n8n
function Test-N8nConnection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ApiUrl,
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey = ""
    )
    
    try {
        $headers = @{
            "Accept" = "application/json"
        }
        
        if ($ApiKey) {
            $headers["X-N8N-API-KEY"] = $ApiKey
        }
        
        $response = Invoke-RestMethod -Uri "$ApiUrl/health" -Method Get -Headers $headers
        
        if ($response.status -eq "ok") {
            Write-Log "Connexion Ã  n8n Ã©tablie. Version: $($response.version)" -Level "SUCCESS"
            return $true
        }
        else {
            Write-Log "n8n n'est pas disponible ou en bonne santÃ©." -Level "ERROR"
            return $false
        }
    }
    catch {
        Write-Log "Erreur lors de la connexion Ã  n8n: $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour crÃ©er un webhook n8n pour le cache prÃ©dictif
function New-N8nCacheWebhook {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ApiUrl,
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey = ""
    )
    
    try {
        $headers = @{
            "Accept" = "application/json"
            "Content-Type" = "application/json"
        }
        
        if ($ApiKey) {
            $headers["X-N8N-API-KEY"] = $ApiKey
        }
        
        # VÃ©rifier si le webhook existe dÃ©jÃ 
        $webhooks = Invoke-RestMethod -Uri "$ApiUrl/webhooks" -Method Get -Headers $headers
        
        $existingWebhook = $webhooks | Where-Object { $_.name -eq "predictive-cache-hook" }
        
        if ($existingWebhook) {
            Write-Log "Le webhook pour le cache prÃ©dictif existe dÃ©jÃ ." -Level "INFO"
            return $existingWebhook.id
        }
        
        # CrÃ©er un nouveau webhook
        $webhookData = @{
            name = "predictive-cache-hook"
            httpMethod = "POST"
            path = "predictive-cache/hook"
            webhookPath = "predictive-cache/hook"
            responseMode = "lastNode"
            responseCode = 200
        }
        
        $response = Invoke-RestMethod -Uri "$ApiUrl/webhooks" -Method Post -Headers $headers -Body ($webhookData | ConvertTo-Json)
        
        Write-Log "Webhook pour le cache prÃ©dictif crÃ©Ã© avec succÃ¨s." -Level "SUCCESS"
        return $response.id
    }
    catch {
        Write-Log "Erreur lors de la crÃ©ation du webhook: $_" -Level "ERROR"
        return $null
    }
}

# Fonction pour crÃ©er un workflow n8n pour le cache prÃ©dictif
function New-N8nCacheWorkflow {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ApiUrl,
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey = "",
        
        [Parameter(Mandatory = $true)]
        [string]$WebhookId
    )
    
    try {
        $headers = @{
            "Accept" = "application/json"
            "Content-Type" = "application/json"
        }
        
        if ($ApiKey) {
            $headers["X-N8N-API-KEY"] = $ApiKey
        }
        
        # VÃ©rifier si le workflow existe dÃ©jÃ 
        $workflows = Invoke-RestMethod -Uri "$ApiUrl/workflows" -Method Get -Headers $headers
        
        $existingWorkflow = $workflows | Where-Object { $_.name -eq "Predictive Cache Manager" }
        
        if ($existingWorkflow) {
            Write-Log "Le workflow pour le cache prÃ©dictif existe dÃ©jÃ ." -Level "INFO"
            return $existingWorkflow.id
        }
        
        # CrÃ©er un nouveau workflow
        $workflowData = @{
            name = "Predictive Cache Manager"
            active = $true
            nodes = @(
                @{
                    id = "webhook"
                    name = "Webhook"
                    type = "n8n-nodes-base.webhook"
                    typeVersion = 1
                    position = @(100, 300)
                    webhookId = $WebhookId
                    parameters = @{
                        path = "predictive-cache/hook"
                        responseMode = "lastNode"
                    }
                },
                @{
                    id = "function"
                    name = "Process Cache Request"
                    type = "n8n-nodes-base.function"
                    typeVersion = 1
                    position = @(400, 300)
                    parameters = @{
                        functionCode = @"
// Process the cache request
const data = $input.first();
const operation = data.operation || 'get';
const key = data.key;
const value = data.value;
const ttl = data.ttl || 3600;
const workflowId = data.workflowId;
const nodeId = data.nodeId;
const metadata = data.metadata || {};

// Create a unique cache key if not provided
const cacheKey = key || `${workflowId}:${nodeId}:${JSON.stringify(metadata)}`;

// Initialize response
let response = {
  success: false,
  operation,
  key: cacheKey,
  timestamp: new Date().toISOString()
};

// Process based on operation
switch (operation.toLowerCase()) {
  case 'get':
    // Get from cache
    const cachedItem = $node['Cache Storage'].getItem(cacheKey);
    if (cachedItem) {
      response.success = true;
      response.value = cachedItem.value;
      response.cached = true;
      response.ttl = cachedItem.ttl;
      response.expiresAt = cachedItem.expiresAt;
      
      // Register cache access for prediction
      $node['Register Access'].registerAccess(cacheKey, workflowId, nodeId, metadata);
    } else {
      response.success = false;
      response.cached = false;
      response.message = 'Item not found in cache';
      
      // Get predictions for this key
      response.predictions = $node['Get Predictions'].getPredictions(cacheKey, workflowId, nodeId);
    }
    break;
    
  case 'set':
    // Set in cache
    if (!value) {
      response.success = false;
      response.message = 'No value provided for cache';
      break;
    }
    
    $node['Cache Storage'].setItem(cacheKey, value, ttl);
    response.success = true;
    response.ttl = ttl;
    response.expiresAt = new Date(Date.now() + (ttl * 1000)).toISOString();
    
    // Register cache access for prediction
    $node['Register Access'].registerAccess(cacheKey, workflowId, nodeId, metadata);
    break;
    
  case 'remove':
    // Remove from cache
    $node['Cache Storage'].removeItem(cacheKey);
    response.success = true;
    break;
    
  default:
    response.success = false;
    response.message = `Unknown operation: ${operation}`;
}

return response;
"@
                    }
                },
                @{
                    id = "respond"
                    name = "Respond to Webhook"
                    type = "n8n-nodes-base.respondToWebhook"
                    typeVersion = 1
                    position = @(700, 300)
                }
            )
            connections = @{
                webhook = @{
                    main = @(
                        @(
                            @{
                                node = "function"
                                type = "main"
                                index = 0
                            }
                        )
                    )
                }
                function = @{
                    main = @(
                        @(
                            @{
                                node = "respond"
                                type = "main"
                                index = 0
                            }
                        )
                    )
                }
            }
        }
        
        $response = Invoke-RestMethod -Uri "$ApiUrl/workflows" -Method Post -Headers $headers -Body ($workflowData | ConvertTo-Json -Depth 10)
        
        Write-Log "Workflow pour le cache prÃ©dictif crÃ©Ã© avec succÃ¨s." -Level "SUCCESS"
        return $response.id
    }
    catch {
        Write-Log "Erreur lors de la crÃ©ation du workflow: $_" -Level "ERROR"
        return $null
    }
}

# Fonction pour crÃ©er un exemple d'utilisation du cache prÃ©dictif
function New-CacheUsageExample {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$N8nApiUrl,
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey = ""
    )
    
    $examplePath = Join-Path -Path $PSScriptRoot -ChildPath "Example-PredictiveCache.ps1"
    
    $exampleContent = @"
#Requires -Version 5.1
<#
.SYNOPSIS
    Exemple d'utilisation du cache prÃ©dictif pour n8n.
.DESCRIPTION
    Ce script montre comment utiliser le cache prÃ©dictif pour amÃ©liorer
    les performances des workflows n8n.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: $(Get-Date -Format "yyyy-MM-dd")
#>

# Importer le module de cache prÃ©dictif
Import-Module "$PSScriptRoot\..\..\modules\PredictiveCache.psm1" -Force

# Initialiser le cache prÃ©dictif
Initialize-PredictiveCache -Enabled $true -MaxCacheSize 100MB -DefaultTTL 3600

# Fonction pour appeler l'API du cache prÃ©dictif
function Invoke-PredictiveCache {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("get", "set", "remove")]
        [string]$Operation,
        
        [Parameter(Mandatory = $true)]
        [string]$Key,
        
        [Parameter(Mandatory = $false)]
        [object]$Value = $null,
        
        [Parameter(Mandatory = $false)]
        [int]$TTL = 3600,
        
        [Parameter(Mandatory = $false)]
        [string]$WorkflowId = "",
        
        [Parameter(Mandatory = $false)]
        [string]$NodeId = "",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Metadata = @{}
    )
    
    $apiUrl = "$N8nApiUrl"
    $headers = @{
        "Content-Type" = "application/json"
    }
    
    if ("$ApiKey") {
        $headers["X-N8N-API-KEY"] = "$ApiKey"
    }
    
    $body = @{
        operation = $Operation
        key = $Key
        workflowId = $WorkflowId
        nodeId = $NodeId
        metadata = $Metadata
    }
    
    if ($Operation -eq "set") {
        $body.value = $Value
        $body.ttl = $TTL
    }
    
    try {
        $response = Invoke-RestMethod -Uri "$apiUrl/webhook/predictive-cache/hook" -Method Post -Headers $headers -Body ($body | ConvertTo-Json -Depth 10)
        return $response
    }
    catch {
        Write-Error "Erreur lors de l'appel au cache prÃ©dictif: $_"
        return $null
    }
}

# Exemple 1: Mettre en cache une valeur
Write-Host "`nExemple 1: Mettre en cache une valeur" -ForegroundColor Magenta
$data = @{
    user = "john.doe"
    email = "john.doe@example.com"
    permissions = @("read", "write", "admin")
}
$result = Invoke-PredictiveCache -Operation "set" -Key "user:john.doe" -Value $data -WorkflowId "user-workflow" -NodeId "get-user"
Write-Host "RÃ©sultat: $($result | ConvertTo-Json)" -ForegroundColor Green

# Exemple 2: RÃ©cupÃ©rer une valeur du cache
Write-Host "`nExemple 2: RÃ©cupÃ©rer une valeur du cache" -ForegroundColor Magenta
$result = Invoke-PredictiveCache -Operation "get" -Key "user:john.doe" -WorkflowId "user-workflow" -NodeId "get-user"
Write-Host "RÃ©sultat: $($result | ConvertTo-Json)" -ForegroundColor Green

# Exemple 3: Mettre en cache plusieurs valeurs liÃ©es
Write-Host "`nExemple 3: Mettre en cache plusieurs valeurs liÃ©es" -ForegroundColor Magenta
for ($i = 1; $i -le 5; $i++) {
    $data = @{
        id = $i
        name = "Product $i"
        price = $i * 10
    }
    $result = Invoke-PredictiveCache -Operation "set" -Key "product:$i" -Value $data -WorkflowId "product-workflow" -NodeId "get-product"
    Write-Host "Produit $i mis en cache" -ForegroundColor Green
}

# Exemple 4: RÃ©cupÃ©rer des valeurs en sÃ©quence (pour construire des prÃ©dictions)
Write-Host "`nExemple 4: RÃ©cupÃ©rer des valeurs en sÃ©quence" -ForegroundColor Magenta
for ($i = 1; $i -le 5; $i++) {
    $result = Invoke-PredictiveCache -Operation "get" -Key "product:$i" -WorkflowId "product-workflow" -NodeId "get-product"
    Write-Host "Produit $i rÃ©cupÃ©rÃ©: $($result.value.name) - $($result.value.price)â‚¬" -ForegroundColor Green
}

# Exemple 5: VÃ©rifier les prÃ©dictions
Write-Host "`nExemple 5: VÃ©rifier les prÃ©dictions" -ForegroundColor Magenta
$result = Invoke-PredictiveCache -Operation "get" -Key "product:1" -WorkflowId "product-workflow" -NodeId "get-product"
Write-Host "RÃ©sultat: $($result | ConvertTo-Json)" -ForegroundColor Green

if ($result.predictions) {
    Write-Host "PrÃ©dictions:" -ForegroundColor Yellow
    foreach ($prediction in $result.predictions) {
        Write-Host "- $($prediction.key) (Score: $($prediction.score))" -ForegroundColor Yellow
    }
}

# Exemple 6: Supprimer une valeur du cache
Write-Host "`nExemple 6: Supprimer une valeur du cache" -ForegroundColor Magenta
$result = Invoke-PredictiveCache -Operation "remove" -Key "user:john.doe"
Write-Host "RÃ©sultat: $($result | ConvertTo-Json)" -ForegroundColor Green
"@
    
    try {
        $exampleContent | Out-File -FilePath $examplePath -Encoding utf8
        Write-Log "Exemple d'utilisation crÃ©Ã©: $examplePath" -Level "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Erreur lors de la crÃ©ation de l'exemple d'utilisation: $_" -Level "ERROR"
        return $false
    }
}

# Fonction principale
function Initialize-N8nPredictiveCache {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$N8nApiUrl,
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey = "",
        
        [Parameter(Mandatory = $true)]
        [string]$CachePath,
        
        [Parameter(Mandatory = $true)]
        [int]$MaxCacheSizeMB,
        
        [Parameter(Mandatory = $true)]
        [int]$DefaultTTL
    )
    
    Write-Log "Initialisation du cache prÃ©dictif pour n8n..." -Level "TITLE"
    
    # Initialiser le module de cache prÃ©dictif
    Initialize-PredictiveCache -Enabled $true -CachePath $CachePath -MaxCacheSize ($MaxCacheSizeMB * 1MB) -DefaultTTL $DefaultTTL
    
    # Tester la connexion Ã  n8n
    $connected = Test-N8nConnection -ApiUrl $N8nApiUrl -ApiKey $ApiKey
    
    if (-not $connected) {
        Write-Log "Impossible de se connecter Ã  n8n. VÃ©rifiez l'URL et la clÃ© API." -Level "ERROR"
        return $false
    }
    
    # CrÃ©er le webhook n8n
    $webhookId = New-N8nCacheWebhook -ApiUrl $N8nApiUrl -ApiKey $ApiKey
    
    if (-not $webhookId) {
        Write-Log "Ã‰chec de la crÃ©ation du webhook n8n." -Level "ERROR"
        return $false
    }
    
    # CrÃ©er le workflow n8n
    $workflowId = New-N8nCacheWorkflow -ApiUrl $N8nApiUrl -ApiKey $ApiKey -WebhookId $webhookId
    
    if (-not $workflowId) {
        Write-Log "Ã‰chec de la crÃ©ation du workflow n8n." -Level "ERROR"
        return $false
    }
    
    # CrÃ©er l'exemple d'utilisation
    $exampleCreated = New-CacheUsageExample -N8nApiUrl $N8nApiUrl -ApiKey $ApiKey
    
    if (-not $exampleCreated) {
        Write-Log "Ã‰chec de la crÃ©ation de l'exemple d'utilisation." -Level "WARNING"
    }
    
    # Enregistrer le hook n8n
    $hookRegistered = Register-N8nCacheHook -N8nApiUrl $N8nApiUrl -ApiKey $ApiKey
    
    if (-not $hookRegistered) {
        Write-Log "Ã‰chec de l'enregistrement du hook n8n." -Level "WARNING"
    }
    
    Write-Log "Initialisation terminÃ©e." -Level "SUCCESS"
    Write-Log "Cache prÃ©dictif pour n8n configurÃ© avec succÃ¨s." -Level "SUCCESS"
    Write-Log "URL de l'API n8n: $N8nApiUrl" -Level "INFO"
    Write-Log "Chemin du cache: $CachePath" -Level "INFO"
    Write-Log "Taille maximale du cache: $MaxCacheSizeMB MB" -Level "INFO"
    Write-Log "DurÃ©e de vie par dÃ©faut: $DefaultTTL secondes" -Level "INFO"
    Write-Log "ID du webhook: $webhookId" -Level "INFO"
    Write-Log "ID du workflow: $workflowId" -Level "INFO"
    
    return $true
}

# ExÃ©cuter la fonction principale
Initialize-N8nPredictiveCache -N8nApiUrl $N8nApiUrl -ApiKey $ApiKey -CachePath $CachePath -MaxCacheSizeMB $MaxCacheSizeMB -DefaultTTL $DefaultTTL
