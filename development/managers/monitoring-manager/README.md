# monitoring-manager

Ce répertoire contient les fichiers du gestionnaire monitoring-manager.

## Description

Le monitoring-manager étend la portée de l'ErrorManager. Il collecte et expose les métriques d'application (performance, utilisation des ressources), les vérifications de santé. Il s'intègre avec l'ErrorManager pour les métriques d'erreurs.

## Structure

- development : Fichiers de développement Go
- scripts : Scripts PowerShell du gestionnaire
- modules : Modules PowerShell du gestionnaire
- tests : Tests unitaires et d'intégration du gestionnaire

## Fonctionnalités

- **Metrics Collection** : Collecte de métriques de performance
- **Health Checks** : Vérifications de santé de l'application
- **Resource Monitoring** : Surveillance de l'utilisation des ressources
- **Error Metrics** : Intégration avec ErrorManager pour les métriques d'erreurs
- **Alerting** : Système d'alertes basé sur les métriques
- **Dashboard** : Interface de visualisation des métriques
- **Performance Analytics** : Analyse des performances

## Configuration

Les fichiers de configuration du gestionnaire sont centralisés dans le répertoire projet/config/managers/monitoring-manager.

## Utilisation

```powershell
# Démarrer la surveillance
.\scripts\Start-Monitoring.ps1

# Vérifier la santé du système
.\scripts\Check-SystemHealth.ps1

# Générer un rapport de performance
.\scripts\Generate-PerformanceReport.ps1

# Configurer les alertes
.\scripts\Configure-Alerts.ps1
```

## Intégration ErrorManager

Ce manager intègre l'ErrorManager pour la gestion centralisée des erreurs, la journalisation structurée et le catalogage des erreurs.
