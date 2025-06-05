# storage-manager

Ce répertoire contient les fichiers du gestionnaire storage-manager.

## Description

Le storage-manager est responsable de la gestion des connexions, migrations de schéma et opérations CRUD pour tous les stores de données persistantes (PostgreSQL, Qdrant). Il fournit des repositories et objets d'accès aux données.

## Structure

- development : Fichiers de développement Go
- scripts : Scripts PowerShell du gestionnaire
- modules : Modules PowerShell du gestionnaire
- tests : Tests unitaires et d'intégration du gestionnaire

## Fonctionnalités

- **Connection Management** : Gestion des connexions aux bases de données
- **Schema Migrations** : Migrations de schéma utilisant des fichiers SQL intégrés
- **CRUD Operations** : Opérations CRUD pour PostgreSQL et Qdrant
- **Repository Pattern** : Fournit des repositories pour l'accès aux données
- **Transaction Management** : Gestion des transactions
- **Connection Pooling** : Pool de connexions pour les performances

## Configuration

Les fichiers de configuration du gestionnaire sont centralisés dans le répertoire projet/config/managers/storage-manager.

## Utilisation

```powershell
# Initialiser les connexions de stockage
.\scripts\Initialize-StorageConnections.ps1

# Exécuter les migrations
.\scripts\Run-Migrations.ps1

# Tester les connexions
.\scripts\Test-StorageConnections.ps1
```

## Intégration ErrorManager

Ce manager intègre l'ErrorManager pour la gestion centralisée des erreurs, la journalisation structurée et le catalogage des erreurs.
