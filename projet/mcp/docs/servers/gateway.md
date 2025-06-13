# Serveur MCP Gateway

Le serveur MCP Gateway (centralmind/gateway) est un serveur MCP (Model Context Protocol) qui permet d'exposer votre base de données aux agents IA via le protocole MCP ou OpenAPI 3.1.

## Fonctionnalités

- Accès aux bases de données SQL (PostgreSQL, MySQL, SQLite, etc.)
- Génération automatique de schémas OpenAPI 3.1
- Exposition des données via le protocole MCP
- Sécurité avec authentification par clé API
- Limitation de débit pour éviter les abus

## Installation

### Prérequis

- Node.js 16 ou ultérieur
- Une base de données supportée (PostgreSQL, MySQL, SQLite, etc.)

### Installation automatique

Utilisez le script d'installation automatique :

```powershell
.\projet\mcp\scripts\setup\setup-mcp-gateway.ps1
```plaintext
### Installation manuelle

1. Téléchargez la dernière version de Gateway depuis GitHub :
   ```
   https://github.com/centralmind/gateway/releases/latest
   ```

2. Extrayez l'archive dans le dossier `projet/mcp/servers/gateway/`

3. Créez un fichier de configuration `gateway.yaml` dans le dossier `projet/mcp/config/servers/`

## Configuration

La configuration du serveur Gateway se fait via un fichier YAML. Voici un exemple de configuration :

```yaml
# Configuration du serveur Gateway MCP

server:
  host: localhost
  port: 8080
  debug: false
  cors:
    enabled: true
    origins:
      - "*"

databases:
  - name: main
    type: sqlite
    connection: "D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/data/database.sqlite"
    tables:
      - name: users
        description: "Table des utilisateurs"
        columns:
          - name: id
            type: INTEGER
            primary_key: true
          - name: username
            type: TEXT
            description: "Nom d'utilisateur"
          - name: email
            type: TEXT
            description: "Adresse e-mail"
          - name: created_at
            type: TIMESTAMP
            description: "Date de création"
      - name: emails
        description: "Table des e-mails"
        columns:
          - name: id
            type: INTEGER
            primary_key: true
          - name: user_id
            type: INTEGER
            foreign_key: users.id
          - name: subject
            type: TEXT
            description: "Sujet de l'e-mail"
          - name: body
            type: TEXT
            description: "Corps de l'e-mail"
          - name: sent_at
            type: TIMESTAMP
            description: "Date d'envoi"

security:
  enabled: true
  api_key: "your_api_key"
  rate_limit:
    enabled: true
    requests_per_minute: 60

logging:
  level: info
  file: "monitoring/logs/gateway.log"
  max_size: 10485760
  max_files: 5
```plaintext
## Utilisation

### Démarrage du serveur

Pour démarrer le serveur Gateway :

```powershell
.\projet\mcp\scripts\utils\start-mcp-server.ps1 -Server gateway
```plaintext
### Vérification de l'état

Pour vérifier l'état du serveur Gateway :

```powershell
.\projet\mcp\scripts\utils\check-mcp-status.ps1 -Server gateway
```plaintext
### Arrêt du serveur

Pour arrêter le serveur Gateway :

```powershell
.\projet\mcp\scripts\utils\stop-mcp-server.ps1 -Server gateway
```plaintext
## Intégration avec n8n

Pour utiliser le serveur Gateway dans n8n, vous devez configurer un nœud MCP Client API avec les paramètres suivants :

1. Type de connexion : Command Line (STDIO)
2. Commande : `gateway.exe.cmd`
3. Arguments : `start --config "config/servers/gateway.yaml" mcp-stdio`
4. Variables d'environnement : `N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true`

Vous pouvez utiliser le script de configuration automatique :

```powershell
.\projet\mcp\integrations\n8n\scripts\configure-n8n-mcp.ps1 -Server gateway
```plaintext
## Exemples d'utilisation

### Exemple de workflow n8n

Voici un exemple de workflow n8n qui utilise le serveur Gateway pour récupérer des données :

```json
{
  "nodes": [
    {
      "parameters": {
        "functionName": "queryDatabase",
        "arguments": {
          "database": "main",
          "query": "SELECT * FROM users WHERE id = 1"
        }
      },
      "name": "MCP Gateway",
      "type": "n8n-nodes-mcp.mcpClientApi",
      "typeVersion": 1,
      "position": [
        880,
        300
      ],
      "credentials": {
        "mcpClientApi": "MCP Gateway"
      }
    }
  ],
  "connections": {}
}
```plaintext
## Dépannage

### Problèmes courants

#### Le serveur ne démarre pas

- Vérifiez que le fichier de configuration existe et est valide
- Vérifiez que la base de données est accessible
- Vérifiez les journaux dans `monitoring/logs/gateway.log`

#### Erreur de connexion à la base de données

- Vérifiez que la chaîne de connexion est correcte
- Vérifiez que la base de données est en cours d'exécution
- Vérifiez que les identifiants sont corrects

#### Erreur d'authentification

- Vérifiez que la clé API est correcte
- Vérifiez que la sécurité est correctement configurée

## Ressources

- [Documentation officielle de Gateway](https://github.com/centralmind/gateway)
- [Guide d'intégration avec n8n](../guides/n8n-integration.md)
- [Référence de configuration](../reference/configuration-reference.md)
