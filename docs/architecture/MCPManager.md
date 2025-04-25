# Module MCPManager

## Description

Le module MCPManager est un module PowerShell qui centralise toutes les fonctionnalités liées à la gestion des serveurs MCP (Model Context Protocol). Il permet de détecter, configurer et gérer les serveurs MCP pour une intégration transparente avec les outils d'IA.

## Fonctionnalités

Le module MCPManager offre les fonctionnalités suivantes :

- Détection des serveurs MCP locaux et cloud
- Configuration des serveurs MCP
- Démarrage du gestionnaire de serveurs MCP
- Exécution de commandes MCP

## Installation

Le module MCPManager est installé dans le dossier `modules` du projet. Pour l'utiliser, il suffit de l'importer avec la commande suivante :

```powershell
Import-Module -Path ".\modules\MCPManager.psm1"
```

## Fonctions publiques

### Find-MCPServers

Détecte les serveurs MCP locaux et cloud.

#### Syntaxe

```powershell
Find-MCPServers [[-ConfigPath] <string>] [[-OutputPath] <string>] [-Scan] [-Force] [<CommonParameters>]
```

#### Paramètres

- **ConfigPath** : Chemin du fichier de configuration MCP. Par défaut : `.\.augment\config.json`.
- **OutputPath** : Chemin du fichier de sortie pour la configuration détectée. Par défaut : `.\mcp-servers\detected.json`.
- **Scan** : Effectue un scan complet du réseau pour détecter les serveurs MCP.
- **Force** : Force la détection même si une configuration existe déjà.

#### Exemple

```powershell
Find-MCPServers -Scan -Force
```

### New-MCPConfiguration

Crée une configuration MCP.

#### Syntaxe

```powershell
New-MCPConfiguration [[-OutputPath] <string>] [-Force] [<CommonParameters>]
```

#### Paramètres

- **OutputPath** : Chemin du fichier de sortie pour la configuration. Par défaut : `.\mcp-servers\mcp-config.json`.
- **Force** : Force la création même si une configuration existe déjà.

#### Exemple

```powershell
New-MCPConfiguration -Force
```

### Start-MCPManager

Démarre le gestionnaire de serveurs MCP ou un agent MCP.

#### Syntaxe

```powershell
Start-MCPManager [-Agent] [[-Query] <string>] [-Force] [<CommonParameters>]
```

#### Paramètres

- **Agent** : Démarre un agent MCP au lieu du gestionnaire de serveurs.
- **Query** : Spécifie la requête à exécuter par l'agent MCP.
- **Force** : Force la recréation de la configuration MCP même si elle existe déjà.

#### Exemple

```powershell
Start-MCPManager -Agent -Query "Trouve les meilleurs restaurants à Paris"
```

### Invoke-MCPCommand

Exécute une commande MCP.

#### Syntaxe

```powershell
Invoke-MCPCommand [-MCP] <string> [[-Args] <string>] [<CommonParameters>]
```

#### Paramètres

- **MCP** : Le type de MCP à exécuter (standard, notion, gateway, git-ingest).
- **Args** : Les arguments à passer à la commande MCP.

#### Exemple

```powershell
Invoke-MCPCommand -MCP "standard" -Args "--help"
```

## Intégration avec les scripts Python

Le module MCPManager s'intègre avec les scripts Python suivants :

- **mcp_manager.py** : Gère les serveurs MCP.
- **mcp_agent.py** : Permet d'interagir avec les serveurs MCP.

Ces scripts sont automatiquement copiés dans le répertoire du projet lors de l'exécution de la fonction `Start-MCPManager`.

## Dépendances

Le module MCPManager dépend des éléments suivants :

- PowerShell 5.1 ou supérieur
- Python 3.11 ou supérieur
- Packages Python : mcp-use, langchain-openai, python-dotenv

## Tests

Des tests unitaires sont disponibles dans le fichier `tests\unit\MCPManager.Tests.ps1`. Pour exécuter les tests, utilisez la commande suivante :

```powershell
Invoke-Pester -Path ".\tests\unit\MCPManager.Tests.ps1" -Output Detailed
```

## Auteur

EMAIL_SENDER_1 Team

## Version

1.0.0

## Date de création

2025-04-20
