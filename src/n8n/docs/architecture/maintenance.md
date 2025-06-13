# Automatisation des tâches récurrentes n8n

Ce document explique comment utiliser les scripts d'automatisation des tâches récurrentes pour maintenir votre installation n8n en bon état de fonctionnement.

## Vue d'ensemble

L'automatisation des tâches récurrentes permet de :

1. Effectuer la rotation des logs pour éviter qu'ils ne deviennent trop volumineux
2. Sauvegarder régulièrement les workflows pour éviter la perte de données
3. Nettoyer les fichiers temporaires pour libérer de l'espace disque
4. Planifier ces tâches pour qu'elles s'exécutent automatiquement

## Scripts disponibles

### Script principal de maintenance

Le script `maintenance.ps1` exécute toutes les tâches de maintenance en une seule fois :

```plaintext
.\n8n-maintenance.cmd
```plaintext
Options disponibles :

- `-N8nRootFolder` : Dossier racine de n8n (par défaut: n8n)
- `-WorkflowFolder` : Dossier contenant les workflows n8n (par défaut: n8n/data/.n8n/workflows)
- `-LogFolder` : Dossier contenant les logs n8n (par défaut: n8n/logs)
- `-BackupFolder` : Dossier où stocker les sauvegardes (par défaut: n8n/backups)
- `-NoInteractive` : Exécute le script en mode non interactif (sans demander de confirmation)

### Rotation des logs

Le script `rotate-logs.ps1` effectue la rotation des logs n8n :

```plaintext
.\n8n\automation\maintenance\rotate-logs.ps1
```plaintext
Options disponibles :

- `-LogFolder` : Dossier contenant les logs n8n (par défaut: n8n/logs)
- `-HistoryFolder` : Dossier où stocker les logs archivés (par défaut: n8n/logs/history)
- `-MaxLogSizeMB` : Taille maximale des fichiers de log en MB avant rotation (par défaut: 10)
- `-MaxLogAgeDays` : Âge maximal des fichiers de log en jours avant rotation (par défaut: 7)
- `-MaxHistoryCount` : Nombre maximal d'archives de logs à conserver (par défaut: 30)
- `-NoInteractive` : Exécute le script en mode non interactif (sans demander de confirmation)

### Sauvegarde des workflows

Le script `backup-workflows.ps1` effectue la sauvegarde des workflows n8n :

```plaintext
.\n8n\automation\maintenance\backup-workflows.ps1
```plaintext
Options disponibles :

- `-WorkflowFolder` : Dossier contenant les workflows n8n (par défaut: n8n/data/.n8n/workflows)
- `-BackupFolder` : Dossier où stocker les sauvegardes (par défaut: n8n/backups)
- `-MaxBackupCount` : Nombre maximal de sauvegardes à conserver (par défaut: 30)
- `-IncludeTimestamp` : Indique s'il faut inclure un horodatage dans le nom du fichier de sauvegarde (par défaut: $true)
- `-NoInteractive` : Exécute le script en mode non interactif (sans demander de confirmation)

### Nettoyage des fichiers temporaires

Le script `cleanup-temp.ps1` nettoie les fichiers temporaires créés par n8n :

```plaintext
.\n8n\automation\maintenance\cleanup-temp.ps1
```plaintext
Options disponibles :

- `-N8nRootFolder` : Dossier racine de n8n (par défaut: n8n)
- `-MaxTempAgeDays` : Âge maximal des fichiers temporaires en jours avant suppression (par défaut: 7)
- `-NoInteractive` : Exécute le script en mode non interactif (sans demander de confirmation)

### Planification des tâches

Le script `schedule-tasks.ps1` installe, désinstalle ou vérifie les tâches planifiées pour la maintenance de n8n :

```plaintext
.\n8n\automation\maintenance\schedule-tasks.ps1 -Action Install
```plaintext
Options disponibles :

- `-Action` : Action à effectuer (Install, Uninstall, Check)
- `-TaskPrefix` : Préfixe pour les noms des tâches planifiées (par défaut: N8N_)
- `-ProjectRoot` : Dossier racine du projet (par défaut: dossier parent du dossier n8n)
- `-NoInteractive` : Exécute le script en mode non interactif (sans demander de confirmation)

## Tâches planifiées

Les tâches planifiées suivantes sont créées par le script `schedule-tasks.ps1` :

1. **N8N_RotateLogs** : Rotation des logs n8n (tous les jours à 3h00)
2. **N8N_BackupWorkflows** : Sauvegarde des workflows n8n (tous les jours à 4h00)
3. **N8N_CleanupTemp** : Nettoyage des fichiers temporaires n8n (tous les dimanches à 5h00)
4. **N8N_Maintenance** : Maintenance complète n8n (tous les dimanches à 2h00)

## Utilisation

### Exécution manuelle

Pour exécuter manuellement toutes les tâches de maintenance :

```plaintext
.\n8n-maintenance.cmd
```plaintext
Pour exécuter manuellement une tâche spécifique :

```plaintext
.\n8n\automation\maintenance\rotate-logs.ps1
.\n8n\automation\maintenance\backup-workflows.ps1
.\n8n\automation\maintenance\cleanup-temp.ps1
```plaintext
### Installation des tâches planifiées

Pour installer les tâches planifiées :

```plaintext
.\n8n\automation\maintenance\schedule-tasks.ps1 -Action Install
```plaintext
**Note** : Ce script doit être exécuté en tant qu'administrateur.

### Vérification des tâches planifiées

Pour vérifier les tâches planifiées :

```plaintext
.\n8n\automation\maintenance\schedule-tasks.ps1 -Action Check
```plaintext
### Désinstallation des tâches planifiées

Pour désinstaller les tâches planifiées :

```plaintext
.\n8n\automation\maintenance\schedule-tasks.ps1 -Action Uninstall
```plaintext
## Personnalisation

### Modification des paramètres par défaut

Vous pouvez modifier les paramètres par défaut en éditant les scripts ou en spécifiant les paramètres lors de l'exécution.

### Ajout de nouvelles tâches de maintenance

Pour ajouter une nouvelle tâche de maintenance :

1. Créez un nouveau script PowerShell dans le dossier `n8n/automation/maintenance`
2. Ajoutez le script à la liste des scripts de maintenance dans `maintenance.ps1`
3. Ajoutez la tâche planifiée dans `schedule-tasks.ps1`

## Logs

Les logs de maintenance sont enregistrés dans le fichier `n8n/logs/maintenance.log`. Ce fichier contient les informations suivantes :

- Date et heure de chaque action
- Niveau de log (INFO, WARNING, ERROR, SUCCESS)
- Description de l'action
- Résultats de l'action
- Erreurs rencontrées

## Dépannage

### Erreur "Ce script doit être exécuté en tant qu'administrateur"

Pour installer les tâches planifiées, vous devez exécuter le script `schedule-tasks.ps1` en tant qu'administrateur. Ouvrez PowerShell en tant qu'administrateur et exécutez le script.

### Erreur "Impossible de continuer sans les dossiers requis"

Vérifiez que les dossiers spécifiés dans les paramètres existent. Si ce n'est pas le cas, créez-les manuellement ou spécifiez des dossiers existants.

### Erreur "Aucun fichier de log/workflow trouvé"

Vérifiez que les dossiers spécifiés contiennent des fichiers de log ou des workflows. Si ce n'est pas le cas, vérifiez les paramètres et assurez-vous que n8n a été exécuté au moins une fois.

### Les tâches planifiées ne s'exécutent pas

Vérifiez que les tâches planifiées sont correctement installées et activées. Utilisez le script `schedule-tasks.ps1` avec l'action `Check` pour vérifier l'état des tâches.

## Exemples d'utilisation

### Rotation des logs avec des paramètres personnalisés

```plaintext
.\n8n\automation\maintenance\rotate-logs.ps1 -LogFolder "C:\n8n\logs" -MaxLogSizeMB 20 -MaxLogAgeDays 14
```plaintext
### Sauvegarde des workflows sans horodatage

```plaintext
.\n8n\automation\maintenance\backup-workflows.ps1 -IncludeTimestamp $false
```plaintext
### Nettoyage des fichiers temporaires plus anciens

```plaintext
.\n8n\automation\maintenance\cleanup-temp.ps1 -MaxTempAgeDays 14
```plaintext
### Installation des tâches planifiées avec un préfixe personnalisé

```plaintext
.\n8n\automation\maintenance\schedule-tasks.ps1 -Action Install -TaskPrefix "MyN8N_"
```plaintext
### Exécution de toutes les tâches de maintenance sans confirmation

```plaintext
.\n8n-maintenance.cmd -NoInteractive
```plaintext
## Conclusion

L'automatisation des tâches récurrentes permet de maintenir votre installation n8n en bon état de fonctionnement sans intervention manuelle. Les scripts fournis effectuent les tâches de maintenance essentielles et peuvent être personnalisés selon vos besoins.
