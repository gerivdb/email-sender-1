# container-manager

Ce répertoire contient les fichiers du gestionnaire container-manager.

## Description

Le container-manager est responsable de la gestion du cycle de vie des conteneurs Docker (start, stop, status, logs) pour les environnements de développement et potentiellement de production. Il gère les réseaux Docker et volumes définis dans docker-compose.yml.

## Structure

- development : Fichiers de développement Go
- scripts : Scripts PowerShell du gestionnaire
- modules : Modules PowerShell du gestionnaire
- tests : Tests unitaires et d'intégration du gestionnaire

## Fonctionnalités

- **Container Lifecycle** : Démarrage, arrêt, statut des conteneurs
- **Docker API Integration** : Intégration avec l'API Docker
- **Network Management** : Gestion des réseaux Docker
- **Volume Management** : Gestion des volumes Docker persistants
- **Container Logs** : Récupération et analyse des logs
- **Health Checks** : Vérification de la santé des conteneurs
- **Environment Setup** : Configuration automatique de l'environnement

## Configuration

Les fichiers de configuration du gestionnaire sont centralisés dans le répertoire projet/config/managers/container-manager.

## Utilisation

```powershell
# Démarrer tous les conteneurs

.\scripts\Start-Containers.ps1

# Arrêter tous les conteneurs

.\scripts\Stop-Containers.ps1

# Vérifier le statut des conteneurs

.\scripts\Get-ContainerStatus.ps1

# Afficher les logs des conteneurs

.\scripts\Get-ContainerLogs.ps1
```plaintext
## Intégration ErrorManager

Ce manager intègre l'ErrorManager pour la gestion centralisée des erreurs, la journalisation structurée et le catalogage des erreurs.
