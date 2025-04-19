# Guide d'utilisation du module MCPClient

## Introduction

Le module `MCPClient` est un client PowerShell pour le protocole MCP (Model Context Protocol). Il permet d'interagir avec un serveur MCP pour exécuter des outils et récupérer des informations.

Ce guide vous aidera à comprendre comment utiliser le module `MCPClient` pour interagir avec un serveur MCP.

## Prérequis

- PowerShell 5.1 ou supérieur
- Un serveur MCP en cours d'exécution

## Installation

Le module `MCPClient` est inclus dans le projet EMAIL_SENDER_1. Pour l'utiliser, il suffit de l'importer :

```powershell
Import-Module -Name ".\modules\MCPClient.psm1"
```

## Démarrage rapide

Voici un exemple simple pour commencer à utiliser le module `MCPClient` :

```powershell
# Importer le module
Import-Module -Name ".\modules\MCPClient.psm1"

# Initialiser la connexion
Initialize-MCPConnection -ServerUrl "http://localhost:8000"

# Récupérer la liste des outils disponibles
$tools = Get-MCPTools
$tools | Format-Table -Property name, description

# Exécuter un outil
$result = Invoke-MCPTool -ToolName "add" -Parameters @{ a = 2; b = 3 }
Write-Host "Résultat : $($result.result)"
```

## Connexion à un serveur MCP

La première étape pour utiliser le module `MCPClient` est de se connecter à un serveur MCP. Pour cela, utilisez la fonction `Initialize-MCPConnection` :

```powershell
Initialize-MCPConnection -ServerUrl "http://localhost:8000"
```

Vous pouvez également spécifier des options supplémentaires :

```powershell
Initialize-MCPConnection -ServerUrl "http://localhost:8000" -Timeout 60 -RetryCount 5 -RetryDelay 3
```

## Récupération des outils disponibles

Une fois connecté, vous pouvez récupérer la liste des outils disponibles sur le serveur MCP :

```powershell
$tools = Get-MCPTools
$tools | Format-Table -Property name, description
```

Pour obtenir des informations détaillées sur un outil spécifique :

```powershell
$tool = $tools | Where-Object { $_.name -eq "add" }
$tool.parameters | Format-Table -Property name, type, description
```

## Exécution d'outils

Pour exécuter un outil, utilisez la fonction `Invoke-MCPTool` :

```powershell
$result = Invoke-MCPTool -ToolName "add" -Parameters @{ a = 2; b = 3 }
$result.result
```

## Exécution de commandes PowerShell

Vous pouvez exécuter des commandes PowerShell via le serveur MCP :

```powershell
$result = Invoke-MCPPowerShell -Command "Get-Process | Select-Object -First 5"
$result.output
```

## Exécution de scripts Python

Vous pouvez exécuter des scripts Python via le serveur MCP :

```powershell
$script = @"
import sys
import os
import platform

print(f"Python version: {platform.python_version()}")
print(f"Platform: {platform.platform()}")
print(f"Arguments: {sys.argv[1:]}")
"@

$result = Invoke-MCPPython -Script $script -Arguments @("arg1", "arg2")
$result.output
```

## Récupération d'informations système

Vous pouvez récupérer des informations sur le système via le serveur MCP :

```powershell
$systemInfo = Get-MCPSystemInfo
$systemInfo.os
$systemInfo.version
$systemInfo.hostname
```

## Détection des serveurs MCP

Vous pouvez détecter les serveurs MCP disponibles sur le réseau :

```powershell
$servers = Find-MCPServers
$servers.servers | Format-Table -Property url, type, status
```

Pour effectuer un scan complet du réseau :

```powershell
$servers = Find-MCPServers -Scan
$servers.servers | Format-Table -Property url, type, status
```

## Exécution de requêtes HTTP

Vous pouvez exécuter des requêtes HTTP via le serveur MCP :

```powershell
# Requête GET
$result = Invoke-MCPHttpRequest -Url "https://api.example.com/data"
$result.body

# Requête POST avec un corps JSON
$result = Invoke-MCPHttpRequest -Url "https://api.example.com/data" -Method "POST" -Body @{ name = "John" }
$result.status_code
```

## Configuration du module

Vous pouvez configurer le module `MCPClient` :

```powershell
Set-MCPClientConfiguration -Timeout 60 -RetryCount 5 -LogLevel "DEBUG"
```

Pour récupérer la configuration actuelle :

```powershell
$config = Get-MCPClientConfiguration
$config.Timeout
$config.RetryCount
$config.LogLevel
```

## Exemples avancés

### Exemple 1 : Traitement des données avec Python

```powershell
# Importer le module
Import-Module -Name ".\modules\MCPClient.psm1"

# Initialiser la connexion
Initialize-MCPConnection -ServerUrl "http://localhost:8000"

# Données à traiter
$data = @{
    values = @(1, 2, 3, 4, 5)
    operation = "sum"
}

# Script Python pour traiter les données
$script = @"
import sys
import json

# Lire les données d'entrée
data = json.loads(sys.argv[1])
values = data['values']
operation = data['operation']

# Effectuer l'opération
result = None
if operation == 'sum':
    result = sum(values)
elif operation == 'avg':
    result = sum(values) / len(values)
elif operation == 'max':
    result = max(values)
elif operation == 'min':
    result = min(values)

# Afficher le résultat
print(json.dumps({
    'result': result,
    'operation': operation,
    'values': values
}))
"@

# Exécuter le script Python
$dataJson = $data | ConvertTo-Json -Compress
$result = Invoke-MCPPython -Script $script -Arguments @($dataJson)

# Analyser le résultat
$resultObj = $result.output | ConvertFrom-Json
Write-Host "Résultat de l'opération $($resultObj.operation) sur $($resultObj.values) : $($resultObj.result)"
```

### Exemple 2 : Automatisation avec PowerShell

```powershell
# Importer le module
Import-Module -Name ".\modules\MCPClient.psm1"

# Initialiser la connexion
Initialize-MCPConnection -ServerUrl "http://localhost:8000"

# Fonction pour exécuter une commande PowerShell et analyser le résultat
function Invoke-RemoteCommand {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Command
    )

    $result = Invoke-MCPPowerShell -Command $Command

    if ($result.exit_code -eq 0) {
        Write-Host "Commande exécutée avec succès" -ForegroundColor Green
        return $result.output
    } else {
        Write-Host "Erreur lors de l'exécution de la commande : $($result.output)" -ForegroundColor Red
        return $null
    }
}

# Récupérer la liste des processus
$processes = Invoke-RemoteCommand -Command "Get-Process | Select-Object -Property Name, Id, CPU | ConvertTo-Json"
$processesObj = $processes | ConvertFrom-Json

# Afficher les processus qui utilisent le plus de CPU
$topProcesses = $processesObj | Sort-Object -Property CPU -Descending | Select-Object -First 5
$topProcesses | Format-Table -Property Name, Id, CPU

# Récupérer des informations sur le système
$systemInfo = Invoke-RemoteCommand -Command @"
[PSCustomObject]@{
    ComputerName = $env:COMPUTERNAME
    OS = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
    Memory = [math]::Round((Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
    CPU = (Get-CimInstance -ClassName Win32_Processor).Name
    Uptime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
} | ConvertTo-Json
"@

$systemInfoObj = $systemInfo | ConvertFrom-Json
Write-Host "Informations système :"
Write-Host "Nom de l'ordinateur : $($systemInfoObj.ComputerName)"
Write-Host "Système d'exploitation : $($systemInfoObj.OS)"
Write-Host "Mémoire (Go) : $($systemInfoObj.Memory)"
Write-Host "Processeur : $($systemInfoObj.CPU)"
Write-Host "Dernier démarrage : $($systemInfoObj.Uptime)"
```

### Exemple 3 : Intégration avec n8n

```powershell
# Importer le module
Import-Module -Name ".\modules\MCPClient.psm1"

# Initialiser la connexion
Initialize-MCPConnection -ServerUrl "http://localhost:8000"

# Fonction pour exécuter un workflow n8n
function Invoke-N8nWorkflow {
    param (
        [Parameter(Mandatory = $true)]
        [string]$WorkflowId,

        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{}
    )

    # Convertir les paramètres en JSON
    $parametersJson = $Parameters | ConvertTo-Json -Compress

    # Exécuter le workflow via le serveur MCP
    $result = Invoke-MCPTool -ToolName "run_n8n_workflow" -Parameters @{
        workflow_id = $WorkflowId
        parameters = $parametersJson
    }

    return $result
}

# Exécuter un workflow n8n
$result = Invoke-N8nWorkflow -WorkflowId "email-sender" -Parameters @{
    to = "user@example.com"
    subject = "Test email"
    body = "This is a test email sent from PowerShell via MCP and n8n."
}

# Afficher le résultat
if ($result.success) {
    Write-Host "Workflow exécuté avec succès" -ForegroundColor Green
    Write-Host "ID de l'exécution : $($result.execution_id)"
} else {
    Write-Host "Erreur lors de l'exécution du workflow : $($result.error)" -ForegroundColor Red
}
```

## Bonnes pratiques

### Gestion des erreurs

Il est important de gérer les erreurs lors de l'utilisation du module `MCPClient`. Voici un exemple de gestion des erreurs :

```powershell
try {
    # Initialiser la connexion
    $connected = Initialize-MCPConnection -ServerUrl "http://localhost:8000"

    if (-not $connected) {
        throw "Impossible de se connecter au serveur MCP"
    }

    # Récupérer la liste des outils disponibles
    $tools = Get-MCPTools

    if (-not $tools) {
        throw "Impossible de récupérer la liste des outils"
    }

    # Exécuter un outil
    $result = Invoke-MCPTool -ToolName "add" -Parameters @{ a = 2; b = 3 }

    if (-not $result) {
        throw "Erreur lors de l'exécution de l'outil"
    }

    Write-Host "Résultat : $($result.result)"
} catch {
    Write-Host "Erreur : $_" -ForegroundColor Red
}
```

### Journalisation

Vous pouvez activer la journalisation détaillée pour faciliter le débogage :

```powershell
# Activer la journalisation détaillée
Set-MCPClientConfiguration -LogLevel "DEBUG" -LogPath "C:\Logs\MCPClient.log"

# Exécuter des opérations
Initialize-MCPConnection -ServerUrl "http://localhost:8000"
Get-MCPTools
Invoke-MCPTool -ToolName "add" -Parameters @{ a = 2; b = 3 }

# Désactiver la journalisation détaillée
Set-MCPClientConfiguration -LogLevel "INFO"
```

## Performance

### Mise en cache

Le module MCPClient prend en charge la mise en cache des résultats pour améliorer les performances. Par défaut, le cache est activé avec une durée de vie de 5 minutes (300 secondes).

```powershell
# Configurer le cache
Set-MCPClientConfiguration -CacheEnabled $true -CacheTTL 600  # 10 minutes

# Exécuter un outil (le résultat sera mis en cache)
$result1 = Invoke-MCPTool -ToolName "add" -Parameters @{ a = 2; b = 3 }

# Exécuter le même outil (le résultat sera récupéré du cache)
$result2 = Invoke-MCPTool -ToolName "add" -Parameters @{ a = 2; b = 3 }

# Désactiver le cache pour un appel spécifique
$result3 = Invoke-MCPTool -ToolName "add" -Parameters @{ a = 2; b = 3 } -NoCache

# Forcer le rafraîchissement du cache
$result4 = Invoke-MCPTool -ToolName "add" -Parameters @{ a = 2; b = 3 } -ForceRefresh

# Nettoyer le cache
Clear-MCPCache

# Vider complètement le cache
Clear-MCPCache -Force
```

### Compression des données

Le module MCPClient prend en charge la compression des données pour réduire la taille des requêtes HTTP. Par défaut, la compression est activée pour les corps de requête de plus de 1 Ko.

```powershell
# Activer la compression des données
Set-MCPClientConfiguration -CompressionEnabled $true

# Exécuter un outil avec un grand volume de données (sera compressé automatiquement)
$largeData = @{ data = 1..1000 }
$result = Invoke-MCPTool -ToolName "process_data" -Parameters $largeData
```

### Exécution parallèle

Le module MCPClient prend en charge l'exécution parallèle des outils MCP pour améliorer les performances lors du traitement de plusieurs requêtes.

```powershell
# Exécuter plusieurs outils en parallèle
$toolNames = @("add", "subtract", "multiply", "divide")
$parametersList = @(
    @{ a = 10; b = 5 },
    @{ a = 10; b = 5 },
    @{ a = 10; b = 5 },
    @{ a = 10; b = 5 }
)

$results = Invoke-MCPToolParallel -ToolNames $toolNames -ParametersList $parametersList -ThrottleLimit 4

# Exécuter plusieurs commandes PowerShell en parallèle
$commands = @(
    "Get-Process | Select-Object -First 5",
    "Get-Service | Select-Object -First 5",
    "Get-ChildItem -Path C:\ | Select-Object -First 5"
)

$results = Invoke-MCPPowerShellParallel -Commands $commands -ThrottleLimit 3
```

### Traitement par lots

Le module MCPClient prend en charge le traitement par lots pour améliorer les performances lors du traitement d'un grand nombre d'objets.

```powershell
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
```

### Autres optimisations

1. Réutiliser la connexion au serveur MCP :

```powershell
# Initialiser la connexion une seule fois
Initialize-MCPConnection -ServerUrl "http://localhost:8000"

# Exécuter plusieurs opérations
for ($i = 0; $i -lt 10; $i++) {
    $result = Invoke-MCPTool -ToolName "add" -Parameters @{ a = $i; b = $i + 1 }
    Write-Host "Résultat $i : $($result.result)"
}
```

2. Augmenter le délai d'attente pour les opérations longues :

```powershell
# Augmenter le délai d'attente pour les opérations longues
Set-MCPClientConfiguration -Timeout 120

# Exécuter une opération longue
$result = Invoke-MCPTool -ToolName "long_running_operation" -Parameters @{ ... }
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

## Conclusion

Le module `MCPClient` offre une interface simple et puissante pour interagir avec un serveur MCP. Il permet d'exécuter des outils, des commandes PowerShell, des scripts Python et des requêtes HTTP via le serveur MCP.

Pour plus d'informations, consultez la [documentation technique du module MCPClient](../technical/MCPClientAPI.md).
