# Orchestrator

## Rôle

L’orchestrator gère la distribution, l’exécution et le suivi des tâches (jobs, workflows) entre sous-systèmes ou clusters. Il orchestre l’enchaînement des actions, la synchronisation et la coordination technique.

## Responsabilités principales

- Sélectionner les clusters ou sous-systèmes cibles pour chaque tâche.
- Suivre l’état d’avancement des jobs.
- Gérer les priorités, dépendances, politiques de retry.
- Fournir une interface d’exécution unifiée pour les managers métiers.

## Relations

- Peut appeler l’integrated-manager pour exécuter des tâches complexes ou synchronisées.

- Ne supervise pas l’ensemble du système, mais agit comme chef d’orchestre technique.

## Interfaces

- API d’exécution de jobs/workflows.
- Suivi d’état, logs d’exécution, métriques d’avancement.

---
Pour la vision globale, voir [ecosystem-overview.md](ecosystem-overview.md)
