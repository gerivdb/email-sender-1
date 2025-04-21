# Intégration n8n avec l'IDE

Cette intégration permet d'utiliser n8n avec l'IDE pour créer, exécuter et gérer des workflows directement depuis l'environnement de développement.

## Fonctionnalités

- Création de workflows n8n depuis l'IDE
- Exécution de workflows n8n via l'IDE
- Synchronisation des workflows entre n8n et l'IDE
- Visualisation des résultats d'exécution dans l'IDE
- Gestion des workflows n8n (activation, désactivation, suppression)

## Configuration

### Prérequis

- n8n installé et configuré (voir le dossier parent)
- IDE configuré avec les extensions nécessaires

### Installation

1. Assurez-vous que n8n est en cours d'exécution
2. Exécutez le script de configuration :

```
.\setup-ide-integration.ps1
```

## Utilisation

### Créer un workflow n8n depuis l'IDE

Vous pouvez créer un workflow n8n directement depuis l'IDE en utilisant le script `new-workflow.ps1` :

```powershell
.\new-workflow.ps1 -Name "Mon Workflow" -Description "Description du workflow"
```

### Exécuter un workflow n8n depuis l'IDE

Vous pouvez exécuter un workflow n8n existant depuis l'IDE en utilisant le script `execute-workflow.ps1` :

```powershell
.\execute-workflow.ps1 -WorkflowId "123456" -Data @{ "param1" = "valeur1" }
```

### Synchroniser les workflows entre n8n et l'IDE

Vous pouvez synchroniser les workflows entre n8n et l'IDE en utilisant le script `sync-workflows.ps1` :

```powershell
.\sync-workflows.ps1
```

## Architecture

L'intégration utilise l'API REST de n8n pour interagir avec les workflows. Les scripts PowerShell et Python fournissent des fonctions pour faciliter cette interaction.

### Composants

- `IdeN8nIntegration.ps1` : Script PowerShell principal pour l'intégration
- `setup-ide-integration.ps1` : Script de configuration de l'intégration
- `new-workflow.ps1` : Script pour créer un nouveau workflow
- `execute-workflow.ps1` : Script pour exécuter un workflow
- `sync-workflows.ps1` : Script pour synchroniser les workflows
- `workflows/` : Dossier contenant des exemples de workflows n8n pour l'IDE
- `templates/` : Dossier contenant des modèles de workflows n8n

## Intégration avec VS Code

L'intégration avec VS Code permet d'utiliser n8n directement depuis l'éditeur. Les fonctionnalités suivantes sont disponibles :

- Extension VS Code pour n8n
- Commandes VS Code pour créer, exécuter et gérer des workflows
- Visualisation des workflows dans VS Code
- Édition des workflows dans VS Code

### Installation de l'extension VS Code

1. Ouvrez VS Code
2. Accédez à l'onglet Extensions
3. Recherchez "n8n"
4. Installez l'extension "n8n Integration"

### Commandes VS Code

Les commandes suivantes sont disponibles dans VS Code :

- `n8n: Create Workflow` : Crée un nouveau workflow n8n
- `n8n: Execute Workflow` : Exécute un workflow n8n existant
- `n8n: Sync Workflows` : Synchronise les workflows entre n8n et VS Code
- `n8n: Open Workflow` : Ouvre un workflow n8n dans VS Code

## Dépannage

### Problèmes courants

- **Erreur de connexion à n8n** : Vérifiez que n8n est en cours d'exécution et accessible à l'adresse http://localhost:5678
- **Erreur d'authentification** : Vérifiez que les informations d'authentification sont correctes
- **Workflow non trouvé** : Vérifiez que le workflow existe dans n8n

### Journaux

Les journaux de l'intégration sont stockés dans le dossier `logs/` et peuvent être consultés pour diagnostiquer les problèmes.

## Développement

Pour contribuer au développement de cette intégration, consultez le fichier CONTRIBUTING.md.
