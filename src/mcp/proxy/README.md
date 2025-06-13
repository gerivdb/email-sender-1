# Proxy MCP Unifié

Un proxy qui unifie l'accès aux systèmes MCP (Augment et Cline) avec gestion de routage, failover automatique et interface de gestion.

## Fonctionnalités

- **Routage intelligent** : Dirige les requêtes vers le système actif
- **Failover automatique** : Bascule automatiquement vers un système de secours en cas de panne
- **Endpoints standardisés** : Endpoints communs `/health` et `/config`
- **Interface web** : Tableau de bord pour surveiller et gérer les systèmes
- **CLI** : Outil en ligne de commande pour la gestion du proxy
- **Journalisation centralisée** : Logs unifiés pour tous les systèmes
- **Synchronisation WebSocket** : Notification en temps réel des changements

## Architecture

```plaintext
Utilisateur
    │
    ▼
┌─────────┐
│ Proxy MCP│
└─────────┘
    │
    ├─────────┬─────────┐
    │         │         │
    ▼         ▼         ▼
┌─────────┐ ┌─────────┐ ┌─────────┐
│ Augment │ │  Cline  │ │Monitoring│
└─────────┘ └─────────┘ └─────────┘
    │         │
    └────┬────┘
         │
         ▼
┌─────────────────┐
│ Base de données │
└─────────────────┘
```plaintext
## Installation

### Prérequis

- Node.js 14.x ou supérieur
- npm 6.x ou supérieur

### Installation des dépendances

```bash
cd proxy_mcp
npm install
```plaintext
### Configuration

Modifiez le fichier `config/default.json` selon vos besoins :

```json
{
  "server": {
    "port": 4000,
    "host": "localhost"
  },
  "proxy": {
    "defaultTarget": "augment",
    "targets": {
      "augment": {
        "url": "http://localhost:3000",
        "priority": 1,
        "healthEndpoint": "/health"
      },
      "cline": {
        "url": "http://localhost:5000",
        "priority": 2,
        "healthEndpoint": "/health"
      }
    },
    "standardEndpoints": {
      "health": "/health",
      "config": "/config"
    },
    "failoverThreshold": 3,
    "healthCheckInterval": 10000
  },
  "logging": {
    "level": "info",
    "format": "combined",
    "directory": "../logs"
  },
  "lockFile": "../config/active_system.lock"
}
```plaintext
## Utilisation

### Démarrage du serveur

```bash
npm start
```plaintext
Pour le développement avec rechargement automatique :

```bash
npm run dev
```plaintext
### Interface web

Accédez à l'interface web à l'adresse `http://localhost:4000/ui`.

### CLI

Le proxy inclut un outil en ligne de commande pour la gestion :

```bash
# Afficher l'état actuel

node src/cli.js status

# Lister les systèmes disponibles

node src/cli.js list

# Basculer vers un autre système

node src/cli.js switch augment
```plaintext
### API REST

Le proxy expose une API REST pour la gestion :

- `GET /api/proxy/status` : Récupère le système actif
- `POST /api/proxy/switch` : Bascule vers un autre système
- `GET /health` : Vérifie la santé de tous les systèmes
- `GET /config` : Récupère la configuration du proxy

## Intégration avec mcp_manager.py

Le module Python `mcp_manager.py` a été mis à jour pour prendre en charge le proxy unifié :

```python
# Exemple d'utilisation

from mcp_manager import MCPManager

# Initialiser le gestionnaire MCP

mcp = MCPManager()

# Utiliser le proxy unifié par défaut

health = mcp.check_health()
print(f"Santé du proxy: {health}")

# Envoyer une requête via le proxy

response = mcp.send_request("/api/some-endpoint")
print(f"Réponse: {response.json()}")
```plaintext
## Workflow de bascule

1. **Automatique** : Le proxy vérifie périodiquement la santé des systèmes et bascule automatiquement en cas de panne
2. **Manuel via l'interface web** : Utilisez le tableau de bord pour basculer manuellement entre les systèmes
3. **Manuel via CLI** : Utilisez la commande `node src/cli.js switch <system>` pour basculer manuellement
4. **Manuel via API** : Envoyez une requête POST à `/api/proxy/switch` avec le système cible

## Journalisation

Les logs sont stockés dans le répertoire `logs` :

- `combined.log` : Tous les logs
- `error.log` : Logs d'erreur uniquement

## Tests

```bash
npm test
```plaintext
## Licence

ISC
