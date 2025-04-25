# Gestion des multi-instances n8n

Ce document explique comment utiliser les scripts de gestion des multi-instances n8n.

## Vue d'ensemble

La gestion des multi-instances n8n permet de :

1. Démarrer plusieurs instances de n8n sur différents ports
2. Gérer chaque instance indépendamment
3. Vérifier l'état de toutes les instances
4. Contrôler les ports utilisés par n8n

Cette approche résout plusieurs problèmes :

- Permet de tester différentes configurations n8n
- Permet de séparer les environnements (développement, test, production)
- Évite les conflits de port
- Facilite la gestion des instances

## Structure des instances

Chaque instance n8n est stockée dans un dossier séparé sous `n8n/instances/{nom_instance}` avec la structure suivante :

```
n8n/instances/{nom_instance}/
├── data/                  # Données de l'instance
│   ├── .n8n/             # Dossier de données n8n
│   │   └── database.sqlite  # Base de données
│   └── workflows/        # Workflows de l'instance
├── n8n-{nom_instance}.pid  # Fichier PID
├── n8n-{nom_instance}.log  # Fichier log
├── n8n-{nom_instance}-error.log  # Fichier log d'erreurs
└── .env                  # Variables d'environnement
```

## Scripts disponibles

### Démarrage d'une instance

Pour démarrer une instance n8n, utilisez :

```
.\start-n8n-instance.cmd -InstanceName "dev" -Port 5679
```

Options disponibles :

- `-InstanceName` : Nom de l'instance (par défaut: "default")
- `-Port` : Port sur lequel n8n sera accessible (par défaut: 5678)
- `-BaseFolder` : Dossier de base pour les données de l'instance (par défaut: dossier data standard)
- `-PidFile` : Chemin du fichier où le PID sera enregistré (par défaut: n8n-{InstanceName}.pid)
- `-LogFile` : Chemin du fichier de log (par défaut: n8n-{InstanceName}.log)
- `-ErrorLogFile` : Chemin du fichier de log d'erreurs (par défaut: n8n-{InstanceName}-error.log)

Si le port spécifié est déjà utilisé, le script trouvera automatiquement un port disponible.

### Arrêt d'une instance

Pour arrêter une instance n8n, utilisez :

```
.\stop-n8n-instance.cmd -InstanceName "dev" -Force
```

Options disponibles :

- `-InstanceName` : Nom de l'instance à arrêter (par défaut: "default")
- `-Force` : Force l'arrêt du processus si l'arrêt normal échoue

### Liste des instances

Pour lister toutes les instances n8n, utilisez :

```
.\list-n8n-instances.cmd
```

Ce script affiche :

- La liste de toutes les instances
- Le PID, le port et l'état de chaque instance
- Les détails des instances en cours d'exécution
- Les instances arrêtées
- Le nombre total d'instances

### Vérification des ports

Pour vérifier les ports utilisés par n8n et trouver des ports disponibles, utilisez :

```
.\check-n8n-ports.cmd -StartPort 5678 -EndPort 5700 -FindAvailable 3
```

Options disponibles :

- `-StartPort` : Port de départ pour la recherche de ports disponibles (par défaut: 5678)
- `-EndPort` : Port de fin pour la recherche de ports disponibles (par défaut: 5700)
- `-FindAvailable` : Nombre de ports disponibles à trouver (par défaut: 1)

## Exemples d'utilisation

### Démarrer plusieurs instances

```
# Démarrer l'instance par défaut
.\start-n8n-instance.cmd

# Démarrer une instance de développement sur le port 5679
.\start-n8n-instance.cmd -InstanceName "dev" -Port 5679

# Démarrer une instance de test sur le port 5680
.\start-n8n-instance.cmd -InstanceName "test" -Port 5680
```

### Arrêter des instances

```
# Arrêter l'instance par défaut
.\stop-n8n-instance.cmd

# Arrêter l'instance de développement
.\stop-n8n-instance.cmd -InstanceName "dev"

# Forcer l'arrêt de l'instance de test
.\stop-n8n-instance.cmd -InstanceName "test" -Force
```

### Vérifier l'état des instances

```
# Lister toutes les instances
.\list-n8n-instances.cmd
```

### Trouver des ports disponibles

```
# Trouver 3 ports disponibles
.\check-n8n-ports.cmd -FindAvailable 3
```

## Bonnes pratiques

1. **Nommage des instances** : Utilisez des noms descriptifs pour les instances (ex: "dev", "test", "prod")
2. **Gestion des ports** : Utilisez des ports différents pour chaque instance
3. **Arrêt propre** : Utilisez toujours le script d'arrêt pour arrêter une instance
4. **Surveillance** : Vérifiez régulièrement l'état des instances
5. **Logs** : Consultez les logs en cas de problème

## Résolution des problèmes

### Une instance ne démarre pas

Si une instance ne démarre pas, vérifiez les points suivants :

1. Vérifiez les logs d'erreurs : `n8n/instances/{nom_instance}/n8n-{nom_instance}-error.log`
2. Vérifiez si le port est déjà utilisé : `.\check-n8n-ports.cmd`
3. Vérifiez si une instance avec le même nom est déjà en cours d'exécution : `.\list-n8n-instances.cmd`

### Une instance ne s'arrête pas

Si une instance ne s'arrête pas, essayez les solutions suivantes :

1. Utilisez l'option `-Force` : `.\stop-n8n-instance.cmd -InstanceName "{nom_instance}" -Force`
2. Vérifiez si le processus existe encore : `.\list-n8n-instances.cmd`
3. Utilisez Task Manager pour arrêter le processus manuellement

### Conflit de port

Si vous rencontrez un conflit de port, le script trouvera automatiquement un port disponible. Vous pouvez également vérifier les ports disponibles avec :

```
.\check-n8n-ports.cmd -FindAvailable 5
```
