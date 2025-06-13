# Tests des nodes MCP pour n8n

Ce répertoire contient les tests automatisés pour les nodes MCP Client et MCP Memory pour n8n.

## Structure des tests

- `test-mcp-nodes.js` : Tests unitaires des nodes MCP Client et MCP Memory
- `test-scenarios.js` : Tests de scénarios d'utilisation des nodes MCP
- `mcp-test-server.js` : Serveur de test HTTP pour simuler un serveur MCP
- `mcp-cmd-server.js` : Serveur de test en ligne de commande pour simuler un serveur MCP
- `run-all-tests.js` : Script pour exécuter tous les tests et générer un rapport
- `Run-MCPTests.ps1` : Script PowerShell pour exécuter les tests sur Windows

## Prérequis

- Node.js 14.x ou supérieur
- npm 6.x ou supérieur

## Exécution des tests

### Sous Linux/macOS

```bash
# Exécuter tous les tests

node run-all-tests.js

# Exécuter uniquement les tests unitaires

node test-mcp-nodes.js

# Exécuter uniquement les tests de scénarios

node test-scenarios.js
```plaintext
### Sous Windows

```powershell
# Exécuter tous les tests

.\Run-MCPTests.ps1

# Exécuter uniquement les tests unitaires

node test-mcp-nodes.js

# Exécuter uniquement les tests de scénarios

node test-scenarios.js
```plaintext
## Rapports de test

Les rapports de test sont générés dans le répertoire `reports` au format Markdown. Chaque rapport contient :

- Un résumé des tests exécutés
- Le nombre de tests réussis et échoués
- Les détails de chaque test, y compris la sortie et les erreurs
- La durée d'exécution de chaque test

## Types de tests

### Tests unitaires

Les tests unitaires vérifient le bon fonctionnement des opérations de base des nodes MCP Client et MCP Memory :

- **MCP Client** :
  - Opération getContext
  - Opération listTools
  - Opération executeTool

- **MCP Memory** :
  - Opération addMemory
  - Opération getMemory
  - Opération searchMemories
  - Opération updateMemory
  - Opération deleteMemory

### Tests de scénarios

Les tests de scénarios vérifient le bon fonctionnement des nodes dans des cas d'utilisation réels :

- **Scénario 1** : Génération d'email contextuel
  - Récupération du contexte pour un contact
  - Génération d'un email personnalisé
  - Sauvegarde de l'email dans les mémoires

- **Scénario 2** : Recherche et mise à jour de mémoires
  - Ajout de plusieurs mémoires
  - Recherche de mémoires par catégorie
  - Mise à jour d'une mémoire
  - Vérification de la mise à jour

- **Scénario 3** : Exécution d'outils et gestion d'erreurs
  - Listage des outils disponibles
  - Exécution d'un outil valide
  - Tentative d'exécution d'un outil invalide (gestion d'erreur)
  - Test de la validation des entrées

## Serveurs de test

### Serveur HTTP

Le serveur de test HTTP (`mcp-test-server.js`) simule un serveur MCP avec les endpoints suivants :

- `POST /api/context` : Récupérer du contexte
- `GET /api/tools` : Lister les outils disponibles
- `POST /api/tools/{toolName}` : Exécuter un outil
- `POST /api/memory` : Ajouter une mémoire
- `GET /api/memory/{memoryId}` : Récupérer une mémoire
- `POST /api/memory/search` : Rechercher des mémoires
- `PUT /api/memory/{memoryId}` : Mettre à jour une mémoire
- `DELETE /api/memory/{memoryId}` : Supprimer une mémoire

### Serveur en ligne de commande

Le serveur de test en ligne de commande (`mcp-cmd-server.js`) simule un serveur MCP qui communique via stdin/stdout. Il prend en charge les opérations suivantes :

- `getContext` : Récupérer du contexte
- `listTools` : Lister les outils disponibles
- `executeTool` : Exécuter un outil
- `addMemory` : Ajouter une mémoire
- `getMemory` : Récupérer une mémoire
- `searchMemories` : Rechercher des mémoires
- `updateMemory` : Mettre à jour une mémoire
- `deleteMemory` : Supprimer une mémoire

## Utilisation manuelle des serveurs de test

### Serveur HTTP

```bash
# Démarrer le serveur HTTP

node mcp-test-server.js 3000 test-api-key
```plaintext
Le serveur démarrera sur le port 3000 et utilisera la clé API `test-api-key`.

### Serveur en ligne de commande

```bash
# Utiliser le serveur en ligne de commande

echo '{"operation": "listTools"}' | node mcp-cmd-server.js
```plaintext
## Intégration avec n8n

### Configuration HTTP

1. Démarrer le serveur de test HTTP :
   ```bash
   node mcp-test-server.js
   ```

2. Configurer les credentials MCP Client API dans n8n :
   - Type de connexion : HTTP
   - URL de base : http://localhost:3000
   - Clé API : test-api-key

3. Créer un workflow qui utilise le node MCP Client avec la connexion HTTP.

### Configuration en ligne de commande

1. Configurer les credentials MCP Client API dans n8n :
   - Type de connexion : Command Line
   - Commande : node
   - Arguments : chemin/vers/mcp-cmd-server.js

2. Créer un workflow qui utilise le node MCP Client avec la connexion en ligne de commande.

## Workflows d'exemple

Le répertoire `../workflows/examples` contient des workflows d'exemple qui démontrent l'utilisation des nodes MCP :

- `mcp-memory-management.json` : Démontre les opérations de base sur les mémoires (ajout, récupération, mise à jour, recherche, suppression)
- `mcp-email-generation.json` : Montre comment utiliser MCP pour générer des emails contextuels

Vous pouvez importer ces workflows dans n8n pour tester les nodes MCP.
