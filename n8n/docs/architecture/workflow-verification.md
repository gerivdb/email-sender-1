# Vérification de la présence des workflows n8n

Ce document explique comment utiliser les scripts de vérification de la présence des workflows n8n.

## Vue d'ensemble

La vérification de la présence des workflows n8n permet de :

1. Vérifier que tous les workflows de référence sont présents dans n8n
2. Détecter les workflows manquants
3. Envoyer des notifications en cas de workflows manquants
4. Générer des rapports détaillés sur l'état des workflows

## Scripts disponibles

### Vérification des workflows

Le script `verify-workflows.cmd` permet de vérifier la présence des workflows n8n :

```
.\verify-workflows.cmd -ReferenceFolder "path/to/reference" -WorkflowFolder "path/to/workflows"
```

Options disponibles :

- `-WorkflowFolder` : Dossier contenant les workflows cibles (par défaut: n8n/data/.n8n/workflows)
- `-ReferenceFolder` : Dossier contenant les workflows de référence (par défaut: n8n/core/workflows/local)
- `-ApiMethod` : Indique si la méthode API doit être utilisée pour récupérer les workflows cibles (par défaut: $false)
- `-Hostname` : Hôte n8n pour la méthode API (par défaut: localhost)
- `-Port` : Port n8n pour la méthode API (par défaut: 5678)
- `-Protocol` : Protocole pour la méthode API (http ou https) (par défaut: http)
- `-ApiKey` : API Key à utiliser pour la méthode API
- `-LogFile` : Fichier de log pour la vérification (par défaut: n8n/logs/verify-workflows.log)
- `-Recursive` : Indique si les sous-dossiers doivent être parcourus récursivement (par défaut: $true)
- `-NotificationEnabled` : Indique si les notifications doivent être envoyées (par défaut: $true)
- `-NotificationScript` : Script à utiliser pour envoyer les notifications (par défaut: n8n/automation/notification/send-notification.ps1)
- `-NotificationLevel` : Niveau minimum pour envoyer une notification (INFO, WARNING, ERROR) (par défaut: WARNING)
- `-OutputFile` : Fichier de sortie pour les résultats de la vérification (par défaut: n8n/logs/missing-workflows.json)
- `-DetailLevel` : Niveau de détail des résultats (1: Basic, 2: Standard, 3: Detailed) (par défaut: 2)

### Envoi de notifications

Le script `send-notification.cmd` permet d'envoyer des notifications :

```
.\send-notification.cmd -Subject "Test" -Message "Ceci est un test" -Level "INFO"
```

Options disponibles :

- `-Subject` : Sujet de la notification
- `-Message` : Message de la notification
- `-Level` : Niveau de la notification (INFO, WARNING, ERROR) (par défaut: INFO)
- `-Channel` : Canal de notification à utiliser (Email, Teams, Slack, All) (par défaut: All)
- `-ConfigFile` : Fichier de configuration pour les notifications (par défaut: n8n/config/notification-config.json)

## Méthodes de vérification

### Vérification via le système de fichiers

La vérification via le système de fichiers compare les workflows de référence avec les workflows cibles en utilisant le système de fichiers. Cette méthode est recommandée pour les environnements où n8n stocke ses workflows dans des fichiers JSON.

Avantages :
- Plus simple à configurer
- Pas besoin d'API Key
- Moins de problèmes d'authentification

Inconvénients :
- Nécessite un accès au système de fichiers de n8n
- Peut ne pas fonctionner si n8n utilise une base de données pour stocker les workflows

### Vérification via l'API

La vérification via l'API utilise l'API REST de n8n pour récupérer les workflows cibles. Cette méthode est recommandée pour les environnements où n8n est accessible via une API REST.

Avantages :
- Fonctionne même si n8n utilise une base de données pour stocker les workflows
- Peut être utilisé avec n8n hébergé à distance
- Plus flexible pour l'intégration avec d'autres systèmes

Inconvénients :
- Nécessite une API Key
- Plus complexe à configurer
- Peut rencontrer des problèmes d'authentification

## Structure des fichiers

Les workflows de référence doivent être stockés dans des fichiers JSON avec la structure suivante :

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

## Notifications

Le script peut envoyer des notifications en cas de workflows manquants. Les notifications peuvent être envoyées via différents canaux :

- Email
- Microsoft Teams
- Slack

### Configuration des notifications

Les notifications sont configurées dans le fichier `n8n/config/notification-config.json` :

```json
{
  "Email": {
    "Enabled": false,
    "SmtpServer": "smtp.example.com",
    "SmtpPort": 587,
    "UseSsl": true,
    "Sender": "n8n@example.com",
    "Recipients": [
      "admin@example.com"
    ],
    "Username": "",
    "Password": ""
  },
  "Teams": {
    "Enabled": false,
    "WebhookUrl": "https://outlook.office.com/webhook/..."
  },
  "Slack": {
    "Enabled": false,
    "WebhookUrl": "https://hooks.slack.com/services/..."
  }
}
```

Pour activer un canal de notification, définissez `Enabled` à `true` et configurez les paramètres correspondants.

### Niveaux de notification

Les notifications peuvent être envoyées avec différents niveaux :

- `INFO` : Informations générales
- `WARNING` : Avertissements (par exemple, quelques workflows manquants)
- `ERROR` : Erreurs (par exemple, de nombreux workflows manquants)

Le niveau minimum pour envoyer une notification peut être configuré avec l'option `-NotificationLevel`.

## Exemples d'utilisation

### Vérification simple

```
.\verify-workflows.cmd -ReferenceFolder "n8n/core/workflows/local" -WorkflowFolder "n8n/data/.n8n/workflows"
```

### Vérification via l'API

```
.\verify-workflows.cmd -ApiMethod $true -Hostname "localhost" -Port 5678
```

### Vérification avec notifications

```
.\verify-workflows.cmd -NotificationEnabled $true -NotificationLevel "WARNING"
```

### Vérification détaillée

```
.\verify-workflows.cmd -DetailLevel 3 -OutputFile "n8n/logs/detailed-workflow-report.json"
```

### Envoi d'une notification de test

```
.\send-notification.cmd -Subject "Test" -Message "Ceci est un test" -Level "INFO" -Channel "Email"
```

## Intégration avec des tâches planifiées

Le script peut être intégré avec des tâches planifiées pour vérifier régulièrement la présence des workflows n8n.

### Windows Task Scheduler

1. Ouvrez Task Scheduler
2. Créez une nouvelle tâche
3. Configurez le déclencheur (par exemple, tous les jours à 8h00)
4. Configurez l'action : Démarrer un programme
5. Programme/script : `cmd.exe`
6. Arguments : `/c "cd /d D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1 && verify-workflows.cmd"`

### Cron (Linux)

```
0 8 * * * cd /path/to/project && ./verify-workflows.cmd
```

## Résolution des problèmes

### Erreur "Le dossier n'existe pas"

Vérifiez que les dossiers spécifiés existent et sont accessibles.

### Erreur "Aucun workflow de référence trouvé"

Vérifiez que le dossier de référence contient des fichiers JSON valides avec la structure d'un workflow n8n.

### Erreur "Échec de l'envoi de la notification"

Vérifiez que la configuration des notifications est correcte et que les services de notification sont accessibles.

### Erreur "Erreur lors de la récupération des workflows via API"

Vérifiez que :
1. n8n est en cours d'exécution
2. L'API Key est correcte
3. L'URL de l'API est correcte
4. L'authentification est correctement configurée dans n8n

## Logs

Les logs sont enregistrés dans le fichier spécifié par l'option `-LogFile` (par défaut: n8n/logs/verify-workflows.log). Les logs contiennent les informations suivantes :

- Date et heure de chaque action
- Niveau de log (INFO, WARNING, ERROR, SUCCESS)
- Description de l'action
- Résultats de l'action
- Erreurs rencontrées
- Résumé de la vérification

Exemple de log :

```
[2025-04-22 10:15:30] [INFO] === Vérification de la présence des workflows n8n ===
[2025-04-22 10:15:30] [INFO] Dossier des workflows: n8n/data/.n8n/workflows
[2025-04-22 10:15:30] [INFO] Dossier de référence: n8n/core/workflows/local
[2025-04-22 10:15:30] [INFO] Méthode API: False
[2025-04-22 10:15:31] [INFO] Récupération des workflows de référence...
[2025-04-22 10:15:32] [INFO] Nombre de workflows de référence: 10
[2025-04-22 10:15:32] [INFO] Récupération des workflows depuis le dossier: n8n/data/.n8n/workflows
[2025-04-22 10:15:33] [INFO] Nombre de workflows cibles: 8
[2025-04-22 10:15:33] [INFO] Comparaison des workflows...
[2025-04-22 10:15:33] [WARNING] Nombre de workflows manquants: 2
[2025-04-22 10:15:33] [INFO] Nombre de workflows présents: 8
[2025-04-22 10:15:33] [WARNING] === Workflows manquants ===
[2025-04-22 10:15:33] [WARNING]   - Workflow1 (Fichier: n8n/core/workflows/local/workflow1.json)
[2025-04-22 10:15:33] [WARNING]   - Workflow2 (Fichier: n8n/core/workflows/local/workflow2.json)
[2025-04-22 10:15:34] [INFO] Résultats enregistrés dans le fichier: n8n/logs/missing-workflows.json
[2025-04-22 10:15:35] [SUCCESS] Notification envoyée: Vérification des workflows n8n: 2 workflows manquants
[2025-04-22 10:15:35] [INFO] === Résumé de la vérification ===
[2025-04-22 10:15:35] [INFO] Nombre de workflows de référence: 10
[2025-04-22 10:15:35] [INFO] Nombre de workflows cibles: 8
[2025-04-22 10:15:35] [WARNING] Nombre de workflows manquants: 2
[2025-04-22 10:15:35] [INFO] Nombre de workflows présents: 8
```

## Résultats de la vérification

Les résultats de la vérification sont enregistrés dans le fichier spécifié par l'option `-OutputFile` (par défaut: n8n/logs/missing-workflows.json). Les résultats contiennent les informations suivantes :

- Liste des workflows manquants
- Liste des workflows présents
- Nombre de workflows de référence
- Nombre de workflows cibles
- Nombre de workflows manquants
- Nombre de workflows présents

Exemple de résultats :

```json
{
  "MissingWorkflows": [
    {
      "Name": "Workflow1",
      "ReferenceFilePath": "n8n/core/workflows/local/workflow1.json",
      "ReferenceLastModified": "2025-04-22T10:15:30",
      "NodeCount": 5
    },
    {
      "Name": "Workflow2",
      "ReferenceFilePath": "n8n/core/workflows/local/workflow2.json",
      "ReferenceLastModified": "2025-04-22T10:15:30",
      "NodeCount": 3
    }
  ],
  "PresentWorkflows": [
    {
      "Name": "Workflow3",
      "ReferenceFilePath": "n8n/core/workflows/local/workflow3.json",
      "TargetFilePath": "n8n/data/.n8n/workflows/workflow3.json",
      "ReferenceLastModified": "2025-04-22T10:15:30",
      "TargetLastModified": "2025-04-22T10:15:30",
      "IsNewer": false,
      "Active": true
    },
    ...
  ],
  "ReferenceCount": 10,
  "TargetCount": 8,
  "MissingCount": 2,
  "PresentCount": 8
}
```
