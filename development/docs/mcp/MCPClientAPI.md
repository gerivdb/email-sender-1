# Documentation technique du module MCPClient

## Vue d'ensemble

Le module `MCPClient` est un client PowerShell pour le protocole MCP (Model Context Protocol). Il permet d'interagir avec un serveur MCP pour exécuter des outils et récupérer des informations.

## Installation

Le module `MCPClient` est inclus dans le projet EMAIL_SENDER_1. Pour l'utiliser, il suffit de l'importer :

```powershell
Import-Module -Name ".\modules\MCPClient.psm1"
```plaintext
## Configuration

### Initialize-MCPConnection

Initialise la connexion à un serveur MCP.

#### Syntaxe

```powershell
Initialize-MCPConnection [-ServerUrl] <string> [[-Timeout] <int>] [[-RetryCount] <int>] [[-RetryDelay] <int>] [[-LogEnabled] <bool>] [[-LogLevel] <string>] [[-LogPath] <string>] [<CommonParameters>]
```plaintext
#### Paramètres

| Nom | Type | Description |
|-----|------|-------------|
| ServerUrl | string | L'URL du serveur MCP. |
| Timeout | int | Le délai d'attente en secondes pour les requêtes HTTP. Par défaut : 30. |
| RetryCount | int | Le nombre de tentatives en cas d'échec. Par défaut : 3. |
| RetryDelay | int | Le délai en secondes entre les tentatives. Par défaut : 2. |
| LogEnabled | bool | Indique si la journalisation est activée. Par défaut : $true. |
| LogLevel | string | Le niveau de journalisation (DEBUG, INFO, WARNING, ERROR). Par défaut : INFO. |
| LogPath | string | Le chemin du fichier de log. Par défaut : %TEMP%\MCPClient.log. |

### Set-MCPClientConfiguration

Configure le module MCPClient avec des options avancées de performance.

#### Syntaxe

```powershell
Set-MCPClientConfiguration [[-Timeout] <int>] [[-RetryCount] <int>] [[-RetryDelay] <int>] [[-LogEnabled] <bool>] [[-LogLevel] <string>] [[-LogPath] <string>] [[-CacheEnabled] <bool>] [[-CacheTTL] <int>] [[-MaxConcurrentRequests] <int>] [[-BatchSize] <int>] [[-CompressionEnabled] <bool>] [<CommonParameters>]
```plaintext
#### Paramètres

| Nom | Type | Description |
|-----|------|-------------|
| Timeout | int | Le délai d'attente en secondes pour les requêtes HTTP. |
| RetryCount | int | Le nombre de tentatives en cas d'échec. |
| RetryDelay | int | Le délai en secondes entre les tentatives. |
| LogEnabled | bool | Indique si la journalisation est activée. |
| LogLevel | string | Le niveau de journalisation (DEBUG, INFO, WARNING, ERROR). |
| LogPath | string | Le chemin du fichier de log. |
| CacheEnabled | bool | Indique si le cache est activé. Par défaut : $true. |
| CacheTTL | int | Durée de vie du cache en secondes. Par défaut : 300 (5 minutes). |
| MaxConcurrentRequests | int | Nombre maximum de requêtes simultanées. Par défaut : 5. |
| BatchSize | int | Taille des lots pour le traitement par lots. Par défaut : 10. |
| CompressionEnabled | bool | Indique si la compression des données est activée. Par défaut : $true. |

#### Valeur de retour

Retourne $true si la connexion est établie avec succès, $false sinon.

#### Exemples

```powershell
# Initialiser la connexion au serveur MCP local sur le port 8000

Initialize-MCPConnection -ServerUrl "http://localhost:8000"

# Initialiser la connexion avec un délai d'attente de 60 secondes et 5 tentatives en cas d'échec

Initialize-MCPConnection -ServerUrl "http://localhost:8000" -Timeout 60 -RetryCount 5
```plaintext
### Get-MCPTools

Récupère la liste des outils disponibles sur le serveur MCP.

#### Syntaxe

```powershell
Get-MCPTools [[-NoCache]] [[-ForceRefresh]] [<CommonParameters>]
```plaintext
#### Paramètres

| Nom | Type | Description |
|-----|------|-------------|
| NoCache | switch | Indique de ne pas utiliser le cache pour cette requête. |
| ForceRefresh | switch | Force le rafraîchissement du cache même si l'entrée n'est pas expirée. |

#### Valeur de retour

Retourne un tableau d'objets représentant les outils disponibles sur le serveur MCP.

#### Exemples

```powershell
# Récupérer la liste des outils disponibles

$tools = Get-MCPTools
$tools | Format-Table -Property name, description
```plaintext
### Invoke-MCPTool

Exécute un outil sur le serveur MCP.

#### Syntaxe

```powershell
Invoke-MCPTool [-ToolName] <string> [[-Parameters] <hashtable>] [[-NoCache]] [[-ForceRefresh]] [<CommonParameters>]
```plaintext
#### Paramètres

| Nom | Type | Description |
|-----|------|-------------|
| ToolName | string | Le nom de l'outil à exécuter. |
| Parameters | hashtable | Les paramètres à passer à l'outil. |
| NoCache | switch | Indique de ne pas utiliser le cache pour cette requête. |
| ForceRefresh | switch | Force le rafraîchissement du cache même si l'entrée n'est pas expirée. |

#### Valeur de retour

Retourne le résultat de l'exécution de l'outil.

#### Exemples

```powershell
# Exécuter l'outil "add" avec les paramètres a=2 et b=3

$result = Invoke-MCPTool -ToolName "add" -Parameters @{ a = 2; b = 3 }
$result.result # Affiche 5

```plaintext
### Invoke-MCPPowerShell

Exécute une commande PowerShell via le serveur MCP.

#### Syntaxe

```powershell
Invoke-MCPPowerShell [-Command] <string> [<CommonParameters>]
```plaintext
#### Paramètres

| Nom | Type | Description |
|-----|------|-------------|
| Command | string | La commande PowerShell à exécuter. |

#### Valeur de retour

Retourne le résultat de l'exécution de la commande PowerShell.

#### Exemples

```powershell
# Exécuter la commande "Get-Process"

$result = Invoke-MCPPowerShell -Command "Get-Process"
$result.output
```plaintext
### Get-MCPSystemInfo

Récupère des informations sur le système via le serveur MCP.

#### Syntaxe

```powershell
Get-MCPSystemInfo [<CommonParameters>]
```plaintext
#### Valeur de retour

Retourne un objet contenant des informations sur le système.

#### Exemples

```powershell
# Récupérer des informations sur le système

$systemInfo = Get-MCPSystemInfo
$systemInfo.os
$systemInfo.version
$systemInfo.hostname
```plaintext
### Find-MCPServers

Détecte les serveurs MCP disponibles.

#### Syntaxe

```powershell
Find-MCPServers [[-Scan]] [<CommonParameters>]
```plaintext
#### Paramètres

| Nom | Type | Description |
|-----|------|-------------|
| Scan | switch | Indique si un scan complet du réseau doit être effectué. |

#### Valeur de retour

Retourne un objet contenant la liste des serveurs MCP disponibles.

#### Exemples

```powershell
# Détecter les serveurs MCP disponibles

$servers = Find-MCPServers
$servers.servers | Format-Table -Property url, type, status

# Effectuer un scan complet du réseau

$servers = Find-MCPServers -Scan
$servers.servers | Format-Table -Property url, type, status
```plaintext
### Invoke-MCPPython

Exécute un script Python via le serveur MCP.

#### Syntaxe

```powershell
Invoke-MCPPython [-Script] <string> [[-Arguments] <string[]>] [<CommonParameters>]
```plaintext
#### Paramètres

| Nom | Type | Description |
|-----|------|-------------|
| Script | string | Le script Python à exécuter. |
| Arguments | string[] | Les arguments à passer au script Python. |

#### Valeur de retour

Retourne le résultat de l'exécution du script Python.

#### Exemples

```powershell
# Exécuter un script Python simple

$result = Invoke-MCPPython -Script "print('Hello, World!')"
$result.output

# Exécuter un script Python avec des arguments

$result = Invoke-MCPPython -Script "import sys; print(sys.argv[1])" -Arguments @("Hello")
$result.output
```plaintext
### Invoke-MCPHttpRequest

Exécute une requête HTTP via le serveur MCP.

#### Syntaxe

```powershell
Invoke-MCPHttpRequest [-Url] <string> [[-Method] <string>] [[-Headers] <hashtable>] [[-Body] <object>] [<CommonParameters>]
```plaintext
#### Paramètres

| Nom | Type | Description |
|-----|------|-------------|
| Url | string | L'URL de la requête. |
| Method | string | La méthode HTTP (GET, POST, PUT, DELETE). Par défaut : GET. |
| Headers | hashtable | Les en-têtes HTTP. |
| Body | object | Le corps de la requête. |

#### Valeur de retour

Retourne le résultat de la requête HTTP.

#### Exemples

```powershell
# Exécuter une requête GET

$result = Invoke-MCPHttpRequest -Url "https://api.example.com/data"
$result.body

# Exécuter une requête POST avec un corps JSON

$result = Invoke-MCPHttpRequest -Url "https://api.example.com/data" -Method "POST" -Body @{ name = "John" }
$result.status_code
```plaintext
### Clear-MCPCache

Nettoie le cache du module MCPClient.

#### Syntaxe

```powershell
Clear-MCPCache [[-Force]] [<CommonParameters>]
```plaintext
#### Paramètres

| Nom | Type | Description |
|-----|------|-------------|
| Force | switch | Force le vidage complet du cache, même pour les entrées non expirées. |

#### Valeur de retour

Retourne $true si le cache a été nettoyé avec succès.

#### Exemples

```powershell
# Configurer le module MCPClient

Set-MCPClientConfiguration -Timeout 60 -RetryCount 5 -LogLevel "DEBUG"
```plaintext
### Get-MCPClientConfiguration

Récupère la configuration actuelle du module MCPClient.

#### Syntaxe

```powershell
Get-MCPClientConfiguration [<CommonParameters>]
```plaintext
#### Valeur de retour

Retourne un objet contenant la configuration actuelle du module MCPClient.

#### Exemples

```powershell
# Récupérer la configuration actuelle

$config = Get-MCPClientConfiguration
$config.Timeout
$config.RetryCount
$config.LogLevel
```plaintext
### Fonctions de traitement parallèle

#### Invoke-MCPToolParallel

Exécute plusieurs outils MCP en parallèle.

##### Syntaxe

```powershell
Invoke-MCPToolParallel [-ToolNames] <string[]> [[-ParametersList] <hashtable[]>] [[-ThrottleLimit] <int>] [<CommonParameters>]
```plaintext
##### Paramètres

| Nom | Type | Description |
|-----|------|-------------|
| ToolNames | string[] | Les noms des outils à exécuter. |
| ParametersList | hashtable[] | Les listes de paramètres à passer aux outils. |
| ThrottleLimit | int | Le nombre maximum de requêtes simultanées. Par défaut : 5. |

##### Valeur de retour

Retourne un tableau des résultats de l'exécution des outils.

#### Invoke-MCPPowerShellParallel

Exécute plusieurs commandes PowerShell en parallèle via le serveur MCP.

##### Syntaxe

```powershell
Invoke-MCPPowerShellParallel [-Commands] <string[]> [[-ThrottleLimit] <int>] [<CommonParameters>]
```plaintext
##### Paramètres

| Nom | Type | Description |
|-----|------|-------------|
| Commands | string[] | Les commandes PowerShell à exécuter. |
| ThrottleLimit | int | Le nombre maximum de requêtes simultanées. Par défaut : 5. |

##### Valeur de retour

Retourne un tableau des résultats de l'exécution des commandes PowerShell.

#### Invoke-MCPPythonParallel

Exécute plusieurs scripts Python en parallèle via le serveur MCP.

##### Syntaxe

```powershell
Invoke-MCPPythonParallel [-Scripts] <string[]> [[-ArgumentsList] <string[][]>] [[-ThrottleLimit] <int>] [<CommonParameters>]
```plaintext
##### Paramètres

| Nom | Type | Description |
|-----|------|-------------|
| Scripts | string[] | Les scripts Python à exécuter. |
| ArgumentsList | string[][] | Les listes d'arguments à passer aux scripts Python. |
| ThrottleLimit | int | Le nombre maximum de requêtes simultanées. Par défaut : 5. |

##### Valeur de retour

Retourne un tableau des résultats de l'exécution des scripts Python.

#### Invoke-MCPHttpRequestParallel

Exécute plusieurs requêtes HTTP en parallèle via le serveur MCP.

##### Syntaxe

```powershell
Invoke-MCPHttpRequestParallel [-Urls] <string[]> [[-Methods] <string[]>] [[-HeadersList] <hashtable[]>] [[-Bodies] <object[]>] [[-ThrottleLimit] <int>] [<CommonParameters>]
```plaintext
##### Paramètres

| Nom | Type | Description |
|-----|------|-------------|
| Urls | string[] | Les URLs des requêtes. |
| Methods | string[] | Les méthodes HTTP (GET, POST, PUT, DELETE). |
| HeadersList | hashtable[] | Les listes d'en-têtes HTTP. |
| Bodies | object[] | Les corps des requêtes. |
| ThrottleLimit | int | Le nombre maximum de requêtes simultanées. Par défaut : 5. |

##### Valeur de retour

Retourne un tableau des résultats des requêtes HTTP.

#### Invoke-MCPBatch

Traite des données par lots.

##### Syntaxe

```powershell
Invoke-MCPBatch [-ScriptBlock] <scriptblock> [-InputObjects] <object[]> [[-BatchSize] <int>] [<CommonParameters>]
```plaintext
##### Paramètres

| Nom | Type | Description |
|-----|------|-------------|
| ScriptBlock | scriptblock | Le script à exécuter pour chaque lot. |
| InputObjects | object[] | Les objets d'entrée à traiter par lots. |
| BatchSize | int | La taille des lots. Par défaut : 10. |

##### Valeur de retour

Retourne un tableau des résultats du traitement par lots.

## Exemples d'utilisation

### Exemple 1 : Connexion à un serveur MCP et exécution d'un outil

```powershell
# Importer le module

Import-Module -Name ".\modules\MCPClient.psm1"

# Initialiser la connexion

Initialize-MCPConnection -ServerUrl "http://localhost:8000"

# Récupérer la liste des outils disponibles

$tools = Get-MCPTools
$tools | Format-Table -Property name, description

# Exécuter l'outil "add"

$result = Invoke-MCPTool -ToolName "add" -Parameters @{ a = 2; b = 3 }
Write-Host "Résultat : $($result.result)"
```plaintext
### Exemple 2 : Exécution d'une commande PowerShell via le serveur MCP

```powershell
# Importer le module

Import-Module -Name ".\modules\MCPClient.psm1"

# Initialiser la connexion

Initialize-MCPConnection -ServerUrl "http://localhost:8000"

# Exécuter une commande PowerShell

$result = Invoke-MCPPowerShell -Command "Get-Process | Select-Object -First 5"
Write-Host "Résultat :"
$result.output
```plaintext
### Exemple 3 : Utilisation du cache et de la compression

```powershell
# Importer le module

Import-Module -Name ".\modules\MCPClient.psm1"

# Initialiser la connexion

Initialize-MCPConnection -ServerUrl "http://localhost:8000"

# Configurer les options de performance

Set-MCPClientConfiguration -CacheEnabled $true -CacheTTL 600 -CompressionEnabled $true

# Exécuter un outil avec mise en cache

$result1 = Invoke-MCPTool -ToolName "add" -Parameters @{ a = 2; b = 3 }
Write-Host "Premier appel (sans cache) : $($result1.result)"

# Exécuter le même outil (récupéré du cache)

$result2 = Invoke-MCPTool -ToolName "add" -Parameters @{ a = 2; b = 3 }
Write-Host "Deuxième appel (avec cache) : $($result2.result)"

# Forcer le rafraîchissement du cache

$result3 = Invoke-MCPTool -ToolName "add" -Parameters @{ a = 2; b = 3 } -ForceRefresh
Write-Host "Troisième appel (force refresh) : $($result3.result)"

# Désactiver le cache pour un appel spécifique

$result4 = Invoke-MCPTool -ToolName "add" -Parameters @{ a = 2; b = 3 } -NoCache
Write-Host "Quatrième appel (sans cache) : $($result4.result)"

# Nettoyer le cache

Clear-MCPCache
Write-Host "Cache nettoyé"
```plaintext
### Exemple 4 : Exécution parallèle d'outils MCP

```powershell
# Importer le module

Import-Module -Name ".\modules\MCPClient.psm1"

# Initialiser la connexion

Initialize-MCPConnection -ServerUrl "http://localhost:8000"

# Définir les outils à exécuter en parallèle

$toolNames = @("add", "subtract", "multiply", "divide")
$parametersList = @(
    @{ a = 10; b = 5 },
    @{ a = 10; b = 5 },
    @{ a = 10; b = 5 },
    @{ a = 10; b = 5 }
)

# Exécuter les outils en parallèle

$results = Invoke-MCPToolParallel -ToolNames $toolNames -ParametersList $parametersList -ThrottleLimit 4

# Afficher les résultats

for ($i = 0; $i -lt $results.Count; $i++) {
    Write-Host "$($toolNames[$i]) : $($results[$i].result)"
}
```plaintext
### Exemple 5 : Traitement par lots

```powershell
# Importer le module

Import-Module -Name ".\modules\MCPClient.psm1"

# Initialiser la connexion

Initialize-MCPConnection -ServerUrl "http://localhost:8000"

# Créer un grand nombre d'objets à traiter

$inputObjects = 1..100 | ForEach-Object {
    [PSCustomObject]@{ Value = $_ }
}

# Définir le script block pour traiter chaque lot

$scriptBlock = {
    param($batch)

    $results = @()
    foreach ($item in $batch) {
        # Traiter chaque élément du lot

        $result = Invoke-MCPTool -ToolName "square" -Parameters @{ value = $item.Value }
        $results += [PSCustomObject]@{
            Input = $item.Value
            Output = $result.result
        }
    }

    return $results
}

# Traiter les objets par lots

$results = Invoke-MCPBatch -ScriptBlock $scriptBlock -InputObjects $inputObjects -BatchSize 10

# Afficher les résultats

Write-Host "Nombre total de résultats : $($results.Count)"
Write-Host "Premiers résultats :"
$results | Select-Object -First 5 | Format-Table
```plaintext
### Exemple 6 : Exécution d'un script Python via le serveur MCP

```powershell
# Importer le module

Import-Module -Name ".\modules\MCPClient.psm1"

# Initialiser la connexion

Initialize-MCPConnection -ServerUrl "http://localhost:8000"

# Exécuter un script Python

$script = @"
import sys
import os
import platform

print(f"Python version: {platform.python_version()}")
print(f"Platform: {platform.platform()}")
print(f"Arguments: {sys.argv[1:]}")
"@

$result = Invoke-MCPPython -Script $script -Arguments @("arg1", "arg2")
Write-Host "Résultat :"
$result.output
```plaintext
## Dépannage

### Problèmes de connexion

Si vous rencontrez des problèmes de connexion au serveur MCP, vérifiez les points suivants :

1. Assurez-vous que le serveur MCP est en cours d'exécution.
2. Vérifiez que l'URL du serveur est correcte.
3. Vérifiez que le port est accessible (pas bloqué par un pare-feu).
4. Augmentez le délai d'attente et le nombre de tentatives :

```powershell
Initialize-MCPConnection -ServerUrl "http://localhost:8000" -Timeout 60 -RetryCount 5
```plaintext
### Problèmes d'exécution d'outils

Si vous rencontrez des problèmes lors de l'exécution d'outils, vérifiez les points suivants :

1. Assurez-vous que l'outil existe sur le serveur MCP :

```powershell
$tools = Get-MCPTools
$tools | Where-Object { $_.name -eq "nom_de_l_outil" }
```plaintext
2. Vérifiez que les paramètres sont corrects :

```powershell
$tool = $tools | Where-Object { $_.name -eq "nom_de_l_outil" }
$tool.parameters
```plaintext
3. Activez la journalisation détaillée :

```powershell
Set-MCPClientConfiguration -LogLevel "DEBUG"
```plaintext
## Voir aussi

- [Documentation du protocole MCP](https://github.com/modelcontextprotocol/mcp)
- [Documentation du module MCPManager](./MCPManagerAPI.md)
- [Guide d'utilisation du module MCPClient](../guides/MCPClient_UserGuide.md)
