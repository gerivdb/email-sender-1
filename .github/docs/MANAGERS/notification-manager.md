# Notification Manager

## Rôle

Le Notification Manager gère l’envoi, la réception et la gestion des notifications dans l’écosystème documentaire.

## Responsabilités

- Envoi de notifications aux utilisateurs ou systèmes
- Gestion des files d’attente de notifications
- Suivi des statuts d’envoi
- Intégration avec l’integrated-manager

## Interfaces

- API d’envoi et de gestion des notifications
- Webhooks, files d’attente

## Corrélations

- Orchestration par l’integrated-manager ([../ARCHITECTURE/integrated-manager.md](../ARCHITECTURE/integrated-manager.md))
- Supervision possible par le central-coordinator ([../ARCHITECTURE/central-coordinator.md](../ARCHITECTURE/central-coordinator.md))
