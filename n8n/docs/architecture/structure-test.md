# Test structurel de n8n

Ce document explique comment utiliser les scripts de test structurel pour vérifier l'intégrité et la structure des composants n8n.

## Vue d'ensemble

Le test structurel de n8n permet de :

1. Vérifier la présence des dossiers, fichiers et scripts nécessaires
2. Valider la structure des workflows n8n
3. Vérifier la configuration du système
4. Corriger automatiquement les problèmes détectés (optionnel)
5. Générer des rapports détaillés sur l'état de la structure

## Script disponible

Le script `test-structure.cmd` permet de vérifier la structure de n8n :

```
.\test-structure.cmd -N8nRootFolder "n8n" -FixIssues $true
```

Options disponibles :

- `-N8nRootFolder` : Dossier racine de n8n (par défaut: n8n)
- `-WorkflowFolder` : Dossier contenant les workflows n8n (par défaut: n8n/data/.n8n/workflows)
- `-ConfigFolder` : Dossier contenant les fichiers de configuration (par défaut: n8n/config)
- `-LogFolder` : Dossier contenant les fichiers de log (par défaut: n8n/logs)
- `-LogFile` : Fichier de log pour le test structurel (par défaut: n8n/logs/structure-test.log)
- `-ReportFile` : Fichier de rapport JSON pour le test structurel (par défaut: n8n/logs/structure-test-report.json)
- `-HtmlReportFile` : Fichier de rapport HTML pour le test structurel (par défaut: n8n/logs/structure-test-report.html)
- `-TestLevel` : Niveau de détail du test (1: Basic, 2: Standard, 3: Detailed) (par défaut: 2)
- `-FixIssues` : Indique si les problèmes détectés doivent être corrigés automatiquement (par défaut: $false)
- `-NotificationEnabled` : Indique si les notifications doivent être envoyées (par défaut: $true)
- `-NotificationScript` : Script à utiliser pour envoyer les notifications (par défaut: n8n/automation/notification/send-notification.ps1)
- `-NotificationLevel` : Niveau minimum pour envoyer une notification (INFO, WARNING, ERROR) (par défaut: WARNING)

## Structure attendue

Le script vérifie la présence des éléments suivants :

### Dossiers

```
n8n/automation
n8n/automation/deployment
n8n/automation/monitoring
n8n/automation/diagnostics
n8n/automation/notification
n8n/config
n8n/core
n8n/core/workflows
n8n/core/workflows/local
n8n/data
n8n/data/.n8n
n8n/data/.n8n/workflows
n8n/docs
n8n/docs/architecture
n8n/logs
```

### Fichiers

```
n8n/config/notification-config.json
n8n/core/n8n-config.json
n8n/.env
```

### Scripts

```
n8n/automation/deployment/start-n8n.ps1
n8n/automation/deployment/stop-n8n.ps1
n8n/automation/monitoring/check-n8n-status.ps1
n8n/automation/notification/send-notification.ps1
```

## Tests effectués

Le script effectue les tests suivants :

### 1. Test de la structure des dossiers

Vérifie la présence des dossiers nécessaires au fonctionnement de n8n.

### 2. Test de la structure des fichiers

Vérifie la présence des fichiers de configuration et autres fichiers nécessaires.

### 3. Test de la structure des scripts

Vérifie la présence des scripts nécessaires et leur validité syntaxique.

### 4. Test de la structure des workflows

Vérifie la présence et la validité des workflows n8n.

### 5. Test de la structure de configuration

Vérifie la présence et la validité des fichiers de configuration.

## Correction automatique

Si l'option `-FixIssues` est activée, le script tente de corriger automatiquement les problèmes détectés :

- Création des dossiers manquants
- Création des fichiers manquants avec un contenu par défaut
- Création des scripts manquants avec un modèle de base

## Rapports

Le script génère deux types de rapports :

### Rapport JSON

Le rapport JSON contient toutes les informations détaillées sur les tests effectués et les problèmes détectés. Il est enregistré dans le fichier spécifié par l'option `-ReportFile`.

Exemple de structure du rapport JSON :

```json
{
  "FolderStructure": {
    "Tested": 15,
    "Passed": 14,
    "Failed": 1,
    "Fixed": 1,
    "Issues": [
      {
        "Type": "MissingFolder",
        "Path": "n8n/logs",
        "Fixed": true,
        "Message": "Dossier manquant: n8n/logs"
      }
    ]
  },
  "FileStructure": {
    "Tested": 3,
    "Passed": 2,
    "Failed": 1,
    "Fixed": 0,
    "Issues": [
      {
        "Type": "MissingFile",
        "Path": "n8n/.env",
        "Fixed": false,
        "Message": "Fichier manquant: n8n/.env"
      }
    ]
  },
  ...
  "Summary": {
    "TotalTested": 30,
    "TotalPassed": 28,
    "TotalFailed": 2,
    "TotalFixed": 1,
    "SuccessRate": 93.33
  },
  "TestInfo": {
    "Date": "2025-04-22 10:15:30",
    "N8nRootFolder": "n8n",
    "WorkflowFolder": "n8n/data/.n8n/workflows",
    "ConfigFolder": "n8n/config",
    "LogFolder": "n8n/logs",
    "TestLevel": 2,
    "FixIssues": true
  }
}
```

### Rapport HTML

Le rapport HTML présente les résultats des tests de manière plus visuelle et conviviale. Il est enregistré dans le fichier spécifié par l'option `-HtmlReportFile`.

Le rapport HTML contient :

- Un résumé des tests effectués
- Le taux de réussite global
- Les détails des problèmes détectés
- Les actions correctives effectuées

## Notifications

Si l'option `-NotificationEnabled` est activée, le script envoie des notifications en cas de problèmes détectés. Les notifications sont envoyées via le script spécifié par l'option `-NotificationScript`.

Le niveau minimum pour envoyer une notification peut être configuré avec l'option `-NotificationLevel` :

- `INFO` : Envoie des notifications pour tous les résultats
- `WARNING` : Envoie des notifications uniquement en cas de problèmes mineurs ou majeurs
- `ERROR` : Envoie des notifications uniquement en cas de problèmes majeurs

## Exemples d'utilisation

### Test simple

```
.\test-structure.cmd
```

### Test avec correction automatique

```
.\test-structure.cmd -FixIssues $true
```

### Test détaillé

```
.\test-structure.cmd -TestLevel 3 -HtmlReportFile "n8n/logs/detailed-structure-report.html"
```

### Test sans notifications

```
.\test-structure.cmd -NotificationEnabled $false
```

### Test avec un dossier racine différent

```
.\test-structure.cmd -N8nRootFolder "path/to/n8n"
```

## Intégration avec des tâches planifiées

Le script peut être intégré avec des tâches planifiées pour vérifier régulièrement la structure de n8n.

### Windows Task Scheduler

1. Ouvrez Task Scheduler
2. Créez une nouvelle tâche
3. Configurez le déclencheur (par exemple, tous les jours à 8h00)
4. Configurez l'action : Démarrer un programme
5. Programme/script : `cmd.exe`
6. Arguments : `/c "cd /d D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1 && test-structure.cmd -FixIssues $true"`

### Cron (Linux)

```
0 8 * * * cd /path/to/project && ./test-structure.cmd -FixIssues $true
```

## Résolution des problèmes

### Erreur "Le dossier n'existe pas"

Vérifiez que le dossier racine de n8n est correctement spécifié avec l'option `-N8nRootFolder`.

### Erreur "Échec de la création du dossier/fichier"

Vérifiez que l'utilisateur qui exécute le script a les droits d'écriture dans les dossiers concernés.

### Erreur "Script invalide"

Vérifiez que les scripts PowerShell sont valides et ne contiennent pas d'erreurs de syntaxe.

### Erreur "Échec de l'envoi de la notification"

Vérifiez que la configuration des notifications est correcte et que les services de notification sont accessibles.

## Logs

Les logs sont enregistrés dans le fichier spécifié par l'option `-LogFile` (par défaut: n8n/logs/structure-test.log). Les logs contiennent les informations suivantes :

- Date et heure de chaque action
- Niveau de log (INFO, WARNING, ERROR, SUCCESS)
- Description de l'action
- Résultats de l'action
- Erreurs rencontrées
- Résumé du test

Exemple de log :

```
[2025-04-22 10:15:30] [INFO] === Test structurel n8n ===
[2025-04-22 10:15:30] [INFO] Dossier racine: n8n
[2025-04-22 10:15:30] [INFO] Dossier des workflows: n8n/data/.n8n/workflows
[2025-04-22 10:15:30] [INFO] Dossier de configuration: n8n/config
[2025-04-22 10:15:30] [INFO] Dossier de log: n8n/logs
[2025-04-22 10:15:30] [INFO] Niveau de test: 2
[2025-04-22 10:15:30] [INFO] Correction automatique: True
[2025-04-22 10:15:30] [INFO] Notifications activées: True
[2025-04-22 10:15:30] [INFO] === Test de la structure des dossiers ===
[2025-04-22 10:15:30] [INFO] Dossier présent: n8n/automation
[2025-04-22 10:15:30] [INFO] Dossier présent: n8n/automation/deployment
[2025-04-22 10:15:30] [WARNING] Dossier manquant: n8n/logs
[2025-04-22 10:15:30] [SUCCESS] Dossier créé: n8n/logs
[2025-04-22 10:15:31] [INFO] === Test de la structure des fichiers ===
[2025-04-22 10:15:31] [INFO] Fichier présent: n8n/config/notification-config.json
[2025-04-22 10:15:31] [WARNING] Fichier manquant: n8n/.env
[2025-04-22 10:15:32] [INFO] === Résumé du test structurel ===
[2025-04-22 10:15:32] [INFO] Éléments testés: 30
[2025-04-22 10:15:32] [SUCCESS] Éléments réussis: 28
[2025-04-22 10:15:32] [WARNING] Éléments échoués: 2
[2025-04-22 10:15:32] [SUCCESS] Éléments corrigés: 1
[2025-04-22 10:15:32] [SUCCESS] Taux de réussite: 93.33%
[2025-04-22 10:15:32] [SUCCESS] Rapport JSON généré: n8n/logs/structure-test-report.json
[2025-04-22 10:15:32] [SUCCESS] Rapport HTML généré: n8n/logs/structure-test-report.html
[2025-04-22 10:15:33] [SUCCESS] Notification envoyée: Test structurel n8n: 93.33% de réussite
```
