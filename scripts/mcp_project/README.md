# Serveur MCP avec intégration PowerShell

Ce projet implémente un serveur FastAPI qui expose des outils similaires à MCP (Model Context Protocol) avec une intégration PowerShell. Il permet d'exposer des outils via une API REST et de les appeler depuis PowerShell.

## Vue d'ensemble

Le serveur MCP expose une API REST pour exécuter des outils. Les outils sont des fonctions qui peuvent être appelées à distance via l'API. Le projet comprend également des clients Python et PowerShell pour interagir avec le serveur.

## Prérequis

- Python 3.7+
- PowerShell 5.1+
- `uv` (gestionnaire de paquets Python)

## Installation

### 1. Installer les dépendances Python

```bash
cd scripts/mcp_project
python -m uv add "fastapi uvicorn requests pydantic"
```

### 2. Installer le module PowerShell

```powershell
.\Install-MCPClient.ps1
```

Cette commande installe le module PowerShell dans le répertoire des modules de l'utilisateur.

## Structure du projet

### Scripts principaux
- `server.py`: Serveur FastAPI qui expose des outils via une API REST
- `client.py`: Client Python pour tester le serveur
- `MCPClient.psm1`: Module PowerShell pour interagir avec le serveur

### Scripts utilitaires
- `Start-MCPServer.ps1`: Script PowerShell pour démarrer le serveur
- `Start-MCPServerBackground.ps1`: Script PowerShell pour démarrer le serveur en arrière-plan
- `Stop-MCPServer.ps1`: Script PowerShell pour arrêter le serveur
- `Install-MCPClient.ps1`: Script PowerShell pour installer le module

### Scripts de test
- `test_server.py`: Tests unitaires pour le serveur Python
- `test_client.py`: Tests unitaires pour le client Python
- `MCPClient.Tests.ps1`: Tests unitaires pour le module PowerShell
- `Run-Tests.ps1`: Script PowerShell pour exécuter tous les tests unitaires
- `Test-MCPClient.ps1`: Script PowerShell pour tester le module
- `Test-MCPServerWithCurl.ps1`: Script PowerShell pour tester le serveur avec curl

### Exemples
- `Example-MCPClient.ps1`: Exemple d'utilisation du module PowerShell

## Utilisation

### Démarrer le serveur

#### Option 1: Démarrer le serveur en mode interactif

```powershell
.\Start-MCPServer.ps1
```

#### Option 2: Démarrer le serveur en arrière-plan

```powershell
.\Start-MCPServerBackground.ps1
```

Le serveur sera accessible à l'adresse http://localhost:8000.

### Arrêter le serveur

```powershell
.\Stop-MCPServer.ps1
```

### Tester le serveur avec le client Python

```bash
python -m uv run client.py
```

### Tester le serveur avec le module PowerShell

```powershell
.\Test-MCPClient.ps1
```

### Exemple d'utilisation du module PowerShell

```powershell
.\Example-MCPClient.ps1
```

### Tester le serveur avec curl

```powershell
.\Test-MCPServerWithCurl.ps1
```

## API REST

Le serveur expose les endpoints suivants:

- `GET /`: Page d'accueil du serveur
- `GET /tools`: Liste des outils disponibles
- `POST /tools/add`: Additionne deux nombres
- `POST /tools/multiply`: Multiplie deux nombres
- `POST /tools/get_system_info`: Retourne des informations sur le système

## Outils disponibles

Le serveur expose les outils suivants:

- `add`: Additionne deux nombres
- `multiply`: Multiplie deux nombres
- `get_system_info`: Retourne des informations sur le système

## Fonctions PowerShell

Le module PowerShell expose les fonctions suivantes:

- `Initialize-MCPConnection`: Initialise la connexion au serveur
- `Get-MCPTools`: Récupère la liste des outils disponibles
- `Invoke-MCPTool`: Appelle un outil sur le serveur
- `Add-MCPNumbers`: Additionne deux nombres via le serveur
- `ConvertTo-MCPProduct`: Multiplie deux nombres via le serveur
- `Get-MCPSystemInfo`: Récupère des informations sur le système via le serveur

## Tests unitaires

Le projet inclut des tests unitaires pour le serveur Python, le client Python et le module PowerShell.

### Exécuter tous les tests

```powershell
.\Run-Tests.ps1
```

Cette commande exécute tous les tests unitaires et affiche les résultats.

### Exécuter les tests Python

```bash
python -m pytest test_server.py -v
python -m pytest test_client.py -v
```

### Exécuter les tests PowerShell

```powershell
Invoke-Pester -Path .\MCPClient.Tests.InModuleScope.ps1 -Output Detailed
```

### Détails des tests

#### Tests Python pour le serveur
- 11 tests unitaires pour le serveur FastAPI
- Tests des fonctions individuelles (add, multiply, get_system_info)
- Tests des endpoints API (/, /tools, /tools/add, /tools/multiply, /tools/get_system_info)
- Tests des cas d'erreur (entrées invalides, endpoint inexistant)
- Utilisation de pytest-asyncio pour tester les fonctions asynchrones

#### Tests Python pour le client
- 2 tests unitaires pour le client Python
- Test de l'appel à un outil avec succès
- Test de l'appel à un outil avec une erreur

#### Tests PowerShell pour le module
- 10 tests unitaires pour le module PowerShell
- Utilisation de InModuleScope pour accéder aux fonctions internes du module
- Mock des appels à Invoke-RestMethod avec des filtres de paramètres
- Tests des fonctions Initialize-MCPConnection, Get-MCPTools, Invoke-MCPTool, Add-MCPNumbers, ConvertTo-MCPProduct, Get-MCPSystemInfo

## Dépannage

Si le serveur ne répond pas, vérifiez que:

1. Le serveur est bien démarré avec `.\Start-MCPServer.ps1` ou `.\Start-MCPServerBackground.ps1`
2. Le port 8000 est bien accessible et n'est pas utilisé par un autre processus
3. Les dépendances sont bien installées
4. Les logs du serveur sont disponibles dans `server.log` si vous utilisez `.\Start-MCPServerBackground.ps1`

## Documentation

Le projet inclut une documentation complète :

- [Documentation de l'API](docs/api.md) : Description détaillée de l'API REST
- [Gestion des erreurs](docs/error_handling.md) : Stratégie de gestion des erreurs
- [Guidelines du projet](docs/guidelines.md) : Guidelines à suivre pour le développement
- [Journal de bord](journal.md) : Journal de bord du projet

## Configuration

La configuration du projet est définie dans le fichier `config.json`. Voici les principales sections :

- **server** : Configuration du serveur (host, port, debug, log_level, cors_origins)
- **client** : Configuration du client (server_url, timeout, retry_attempts, retry_delay)
- **testing** : Configuration des tests (enable_mocks, test_server_url, test_timeout)
- **logging** : Configuration de la journalisation (level, format, date_format, file, max_size, backup_count)
- **tools** : Configuration des outils (add, multiply, get_system_info)
- **error_handling** : Configuration de la gestion des erreurs (log_errors, show_traceback, retry_on_connection_error, max_retries, retry_delay)

## Ressources

- [Documentation FastAPI](https://fastapi.tiangolo.com/)
- [Documentation PowerShell](https://docs.microsoft.com/en-us/powershell/)
- [Documentation MCP](https://github.com/modelcontextprotocol/python-sdk)
- [Exemple de serveur SSE](https://github.com/sidharthrajaram/mcp-sse)
- [Tutoriel DigitalOcean](https://www.digitalocean.com/community/tutorials/mcp-server-python)
