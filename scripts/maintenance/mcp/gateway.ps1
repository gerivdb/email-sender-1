# Script PowerShell pour simuler le MCP Gateway

param (
    [string]$command,
    [string]$config,
    [string]$mode
)

# Verifier les arguments
if ($command -ne "start") {
    Write-Host "Usage: gateway.ps1 start --config <config_file> mcp-stdio"
    exit 1
}

if ($mode -ne "mcp-stdio") {
    Write-Host "Mode non supporte. Utilisez 'mcp-stdio'."
    exit 1
}

# Definition des outils disponibles
$databaseTools = @(
    @{
        Name = "get_customers"
        Description = "Recupere la liste des clients"
        Query = "SELECT * FROM customers LIMIT :limit OFFSET :offset"
        Parameters = @{
            limit = "Nombre maximum de resultats a retourner"
            offset = "Nombre de resultats a ignorer"
        }
    },
    @{
        Name = "get_orders"
        Description = "Recupere la liste des commandes"
        Query = "SELECT * FROM orders LIMIT :limit OFFSET :offset"
        Parameters = @{
            limit = "Nombre maximum de resultats a retourner"
            offset = "Nombre de resultats a ignorer"
        }
    },
    @{
        Name = "search_products"
        Description = "Recherche des produits par nom"
        Query = "SELECT * FROM products WHERE name LIKE :name LIMIT :limit"
        Parameters = @{
            name = "Nom du produit a rechercher"
            limit = "Nombre maximum de resultats a retourner"
        }
    }
)

# Fonction pour gerer la requete list_tools
function Handle-ListTools {
    $tools = @()
    foreach ($dbTool in $databaseTools) {
        $properties = @{}
        foreach ($paramName in $dbTool.Parameters.Keys) {
            $properties[$paramName] = @{
                type = "string"
                description = $dbTool.Parameters[$paramName]
            }
        }
        
        $schema = @{
            type = "object"
            properties = $properties
            required = @()
        }
        
        $tools += @{
            name = $dbTool.Name
            description = $dbTool.Description
            schema = $schema
        }
    }
    
    return @{
        type = "list_tools_response"
        content = @{
            tools = $tools
        }
    }
}

# Fonction pour gerer la requete tool_call
function Handle-ToolCall {
    param (
        [PSCustomObject]$content
    )
    
    $toolName = $content.tool_name
    $parameters = $content.parameters
    
    # Rechercher l'outil
    $dbTool = $null
    foreach ($tool in $databaseTools) {
        if ($tool.Name -eq $toolName) {
            $dbTool = $tool
            break
        }
    }
    
    if ($null -eq $dbTool) {
        return @{
            type = "error"
            content = "Outil non trouve: $toolName"
        }
    }
    
    # Simuler l'execution de la requete
    $query = $dbTool.Query
    foreach ($paramName in $parameters.Keys) {
        $placeholder = ":$paramName"
        $query = $query.Replace($placeholder, $parameters[$paramName])
    }
    
    # Simuler des resultats
    $result = @()
    switch ($dbTool.Name) {
        "get_customers" {
            $result = @(
                @{ id = 1; name = "Jean Dupont"; email = "jean.dupont@example.com" },
                @{ id = 2; name = "Marie Martin"; email = "marie.martin@example.com" },
                @{ id = 3; name = "Pierre Durand"; email = "pierre.durand@example.com" }
            )
        }
        "get_orders" {
            $result = @(
                @{ id = 101; customer_id = 1; amount = 150.50; date = "2025-04-01" },
                @{ id = 102; customer_id = 2; amount = 75.20; date = "2025-04-02" },
                @{ id = 103; customer_id = 1; amount = 200.00; date = "2025-04-03" }
            )
        }
        "search_products" {
            $result = @(
                @{ id = 201; name = "Ordinateur portable"; price = 999.99; stock = 10 },
                @{ id = 202; name = "Ordinateur de bureau"; price = 799.99; stock = 5 },
                @{ id = 203; name = "Ordinateur tout-en-un"; price = 1299.99; stock = 3 }
            )
        }
        default {
            $result = @()
        }
    }
    
    return @{
        type = "tool_call_response"
        content = @{
            result = @{
                query = $query
                results = $result
            }
        }
    }
}

# Boucle principale
try {
    while ($true) {
        # Lire l'entree JSON
        $inputLine = [Console]::In.ReadLine()
        if ([string]::IsNullOrEmpty($inputLine)) {
            break
        }
        
        # Decoder la requete JSON
        $request = $inputLine | ConvertFrom-Json
        
        # Traiter la requete
        $response = $null
        switch ($request.type) {
            "list_tools" {
                $response = Handle-ListTools
            }
            "tool_call" {
                $response = Handle-ToolCall -content $request.content
            }
            default {
                $response = @{
                    type = "error"
                    content = "Type de requete non supporte: $($request.type)"
                }
            }
        }
        
        # Encoder et envoyer la reponse
        $responseJson = $response | ConvertTo-Json -Depth 10
        Write-Output $responseJson
    }
} catch {
    Write-Error "Erreur: $_"
    exit 1
}

