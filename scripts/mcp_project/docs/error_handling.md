# Gestion des erreurs dans le projet MCP

Ce document décrit la stratégie de gestion des erreurs dans le projet MCP, tant pour le serveur que pour les clients Python et PowerShell.

## Principes généraux

1. **Transparence** : Les erreurs doivent être claires et informatives pour faciliter le débogage.
2. **Robustesse** : Le système doit être capable de gérer les erreurs sans planter.
3. **Traçabilité** : Toutes les erreurs doivent être journalisées pour permettre une analyse ultérieure.
4. **Récupération** : Le système doit être capable de récupérer après une erreur lorsque c'est possible.

## Serveur FastAPI

### Types d'erreurs

1. **Erreurs de validation** : Erreurs liées à la validation des données d'entrée.
2. **Erreurs d'exécution** : Erreurs survenant lors de l'exécution des outils.
3. **Erreurs de ressource** : Erreurs liées à l'indisponibilité des ressources.
4. **Erreurs de route** : Erreurs liées à des routes inexistantes.

### Gestion des erreurs

- **Erreurs de validation** : FastAPI gère automatiquement les erreurs de validation et renvoie un code HTTP 422 avec des détails sur l'erreur.
- **Erreurs d'exécution** : Les erreurs d'exécution sont capturées dans un bloc try/except et renvoyées avec un code HTTP 500 et un message d'erreur.
- **Erreurs de ressource** : Les erreurs de ressource sont renvoyées avec un code HTTP 503 et un message d'erreur.
- **Erreurs de route** : FastAPI gère automatiquement les erreurs de route et renvoie un code HTTP 404.

### Exemple de code

```python
@app.post("/tools/{tool_name}")
async def call_tool(tool_name: str, request: dict = Body(...)):
    try:
        # Vérifier si l'outil existe
        if tool_name not in tools:
            raise HTTPException(status_code=404, detail=f"Tool {tool_name} not found")
        
        # Appeler l'outil
        result = await tools[tool_name](request)
        
        # Renvoyer le résultat
        return result
    except ValidationError as e:
        # Erreur de validation
        raise HTTPException(status_code=422, detail=str(e))
    except Exception as e:
        # Erreur d'exécution
        logger.error(f"Error calling tool {tool_name}: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error calling tool {tool_name}: {str(e)}")
```

## Client Python

### Types d'erreurs

1. **Erreurs de connexion** : Erreurs liées à la connexion au serveur MCP.
2. **Erreurs de validation** : Erreurs liées à la validation des données d'entrée.
3. **Erreurs d'exécution** : Erreurs survenant lors de l'exécution des outils.
4. **Erreurs de ressource** : Erreurs liées à l'indisponibilité des ressources.

### Gestion des erreurs

- **Erreurs de connexion** : Les erreurs de connexion sont capturées et une exception est levée avec un message d'erreur.
- **Erreurs de validation** : Les erreurs de validation sont capturées et une exception est levée avec un message d'erreur.
- **Erreurs d'exécution** : Les erreurs d'exécution sont capturées et une exception est levée avec un message d'erreur.
- **Erreurs de ressource** : Les erreurs de ressource sont capturées et une exception est levée avec un message d'erreur.

### Exemple de code

```python
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
    except requests.exceptions.ConnectionError as e:
        # Erreur de connexion
        raise Exception(f"Error connecting to MCP server: {str(e)}")
    except requests.exceptions.HTTPError as e:
        # Erreur HTTP
        raise Exception(f"HTTP error calling tool {tool_name}: {str(e)}")
    except requests.exceptions.Timeout as e:
        # Erreur de timeout
        raise Exception(f"Timeout calling tool {tool_name}: {str(e)}")
    except requests.exceptions.RequestException as e:
        # Erreur de requête
        raise Exception(f"Error calling tool {tool_name}: {str(e)}")
    except Exception as e:
        # Erreur générale
        raise Exception(f"Error calling tool {tool_name}: {str(e)}")
```

## Module PowerShell

### Types d'erreurs

1. **Erreurs de connexion** : Erreurs liées à la connexion au serveur MCP.
2. **Erreurs de validation** : Erreurs liées à la validation des données d'entrée.
3. **Erreurs d'exécution** : Erreurs survenant lors de l'exécution des outils.
4. **Erreurs de ressource** : Erreurs liées à l'indisponibilité des ressources.

### Gestion des erreurs

- **Erreurs de connexion** : Les erreurs de connexion sont capturées et Write-Error est appelé avec un message d'erreur.
- **Erreurs de validation** : Les erreurs de validation sont capturées et Write-Error est appelé avec un message d'erreur.
- **Erreurs d'exécution** : Les erreurs d'exécution sont capturées et Write-Error est appelé avec un message d'erreur.
- **Erreurs de ressource** : Les erreurs de ressource sont capturées et Write-Error est appelé avec un message d'erreur.

### Exemple de code

```powershell
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
```

## Tests unitaires

### Types d'erreurs

1. **Erreurs de test** : Erreurs survenant lors de l'exécution des tests.
2. **Erreurs de mock** : Erreurs liées à la configuration des mocks.
3. **Erreurs d'assertion** : Erreurs liées aux assertions des tests.

### Gestion des erreurs

- **Erreurs de test** : Les erreurs de test sont capturées et affichées avec des détails sur l'erreur.
- **Erreurs de mock** : Les erreurs de mock sont capturées et affichées avec des détails sur l'erreur.
- **Erreurs d'assertion** : Les erreurs d'assertion sont capturées et affichées avec des détails sur l'erreur.

### Exemple de code

```powershell
# Test pour Invoke-MCPTool avec un outil inexistant
It "Should handle errors correctly" {
    # Appeler la fonction et vérifier qu'elle écrit une erreur
    Mock Write-Error { } -Verifiable
    
    # Appeler la fonction
    Invoke-MCPTool -ToolName "nonexistent" -Parameters @{}
    
    # Vérifier que Write-Error a été appelé
    Should -Invoke Write-Error -Times 1
    
    # Vérifier que Invoke-RestMethod a été appelé correctement
    Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
        $Uri -eq "http://localhost:8000/tools/nonexistent" -and
        $Method -eq "Post" -and
        $ContentType -eq "application/json" -and
        $Headers.Accept -eq "application/json"
    }
}
```

## Configuration de la gestion des erreurs

La configuration de la gestion des erreurs est définie dans le fichier `config.json` :

```json
"error_handling": {
    "log_errors": true,
    "show_traceback": false,
    "retry_on_connection_error": true,
    "max_retries": 3,
    "retry_delay": 1
}
```

- **log_errors** : Indique si les erreurs doivent être journalisées.
- **show_traceback** : Indique si la trace d'appel doit être affichée.
- **retry_on_connection_error** : Indique si les erreurs de connexion doivent être réessayées.
- **max_retries** : Le nombre maximum de tentatives en cas d'erreur de connexion.
- **retry_delay** : Le délai en secondes entre les tentatives en cas d'erreur de connexion.

## Bonnes pratiques

1. **Toujours capturer les exceptions** : Ne jamais laisser une exception non capturée.
2. **Journaliser les erreurs** : Toujours journaliser les erreurs pour permettre une analyse ultérieure.
3. **Fournir des messages d'erreur clairs** : Les messages d'erreur doivent être clairs et informatifs.
4. **Gérer les erreurs au niveau approprié** : Les erreurs doivent être gérées au niveau approprié dans la pile d'appels.
5. **Utiliser les codes HTTP appropriés** : Les erreurs HTTP doivent utiliser les codes appropriés.
6. **Tester les cas d'erreur** : Les cas d'erreur doivent être testés dans les tests unitaires.
7. **Documenter les erreurs** : Les erreurs doivent être documentées dans la documentation de l'API.
