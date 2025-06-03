# Scripts Utilitaires

Ce répertoire contient les scripts utilitaires principaux pour interagir avec les différents gestionnaires du projet.

## Scripts disponibles

### 📦 Gestionnaire de dépendances - `dep.ps1`

Script simplifié pour gérer les dépendances Go du projet.

```powershell
# Afficher l'aide
.\scripts\dep.ps1 help

# Lister les dépendances
.\scripts\dep.ps1 list

# Ajouter une dépendance
.\scripts\dep.ps1 add github.com/pkg/errors v0.9.1

# Supprimer une dépendance
.\scripts\dep.ps1 remove github.com/pkg/errors

# Mettre à jour une dépendance
.\scripts\dep.ps1 update github.com/gorilla/mux

# Compiler le gestionnaire
.\scripts\dep.ps1 build
```

### 🗺️ Gestionnaire de roadmap - `roadmap.ps1`

Script simplifié pour interagir avec TaskMaster (gestionnaire de roadmap).

```powershell
# Afficher l'aide
.\scripts\roadmap.ps1 help

# Interface TUI interactive
.\scripts\roadmap.ps1 view

# Créer un nouvel item
.\scripts\roadmap.ps1 create item "Build API" --priority high

# Ingérer un document avec parsing avancé
.\scripts\roadmap.ps1 ingest-advanced plan.md --dry-run

# Compiler le gestionnaire
.\scripts\roadmap.ps1 build

# Lancer les tests
.\scripts\roadmap.ps1 test
```

## Architecture

Ces scripts sont des interfaces simplifiées qui pointent vers les gestionnaires dans `development/managers/` :

- `dep.ps1` → `development/managers/dependency-manager/`
- `roadmap.ps1` → `development/managers/roadmap-manager/roadmap-cli/`

## Utilisation depuis la racine

Tous les scripts doivent être exécutés depuis la racine du projet :

```powershell
# Depuis la racine du projet
.\scripts\dep.ps1 list
.\scripts\roadmap.ps1 view
```

## Gestionnaires avancés

Pour un accès plus avancé aux gestionnaires, utilisez directement :

- **Process Manager** : `development/managers/process-manager/`
- **Integrated Manager** : `development/managers/integrated-manager/`
- **Adaptateurs** : `development/managers/process-manager/adapters/`
