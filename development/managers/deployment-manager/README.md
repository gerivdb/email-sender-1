# deployment-manager

Ce répertoire contient les fichiers du gestionnaire deployment-manager.

## Description

Le deployment-manager gère les processus de build (compilation Go, construction d'assets), le packaging et l'interface avec les systèmes CI/CD. Il gère le déploiement vers différents environnements, incluant la construction/push d'images Docker si applicable.

## Structure

- development : Fichiers de développement Go
- scripts : Scripts PowerShell du gestionnaire
- modules : Modules PowerShell du gestionnaire
- tests : Tests unitaires et d'intégration du gestionnaire

## Fonctionnalités

- **Build Management** : Compilation Go et construction d'assets
- **Packaging** : Empaquetage des applications
- **CI/CD Integration** : Interface avec les systèmes CI/CD
- **Environment Deployment** : Déploiement vers différents environnements
- **Docker Image Building** : Construction et push d'images Docker
- **Asset Optimization** : Optimisation des assets pour la production
- **Release Management** : Gestion des releases et versions

## Configuration

Les fichiers de configuration du gestionnaire sont centralisés dans le répertoire projet/config/managers/deployment-manager.

## Utilisation

```powershell
# Construire l'application

.\scripts\Build-Application.ps1

# Déployer vers un environnement

.\scripts\Deploy-ToEnvironment.ps1 -Environment "staging"

# Construire une image Docker

.\scripts\Build-DockerImage.ps1

# Créer une release

.\scripts\Create-Release.ps1 -Version "1.0.0"
```plaintext
## Intégration ErrorManager

Ce manager intègre l'ErrorManager pour la gestion centralisée des erreurs, la journalisation structurée et le catalogage des erreurs.
