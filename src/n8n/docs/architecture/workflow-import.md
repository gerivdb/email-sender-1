# Importation automatique des workflows n8n

Ce document explique comment utiliser les scripts d'importation automatique des workflows n8n.

## Vue d'ensemble

L'importation automatique des workflows n8n permet de :

1. Importer des workflows depuis des fichiers JSON vers n8n
2. Gérer les erreurs et les cas particuliers lors de l'importation
3. Optimiser le processus d'importation pour gérer un grand nombre de workflows
4. Suivre l'avancement de l'importation via des logs détaillés

## Scripts disponibles

### Importation standard

Le script `import-workflows-auto.cmd` permet d'importer des workflows de manière standard :

```
.\import-workflows-auto.cmd -SourceFolder "path/to/workflows" -Method "API" -Tags "imported,auto" -Active $true
```

Options disponibles :

- `-SourceFolder` : Dossier contenant les workflows à importer (par défaut: n8n/core/workflows/local)
- `-TargetFolder` : Dossier de destination pour les workflows importés (par défaut: n8n/data/.n8n/workflows)
- `-Method` : Méthode d'importation à utiliser (API ou CLI, par défaut: CLI)
- `-ApiKey` : API Key à utiliser pour l'importation via API
- `-Hostname` : Hôte n8n pour l'importation via API (par défaut: localhost)
- `-Port` : Port n8n pour l'importation via API (par défaut: 5678)
- `-Protocol` : Protocole pour l'importation via API (http ou https) (par défaut: http)
- `-Tags` : Tags à ajouter aux workflows importés (séparés par des virgules)
- `-Active` : Indique si les workflows importés doivent être activés (par défaut: $true)
- `-Force` : Force l'importation même si le workflow existe déjà (par défaut: $false)
- `-LogFile` : Fichier de log pour l'importation (par défaut: n8n/logs/import-workflows.log)
- `-Recursive` : Indique si les sous-dossiers doivent être parcourus récursivement (par défaut: $true)
- `-BackupFolder` : Dossier de sauvegarde pour les workflows existants avant importation (par défaut: n8n/data/.n8n/workflows/backup)

### Importation en masse

Le script `import-workflows-bulk.cmd` permet d'importer un grand nombre de workflows en parallèle :

```
.\import-workflows-bulk.cmd -SourceFolder "path/to/workflows" -Method "API" -MaxConcurrent 10 -BatchSize 20
```

Options supplémentaires :

- `-MaxConcurrent` : Nombre maximum d'importations simultanées (par défaut: 5)
- `-BatchSize` : Taille des lots pour l'importation en masse (par défaut: 10)

## Méthodes d'importation

### Importation via CLI

L'importation via CLI utilise la commande `npx n8n import:workflow` pour importer les workflows. Cette méthode est recommandée pour les environnements où n8n est installé localement.

Avantages :
- Plus simple à configurer
- Pas besoin d'API Key
- Moins de problèmes d'authentification

Inconvénients :
- Nécessite que n8n soit installé localement
- Plus lent pour l'importation en masse

### Importation via API

L'importation via API utilise l'API REST de n8n pour importer les workflows. Cette méthode est recommandée pour les environnements où n8n est accessible via une API REST.

Avantages :
- Plus rapide pour l'importation en masse
- Peut être utilisé avec n8n hébergé à distance
- Plus flexible pour l'intégration avec d'autres systèmes

Inconvénients :
- Nécessite une API Key
- Plus complexe à configurer
- Peut rencontrer des problèmes d'authentification

## Structure des fichiers

Les workflows doivent être stockés dans des fichiers JSON avec la structure suivante :

```json
{
  "name": "Nom du workflow",
  "nodes": [...],
  "connections": {...},
  "active": false,
  "settings": {...},
  "tags": [...]
}
```

Les fichiers peuvent être organisés dans des dossiers et sous-dossiers. Le script parcourt récursivement tous les dossiers par défaut.

## Gestion des erreurs

Le script gère les erreurs suivantes :

- Fichiers JSON invalides
- Fichiers qui ne sont pas des workflows n8n valides
- Erreurs d'importation via CLI ou API
- Erreurs de copie des fichiers
- Conflits de noms de fichiers

En cas d'erreur, le script :
1. Enregistre l'erreur dans le fichier de log
2. Affiche l'erreur dans la console
3. Continue avec le fichier suivant
4. Fournit un résumé des erreurs à la fin de l'importation

## Sauvegarde des workflows existants

Avant d'importer un workflow qui existe déjà dans le dossier cible, le script sauvegarde le workflow existant dans le dossier de sauvegarde spécifié. Les sauvegardes sont horodatées pour éviter les conflits de noms.

## Optimisation pour les grands volumes

Le script `import-workflows-bulk.ps1` est optimisé pour l'importation de grands volumes de workflows :

1. Il divise les fichiers en lots de taille configurable
2. Il traite les lots en parallèle avec un nombre maximum d'importations simultanées configurable
3. Il utilise ForEach-Object -Parallel sur PowerShell 7+ ou des jobs sur PowerShell 5.1
4. Il fournit un suivi de l'avancement par lot

## Exemples d'utilisation

### Importation simple

```
.\import-workflows-auto.cmd -SourceFolder "n8n/core/workflows/local" -Method "CLI"
```

### Importation avec tags et activation

```
.\import-workflows-auto.cmd -SourceFolder "n8n/core/workflows/local" -Method "CLI" -Tags "imported,local" -Active $true
```

### Importation via API

```
.\import-workflows-auto.cmd -SourceFolder "n8n/core/workflows/local" -Method "API" -Hostname "localhost" -Port 5678 -Protocol "http"
```

### Importation en masse

```
.\import-workflows-bulk.cmd -SourceFolder "n8n/core/workflows/local" -Method "CLI" -MaxConcurrent 10 -BatchSize 20
```

### Importation forcée (écrase les workflows existants)

```
.\import-workflows-auto.cmd -SourceFolder "n8n/core/workflows/local" -Method "CLI" -Force
```

## Résolution des problèmes

### Erreur "Le fichier n'est pas un workflow n8n valide"

Vérifiez que le fichier JSON est valide et contient les propriétés requises d'un workflow n8n (name, nodes, etc.).

### Erreur "Échec de l'importation du workflow via CLI"

Vérifiez que n8n est installé localement et accessible via la commande `npx n8n`.

### Erreur "Échec de l'importation du workflow via API"

Vérifiez que :
1. n8n est en cours d'exécution
2. L'API Key est correcte
3. L'URL de l'API est correcte
4. L'authentification est correctement configurée dans n8n

### Erreur "Le fichier cible existe déjà"

Utilisez l'option `-Force` pour écraser les workflows existants.

### Performances lentes lors de l'importation en masse

Utilisez le script `import-workflows-bulk.cmd` avec des valeurs plus élevées pour `-MaxConcurrent` et `-BatchSize`.

## Logs

Les logs sont enregistrés dans le fichier spécifié par l'option `-LogFile` (par défaut: n8n/logs/import-workflows.log). Les logs contiennent les informations suivantes :

- Date et heure de chaque action
- Niveau de log (INFO, WARNING, ERROR, SUCCESS)
- Description de l'action
- Résultats de l'action
- Erreurs rencontrées
- Résumé de l'importation

Exemple de log :

```
[2025-04-22 10:15:30] [INFO] === Importation automatique des workflows n8n ===
[2025-04-22 10:15:30] [INFO] Dossier source: n8n/core/workflows/local
[2025-04-22 10:15:30] [INFO] Dossier cible: n8n/data/.n8n/workflows
[2025-04-22 10:15:30] [INFO] Méthode d'importation: CLI
[2025-04-22 10:15:30] [INFO] Nombre de fichiers à importer: 10
[2025-04-22 10:15:31] [INFO] Traitement du fichier: n8n/core/workflows/local/workflow1.json
[2025-04-22 10:15:32] [SUCCESS] Workflow importé avec succès: workflow1.json
[2025-04-22 10:15:32] [INFO] Traitement du fichier: n8n/core/workflows/local/workflow2.json
[2025-04-22 10:15:33] [ERROR] Échec de l'importation du workflow: workflow2.json
[2025-04-22 10:15:35] [INFO] === Résumé de l'importation ===
[2025-04-22 10:15:35] [INFO] Total des fichiers: 10
[2025-04-22 10:15:35] [SUCCESS] Succès: 9
[2025-04-22 10:15:35] [ERROR] Échecs: 1
[2025-04-22 10:15:35] [INFO] Taux de réussite: 90%
```
