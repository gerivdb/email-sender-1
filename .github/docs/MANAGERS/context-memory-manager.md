# Context Memory Manager

## Rôle

Le Context Memory Manager gère la mémoire contextuelle et l’historique des opérations/documents pour permettre des traitements intelligents et contextuels.

## Responsabilités

- Stockage et récupération du contexte documentaire
- Gestion de l’historique des modifications
- Fourniture d’informations contextuelles aux autres managers
- Intégration avec l’integrated-manager

## Interfaces

- API de gestion du contexte
- Export d’historique

## Corrélations

- Orchestration par l’integrated-manager ([../ARCHITECTURE/integrated-manager.md](../ARCHITECTURE/integrated-manager.md))
- Supervision possible par le central-coordinator ([../ARCHITECTURE/central-coordinator.md](../ARCHITECTURE/central-coordinator.md))
