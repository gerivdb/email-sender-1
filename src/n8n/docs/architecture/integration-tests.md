# Tests d'intégration n8n

Ce document explique comment utiliser les tests d'intégration pour vérifier que tous les composants de la remédiation n8n fonctionnent correctement ensemble.

## Vue d'ensemble

Les tests d'intégration permettent de :

1. Vérifier que tous les composants de la remédiation n8n fonctionnent correctement ensemble
2. Détecter les problèmes d'intégration entre les différents modules
3. Valider le bon fonctionnement du système dans son ensemble
4. Générer des rapports détaillés sur les résultats des tests

## Scripts disponibles

### Tests d'intégration

Le script `integration-tests.cmd` permet d'exécuter les tests d'intégration :

```plaintext
.\integration-tests.cmd
```plaintext
Options disponibles :

- `-ScenariosFile` : Fichier JSON contenant les scénarios de test (par défaut: test-scenarios.json)
- `-LogFile` : Fichier de log pour les tests d'intégration (par défaut: n8n/logs/integration-tests.log)
- `-ReportFile` : Fichier de rapport JSON pour les tests d'intégration (par défaut: n8n/logs/integration-tests-report.json)
- `-HtmlReportFile` : Fichier de rapport HTML pour les tests d'intégration (par défaut: n8n/logs/integration-tests-report.html)
- `-ScenarioFilter` : Filtre pour exécuter uniquement certains scénarios (par défaut: tous les scénarios)
- `-PriorityFilter` : Filtre pour exécuter uniquement les scénarios avec une certaine priorité (par défaut: toutes les priorités)
- `-NotificationEnabled` : Indique si les notifications doivent être envoyées (par défaut: $true)
- `-NotificationScript` : Script à utiliser pour envoyer les notifications (par défaut: n8n/automation/notification/send-notification.ps1)

## Scénarios de test

Les scénarios de test sont définis dans le fichier `test-scenarios.json`. Chaque scénario contient :

- `id` : Identifiant unique du scénario
- `name` : Nom du scénario
- `description` : Description du scénario
- `priority` : Priorité du scénario (high, medium, low)
- `steps` : Liste des étapes du scénario

Chaque étape contient :

- `id` : Identifiant unique de l'étape
- `description` : Description de l'étape
- `command` : Commande PowerShell à exécuter
- `expectedResult` : Résultat attendu de la commande
- `continueOnFailure` : Indique si le scénario doit continuer en cas d'échec de l'étape

### Scénarios disponibles

#### Cycle de vie basique

Teste le cycle de vie basique de n8n (démarrage, vérification, arrêt).

Étapes :
1. Arrêter n8n s'il est en cours d'exécution
2. Démarrer n8n
3. Vérifier que n8n est en cours d'exécution
4. Vérifier l'état de n8n
5. Arrêter n8n
6. Vérifier que n8n est arrêté

#### Cycle de vie avancé

Teste le cycle de vie avancé de n8n (démarrage, redémarrage, arrêt).

Étapes :
1. Arrêter n8n s'il est en cours d'exécution
2. Démarrer n8n
3. Vérifier que n8n est en cours d'exécution
4. Redémarrer n8n
5. Vérifier que n8n est en cours d'exécution après redémarrage
6. Vérifier l'état de n8n après redémarrage
7. Arrêter n8n

#### Gestion des workflows

Teste la gestion des workflows (importation, vérification).

Étapes :
1. Arrêter n8n s'il est en cours d'exécution
2. Démarrer n8n
3. Importer des workflows
4. Vérifier la présence des workflows
5. Arrêter n8n

#### Test de structure

Teste la structure du système n8n.

Étapes :
1. Tester la structure

#### Test de bout en bout

Teste le système n8n de bout en bout.

Étapes :
1. Arrêter n8n s'il est en cours d'exécution
2. Tester la structure
3. Démarrer n8n
4. Vérifier l'état de n8n
5. Importer des workflows
6. Vérifier la présence des workflows
7. Redémarrer n8n
8. Vérifier l'état de n8n après redémarrage
9. Arrêter n8n

## Rapports

Le script génère deux types de rapports :

### Rapport JSON

Le rapport JSON contient toutes les informations détaillées sur les tests effectués. Il est enregistré dans le fichier spécifié par l'option `-ReportFile`.

Exemple de structure du rapport JSON :

```json
{
  "TestDate": "2025-04-24 10:15:30",
  "TotalScenarios": 5,
  "SuccessfulScenarios": 4,
  "FailedScenarios": 1,
  "TotalDuration": 120.5,
  "ScenarioResults": [
    {
      "Id": "lifecycle-basic",
      "Name": "Cycle de vie basique",
      "Description": "Teste le cycle de vie basique de n8n (démarrage, vérification, arrêt)",
      "Priority": "high",
      "StartTime": "2025-04-24T10:15:30",
      "EndTime": "2025-04-24T10:16:00",
      "Duration": 30.0,
      "Success": true,
      "StepResults": [
        {
          "Id": "stop-if-running",
          "Description": "Arrêter n8n s'il est en cours d'exécution",
          "Command": "...",
          "ExpectedResult": null,
          "StartTime": "2025-04-24T10:15:30",
          "EndTime": "2025-04-24T10:15:35",
          "Duration": 5.0,
          "ActualResult": true,
          "Success": true,
          "Error": null
        },
        ...
      ]
    },
    ...
  ]
}
```plaintext
### Rapport HTML

Le rapport HTML présente les résultats des tests de manière plus visuelle et conviviale. Il est enregistré dans le fichier spécifié par l'option `-HtmlReportFile`.

Le rapport HTML contient :

- Un résumé des tests effectués
- Le taux de réussite global
- Les détails de chaque scénario
- Les détails de chaque étape
- Les erreurs rencontrées

## Notifications

Si l'option `-NotificationEnabled` est activée, le script envoie des notifications en cas de problèmes détectés. Les notifications sont envoyées via le script spécifié par l'option `-NotificationScript`.

Le niveau de notification dépend du taux de réussite des tests :

- `INFO` : Taux de réussite >= 90%
- `WARNING` : Taux de réussite >= 70% et < 90%
- `ERROR` : Taux de réussite < 70%

## Exemples d'utilisation

### Exécuter tous les tests

```plaintext
.\n8n-test.cmd
```plaintext
### Exécuter un scénario spécifique

```plaintext
.\n8n-test.cmd -ScenarioFilter "lifecycle-basic"
```plaintext
### Exécuter les tests de haute priorité

```plaintext
.\n8n-test.cmd -PriorityFilter "high"
```plaintext
### Exécuter les tests sans notifications

```plaintext
.\n8n-test.cmd -NotificationEnabled $false
```plaintext
### Exécuter les tests avec un fichier de rapport personnalisé

```plaintext
.\n8n-test.cmd -HtmlReportFile "n8n/logs/custom-report.html"
```plaintext
## Intégration avec des tâches planifiées

Le script peut être intégré avec des tâches planifiées pour exécuter régulièrement les tests d'intégration.

### Windows Task Scheduler

1. Ouvrez Task Scheduler
2. Créez une nouvelle tâche
3. Configurez le déclencheur (par exemple, tous les jours à 8h00)
4. Configurez l'action : Démarrer un programme
5. Programme/script : `cmd.exe`
6. Arguments : `/c "cd /d D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1 && n8n-test.cmd"`

### Cron (Linux)

```plaintext
0 8 * * * cd /path/to/project && ./n8n-test.cmd
```plaintext
## Résolution des problèmes

### Erreur "Fichier de scénarios non trouvé"

Vérifiez que le fichier de scénarios existe et est accessible.

### Erreur "Aucun scénario de test trouvé"

Vérifiez que le fichier de scénarios contient des scénarios valides et que les filtres spécifiés correspondent à des scénarios existants.

### Erreur lors de l'exécution d'une commande

Vérifiez que la commande spécifiée dans l'étape est valide et peut être exécutée dans l'environnement actuel.

### Erreur "Script de notification non trouvé"

Vérifiez que le script de notification existe et est accessible.

## Personnalisation des tests

### Ajouter un nouveau scénario

Pour ajouter un nouveau scénario, modifiez le fichier `test-scenarios.json` et ajoutez un nouvel objet avec les propriétés suivantes :

```json
{
  "id": "nouveau-scenario",
  "name": "Nouveau scénario",
  "description": "Description du nouveau scénario",
  "priority": "high",
  "steps": [
    {
      "id": "etape-1",
      "description": "Description de l'étape 1",
      "command": "Commande PowerShell à exécuter",
      "expectedResult": true,
      "continueOnFailure": false
    },
    ...
  ]
}
```plaintext
### Modifier un scénario existant

Pour modifier un scénario existant, modifiez le fichier `test-scenarios.json` et mettez à jour les propriétés du scénario.

### Ajouter une étape à un scénario

Pour ajouter une étape à un scénario, modifiez le fichier `test-scenarios.json` et ajoutez un nouvel objet dans la liste `steps` du scénario.

## Logs

Les logs sont enregistrés dans le fichier spécifié par l'option `-LogFile` (par défaut: n8n/logs/integration-tests.log). Les logs contiennent les informations suivantes :

- Date et heure de chaque action
- Niveau de log (INFO, WARNING, ERROR, SUCCESS)
- Description de l'action
- Résultats de l'action
- Erreurs rencontrées
- Résumé des tests

Exemple de log :

```plaintext
[2025-04-24 10:15:30] [INFO] === Tests d'intégration n8n ===
[2025-04-24 10:15:30] [INFO] Fichier de scénarios: n8n/automation/tests/test-scenarios.json
[2025-04-24 10:15:30] [INFO] Filtre de scénario: Aucun
[2025-04-24 10:15:30] [INFO] Filtre de priorité: Aucun
[2025-04-24 10:15:30] [INFO] Nombre de scénarios: 5
[2025-04-24 10:15:30] [INFO] === Exécution du scénario: Cycle de vie basique ===
[2025-04-24 10:15:30] [INFO] Description: Teste le cycle de vie basique de n8n (démarrage, vérification, arrêt)
[2025-04-24 10:15:30] [INFO] Priorité: high
[2025-04-24 10:15:30] [INFO]   Étape: Arrêter n8n s'il est en cours d'exécution
[2025-04-24 10:15:35] [SUCCESS]     Résultat: Succès
[2025-04-24 10:15:35] [INFO]   Étape: Démarrer n8n
[2025-04-24 10:15:45] [SUCCESS]     Résultat: Succès
[2025-04-24 10:15:45] [INFO]   Étape: Vérifier que n8n est en cours d'exécution
[2025-04-24 10:15:46] [SUCCESS]     Résultat: Succès
[2025-04-24 10:15:46] [INFO]   Étape: Vérifier l'état de n8n
[2025-04-24 10:15:50] [SUCCESS]     Résultat: Succès
[2025-04-24 10:15:50] [INFO]   Étape: Arrêter n8n
[2025-04-24 10:15:55] [SUCCESS]     Résultat: Succès
[2025-04-24 10:15:55] [INFO]   Étape: Vérifier que n8n est arrêté
[2025-04-24 10:15:56] [SUCCESS]     Résultat: Succès
[2025-04-24 10:15:56] [SUCCESS] Résultat du scénario: Succès
[2025-04-24 10:15:56] [INFO] Durée: 26.0 secondes
...
[2025-04-24 10:18:30] [SUCCESS] Rapport JSON généré: n8n/logs/integration-tests-report.json
[2025-04-24 10:18:31] [SUCCESS] Rapport HTML généré: n8n/logs/integration-tests-report.html
[2025-04-24 10:18:31] [INFO] === Résumé des tests d'intégration ===
[2025-04-24 10:18:31] [INFO] Scénarios testés: 5
[2025-04-24 10:18:31] [SUCCESS] Scénarios réussis: 4
[2025-04-24 10:18:31] [ERROR] Scénarios échoués: 1
[2025-04-24 10:18:31] [WARNING] Taux de réussite: 80%
[2025-04-24 10:18:32] [SUCCESS] Notification envoyée: Tests d'intégration n8n: 80% de réussite
```plaintext