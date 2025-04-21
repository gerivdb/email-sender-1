# n8n Unified

Ce projet fournit une structure unifiée pour n8n avec des intégrations pour l'IDE et les serveurs MCP.

## Fonctionnalités

- Intégration avec l'IDE (VS Code)
- Intégration avec les serveurs MCP
- Démarrage et arrêt unifiés de n8n avec toutes les intégrations
- Synchronisation des workflows entre n8n, l'IDE et les serveurs MCP

## Structure du projet

```
n8n-unified/
├── config/               # Configuration unifiée
├── data/                 # Données n8n (workflows, credentials, etc.)
├── docker/               # Configuration Docker
│   ├── docker-compose.yml # Configuration des conteneurs
│   └── .env              # Variables d'environnement
├── docs/                 # Documentation
├── integrations/         # Intégrations avec d'autres systèmes
│   ├── ide/              # Intégration avec l'IDE
│   └── mcp/              # Intégration avec les serveurs MCP
├── logs/                 # Journaux
├── scripts/              # Scripts utilitaires
│   ├── start-n8n-docker.cmd    # Démarrage de n8n avec Docker
│   ├── stop-n8n-docker.cmd     # Arrêt de n8n avec Docker
│   ├── backup-workflows.cmd    # Sauvegarde des workflows
│   └── restore-workflows.cmd   # Restauration des workflows
├── tests/                # Tests unitaires
├── start-n8n-unified.ps1 # Script de démarrage unifié
└── stop-n8n-unified.ps1  # Script d'arrêt unifié
```

## Installation

### Prérequis

- Node.js 16+
- npm 7+
- PowerShell 5.1+
- VS Code (pour l'intégration IDE)
- Serveurs MCP (pour l'intégration MCP)

### Installation

1. Clonez ce dépôt :

```
git clone <URL_DU_DEPOT>
cd n8n-unified
```

2. Installez n8n :

```
npm install n8n -g
```

3. Configurez les intégrations :

```
# Configuration de l'intégration IDE
cd integrations/ide
.\setup-ide-integration.ps1

# Configuration de l'intégration MCP
cd ..\mcp
.\setup-mcp-integration.ps1
```

## Utilisation

### Démarrer n8n avec toutes les intégrations

```
.\start-n8n-unified.ps1 -EnableIde -EnableMcp
```

### Arrêter n8n et toutes les intégrations

```
.\stop-n8n-unified.ps1
```

### Utiliser l'intégration IDE

```
cd integrations/ide
.\new-workflow.ps1 -Name "Mon Workflow" -Description "Description du workflow"
.\execute-workflow.ps1 -WorkflowId "123456" -Data @{ "param1" = "valeur1" }
.\sync-workflows.ps1
```

### Utiliser l'intégration MCP

```
cd integrations/mcp
.\configure-n8n-mcp.ps1
.\sync-workflows-with-mcp.ps1
```

### Utiliser Docker (alternative)

Pour démarrer n8n avec Docker :

```
scripts\start-n8n-docker.cmd
```

Pour arrêter n8n avec Docker :

```
scripts\stop-n8n-docker.cmd
```

## Tests

Pour exécuter les tests unitaires :

```
cd tests
Invoke-Pester
```

## Intégration avec l'IDE

L'intégration avec l'IDE permet de :

- Créer des workflows n8n directement depuis l'IDE
- Exécuter des workflows n8n via l'IDE
- Synchroniser les workflows entre n8n et l'IDE
- Visualiser les résultats d'exécution dans l'IDE

## Intégration avec les serveurs MCP

L'intégration avec les serveurs MCP permet de :

- Configurer les identifiants MCP dans n8n
- Démarrer n8n avec les serveurs MCP
- Synchroniser les workflows entre n8n et les serveurs MCP
- Utiliser les serveurs MCP dans les workflows n8n

## Dépannage

### Problèmes courants

- **Erreur de connexion à n8n** : Vérifiez que n8n est en cours d'exécution et accessible à l'adresse http://localhost:5678
- **Erreur de connexion aux serveurs MCP** : Vérifiez que les serveurs MCP sont en cours d'exécution
- **Erreur d'authentification** : Vérifiez que les identifiants sont correctement configurés

### Journaux

Les journaux sont stockés dans le dossier `logs/` et peuvent être consultés pour diagnostiquer les problèmes.
