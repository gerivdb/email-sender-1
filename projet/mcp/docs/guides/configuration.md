# Guide de configuration MCP

Ce guide explique comment configurer les serveurs MCP (Model Context Protocol) dans le projet EMAIL_SENDER_1.

## Structure de configuration

La configuration des serveurs MCP est centralisée dans le dossier `projet/mcp/config/`. La structure est la suivante :

```
config/
├── mcp-config.json             # Configuration principale
├── servers/                    # Configurations spécifiques aux serveurs
│   ├── filesystem.json         # Configuration du serveur filesystem
│   ├── github.json             # Configuration du serveur GitHub
│   ├── gcp.json                # Configuration du serveur GCP
│   ├── notion.json             # Configuration du serveur Notion
│   └── gateway.yaml            # Configuration du serveur Gateway
├── templates/                  # Modèles de configuration
│   └── mcp-config-template.json # Modèle de configuration principale
└── environments/               # Configurations par environnement
    ├── development.json        # Configuration de développement
    └── production.json         # Configuration de production
```

## Configuration principale

Le fichier `mcp-config.json` contient la configuration principale des serveurs MCP. Voici un exemple :

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "@modelcontextprotocol/server-filesystem",
        "D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1"
      ],
      "enabled": true,
      "configPath": "config/servers/filesystem.json"
    },
    "github": {
      "command": "npx",
      "args": [
        "@modelcontextprotocol/server-github",
        "--config",
        "config/servers/github.json"
      ],
      "enabled": true,
      "configPath": "config/servers/github.json"
    },
    // Autres serveurs...
  },
  "global": {
    "logLevel": "info",
    "autoStart": true,
    "notificationEnabled": true,
    "logPath": "monitoring/logs/mcp.log",
    "maxLogSize": 10485760,
    "maxLogFiles": 5
  }
}
```

## Configuration des serveurs

### Serveur Filesystem

Le serveur Filesystem permet d'accéder aux fichiers locaux. Voici un exemple de configuration :

```json
{
  "rootPath": "D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1",
  "allowedExtensions": [
    ".txt",
    ".md",
    ".json",
    ".yaml",
    ".yml",
    ".ps1",
    ".psm1",
    ".psd1",
    ".py",
    ".js",
    ".ts",
    ".html",
    ".css"
  ],
  "excludedPaths": [
    "node_modules",
    ".git",
    "dist",
    "build",
    "__pycache__"
  ],
  "maxFileSize": 10485760,
  "readOnly": false
}
```

### Serveur GitHub

Le serveur GitHub permet d'accéder aux dépôts GitHub. Voici un exemple de configuration :

```json
{
  "token": "ghp_your_github_token",
  "repositories": [
    {
      "owner": "gerivonderbitsh",
      "repo": "EMAIL_SENDER_1",
      "branch": "main"
    }
  ],
  "cacheEnabled": true,
  "cacheDirectory": "servers/github/cache",
  "cacheTTL": 3600,
  "maxFileSize": 10485760,
  "excludedPaths": [
    "node_modules",
    "dist",
    "build",
    "__pycache__"
  ]
}
```

### Serveur Gateway

Le serveur Gateway permet d'accéder aux bases de données SQL. Voici un exemple de configuration :

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
          # Autres colonnes...
      # Autres tables...

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
```

## Configurations par environnement

Les fichiers dans le dossier `environments/` contiennent des configurations spécifiques à chaque environnement. Ces configurations sont fusionnées avec la configuration principale.

### Développement

```json
{
  "mcpServers": {
    "filesystem": {
      "enabled": true
    },
    "github": {
      "enabled": true
    },
    "gcp": {
      "enabled": false
    },
    // Autres serveurs...
  },
  "global": {
    "logLevel": "debug",
    "autoStart": true,
    "notificationEnabled": true,
    "logPath": "monitoring/logs/mcp-dev.log"
  }
}
```

### Production

```json
{
  "mcpServers": {
    "filesystem": {
      "enabled": true
    },
    "github": {
      "enabled": true
    },
    "gcp": {
      "enabled": true
    },
    // Autres serveurs...
  },
  "global": {
    "logLevel": "info",
    "autoStart": true,
    "notificationEnabled": true,
    "logPath": "monitoring/logs/mcp-prod.log"
  }
}
```

## Utilisation des configurations

Pour utiliser une configuration spécifique à un environnement, utilisez le paramètre `-Environment` avec les scripts :

```powershell
.\projet\mcp\scripts\utils\start-mcp-server.ps1 -Environment development
```

## Génération de configuration

Pour générer une nouvelle configuration à partir du modèle :

```powershell
.\projet\mcp\scripts\setup\generate-mcp-config.ps1 -Environment development
```

## Validation de configuration

Pour valider une configuration :

```powershell
.\projet\mcp\scripts\utils\validate-mcp-config.ps1 -ConfigPath "config/mcp-config.json"
```
