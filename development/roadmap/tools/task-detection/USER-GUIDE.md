# Guide d'utilisation du système de détection automatique des tâches

Ce guide vous explique comment utiliser le système de détection automatique des tâches pour capturer les demandes dans les conversations avec l'IA et les ajouter à la roadmap du projet.

## Table des matières

1. [Introduction](#introduction)

2. [Installation](#installation)

3. [Configuration](#configuration)

4. [Utilisation quotidienne](#utilisation-quotidienne)

5. [Gestion des tâches](#gestion-des-tâches)

6. [Maintenance](#maintenance)

7. [Dépannage](#dépannage)

8. [FAQ](#faq)

## Introduction

Le système de détection automatique des tâches est conçu pour capturer les demandes faites à l'IA et les ajouter automatiquement à la roadmap du projet. Il utilise des balises spéciales que l'IA insère dans ses réponses pour marquer les tâches à implémenter.

### Avantages

- Capture automatique des demandes sans intervention manuelle
- Standardisation du format des tâches
- Suivi centralisé de toutes les demandes
- Intégration avec la roadmap existante

### Fonctionnalités principales

- Détection des tâches dans les conversations avec l'IA
- Extraction des informations pertinentes (catégorie, priorité, estimation, etc.)
- Ajout automatique des tâches à la roadmap
- Confirmation manuelle des tâches détectées
- Journalisation des tâches détectées et ajoutées

## Installation

### Prérequis

- PowerShell 5.1 ou supérieur
- Accès en écriture au dossier de la roadmap
- Accès en lecture/écriture au dossier des conversations

### Étapes d'installation

1. Assurez-vous que tous les scripts sont présents dans le dossier `tools\roadmap\task-detection`
2. Créez un dossier `conversations` pour stocker les fichiers de conversation
3. Exécutez le script d'intégration :

```powershell
.\development\tools\roadmap\task-detection\Integrate-TaskDetection.ps1
```plaintext
4. Vérifiez que l'installation s'est bien déroulée :

```powershell
.\development\tools\roadmap\task-detection\Test-TaskDetection.ps1 -InputText "<task category=\"1\">Test</task>"
```plaintext
## Configuration

### Configuration du prompt système

Pour que l'IA puisse détecter et marquer les tâches, vous devez ajouter le contenu du fichier `task-detection-prompt.md` au prompt système de l'IA. Voici comment procéder :

1. Ouvrez le fichier `task-detection-prompt.md`
2. Copiez son contenu
3. Ajoutez-le au prompt système de l'IA

### Configuration du dossier de conversations

Par défaut, le système surveille le dossier `.\conversations` pour détecter les nouveaux fichiers de conversation. Vous pouvez modifier ce comportement en spécifiant un autre dossier :

```powershell
.\development\tools\roadmap\task-detection\Watch-Conversations.ps1 -ConversationsFolder "chemin/vers/dossier"
```plaintext
### Configuration de l'ajout automatique à la roadmap

Par défaut, le système ne fait que détecter les tâches sans les ajouter automatiquement à la roadmap. Pour activer l'ajout automatique :

```powershell
.\development\tools\roadmap\task-detection\Watch-Conversations.ps1 -AddToRoadmap
```plaintext
## Utilisation quotidienne

### Démarrer la surveillance des conversations

Pour démarrer la surveillance automatique des conversations :

```powershell
.\development\tools\roadmap\task-detection\Watch-Conversations.ps1 -AddToRoadmap
```plaintext
Ce script s'exécutera en continu et traitera automatiquement les nouveaux fichiers de conversation.

### Traiter manuellement une conversation

Si vous préférez traiter manuellement les conversations :

```powershell
.\development\tools\roadmap\task-detection\Process-Conversation.ps1 -ConversationFile "chemin/vers/conversation.txt" -AddToRoadmap
```plaintext
### Confirmer les tâches détectées

Pour confirmer ou rejeter les tâches détectées :

```powershell
.\development\tools\roadmap\task-detection\Confirm-Tasks.ps1
```plaintext
Ce script vous présentera les tâches détectées une par une et vous permettra de les ajouter à la roadmap, de les modifier, de les ignorer ou de les supprimer.

### Consulter les journaux

Pour consulter les journaux des tâches détectées et traitées :

```powershell
.\development\tools\roadmap\task-detection\Show-TaskLogs.ps1
```plaintext
Pour voir uniquement les dernières entrées :

```powershell
.\development\tools\roadmap\task-detection\Show-TaskLogs.ps1 -LastEntries 10
```plaintext
Pour exporter les journaux au format CSV :

```powershell
.\development\tools\roadmap\task-detection\Show-TaskLogs.ps1 -Export
```plaintext
## Gestion des tâches

### Catégories de tâches

Les tâches sont classées dans les catégories suivantes :

1. Documentation et formation
2. Gestion améliorée des répertoires et des chemins
3. Amélioration de la compatibilité des terminaux
4. Standardisation des hooks Git
5. Amélioration de l'authentification
6. Alternatives aux serveurs MCP traditionnels
7. Demandes spontanées

### Priorités

Les tâches peuvent avoir les priorités suivantes :

- `high` : Tâches critiques, urgentes ou prioritaires
- `medium` : Tâches normales (valeur par défaut)
- `low` : Tâches moins importantes ou qui peuvent attendre

### Estimations

Les estimations de temps sont exprimées en jours, au format `X-Y` (plage) ou `X` (valeur exacte). Par exemple :

- `1-2` : Entre 1 et 2 jours
- `3` : Exactement 3 jours

### Démarrage immédiat

L'attribut `start` indique si la tâche doit être démarrée immédiatement :

- `true` : La tâche est marquée comme démarrée
- `false` : La tâche est simplement ajoutée à la roadmap (valeur par défaut)

## Maintenance

### Tests automatiques

Pour tester automatiquement le système :

```powershell
.\development\tools\roadmap\task-detection\Run-Tests.ps1
```plaintext
Ce script exécutera une série de tests pour vérifier que le système fonctionne correctement.

### Optimisation du prompt système

Pour optimiser le prompt système en fonction des résultats des tests :

```powershell
.\development\tools\roadmap\task-detection\Optimize-Prompt.ps1
```plaintext
Pour appliquer automatiquement les optimisations :

```powershell
.\development\tools\roadmap\task-detection\Optimize-Prompt.ps1 -ApplyChanges
```plaintext
### Optimisation des performances

Pour optimiser les performances du système :

```powershell
.\development\tools\roadmap\task-detection\Optimize-Performance.ps1
```plaintext
Ce script analysera les performances du système et vous proposera des optimisations.

### Nettoyage des journaux

Pour effacer les journaux :

```powershell
.\development\tools\roadmap\task-detection\Show-TaskLogs.ps1 -Clear
```plaintext
## Dépannage

### Problèmes courants

#### Aucune tâche détectée

Si aucune tâche n'est détectée dans les conversations :

1. Vérifiez que le prompt système a bien été ajouté à l'IA
2. Vérifiez que les balises de tâches sont correctement formatées
3. Exécutez les tests automatiques pour identifier le problème

#### Erreur lors de l'ajout à la roadmap

Si les tâches sont détectées mais ne sont pas ajoutées à la roadmap :

1. Vérifiez que le script `Capture-Request-Simple.ps1` est accessible
2. Vérifiez que la catégorie "Demandes spontanées" existe dans la roadmap
3. Consultez les journaux pour identifier l'erreur

#### Performances lentes

Si le système est lent :

1. Exécutez le script d'optimisation des performances
2. Augmentez la taille de lot pour le traitement des conversations
3. Réduisez la fréquence de vérification des nouveaux fichiers

### Journaux d'erreurs

Les erreurs sont enregistrées dans le fichier `tasks-log.txt`. Consultez ce fichier pour identifier les problèmes.

## FAQ

### Comment ajouter une nouvelle catégorie de tâches ?

Pour ajouter une nouvelle catégorie, vous devez :

1. Ajouter la catégorie à la roadmap
2. Mettre à jour le prompt système pour inclure la nouvelle catégorie
3. Mettre à jour les scripts pour prendre en compte la nouvelle catégorie

### Comment modifier le format des balises de tâches ?

Le format des balises est défini dans le fichier `task-tags-syntax.md`. Si vous modifiez ce format, vous devez également mettre à jour :

1. Le prompt système
2. Les scripts de détection des tâches
3. Les tests automatiques

### Comment intégrer ce système avec d'autres outils ?

Le système peut être intégré avec d'autres outils en :

1. Exportant les journaux au format CSV
2. Utilisant les scripts comme des modules PowerShell
3. Créant des hooks personnalisés pour déclencher d'autres actions

### Comment automatiser complètement le processus ?

Pour automatiser complètement le processus :

1. Configurez un hook post-conversation pour traiter automatiquement les conversations
2. Activez l'ajout automatique à la roadmap
3. Configurez une tâche planifiée pour exécuter régulièrement le script de surveillance
