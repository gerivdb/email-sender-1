# Analyse de la structure MCP pour Hygen

Ce document présente l'analyse de la structure du dossier MCP pour l'implémentation de Hygen.

## Structure actuelle

La structure actuelle du dossier MCP est la suivante :

```plaintext
mcp/
  ├── config/           # Configuration MCP

  ├── core/             # Composants principaux

  │   ├── client/       # Scripts client

  │   └── server/       # Scripts serveur

  ├── docs/             # Documentation

  ├── integrations/     # Intégrations avec d'autres systèmes

  ├── modules/          # Modules PowerShell

  └── server/           # Serveurs MCP

```plaintext
## Types de fichiers identifiés

### Scripts serveur

Les scripts serveur sont des scripts PowerShell qui implémentent des serveurs MCP. Ils sont stockés dans le dossier `mcp/core/server/`.

Caractéristiques :
- Extension : `.ps1`
- Shebang : `#!/usr/bin/env pwsh`

- Paramètres communs : `Port`, `LogLevel`
- Fonctions communes : `Start-Server`, `Register-MCPTools`, `Write-Log`

### Scripts client

Les scripts client sont des scripts PowerShell qui se connectent à des serveurs MCP. Ils sont stockés dans le dossier `mcp/core/client/`.

Caractéristiques :
- Extension : `.ps1`
- Directive : `#Requires -Version 5.1`

- Paramètres communs : `ServerUrl`, `Timeout`
- Fonctions communes : `Start-Client`
- Dépendances : Module `MCPClient.psm1`

### Modules

Les modules sont des modules PowerShell qui fournissent des fonctionnalités réutilisables. Ils sont stockés dans le dossier `mcp/modules/`.

Caractéristiques :
- Extension : `.psm1`
- Directive : `#Requires -Version 5.1`

- Variables globales : `$script:<ModuleName>Config`
- Fonctions communes : `Initialize-<ModuleName>Config`, `Clear-<ModuleName>Cache`, `Write-<ModuleName>Log`
- Export : `Export-ModuleMember`

### Documentation

La documentation est stockée dans le dossier `mcp/docs/` et est organisée par catégories.

Caractéristiques :
- Extension : `.md`
- Format : Markdown
- Sections communes : Introduction, Prérequis, Installation, Utilisation, Exemples, Configuration, Dépannage, Références

## Templates Hygen

Sur la base de cette analyse, les templates Hygen suivants ont été créés :

1. **mcp-server** : Pour générer des scripts serveur MCP
2. **mcp-client** : Pour générer des scripts client MCP
3. **mcp-module** : Pour générer des modules MCP
4. **mcp-doc** : Pour générer de la documentation MCP

## Paramètres des templates

### mcp-server

- `name` : Nom du script serveur (sans extension)
- `description` : Description du script serveur
- `author` : Auteur du script (optionnel, par défaut "MCP Team")

### mcp-client

- `name` : Nom du script client (sans extension)
- `description` : Description du script client
- `author` : Auteur du script (optionnel, par défaut "MCP Team")

### mcp-module

- `name` : Nom du module (sans extension)
- `description` : Description du module
- `author` : Auteur du module (optionnel, par défaut "MCP Team")

### mcp-doc

- `name` : Nom du document (sans extension)
- `description` : Description du document
- `category` : Catégorie du document (architecture, api, guides, etc.)
- `author` : Auteur du document (optionnel, par défaut "MCP Team")

## Intégration avec la structure existante

Les templates Hygen ont été conçus pour s'intégrer parfaitement avec la structure existante du dossier MCP. Les fichiers générés sont placés dans les dossiers appropriés selon leur type :

- Scripts serveur : `mcp/core/server/`
- Scripts client : `mcp/core/client/`
- Modules : `mcp/modules/`
- Documentation : `mcp/docs/<category>/`

## Utilisation

Pour utiliser les templates Hygen, deux options sont disponibles :

1. **Script PowerShell** : `mcp/scripts/utils/Generate-MCPComponent.ps1`
2. **Script de commande** : `mcp/cmd/utils/generate-component.cmd`

### Exemples d'utilisation

```powershell
# Générer un script serveur

.\mcp\scripts\utils\Generate-MCPComponent.ps1 -Type server -Name "api-server" -Description "Serveur API MCP" -Author "John Doe"

# Générer un script client

.\mcp\scripts\utils\Generate-MCPComponent.ps1 -Type client -Name "admin-client" -Description "Client d'administration MCP" -Author "Jane Smith"

# Générer un module

.\mcp\scripts\utils\Generate-MCPComponent.ps1 -Type module -Name "MCPUtils" -Description "Utilitaires MCP" -Author "Dev Team"

# Générer une documentation

.\mcp\scripts\utils\Generate-MCPComponent.ps1 -Type doc -Name "installation-guide" -Category "guides" -Description "Guide d'installation MCP" -Author "Doc Team"
```plaintext
## Conclusion

L'implémentation de Hygen pour le dossier MCP permet de générer rapidement et de manière cohérente des composants MCP. Les templates sont conçus pour s'intégrer parfaitement avec la structure existante et respecter les conventions de codage du projet.
