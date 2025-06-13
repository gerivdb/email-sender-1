# Module MCPManager

## Description

Le module MCPManager est un module PowerShell qui centralise toutes les fonctionnalitÃ©s liÃ©es Ã  la gestion des serveurs MCP (Model Context Protocol). Il permet de dÃ©tecter, configurer et gÃ©rer les serveurs MCP pour une intÃ©gration transparente avec les outils d'IA.

## FonctionnalitÃ©s

Le module MCPManager offre les fonctionnalitÃ©s suivantes :

- DÃ©tection des serveurs MCP locaux et cloud
- Configuration des serveurs MCP
- DÃ©marrage du gestionnaire de serveurs MCP
- ExÃ©cution de commandes MCP

## Installation

Le module MCPManager est installÃ© dans le dossier `modules` du projet. Pour l'utiliser, il suffit de l'importer avec la commande suivante :

```powershell
Import-Module -Path ".\modules\MCPManager.psm1"
```plaintext
## Fonctions publiques

### Find-MCPServers

DÃ©tecte les serveurs MCP locaux et cloud.

#### Syntaxe

```powershell
Find-MCPServers [[-ConfigPath] <string>] [[-OutputPath] <string>] [-Scan] [-Force] [<CommonParameters>]
```plaintext
#### ParamÃ¨tres

- **ConfigPath** : Chemin du fichier de configuration MCP. Par dÃ©faut : `.\.augment\config.json`.
- **OutputPath** : Chemin du fichier de sortie pour la configuration dÃ©tectÃ©e. Par dÃ©faut : `.\mcp-servers\detected.json`.
- **Scan** : Effectue un scan complet du rÃ©seau pour dÃ©tecter les serveurs MCP.
- **Force** : Force la dÃ©tection mÃªme si une configuration existe dÃ©jÃ .

#### Exemple

```powershell
Find-MCPServers -Scan -Force
```plaintext
### New-MCPConfiguration

CrÃ©e une configuration MCP.

#### Syntaxe

```powershell
New-MCPConfiguration [[-OutputPath] <string>] [-Force] [<CommonParameters>]
```plaintext
#### ParamÃ¨tres

- **OutputPath** : Chemin du fichier de sortie pour la configuration. Par dÃ©faut : `.\mcp-servers\mcp-config.json`.
- **Force** : Force la crÃ©ation mÃªme si une configuration existe dÃ©jÃ .

#### Exemple

```powershell
New-MCPConfiguration -Force
```plaintext
### mcp-manager

DÃ©marre le gestionnaire de serveurs MCP ou un agent MCP.

#### Syntaxe

```powershell
mcp-manager [-Agent] [[-Query] <string>] [-Force] [<CommonParameters>]
```plaintext
#### ParamÃ¨tres

- **Agent** : DÃ©marre un agent MCP au lieu du gestionnaire de serveurs.
- **Query** : SpÃ©cifie la requÃªte Ã  exÃ©cuter par l'agent MCP.
- **Force** : Force la recrÃ©ation de la configuration MCP mÃªme si elle existe dÃ©jÃ .

#### Exemple

```powershell
mcp-manager -Agent -Query "Trouve les meilleurs restaurants Ã  Paris"
```plaintext
### Invoke-MCPCommand

ExÃ©cute une commande MCP.

#### Syntaxe

```powershell
Invoke-MCPCommand [-MCP] <string> [[-Args] <string>] [<CommonParameters>]
```plaintext
#### ParamÃ¨tres

- **MCP** : Le type de MCP Ã  exÃ©cuter (standard, notion, gateway, git-ingest).
- **Args** : Les arguments Ã  passer Ã  la commande MCP.

#### Exemple

```powershell
Invoke-MCPCommand -MCP "standard" -Args "--help"
```plaintext
## IntÃ©gration avec les scripts Python

Le module MCPManager s'intÃ¨gre avec les scripts Python suivants :

- **mcp_manager.py** : GÃ¨re les serveurs MCP.
- **mcp_agent.py** : Permet d'interagir avec les serveurs MCP.

Ces scripts sont automatiquement copiÃ©s dans le rÃ©pertoire du projet lors de l'exÃ©cution de la fonction `mcp-manager`.

## DÃ©pendances

Le module MCPManager dÃ©pend des Ã©lÃ©ments suivants :

- PowerShell 5.1 ou supÃ©rieur
- Python 3.11 ou supÃ©rieur
- Packages Python : mcp-use, langchain-openai, python-dotenv

## Tests

Des tests unitaires sont disponibles dans le fichier `tests\unit\MCPManager.Tests.ps1`. Pour exÃ©cuter les tests, utilisez la commande suivante :

```powershell
Invoke-Pester -Path ".\development\testing\tests\unit\MCPManager.Tests.ps1" -Output Detailed
```plaintext
## Auteur

EMAIL_SENDER_1 Team

## Version

1.0.0

## Date de crÃ©ation

2025-04-20

