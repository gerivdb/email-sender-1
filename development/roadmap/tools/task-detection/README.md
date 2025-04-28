# Système de détection automatique des tâches

Ce dossier contient les scripts et les ressources nécessaires pour détecter automatiquement les tâches dans les conversations avec l'IA et les ajouter à la roadmap du projet.

## Vue d'ensemble

Le système de détection automatique des tâches permet de :

1. Détecter les tâches dans les conversations avec l'IA à l'aide de balises spéciales
2. Extraire les informations pertinentes (catégorie, priorité, estimation, etc.)
3. Ajouter automatiquement ces tâches à la roadmap du projet
4. Suivre l'évolution des tâches détectées et ajoutées

## Architecture

Le système est composé des éléments suivants :

- **Balises de tâches** : Format XML utilisé par l'IA pour marquer les tâches dans les conversations
- **Prompt système** : Instructions données à l'IA pour détecter et marquer les tâches
- **Scripts de traitement** : Scripts PowerShell pour extraire et traiter les tâches
- **Hooks post-conversation** : Mécanismes pour traiter automatiquement les conversations
- **Système de confirmation** : Interface pour confirmer ou rejeter les tâches détectées
- **Journalisation** : Système pour suivre les tâches détectées et ajoutées

## Fichiers inclus

### Scripts principaux

- `Test-TaskDetection.ps1` : Script pour tester la détection des balises de tâches
- `Process-Conversation.ps1` : Script pour analyser les fichiers de conversation et extraire les tâches
- `Watch-Conversations.ps1` : Script pour surveiller un dossier de conversations
- `Integrate-TaskDetection.ps1` : Script pour intégrer le système avec les scripts existants
- `Post-Conversation-Hook.ps1` : Script à exécuter après chaque conversation
- `Confirm-Tasks.ps1` : Script pour confirmer ou rejeter les tâches détectées
- `Show-TaskLogs.ps1` : Script pour afficher et gérer les journaux des tâches
- `Run-Tests.ps1` : Script pour tester automatiquement le système
- `Optimize-Prompt.ps1` : Script pour affiner le prompt système
- `Optimize-Performance.ps1` : Script pour optimiser les performances du système

### Ressources

- `task-tags-syntax.md` : Documentation de la syntaxe des balises de tâches
- `task-detection-prompt.md` : Prompt système pour la détection des tâches
- `development/testing/tests/test-cases.txt` : Cas de test pour le système de détection des tâches

### Fichiers de données

- `tasks-log.txt` : Journal des tâches détectées et traitées
- `processed-files.txt` : Liste des fichiers de conversation déjà traités
- `pending-tasks.json` : Liste des tâches en attente de confirmation
- `performance-log.txt` : Journal des performances du système

## Installation

1. Assurez-vous que PowerShell est installé sur votre système
2. Clonez ce dépôt ou copiez les fichiers dans un dossier de votre choix
3. Créez un dossier `conversations` pour stocker les fichiers de conversation
4. Exécutez le script `Integrate-TaskDetection.ps1` pour configurer le système

## Utilisation

### Détection manuelle des tâches

Pour détecter manuellement les tâches dans un fichier de conversation :

```powershell
.\Process-Conversation.ps1 -ConversationFile "chemin/vers/conversation.txt" [-AddToRoadmap] [-Verbose]
```

### Surveillance automatique des conversations

Pour surveiller automatiquement un dossier de conversations :

```powershell
.\Watch-Conversations.ps1 -ConversationsFolder "chemin/vers/dossier" [-AddToRoadmap] [-Verbose]
```

### Confirmation des tâches détectées

Pour confirmer ou rejeter les tâches détectées :

```powershell
.\Confirm-Tasks.ps1 [-Verbose]
```

### Affichage des journaux

Pour afficher les journaux des tâches détectées et traitées :

```powershell
.\Show-TaskLogs.ps1 [-LastEntries 10] [-Export] [-ExportFile "chemin/vers/export.csv"]
```

### Tests automatiques

Pour tester automatiquement le système :

```powershell
.\Run-Tests.ps1 [-Verbose]
```

### Optimisation du prompt système

Pour optimiser le prompt système en fonction des résultats des tests :

```powershell
.\Optimize-Prompt.ps1 [-ApplyChanges]
```

### Optimisation des performances

Pour optimiser les performances du système :

```powershell
.\Optimize-Performance.ps1 -BatchSize 5 [-Verbose]
```

## Intégration avec l'IA

Pour intégrer ce système avec l'IA, vous devez ajouter le contenu du fichier `task-detection-prompt.md` au prompt système de l'IA. Cela permettra à l'IA de détecter et de marquer automatiquement les tâches dans les conversations.

## Syntaxe des balises de tâches

Les tâches sont marquées à l'aide de balises XML spéciales dans le format suivant :

```xml
<task category="X" priority="Y" estimate="Z" start="true|false">
Description de la tâche
</task>
```

Pour plus de détails, consultez le fichier `task-tags-syntax.md`.

## Dépannage

### Problèmes courants

- **Aucune tâche détectée** : Vérifiez que les balises de tâches sont correctement formatées
- **Erreur lors de l'ajout à la roadmap** : Vérifiez que le script `Capture-Request-Simple.ps1` est accessible
- **Performances lentes** : Utilisez le script `Optimize-Performance.ps1` pour optimiser les performances

### Journaux

Les journaux sont stockés dans les fichiers suivants :

- `tasks-log.txt` : Journal des tâches détectées et traitées
- `performance-log.txt` : Journal des performances du système

## Licence

Ce projet est sous licence MIT. Voir le fichier LICENSE pour plus de détails.
