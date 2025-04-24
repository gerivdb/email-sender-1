# Guide d'utilisation de BifrostMCP

Ce guide explique comment utiliser BifrostMCP, une extension VSCode qui expose les fonctionnalités de développement de VSCode aux assistants IA via le protocole MCP (Model Context Protocol).

## Prérequis

- VSCode version 1.93.0 ou supérieure (vous utilisez la version 1.98.2, qui est compatible)
- Extension BifrostMCP installée dans VSCode
- Configuration n8n pour BifrostMCP (déjà effectuée)

## Installation

1. **Installation de l'extension VSCode**
   - Ouvrez VSCode
   - Appuyez sur `Ctrl+Shift+X` pour ouvrir le panneau des extensions
   - Recherchez "Bifrost MCP"
   - Installez l'extension "Bifrost - VSCode Dev Tools MCP Server" par Connor Hallman

2. **Configuration de BifrostMCP**
   - Le fichier `bifrost.config.json` à la racine du projet configure BifrostMCP pour votre projet
   - Le port 8009 est utilisé pour éviter les conflits avec d'autres services
   - Le chemin `/email-sender-1` est utilisé pour identifier votre projet

## Démarrage du serveur BifrostMCP

### Méthode 1 : Via VSCode

1. Ouvrez VSCode avec votre projet
2. Appuyez sur `Ctrl+Shift+P` pour ouvrir la palette de commandes
3. Tapez "Bifrost MCP: Start Server" et sélectionnez cette commande
4. Le serveur BifrostMCP démarrera sur le port 8009

### Méthode 2 : Via le script PowerShell

Vous pouvez également démarrer BifrostMCP en utilisant le script PowerShell :

```powershell
.\src\mcp\use-mcp.ps1 bifrost
```

## Utilisation dans n8n

1. Ouvrez n8n (http://localhost:5678)
2. Créez un nouveau workflow ou ouvrez un workflow existant
3. Ajoutez un nœud MCP Client
4. Dans les paramètres du nœud, sélectionnez l'identifiant "MCP Bifrost"
5. Configurez les requêtes MCP selon vos besoins

## Fonctionnalités disponibles

BifrostMCP expose de nombreuses fonctionnalités de développement de VSCode, notamment :

- **find_usages** : Trouver toutes les références à un symbole
- **go_to_definition** : Aller à la définition d'un symbole
- **find_implementations** : Trouver les implémentations d'une interface ou d'une méthode abstraite
- **get_hover_info** : Obtenir des informations sur un symbole au survol
- **get_document_symbols** : Obtenir tous les symboles d'un document
- **get_completions** : Obtenir des suggestions de complétion de code
- **get_signature_help** : Obtenir de l'aide sur les signatures de fonctions
- **get_rename_locations** : Trouver les emplacements à renommer
- **get_code_actions** : Obtenir des actions de code (corrections rapides, refactorisations)
- **get_semantic_tokens** : Obtenir des informations de coloration syntaxique
- **get_call_hierarchy** : Visualiser la hiérarchie des appels
- **get_type_hierarchy** : Visualiser la hiérarchie des types
- **get_code_lens** : Obtenir des informations contextuelles sur le code
- **get_selection_range** : Obtenir des plages de sélection intelligentes
- **get_type_definition** : Aller à la définition d'un type
- **get_declaration** : Aller à la déclaration d'un symbole
- **get_document_highlights** : Mettre en évidence toutes les occurrences d'un symbole
- **get_workspace_symbols** : Rechercher des symboles dans l'espace de travail

## Exemples d'utilisation

### Exemple 1 : Trouver toutes les références à un symbole

```json
{
  "name": "find_usages",
  "arguments": {
    "textDocument": {
      "uri": "file:///chemin/vers/votre/fichier"
    },
    "position": {
      "line": 10,
      "character": 15
    },
    "context": {
      "includeDeclaration": true
    }
  }
}
```

### Exemple 2 : Rechercher des symboles dans l'espace de travail

```json
{
  "name": "get_workspace_symbols",
  "arguments": {
    "query": "MaClasse"
  }
}
```

## Dépannage

Si vous rencontrez des problèmes :

1. Vérifiez que VSCode est ouvert avec le bon projet
2. Vérifiez que le serveur BifrostMCP est en cours d'exécution
3. Vérifiez que le port 8009 est disponible
4. Consultez le panneau de sortie de VSCode pour les messages d'erreur

## Ressources supplémentaires

- [Documentation officielle de BifrostMCP](https://github.com/biegehydra/BifrostMCP)
- [Documentation du protocole MCP](https://modelcontextprotocol.io/docs/)
- [Documentation de l'API VSCode](https://code.visualstudio.com/api/references/vscode-api)
