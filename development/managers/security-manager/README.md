# security-manager

Ce répertoire contient les fichiers du gestionnaire security-manager.

## Description

Le security-manager gère les secrets (chargement, accès sécurisé), les clés API et potentiellement la logique de contrôle d'accès si elle n'est pas gérée par un service d'auth dédié.

## Structure

- development : Fichiers de développement Go
- scripts : Scripts PowerShell du gestionnaire
- modules : Modules PowerShell du gestionnaire
- tests : Tests unitaires et d'intégration du gestionnaire

## Fonctionnalités

- **Secret Management** : Gestion sécurisée des secrets
- **API Key Management** : Gestion des clés API
- **Access Control** : Logique de contrôle d'accès
- **Encryption/Decryption** : Chiffrement et déchiffrement
- **Certificate Management** : Gestion des certificats
- **Authentication** : Authentification des utilisateurs
- **Security Auditing** : Audit de sécurité

## Configuration

Les fichiers de configuration du gestionnaire sont centralisés dans le répertoire projet/config/managers/security-manager.

## Utilisation

```powershell
# Charger les secrets
.\scripts\Load-Secrets.ps1

# Générer une clé API
.\scripts\Generate-ApiKey.ps1

# Vérifier les permissions
.\scripts\Check-Permissions.ps1

# Audit de sécurité
.\scripts\Run-SecurityAudit.ps1
```

## Intégration ErrorManager

Ce manager intègre l'ErrorManager pour la gestion centralisée des erreurs, la journalisation structurée et le catalogage des erreurs.
