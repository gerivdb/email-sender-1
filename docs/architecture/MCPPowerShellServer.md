# Serveur MCP PowerShell

## Description

Le serveur MCP PowerShell est une implémentation du Model Context Protocol (MCP) qui permet d'exécuter des commandes PowerShell via un serveur MCP. Il utilise le SDK MCP officiel d'Anthropic et permet aux modèles d'IA comme Claude d'interagir avec PowerShell.

## Fonctionnalités

Le serveur MCP PowerShell offre les fonctionnalités suivantes :

- Exécution de commandes PowerShell
- Récupération des informations système
- Détection des serveurs MCP
- Démarrage du gestionnaire de serveurs MCP

## Installation

### Prérequis

- Python 3.10 ou supérieur
- PowerShell 5.1 ou PowerShell 7
- SDK MCP (`pip install mcp[cli]`)
- Module PowerShell MCPManager

### Installation

1. Assurez-vous que Python est installé et accessible dans le PATH.
2. Installez le SDK MCP avec la commande suivante :
   ```
   pip install mcp[cli]
   ```
3. Installez les dépendances supplémentaires :
   ```
   pip install langchain-openai python-dotenv
   ```
4. Assurez-vous que le module PowerShell MCPManager est installé dans le dossier `modules` du projet.

## Utilisation

### Démarrage du serveur

Pour démarrer le serveur MCP PowerShell, exécutez le script `Start-MCPPowerShellServer.ps1` :

```powershell
.\scripts\Start-MCPPowerShellServer.ps1
```

Par défaut, le serveur écoute sur `localhost:8000`. Vous pouvez spécifier un port différent avec le paramètre `-Port` :

```powershell
.\scripts\Start-MCPPowerShellServer.ps1 -Port 9000
```

### Utilisation avec Claude Desktop

Pour utiliser le serveur MCP PowerShell avec Claude Desktop, vous devez ajouter la configuration suivante dans le fichier de configuration de Claude Desktop :

```json
{
  "mcpServers": {
    "powershell_server": {
      "command": "python",
      "args": ["chemin/vers/mcp_powershell_server.py"]
    }
  }
}
```

Remplacez `chemin/vers/mcp_powershell_server.py` par le chemin absolu vers le script `mcp_powershell_server.py`.

### Exemple d'utilisation avec Python

Vous pouvez utiliser le client MCP Python pour interagir avec le serveur MCP PowerShell. Voici un exemple :

```python
from mcp.client import Client

# Créer un client MCP qui se connecte au serveur local
client = Client("http://localhost:8000")

# Exécuter une commande PowerShell
result = client.run_powershell_command("Get-Date")
print(f"Résultat: {result}")

# Récupérer les informations système
system_info = client.get_system_info()
print(f"OS: {system_info.get('OsName', 'N/A')}")
```

Un exemple complet est disponible dans le fichier `scripts/python/mcp_client_example.py`.

## Outils disponibles

Le serveur MCP PowerShell expose les outils suivants :

### run_powershell_command

Exécute une commande PowerShell et retourne le résultat.

#### Paramètres

- `command` (string) : La commande PowerShell à exécuter.

#### Exemple

```python
result = client.run_powershell_command("Get-Process | Select-Object -First 5")
```

### get_system_info

Récupère les informations système via PowerShell.

#### Exemple

```python
system_info = client.get_system_info()
```

### find_mcp_servers

Détecte les serveurs MCP disponibles en utilisant le module MCPManager.

#### Exemple

```python
servers = client.find_mcp_servers()
```

### start_mcp_manager

Démarre le gestionnaire de serveurs MCP ou un agent MCP.

#### Paramètres

- `agent` (boolean, optionnel) : Si True, démarre un agent MCP au lieu du gestionnaire de serveurs.
- `query` (string, optionnel) : La requête à exécuter par l'agent MCP (uniquement si agent=True).

#### Exemple

```python
result = client.start_mcp_manager(agent=True, query="Trouve les meilleurs restaurants à Paris")
```

## Sécurité

Le serveur MCP PowerShell exécute des commandes PowerShell, ce qui peut présenter des risques de sécurité. Assurez-vous de n'utiliser ce serveur que dans un environnement sécurisé et de limiter les commandes qui peuvent être exécutées.

## Dépannage

### Le serveur ne démarre pas

- Vérifiez que Python est installé et accessible dans le PATH.
- Vérifiez que le SDK MCP est installé (`pip install mcp[cli]`).
- Vérifiez que le module PowerShell MCPManager est installé dans le dossier `modules` du projet.

### Erreurs lors de l'exécution des commandes PowerShell

- Vérifiez que PowerShell est installé et accessible dans le PATH.
- Vérifiez que les commandes PowerShell sont valides.
- Vérifiez les permissions d'exécution de PowerShell (`Get-ExecutionPolicy`).

## Auteur

EMAIL_SENDER_1 Team

## Version

1.0.0

## Date de création

2025-04-20
