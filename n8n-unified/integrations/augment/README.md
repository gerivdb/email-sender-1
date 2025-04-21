# Intégration n8n avec Augment

Cette intégration permet d'utiliser n8n avec Augment pour automatiser des tâches et créer des workflows intelligents.

## Fonctionnalités

- Création de workflows n8n depuis Augment
- Exécution de workflows n8n via Augment
- Récupération des résultats de workflows n8n dans Augment
- Synchronisation des données entre n8n et Augment
- Utilisation des Memories d'Augment dans les workflows n8n

## Configuration

### Prérequis

- n8n installé et configuré (voir le dossier parent)
- Augment configuré avec les permissions nécessaires

### Installation

1. Assurez-vous que n8n est en cours d'exécution
2. Exécutez le script de configuration :

```
.\setup-augment-integration.ps1
```

## Utilisation

### Créer un workflow n8n depuis Augment

Vous pouvez demander à Augment de créer un workflow n8n en utilisant la commande suivante :

```
Crée un workflow n8n pour [description de la tâche]
```

### Exécuter un workflow n8n depuis Augment

Vous pouvez demander à Augment d'exécuter un workflow n8n existant :

```
Exécute le workflow n8n [nom du workflow]
```

### Récupérer les résultats d'un workflow n8n

Vous pouvez demander à Augment de récupérer les résultats d'un workflow n8n :

```
Récupère les résultats du workflow n8n [nom du workflow]
```

## Architecture

L'intégration utilise l'API REST de n8n pour interagir avec les workflows. Les scripts PowerShell et Python fournissent des fonctions pour faciliter cette interaction.

### Composants

- `AugmentN8nIntegration.ps1` : Script PowerShell principal pour l'intégration
- `setup-augment-integration.ps1` : Script de configuration de l'intégration
- `workflows/` : Dossier contenant des exemples de workflows n8n pour Augment

## Dépannage

### Problèmes courants

- **Erreur de connexion à n8n** : Vérifiez que n8n est en cours d'exécution et accessible à l'adresse http://localhost:5678
- **Erreur d'authentification** : Vérifiez que les informations d'authentification sont correctes
- **Workflow non trouvé** : Vérifiez que le workflow existe dans n8n

### Journaux

Les journaux de l'intégration sont stockés dans le dossier `logs/` et peuvent être consultés pour diagnostiquer les problèmes.

## Développement

Pour contribuer au développement de cette intégration, consultez le fichier CONTRIBUTING.md.
