# Documentation de l'API MCP

Ce document décrit l'API du serveur MCP et comment l'utiliser.

## Vue d'ensemble

Le serveur MCP (Model Context Protocol) est un serveur FastAPI qui expose une API REST pour exécuter des outils. Les outils sont des fonctions qui peuvent être appelées à distance via l'API.

## Endpoints

### GET /

Renvoie un message de bienvenue.

#### Réponse

```json
{
  "message": "Welcome to the MCP Server"
}
```

### GET /tools

Renvoie la liste des outils disponibles sur le serveur.

#### Réponse

```json
[
  {
    "name": "add",
    "description": "Additionne deux nombres",
    "parameters": {
      "a": "int",
      "b": "int"
    },
    "returns": "int"
  },
  {
    "name": "multiply",
    "description": "Multiplie deux nombres",
    "parameters": {
      "a": "int",
      "b": "int"
    },
    "returns": "int"
  },
  {
    "name": "get_system_info",
    "description": "Retourne des informations sur le système",
    "parameters": {},
    "returns": "dict"
  }
]
```

### POST /tools/{tool_name}

Appelle un outil avec les paramètres spécifiés.

#### Paramètres

- **tool_name** (string, path) : Le nom de l'outil à appeler.
- **request** (object, body) : Les paramètres à passer à l'outil.

#### Exemple de requête pour l'outil "add"

```json
{
  "a": 2,
  "b": 3
}
```

#### Exemple de réponse pour l'outil "add"

```json
{
  "result": 5
}
```

#### Exemple de requête pour l'outil "multiply"

```json
{
  "a": 4,
  "b": 5
}
```

#### Exemple de réponse pour l'outil "multiply"

```json
{
  "result": 20
}
```

#### Exemple de requête pour l'outil "get_system_info"

```json
{}
```

#### Exemple de réponse pour l'outil "get_system_info"

```json
{
  "result": {
    "os": "Windows",
    "os_version": "10.0.19042",
    "python_version": "3.9.7",
    "hostname": "DESKTOP-1234567",
    "cpu_count": 8
  }
}
```

## Codes d'erreur

- **400 Bad Request** : La requête est mal formée.
- **404 Not Found** : L'outil demandé n'existe pas.
- **422 Unprocessable Entity** : Les paramètres de la requête sont invalides.
- **500 Internal Server Error** : Une erreur est survenue lors de l'exécution de l'outil.

## Exemples d'utilisation

### Python

```python
import requests

def call_mcp_tool(server_url, tool_name, parameters=None):
    """
    Appelle un outil sur le serveur MCP.
    
    Args:
        server_url (str): L'URL du serveur MCP.
        tool_name (str): Le nom de l'outil à appeler.
        parameters (dict, optional): Les paramètres à passer à l'outil. Defaults to None.
        
    Returns:
        dict: Le résultat de l'appel à l'outil.
        
    Raises:
        Exception: Si une erreur survient lors de l'appel à l'outil.
    """
    if parameters is None:
        parameters = {}
    
    try:
        # Construire l'URL de l'outil
        tool_url = f"{server_url}/tools/{tool_name}"
        
        # Appeler l'outil
        response = requests.post(tool_url, json=parameters, headers={"Accept": "application/json"})
        
        # Vérifier le code de statut
        response.raise_for_status()
        
        # Renvoyer le résultat
        return response.json()
    except Exception as e:
        raise Exception(f"Error calling tool {tool_name}: {str(e)}")

# Exemple d'utilisation
server_url = "http://localhost:8000"

# Appeler l'outil "add"
result = call_mcp_tool(server_url, "add", {"a": 2, "b": 3})
print(f"2 + 3 = {result['result']}")

# Appeler l'outil "multiply"
result = call_mcp_tool(server_url, "multiply", {"a": 4, "b": 5})
print(f"4 * 5 = {result['result']}")

# Appeler l'outil "get_system_info"
result = call_mcp_tool(server_url, "get_system_info")
print(f"System info: {result['result']}")
```

### PowerShell

```powershell
function Initialize-MCPConnection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ServerUrl
    )
    
    $script:MCPServerUrl = $ServerUrl
    Write-Verbose "Connexion au serveur MCP initialisée à l'adresse $ServerUrl"
}

function Get-MCPTools {
    [CmdletBinding()]
    param ()
    
    try {
        $url = "$script:MCPServerUrl/tools"
        Write-Verbose "Récupération des outils depuis $url"
        
        $response = Invoke-RestMethod -Uri $url -Method Get -Headers @{
            "Accept" = "application/json"
        }
        
        return $response
    }
    catch {
        Write-Error "Erreur lors de la récupération des outils: $_"
    }
}

function Invoke-MCPTool {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ToolName,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{}
    )
    
    try {
        $url = "$script:MCPServerUrl/tools/$ToolName"
        Write-Verbose "Appel de l'outil $ToolName depuis $url avec les paramètres $($Parameters | ConvertTo-Json -Compress)"
        
        $body = $Parameters | ConvertTo-Json -Compress
        $response = Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/json" -Headers @{
            "Accept" = "application/json"
        }
        
        return $response
    }
    catch {
        Write-Error "Erreur lors de l'appel a l'outil ${ToolName}: $($_.Exception.Message)"
    }
}

# Exemple d'utilisation
Initialize-MCPConnection -ServerUrl "http://localhost:8000"

# Récupérer la liste des outils
$tools = Get-MCPTools
$tools | Format-Table -AutoSize

# Appeler l'outil "add"
$result = Invoke-MCPTool -ToolName "add" -Parameters @{a = 2; b = 3}
Write-Host "2 + 3 = $($result.result)"

# Appeler l'outil "multiply"
$result = Invoke-MCPTool -ToolName "multiply" -Parameters @{a = 4; b = 5}
Write-Host "4 * 5 = $($result.result)"

# Appeler l'outil "get_system_info"
$result = Invoke-MCPTool -ToolName "get_system_info"
$result.result | Format-Table -AutoSize
```

## Authentification

L'API ne nécessite pas d'authentification pour le moment. Une authentification sera ajoutée dans une version future.

## Limites

- L'API est limitée à 100 requêtes par minute par adresse IP.
- La taille maximale des requêtes est de 1 Mo.
- La taille maximale des réponses est de 10 Mo.

## Versions

- **v1.0.0** : Version initiale de l'API.

## Prochaines fonctionnalités

- Authentification
- Autorisation basée sur les rôles
- Pagination pour les grandes collections de données
- Compression des réponses
- Streaming pour les réponses volumineuses
- WebSockets pour les communications bidirectionnelles
- GraphQL pour les requêtes complexes
