# Guide d'utilisation du système de remédiation n8n

Ce guide explique comment utiliser le système de remédiation n8n pour gérer, surveiller et maintenir votre installation n8n.

## Table des matières

1. [Introduction](#introduction)
2. [Installation](#installation)
3. [Interface principale](#interface-principale)
4. [Gestion du cycle de vie](#gestion-du-cycle-de-vie)
5. [Surveillance et diagnostics](#surveillance-et-diagnostics)
6. [Gestion des workflows](#gestion-des-workflows)
7. [Maintenance](#maintenance)
8. [Tests d'intégration](#tests-dintégration)
9. [Configuration](#configuration)
10. [Dépannage](#dépannage)
11. [Références](#références)

## Introduction

Le système de remédiation n8n est un ensemble d'outils conçus pour gérer, surveiller et maintenir votre installation n8n. Il fournit une interface unifiée pour toutes les fonctionnalités nécessaires à la gestion de n8n, incluant le démarrage, l'arrêt, la surveillance, l'importation de workflows et les diagnostics.

### Fonctionnalités principales

- Gestion du cycle de vie (démarrage, arrêt, redémarrage)
- Surveillance et diagnostics
- Gestion des workflows
- Maintenance
- Tests d'intégration
- Interface utilisateur conviviale

## Installation

### Prérequis

- Windows 10/11
- PowerShell 5.1 ou supérieur
- Node.js 18 ou supérieur
- n8n installé

### Structure des dossiers

Le système de remédiation n8n est organisé selon la structure suivante :

```
n8n/
├── automation/
│   ├── deployment/
│   ├── monitoring/
│   ├── diagnostics/
│   ├── notification/
│   ├── development/testing/tests/
│   ├── maintenance/
│   ├── dashboard/
│   └── n8n-manager.ps1
├── projet/config/
├── core/
├── data/
├── projet/documentation/
└── logs/
```

### Premiers pas

1. Assurez-vous que tous les prérequis sont installés
2. Clonez ou téléchargez le dépôt dans votre répertoire de travail
3. Exécutez `.\n8n-manager.cmd` pour lancer l'interface principale

## Interface principale

L'interface principale du système de remédiation n8n est accessible via le script `n8n-manager.cmd`. Ce script fournit un menu interactif pour accéder à toutes les fonctionnalités du système.

### Lancement de l'interface

```
.\n8n-manager.cmd
```

### Menu principal

Le menu principal propose les options suivantes :

```
╔══════════════════════════════════════╗
║           n8n Manager v1.0           ║
╚══════════════════════════════════════╝

Gestion du cycle de vie:
  1. Démarrer n8n
  2. Arrêter n8n
  3. Redémarrer n8n

Surveillance et diagnostics:
  4. Vérifier l'état de n8n
  5. Afficher le tableau de bord
  6. Tester la structure

Gestion des workflows:
  7. Importer des workflows
  8. Importer des workflows en masse
  9. Vérifier la présence des workflows

Maintenance:
  M. Exécuter la maintenance

Configuration:
  C. Configurer n8n Manager

  0. Quitter

Statut actuel:
  n8n est en cours d'exécution (PID: 1234)
```

### Exécution directe d'une action

Pour exécuter directement une action sans passer par le menu, utilisez le paramètre `-Action` :

```
.\n8n-manager.cmd -Action start
```

Actions disponibles :
- `start` : Démarre n8n
- `stop` : Arrête n8n
- `restart` : Redémarre n8n
- `status` : Vérifie l'état de n8n
- `import` : Importe des workflows
- `verify` : Vérifie la présence des workflows
- `test` : Teste la structure
- `dashboard` : Affiche le tableau de bord
- `maintenance` : Exécute la maintenance

### Scripts de raccourcis

Des scripts de raccourcis sont disponibles pour les actions les plus courantes :

- `n8n-start.cmd` : Démarre n8n
- `n8n-stop.cmd` : Arrête n8n
- `n8n-restart.cmd` : Redémarre n8n
- `n8n-status.cmd` : Vérifie l'état de n8n
- `n8n-import.cmd` : Importe des workflows
- `n8n-test.cmd` : Exécute les tests d'intégration

## Gestion du cycle de vie

La gestion du cycle de vie permet de démarrer, arrêter et redémarrer n8n.

### Démarrer n8n

Pour démarrer n8n, utilisez l'une des méthodes suivantes :

- Option 1 dans le menu principal
- `.\n8n-manager.cmd -Action start`
- `.\n8n-start.cmd`

Le script vérifie si n8n est déjà en cours d'exécution, puis démarre n8n et enregistre le PID dans un fichier.

### Arrêter n8n

Pour arrêter n8n, utilisez l'une des méthodes suivantes :

- Option 2 dans le menu principal
- `.\n8n-manager.cmd -Action stop`
- `.\n8n-stop.cmd`

Le script arrête proprement n8n et supprime le fichier PID.

### Redémarrer n8n

Pour redémarrer n8n, utilisez l'une des méthodes suivantes :

- Option 3 dans le menu principal
- `.\n8n-manager.cmd -Action restart`
- `.\n8n-restart.cmd`

Le script arrête n8n, attend quelques secondes, puis démarre n8n.

## Surveillance et diagnostics

La surveillance et les diagnostics permettent de vérifier l'état de n8n et de détecter les problèmes.

### Vérifier l'état de n8n

Pour vérifier l'état de n8n, utilisez l'une des méthodes suivantes :

- Option 4 dans le menu principal
- `.\n8n-manager.cmd -Action status`
- `.\n8n-status.cmd`

Le script vérifie si le port n8n est accessible et si l'API n8n répond correctement. Il génère un rapport détaillé sur l'état de n8n.

### Afficher le tableau de bord

Pour afficher le tableau de bord, utilisez l'option 5 dans le menu principal.

Le tableau de bord fournit une vue d'ensemble de l'état de n8n, incluant :

- Statut actuel
- Temps de réponse
- Historique des performances
- Statut des endpoints

### Tester la structure

Pour tester la structure du système n8n, utilisez l'option 6 dans le menu principal.

Le script vérifie l'intégrité et la structure des composants n8n, incluant :

- Présence des dossiers nécessaires
- Présence des fichiers nécessaires
- Présence des scripts nécessaires
- Structure des workflows
- Configuration du système

## Gestion des workflows

La gestion des workflows permet d'importer et de vérifier les workflows n8n.

### Importer des workflows

Pour importer des workflows, utilisez l'une des méthodes suivantes :

- Option 7 dans le menu principal
- `.\n8n-manager.cmd -Action import`
- `.\n8n-import.cmd`

Le script importe les workflows depuis les fichiers JSON dans le dossier de référence vers le dossier des workflows n8n.

### Importer des workflows en masse

Pour importer des workflows en masse, utilisez l'option 8 dans le menu principal.

Le script importe un grand nombre de workflows en parallèle, ce qui est utile pour les installations avec de nombreux workflows.

### Vérifier la présence des workflows

Pour vérifier la présence des workflows, utilisez l'option 9 dans le menu principal.

Le script vérifie que tous les workflows de référence sont présents dans le dossier des workflows n8n. Il génère un rapport détaillé sur les workflows manquants ou différents.

## Maintenance

La maintenance permet d'effectuer des tâches de maintenance comme la rotation des logs et la sauvegarde des workflows.

### Exécuter la maintenance

Pour exécuter la maintenance, utilisez l'option M dans le menu principal.

Le script exécute les tâches de maintenance suivantes :

- Rotation des logs
- Sauvegarde des workflows
- Nettoyage des fichiers temporaires

### Planifier les tâches de maintenance

Pour planifier les tâches de maintenance, utilisez le script `schedule-tasks.ps1` :

```
.\n8n\automation\maintenance\schedule-tasks.ps1 -Install
```

Le script installe des tâches planifiées pour exécuter automatiquement les tâches de maintenance.

## Tests d'intégration

Les tests d'intégration permettent de vérifier que tous les composants du système fonctionnent correctement ensemble.

### Exécuter les tests d'intégration

Pour exécuter les tests d'intégration, utilisez l'une des méthodes suivantes :

- `.\n8n-manager.cmd -Action test`
- `.\n8n-test.cmd`

Le script exécute les scénarios de test définis dans le fichier `test-scenarios.json` et génère un rapport détaillé sur les résultats.

### Scénarios de test disponibles

- Cycle de vie basique : Teste le démarrage, la vérification et l'arrêt de n8n
- Cycle de vie avancé : Teste le démarrage, le redémarrage et l'arrêt de n8n
- Gestion des workflows : Teste l'importation et la vérification des workflows
- Test de structure : Teste la structure du système n8n
- Test de bout en bout : Teste le système n8n de bout en bout

### Filtrer les tests

Pour exécuter uniquement certains scénarios, utilisez les options `-ScenarioFilter` et `-PriorityFilter` :

```
.\n8n-test.cmd -ScenarioFilter "lifecycle-basic"
.\n8n-test.cmd -PriorityFilter "high"
```

## Configuration

La configuration permet de modifier les paramètres du système de remédiation n8n.

### Menu de configuration

Pour accéder au menu de configuration, utilisez l'option C dans le menu principal.

Le menu de configuration propose les options suivantes :

```
╔══════════════════════════════════════╗
║       Configuration n8n Manager      ║
╚══════════════════════════════════════╝

Configuration actuelle:
  1. Dossier racine n8n: n8n
  2. Dossier des workflows: n8n/data/.n8n/workflows
  3. Dossier de référence: n8n/core/workflows/local
  4. Dossier des logs: n8n/logs
  5. Port par défaut: 5678
  6. Protocole par défaut: http
  7. Hôte par défaut: localhost
  8. Redémarrage automatique: False
  9. Notifications activées: True

  S. Sauvegarder la configuration
  R. Réinitialiser la configuration

  0. Retour au menu principal
```

### Fichier de configuration

Le fichier de configuration `n8n/projet/config/n8n-manager-config.json` contient les paramètres suivants :

```json
{
  "N8nRootFolder": "n8n",
  "WorkflowFolder": "n8n/data/.n8n/workflows",
  "ReferenceFolder": "n8n/core/workflows/local",
  "LogFolder": "n8n/logs",
  "DefaultPort": 5678,
  "DefaultProtocol": "http",
  "DefaultHostname": "localhost",
  "AutoRestart": false,
  "NotificationEnabled": true
}
```

## Dépannage

Cette section fournit des solutions aux problèmes courants rencontrés lors de l'utilisation du système de remédiation n8n.

### n8n ne démarre pas

**Problème** : n8n ne démarre pas ou le script de démarrage échoue.

**Solutions** :
1. Vérifiez les logs dans `n8n/logs/n8n.log`
2. Vérifiez que le port n'est pas déjà utilisé par un autre processus
3. Vérifiez que Node.js est correctement installé
4. Vérifiez que n8n est correctement installé
5. Exécutez le test de structure pour vérifier l'intégrité du système

### Les workflows ne s'importent pas

**Problème** : Les workflows ne s'importent pas ou le script d'importation échoue.

**Solutions** :
1. Vérifiez que n8n est en cours d'exécution
2. Vérifiez que les fichiers JSON sont valides
3. Vérifiez que les dossiers de référence et de destination existent
4. Vérifiez les logs dans `n8n/logs/import-workflows.log`
5. Vérifiez que l'API n8n est accessible

### Le script n8n-manager ne s'exécute pas

**Problème** : Le script n8n-manager ne s'exécute pas ou affiche des erreurs.

**Solutions** :
1. Vérifiez que PowerShell est correctement installé
2. Vérifiez que la politique d'exécution PowerShell permet l'exécution de scripts
3. Exécutez le script directement : `powershell -ExecutionPolicy Bypass -File "n8n\automation\n8n-manager.ps1"`
4. Vérifiez que tous les fichiers nécessaires sont présents

### Les tests d'intégration échouent

**Problème** : Les tests d'intégration échouent ou affichent des erreurs.

**Solutions** :
1. Vérifiez les logs dans `n8n/logs/integration-tests.log`
2. Vérifiez que n8n est correctement installé et configuré
3. Exécutez les tests avec l'option `-ScenarioFilter` pour isoler le problème
4. Vérifiez que tous les composants nécessaires sont présents et fonctionnels

## Références

### Documentation complémentaire

- [Architecture du système](architecture/system-overview.md)
- [Vérification des workflows](architecture/workflow-verification.md)
- [Surveillance du port et de l'API](architecture/port-api-monitoring.md)
- [Test de structure](architecture/structure-test.md)
- [Tests d'intégration](architecture/integration-tests.md)
- [n8n Manager](architecture/n8n-manager.md)

### Ressources externes

- [Documentation officielle n8n](https://projet/documentation.n8n.io/)
- [GitHub n8n](https://github.com/n8n-io/n8n)
- [Forum n8n](https://community.n8n.io/)
