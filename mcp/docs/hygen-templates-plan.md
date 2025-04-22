# Plan des templates Hygen pour MCP

Ce document présente le plan des templates Hygen à développer pour le dossier MCP.

## Types de templates

### 1. Scripts serveur (mcp-server)

**Description** : Templates pour générer des scripts serveur MCP.

**Fichiers générés** :
- `mcp/core/server/<name>.ps1` : Script serveur PowerShell

**Paramètres** :
- `name` : Nom du script serveur (sans extension)
- `description` : Description du script serveur
- `author` : Auteur du script (optionnel, par défaut "MCP Team")

**Structure du script généré** :
- Shebang : `#!/usr/bin/env pwsh`
- Documentation : Synopsis, Description, Paramètres, Exemples, Notes
- Paramètres : `Port`, `LogLevel`
- Importation des modules nécessaires
- Configuration du serveur
- Fonction de journalisation
- Fonction principale `Start-Server`
- Fonction `Register-MCPTools`
- Appel à la fonction principale

### 2. Scripts client (mcp-client)

**Description** : Templates pour générer des scripts client MCP.

**Fichiers générés** :
- `mcp/core/client/<name>.ps1` : Script client PowerShell

**Paramètres** :
- `name` : Nom du script client (sans extension)
- `description` : Description du script client
- `author` : Auteur du script (optionnel, par défaut "MCP Team")

**Structure du script généré** :
- Directive : `#Requires -Version 5.1`
- Documentation : Synopsis, Description, Paramètres, Exemples, Notes
- Paramètres : `ServerUrl`, `Timeout`
- Importation des modules nécessaires
- Initialisation de la connexion au serveur MCP
- Récupération de la liste des outils disponibles
- Exemple d'utilisation d'un outil
- Fonction principale `Start-Client`
- Appel à la fonction principale

### 3. Modules (mcp-module)

**Description** : Templates pour générer des modules MCP.

**Fichiers générés** :
- `mcp/modules/<name>.psm1` : Module PowerShell

**Paramètres** :
- `name` : Nom du module (sans extension)
- `description` : Description du module
- `author` : Auteur du module (optionnel, par défaut "MCP Team")

**Structure du module généré** :
- Directive : `#Requires -Version 5.1`
- Documentation : Synopsis, Description, Notes
- Variables globales : `$script:<name>Config`
- Cache : `$script:<name>Cache`
- Fonction de journalisation : `Write-<name>Log`
- Fonction d'initialisation : `Initialize-<name>Config`
- Fonction de nettoyage du cache : `Clear-<name>Cache`
- Fonction d'exemple : `Get-<name>Example`
- Export des fonctions : `Export-ModuleMember`

### 4. Documentation (mcp-doc)

**Description** : Templates pour générer de la documentation MCP.

**Fichiers générés** :
- `mcp/docs/<category>/<name>.md` : Document Markdown

**Paramètres** :
- `name` : Nom du document (sans extension)
- `description` : Description du document
- `category` : Catégorie du document (architecture, api, guides, etc.)
- `author` : Auteur du document (optionnel, par défaut "MCP Team")

**Structure du document généré** :
- Titre : `# <name>`
- Description
- Table des matières
- Sections : Introduction, Prérequis, Installation, Utilisation, Exemples, Configuration, Dépannage, Références
- Auteur
- Date de création
- Version

## Implémentation

Les templates ont été implémentés dans les dossiers suivants :

- `mcp/_templates/mcp-server/new/` : Templates pour les scripts serveur
- `mcp/_templates/mcp-client/new/` : Templates pour les scripts client
- `mcp/_templates/mcp-module/new/` : Templates pour les modules
- `mcp/_templates/mcp-doc/new/` : Templates pour la documentation

Chaque dossier contient les fichiers suivants :

- `hello.ejs.t` : Template principal
- `prompt.js` : Script de prompt pour les paramètres

## Utilisation

Pour utiliser ces templates, deux options sont disponibles :

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
```

## Prochaines étapes

1. **Tests** : Tester les templates avec différents paramètres
2. **Améliorations** : Ajouter des fonctionnalités supplémentaires aux templates
3. **Documentation** : Créer une documentation complète pour l'utilisation des templates
4. **Intégration** : Intégrer les templates dans le workflow de développement MCP
