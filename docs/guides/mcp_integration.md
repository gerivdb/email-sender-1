# Guide d'intégration MCP

## Introduction

Le Model Context Protocol (MCP) est un protocole standardisé qui permet d'interagir avec des modèles d'intelligence artificielle de manière cohérente et efficace. Le module `MCPManager` fournit des outils puissants pour gérer les serveurs MCP, détecter les serveurs disponibles et interagir avec eux. Ce guide vous expliquera comment utiliser efficacement le module `MCPManager` pour intégrer des fonctionnalités d'IA dans vos projets.

## Prérequis

Avant de commencer, assurez-vous de disposer des éléments suivants :

- PowerShell 5.1 ou PowerShell 7+ installé
- Python 3.11+ installé (pour certaines fonctionnalités)
- Le module `MCPManager.psm1` disponible dans votre projet
- Connaissances de base sur les API et les protocoles de communication

## Installation et configuration

### Installation du module

Pour utiliser le module `MCPManager`, vous devez d'abord l'importer dans votre session PowerShell :

```powershell
# Importer le module
Import-Module -Path ".\modules\MCPManager.psm1" -Force
```

### Initialisation du module

Après avoir importé le module, vous devez l'initialiser avec les paramètres souhaités :

```powershell
# Initialisation avec les paramètres par défaut
Initialize-MCPManager

# Ou avec des paramètres personnalisés
Initialize-MCPManager -Enabled $true -ConfigPath ".\config\custom_mcp_config.json" -LogPath ".\logs\mcp.log" -LogLevel "DEBUG"
```

Les paramètres disponibles sont :

- `Enabled` : Active ou désactive le gestionnaire MCP (par défaut : $true)
- `ConfigPath` : Chemin du fichier de configuration (par défaut : ".\config\mcp_manager.json")
- `LogPath` : Chemin du fichier de log (par défaut : ".\logs\mcp_manager.log")
- `LogLevel` : Niveau de log (DEBUG, INFO, WARNING, ERROR) (par défaut : "INFO")

### Installation des dépendances

Avant d'utiliser les fonctionnalités MCP, vous devez installer les dépendances nécessaires :

```powershell
# Installer les dépendances pour un serveur MCP local
$installed = Install-MCPDependencies -ServerType "local"

if ($installed) {
    Write-Host "Dépendances installées avec succès"
} else {
    Write-Host "Erreur lors de l'installation des dépendances"
}
```

## Concepts de base

### Qu'est-ce que MCP ?

Le Model Context Protocol (MCP) est un protocole standardisé qui définit comment les applications peuvent communiquer avec des modèles d'intelligence artificielle. Il permet d'envoyer des requêtes aux modèles et de recevoir des réponses de manière cohérente, indépendamment du modèle ou du fournisseur spécifique.

### Types de serveurs MCP

Le module `MCPManager` prend en charge plusieurs types de serveurs MCP :

1. **Serveur local** : Un serveur MCP exécuté localement sur votre machine.
2. **Serveur n8n** : Un serveur MCP intégré à n8n pour l'automatisation des flux de travail.
3. **Serveur Notion** : Un serveur MCP intégré à Notion pour la gestion des connaissances.
4. **Serveur Gateway** : Un serveur MCP qui agit comme une passerelle vers d'autres serveurs MCP.
5. **Serveur Git Ingest** : Un serveur MCP spécialisé dans l'ingestion de données à partir de dépôts Git.

## Utilisation de base

### Recherche de serveurs MCP

Pour rechercher les serveurs MCP disponibles sur votre réseau, utilisez la fonction `Find-MCPServers` :

```powershell
# Rechercher les serveurs MCP locaux
$localServers = Find-MCPServers -ScanLocalPorts

# Afficher les serveurs détectés
foreach ($server in $localServers) {
    Write-Host "Serveur MCP détecté: $($server.Type) sur $($server.Host):$($server.Port) - $($server.Status)"
}

# Rechercher les serveurs MCP sur des hôtes distants
$remoteServers = Find-MCPServers -ScanRemoteHosts @("server1.example.com", "server2.example.com") -PortRange @(8000, 8001, 8002)

# Afficher les serveurs distants détectés
foreach ($server in $remoteServers) {
    Write-Host "Serveur MCP distant détecté: $($server.Type) sur $($server.Host):$($server.Port) - $($server.Status)"
}
```

Les paramètres disponibles sont :

- `ScanLocalPorts` : Analyse les ports locaux pour détecter les serveurs MCP
- `ScanRemoteHosts` : Tableau d'hôtes distants à analyser
- `PortRange` : Plage de ports à analyser (par défaut : 8000-8100)
- `Timeout` : Délai d'attente en millisecondes (par défaut : 1000)

### Création d'une configuration MCP

Pour créer une configuration pour un serveur MCP, utilisez la fonction `New-MCPConfiguration` :

```powershell
# Créer une configuration pour un serveur MCP local
$configCreated = New-MCPConfiguration -OutputPath ".\config\local_mcp_config.json" -ServerType "local" -Port 8000 -Force

if ($configCreated) {
    Write-Host "Configuration créée avec succès: .\config\local_mcp_config.json"
}

# Créer une configuration pour un serveur MCP n8n
$n8nConfigCreated = New-MCPConfiguration -OutputPath ".\config\n8n_mcp_config.json" -ServerType "n8n" -Port 5678 -Host "localhost" -Force

if ($n8nConfigCreated) {
    Write-Host "Configuration n8n créée avec succès: .\config\n8n_mcp_config.json"
}
```

Les paramètres disponibles sont :

- `OutputPath` : Chemin du fichier de configuration à créer
- `ServerType` : Type de serveur MCP (local, n8n, notion, gateway, git-ingest)
- `Port` : Numéro de port du serveur MCP
- `Host` : Nom ou adresse IP de l'hôte
- `Force` : Écrase le fichier de configuration s'il existe déjà

### Démarrage d'un serveur MCP

Pour démarrer un serveur MCP, utilisez la fonction `Start-MCPServer` :

```powershell
# Démarrer un serveur MCP local
$server = Start-MCPServer -ServerType "local" -Port 8000 -Wait

if ($server.Status -eq "running") {
    Write-Host "Serveur MCP démarré avec succès: $($server.Url)"
    Write-Host "ID du processus: $($server.ProcessId)"
} else {
    Write-Host "Erreur lors du démarrage du serveur MCP: $($server.Error)"
}

# Démarrer un serveur MCP n8n
$n8nServer = Start-MCPServer -ServerType "n8n" -Port 5678 -Wait

if ($n8nServer.Status -eq "running") {
    Write-Host "Serveur MCP n8n démarré avec succès: $($n8nServer.Url)"
}
```

Les paramètres disponibles sont :

- `ServerType` : Type de serveur MCP (local, n8n, notion, gateway, git-ingest)
- `Port` : Numéro de port du serveur MCP
- `Host` : Nom ou adresse IP de l'hôte
- `ConfigPath` : Chemin du fichier de configuration
- `Wait` : Attend que le serveur soit prêt avant de retourner
- `Timeout` : Délai d'attente en secondes

### Exécution de commandes MCP

Pour exécuter une commande sur un serveur MCP, utilisez la fonction `Invoke-MCPCommand` :

```powershell
# Exécuter une commande sur un serveur MCP local
$result = Invoke-MCPCommand -Command "get_tools" -ServerType "local" -Port 8000

# Afficher les outils disponibles
Write-Host "Outils disponibles sur le serveur MCP:"
foreach ($tool in $result.tools) {
    Write-Host "- $($tool.name): $($tool.description)"
}

# Exécuter une commande avec des paramètres
$addResult = Invoke-MCPCommand -Command "add" -Parameters @{ a = 2; b = 3 } -ServerType "local" -Port 8000

Write-Host "Résultat de l'addition: $addResult"
```

Les paramètres disponibles sont :

- `Command` : Commande à exécuter
- `Parameters` : Paramètres de la commande
- `ServerType` : Type de serveur MCP (local, n8n, notion, gateway, git-ingest)
- `Port` : Numéro de port du serveur MCP
- `Host` : Nom ou adresse IP de l'hôte
- `Timeout` : Délai d'attente en secondes

### Arrêt d'un serveur MCP

Pour arrêter un serveur MCP, utilisez la fonction `Stop-MCPServer` :

```powershell
# Arrêter un serveur MCP local
$stopped = Stop-MCPServer -ServerType "local" -Port 8000

if ($stopped) {
    Write-Host "Serveur MCP arrêté avec succès"
} else {
    Write-Host "Erreur lors de l'arrêt du serveur MCP"
}

# Arrêter un serveur MCP par son ID de processus
$stoppedById = Stop-MCPServer -ProcessId 1234 -Force

if ($stoppedById) {
    Write-Host "Serveur MCP avec l'ID de processus 1234 arrêté avec succès"
}
```

Les paramètres disponibles sont :

- `ServerType` : Type de serveur MCP (local, n8n, notion, gateway, git-ingest)
- `Port` : Numéro de port du serveur MCP
- `Host` : Nom ou adresse IP de l'hôte
- `ProcessId` : ID du processus du serveur MCP
- `Force` : Force l'arrêt du serveur

## Exemples avancés

### Exemple 1 : Utilisation de plusieurs serveurs MCP

Vous pouvez gérer plusieurs serveurs MCP simultanément :

```powershell
# Fonction pour démarrer un serveur MCP
function Start-TestMCPServer {
    param (
        [string]$ServerType,
        [int]$Port
    )
    
    Write-Host "Démarrage du serveur MCP $ServerType sur le port $Port..."
    $server = Start-MCPServer -ServerType $ServerType -Port $Port -Wait
    
    if ($server.Status -eq "running") {
        Write-Host "Serveur MCP $ServerType démarré avec succès: $($server.Url)"
        Write-Host "ID du processus: $($server.ProcessId)"
        return $server
    } else {
        Write-Host "Erreur lors du démarrage du serveur MCP $ServerType: $($server.Error)"
        return $null
    }
}

# Démarrer plusieurs serveurs MCP
$servers = @()
$servers += Start-TestMCPServer -ServerType "local" -Port 8000
$servers += Start-TestMCPServer -ServerType "n8n" -Port 5678

# Attendre quelques secondes
Start-Sleep -Seconds 5

# Tester tous les serveurs
Write-Host "`nTest de tous les serveurs MCP..."
foreach ($server in $servers) {
    if ($server -ne $null) {
        $testResult = Test-MCPServer -ServerType $server.ServerType -Port $server.Port -Host $server.Host
        
        if ($testResult.Available) {
            Write-Host "Serveur MCP $($server.ServerType) disponible: $($server.Url)"
            Write-Host "Temps de réponse: $($testResult.ResponseTime) ms"
        } else {
            Write-Host "Serveur MCP $($server.ServerType) non disponible: $($server.Url)"
        }
    }
}

# Arrêter tous les serveurs
Write-Host "`nArrêt de tous les serveurs MCP..."
foreach ($server in $servers) {
    if ($server -ne $null) {
        $stopped = Stop-MCPServer -ProcessId $server.ProcessId
        
        if ($stopped) {
            Write-Host "Serveur MCP $($server.ServerType) arrêté avec succès: $($server.Url)"
        } else {
            Write-Host "Erreur lors de l'arrêt du serveur MCP $($server.ServerType): $($server.Url)"
        }
    }
}
```

### Exemple 2 : Intégration avec des scripts Python

Vous pouvez intégrer le module `MCPManager` avec des scripts Python :

```powershell
# Vérifier si Python est installé
$pythonInstalled = Get-Command python -ErrorAction SilentlyContinue

if (-not $pythonInstalled) {
    Write-Host "Python n'est pas installé ou n'est pas dans le PATH"
    return
}

# Créer un script Python simple pour tester l'intégration
$pythonScriptPath = ".\scripts\mcp_test.py"
$pythonScript = @"
import sys
import json
import requests

def main():
    server_type = sys.argv[1] if len(sys.argv) > 1 else "local"
    port = int(sys.argv[2]) if len(sys.argv) > 2 else 8000
    
    print(f"Testing MCP server: {server_type} on port {port}")
    
    try:
        response = requests.get(f"http://localhost:{port}/health", timeout=2)
        if response.status_code == 200:
            print(f"Server is healthy: {response.json()}")
            return 0
        else:
            print(f"Server returned status code: {response.status_code}")
            return 1
    except Exception as e:
        print(f"Error connecting to server: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
"@

Set-Content -Path $pythonScriptPath -Value $pythonScript
Write-Host "Script Python créé: $pythonScriptPath"

# Démarrer un serveur MCP local
Write-Host "`nDémarrage d'un serveur MCP local..."
$server = Start-MCPServer -ServerType "local" -Port 8000 -Wait

if ($server.Status -eq "running") {
    Write-Host "Serveur MCP démarré avec succès: $($server.Url)"
    
    # Exécuter le script Python
    Write-Host "`nExécution du script Python..."
    $pythonResult = python $pythonScriptPath "local" 8000
    
    Write-Host "Résultat du script Python:"
    Write-Host $pythonResult
    
    # Arrêter le serveur
    Write-Host "`nArrêt du serveur MCP..."
    $stopped = Stop-MCPServer -ServerType "local" -Port 8000
    
    if ($stopped) {
        Write-Host "Serveur MCP arrêté avec succès"
    } else {
        Write-Host "Erreur lors de l'arrêt du serveur MCP"
    }
} else {
    Write-Host "Erreur lors du démarrage du serveur MCP: $($server.Error)"
}

# Supprimer le script Python
Remove-Item -Path $pythonScriptPath
Write-Host "`nScript Python supprimé: $pythonScriptPath"
```

### Exemple 3 : Utilisation de MCP avec n8n

Vous pouvez intégrer MCP avec n8n pour l'automatisation des flux de travail :

```powershell
# Créer une configuration pour un serveur MCP n8n
$n8nConfigCreated = New-MCPConfiguration -OutputPath ".\config\n8n_mcp_config.json" -ServerType "n8n" -Port 5678 -Host "localhost" -Force

if ($n8nConfigCreated) {
    Write-Host "Configuration n8n créée avec succès: .\config\n8n_mcp_config.json"
    
    # Démarrer un serveur MCP n8n
    $n8nServer = Start-MCPServer -ServerType "n8n" -Port 5678 -Wait
    
    if ($n8nServer.Status -eq "running") {
        Write-Host "Serveur MCP n8n démarré avec succès: $($n8nServer.Url)"
        
        # Exécuter une commande sur le serveur n8n
        $result = Invoke-MCPCommand -Command "get_workflows" -ServerType "n8n" -Port 5678
        
        Write-Host "Workflows disponibles sur le serveur n8n:"
        foreach ($workflow in $result.workflows) {
            Write-Host "- $($workflow.name): $($workflow.id)"
        }
        
        # Exécuter un workflow spécifique
        $workflowResult = Invoke-MCPCommand -Command "execute_workflow" -Parameters @{ 
            workflow_id = "12345"
            input = @{
                message = "Hello from MCP!"
            }
        } -ServerType "n8n" -Port 5678
        
        Write-Host "Résultat de l'exécution du workflow: $($workflowResult | ConvertTo-Json -Depth 3)"
        
        # Arrêter le serveur
        $stopped = Stop-MCPServer -ServerType "n8n" -Port 5678
        
        if ($stopped) {
            Write-Host "Serveur MCP n8n arrêté avec succès"
        } else {
            Write-Host "Erreur lors de l'arrêt du serveur MCP n8n"
        }
    } else {
        Write-Host "Erreur lors du démarrage du serveur MCP n8n: $($n8nServer.Error)"
    }
} else {
    Write-Host "Erreur lors de la création de la configuration n8n"
}
```

## Intégration avec d'autres modules

### Intégration avec le module InputSegmenter

Vous pouvez intégrer le module `MCPManager` avec le module `InputSegmenter` pour traiter des entrées volumineuses :

```powershell
# Importer les modules
Import-Module -Path ".\modules\MCPManager.psm1" -Force
Import-Module -Path ".\modules\InputSegmenter.psm1" -Force

# Initialiser les modules
Initialize-MCPManager
Initialize-InputSegmentation

# Démarrer un serveur MCP local
$server = Start-MCPServer -ServerType "local" -Port 8000 -Wait

if ($server.Status -eq "running") {
    Write-Host "Serveur MCP démarré avec succès: $($server.Url)"
    
    # Créer un texte volumineux
    $text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. " * 1000
    
    # Segmenter le texte
    $segments = Split-TextInput -Text $text -SegmentSizeKB 10
    
    Write-Host "Nombre de segments: $($segments.Count)"
    
    # Traiter chaque segment avec MCP
    $results = @()
    foreach ($segment in $segments) {
        $result = Invoke-MCPCommand -Command "process_text" -Parameters @{ 
            text = $segment
        } -ServerType "local" -Port 8000
        
        $results += $result
    }
    
    Write-Host "Résultats du traitement: $($results.Count) segments traités"
    
    # Arrêter le serveur
    $stopped = Stop-MCPServer -ServerType "local" -Port 8000
    
    if ($stopped) {
        Write-Host "Serveur MCP arrêté avec succès"
    } else {
        Write-Host "Erreur lors de l'arrêt du serveur MCP"
    }
} else {
    Write-Host "Erreur lors du démarrage du serveur MCP: $($server.Error)"
}
```

## Dépannage

### Problème : Le serveur MCP ne démarre pas

Si le serveur MCP ne démarre pas, vérifiez les points suivants :

1. Assurez-vous que toutes les dépendances sont installées :

```powershell
Install-MCPDependencies -ServerType "local" -Force
```

2. Vérifiez que le port n'est pas déjà utilisé :

```powershell
# Vérifier si le port est déjà utilisé
$portInUse = Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue

if ($portInUse) {
    Write-Host "Le port 8000 est déjà utilisé par le processus $($portInUse.OwningProcess)"
} else {
    Write-Host "Le port 8000 est disponible"
}
```

3. Vérifiez les logs pour plus d'informations :

```powershell
Get-Content -Path ".\logs\mcp_manager.log" -Tail 20
```

### Problème : Erreurs lors de l'exécution de commandes MCP

Si vous rencontrez des erreurs lors de l'exécution de commandes MCP, vérifiez les points suivants :

1. Assurez-vous que le serveur est en cours d'exécution :

```powershell
$testResult = Test-MCPServer -ServerType "local" -Port 8000

if ($testResult.Available) {
    Write-Host "Serveur MCP disponible: $($testResult.Url)"
} else {
    Write-Host "Serveur MCP non disponible"
}
```

2. Vérifiez que la commande et les paramètres sont corrects :

```powershell
# Obtenir la liste des commandes disponibles
$commands = Invoke-MCPCommand -Command "get_commands" -ServerType "local" -Port 8000

Write-Host "Commandes disponibles:"
foreach ($command in $commands) {
    Write-Host "- $command"
}
```

3. Augmentez le niveau de log pour obtenir plus d'informations :

```powershell
Initialize-MCPManager -LogLevel "DEBUG"
```

## Bonnes pratiques

- **Utilisez des configurations séparées** pour chaque type de serveur MCP.
- **Gérez proprement les ressources** en arrêtant les serveurs MCP lorsque vous avez terminé.
- **Utilisez le paramètre Wait** lors du démarrage des serveurs pour vous assurer qu'ils sont prêts avant de les utiliser.
- **Journalisez les actions importantes** pour faciliter le débogage.
- **Testez régulièrement** la disponibilité des serveurs MCP.
- **Utilisez des délais d'attente appropriés** pour éviter les blocages.
- **Intégrez avec d'autres modules** pour des fonctionnalités avancées.

## FAQ

### Quelle est la différence entre les différents types de serveurs MCP ?

- **Serveur local** : Un serveur MCP exécuté localement sur votre machine, idéal pour le développement et les tests.
- **Serveur n8n** : Un serveur MCP intégré à n8n, permettant d'utiliser MCP dans les workflows n8n.
- **Serveur Notion** : Un serveur MCP intégré à Notion, permettant d'utiliser MCP avec les bases de données Notion.
- **Serveur Gateway** : Un serveur MCP qui agit comme une passerelle vers d'autres serveurs MCP, permettant de centraliser les requêtes.
- **Serveur Git Ingest** : Un serveur MCP spécialisé dans l'ingestion de données à partir de dépôts Git, utile pour l'analyse de code.

### Comment puis-je créer mon propre serveur MCP ?

Vous pouvez créer votre propre serveur MCP en utilisant le SDK Python MCP. Voici un exemple simple :

```python
from mcp import MCPServer

# Créer un serveur MCP
server = MCPServer(port=8000)

# Définir une fonction de traitement
@server.command
def process_text(text):
    return {"processed": text.upper()}

# Démarrer le serveur
server.start()
```

### Comment puis-je sécuriser mon serveur MCP ?

Vous pouvez sécuriser votre serveur MCP en utilisant HTTPS et en ajoutant une authentification. Voici quelques recommandations :

1. Utilisez HTTPS pour chiffrer les communications.
2. Ajoutez une authentification par clé API ou OAuth.
3. Limitez l'accès au serveur à des adresses IP spécifiques.
4. Utilisez un pare-feu pour protéger le serveur.
5. Journalisez toutes les requêtes pour détecter les activités suspectes.

### Puis-je utiliser MCP avec d'autres langages de programmation ?

Oui, MCP est un protocole indépendant du langage. Il existe des SDK pour plusieurs langages, notamment :

- Python : `mcp` et `FastMCP`
- JavaScript/TypeScript : `mcp-js`
- Java : `mcp-java`
- Go : `mcp-go`

## Ressources supplémentaires

- [Documentation API du module MCPManager](../api/MCPManager.html)
- [Exemples d'utilisation du module MCPManager](../api/examples/MCPManager_Examples.html)
- [Documentation technique sur MCP](../technical/MCPManager.md)
- [Site officiel de MCP](https://mcp-protocol.org)
- [SDK Python MCP](https://github.com/mcp-protocol/mcp-python)
