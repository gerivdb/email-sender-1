#Requires -Version 5.1
<#
.SYNOPSIS
    Initialise le cache prédictif pour n8n.
.DESCRIPTION
    Ce script configure et initialise le cache prédictif pour n8n,
    améliorant les performances des workflows en anticipant les besoins en données.
.PARAMETER N8nApiUrl
    URL de l'API n8n (par défaut: http://localhost:5678/api/v1).
.PARAMETER ApiKey
    Clé API pour l'authentification n8n.
.PARAMETER CachePath
    Chemin du dossier de cache.
.PARAMETER MaxCacheSizeMB
    Taille maximale du cache en MB (par défaut: 100).
.PARAMETER DefaultTTL
    Durée de vie par défaut des entrées du cache en secondes (par défaut: 3600).
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

# Importer le module de cache prédictif
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\PredictiveCache.psm1"

if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Module de cache prédictif introuvable: $modulePath"
    exit 1
}

Import-Module $modulePath -Force

# Fonction pour écrire dans le journal
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

# Fonction pour tester la connexion à n8n
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
            Write-Log "Connexion à n8n établie. Version: $($response.version)" -Level "SUCCESS"
            return $true
        }
        else {
            Write-Log "n8n n'est pas disponible ou en bonne santé." -Level "ERROR"
            return $false
        }
    }
    catch {
        Write-Log "Erreur lors de la connexion à n8n: $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour créer un webhook n8n pour le cache prédictif
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
        
        # Vérifier si le webhook existe déjà
        $webhooks = Invoke-RestMethod -Uri "$ApiUrl/webhooks" -Method Get -Headers $headers
        
        $existingWebhook = $webhooks | Where-Object { $_.name -eq "predictive-cache-hook" }
        
        if ($existingWebhook) {
            Write-Log "Le webhook pour le cache prédictif existe déjà." -Level "INFO"
            return $existingWebhook.id
        }
        
        # Créer un nouveau webhook
        $webhookData = @{
            name = "predictive-cache-hook"
            httpMethod = "POST"
            path = "predictive-cache/hook"
            webhookPath = "predictive-cache/hook"
            responseMode = "lastNode"
            responseCode = 200
        }
        
        $response = Invoke-RestMethod -Uri "$ApiUrl/webhooks" -Method Post -Headers $headers -Body ($webhookData | ConvertTo-Json)
        
        Write-Log "Webhook pour le cache prédictif créé avec succès." -Level "SUCCESS"
        return $response.id
    }
    catch {
        Write-Log "Erreur lors de la création du webhook: $_" -Level "ERROR"
        return $null
    }
}

# Fonction pour créer un workflow n8n pour le cache prédictif
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
        
        # Vérifier si le workflow existe déjà
        $workflows = Invoke-RestMethod -Uri "$ApiUrl/workflows" -Method Get -Headers $headers
        
        $existingWorkflow = $workflows | Where-Object { $_.name -eq "Predictive Cache Manager" }
        
        if ($existingWorkflow) {
            Write-Log "Le workflow pour le cache prédictif existe déjà." -Level "INFO"
            return $existingWorkflow.id
        }
        
        # Créer un nouveau workflow
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
        
        Write-Log "Workflow pour le cache prédictif créé avec succès." -Level "SUCCESS"
        return $response.id
    }
    catch {
        Write-Log "Erreur lors de la création du workflow: $_" -Level "ERROR"
        return $null
    }
}

# Fonction pour créer un exemple d'utilisation du cache prédictif
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
    Exemple d'utilisation du cache prédictif pour n8n.
.DESCRIPTION
    Ce script montre comment utiliser le cache prédictif pour améliorer
    les performances des workflows n8n.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: $(Get-Date -Format "yyyy-MM-dd")
#>

# Importer le module de cache prédictif
Import-Module "$PSScriptRoot\..\..\modules\PredictiveCache.psm1" -Force

# Initialiser le cache prédictif
Initialize-PredictiveCache -Enabled $true -MaxCacheSize 100MB -DefaultTTL 3600

# Fonction pour appeler l'API du cache prédictif
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
        Write-Error "Erreur lors de l'appel au cache prédictif: $_"
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
Write-Host "Résultat: $($result | ConvertTo-Json)" -ForegroundColor Green

# Exemple 2: Récupérer une valeur du cache
Write-Host "`nExemple 2: Récupérer une valeur du cache" -ForegroundColor Magenta
$result = Invoke-PredictiveCache -Operation "get" -Key "user:john.doe" -WorkflowId "user-workflow" -NodeId "get-user"
Write-Host "Résultat: $($result | ConvertTo-Json)" -ForegroundColor Green

# Exemple 3: Mettre en cache plusieurs valeurs liées
Write-Host "`nExemple 3: Mettre en cache plusieurs valeurs liées" -ForegroundColor Magenta
for ($i = 1; $i -le 5; $i++) {
    $data = @{
        id = $i
        name = "Product $i"
        price = $i * 10
    }
    $result = Invoke-PredictiveCache -Operation "set" -Key "product:$i" -Value $data -WorkflowId "product-workflow" -NodeId "get-product"
    Write-Host "Produit $i mis en cache" -ForegroundColor Green
}

# Exemple 4: Récupérer des valeurs en séquence (pour construire des prédictions)
Write-Host "`nExemple 4: Récupérer des valeurs en séquence" -ForegroundColor Magenta
for ($i = 1; $i -le 5; $i++) {
    $result = Invoke-PredictiveCache -Operation "get" -Key "product:$i" -WorkflowId "product-workflow" -NodeId "get-product"
    Write-Host "Produit $i récupéré: $($result.value.name) - $($result.value.price)€" -ForegroundColor Green
}

# Exemple 5: Vérifier les prédictions
Write-Host "`nExemple 5: Vérifier les prédictions" -ForegroundColor Magenta
$result = Invoke-PredictiveCache -Operation "get" -Key "product:1" -WorkflowId "product-workflow" -NodeId "get-product"
Write-Host "Résultat: $($result | ConvertTo-Json)" -ForegroundColor Green

if ($result.predictions) {
    Write-Host "Prédictions:" -ForegroundColor Yellow
    foreach ($prediction in $result.predictions) {
        Write-Host "- $($prediction.key) (Score: $($prediction.score))" -ForegroundColor Yellow
    }
}

# Exemple 6: Supprimer une valeur du cache
Write-Host "`nExemple 6: Supprimer une valeur du cache" -ForegroundColor Magenta
$result = Invoke-PredictiveCache -Operation "remove" -Key "user:john.doe"
Write-Host "Résultat: $($result | ConvertTo-Json)" -ForegroundColor Green
"@
    
    try {
        $exampleContent | Out-File -FilePath $examplePath -Encoding utf8
        Write-Log "Exemple d'utilisation créé: $examplePath" -Level "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Erreur lors de la création de l'exemple d'utilisation: $_" -Level "ERROR"
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
    
    Write-Log "Initialisation du cache prédictif pour n8n..." -Level "TITLE"
    
    # Initialiser le module de cache prédictif
    Initialize-PredictiveCache -Enabled $true -CachePath $CachePath -MaxCacheSize ($MaxCacheSizeMB * 1MB) -DefaultTTL $DefaultTTL
    
    # Tester la connexion à n8n
    $connected = Test-N8nConnection -ApiUrl $N8nApiUrl -ApiKey $ApiKey
    
    if (-not $connected) {
        Write-Log "Impossible de se connecter à n8n. Vérifiez l'URL et la clé API." -Level "ERROR"
        return $false
    }
    
    # Créer le webhook n8n
    $webhookId = New-N8nCacheWebhook -ApiUrl $N8nApiUrl -ApiKey $ApiKey
    
    if (-not $webhookId) {
        Write-Log "Échec de la création du webhook n8n." -Level "ERROR"
        return $false
    }
    
    # Créer le workflow n8n
    $workflowId = New-N8nCacheWorkflow -ApiUrl $N8nApiUrl -ApiKey $ApiKey -WebhookId $webhookId
    
    if (-not $workflowId) {
        Write-Log "Échec de la création du workflow n8n." -Level "ERROR"
        return $false
    }
    
    # Créer l'exemple d'utilisation
    $exampleCreated = New-CacheUsageExample -N8nApiUrl $N8nApiUrl -ApiKey $ApiKey
    
    if (-not $exampleCreated) {
        Write-Log "Échec de la création de l'exemple d'utilisation." -Level "WARNING"
    }
    
    # Enregistrer le hook n8n
    $hookRegistered = Register-N8nCacheHook -N8nApiUrl $N8nApiUrl -ApiKey $ApiKey
    
    if (-not $hookRegistered) {
        Write-Log "Échec de l'enregistrement du hook n8n." -Level "WARNING"
    }
    
    Write-Log "Initialisation terminée." -Level "SUCCESS"
    Write-Log "Cache prédictif pour n8n configuré avec succès." -Level "SUCCESS"
    Write-Log "URL de l'API n8n: $N8nApiUrl" -Level "INFO"
    Write-Log "Chemin du cache: $CachePath" -Level "INFO"
    Write-Log "Taille maximale du cache: $MaxCacheSizeMB MB" -Level "INFO"
    Write-Log "Durée de vie par défaut: $DefaultTTL secondes" -Level "INFO"
    Write-Log "ID du webhook: $webhookId" -Level "INFO"
    Write-Log "ID du workflow: $workflowId" -Level "INFO"
    
    return $true
}

# Exécuter la fonction principale
Initialize-N8nPredictiveCache -N8nApiUrl $N8nApiUrl -ApiKey $ApiKey -CachePath $CachePath -MaxCacheSizeMB $MaxCacheSizeMB -DefaultTTL $DefaultTTL
