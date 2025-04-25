# n8n Manager - Script d'orchestration principal

Ce document explique comment utiliser le script d'orchestration principal `n8n-manager.ps1` pour gérer toutes les fonctionnalités de n8n.

## Vue d'ensemble

Le script d'orchestration principal `n8n-manager.ps1` fournit une interface unifiée pour toutes les fonctionnalités de gestion de n8n, incluant :

- Gestion du cycle de vie (démarrage, arrêt, redémarrage)
- Surveillance et diagnostics
- Gestion des workflows
- Maintenance
- Configuration

## Installation

Aucune installation spécifique n'est nécessaire. Le script est déjà inclus dans le projet.

## Utilisation

### Interface interactive

Pour lancer l'interface interactive, exécutez simplement :

```
.\n8n-manager.cmd
```

Cela affichera un menu avec toutes les options disponibles.

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

## Menu principal

Le menu principal propose les options suivantes :

### Gestion du cycle de vie

- **1. Démarrer n8n** : Démarre le service n8n
- **2. Arrêter n8n** : Arrête proprement le service n8n
- **3. Redémarrer n8n** : Redémarre le service n8n

### Surveillance et diagnostics

- **4. Vérifier l'état de n8n** : Vérifie si le port n8n est accessible et si l'API n8n répond correctement
- **5. Afficher le tableau de bord** : Affiche un tableau de bord HTML avec des informations sur l'état de n8n
- **6. Tester la structure** : Vérifie l'intégrité et la structure des composants n8n

### Gestion des workflows

- **7. Importer des workflows** : Importe des workflows depuis des fichiers JSON
- **8. Importer des workflows en masse** : Importe un grand nombre de workflows en parallèle
- **9. Vérifier la présence des workflows** : Vérifie que tous les workflows de référence sont présents dans n8n

### Maintenance

- **M. Exécuter la maintenance** : Exécute des tâches de maintenance comme la rotation des logs et la sauvegarde des workflows

### Configuration

- **C. Configurer n8n Manager** : Configure les paramètres de n8n Manager

## Menu de configuration

Le menu de configuration permet de modifier les paramètres suivants :

- **1. Dossier racine n8n** : Dossier racine de n8n
- **2. Dossier des workflows** : Dossier contenant les workflows n8n
- **3. Dossier de référence** : Dossier contenant les workflows de référence
- **4. Dossier des logs** : Dossier contenant les fichiers de log
- **5. Port par défaut** : Port utilisé par n8n
- **6. Protocole par défaut** : Protocole utilisé par n8n (http ou https)
- **7. Hôte par défaut** : Nom d'hôte ou adresse IP du serveur n8n
- **8. Redémarrage automatique** : Indique si n8n doit être redémarré automatiquement en cas de problème
- **9. Notifications activées** : Indique si les notifications doivent être envoyées

Options supplémentaires :
- **S. Sauvegarder la configuration** : Sauvegarde la configuration dans le fichier de configuration
- **R. Réinitialiser la configuration** : Réinitialise la configuration à partir du fichier de configuration
- **0. Retour au menu principal** : Retourne au menu principal

## Fichier de configuration

Le fichier de configuration `n8n/config/n8n-manager-config.json` contient les paramètres suivants :

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

## Exemples d'utilisation

### Démarrer n8n

```
.\n8n-manager.cmd -Action start
```

ou

```
.\n8n-start.cmd
```

### Vérifier l'état de n8n

```
.\n8n-manager.cmd -Action status
```

ou

```
.\n8n-status.cmd
```

### Importer des workflows

```
.\n8n-manager.cmd -Action import
```

ou

```
.\n8n-import.cmd
```

### Configurer n8n Manager

```
.\n8n-manager.cmd
```

Puis sélectionner l'option `C` dans le menu principal.

## Résolution des problèmes

### n8n ne démarre pas

1. Vérifiez les logs dans `n8n/logs/n8n.log`
2. Exécutez le test de structure : `.\n8n-manager.cmd -Action test`
3. Vérifiez que le port n'est pas déjà utilisé

### Les workflows ne s'importent pas

1. Vérifiez que les fichiers JSON sont valides
2. Vérifiez que n8n est en cours d'exécution
3. Vérifiez les logs dans `n8n/logs/import-workflows.log`

### Le script n8n-manager ne s'exécute pas

1. Vérifiez que PowerShell est installé
2. Vérifiez que la politique d'exécution PowerShell permet l'exécution de scripts
3. Exécutez le script directement : `powershell -ExecutionPolicy Bypass -File "n8n\automation\n8n-manager.ps1"`
