# Documentation technique du module MCPClient

## Vue d'ensemble

Le module `MCPClient` est un client PowerShell pour le protocole MCP (Model Context Protocol). Il permet d'interagir avec un serveur MCP pour exécuter des outils et récupérer des informations.

## Installation

Le module `MCPClient` est inclus dans le projet EMAIL_SENDER_1. Pour l'utiliser, il suffit de l'importer :

```powershell
Import-Module -Name ".\modules\MCPClient.psm1"
```

## Configuration

### Initialize-MCPConnection

Initialise la connexion à un serveur MCP.

#### Syntaxe

```powershell
Initialize-MCPConnection [-ServerUrl] <string> [[-Timeout] <int>] [[-RetryCount] <int>] [[-RetryDelay] <int>] [[-LogEnabled] <bool>] [[-LogLevel] <string>] [[-LogPath] <string>] [<CommonParameters>]
```

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

#### Valeur de retour

Retourne $true si la connexion est établie avec succès, $false sinon.

#### Exemples

```powershell
# Initialiser la connexion au serveur MCP local sur le port 8000
Initialize-MCPConnection -ServerUrl "http://localhost:8000"

# Initialiser la connexion avec un délai d'attente de 60 secondes et 5 tentatives en cas d'échec
Initialize-MCPConnection -ServerUrl "http://localhost:8000" -Timeout 60 -RetryCount 5
```

### Get-MCPTools

Récupère la liste des outils disponibles sur le serveur MCP.

#### Syntaxe

```powershell
Get-MCPTools [<CommonParameters>]
```

#### Valeur de retour

Retourne un tableau d'objets représentant les outils disponibles sur le serveur MCP.

#### Exemples

```powershell
# Récupérer la liste des outils disponibles
$tools = Get-MCPTools
$tools | Format-Table -Property name, description
```

### Invoke-MCPTool

Exécute un outil sur le serveur MCP.

#### Syntaxe

```powershell
Invoke-MCPTool [-ToolName] <string> [[-Parameters] <hashtable>] [<CommonParameters>]
```

#### Paramètres

| Nom | Type | Description |
|-----|------|-------------|
| ToolName | string | Le nom de l'outil à exécuter. |
| Parameters | hashtable | Les paramètres à passer à l'outil. |

#### Valeur de retour

Retourne le résultat de l'exécution de l'outil.

#### Exemples

```powershell
# Exécuter l'outil "add" avec les paramètres a=2 et b=3
$result = Invoke-MCPTool -ToolName "add" -Parameters @{ a = 2; b = 3 }
$result.result # Affiche 5
```

### Invoke-MCPPowerShell

Exécute une commande PowerShell via le serveur MCP.

#### Syntaxe

```powershell
Invoke-MCPPowerShell [-Command] <string> [<CommonParameters>]
```

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
```

### Get-MCPSystemInfo

Récupère des informations sur le système via le serveur MCP.

#### Syntaxe

```powershell
Get-MCPSystemInfo [<CommonParameters>]
```

#### Valeur de retour

Retourne un objet contenant des informations sur le système.

#### Exemples

```powershell
# Récupérer des informations sur le système
$systemInfo = Get-MCPSystemInfo
$systemInfo.os
$systemInfo.version
$systemInfo.hostname
```

### Find-MCPServers

Détecte les serveurs MCP disponibles.

#### Syntaxe

```powershell
Find-MCPServers [[-Scan]] [<CommonParameters>]
```

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
```

### Invoke-MCPPython

Exécute un script Python via le serveur MCP.

#### Syntaxe

```powershell
Invoke-MCPPython [-Script] <string> [[-Arguments] <string[]>] [<CommonParameters>]
```

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
```

### Invoke-MCPHttpRequest

Exécute une requête HTTP via le serveur MCP.

#### Syntaxe

```powershell
Invoke-MCPHttpRequest [-Url] <string> [[-Method] <string>] [[-Headers] <hashtable>] [[-Body] <object>] [<CommonParameters>]
```

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
```

### Set-MCPClientConfiguration

Configure le module MCPClient.

#### Syntaxe

```powershell
Set-MCPClientConfiguration [[-Timeout] <int>] [[-RetryCount] <int>] [[-RetryDelay] <int>] [[-LogEnabled] <bool>] [[-LogLevel] <string>] [[-LogPath] <string>] [<CommonParameters>]
```

#### Paramètres

| Nom | Type | Description |
|-----|------|-------------|
| Timeout | int | Le délai d'attente en secondes pour les requêtes HTTP. |
| RetryCount | int | Le nombre de tentatives en cas d'échec. |
| RetryDelay | int | Le délai en secondes entre les tentatives. |
| LogEnabled | bool | Indique si la journalisation est activée. |
| LogLevel | string | Le niveau de journalisation (DEBUG, INFO, WARNING, ERROR). |
| LogPath | string | Le chemin du fichier de log. |

#### Valeur de retour

Retourne $true si la configuration est mise à jour avec succès.

#### Exemples

```powershell
# Configurer le module MCPClient
Set-MCPClientConfiguration -Timeout 60 -RetryCount 5 -LogLevel "DEBUG"
```

### Get-MCPClientConfiguration

Récupère la configuration actuelle du module MCPClient.

#### Syntaxe

```powershell
Get-MCPClientConfiguration [<CommonParameters>]
```

#### Valeur de retour

Retourne un objet contenant la configuration actuelle du module MCPClient.

#### Exemples

```powershell
# Récupérer la configuration actuelle
$config = Get-MCPClientConfiguration
$config.Timeout
$config.RetryCount
$config.LogLevel
```

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
```

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
```

### Exemple 3 : Exécution d'un script Python via le serveur MCP

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
```

## Dépannage

### Problèmes de connexion

Si vous rencontrez des problèmes de connexion au serveur MCP, vérifiez les points suivants :

1. Assurez-vous que le serveur MCP est en cours d'exécution.
2. Vérifiez que l'URL du serveur est correcte.
3. Vérifiez que le port est accessible (pas bloqué par un pare-feu).
4. Augmentez le délai d'attente et le nombre de tentatives :

```powershell
Initialize-MCPConnection -ServerUrl "http://localhost:8000" -Timeout 60 -RetryCount 5
```

### Problèmes d'exécution d'outils

Si vous rencontrez des problèmes lors de l'exécution d'outils, vérifiez les points suivants :

1. Assurez-vous que l'outil existe sur le serveur MCP :

```powershell
$tools = Get-MCPTools
$tools | Where-Object { $_.name -eq "nom_de_l_outil" }
```

2. Vérifiez que les paramètres sont corrects :

```powershell
$tool = $tools | Where-Object { $_.name -eq "nom_de_l_outil" }
$tool.parameters
```

3. Activez la journalisation détaillée :

```powershell
Set-MCPClientConfiguration -LogLevel "DEBUG"
```

## Voir aussi

- [Documentation du protocole MCP](https://github.com/modelcontextprotocol/mcp)
- [Documentation du module MCPManager](./MCPManagerAPI.md)
- [Guide d'utilisation du module MCPClient](../guides/MCPClient_UserGuide.md)
