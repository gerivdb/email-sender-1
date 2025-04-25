# Surveillance du port et de l'API n8n

Ce document explique comment utiliser les scripts de surveillance du port et de l'API n8n.

## Vue d'ensemble

La surveillance du port et de l'API n8n permet de :

1. Vérifier si le port n8n est accessible
2. Vérifier si l'API n8n répond correctement
3. Envoyer des alertes en cas de problème
4. Générer des rapports sur l'état de n8n
5. Redémarrer automatiquement n8n en cas de problème (optionnel)

## Scripts disponibles

### Surveillance du port et de l'API

Le script `check-n8n-status.cmd` permet de vérifier l'état du port et de l'API n8n :

```
.\check-n8n-status.cmd -Hostname "localhost" -Port 5678 -Protocol "http"
```

Options disponibles :

- `-Hostname` : Nom d'hôte ou adresse IP du serveur n8n (par défaut: localhost)
- `-Port` : Port utilisé par n8n (par défaut: 5678)
- `-Protocol` : Protocole utilisé par n8n (http ou https) (par défaut: http)
- `-ApiKey` : API Key à utiliser pour les requêtes API
- `-Endpoints` : Liste des endpoints à tester (par défaut: /, /healthz, /api/v1/executions)
- `-Timeout` : Timeout en secondes pour les requêtes (par défaut: 10)
- `-RetryCount` : Nombre de tentatives en cas d'échec (par défaut: 3)
- `-RetryDelay` : Délai en secondes entre les tentatives (par défaut: 2)
- `-LogFile` : Fichier de log pour la surveillance (par défaut: n8n/logs/n8n-status.log)
- `-ReportFile` : Fichier de rapport JSON pour la surveillance (par défaut: n8n/logs/n8n-status-report.json)
- `-HtmlReportFile` : Fichier de rapport HTML pour la surveillance (par défaut: n8n/logs/n8n-status-report.html)
- `-NotificationEnabled` : Indique si les notifications doivent être envoyées (par défaut: $true)
- `-NotificationScript` : Script à utiliser pour envoyer les notifications (par défaut: n8n/automation/notification/send-notification.ps1)
- `-NotificationLevel` : Niveau minimum pour envoyer une notification (INFO, WARNING, ERROR) (par défaut: WARNING)
- `-HistoryLength` : Nombre d'historiques à conserver (par défaut: 10)
- `-HistoryFolder` : Dossier pour stocker l'historique des résultats (par défaut: n8n/logs/history)
- `-AutoRestart` : Indique si n8n doit être redémarré automatiquement en cas de problème (par défaut: $false)
- `-RestartScript` : Script à utiliser pour redémarrer n8n (par défaut: n8n/automation/deployment/restart-n8n.ps1)
- `-RestartThreshold` : Nombre d'échecs consécutifs avant redémarrage (par défaut: 3)

### Redémarrage de n8n

Le script `restart-n8n.cmd` permet de redémarrer n8n :

```
.\restart-n8n.cmd
```

Options disponibles :

- `-LogFile` : Fichier de log pour le redémarrage (par défaut: n8n/logs/restart-n8n.log)
- `-StartScript` : Script à utiliser pour démarrer n8n (par défaut: n8n/automation/deployment/start-n8n.ps1)
- `-StopScript` : Script à utiliser pour arrêter n8n (par défaut: n8n/automation/deployment/stop-n8n.ps1)
- `-WaitBeforeStart` : Temps d'attente en secondes entre l'arrêt et le démarrage (par défaut: 5)
- `-NotificationEnabled` : Indique si les notifications doivent être envoyées (par défaut: $true)
- `-NotificationScript` : Script à utiliser pour envoyer les notifications (par défaut: n8n/automation/notification/send-notification.ps1)

## Tests effectués

Le script de surveillance effectue les tests suivants :

### 1. Test du port

Vérifie si le port n8n est accessible en établissant une connexion TCP.

### 2. Test des endpoints

Vérifie si les endpoints n8n répondent correctement en envoyant des requêtes HTTP.

Par défaut, les endpoints suivants sont testés :

- `/` : Page d'accueil de n8n
- `/healthz` : Endpoint de santé de n8n
- `/api/v1/executions` : API des exécutions de workflows (nécessite une API Key)

## Redémarrage automatique

Si l'option `-AutoRestart` est activée, le script peut redémarrer automatiquement n8n en cas de problème.

Le redémarrage est déclenché lorsque le nombre d'échecs consécutifs atteint le seuil spécifié par l'option `-RestartThreshold`.

Le redémarrage est effectué en utilisant le script spécifié par l'option `-RestartScript`.

## Rapports

Le script génère deux types de rapports :

### Rapport JSON

Le rapport JSON contient toutes les informations détaillées sur les tests effectués. Il est enregistré dans le fichier spécifié par l'option `-ReportFile`.

Exemple de structure du rapport JSON :

```json
{
  "PortTest": {
    "Success": true,
    "ResponseTime": 5.123,
    "Error": "",
    "Attempts": 1
  },
  "EndpointTests": {
    "/": {
      "Success": true,
      "StatusCode": 200,
      "ResponseTime": 120.456,
      "Response": "...",
      "Error": "",
      "Attempts": 1
    },
    "/healthz": {
      "Success": true,
      "StatusCode": 200,
      "ResponseTime": 80.789,
      "Response": "...",
      "Error": "",
      "Attempts": 1
    },
    "/api/v1/executions": {
      "Success": false,
      "StatusCode": 401,
      "ResponseTime": 0,
      "Response": "...",
      "Error": "Erreur HTTP: Unauthorized",
      "Attempts": 3
    }
  },
  "OverallSuccess": false,
  "StartTime": "2025-04-22T10:15:30",
  "EndTime": "2025-04-22T10:15:32",
  "TotalTime": 2000.123
}
```

### Rapport HTML

Le rapport HTML présente les résultats des tests de manière plus visuelle et conviviale. Il est enregistré dans le fichier spécifié par l'option `-HtmlReportFile`.

Le rapport HTML contient :

- Un résumé des tests effectués
- Le statut global de n8n
- Les détails des tests du port et des endpoints
- L'historique des tests précédents

## Historique

Le script conserve un historique des résultats des tests précédents. Cet historique est utilisé pour :

- Déterminer si n8n doit être redémarré automatiquement
- Afficher l'évolution de l'état de n8n dans le rapport HTML
- Détecter les changements d'état de n8n (passage de non opérationnel à opérationnel)

L'historique est stocké dans le dossier spécifié par l'option `-HistoryFolder`. Le nombre d'historiques à conserver est spécifié par l'option `-HistoryLength`.

## Notifications

Le script peut envoyer des notifications en cas de problème ou de changement d'état de n8n. Les notifications sont envoyées via le script spécifié par l'option `-NotificationScript`.

Les notifications sont envoyées dans les cas suivants :

- n8n n'est pas accessible (port fermé ou endpoints inaccessibles)
- n8n est de nouveau opérationnel après un problème
- n8n a été redémarré automatiquement

Le niveau minimum pour envoyer une notification peut être configuré avec l'option `-NotificationLevel` :

- `INFO` : Envoie des notifications pour tous les événements
- `WARNING` : Envoie des notifications uniquement en cas de problèmes mineurs ou majeurs
- `ERROR` : Envoie des notifications uniquement en cas de problèmes majeurs

## Exemples d'utilisation

### Surveillance simple

```
.\check-n8n-status.cmd
```

### Surveillance avec redémarrage automatique

```
.\check-n8n-status.cmd -AutoRestart $true -RestartThreshold 3
```

### Surveillance d'un serveur distant

```
.\check-n8n-status.cmd -Hostname "n8n.example.com" -Port 5678 -Protocol "https"
```

### Surveillance avec API Key

```
.\check-n8n-status.cmd -ApiKey "votre-api-key"
```

### Surveillance avec endpoints personnalisés

```
.\check-n8n-status.cmd -Endpoints @("/", "/healthz", "/api/v1/workflows")
```

### Redémarrage manuel

```
.\restart-n8n.cmd
```

## Intégration avec des tâches planifiées

Le script peut être intégré avec des tâches planifiées pour surveiller régulièrement l'état de n8n.

### Windows Task Scheduler

1. Ouvrez Task Scheduler
2. Créez une nouvelle tâche
3. Configurez le déclencheur (par exemple, toutes les 5 minutes)
4. Configurez l'action : Démarrer un programme
5. Programme/script : `cmd.exe`
6. Arguments : `/c "cd /d D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1 && check-n8n-status.cmd -AutoRestart $true"`

### Cron (Linux)

```
*/5 * * * * cd /path/to/project && ./check-n8n-status.cmd -AutoRestart $true
```

## Résolution des problèmes

### Erreur "Le port n'est pas accessible"

Vérifiez que n8n est en cours d'exécution et que le port spécifié est correct.

### Erreur "Échec de l'accès à l'endpoint"

Vérifiez que n8n est en cours d'exécution et que les endpoints spécifiés sont corrects.

### Erreur "Unauthorized" pour l'endpoint `/api/v1/executions`

Vérifiez que l'API Key spécifiée est correcte et que l'authentification est correctement configurée dans n8n.

### Erreur "Script de redémarrage non trouvé"

Vérifiez que le script de redémarrage spécifié existe et est accessible.

### Erreur "Échec du redémarrage de n8n"

Vérifiez que les scripts de démarrage et d'arrêt spécifiés existent et sont accessibles.

## Logs

Les logs sont enregistrés dans le fichier spécifié par l'option `-LogFile` (par défaut: n8n/logs/n8n-status.log). Les logs contiennent les informations suivantes :

- Date et heure de chaque action
- Niveau de log (INFO, WARNING, ERROR, SUCCESS)
- Description de l'action
- Résultats de l'action
- Erreurs rencontrées
- Résumé de la surveillance

Exemple de log :

```
[2025-04-22 10:15:30] [INFO] === Surveillance du port et de l'API n8n ===
[2025-04-22 10:15:30] [INFO] Hôte: localhost
[2025-04-22 10:15:30] [INFO] Port: 5678
[2025-04-22 10:15:30] [INFO] Protocole: http
[2025-04-22 10:15:30] [INFO] Endpoints à tester: /, /healthz, /api/v1/executions
[2025-04-22 10:15:30] [INFO] Timeout: 10 secondes
[2025-04-22 10:15:30] [INFO] Nombre de tentatives: 3
[2025-04-22 10:15:30] [INFO] Délai entre les tentatives: 2 secondes
[2025-04-22 10:15:30] [INFO] Redémarrage automatique: True
[2025-04-22 10:15:30] [INFO] Test du port 5678 sur localhost...
[2025-04-22 10:15:30] [SUCCESS] Port 5678 accessible sur localhost (Temps de réponse: 5.123 ms)
[2025-04-22 10:15:30] [INFO] Test de l'endpoint: http://localhost:5678/
[2025-04-22 10:15:31] [SUCCESS] Endpoint http://localhost:5678/ accessible (Code: 200, Temps: 120.456 ms)
[2025-04-22 10:15:31] [INFO] Test de l'endpoint: http://localhost:5678/healthz
[2025-04-22 10:15:31] [SUCCESS] Endpoint http://localhost:5678/healthz accessible (Code: 200, Temps: 80.789 ms)
[2025-04-22 10:15:31] [INFO] Test de l'endpoint: http://localhost:5678/api/v1/executions
[2025-04-22 10:15:31] [WARNING] Tentative 1 échouée. Nouvelle tentative dans 2 secondes...
[2025-04-22 10:15:33] [WARNING] Tentative 2 échouée. Nouvelle tentative dans 2 secondes...
[2025-04-22 10:15:35] [ERROR] Échec de l'accès à l'endpoint http://localhost:5678/api/v1/executions: Erreur HTTP: Unauthorized
[2025-04-22 10:15:35] [SUCCESS] Résultats enregistrés dans le fichier: n8n/logs/n8n-status-report.json
[2025-04-22 10:15:35] [INFO] Résultats sauvegardés dans l'historique: n8n/logs/history/n8n-status-20250422_101535.json
[2025-04-22 10:15:35] [SUCCESS] Rapport HTML généré: n8n/logs/n8n-status-report.html
[2025-04-22 10:15:35] [SUCCESS] Notification envoyée: Problème détecté avec n8n
[2025-04-22 10:15:35] [INFO] === Résumé de la surveillance ===
[2025-04-22 10:15:35] [ERROR] Statut global: Non opérationnel
[2025-04-22 10:15:35] [SUCCESS] Port 5678: Accessible
[2025-04-22 10:15:35] [SUCCESS] Endpoint /: Accessible
[2025-04-22 10:15:35] [SUCCESS] Endpoint /healthz: Accessible
[2025-04-22 10:15:35] [ERROR] Endpoint /api/v1/executions: Non accessible
[2025-04-22 10:15:35] [INFO] Temps total du test: 2000.123 ms
[2025-04-22 10:15:35] [INFO] Rapport JSON: n8n/logs/n8n-status-report.json
[2025-04-22 10:15:35] [INFO] Rapport HTML: n8n/logs/n8n-status-report.html
```
