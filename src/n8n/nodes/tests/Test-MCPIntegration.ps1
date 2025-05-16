# Script de test pour l'intégration MCP avec n8n
# Ce script simule des requêtes vers un serveur MCP pour tester les nœuds MCP Client et MCP Memory

# Configuration
$baseUrl = "http://localhost:3000"
$apiKey = "test-api-key"

# Fonction pour afficher un message d'information
function Write-Info {
    param (
        [string]$Message
    )
    
    Write-Host $Message -ForegroundColor Cyan
}

# Fonction pour afficher un message de succès
function Write-Success {
    param (
        [string]$Message
    )
    
    Write-Host $Message -ForegroundColor Green
}

# Fonction pour afficher un message d'erreur
function Write-Error {
    param (
        [string]$Message
    )
    
    Write-Host "ERREUR: $Message" -ForegroundColor Red
}

# Fonction pour simuler une requête HTTP vers le serveur MCP
function Invoke-MCPRequest {
    param (
        [string]$Method,
        [string]$Endpoint,
        [hashtable]$Headers = @{},
        [object]$Body = $null
    )
    
    # Ajouter l'en-tête d'autorisation
    $Headers["Authorization"] = "Bearer $apiKey"
    
    # Ajouter l'en-tête Content-Type pour les requêtes POST et PUT
    if ($Method -in @("POST", "PUT")) {
        $Headers["Content-Type"] = "application/json"
    }
    
    # Construire l'URL complète
    $url = "$baseUrl$Endpoint"
    
    # Convertir le corps en JSON si nécessaire
    $bodyJson = if ($Body) { $Body | ConvertTo-Json -Depth 10 } else { $null }
    
    try {
        # Effectuer la requête HTTP
        $response = Invoke-RestMethod -Method $Method -Uri $url -Headers $Headers -Body $bodyJson -ErrorAction Stop
        return $response
    }
    catch {
        Write-Error "La requête a échoué: $_"
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
            Write-Error "Code de statut: $statusCode"
            
            # Essayer de lire le corps de la réponse d'erreur
            try {
                $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                $responseBody = $reader.ReadToEnd()
                Write-Error "Corps de la réponse: $responseBody"
                $reader.Close()
            }
            catch {
                Write-Error "Impossible de lire le corps de la réponse d'erreur: $_"
            }
        }
        return $null
    }
}

# Fonction pour simuler une commande MCP en ligne de commande
function Invoke-MCPCommand {
    param (
        [string]$Operation,
        [hashtable]$Parameters = @{}
    )
    
    # Créer l'objet de requête
    $request = @{
        operation = $Operation
    } + $Parameters
    
    # Convertir la requête en JSON
    $requestJson = $request | ConvertTo-Json -Depth 10
    
    # Chemin vers le script du serveur MCP en ligne de commande
    $serverPath = Join-Path $PSScriptRoot "mcp-cmd-server.js"
    
    try {
        # Exécuter la commande et capturer la sortie
        $output = $requestJson | node $serverPath
        
        # Analyser la sortie JSON
        $response = $output | ConvertFrom-Json
        return $response
    }
    catch {
        Write-Error "La commande a échoué: $_"
        return $null
    }
}

# Fonction pour tester le nœud MCP Client (HTTP)
function Test-MCPClientHTTP {
    Write-Info "=== Test du nœud MCP Client (HTTP) ==="
    
    # Test de l'opération getContext
    Write-Info "`n1. Test de l'opération getContext"
    $contextResponse = Invoke-MCPRequest -Method "POST" -Endpoint "/api/context" -Body @{
        prompt = "Générer un email pour Jean Dupont"
        sources = @("notion", "calendar", "memory")
    }
    
    if ($contextResponse) {
        Write-Success "Réponse: $($contextResponse | ConvertTo-Json -Depth 10)"
    }
    
    # Test de l'opération listTools
    Write-Info "`n2. Test de l'opération listTools"
    $toolsResponse = Invoke-MCPRequest -Method "GET" -Endpoint "/api/tools"
    
    if ($toolsResponse) {
        Write-Success "Réponse: $($toolsResponse | ConvertTo-Json -Depth 10)"
    }
    
    # Test de l'opération executeTool
    Write-Info "`n3. Test de l'opération executeTool"
    $executeToolResponse = Invoke-MCPRequest -Method "POST" -Endpoint "/api/tools/search_documentation" -Body @{
        query = "Comment utiliser MCP avec n8n"
    }
    
    if ($executeToolResponse) {
        Write-Success "Réponse: $($executeToolResponse | ConvertTo-Json -Depth 10)"
    }
    
    Write-Success "`nTous les tests du nœud MCP Client (HTTP) ont été exécutés!"
}

# Fonction pour tester le nœud MCP Memory (HTTP)
function Test-MCPMemoryHTTP {
    Write-Info "`n=== Test du nœud MCP Memory (HTTP) ==="
    
    # Test de l'opération addMemory
    Write-Info "`n1. Test de l'opération addMemory"
    $addMemoryResponse = Invoke-MCPRequest -Method "POST" -Endpoint "/api/memory" -Body @{
        content = "Ceci est une mémoire de test pour n8n"
        metadata = @{
            category = "test"
            tags = @("n8n", "mcp", "test")
        }
    }
    
    if ($addMemoryResponse) {
        Write-Success "Réponse: $($addMemoryResponse | ConvertTo-Json -Depth 10)"
        $memoryId = $addMemoryResponse.memory_id
        
        # Test de l'opération getMemory
        Write-Info "`n2. Test de l'opération getMemory"
        $getMemoryResponse = Invoke-MCPRequest -Method "GET" -Endpoint "/api/memory/$memoryId"
        
        if ($getMemoryResponse) {
            Write-Success "Réponse: $($getMemoryResponse | ConvertTo-Json -Depth 10)"
        }
        
        # Test de l'opération searchMemories
        Write-Info "`n3. Test de l'opération searchMemories"
        $searchMemoriesResponse = Invoke-MCPRequest -Method "POST" -Endpoint "/api/memory/search" -Body @{
            query = "test"
            metadata = @{
                category = "test"
            }
            limit = 10
        }
        
        if ($searchMemoriesResponse) {
            Write-Success "Réponse: $($searchMemoriesResponse | ConvertTo-Json -Depth 10)"
        }
    }
    
    Write-Success "`nTous les tests du nœud MCP Memory (HTTP) ont été exécutés!"
}

# Fonction pour tester le nœud MCP Client (ligne de commande)
function Test-MCPClientCMD {
    Write-Info "`n=== Test du nœud MCP Client (ligne de commande) ==="
    
    # Test de l'opération getContext
    Write-Info "`n1. Test de l'opération getContext"
    $contextResponse = Invoke-MCPCommand -Operation "getContext" -Parameters @{
        prompt = "Générer un email pour Jean Dupont"
        sources = @("notion", "calendar", "memory")
    }
    
    if ($contextResponse) {
        Write-Success "Réponse: $($contextResponse | ConvertTo-Json -Depth 10)"
    }
    
    # Test de l'opération listTools
    Write-Info "`n2. Test de l'opération listTools"
    $toolsResponse = Invoke-MCPCommand -Operation "listTools"
    
    if ($toolsResponse) {
        Write-Success "Réponse: $($toolsResponse | ConvertTo-Json -Depth 10)"
    }
    
    # Test de l'opération executeTool
    Write-Info "`n3. Test de l'opération executeTool"
    $executeToolResponse = Invoke-MCPCommand -Operation "executeTool" -Parameters @{
        toolName = "search_documentation"
        parameters = @{
            query = "Comment utiliser MCP avec n8n"
        }
    }
    
    if ($executeToolResponse) {
        Write-Success "Réponse: $($executeToolResponse | ConvertTo-Json -Depth 10)"
    }
    
    Write-Success "`nTous les tests du nœud MCP Client (ligne de commande) ont été exécutés!"
}

# Fonction pour tester le nœud MCP Memory (ligne de commande)
function Test-MCPMemoryCMD {
    Write-Info "`n=== Test du nœud MCP Memory (ligne de commande) ==="
    
    # Test de l'opération addMemory
    Write-Info "`n1. Test de l'opération addMemory"
    $addMemoryResponse = Invoke-MCPCommand -Operation "addMemory" -Parameters @{
        content = "Ceci est une mémoire de test pour n8n"
        metadata = @{
            category = "test"
            tags = @("n8n", "mcp", "test")
        }
    }
    
    if ($addMemoryResponse) {
        Write-Success "Réponse: $($addMemoryResponse | ConvertTo-Json -Depth 10)"
        $memoryId = $addMemoryResponse.memory_id
        
        # Test de l'opération getMemory
        Write-Info "`n2. Test de l'opération getMemory"
        $getMemoryResponse = Invoke-MCPCommand -Operation "getMemory" -Parameters @{
            memoryId = $memoryId
        }
        
        if ($getMemoryResponse) {
            Write-Success "Réponse: $($getMemoryResponse | ConvertTo-Json -Depth 10)"
        }
        
        # Test de l'opération searchMemories
        Write-Info "`n3. Test de l'opération searchMemories"
        $searchMemoriesResponse = Invoke-MCPCommand -Operation "searchMemories" -Parameters @{
            query = "test"
            metadata = @{
                category = "test"
            }
            limit = 10
        }
        
        if ($searchMemoriesResponse) {
            Write-Success "Réponse: $($searchMemoriesResponse | ConvertTo-Json -Depth 10)"
        }
    }
    
    Write-Success "`nTous les tests du nœud MCP Memory (ligne de commande) ont été exécutés!"
}

# Fonction principale pour exécuter tous les tests
function Test-MCPIntegration {
    Write-Info "Démarrage des tests pour l'intégration MCP avec n8n...`n"
    
    # Vérifier si le serveur HTTP est accessible
    try {
        $null = Invoke-RestMethod -Uri $baseUrl -Method GET -ErrorAction Stop
        Write-Success "Serveur HTTP accessible à $baseUrl"
        
        # Exécuter les tests HTTP
        Test-MCPClientHTTP
        Test-MCPMemoryHTTP
    }
    catch {
        Write-Error "Impossible de se connecter au serveur HTTP à $baseUrl"
        Write-Info "Les tests HTTP seront ignorés."
    }
    
    # Exécuter les tests en ligne de commande
    Test-MCPClientCMD
    Test-MCPMemoryCMD
    
    Write-Success "`nTous les tests ont été exécutés!"
}

# Exécuter les tests
Test-MCPIntegration
