# Branch Manager

## Rôle

Le Branch Manager gère la création, la gestion, la fusion et la suppression des branches dans l’écosystème documentaire.

## Responsabilités

- Création et suppression de branches
- Fusion de branches (avec ou sans résolution de conflits)
- Suivi de l’état des branches
- Intégration avec l’integrated-manager pour les opérations synchronisées

## Interfaces

- API de gestion des branches
- Événements de notification lors des changements d’état

## Corrélations

- Orchestration par l’integrated-manager ([../ARCHITECTURE/integrated-manager.md](../ARCHITECTURE/integrated-manager.md))
- Supervision possible par le central-coordinator ([../ARCHITECTURE/central-coordinator.md](../ARCHITECTURE/central-coordinator.md))
