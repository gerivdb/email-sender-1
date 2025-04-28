# Guide de maintenance MCP

Ce guide explique comment maintenir et gérer les serveurs MCP (Model Context Protocol) dans le projet EMAIL_SENDER_1.

## Surveillance des serveurs

### Vérification de l'état

Pour vérifier l'état des serveurs MCP, utilisez la commande suivante :

```powershell
Import-Module .\projet\mcp\modules\MCPManager
Get-MCPServerStatus
```

Ou utilisez le script de vérification de l'état :

```powershell
.\projet\mcp\monitoring\scripts\check-mcp-status.ps1
```

### Génération de rapports de santé

Pour générer un rapport de santé complet des serveurs MCP :

```powershell
.\projet\mcp\monitoring\scripts\generate-health-report.ps1 -OutputFormat HTML -IncludeTests
```

Options disponibles :
- `-OutputFormat` : Format de sortie (HTML, JSON, Text)
- `-IncludeTests` : Inclut les résultats des tests dans le rapport
- `-SendEmail` : Envoie le rapport par e-mail
- `-EmailTo` : Adresse e-mail du destinataire

### Collecte de métriques

Pour collecter des métriques de performance des serveurs MCP :

```powershell
.\projet\mcp\monitoring\scripts\collect-metrics.ps1 -Interval 60 -Duration 60
```

Options disponibles :
- `-Interval` : Intervalle de collecte en secondes
- `-Duration` : Durée de collecte en minutes
- `-OutputFormat` : Format de sortie (CSV, JSON)

### Vérification de l'état de santé

Pour vérifier l'état de santé des serveurs MCP :

```powershell
.\projet\mcp\monitoring\scripts\check-mcp-health.ps1 -OutputFormat HTML -SendAlert
```

Options disponibles :
- `-OutputFormat` : Format de sortie (Text, JSON, HTML)
- `-SendAlert` : Envoie une alerte en cas de problème détecté

## Sauvegarde et restauration

### Sauvegarde manuelle

Pour sauvegarder manuellement la configuration MCP :

```powershell
.\projet\mcp\scripts\maintenance\backup-mcp-config.ps1 -CreateZip -IncludeData
```

Options disponibles :
- `-BackupDir` : Répertoire de sauvegarde
- `-CreateZip` : Crée un fichier ZIP au lieu d'un répertoire
- `-IncludeData` : Inclut les données en plus de la configuration

### Planification des sauvegardes

Pour planifier des sauvegardes automatiques :

```powershell
.\projet\mcp\scripts\maintenance\schedule-mcp-backups.ps1 -Frequency Daily -Time 02:00 -CreateZip
```

Options disponibles :
- `-Frequency` : Fréquence des sauvegardes (Daily, Weekly, Monthly)
- `-DayOfWeek` : Jour de la semaine pour les sauvegardes hebdomadaires
- `-Time` : Heure des sauvegardes au format HH:mm
- `-CreateZip` : Crée un fichier ZIP au lieu d'un répertoire
- `-IncludeData` : Inclut les données en plus de la configuration

### Nettoyage des anciennes sauvegardes

Pour nettoyer les anciennes sauvegardes :

```powershell
.\projet\mcp\scripts\maintenance\cleanup-mcp-backups.ps1 -MaxAge 30 -MaxCount 10
```

Options disponibles :
- `-BackupDir` : Répertoire de sauvegarde
- `-MaxAge` : Âge maximum des sauvegardes en jours
- `-MaxCount` : Nombre maximum de sauvegardes à conserver

### Restauration d'une sauvegarde

Pour restaurer une sauvegarde :

```powershell
.\projet\mcp\versioning\scripts\rollback-mcp-update.ps1 -BackupDate 20250501 -Version 1.0.0
```

Options disponibles :
- `-BackupDate` : Date de la sauvegarde au format 'yyyyMMdd'
- `-Version` : Version à restaurer

## Mise à jour des composants

### Mise à jour manuelle

Pour mettre à jour manuellement les composants MCP :

```powershell
.\projet\mcp\versioning\scripts\update-mcp-components.ps1 -Components Npm,Pip
```

Options disponibles :
- `-SkipBackup` : Ignore la création d'une sauvegarde avant la mise à jour
- `-Components` : Liste des composants à mettre à jour (All, Npm, Pip, Binary)

### Planification des mises à jour

Pour planifier des mises à jour automatiques :

```powershell
.\projet\mcp\scripts\maintenance\schedule-mcp-updates.ps1 -Frequency Weekly -DayOfWeek Sunday -Time 03:00
```

Options disponibles :
- `-Frequency` : Fréquence des mises à jour (Daily, Weekly, Monthly)
- `-DayOfWeek` : Jour de la semaine pour les mises à jour hebdomadaires
- `-Time` : Heure des mises à jour au format HH:mm

## Gestion des serveurs

### Démarrage et arrêt des serveurs

Pour démarrer tous les serveurs MCP :

```powershell
Import-Module .\projet\mcp\modules\MCPManager
Start-MCPServer
```

Pour démarrer un serveur spécifique :

```powershell
Start-MCPServer -ServerName filesystem
```

Pour arrêter tous les serveurs MCP :

```powershell
Stop-MCPServer
```

Pour arrêter un serveur spécifique :

```powershell
Stop-MCPServer -ServerName filesystem
```

Pour redémarrer un serveur :

```powershell
Restart-MCPServer -ServerName filesystem
```

### Activation et désactivation des serveurs

Pour activer un serveur :

```powershell
Enable-MCPServer -ServerName filesystem
```

Pour désactiver un serveur :

```powershell
Disable-MCPServer -ServerName filesystem
```

### Configuration du démarrage automatique

Pour configurer le démarrage automatique des serveurs MCP :

```powershell
.\projet\mcp\scripts\utils\register-mcp-startup.ps1 -StartupType User
```

Options disponibles :
- `-StartupType` : Type de démarrage (System, User)

## Tests

### Exécution des tests

Pour exécuter tous les tests :

```powershell
.\projet\mcp\tests\Run-AllTests.ps1
```

Pour exécuter uniquement les tests unitaires :

```powershell
.\projet\mcp\tests\Run-AllTests.ps1 -SkipIntegrationTests -SkipPerformanceTests
```

Pour exécuter uniquement les tests d'intégration :

```powershell
.\projet\mcp\tests\Run-AllTests.ps1 -SkipUnitTests -SkipPerformanceTests
```

### Tests spécifiques

Pour exécuter des tests spécifiques :

```powershell
.\projet\mcp\tests\unit\Test-MCPConfig.ps1
.\projet\mcp\tests\unit\Test-MCPManager.ps1
.\projet\mcp\tests\integration\Test-MCPServerIntegration.ps1 -Server filesystem
```

## Désinstallation

Pour désinstaller les serveurs MCP :

```powershell
.\projet\mcp\scripts\maintenance\uninstall-mcp.ps1 -RemoveFiles
```

Options disponibles :
- `-RemoveFiles` : Supprime les fichiers MCP après la désinstallation

## Bonnes pratiques

### Surveillance régulière

- Vérifiez régulièrement l'état des serveurs MCP
- Configurez des alertes pour être informé des problèmes
- Générez des rapports de santé hebdomadaires

### Sauvegardes

- Effectuez des sauvegardes quotidiennes de la configuration
- Conservez au moins 7 jours de sauvegardes
- Testez régulièrement la restauration des sauvegardes

### Mises à jour

- Mettez à jour les composants MCP au moins une fois par mois
- Créez toujours une sauvegarde avant une mise à jour
- Testez les fonctionnalités après chaque mise à jour

### Tests

- Exécutez les tests unitaires après chaque modification
- Exécutez les tests d'intégration avant chaque déploiement
- Corrigez immédiatement les tests qui échouent

### Journalisation

- Consultez régulièrement les journaux des serveurs MCP
- Archivez les journaux après une certaine période
- Analysez les journaux pour détecter les problèmes récurrents

## Résolution des problèmes courants

### Un serveur ne démarre pas

1. Vérifiez les journaux dans `projet/mcp/monitoring/logs/`
2. Vérifiez que les dépendances sont correctement installées
3. Vérifiez que la configuration du serveur est correcte
4. Essayez de redémarrer le serveur avec `Restart-MCPServer -ServerName <nom_du_serveur> -Force`

### Un serveur est lent ou instable

1. Collectez des métriques de performance avec `collect-metrics.ps1`
2. Vérifiez l'utilisation des ressources (CPU, mémoire)
3. Redémarrez le serveur si nécessaire
4. Mettez à jour les composants du serveur

### Erreurs de configuration

1. Vérifiez la configuration dans `projet/mcp/config/`
2. Restaurez une sauvegarde fonctionnelle si nécessaire
3. Exécutez les tests de configuration avec `Test-MCPConfig.ps1`

### Problèmes d'intégration avec n8n

1. Vérifiez que n8n est en cours d'exécution
2. Reconfigurez l'intégration avec `configure-n8n-mcp.ps1`
3. Vérifiez les credentials dans n8n
4. Testez les workflows avec des données simples
