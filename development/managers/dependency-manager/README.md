# dependency-manager

Ce répertoire contient les fichiers du gestionnaire dependency-manager.

## Description

Le dependency-manager est responsable de la gestion des dépendances Go du projet. Il offre une interface unifiée pour lister, ajouter, supprimer et mettre à jour les dépendances via go.mod.

## Structure

- config : Fichiers de configuration spécifiques au gestionnaire
- scripts : Scripts PowerShell du gestionnaire
- modules : Modules PowerShell du gestionnaire
- tests : Tests unitaires et d'intégration du gestionnaire

## Fonctionnalités

- **List** : Affiche toutes les dépendances du projet avec leurs versions
- **Add** : Ajoute une nouvelle dépendance au projet
- **Remove** : Supprime une dépendance du projet
- **Update** : Met à jour une dépendance vers la dernière version
- **Audit** : Vérifie les vulnérabilités des dépendances
- **Cleanup** : Nettoie les dépendances inutilisées

## Configuration

Les fichiers de configuration du gestionnaire sont centralisés dans le répertoire projet/config/managers/dependency-manager.

## Utilisation

```powershell
# Via le script PowerShell
.\dependency-manager.ps1 -Action list
.\dependency-manager.ps1 -Action add -Module "github.com/pkg/errors" -Version "v0.9.1"
.\dependency-manager.ps1 -Action remove -Module "github.com/pkg/errors"
.\dependency-manager.ps1 -Action update -Module "github.com/gorilla/mux"

# Via le binaire Go directement
go run .\modules\dependency_manager.go list
go run .\modules\dependency_manager.go add --module github.com/pkg/errors --version v0.9.1
```
